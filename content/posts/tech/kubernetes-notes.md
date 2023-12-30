---
title: "kubernetes | 杂记" 
date: 2022-10-01
lastmod: 2023-04-08
tags: 
- kubernetes
keywords:
- kubernetes
description: "介绍一些常见的报错处理、kubectl命令的一些用法、yaml编写技巧、小优化等" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
---

# kubectl 命令的自动补全

```textile
yum install bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
```

# 镜像拉取策略

```textile
imagePullPolicy: Always|Never|IfNotPresent
```

# 修改 nodePort 范围

```bash
vim /etc/kubernetes/manifests/kube-apiserver.yaml
# spec.containers.command 增加
- --service-node-port-range=1-65535
```

# command 和 args

`containers.command` 等同于 Dockerfile 中的 `ENTRYPOINT`

`containers.args` 等同于 Dockerfile 中的 `CMD`

如果 Dockerfile 中默认的 ENTRYPOINT 被覆盖，则默认的 CMD 指令同时也会被覆盖

# label 标签选择运算符

> <https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/labels>

1. 基于等值

有三种运算符 `=` `==` `!=`

前两种是等效的，示例

```bash
[root@k8s-node1 ~]# kubectl get nodes -l kubernetes.io/hostname=k8s-node1
NAME        STATUS   ROLES                  AGE   VERSION
k8s-node1   Ready    control-plane,master   21d   v1.22.3
[root@k8s-node1 ~]# kubectl get nodes -l kubernetes.io/hostname!=k8s-node1
NAME        STATUS   ROLES    AGE   VERSION
k8s-node2   Ready    <none>   21d   v1.22.3
k8s-node3   Ready    <none>   21d   v1.22.3
```

1. 基于集合

同样三种运算符 `in` `notin` `exists`

`exists` 只用于判断 key 是否存在

```bash
hello in (foo, bar)    # 所有包含了 hello 标签且值等于 foo 或者 bar 的资源
hello notin (foo, bar) # 所有包含了 hello 标签且值不等于 foo 或者 bar 的资源；以及没有 hello 标签的资源
hello                  # 所有包含了 hello 标签的资源；不校验值
!hello                 # 所有未包含 hello 标签的资源；不校验值
```

示例

```bash
[root@k8s-node1 ~]# kubectl get nodes -l "kubernetes.io/hostname in (k8s-node1, k8s-node2)"
NAME        STATUS   ROLES                  AGE   VERSION
k8s-node1   Ready    control-plane,master   21d   v1.22.3
k8s-node2   Ready    <none>                 21d   v1.22.3
[root@k8s-node1 ~]# kubectl get nodes -l "kubernetes.io/hostname notin (k8s-node1, k8s-node2)"
NAME        STATUS   ROLES    AGE   VERSION
k8s-node3   Ready    <none>   21d   v1.22.3
[root@k8s-node1 ~]# kubectl get nodes -l kubernetes.io/hostname
NAME        STATUS   ROLES                  AGE   VERSION
k8s-node1   Ready    control-plane,master   21d   v1.22.3
k8s-node2   Ready    <none>                 21d   v1.22.3
k8s-node3   Ready    <none>                 21d   v1.22.3
[root@k8s-node1 ~]# kubectl get nodes -l \!kubernetes.io/hostname
No resources found
```

# 常见报错

## NodeNotReady

### Image garbage collection failed once

