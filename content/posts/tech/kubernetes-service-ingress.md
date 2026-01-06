    ---
title: "kubernetes | service & ingress" 
date: 2022-10-07
lastmod: 2024-01-28
tags:
  - kubernetes
keywords:
  - kubernetes
  - service
  - iptables
  - ipvs
  - ingress
  - nginx
description: "介绍 kubernetes 中的 service 和 Headless Service，service 的两种代理模式，以及ingress 控制器的使用" 
cover:
    image: "images/logo-kubernetes.png"
---

# 0 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# 1 service

## 1.1 基本概念

service 存在的意义

- 服务发现：防止 Pod 失联
- 负载均衡：定义一组 Pod 的访问策略

service 通过 label-selector 关联 pod

service 的三种类型

- ClusterIP：集群内部使用
    - 默认，分配一个稳定的 IP 地址，即 VIP，只能在集群内部访问（同 Namespace 内的 Pod）
- NodePort：对外暴露应用
    - 在每个节点上启用一个端口 (30000-32767) 来暴露服务，可以在集群外部访问。也会分配一个稳定内部集群 IP 地址。
- LoadBalancer：对外暴露应用，适用公有云

  与 NodePort 类似，在每个节点上启用一个端口来暴露服务。除此之外，Kubernetes 会请求底层云平台上的负载均衡器，将每个 Node（[NodeIP]:[NodePort]）作为后端添加进去。

示例

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
    - protocol: TCP
      port: 80 # service端口，内部访问端口
      targetPort: 80 # 后端业务镜像实际暴露的端口
      nodePort: 30002 # 内部访问端口映射到节点端口
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.22.1
        ports:
        - containerPort: 80
```

## 1.2 代理模式

Iptables：

- 灵活，功能强大
- 规则遍历匹配和更新，呈线性时延

IPVS：

- 工作在内核态，有更好的性能
- 调度算法丰富：rr，wrr，lc，wlc，ip hash…

![image-20221005090953888](/images/image-20221005090953888.png)

### 1.2.1 iptables 模式

使用 iptables 模式时，根据 iptables 的 `--mode random --probability` 来匹配每一条请求，每个 pod 收到的流量趋近于平衡，不是完全的轮询

这种模式，kube-proxy 会监听 Kubernetes 对 `Service` 对象和 `Endpoints` 对象的添加和移除。对每个 `Service`，它会安装 `iptables` 规则，从而捕获到达该 `Service` 的 `clusterIP` 和端口的请求，进而将请求重定向到 `Service` 任意一组 `backend pod` 中。对于每个 `Endpoints` 对象，它也会安装 `iptables` 规则，这个规则会选择一个 `backend pod` 组合。

k8s 默认采用的代理模式是 iptables，可以通过查看 kube-proxy 组件的日志可得

```bash
[root@k8s-node1 ~]# kubectl logs kube-proxy-8mf2l -n kube-system  | grep Using
I0412 02:02:29.634610       1 server_others.go:212] Using iptables Proxier.
```

创建一个上述示例中的 yaml ，查看 iptables 规则

```bash
[root@k8s-node1 ~]# kubectl get svc nginx
NAME    TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
nginx   NodePort   10.105.220.154   <none>        80:30002/TCP   4m40s

# SVC当前共关联三个POD
[root@k8s-node1 ~]# kubectl get pod -o wide -l app=nginx
NAME                    READY   STATUS    RESTARTS   AGE     IP               NODE        NOMINATED NODE   READINESS GATES
nginx-55f4d8c85-l29wx   1/1     Running   0          4m57s   10.244.169.133   k8s-node2   <none>           <none>
nginx-55f4d8c85-lf5dj   1/1     Running   0          4m57s   10.244.107.205   k8s-node3   <none>           <none>
nginx-55f4d8c85-q4gsx   1/1     Running   0          4m57s   10.244.107.203   k8s-node3   <none>           <none>

[root@k8s-node1 ~]# iptables-save |grep -i nodeport |grep 30002
# NODEPORTS 根据端口将流量转发到 SVC 链
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/nginx" -m tcp --dport 30002 -j KUBE-SVC-2CMXP7HKUVJN7L6M

