---
title: "kubernetes | RBAC 鉴权和 NetworkPolicy" 
date: 2022-10-07
lastmod: 2024-01-28
tags:
  - kubernetes
keywords:
  - kubernetes
  - RBAC
  - networkPolicy
description: "介绍 kubernetes 中的安全框架、RBAC 鉴权和网络策略（Pod ACL)" 
cover:
    image: "images/kubernetes.png"
---

# 0 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# 1 kubernetes 安全框架

- 客户端要想访问 K8s 集群 `API Server`，一般需要 CA 证书、Token 或者用户名 + 密码
- 如果 Pod 访问，需要 `ServiceAccount`

K8S 安全控制框架主要由下面 3 个阶段进行控制，每一个阶段都支持插件方式，通过 `API Server` 配置来启用插件。

1. Authentication（鉴权）
2. Authorization（授权）
3. Admission Control（准入控制）

![image-20221007174309826](/images/image-20221007174309826.png)

## 1.1 鉴权 (Authentication)

三种客户端身份认证：

- HTTPS 证书认证：基于 CA 证书签名的数字证书认证
- HTTP Token 认证：通过一个 Token 来识别用户
- HTTP Base 认证：用户名 + 密码的方式认证

## 1.2 授权 (Authorization)

RBAC（Role-Based Access Control，基于角色的访问控制）：负责完成授权（Authorization）工作。

RBAC 根据 API 请求属性，决定允许还是拒绝。

比较常见的授权维度：

- user：用户名
- group：用户分组
- 资源，例如 pod、deployment
- 资源操作方法：get，list，create，update，patch，watch，delete
- 命名空间
- API 组

## 1.3 准入控制 (Admission Control)

Adminssion Control 实际上是一个准入控制器插件列表，发送到 API Server 的请求都需要经过这个列表中的每个准入控制器插件的检查，检查不通过，则拒绝请求

# 2 RBAC

> <https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/rbac/>

## 2.1 基础概念

RBAC（Role-Based Access Control，基于角色的访问控制），允许通过 Kubernetes API 动态配置策略。

角色

- Role：授权特定命名空间的访问权限
- ClusterRole：授权所有命名空间的访问权限

角色绑定

- RoleBinding：将角色绑定到主体（即 subject）
- ClusterRoleBinding：将集群角色绑定到主体

主体（subject）

- User：用户
- Group：用户组
- ServiceAccount：服务账号

![2022年10月7日184036](/images/2022%E5%B9%B410%E6%9C%887%E6%97%A5184036.png)

## 2.2 示例

为 Amadeus 用户授权 default 命名空间 Pod 读取权限

### 2.2.1 新建用户

新建一个 k8s 用户大概可以分为以下几步：

- 签发用户证书
  - 生成用户的证书 key
  - 通过用户的证书 key，生成用户的证书请求 (csr)
  - 通过 k8s api 的 ca 证书去签发用户的证书请求，生成用户的证书 (crt)
- 生成 kubeconfig 配置文件
  - kubectl config set-cluster //集群配置
  - kubectl config set-credentials //用户配置
  - kubectl config set-context //context 配置
  - kubectl config use-context //使用 context
- 使用新创建的用户
  - kubectl --kubecofig=`path` // 通过参数指定
  - KUBECONFIG=`path` kubectl // 通过环境变量指定，`path` 可以指定多个，用 `:` 连接，从而将多个配置文件合并在一起使用

### 2.2.2 签发用户证书

可以使用 `openssl` 或者 `cfssl` 进行签发，任选一种

```bash
[root@k8s-node1 ~]# mkdir -p /etc/kubernetes/users/Amadeus
[root@k8s-node1 ~]# cd /etc/kubernetes/users/Amadeus/
```

openssl

