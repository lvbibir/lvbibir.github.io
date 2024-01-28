---
title: "kubernetes | 调度" 
date: 2022-10-03
lastmod: 2024-01-28
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
description: "介绍 kubernetes 中影响 pod 调度的一些因素，比如资源限制、nodeSelector、nodeAffinity、Taint、nodeName、DaemonSet 控制器" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
---

# 0 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# 1 创建 pod 的工作流程

1. kubectl run nginx --image=nginx
2. kubectl 将创建 pod 的请求发送到 apiserver
3. apiserver 将请求信息写入 etcd
4. apiserver 通知 scheduler，收到请求信息后根据调度算法将 pod 分配到合适节点
5. scheduler 给 pod 标记调度结果，并返回给 apiserver
6. apiserver 收到后写入 etcd
7. 对应节点的 kubelet 收到创建 pod 的事件，从 apiserver 获取到 pod 的相关信息
8. kubelet 调用 docker api 创建 pod 所需的容器
9. 创建完成之后将 pod 状态汇报给 apiserver
10. apiserver 将收到的 pod 状态写入 apiserver
11. kubectl get pods 即可收到相关信息

# 2 资源限制对 pod 调度的影响

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

# 3 nodeSelector

nodeSelector 用于将 Pod 调度到匹配 Label 的 Node 上，如果没有匹配的标签会调度失败。

先创建 pod 后打标签，起始出于 pending 状态，打好标签后，pod 会正常分配

给节点打标签：

```bash
kubectl label nodes [node] key=value # 打lable, value可以是空
kubectl label nodes [node] key- # 删除label
kubectl get nodes -l key=value # 根据label筛选
# 示例
kubectl label nodes k8s-node1 disktype=ssd
kubectl label nodes k8s-node1 disktype-
```

示例

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

# 4 nodeAffinity

节点亲和性概念上类似于 `nodeSelector`， 它使你可以根据节点上的标签来约束 Pod 可以调度到哪些节点上。 节点亲和性有两种：

- `requiredDuringSchedulingIgnoredDuringExecution`： 调度器只有在规则被满足的时候才能执行调度。此功能类似于 `nodeSelector`， 但其语法表达能力更强。
- `preferredDuringSchedulingIgnoredDuringExecution`： 调度器会尝试寻找满足对应规则的节点。如果找不到匹配的节点，调度器仍然会调度该 Pod。

> 先创建 pod 后打标签起始出于 pending 状态，打好标签后，pod 会正常分配
>
> `IgnoredDuringExecution` 意味着如果节点标签在 Kubernetes 调度 Pod 后发生了变更，Pod 仍将继续运行。

操作符：In、NotIn、Exists、DoesNotExist、Gt、Lt

示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-affinity-anti-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/os
            operator: In
            values:
            - linux
            - windows
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: label-1
            operator: In
            values:
            - key-1
      - weight: 50
        preference:
          matchExpressions:
          - key: label-2
            operator: In
            values:
            - key-2
  containers:
  - name: with-node-affinity
    image: registry.k8s.io/pause:2.0
```

# 5 Taint(污点)

Taints：避免 Pod 调度到特定 Node 上

应用场景：

- 专用节点，例如配备了特殊硬件的节点
- 基于 Taint 的驱逐

设置污点：

```bash
kubectl taint node [node] key=value:[effect] 
# 其中[effect]可取值：
# - NoSchedule ：一定不能被调度。
# - PreferNoSchedule：尽量不要调度。
# - NoExecute：不仅不会调度，还会驱逐Node上已有的Pod。
```

去掉污点：

```plaintext
kubectl taint node [node] key:[effect]-
```

示例

```bash
[root@k8s-node1 ~]# kubectl label node k8s-node2 disktype=ssd
node/k8s-node2 labeled
[root@k8s-node1 ~]# kubectl taint node k8s-node2 disktype=ssd:NoSchedule
node/k8s-node2 tainted
[root@k8s-node1 ~]# kubectl describe node k8s-node2 | grep -i taints
Taints:             disktype=ssd:NoSchedule
```

**Tolerations（污点容忍）**

允许 Pod 调度到持有 Taints 的 Node 上，但不是绝对分配到指定的标签，搭配 nodeSelector 或者 nodeAffinity 使用，实现将 pod 分配到特定污点的节点上

```yaml
      tolerations:              #设置容忍所有污点，防止节点被设置污点
        - operator: "Exists"
```

示例

```bash
[root@k8s-node1 ~]# kubectl describe node k8s-node2 | grep -i taints Taint
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

# 6 nodeName

指定节点名称，用于将 Pod 调度到指定的 Node 上，不经过调度器 scheduler，所以无视污点

示例

```plaintext
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

# 7 DaemonSet 控制器

DaemonSet 功能：

- 在每一个 Node 上运行一个 Pod
- 新加入的 Node 也同样会自动运行一个 Pod

应用场景：网络插件、监控 Agent、日志 Agent，比如 k8s 的 calico-node 和 kube-proxy 组件

示例

```plaintext
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

以上