[root@k8s-node1 ~]# iptables-save |grep KUBE-SVC-2CMXP7HKUVJN7L6M
# ClusterIP 相关
-A KUBE-SERVICES -d 10.109.98.33/32 -p tcp -m comment --comment "default/nginx cluster IP" -m tcp --dport 80 -j KUBE-SVC-2CMXP7HKUVJN7L6M
# 转发到具体 POD 链，每条 POD 链都有一样的概率获取到流量
-A KUBE-SVC-2CMXP7HKUVJN7L6M -m comment --comment "default/nginx" -m statistic --mode random --probability 0.33333333349 -j KUBE-SEP-ONLOYCYPTBL5FQH5
-A KUBE-SVC-2CMXP7HKUVJN7L6M -m comment --comment "default/nginx" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-JABTJNSPARJARZOW
-A KUBE-SVC-2CMXP7HKUVJN7L6M -m comment --comment "default/nginx" -j KUBE-SEP-TZBGLRHUI2CFM5CU

# POD链中定义了转发到具体的POD地址，
[root@k8s-node1 ~]# iptables-save |grep KUBE-SEP-ONLOYCYPTBL5FQH5
-A KUBE-SEP-ONLOYCYPTBL5FQH5 -s 10.244.107.252/32 -m comment --comment "default/nginx" -j KUBE-MARK-MASQ
-A KUBE-SEP-ONLOYCYPTBL5FQH5 -p tcp -m comment --comment "default/nginx" -m tcp -j DNAT --to-destination 10.244.107.252:80
[root@k8s-node1 ~]# iptables-save |grep KUBE-SEP-JABTJNSPARJARZOW
-A KUBE-SEP-JABTJNSPARJARZOW -s 10.244.169.135/32 -m comment --comment "default/nginx" -j KUBE-MARK-MASQ
-A KUBE-SEP-JABTJNSPARJARZOW -p tcp -m comment --comment "default/nginx" -m tcp -j DNAT --to-destination 10.244.169.135:80
[root@k8s-node1 ~]# iptables-save |grep KUBE-SEP-TZBGLRHUI2CFM5CU
-A KUBE-SEP-TZBGLRHUI2CFM5CU -s 10.244.169.136/32 -m comment --comment "default/nginx" -j KUBE-MARK-MASQ
-A KUBE-SEP-TZBGLRHUI2CFM5CU -p tcp -m comment --comment "default/nginx" -m tcp -j DNAT --to-destination 10.244.169.136:80

```

### 1.2.2 ipvs 模式

ipvsadm 安装配置 (所有节点都要配置)

```bash
[root@k8s-node1 ~]# yum install ipvsadm
[root@k8s-node1 ~]# cat > /etc/sysconfig/modules/ipvs.modules << EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
[root@k8s-node1 ~]# chmod 755 /etc/sysconfig/modules/ipvs.modules
[root@k8s-node1 ~]# source /etc/sysconfig/modules/ipvs.modules
```

修改 service 使用的代理模式为 ipvs

```bash
[root@k8s-node1 ~]# kubectl edit configmap kube-proxy -n kube-system
    mode: "ipvs"
    ipvs:
      scheduler: "rr" #rr, wrr, lc, wlc, ip hash等

# 删除所有 kube-proxy，k8s 会重新创建
[root@k8s-node1 ~]# kubectl delete pod -n kube-system -l k8s-app=kube-proxy
[root@k8s-node1 ~]# kubectl logs kube-proxy-8z86w -n kube-system | grep Using
I0412 08:30:21.169231       1 server_others.go:274] Using ipvs Proxier.
```

查看 ipvs 规则

```bash
[root@k8s-node1 ~]# ipvsadm -L -n
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.17.0.1:30002 rr
  -> 10.244.107.252:80            Masq    1      0          0
  -> 10.244.169.135:80            Masq    1      0          0
  -> 10.244.169.136:80            Masq    1      0          0
TCP  1.1.1.1:30002 rr
  -> 10.244.107.252:80            Masq    1      0          0
  -> 10.244.169.135:80            Masq    1      0          0
  -> 10.244.169.136:80            Masq    1      0          0
