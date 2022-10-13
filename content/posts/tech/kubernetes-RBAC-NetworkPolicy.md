---
title: "kubernetes | RBAC鉴权和PodAcl" 
date: 2022-10-07
lastmod: 2022-10-07
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- RBAC
- PodAcl
description: "介绍kubernetes中的安全框架、RBAC鉴权和网络策略（Pod ACL)" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 

---

# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`



# kubernetes安全框架

- 客户端要想访问K8s集群API Server，一般需要证书、Token或者用户名+密码；如果Pod访问，需要ServiceAccount

- K8S安全控制框架主要由下面3个阶段进行控制，每一个阶段都支持插件方式，通过API Server配置来启用插件。
  - Authentication（鉴权）
  - Authorization（授权）
  - Admission Control（准入控制） 

![image-20221007174309826](https://image.lvbibir.cn/blog/image-20221007174309826.png)

**鉴权(Authentication)**

三种客户端身份认证： 

- HTTPS 证书认证：基于CA证书签名的数字证书认证

- HTTP Token认证：通过一个Token来识别用户

- HTTP Base认证：用户名+密码的方式认证

RBAC（Role-Based Access Control，基于角色的访问控制）：负责完成授权（Authorization）工作。

RBAC根据API请求属性，决定允许还是拒绝。

比较常见的授权维度：

- user：用户名

- group：用户分组

- 资源，例如pod、deployment

- 资源操作方法：get，list，create，update，patch，watch，delete

- 命名空间

- API组

**准入控制(Admission Control)**

Adminssion Control实际上是一个准入控制器插件列表，发送到API Server的请求都需要经过这个列表中的每个准入控制器插件的检查，检查不通过，则拒绝请求

# RBAC

## 基础概念

RBAC（Role-Based Access Control，基于角色的访问控制），允许通过Kubernetes API动态配置策略。

**角色**

- Role：授权特定命名空间的访问权限

- ClusterRole：授权所有命名空间的访问权限

**角色绑定**

- RoleBinding：将角色绑定到主体（即subject） 

- ClusterRoleBinding：将集群角色绑定到主体

**主体（subject）** 

- User：用户

- Group：用户组

- ServiceAccount：服务账号

![2022年10月7日184036](https://image.lvbibir.cn/blog/2022%E5%B9%B410%E6%9C%887%E6%97%A5184036.png)

## 示例

为Amadeus用户授权default命名空间Pod读取权限

### 用k8s ca签发客户端证书

下载cfssl工具

```
wget --no-check-certificate https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssl_linux-amd64
wget --no-check-certificate https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssljson_linux-amd64
wget --no-check-certificate https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssl-certinfo_linux-amd64
chmod a+x cfssl*
mv cfssl_linux-amd64 /usr/bin/cfssl
mv cfssljson_linux-amd64 /usr/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
```

创建ca-config.json 证书文件

```json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
```

Amadeus-csr.json 证书文件

```json
{
  "CN": "Amadeus",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
```

生成证书

```
[root@k8s-node1 ~]# cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key -config=ca-config.json -profile=kubernetes Amadeus-csr.json | cfssljson -bare Amadeus
# 生成时会有警告，可以忽略，是因为提供的信息不是很全
[root@k8s-node1 ~]# ls Amadeus*
# 生成如下三个文件
Amadeus.csr   Amadeus-key.pem  Amadeus.pem
```

### 生成kubeconfig授权文件

```bash
kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/pki/ca.crt \
--embed-certs=true \
--server=https://1.1.1.1:6443 \
--kubeconfig=Amadeus.kubeconfig

# --embed-certs=true 表示将证书写入etcd
```

设置客户端证书

```bash
kubectl config set-credentials Amadeus \
--client-key=Amadeus-key.pem \
--client-certificate=Amadeus.pem \
--embed-certs=true \
--kubeconfig=Amadeus.kubeconfig
```

设置默认上下文

```bash
kubectl config set-context kubernetes \
--cluster=kubernetes \
--user=Amadeus \
--kubeconfig=Amadeus.kubeconfig
```

设置将配置的授权文件添加到集群

```bash
kubectl config use-context kubernetes --kubeconfig=Amadeus.kubeconfig
```

### 创建RBAC权限策略

yaml示例：使Amadeus用户仅有查看default命名空间下的pod

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] # api组，置空为核心组
  resources: ["pods"] # 资源
  verbs: ["get", "watch", "list"] # 对资源的操作
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: Amadeus # 绑定的用户名
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

测试验证

```
[root@k8s-node1 ~]# kubectl apply -f rbac.yaml
role.rbac.authorization.k8s.io/pod-reader created
rolebinding.rbac.authorization.k8s.io/read-pods created

# pod可以正常查看
[root@k8s-node1 ~]# kubectl --kubeconfig=/root/Amadeus.kubeconfig get pods
NAME                                      READY   STATUS    RESTARTS        AGE
nfs-client-provisioner-66d6cb77fd-k2n9l   1/1     Running   7 (4h53m ago)   30h
pod-configmap                             1/1     Running   0               3h6m
pod-secret-demo                           1/1     Running   0               127m

# 其他资源都没有权限
[root@k8s-node1 ~]# kubectl --kubeconfig=/root/Amadeus.kubeconfig get nodes
Error from server (Forbidden): nodes is forbidden: User "Amadeus" cannot list resource "nodes" in API group "" at the cluster scope
[root@k8s-node1 ~]# kubectl --kubeconfig=/root/Amadeus.kubeconfig get deployment
Error from server (Forbidden): deployments.apps is forbidden: User "Amadeus" cannot list resource "deployments" in API group "apps" in the namespace "default"
```

给该用户增加查看和删除deployment的权限，但pod的权限依旧只有查看

```
[root@k8s-node1 ~]# vim rbac.yaml
# 在rbac.yaml中增加如下规则
- apiGroups: ["apps"]
  resources: ["deployments"] 
  verbs: ["get", "watch", "list", "delete"] 

[root@k8s-node1 ~]# kubectl apply -f rbac.yaml
role.rbac.authorization.k8s.io/pod-reader configured
rolebinding.rbac.authorization.k8s.io/read-pods unchanged

[root@k8s-node1 ~]# kubectl --kubeconfig=/root/Amadeus.kubeconfig get deployment
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
nfs-client-provisioner   1/1     1            1           30h
```

# 网络策略(Network Policy)

## 基础概念

网络策略（Network Policy），用于限制Pod出入流量，提供Pod级别和Namespace级别网络访问控制。

一些应用场景：

- 应用程序间的访问控制。例如微服务A允许访问微服务B，微服务C不能访问微服务A 

- 开发环境命名空间不能访问测试环境命名空间Pod

- 当Pod暴露到外部时，需要做Pod白名单

- 多租户网络环境隔离

Pod网络入口方向隔离：

- 基于Pod级网络隔离：只允许特定对象访问Pod（使用标签定义），允许白名单上的IP地址或者IP段访问Pod

- 基于Namespace级网络隔离：多个命名空间，A和B命名空间Pod完全隔离。

Pod网络出口方向隔离：

- 拒绝某个Namespace上所有Pod访问外部

- 基于目的IP的网络隔离：只允许Pod访问白名单上的IP地址或者IP段 

- 基于目标端口的网络隔离：只允许Pod访问白名单上的端

## 实际应用

示例一：只允许default命名空间中携带run=client1标签的Pod访问default命名空间携带app=web标签的Pod的80端口，无法ping通

```
[root@k8s-node1 ~]# kubectl create deployment web --image=nginx:1.19
[root@k8s-node1 ~]# kubectl run client1 --image=busybox -- sleep 36000
[root@k8s-node1 ~]# kubectl run client2 --image=busybox -- sleep 36000
[root@k8s-node1 ~]# kubectl get pods --show-labels
NAME                                      READY   STATUS    RESTARTS        AGE    LABELS
client1                                   1/1     Running   0               69s    run=client1
client2                                   1/1     Running   0               62s    run=client2
web-bc7cc9f65-5mg9d                       1/1     Running   0               2m3s   app=web,pod-template-hash=bc7cc9f65
```

networkpolicy.yaml示例

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          project: default
    - podSelector:
        matchLabels:
          run: client1
    ports:
    - protocol: TCP
      port: 80
```

测试验证

```
[root@k8s-node1 ~]# kubectl apply -f networkpolicy.yaml
[root@k8s-node1 ~]# kubectl get networkpolicy
[root@k8s-node1 ~]# kubectl get pods  web-bc7cc9f65-hdhr2 -o jsonpath='{.metadata.annotations.cni\.projectcalico\.org\/podIP}'
10.244.169.169/32

[root@k8s-node1 ~]# kubectl exec -it client1 -- telnet 10.244.169.169 80
Connected to 10.244.169.169

[root@k8s-node1 ~]# kubectl exec -it client2 -- telnet 10.244.169.169 80
# 超时无法联通

[root@k8s-node1 ~]# kubectl delete -f networkpolicy.yaml
```

示例二：ns1命名空间下所有pod可以互相访问，也可以访问其他命名空间Pod，但其他命名空间不能访问ns1命名空间Pod。

```
[root@k8s-node1 ~]# kubectl create ns ns1
[root@k8s-node1 ~]# kubectl run ns1-client1 --image=busybox -n ns1 -- sleep 36000
[root@k8s-node1 ~]# kubectl run ns1-client2 --image=busybox -n ns1 -- sleep 36000
[root@k8s-node1 ~]# kubectl get pods -n ns1 -o wide
NAME          READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
ns1-client1   1/1     Running   0          78s   10.244.169.168   k8s-node2   <none>           <none>
ns1-client2   1/1     Running   0          70s   10.244.107.212   k8s-node3   <none>           <none>
[root@k8s-node1 ~]# kubectl get pods -o wide
NAME                                      READY   STATUS    RESTARTS        AGE   IP               NODE        NOMINATED NODE   READINESS GATES
client1                                   1/1     Running   0               51s   10.244.169.171   k8s-node2   <none>           <none>
client2                                   1/1     Running   0               26m   10.244.107.238   k8s-node3   <none>           <none>
```

networkpolicy.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: ns1
spec:
  podSelector: {} # 置空表示默认所有Pod
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {} # 置空表示拒绝所有
```

验证

```
[root@k8s-node1 ~]# kubectl apply -f networkpolicy.yaml
[root@k8s-node1 ~]# kubectl get networkpolicy -n ns1

# ns1命名空间内pod可以互通
[root@k8s-node1 ~]# kubectl exec -it ns1-client1 -n ns1 -- ping 10.244.107.212 # ns1-client2
PING 10.244.107.212 (10.244.107.212): 56 data bytes
64 bytes from 10.244.107.212: seq=0 ttl=62 time=0.900 ms
64 bytes from 10.244.107.212: seq=1 ttl=62 time=0.651 ms

# default命名空间的pod无法访问ns1命名空间的pod
[root@k8s-node1 ~]# kubectl exec -it client1 -- ping 10.244.107.212 # ns1-client2

# ns1命名空间的pod可以正常访问default命名空间的pod
[root@k8s-node1 ~]# kubectl exec -it ns1-client1 -n ns1 -- ping 10.244.169.171 # client1
PING 10.244.169.171 (10.244.169.171): 56 data bytes
64 bytes from 10.244.169.171: seq=0 ttl=63 time=0.119 ms
64 bytes from 10.244.169.171: seq=1 ttl=63 time=0.067 ms

[root@k8s-node1 ~]# kubectl delete -f networkpolicy.yaml
```

