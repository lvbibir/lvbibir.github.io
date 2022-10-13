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

```
kubectl set image (-f FILENAME | TYPE NAME) CONTAINER_NAME_1=CONTAINER_IMAGE_1 ... CONTAINER_NAME_N=CONTAINER_IMAGE_N [options]
# 示例
kubectl set image deployment/nginx-deployment nginx=nginx:1.15 --record=true
# --record=true 表示将升级的命令记录到升级记录中
```

回滚

```
# 上次升级状态
kubectl rollout status deployment/nginx-deployment
# 升级记录
kubectl rollout history deployment/nginx-deployment
# 回滚至上个版本
kubectl rollout undo deployment/nginx-deployment
# 回滚至指定版本
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```

# 自动伸缩

手动扩容

```
 kubectl scale [--resource-version=version] [--current-replicas=count] --replicas=COUNT (-f FILENAME | TYPE NAME) [options]
 # 示例
 kubectl scale deployment nginx-deployment --replicas=10
```

自动扩容

HPA：pod水平扩容，k8s中的一个api资源，使用autoscale时会创建一个hpa资源

实现自动扩容还需满足两个条件：

- 运行了metric-server

- HPA对应的pod设置了request资源

示例：

metrics-server部署

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
kubectl autoscale deployment nginx-deployment --min=3 --max=10 --cpu-percent=10

# 查看hpa
kubectl get hpa

# replicaset控制器记录了pod的详细伸缩记录
kubectl get rs
kubectl describe rs nginx-deployment-54fdcc5676
```