TCP  10.244.36.64:30002 rr
  -> 10.244.107.252:80            Masq    1      0          0
  -> 10.244.169.135:80            Masq    1      0          0
  -> 10.244.169.136:80            Masq    1      0          0
TCP  10.109.98.33:80 rr
  -> 10.244.107.252:80            Masq    1      0          0
  -> 10.244.169.135:80            Masq    1      0          0
  -> 10.244.169.136:80            Masq    1      0          0
```

# 2 Headless Service

Headless Service 相比普通 Service 只是将 spec.clusterIP 定义为 None

Headless Service 几大特点：

- 不分配 clusterIP
- 没有负载均衡的功能 (kube-proxy 不会安装 iptables 规则)
- 可以通过解析 service 的 DNS，返回所有 Pod 的 IP 和 DNS (statefulSet 部署的 Pod 才有 DNS)

  ```bash
  [root@k8s-node1 ~]# kubectl run -it --rm --restart=Never --image busybox:1.28  dns-test -- nslookup statefulset-nginx.default.svc.cluster.local
  Server:    10.96.0.10
  Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
  
  Name:      statefulset-nginx.default.svc.cluster.local
  Address 1: 10.244.107.200 statefulset-nginx-1.statefulset-nginx.default.svc.cluster.local
  Address 2: 10.244.169.188 statefulset-nginx-0.statefulset-nginx.default.svc.cluster.local
  pod "dns-test" deleted
  ```

Headless Services 应用场景

1. 自主选择权，`client` 可以通过查询 DNS 来获取 `Real Server` 的信息，自己来决定使用哪个 `Real Server`
2. `Headless Service` 的对应的每一个 `Endpoints`，即每一个 `Pod`，都会有对应的 `DNS域名`，这样 Pod 之间就可以互相访问

DNS 解析名称：

- pod：`<pod-name>.<service-name>.<namespace>.svc.cluster.local`
- service: `<service-name>.<namespace>.svc.cluster.local`

# 3 Ingress

## 3.1 基本概念

NodePort 的不足

- 一个端口只能一个服务使用，端口需提前规划
- 只支持 4 层负载均衡

**Ingress 是什么？**

Ingress 公开了从集群外部到集群内服务的 HTTP 和 HTTPS 路由。流量路由由 Ingress 资源上定义的规则控制。

下面是一个将所有流量都发送到同一 Service 的简单 Ingress 示例：

![image-20221005140153771](/images/image-20221005140153771.png)

Ingress Controller

Ingress 管理的负载均衡器，为集群提供全局的负载均衡能力。

Ingress Contronler 怎么工作的？

Ingress Contronler 通过与 Kubernetes API 交互，动态的去感知集群中 Ingress 规则变化，然后读取它，按照自定义的规则，规则就是写明了哪个域名对应哪个 service，生成一段 Nginx 配置，应用到管理的 Nginx 服务，然后热加载生效。

以此来达到 Nginx 负载均衡器配置及动态更新的问题

使用流程：

1. 部署 Ingress Controller
2. 创建 Ingress 规则

![image-20221005141711017](/images/image-20221005141711017.png)

Ingress Contorller 主流控制器：

- ingress-nginx-controller: nginx 官方维护的控制器
- Traefik： HTTP 反向代理、负载均衡工具
- Istio：服务治理，控制入口流量

这里使用 Nginx 官方维护的，[项目地址](https://github.com/kubernetes/ingress-nginx)

## 3.2 安装部署

下载 yaml 文件

```bash
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/baremetal/1.22/deploy.yaml --no-check-certificate
```

修改

```yaml
# 修改kind, 将原先的Deployment修改为DaemontSet，实现所有物理节点访问
kind: DaemonSet 
spec:
  template:
    spec:
      # 新增 hostNetwork, 将ingress-nginx-controller的端口直接暴露在宿主机上
      hostNetwork: true 
      containers:
        # 修改 image 为国内地址
        image: registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:v1.3.0 
      # 新增污点容忍，允许在 master 节点创建pod
      tolerations: 
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
---
kind: Job
spec:
  template:
    spec:
      containers:
        # 修改 image 为国内地址
        image: registry.cn-hangzhou.aliyuncs.com/google_containers/kube-webhook-certgen:v1.1.1
