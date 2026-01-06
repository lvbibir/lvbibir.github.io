---
title: "kubernetes | 控制器" 
date: 2022-10-04
lastmod: 2024-01-28
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
description: "介绍 kubernetes 中几种常用的控制器的使用场景和示例" 
cover:
    image: "images/logo-kubernetes.png"
---

# 0 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

controllers 作用：

- 管理 pod 对象
- 使用标签与 pod 关联
- 负责滚动更新、伸缩、副本管理、维持 pod 状态等

![Snipaste_2022-10-03_09-06-24](/images/Snipaste_2022-10-03_09-06-24.png)

# 1 daemonset

# 2 ingress

# 3 statefulset

# 4 replicaset

ReplicaSet：副本集

- 协助 Deployment 做事

- Pod 副本数量管理，不断对比当前 Pod 数量与期望 Pod 数量

- Deployment 每次发布都会创建一个 RS 作为记录，用于实现回滚

![image-20221003113534541](/images/image-20221003113534541.png)

# 5 deployment

deployment 用于网站、API、微服务等，功能特性：

- 管理 pod 和 replicaset
- 具有上线部署、副本设定、滚动升级、回滚等功能
- 提供声明式更新，例如只更新一个新的 image

![image-20221003092803567](/images/image-20221003092803567.png)

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

以上
