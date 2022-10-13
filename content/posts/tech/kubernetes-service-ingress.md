---
title: "kubernetes | service & ingress" 
date: 2022-10-07
lastmod: 2022-10-07
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- network
- service
- iptables
- ipvs
- ingress
- nginx
description: "介绍kubernetes中的service基础概念，service的两种代理模式，以及ingress控制器的使用" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---
# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# service

## 基本概念

service存在的意义

- 服务发现：防止Pod失联

- 负载均衡：定义一组Pod的访问策略

service通过label-selector关联pod

service的三种类型

- ClusterIP：集群内部使用

  默认**，**分配一个稳定的IP地址，即VIP，只能在集群内部访问（同Namespace内的Pod）

- NodePort：对外暴露应用

  在每个节点上启用一个端口(30000-32767)来暴露服务，可以在集群外部访问。也会分配一个稳定内部集群IP地址。访问地址：[NodeIP]:[NodePort]

- LoadBalancer：对外暴露应用，适用公有云

  与NodePort类似，在每个节点上启用一个端口来暴露服务。除此之外，Kubernetes会请求底层云平台上的负载均衡器，将每个Node（[NodeIP]:[NodePort]）作为后端添加进去。

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
      targetPort: 80 # 代理的业务端口
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
        image: nginx:1.19
        ports:
        - containerPort: 80
```

## service代理模式

Iptables： 

- 灵活，功能强大

- 规则遍历匹配和更新，呈线性时延

IPVS： 

- 工作在内核态，有更好的性能

- 调度算法丰富：rr，wrr，lc，wlc，ip hash...



![image-20221005090953888](https://image.lvbibir.cn/blog/image-20221005090953888.png)

k8s默认采用的代理模式是iptables，可以通过查看kube-proxy组件的日志可得

```
[root@k8s-node1 ~]# kubectl logs kube-proxy-qqdq4 -n kube-system
I1005 00:27:19.907705       1 node.go:172] Successfully retrieved node IP: 1.1.1.2
I1005 00:27:19.907801       1 server_others.go:140] Detected node IP 1.1.1.2
W1005 00:27:19.907939       1 server_others.go:565] Unknown proxy mode "", assuming iptables proxy
I1005 00:27:20.845559       1 server_others.go:206] kube-proxy running in dual-stack mode, IPv4-primary
I1005 00:27:20.845678       1 server_others.go:212] Using iptables Proxier.
I1005 00:27:20.845803       1 server_others.go:219] creating dualStackProxier for iptables.
......
```

创建一个nodeport类型的service，查看iptables规则

```
[root@k8s-node1 ~]# kubectl get svc nginx
NAME    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx   NodePort   10.109.98.33   <none>        80:30002/TCP   17m

# SVC当前共关联三个POD
[root@k8s-node1 ~]# kubectl get pod -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
nginx-7cf55fb7bb-5fjcn   1/1     Running   0          37m   10.244.169.136   k8s-node2   <none>           <none>
nginx-7cf55fb7bb-bts6p   1/1     Running   0          37m   10.244.107.252   k8s-node3   <none>           <none>
nginx-7cf55fb7bb-qm4vl   1/1     Running   0          37m   10.244.169.135   k8s-node2   <none>           <none>

[root@k8s-node1 ~]# iptables-save |grep nginx |grep 30002
...... 流量转发到SVC链
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/nginx" -m tcp --dport 30002 -j KUBE-SVC-2CMXP7HKUVJN7L6M
......

[root@k8s-node1 ~]# iptables-save |grep KUBE-SVC-2CMXP7HKUVJN7L6M
......
# ClusterIP相关
-A KUBE-SERVICES -d 10.109.98.33/32 -p tcp -m comment --comment "default/nginx cluster IP" -m tcp --dport 80 -j KUBE-SVC-2CMXP7HKUVJN7L6M
......
# 转发到具体POD链
-A KUBE-SVC-2CMXP7HKUVJN7L6M -m comment --comment "default/nginx" -m statistic --mode random --probability 0.33333333349 -j KUBE-SEP-ONLOYCYPTBL5FQH5
-A KUBE-SVC-2CMXP7HKUVJN7L6M -m comment --comment "default/nginx" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-JABTJNSPARJARZOW
-A KUBE-SVC-2CMXP7HKUVJN7L6M -m comment --comment "default/nginx" -j KUBE-SEP-TZBGLRHUI2CFM5CU