[参考地址](https://stackoverflow.com/questions/62020493/kubernetes-1-18-warning-imagegcfailed-error-failed-to-get-imagefs-info-unable-t?newreg=6012e8d3a8494d7d816cf2d6606ed1b2)

报错：

```textile
# kubectl describe node k8s-node01
Events:
  Type    Reason                   Age   From     Message
  ----    ------                   ----  ----     -------
  Normal  Starting                 11m   kubelet  Starting kubelet.
  Normal  NodeHasSufficientMemory  11m   kubelet  Node k8s-node01 status is now: NodeHasSufficientMemory
  Normal  NodeHasNoDiskPressure    11m   kubelet  Node k8s-node01 status is now: NodeHasNoDiskPressure
  Normal  NodeHasSufficientPID     11m   kubelet  Node k8s-node01 status is now: NodeHasSufficientPID
  Normal  NodeAllocatableEnforced  11m   kubelet  Updated Node Allocatable limit across pods
  
# journalctl -u kubelet | grep garbage
Mar 06 09:50:33 k8s-node01 kubelet[45471]: E0306 09:50:33.106476   45471 kubelet.go:1343] "Image garbage collection failed once. Stats initialization may not have completed yet" err="failed to get imageFs info: unable to find data in memory cache"
```

解决：

1. 未部署 CNI 组件

2. docker 镜像或容器未能正确删除导致的

```textile
docker system prune
systemctl stop kubelet
systemctl stop docker
systemctl start docker
systemctl start kubelet
```

## node 无法 ping 通 pod

所有 calico 的 pod 运行都是 running 状态, 使用 `calicoctl node status` 看到的网卡绑定也是没问题的.

calico 的 pod 有如下报错

```bash
[root@k8s-node1 ~]# kubectl logs calico-node-l66pn -n kube-system
2023-04-08 04:28:47.660 [INFO][65] felix/int_dataplane.go 1600: Received interface update msg=&intdataplane.ifaceUpdate{Name:"tunl0", State:"down", Index:4}
bird: Netlink: Network is down
bird: Netlink: Network is down
bird: Netlink: Network is down
bird: Netlink: Network is down
```

我这里是通过关闭 NetworkManager 解决的.关闭后 pod 日志立即就恢复正常了

```bash
[root@k8s-node1 ~]# systemctl stop NetworkManager
[root@k8s-node1 ~]# systemctl disable NetworkManager
```

## 虚拟机挂起导致 calico 网络不可用

出现在我的虚拟机测试机群上，挂起虚拟机过段时间后重新启动虚拟机，发现集群状态是正常的 (node 是 ready 状态)，然而 `calico-kube-controllers` `metric-server` `nfs-provisiner` 等功能组件陷入了 `CrashLoopBackOff` 状态，报错基本上都是无法连接到 `api-server`

但是 `calicoctl` 看到 calico 集群是没什么问题的，之前遇到几次都是暴躁重启 docker 解决的，后面发现重启 calico 相关容器就可以了，具体原因还没找到，估计与 vmware 虚拟机挂起操作有关。

```bash
kubectl delete pods -n kube-system -l "k8s-app in (calico-node, calico-kube-controllers)"
```

# kubectl 命令

一些常用命令

```textile
# 查看某个资源的详细信息
kubectl describe <type> <name> -n <namespace>
# 查看pod的日志
kubectl logs <pod> -n <namespace>
# 查看当前支持的api版本
kubectl api-versions
```

## get

options:

```bash
-w/--watch: # 实时更新，类似tail的-f选项
-o wide: # 查看更为详细的信息，比如ip和分配的节点
-o json: # 以json格式输出
-o jsonpath='{}' # 输出指定的json内容
-l key=vaule # 根据lable筛选
--show-lables # 显示资源的所有label
```

示例:

```bash
# 查看所有支持的资源
kubectl api-resources
# 查看service映射的pod的端口和ip
kubectl get cp/endpoints
# 查看pod
kubectl get pod <podname> -n <namespace>
  -o jsonpath='{.metadata.uid}' # 查看pod的id
# 查看指定pod的事件
kubectl get events --field-selector involvedObject.name=demo-probes
```

## create

```bash
kubectl create <resource> [Options]
  --dry-run=client:  仅尝试运行，不实际运行
  -o, --output='': 输出为指定的格式
```

快速创建一系列资源

```bash
[root@k8s-node1 ~]# kubectl create namespace test
namespace/test created
[root@k8s-node1 ~]# kubectl create deployment my-dep --image=nginx:1.22. --replicas=3 -n test
deployment.apps/my-dep created
[root@k8s-node1 ~]# kubectl expose deployment my-dep --port=80 --target-port=8080 --type=NodePort -n test
service/my-dep exposed
[root@k8s-node1 ~]# kubectl get pods,deployment,svc -n test
NAME                          READY   STATUS    RESTARTS   AGE
pod/my-dep-5f8dfc8c78-7w5nz   1/1     Running   0          41s
pod/my-dep-5f8dfc8c78-gt65r   1/1     Running   0          41s
pod/my-dep-5f8dfc8c78-n4vjd   1/1     Running   0          41s

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-dep   3/3     3            3           41s

NAME             TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/my-dep   NodePort   10.110.205.138   <none>        80:31890/TCP   17s
```

## expose

```bash
kubectl expose deployment my-dep --port=80 --target-port=8080 --type=NodePort -n test
# --port 表示service暴露的端口
# --target-port 表示后端镜像实际提供服务的端口
```

## label

```bash
kubectl label nodes [node] key=value # 打lable, value可以是空
kubectl label nodes [node] key- # 删除label
kubectl get nodes -l key=value # 根据label筛选
kubectl get nodes --show-labesl # 显示资源的所有标签
```

## run

```bash
kubectl run -it  test --image busybox --rm -- ping 10.244.107.207
```

# calicoctl

[下载地址](https://github.com/projectcalico/calicoctl/releases)

```bash
# 查看集群信息
DATASTORE_TYPE=kubernetes KUBECONFIG=~/.kube/config calicoctl get nodes

# 使用配置文件的方式
[root@k8s-node1 ~]# mkdir /etc/calico
[root@k8s-node1 ~]# cat > /etc/calico/calicoctl.cfg <<EOF
> apiVersion: projectcalico.org/v3
> kind: CalicoAPIConfig
> metadata:
> spec:
>   datastoreType: "kubernetes"
>   kubeconfig: "/root/.kube/config"
> EOF

# 查看集群信息
[root@k8s-node1 ~]# calicoctl --allow-version-mismatch get nodes
NAME
k8s-node1
k8s-node2
k8s-node3
[root@k8s-node1 ~]# calicoctl --allow-version-mismatch node status
IPv4 BGP status
+--------------+-------------------+-------+----------+-------------+
| PEER ADDRESS |     PEER TYPE     | STATE |  SINCE   |    INFO     |
+--------------+-------------------+-------+----------+-------------+
| 1.1.1.2      | node-to-node mesh | up    | 03:53:45 | Established |
| 1.1.1.3      | node-to-node mesh | up    | 03:53:51 | Established |
+--------------+-------------------+-------+----------+-------------+
```

# namespace

k8s 与 docker 的 namespace 不同

docker 中的 namespace 用于容器间的资源隔离

k8s 中的 namespace 用于

- k8s 的抽象资源间的资源隔离，比如 pods、控制器、service 等

- 资源隔离后，对这一组资源进行权限控制

# yaml 编写

通过创建资源获取 yaml

```textile
kubectl create deployment web --image=nginx:1.19 --dry-run=client -o yaml > deploy.yaml
```

通过已有资源获取 yaml

```textile
kubectl get deployment nginx-deployment -o yaml > deploy2.yaml
```

查看 api 中的资源及解释

```textile
kubectl explain pods.spec.container
kubectl explain deployment
```

yaml 报错排查

```textile
error: error parsing pod-configmap.yaml: error converting YAML to JSON: yaml: line 19: did not find expected '-' indicator
```

解决

由于 yaml 文件列表对齐不统一导致的

yaml 文件格式要对齐，同一级别的对象要放在同一列，几个空格不重要，不要用 tab 制表符

```yaml
# 格式1
ports:
  - port: 80
  
# 格式2
ports:
- port: 80
```
