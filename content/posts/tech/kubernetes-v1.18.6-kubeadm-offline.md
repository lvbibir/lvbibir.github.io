---
title: "kubeadm 搭建 k8s 集群 [离线版] v1.18.6" 
date: 2021-10-01
lastmod: 2021-10-01
tags: 
- linux
- centos
- kubernetes
keywords:
- linux
- centos
- kubernetes
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png" 
---


# 环境规划

| 操作系统          | IP           | CPU/MEM | 主机名     | 角色      |
| ----------------- | ------------ | ------- | ---------- | --------- |
| CentOS 7.7-x86_64 | 192.168.1.14 | 2/4G    | k8s-master | Master    |
| CentOS 7.7-x86_64 | 192.168.1.15 | 2/4G    | k8s-node1  | Work node |
| CentOS 7.7-x86_64 | 192.168.1.16 | 2/4G    | k8s-node2  | Work node |

【软件包版本号】

| name       | version    |
| ---------- | ---------- |
| Docker     | 3:19.03.13 |
| kubeadm    | v1.18.6    |
| kubernetes | v1.18.6    |

安装前提条件

- Centos 7.x 最小化安装
- 时钟同步

下载离线程序包

> 链接：https://pan.baidu.com/s/1Q3jbJcgq0rH8jK-LTpa6Vg
> 提取码：hhhh

# 部署Master节点

1. **执行自动安装脚本**

将下载到的程序包拷贝到 k8s-master 节点解压，我这里的master节点是 192.168.1.14

```shell
[root@localhost ~]# ip a | egrep global
    inet 192.168.1.14/24 brd 192.168.1.255 scope global noprefixroute eth0
[root@localhost ~]# ls
anaconda-ks.cfg  k8s-kubeadm.tar.gz
[root@localhost ~]# tar xf k8s-kubeadm.tar.gz
[root@localhost ~]# cd k8s-kubeadm
[root@localhost k8s-kubeadm]# ls
docker-ce-19.03.12.tar.gz  flannel-v0.12.0-linux-amd64.tar.gz  install.sh  k8s-imagesV1.18.6.tar.gz  k8s-V1.18.6.tar.gz  kube-flannel.yml packages.tar.gz
# 执行脚本 ./install.sh [主机名]
[root@localhost k8s-kubeadm]# ./install.sh k8s-master
```

等待脚本执行自动安装。。。

执行完毕后，会出现以下提示：

[![img](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171930922-2104593063.png)](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171930922-2104593063.png)

因为内核进行了升级，请重启服务器。

[![img](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171930656-34274130.png)](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171930656-34274130.png)

重启以后，内核版本更新为 `5.8.13`

1. **使用 kubeadm 初始化集群**

```shell
kubeadm init --kubernetes-version=v1.18.6 --apiserver-advertise-address=192.168.1.14 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12
```

等待集群初始化完成。。。

[![img](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171930352-470109468.png)](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171930352-470109468.png)

```shell
kubeadm join 192.168.1.14:6443 --token utml0h.gj2nafii8xm1512e \
    --discovery-token-ca-cert-hash sha256:e91fb35667cf51c76b9afa288e4416a1314a1244158123ffbcee55b7ac4a70d4
```

上面命令记录下来，这是将 node 节点加入到 集群的执行操作命令。

出现如上提示，集群初始化成功，执行提示命令：

```shell
[root@k8s-master ~]# mkdir -p $HOME/.kube
[root@k8s-master ~]# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[root@k8s-master ~]# chown $(id -u):$(id -g) $HOME/.kube/config
```

使用 kubectl 查看 nodes

```shell
[root@k8s-master ~]# kubectl get nodes
NAME         STATUS     ROLES    AGE   VERSION
k8s-master   NotReady   master   74s   v1.18.6
```

1. **初始化网络插件 flannel**

```shell
# 进入压缩后的目录里
[root@k8s-master ~]# cd k8s-kubeadm/
# 开始进行 flannel 初始化安装
[root@k8s-master k8s-kubeadm]# kubectl apply -f kube-flannel.yml
podsecuritypolicy.policy/psp.flannel.unprivileged created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
```

flannel 初始化完成后，查看 nodes 状态：

```shell
[root@k8s-master k8s-kubeadm]# kubectl get nodes
NAME         STATUS   ROLES    AGE     VERSION
k8s-master   Ready    master   3m58s   v1.18.6
```

到此，通过 kubeadm 初始化安装 master 节点完毕。接下来是 node 节点就很简单。

# 部署node节点

1. 将下载的压缩包拷贝到 node 节点执行

```shell
[root@k8s-master ~]# scp k8s-kubeadm.tar.gz 192.168.1.15:/root/

------以下node节点执行------
[root@localhost ~]# ls
anaconda-ks.cfg  k8s-kubeadm.tar.gz
[root@localhost ~]# tar xf k8s-kubeadm.tar.gz
[root@localhost ~]# cd k8s-kubeadm/
# ./install.sh 主机名
[root@localhost k8s-kubeadm]# ./install.sh k8s-node1
```

这里和上面 master 初始化一样，完成后重启主机。

[![img](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171930087-1054624258.png)](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171930087-1054624258.png)

1. 重启完成后，执行 join 命令加入集群

```shell
# 就是上面记录的命令
kubeadm join 192.168.1.14:6443 --token utml0h.gj2nafii8xm1512e \
    --discovery-token-ca-cert-hash sha256:e91fb35667cf51c76b9afa288e4416a1314a1244158123ffbcee55b7ac4a70d4
```

[![img](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171929732-1855734873.png)](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171929732-1855734873.png)

1. 切换到 k8s-master 查看 k8s-node1 是否加入集群

[![img](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171929194-630188569.png)](https://img2020.cnblogs.com/blog/828019/202010/828019-20201006171929194-630188569.png)

k8s-node1 成功加入集群，剩下的 node 节点都是一样的操作。

到此，通过 kubeadm 搭建 k8s 环境已经完成。

# k8s 集群简单测试

> 注意：本节测试需要网络拉取镜像，可以通过网络将 镜像拷贝到主机里 所需镜像： nginx:alpine / busybox

这里做一个简单的小测试来证明集群是健康正常运行的。

1. 创建一个 nginx pod

```shell
[root@k8s-master ~]# kubectl run nginx-deploy --image=nginx:alpine
pod/nginx-deploy created
[root@k8s-master ~]# kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
nginx-deploy   1/1     Running   0          11s
[root@k8s-master ~]# kubectl get pods -o wide
NAME           READY   STATUS    RESTARTS   AGE   IP           NODE        NOMINATED NODE   READINESS GATES
nginx-deploy   1/1     Running   0          18s   10.244.1.2   k8s-node1   <none>           <none>
```

1. 为 nginx pod 创建一个服务

```shell
[root@k8s-master ~]# kubectl expose pod nginx-deploy --name=nginx --port=80 --target-port=80 --protocol=TCP
service/nginx exposed
[root@k8s-master ~]# kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   21m
nginx        ClusterIP   10.106.14.253   <none>        80/TCP    9s
[root@k8s-master ~]# curl 10.106.14.253
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

1. 创建一个 busybox pod 来通过 nginx 服务名访问

```shell
[root@k8s-master ~]# kubectl run client --image=busybox -it
If you don't see a command prompt, try pressing enter.

------ 通过服务名来访问 nginx 服务 ------ 
/ # wget -O - -q nginx
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

/ # cat /etc/resolv.conf
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

测试通过，网络及dns服务正常。集群处于正常健康状态。

# 参考

https://www.cnblogs.com/hukey/p/13773927.html