```bash
# 创建用户证书 key
[root@k8s-node1 Amadeus]# openssl genrsa -out Amadeus.key 2048
# 创建用户证书请求 (csr)，-subj 指定组和用户，其中 O 是组名，CN 是用户名
[root@k8s-node1 Amadeus]# openssl req -new -key Amadeus.key -out Amadeus.csr -subj "/O=hello/CN=Amadeus"
# 生成用户的证书 (crt)，使用 k8s 的 ca 签发用户证书
[root@k8s-node1 Amadeus]# openssl x509 -req -in Amadeus.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out Amadeus.crt -days 3650

[root@k8s-node1 Amadeus]# ls
Amadeus.crt  Amadeus.csr  Amadeus.key
```

cfssl

下载 cfssl 工具

```bash
wget --no-check-certificate https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssl_linux-amd64
wget --no-check-certificate https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssljson_linux-amd64
wget --no-check-certificate https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssl-certinfo_linux-amd64
chmod a+x cfssl*
mv cfssl_linux-amd64 /usr/bin/cfssl
mv cfssljson_linux-amd64 /usr/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo

[root@k8s-node1 ~]# cfssl version
Version: 1.2.0
Revision: dev
Runtime: go1.6
```

创建 ca-config.json 证书文件

```bash
cat > ca-config.json <<EOF
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
EOF
```

Amadeus-csr.json 证书文件

```bash
cat > Amadeus-csr.json <<EOF
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
EOF
```

生成证书

```bash
[root@k8s-node1 ~]# cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key -config=ca-config.json -profile=kubernetes Amadeus-csr.json | cfssljson -bare Amadeus
# 生成时会有警告，可以忽略，是因为提供的信息不是很全
[root@k8s-node1 ~]# ls Amadeus*
# 生成如下三个文件
Amadeus.csr      # csr
Amadeus-key.pem  # key
Amadeus.pem      # crt
```

配置 kubeconfig 配置文件

生成 kubeconfig 文件，并将 cluster 信息添加进去

```bash
kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/pki/ca.crt \
--embed-certs=true \
--server=https://1.1.1.1:6443 \
--kubeconfig=Amadeus.kubeconfig

# --embed-certs=true 表示将证书写入etcd
```

为 kubeconfig 配置文件添加用户配置：设置用户证书 (crt) 和证书 key

```bash
kubectl config set-credentials Amadeus \
--client-key=Amadeus-key.pem \
--client-certificate=Amadeus.pem \
--embed-certs=true \
--kubeconfig=Amadeus.kubeconfig
```

为 kubeconfig 配置文件添加 context

```bash
kubectl config set-context Amadeus@kubernetes \
--cluster=kubernetes \
--user=Amadeus \
--kubeconfig=Amadeus.kubeconfig
```

为 kubeconfig 配置文件设置使用的 context

```bash
kubectl config use-context Amadeus@kubernetes --kubeconfig=Amadeus.kubeconfig
```

查看生成的配置文件

```yaml
# KUBECONFIG=./Amadeus.kubeconfig kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://1.1.1.1:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: Amadeus
  name: Amadeus@kubernetes
current-context: Amadeus@kubernetes
kind: Config
preferences: {}
users:
- name: Amadeus
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```

### 2.2.3 创建 RBAC 权限策略

使 Amadeus 用户有权限查看 default 命名空间下的 pod

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

### 2.2.4 测试验证

```bash
[root@k8s-node1 ~]# kubectl apply -f demo-rbac.yml
role.rbac.authorization.k8s.io/pod-reader created
rolebinding.rbac.authorization.k8s.io/read-pods created

# pod可以正常查看
[root@k8s-node1 ~]# cp /etc/kubernetes/users/Amadeus/Amadeus.kubeconfig  /root/
[root@k8s-node1 ~]# KUBECONFIG=/root/Amadeus.kubeconfig kubectl get pods -n default
NAME                                      READY   STATUS    RESTARTS      AGE
bar-664fbc5498-kz4sr                      1/1     Running   0             18h
bar-664fbc5498-r74vl                      1/1     Running   0             18h
bar-664fbc5498-smqxm                      1/1     Running   0             18h
......

# 其他资源都没有权限
[root@k8s-node1 ~]# KUBECONFIG=/root/Amadeus.kubeconfig kubectl get nodes
Error from server (Forbidden): nodes is forbidden: User "Amadeus" cannot list resource "nodes" in API group "" at the cluster scope
[root@k8s-node1 ~]# KUBECONFIG=/root/Amadeus.kubeconfig kubectl get deployments
Error from server (Forbidden): deployments.apps is forbidden: User "Amadeus" cannot list resource "deployments" in API group "apps" in the namespace "default"
```

