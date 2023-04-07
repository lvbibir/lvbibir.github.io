---
title: "kubernetes | 滚动升级和自动伸缩" 
date: 2022-10-05
lastmod: 2022-10-05
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- update
description: "介绍kubernetes中滚动升级的实现机制，如何手动伸缩pod，以及基于hpa实现自动伸缩" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---
# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# 滚动升级

滚动升级的实现机制

两个replicaset控制器分别控制旧版本的pod和新版本pod，replicaset2启动一个新版版本pod，相应的replicaset1停止一个旧版本pod，从而实现滚动升级。在这过程中，无法保证业务流量完全不丢失。

![image-20221003113645777](https://image.lvbibir.cn/blog/image-20221003113645777.png)



升级

```bash
kubectl set image (-f FILENAME | TYPE NAME) CONTAINER_NAME_1=CONTAINER_IMAGE_1 ... CONTAINER_NAME_N=CONTAINER_IMAGE_N [options]
# 示例
kubectl set image deployment/demo-rollout nginx=nginx:1.15 --record=true
# --record=true 表示将升级的命令记录到升级记录中
```

回滚

```bash
# 上次升级状态
kubectl rollout status deployment demo-rollout
# 升级记录
kubectl rollout history deployment demo-rollout
# 回滚至上个版本
kubectl rollout undo deployment demo-rollout
# 回滚至指定版本
kubectl rollout undo deployment demo-rollout --to-revision=2
```

## 示例

在所有work节点先创建几个busybox镜像的tag用于升级演示

```bash
[root@k8s-node3 ~]# for i in {1..3}; do docker tag busybox:latest busybox:v${i}; done
[root@k8s-node3 ~]# docker images | grep busybox
busybox                                              latest    7cfbbec8963d   3 weeks ago     4.86MB
busybox                                              v1        7cfbbec8963d   3 weeks ago     4.86MB
busybox                                              v2        7cfbbec8963d   3 weeks ago     4.86MB
busybox                                              v3        7cfbbec8963d   3 weeks ago     4.86MB
```

创建v1版本的deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-rollout
  labels:
    app: demo-rollout
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-rollout
  template:
    metadata:
      labels:
        app: demo-rollout
    spec:
      containers:
      - name: busybox
        image: busybox:v1
        command: ['/bin/sh', '-c', 'sleep 36000']
```

也可以使用命令创建

```bash
[root@k8s-node1 ~]# kubectl create deployment demo-rollout --image=busybox:v1 --replicas=3 -- sleep 3600
deployment.apps/demo-rollout created
[root@k8s-node1 ~]# kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
demo-rollout-5d847fd86c-678pr   1/1     Running   0          4s
demo-rollout-5d847fd86c-9mj4v   1/1     Running   0          4s
demo-rollout-5d847fd86c-xhvf7   1/1     Running   0          4s

```

升级至v2和v3

```bash
# 升级
[root@k8s-node1 ~]# kubectl set image deployment/demo-rollout busybox=busybox:v2 --record=true
[root@k8s-node1 ~]# kubectl set image deployment/demo-rollout busybox=busybox:v3 --record=true
# 查看升级状态
[root@k8s-node1 ~]# kubectl rollout status deployment demo-rollout
deployment "demo-rollout" successfully rolled out
[root@k8s-node1 ~]# kubectl rollout history deployment demo-rollout
deployment.apps/demo-rollout
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deployment/demo-rollout busybox=busybox:v2 --record=true
3         kubectl set image deployment/demo-rollout busybox=busybox:v3 --record=true
# 查看实际镜像版本
[root@k8s-node1 ~]# kubectl get deployment demo-rollout -o jsonpath='{.spec.template.spec.containers}'
[root@k8s-node1 ~]# kubectl describe deployment demo-rollout | grep -i image:
    Image:      busybox:v3
```

回滚至v1版本

```bash
[root@k8s-node1 ~]# kubectl rollout undo deployment/demo-rollout --to-revision=1
deployment.apps/demo-rollout rolled back
[root@k8s-node1 ~]# kubectl describe deployment demo-rollout | grep -i image:
    Image:      busybox:v1
[root@k8s-node1 ~]# kubectl rollout history deployment demo-rollout
deployment.apps/demo-rollout
REVISION  CHANGE-CAUSE
2         kubectl set image deployment/demo-rollout busybox=busybox:v2 --record=true
3         kubectl set image deployment/demo-rollout busybox=busybox:v3 --record=true
4         <none>
```

可以看到 rollout history 删除了第一次的记录, 重新记录到第四条

恢复到v2版本

```bash
[root@k8s-node1 ~]# kubectl rollout undo deployment/demo-rollout --to-revision=2
deployment.apps/demo-rollout rolled back
[root@k8s-node1 ~]# kubectl describe deployment demo-rollout | grep -i image:
    Image:      busybox:v2
[root@k8s-node1 ~]# kubectl rollout history deployment demo-rollout
deployment.apps/demo-rollout
REVISION  CHANGE-CAUSE
3         kubectl set image deployment/demo-rollout busybox=busybox:v3 --record=true
4         <none>
5         kubectl set image deployment/demo-rollout busybox=busybox:v2 --record=true
```

# 自动伸缩

手动扩容

```
 kubectl scale [--resource-version=version] [--current-replicas=count] --replicas=COUNT (-f FILENAME | TYPE NAME) [options]
 # 示例
 kubectl scale deployment demo-rollout --replicas=10
```

自动扩容

HPA：pod水平扩容，k8s中的一个api资源，使用autoscale时会创建一个hpa资源

实现自动扩容还需满足两个条件：

- 运行了metric-server

- HPA对应的pod设置了request资源

示例：

[metrics-server部署](https://www.lvbibir.cn/posts/tech/kubernetes-v1.22.3-kubeadm/#5-metric-server)

```
kubectl get pods -n kube-system | grep metrics-server
```

pod中设置request资源

```yaml
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 0.3
```

创建hpa


```
kubectl autoscale (-f FILENAME | TYPE NAME | TYPE/NAME) [--min=MINPODS] --max=MAXPODS [--cpu-percent=CPU] [options]
# 基于cpu指标进行扩容
kubectl autoscale deployment demo-rollout --min=3 --max=10 --cpu-percent=10

# 查看hpa
kubectl get hpa

# replicaset控制器记录了pod的详细伸缩记录
kubectl get rs
kubectl describe rs demo-rollout-54fdcc5676
```

## 示例