---
kind: Job
spec:
  template:
    spec:
      containers:
        # 修改 image 为国内地址
        image: registry.cn-hangzhou.aliyuncs.com/google_containers/kube-webhook-certgen:v1.1.1
```

部署

```bash
[root@k8s-node1 ~]# kubectl apply -f deploy.yaml

[root@k8s-node1 opt]# kubectl get pods -n ingress-nginx -o wide
NAME                                      READY   STATUS      RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
ingress-nginx-admission-create--1-zfwrz   0/1     Completed   0          12m   10.244.169.135   k8s-node2   <none>           <none>
ingress-nginx-admission-patch--1-8rhjr    0/1     Completed   0          12m   10.244.169.134   k8s-node2   <none>           <none>
ingress-nginx-controller-bb2kd            1/1     Running     0          12m   1.1.1.3          k8s-node3   <none>           <none>
ingress-nginx-controller-bp588            1/1     Running     0          12m   1.1.1.2          k8s-node2   <none>           <none>
ingress-nginx-controller-z2782            1/1     Running     0          12m   1.1.1.1          k8s-node1   <none>           <none>

# 如果出现内部访问报错：failed calling webhook "validate.nginx.ingress.kubernetes.io"
[root@k8s-node1 ~]# kubectl get ValidatingWebhookConfiguration
[root@k8s-node1 ~]# kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```

## 3.3 测试

测试 url 跳转，创建三套 nginx 应用 : `test | foo | bar`

需要注意的是，代理路径假如是 `/foo` 的话，后端真实路径也是 `/foo`

test 应用示例，foo 和 bar 的自行修改

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test
  labels:
    app: test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: test
        image: nginx:1.22.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: www
        persistentVolumeClaim:
          claimName: pvc-test
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-test
spec:
  storageClassName: "nfs"
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Service
metadata:
  name: test
  labels:
    app: test
spec:
  selector:
    app: test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

创建 ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-nginx
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: test.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
      - path: /foo
        pathType: Prefix
        backend:
          service:
            name: foo
            port:
              number: 80
      - path: /bar
        pathType: Prefix
        backend:
          service:
            name: bar
            port:
              number: 80
```

查看创建的 ingress

```bash
[root@k8s-node1 ~]# kubectl describe ingress demo-nginx
Name:             demo-nginx
Namespace:        default
Address:          1.1.1.1,1.1.1.2,1.1.1.3
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  test.com
              /      test:80 (10.244.107.209:80,10.244.107.212:80,10.244.169.140:80)
              /foo   foo:80 (10.244.107.210:80,10.244.169.138:80,10.244.169.144:80)
              /bar   bar:80 (10.244.107.211:80,10.244.169.131:80,10.244.169.143:80)
Annotations:  kubernetes.io/ingress.class: nginx
Events:       <none>
```

修改 index.html

```bash
[root@k8s-node1 ~]# echo "test" > /nfs/default-pvc-test-pvc-93a7df14-90f2-4466-8655-6ef42549b760/index.html
[root@k8s-node1 ~]# mkdir /nfs/default-pvc-foo-pvc-75e73500-1a70-4305-8253-d1e7d8c88b49/foo
[root@k8s-node1 ~]# echo "foo" > /nfs/default-pvc-foo-pvc-75e73500-1a70-4305-8253-d1e7d8c88b49/foo/index.html
[root@k8s-node1 ~]# mkdir /nfs/default-pvc-bar-pvc-73d12b15-7c53-46ee-a1b6-d0cb2c25e7e6/bar/
[root@k8s-node1 ~]# echo "bar" > /nfs/default-pvc-bar-pvc-73d12b15-7c53-46ee-a1b6-d0cb2c25e7e6/bar/index.html
```

访问测试

```bash
[root@k8s-node1 ~]# curl http://1.1.1.1/ -H "Host: test.com"
test
[root@k8s-node1 ~]# curl http://1.1.1.2/foo/ -H "Host: test.com"
foo
[root@k8s-node1 ~]# curl http://1.1.1.3/bar/ -H "Host: test.com"
bar
```

以上
