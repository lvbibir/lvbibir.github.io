---
title: "kubeadm快速搭建K8s集群v1.22.3" 
date: 2021-10-01
lastmod: 2021-10-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- k8s
description: "" 
weight: 
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: "" #图片路径：posts/tech/文章1/picture.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
---
# 前言

kubeadm是官方社区推出的一个用于快速部署kubernetes集群的工具。

这个工具能通过两条指令完成一个kubernetes集群的部署：

```
# 创建一个 Master 节点
$ kubeadm init

# 将一个 Node 节点加入到当前集群中
$ kubeadm join <Master节点的IP和端口 >
```

# 1. 安装要求

在开始之前，部署Kubernetes集群机器需要满足以下几个条件：

- 一台或多台机器，操作系统 CentOS7.x-86_x64
- 硬件配置：2GB或更多RAM，2个CPU或更多CPU，硬盘30GB或更多
- 集群中所有机器之间网络互通
- 可以访问外网，需要拉取镜像
- 禁用swap分区

# 2. 准备环境

 ![kubernetesæ¶æå¾](https://blog-1252881505.cos.ap-beijing.myqcloud.com/k8s/single-master.jpg) 

| 角色       | IP              |
| ---------- | --------------- |
| k8s-master | 192.168.150.101 |
| k8s-node1  | 192.168.150.102 |
| k8s-node2  | 192.168.150.103 |

```
关闭防火墙：
$ systemctl stop firewalld
$ systemctl disable firewalld

关闭selinux：
$ sed -i 's/enforcing/disabled/' /etc/selinux/config  # 永久
$ setenforce 0  # 临时

关闭swap：
$ swapoff -a  # 临时
$ vim /etc/fstab  # 永久
注释掉swap分区相关行

设置主机名：
$ hostnamectl set-hostname <hostname>

在master添加hosts：
$ cat >> /etc/hosts << EOF
192.168.150.101 k8s-master
192.168.150.102 k8s-node1
192.168.150.103 k8s-node2
EOF

将桥接的IPv4流量传递到iptables的链：
$ cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
$ sysctl --system  # 生效

时间同步：
$ yum install ntpdate -y
$ ntpdate time.windows.com
```

# 3. 安装 Docker/kubeadm/kubelet/kubectl (所有节点)

Kubernetes默认CRI（容器运行时）为Docker，因此先安装Docker。

## 3.1 安装Docker

```
$ wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
$ yum -y install docker-ce
$ systemctl enable docker && systemctl start docker
```

## 3.2 配置镜像下载加速器，同时修改docker的cgroupdriver为systemd

```
$ cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://jc0srqak.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
$ systemctl restart docker
$ docker info
```

## 3.3 添加阿里云YUM软件源

```
$ cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

## 3.4 安装kubeadm，kubelet和kubectl

由于版本更新频繁，这里指定版本号部署：

```
$ yum install -y kubelet-1.22.3 kubeadm-1.22.3 kubectl-1.22.3
$ systemctl enable kubelet
$ systemctl start kubelet
```

# 4. 部署Kubernetes Master

https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file 

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node 

在192.168.150.101（Master）执行。

```
    $ kubeadm init \
      --apiserver-advertise-address=192.168.150.101 \
      --kubernetes-version v1.22.3 \
      --service-cidr=10.96.0.0/12 \
      --pod-network-cidr=10.244.0.0/16 \
      --ignore-preflight-errors=all \
      --image-repository registry.aliyuncs.com/google_containers 
```

- --apiserver-advertise-address 集群通告地址
- --kubernetes-version K8s版本，与上面安装的一致
- --service-cidr 集群内部虚拟网络，Pod统一访问入口
- --pod-network-cidr Pod网络，与下面部署的CNI网络组件yaml中保持一致
- --ignore-preflight-errors=all，跳过一些错误
- --image-repository  由于默认拉取镜像地址k8s.gcr.io国内无法访问，这里指定阿里云镜像仓库地址

或者使用配置文件引导：

```
$ vi kubeadm.conf
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.22.3
imageRepository: registry.aliyuncs.com/google_containers 
networking:
  podSubnet: 10.244.0.0/16 
  serviceSubnet: 10.96.0.0/12 

$ kubeadm init --config kubeadm.conf --ignore-preflight-errors=all  
```

拷贝kubectl使用的连接k8s认证文件到默认路径：

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

$ kubectl get nodes
NAME         STATUS   ROLES    AGE   VERSION
k8s-master   Ready    master   2m   v1.18.0
```

# 5. 加入Kubernetes Node

在192.168.150.102/103（Node）执行。

向集群添加新节点，执行在kubeadm init输出的kubeadm join命令：

```
$ kubeadm join 192.168.150.101:6443 --token esce21.q6hetwm8si29qxwn \
    --discovery-token-ca-cert-hash sha256:00603a05805807501d7181c3d60b478788408cfe6cedefedb1f97569708be9c5
```

默认token有效期为24小时，当过期之后，该token就不可用了。这时就需要重新创建token，操作如下：

```
$ kubeadm token create
$ kubeadm token list
$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
63bca849e0e01691ae14eab449570284f0c3ddeea590f8da988c07fe2729e924

$ kubeadm join 192.168.150.101:6443 --token nuja6n.o3jrhsffiqs9swnu --discovery-token-ca-cert-hash sha256:63bca849e0e01691ae14eab449570284f0c3ddeea590f8da988c07fe2729e924
```

或者直接命令快捷生成：kubeadm token create --print-join-command

<https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/>

# 6. 部署容器网络（CNI）

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network 

注意：只需要部署下面其中一个，推荐Calico。

Calico是一个纯三层的数据中心网络方案，Calico支持广泛的平台，包括Kubernetes、OpenStack等。

Calico 在每一个计算节点利用 Linux Kernel 实现了一个高效的虚拟路由器（ vRouter） 来负责数据转发，而每个 vRouter 通过 BGP 协议负责把自己上运行的 workload 的路由信息向整个 Calico 网络内传播。

此外，Calico  项目还实现了 Kubernetes 网络策略，提供ACL功能。

 https://docs.projectcalico.org/getting-started/kubernetes/quickstart 

```
$ wget https://docs.projectcalico.org/manifests/calico.yaml
```

下载完后还需要修改里面定义Pod网络（CALICO_IPV4POOL_CIDR），与前面kubeadm init指定的一样

修改完后应用清单：

```
$ kubectl apply -f calico.yaml
$ kubectl get pods -n kube-system
```

# 7. 测试kubernetes集群

- 验证Pod工作
- 验证Pod网络通信
- 验证DNS解析

在Kubernetes集群中创建一个pod，验证是否正常运行：

```
$ kubectl create deployment nginx --image=nginx
$ kubectl expose deployment nginx --port=80 --type=NodePort
$ kubectl get pod,svc
```

访问地址：http://NodeIP:Port  

# 8. 部署 Dashboard

```
$ wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
```

默认Dashboard只能集群内部访问，修改Service为NodePort类型，暴露到外部：

```
$ vi recommended.yaml
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
$ kubectl apply -f recommended.yaml
$ kubectl get pods -n kubernetes-dashboard
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-6b4884c9d5-gl8nr   1/1     Running   0          13m
kubernetes-dashboard-7f99b75bf4-89cds        1/1     Running   0          13m
```
访问地址：https://NodeIP:30001

创建service account并绑定默认cluster-admin管理员集群角色：

```
# 创建用户
$ kubectl create serviceaccount dashboard-admin -n kube-system
# 用户授权
$ kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 获取用户Token
$ kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
```
使用输出的token登录Dashboard。

