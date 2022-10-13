---
title: "kubernetes | 调度" 
date: 2022-10-03
lastmod: 2022-10-03
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- scheduler
- nodeSelector
- nodeAffinity
- nodeName
- DaemonSet
description: "介绍kubernetes中影响pod调度的一些因素，比如资源限制|nodeSelector|nodeAffinity|Taint|nodeName|DaemonSet控制器" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---
# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# 创建pod的工作流程

1. kubectl run nginx --image=nginx
2. kubectl将创建pod的请求发送到apiserver
3. apiserver将请求信息写入etcd
4. apiserver通知scheduler，收到请求信息后根据调度算法将pod分配到合适节点
5. scheduler给pod标记调度结果，并返回给apiserver
6. apiserver收到后写入etcd
7. 对应节点的kubelet收到创建pod的事件，从apiserver获取到pod的相关信息
8. kubelet调用docker api创建pod所需的容器
9. 创建完成之后将pod状态汇报给apiserver
10. apiserver将收到的pod状态写入apiserver
11. kubectl get pods即可收到相关信息

# 资源限制对pod调度的影响

容器资源限制：

- resources.limits.cpu

- resources.limits.memory

容器使用的最小资源需求，并不是实际占用，是预留资源：

- resources.requests.cpu

- resources.requests.memory

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: web
    image: nginx
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m" #cpu单位也可以写浮点数，例如0.25=250m，代表四分之一核cpu
      limits:
        memory: "128Mi"
        cpu: "500m"
```

# nodeSelector

nodeSelector用于将Pod调度到匹配Label的Node上，如果没有匹配的标签会调度失败。

先创建pod后打标签，起始出于pending状态，打好标签后，pod会正常分配

给节点打标签：

```
kubectl label nodes [node] key=value 
kubectl label nodes [node] key-
# 示例
kubectl label nodes k8s-node1 disktype=ssd
kubectl label nodes k8s-node1 disktype-
```

yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-nodeselector
spec:
  containers:
  - name: nginx
    image: nginx:1.19
  nodeSelector:
    disktype: "ssd"
```

#  nodeAffinity

nodeAffinity：节点亲和类似于nodeSelector，可以根据节点上的标签来约束Pod可以调度到哪些节点。

相比nodeSelector： 

- 匹配有更多的逻辑组合，不只是字符串的完全相等

- 调度分为软策略和硬策略，而不是硬性要求

- - 硬（required）：必须满足
  - 软（preferred）：尝试满足，但不保证

操作符：In、NotIn、Exists、DoesNotExist、Gt、Lt

先创建pod后打标签，起始出于pending状态，打好标签后，pod会正常分配

示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-nodeaffinity
spec:
  containers:
  - name: with-node-affinity
    image: nignx:1.19
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution: # 硬策略
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
      preferredDuringSchedulingIgnoredDuringExecution: # 软策略
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
```

# Taint (污点)

Taints：避免Pod调度到特定Node上

应用场景：

- 专用节点，例如配备了特殊硬件的节点

- 基于Taint的驱逐

设置污点：

```
kubectl taint node [node] key=value:[effect] 
其中[effect]可取值：
- NoSchedule ：一定不能被调度。
- PreferNoSchedule：尽量不要调度。
- NoExecute：不仅不会调度，还会驱逐Node上已有的Pod。
```

去掉污点：

```
kubectl taint node [node] key:[effect]-
```

示例

```
[root@k8s-node1 ~]# kubectl label node k8s-node2 disktype=ssd
node/k8s-node2 labeled
[root@k8s-node1 ~]# kubectl describe node k8s-node2 | grep Taint
Taints:             disktype=ssd:NoSchedule
```

**Tolerations（污点容忍）**

允许Pod调度到持有Taints的Node上，但不是绝对分配到指定的标签，搭配nodeSelector或者nodeAffinity使用，实现将pod分配到特定污点的节点上

示例

```
[root@k8s-node1 ~]# kubectl label node k8s-node2 disktype=ssd
node/k8s-node2 labeled
[root@k8s-node1 ~]# kubectl describe node k8s-node2 | grep Taint
Taints:             disktype=ssd:NoSchedule
[root@k8s-node1 ~]# kubectl apply -f pod-tolerations.yaml
[root@k8s-node1 ~]# kubectl get pods pod-tolerations -o wide
pod-tolerations   1/1     Running   0          13s   10.244.169.183   k8s-node2   <none>           <none>
```

yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-tolerations
spec:
  containers:
  - name: nginx
    image: nginx:1.19
  nodeSelector:
    disktype: "ssd"
  tolerations:
  - key: "disktype"
    operator: "Equal"
    value: "ssd"
    effect: "NoSchedule"
```

# nodeName

指定节点名称，用于将Pod调度到指定的Node上，不经过调度器scheduler，所以无视污点

示例

```
[root@k8s-node1 ~]# kubectl describe node k8s-node2| grep Taint
Taints:             disktype=ssd:NoSchedule
[root@k8s-node1 ~]# kubectl apply -f pod-nodename.yaml
pod/pod-nodename created
[root@k8s-node1 ~]# kubectl get pod pod-nodename -o wide
NAME           READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
pod-nodename   1/1     Running   0          27s   10.244.169.184   k8s-node2   <none>           <none>
```

yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-nodename
spec:
  containers:
  - name: nginx
    image: nginx
  nodeName: k8s-node2
```

# DaemonSet控制器

DaemonSet功能：

- 在每一个Node上运行一个Pod

- 新加入的Node也同样会自动运行一个Pod

应用场景：网络插件、监控Agent、日志Agent，比如k8s的calico-node和kube-proxy组件

示例

```
[root@k8s-node1 ~]# kubectl apply -f daemonset-filebeat.yaml
[root@k8s-node1 ~]# kubectl get pods -n kube-system -o wide |grep filebeat
filebeat-2c6p4       1/1     Running   0               90s    10.244.107.246   k8s-node3   <none>           <none>
filebeat-4ffcx        1/1     Running   0               90s    10.244.36.65     k8s-node1   <none>           <none>
filebeat-h7959       1/1     Running   0               90s    10.244.169.186   k8s-node2   <none>           <none>
```

yaml

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: filebeat
  template:
    metadata:
      labels:
        name: filebeat
    spec:
      containers:
      - name: log
        image: elastic/filebeat:7.3.2
        volumeMounts:
        - mountPath: /log/
          name: log
      volumes:
      - name: log
        hostPath:
          path: /var/lib/docker/containers/
          type: Directory
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
```