# POD链中定义了转发到具体的POD地址，
[root@k8s-node1 ~]# iptables-save |grep KUBE-SEP-ONLOYCYPTBL5FQH5
......
-A KUBE-SEP-ONLOYCYPTBL5FQH5 -s 10.244.107.252/32 -m comment --comment "default/nginx" -j KUBE-MARK-MASQ
-A KUBE-SEP-ONLOYCYPTBL5FQH5 -p tcp -m comment --comment "default/nginx" -m tcp -j DNAT --to-destination 10.244.107.252:80
......
[root@k8s-node1 ~]# iptables-save |grep KUBE-SEP-JABTJNSPARJARZOW
......
-A KUBE-SEP-JABTJNSPARJARZOW -s 10.244.169.135/32 -m comment --comment "default/nginx" -j KUBE-MARK-MASQ
-A KUBE-SEP-JABTJNSPARJARZOW -p tcp -m comment --comment "default/nginx" -m tcp -j DNAT --to-destination 10.244.169.135:80
......
[root@k8s-node1 ~]# iptables-save |grep KUBE-SEP-TZBGLRHUI2CFM5CU
......
-A KUBE-SEP-TZBGLRHUI2CFM5CU -s 10.244.169.136/32 -m comment --comment "default/nginx" -j KUBE-MARK-MASQ
-A KUBE-SEP-TZBGLRHUI2CFM5CU -p tcp -m comment --comment "default/nginx" -m tcp -j DNAT --to-destination 10.244.169.136:80
......
```

ipvs模式（所有节点都要配置）

```none
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

# 修改mode
[root@k8s-node1 ~]# kubectl edit configmap kube-proxy -n kube-system
    mode: "ipvs"
    ipvs:
      scheduler: "rr" #rr, wrr, lc, wlc, ip hash等

# 删除所有节点的kube-proxy，k8s会再自动拉起一个
[root@k8s-node1 ~]# kubectl delete pod kube-proxy-92rd4 -n kube-system
[root@k8s-node1 ~]# kubectl delete pod kube-proxy-bgzhk -n kube-system
[root@k8s-node1 ~]# kubectl delete pod kube-proxy-n57zw -n kube-system
[root@k8s-node1 ~]# kubectl logs kube-proxy-245vq -n kube-system
......
I1005 05:42:48.379343       1 server_others.go:274] Using ipvs Proxier.
......
```

查看iptables规则

```
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

# Ingress

NodePort的不足

- 一个端口只能一个服务使用，端口需提前规划
- 只支持4层负载均衡

**Ingress是什么？**

Ingress 公开了从集群外部到集群内服务的HTTP和HTTPS路由。流量路由由Ingress资源上定义的规则控制。

下面是一个将所有流量都发送到同一Service的简单Ingress示例：

![image-20221005140153771](https://image.lvbibir.cn/blog/image-20221005140153771.png)

**Ingress Controller**

Ingress管理的负载均衡器，为集群提供全局的负载均衡能力。

**Ingress Contronler怎么工作的？**

Ingress Contronler通过与 Kubernetes API 交互，动态的去感知集群中 Ingress 规则变化，然后读取它，按照自定义的规则，规则就是写明了哪个域名对应哪个service，生成一段 Nginx 配置，应用到管理的Nginx服务，然后热加载生效。

以此来达到Nginx负载均衡器配置及动态更新的问题

使用流程：

1. 部署Ingress Controller

2. 创建Ingress规则

![image-20221005141711017](https://image.lvbibir.cn/blog/image-20221005141711017.png)

Ingress Contorller主流控制器：

- ingress-nginx-controller: 官方维护的基于nginx的控制器

- Traefik： HTTP反向代理、负载均衡工具

- Istio：服务治理，控制入口流量

这里使用官方维护的基于Nginx实现的，Github：https://github.com/kubernetes/ingress-nginx

部署

```
[root@k8s-node1 ~]# wget https://github.com/kubernetes/ingress-nginx/raw/controller-v1.1.0/deploy/static/provider/baremetal/deploy.yaml --no-check-certificate
[root@k8s-node1 ~]# vim deploy.yaml
kind: DaemonSet # 将原先的Deployment修改为DaemontSet，实现所有物理节点访问
      hostNetwork: true # 新增hostNetwork将ingress-nginx-controller的端口直接暴露在宿主机上，不然还需要创建一个sevice用于暴露ingress-nginx-controller的端口
      containers:
        - name: controller
          # 镜像地址
          image: registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:v1.1.0
          image: registry.cn-hangzhou.aliyuncs.com/google_containers/kube-webhook-certgen:v1.1.1
          image: registry.cn-hangzhou.aliyuncs.com/google_containers/kube-webhook-certgen:v1.1.1
[root@k8s-node1 ~]# kubectl apply -f deploy.yaml

# 只有两个节点上有ingress-nginx-controller控制器，因为master节点有污点
[root@k8s-node1 ~]# kubectl get pods -n ingress-nginx -o wide | grep controller
ingress-nginx-controller-h6hl5            1/1     Running     0          2m36s   1.1.1.3          k8s-node3   <none>           <none>
ingress-nginx-controller-rwbjx            1/1     Running     0          2m36s   1.1.1.2          k8s-node2   <none>           <none>


# 如果出现内部访问报错：failed calling webhook "validate.nginx.ingress.kubernetes.io"
kubectl get ValidatingWebhookConfiguration
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```

示例（http）

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-nginx
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

curl访问

```
[root@k8s-node1 ~]# curl -I http://1.1.1.2 -H "Host: foo.bar.com"
HTTP/1.1 200 OK
[root@k8s-node1 ~]# curl -I http://1.1.1.3 -H "Host: foo.bar.com"
HTTP/1.1 200 OK
```