给该用户增加查看、创建和删除 deployment 的权限，但 pod 的权限依旧只有查看

```bash
[root@k8s-node1 ~]# vim demo-rbac.yml
# 在rbac.yaml中增加如下规则
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "watch", "list", "create", "delete"]

[root@k8s-node1 ~]# kubectl apply -f demo-rbac.yml
role.rbac.authorization.k8s.io/pod-reader configured
rolebinding.rbac.authorization.k8s.io/read-pods unchanged

# 操作 deployment
[root@k8s-node1 ~]# KUBECONFIG=/root/Amadeus.kubeconfig kubectl create deployment my-dep --image=nginx:1.22.1 --replicas=3
deployment.apps/my-dep created
[root@k8s-node1 ~]# KUBECONFIG=/root/Amadeus.kubeconfig kubectl get pods -l app=my-dep
NAME                    READY   STATUS    RESTARTS   AGE
my-dep-bc4cb798-4kbkq   1/1     Running   0          15s
my-dep-bc4cb798-jdzq7   1/1     Running   0          15s
my-dep-bc4cb798-lhm8p   1/1     Running   0          15s
[root@k8s-node1 ~]# KUBECONFIG=/root/Amadeus.kubeconfig kubectl delete deployment my-dep
deployment.apps "my-dep" deleted
```

# 3 网络策略 (Network Policy)

[官方文档](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)

## 3.1 基础概念

网络策略（Network Policy），用于限制 Pod 出入流量，提供 Pod 级别和 Namespace 级别网络访问控制。

一些应用场景：

- 应用程序间的访问控制。例如微服务 A 允许访问微服务 B，微服务 C 不能访问微服务 A
- 开发环境命名空间不能访问测试环境命名空间 Pod
- 当 Pod 暴露到外部时，需要做 Pod 白名单
- 多租户网络环境隔离

Pod 网络入口方向隔离：

- 基于 Pod 级网络隔离：只允许特定对象访问 Pod（使用标签定义），允许白名单上的 IP 地址或者 IP 段访问 Pod
- 基于 Namespace 级网络隔离：多个命名空间，A 和 B 命名空间 Pod 完全隔离。

Pod 网络出口方向隔离：

- 拒绝某个 Namespace 上所有 Pod 访问外部
- 基于目的 IP 的网络隔离：只允许 Pod 访问白名单上的 IP 地址或者 IP 段
- 基于目标端口的网络隔离：只允许 Pod 访问白名单上的端

## 3.2 示例一

只允许 default 命名空间中携带 run=client1 标签的 Pod 访问 default 命名空间携带 app=web 标签的 Pod 的 80 端口，无法 ping 通

```bash
[root@k8s-node1 ~]# kubectl create deployment web --image=nginx:1.22.1
[root@k8s-node1 ~]# kubectl run client1 --image=busybox:1.28 -- sleep 36000
[root@k8s-node1 ~]# kubectl run client2 --image=busybox:1.28 -- sleep 36000
[root@k8s-node1 ~]# kubectl get pods --show-labels
NAME                                      READY   STATUS    RESTARTS        AGE    LABELS
client1                                   1/1     Running   0               69s    run=client1
client2                                   1/1     Running   0               62s    run=client2
web-bc7cc9f65-5mg9d                       1/1     Running   0               2m3s   app=web,pod-template-hash=bc7cc9f65
```

networkpolicy.yaml 示例

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

```bash
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

## 3.3 示例二

ns1 命名空间下所有 pod 可以互相访问，也可以访问其他命名空间 Pod，但其他命名空间不能访问 ns1 命名空间 Pod。

```bash
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

```bash
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

以上
