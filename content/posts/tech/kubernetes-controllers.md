---
title: "kubernetes | 控制器" 
date: 2022-10-04
lastmod: 2022-10-04
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- controller
- daemonset
- ingress
- statefulset
- replicaset
- deployment
description: "介绍kubernetes中几种常用的控制器的使用场景和示例" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---
# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

controllers作用：

- 管理pod对象
- 使用标签与pod关联
- 负责滚动更新、伸缩、副本管理、维持pod状态等

![Snipaste_2022-10-03_09-06-24](https://image.lvbibir.cn/blog/Snipaste_2022-10-03_09-06-24.png)

# daemonset

# ingress

# statefulset

# replicaset

ReplicaSet：副本集

- 协助Deployment做事

- Pod副本数量管理，不断对比当前Pod数量与期望Pod数量

- Deployment每次发布都会创建一个RS作为记录，用于实现回滚

![image-20221003113534541](https://image.lvbibir.cn/blog/image-20221003113534541.png)

# deployment

deployment用于网站、API、微服务等，功能特性：

- 管理pod和replicaset
- 具有上线部署、副本设定、滚动升级、回滚等功能
- 提供声明式更新，例如只更新一个新的image

![image-20221003092803567](https://image.lvbibir.cn/blog/image-20221003092803567.png)

示例

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
```
