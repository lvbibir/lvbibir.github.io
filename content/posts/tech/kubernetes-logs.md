---
title: "kubernetes | 日志" 
date: 2022-10-03
lastmod: 2022-10-03
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- log
- emptydir
- sidebar
description: "介绍kubernetes中组件日志、标准输出类型的应用日志、文件类型的应用日志如何收集分析" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---
# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

kubelet logs命令的流程

```
kubectl logs ----请求----> apiserver ----请求----> kubelet ----读取----> container日志
```

k8s日志包含两大类：

- k8s系统的组件日志

- k8s集群中部署的应用程序的日志

  - 标准输出

  - 日志文件

# 组件日志

```
journalctl -u kubelet

kubectl logs kube-proxy -n kube-system

/var/log/messages
```

# 应用日志

## 标准输出

实时查看pod标准输出日志

```
kubectl logs -f <podname>
kubectl logs -f <podname> -c <containername>
```

标准输出文件的路径

```
/var/lib/docker/containers/<container-id>/<container-id>-json.log
```

## 日志文件

比如nginx应用的日志一般保存在accesss.log和error.log日志中，这些日志是不会输出到标准输出的，可以采用如下两种方式进行采集

### emptyDir数据卷

创建pod时挂载emptyDIr类型的数据卷，用以持久化自定义的日志文件

需要先找到pod分配的节点

```
Kubectl get pods -o wide
```

再查看pod的id

```
docker ps | grep pod-name
```

pod日志文件路径

```
/var/lib/kubelet/pods/<pod-id>/volumes/kubernetes.io~empty-dir
```

示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web2
spec:
  containers:
  - name: web
    image: lizhenliang/nginx-php
    volumeMounts:
    - name: logs
      mountPath: /usr/local/nginx/logs
  volumes:
  - name: logs
    emptyDir: {}
```

### sidebar边车容器

通过创建边车容器实现将应用原本的日志文件输出到标准输出

示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidebar
spec:
  containers:
  - name: web
    image: lizhenliang/nginx-php
    volumeMounts:
    - name: logs
      mountPath: /usr/local/nginx/logs
  - name: log
    image: busybox
    args: [/bin/sh, -c, 'tail -f /opt/access.log']
    volumeMounts:
    - name: logs
      mountPath: /opt
  volumes:
  - name: logs
    emptyDir: {}
```