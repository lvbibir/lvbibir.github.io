---
title: "kubernetes | kubeadm 搭建 K8s 集群 v1.22.3" 
date: 2021-10-01
lastmod: 2024-01-28
tags:
  - kubernetes
keywords:
  - linux
  - centos
  - kubernetes
description: "介绍 kubernetes, 并在 centos 中使用 kubeadm 快速搭建 k8s 集群 v1.22.3、安装cni组件" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
---

# 1 Kubernetes 概述

kubernetes 是什么

- kubernetes 是 Google 在 2014 年开源的一个容器集群管理平台，kubernetes 简称 k8s
- k8s 用于容器化应用程序的部署，扩展和管理。
- k8s 提供了容器的编排，资源调度，弹性伸缩，部署管理，服务发现等一系列功能
- kubernetes 目标是让部署容器化应用简单高效

Kubernetes 特性

- 自我修复
    - 在节点故障时重新启动失败的容器，替换和重新部署，保证预期的副本数量；杀死健康检查失败的容器，并且在未准备好之前不会处理客户端请求，确保线上服务不中断。
- 伸缩性
    - 使用命令、UI 或者基于 CPU 使用情况自动快速扩容和缩容应用程序实例，保证应用业务高峰并发时的高可用性；业务低峰时回收资源，以最小成本运行服务。
- 自动部署和回滚
    - K8S 采用滚动更新策略更新应用，一次更新一个 Pod，而不是同时删除所有 Pod，如果更新过程中出现问题，将回滚更改，确保升级不受影响业务。
- 服务发现和负载均衡
    - K8S 为多个容器提供一个统一访问入口（内部 IP 地址和一个 DNS 名称），并且负载均衡关联的所有容器，使得用户无需考虑容器 IP 问题。
- 机密和配置管理
    - 管理机密数据和应用程序配置，而不需要把敏感数据暴露在镜像里，提高敏感数据安全性。并可以将一些常用的配置存储在 K8S 中，方便应用程序使用。
- 存储编排
    - 挂载外部存储系统，无论是来自本地存储，公有云（如 AWS），还是网络存储（如 NFS、GlusterFS、Ceph）都作为集群资源的一部分使用，极大提高存储使用灵活性。
- 批处理
    - 提供一次性任务，定时任务；满足批量数据处理和分析的场景。

Kubeadm 概述

- `kubeadm` 是 `Kubernetes` 项目自带的及集群构建工具，负责执行构建一个最小化的可用集群以及将其启动等的必要基本步骤，`kubeadm` 是 `Kubernetes` 集群全生命周期的管理工具，可用于实现集群的部署、升级、降级及拆除。`kubeadm` 部署 `Kubernetes` 集群是将大部分资源以 `pod` 的方式运行，例如（`kube-proxy`、`kube-controller-manager`、`kube-scheduler`、`kube-apiserver`、`flannel`) 都是以 `pod` 方式运行。
- `Kubeadm` 仅关心如何初始化并启动集群，余下的其他操作，例如安装 `Kubernetes Dashboard`、监控系统、日志系统等必要的附加组件则不在其考虑范围之内，需要管理员自行部署。
- `Kubeadm` 集成了 `Kubeadm init` 和 `kubeadm join` 等工具程序，其中 `kubeadm init` 用于集群的快速初始化，其核心功能是部署 Master 节点的各个组件，而 `kubeadm join` 则用于将节点快速加入到指定集群中，它们是创建 `Kubernetes` 集群最佳实践的“快速路径”。另外，`kubeadm token` 可于集群构建后管理用于加入集群时使用的认证令牌（`token`)，而 `kubeadm reset` 命令的功能则是删除集群构建过程中生成的文件以重置回初始状态。

![img](https://image.lvbibir.cn/blog/828019-20201006171931291-1034333699.png)

# 2 环境准备

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

部署 Kubernetes 集群需要满足每个节点至少满足 2 核 CPU、2G 内存和 30GB 硬盘且都可以访问外网

| 角色      | IP      |
| --------- | ------- |
| k8s-node1 | 1.1.1.1 |
| k8s-node2 | 1.1.1.2 |
| k8s-node3 | 1.1.1.3 |

## 2.1 基础配置

```bash
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭selinux
sed -i 's/enforcing/disabled/' /etc/selinux/config  # 永久
setenforce 0  # 临时

# 关闭swap
swapoff -a  # 临时
vim /etc/fstab  # 永久, 注释掉swap分区相关行

# 设置主机名
hostnamectl set-hostname <hostname>

# 添加hosts
cat >> /etc/hosts << EOF
1.1.1.1 k8s-node1
1.1.1.2 k8s-node2
1.1.1.3 k8s-node3
EOF

# 将桥接的IPv4流量传递到iptables的链
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system  # 生效

# 时间同步
timedatectl set-timezone Asia/Shanghai
yum install ntpdate -y
ntpdate time.windows.com
```

## 2.2 安装 Docker

Kubernetes 默认 CRI（容器运行时）为 Docker，因此先安装 Docker。

```bash
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum list docker-ce --show-duplicates
yum install docker-ce-20.10.23-3.el7.x86_64
```

配置镜像下载加速器，同时修改 docker 的 cgroupdriver 为 systemd

```bash
mkdir /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://jc0srqak.mirror.aliyuncs.com"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl daemon-reload
systemctl enable docker && systemctl start docker
docker info
```

## 2.3 kubeadm/kubelet/kubectl

添加阿里云 YUM 软件源

```bash
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

这里指定版本号部署

```bash
yum install -y kubelet-1.22.3 kubeadm-1.22.3 kubectl-1.22.3
systemctl enable kubelet
systemctl start kubelet
```

# 3 部署 Kubernetes Master

[官方文档 1](https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file) [官方文档 2](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node)

在 1.1.1.1（Master）执行

```bash
kubeadm init \
--apiserver-advertise-address=1.1.1.1 \
--kubernetes-version v1.22.3 \
--service-cidr=10.96.0.0/12 \
--pod-network-cidr=10.244.0.0/16 \
--ignore-preflight-errors=all \
--image-repository registry.aliyuncs.com/google_containers 
```

- --apiserver-advertise-address 集群通告地址
- --kubernetes-version K8s 版本，与上面安装的一致
- --service-cidr 集群内部虚拟网络，Pod 统一访问入口
- --pod-network-cidr Pod 网络，与下面部署的 CNI 网络组件 yaml 中保持一致
- --ignore-preflight-errors=all，跳过一些错误
- --image-repository 由于默认拉取镜像地址 k8s.gcr.io 国内无法访问，这里指定阿里云镜像仓库地址

或者使用配置文件引导：

```bash
cat > kubeadm.conf << EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.22.3
imageRepository: registry.aliyuncs.com/google_containers 
networking:
  podSubnet: 10.244.0.0/16 
  serviceSubnet: 10.96.0.0/12 
EOF

kubeadm init --config kubeadm.conf --ignore-preflight-errors=all  
```

拷贝 kubectl 使用的连接 k8s 认证文件到默认路径：

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

查看 k8s 集群状态

```bash
kubectl get cs
NAME                 STATUS      MESSAGE                                                                                       ERROR
scheduler            Unhealthy   Get "http://127.0.0.1:10251/healthz": dial tcp 127.0.0.1:10251: connect: connection refused
controller-manager   Healthy     ok                                                                      
etcd-0               Healthy     {"health":"true","reason":""}   

vim /etc/kubernetes/manifests/kube-scheduler.yaml
# 注释掉 --port=0 ，scheduler会自动重启，稍等一小会状态变为正常

kubectl get cs
NAME                 STATUS    MESSAGE                         ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true","reason":""}
```

# 4 加入 Kubernetes Node

[官方文档](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/)

在 192.168.150.102/103（Node）执行。

向集群添加新节点，执行在 kubeadm init 输出的 kubeadm join 命令：

```bash
kubeadm join 1.1.1.1:6443 --token esce21.q6hetwm8si29qxwn \
--discovery-token-ca-cert-hash sha256:00603a05805807501d7181c3d60b478788408cfe6cedefedb1f97569708be9c5
```

默认 token 有效期为 24 小时，当过期之后，该 token 就不可用了。这时就需要重新创建 token，操作如下：

```bash
kubeadm token create
kubeadm token list

openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
63bca849e0e01691ae14eab449570284f0c3ddeea590f8da988c07fe2729e924

kubeadm join 1.1.1.1:6443 --token nuja6n.o3jrhsffiqs9swnu --discovery-token-ca-cert-hash 
sha256:63bca849e0e01691ae14eab449570284f0c3ddeea590f8da988c07fe2729e924
```

或者直接命令快捷生成: `kubeadm token create --print-join-command`

# 5 部署容器网络 (cni)

Calico 是一个纯三层的数据中心网络方案，Calico 支持广泛的平台，包括 Kubernetes、OpenStack 等。

Calico 在每一个计算节点利用 Linux Kernel 实现了一个高效的虚拟路由器（ vRouter） 来负责数据转发，而每个 vRouter 通过 BGP 协议负责把自己上运行的 workload 的路由信息向整个 Calico 网络内传播。

此外，Calico 项目还实现了 Kubernetes 网络策略，提供 ACL 功能。

[quickstart](https://docs.projectcalico.org/getting-started/kubernetes/quickstart)

[版本对照表](https://docs.tigera.io/archive/v3.23/getting-started/kubernetes/requirements)，在此页面可以看到 calico 每个版本支持的 kubernetes 的版本

安装 calico

```bash
wget --no-check-certificate https://docs.tigera.io/archive/v3.23/manifests/calico.yaml
```

修改 Pod 网络和网卡识别参数，Pod 网络与前面 kubeadm init 指定的一样

```bash
[root@k8s-node1 ~]# vim calico.yaml
# 修改位置：DaemonSet.spec.template.spec.containers.env
# 新增如下四行
- name: CALICO_IPV4POOL_CIDR
  value: "10.244.0.0/16"
- name: IP_AUTODETECTION_METHOD
  value: interface=bond*,ens* #网卡名根据实际情况修改

kubectl apply -f calico.yaml
kubectl get pods -n kube-system

# 所有Pod起来后，节点状态应该都是Ready状态了
[root@k8s-node1 ~]# kubectl get nodes
NAME        STATUS   ROLES                  AGE    VERSION
k8s-node1   Ready    control-plane,master   153m   v1.22.3
k8s-node2   Ready    <none>                 151m   v1.22.3
k8s-node3   Ready    <none>                 151m   v1.22.3
```

# 6 metric-server

cadvisor 负责提供数据，已集成到 k8s 中

Metrics-server 负责数据汇总，需额外安装

![Snipaste_2022-10-02_09-04-36](https://image.lvbibir.cn/blog/Snipaste_2022-10-02_09-04-36.png)

下载 yaml

```bash
wget --no-check-certificate https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.0/components.yaml 
mv components.yaml metrics-server.yaml
```

修改 yaml

```yaml
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP # 第一处修改
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls # 第二处修改
        image: registry.aliyuncs.com/google_containers/metrics-server:v0.6.0 # 第三处修改
        imagePullPolicy: IfNotPresent
```

- `--kubelet-insecure-tls`
    - 不验证 kubelet 自签的证书
- `--kubelet-preferred-address-types=InternalIP
    - Metrics-server 连接 cadvisor 默认通过主机名即 node 的名称进行连接，而 Metric-server 作为 pod 运行在集群中默认是无法解析的，所以这里修改成通过节点 ip 连接

部署 metrics-server

```bash
[root@k8s-node1 ~]# kubectl apply -f metrics-server.yaml
[root@k8s-node1 ~]# kubectl get pods -n kube-system -l k8s-app=metrics-server
NAME                              READY   STATUS    RESTARTS   AGE
metrics-server-7f66b69ff6-bkfqg   1/1     Running   0          59s
[root@k8s-node1 ~]# kubectl top nodes
NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k8s-node1   226m         11%    2004Mi          54%
k8s-node2   97m          4%     1047Mi          28%
k8s-node3   98m          4%     1096Mi          29%
```

# 7 测试 kubernetes 集群

- 验证 Pod 工作
- 验证 Pod 网络通信
- 验证 DNS 解析

在 Kubernetes 集群中创建一个 pod，验证是否正常运行：

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80  --target-port=80
[root@k8s-node1 ~]# kubectl get pod,deploy,svc
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-6799fc88d8-57bqd   1/1     Running   0          10m

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           10m

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        170m
service/nginx        NodePort    10.102.188.108   <none>        80:30954/TCP   2m31s
```

访问地址：<http://1.1.1.1:30954>，端口是固定的，ip 可以是集群内任一节点的 ip

# 8 部署 Dashboard

```bash
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
```

默认 Dashboard 只能集群内部访问，修改 Service 为 NodePort 类型，暴露到外部：

```bash
vi recommended.yaml
...
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort
...

kubectl apply -f recommended.yaml

kubectl get pods -n kubernetes-dashboard
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-6b4884c9d5-gl8nr   1/1     Running   0          13m
kubernetes-dashboard-7f99b75bf4-89cds        1/1     Running   0          13m
```

访问地址：https://NodeIP:30001

创建 service account 并绑定默认 cluster-admin 管理员集群角色：

```bash
# 创建用户
kubectl create serviceaccount dashboard-admin -n kube-system
# 用户授权
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 获取用户Token
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
```

使用输出的 token 登录 Dashboard。

以上
