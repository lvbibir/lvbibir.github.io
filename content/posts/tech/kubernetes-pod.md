---
title: "kubernetes | pod" 
date: 2022-10-02
lastmod: 2022-10-02
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- pod
description: "介绍kubernetes中pod的基础概念、存在意义、pod中容器的分类、静态pod、重启策略、健康检查等" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---
# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# 基本概念

- 最小部署单元

- 一组容器的集合

- 一个Pod中的容器共享网络命名空间

- Pod是短暂的

# 存在意义

Pod为亲密性应用而存在。

亲密性应用场景：

- 两个应用之间发生文件交互

- 两个应用需要通过127.0.0.1或者socket通信（典型组合：nginx+php） 

- 两个应用需要发生频繁的调用

# 容器分类

- Infrastructure Container：基础容器，维护整个Pod网络空间

- InitContainers：初始化容器，先于业务容器开始执行

- Containers：业务容器，并行启动

**Infrastructure Container**

pod中总会多一个pause容器，这个容器就是实现将pod中的所有容器的网络命名空间进行统一，a容器在localhost或者127.0.0.1的某个端口提供了服务，b容器访问localhost或者127.0.0.1加端口也可以访问到

**Init container：** 

- 基本支持所有普通容器特征

- 优先普通容器执行

应用场景：

- 控制普通容器启动，初始容器完成后才会启动业务容器

- 初始化配置，例如下载应用配置文件、注册信息等

示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: workdir
      mountPath: /usr/share/nginx/html
  initContainers:
  - name: install
    image: busybox
    command:
    - wget
    - "-O"
    - "/work-dir/index.html"
    - http://www.baidu.com/index.html
    volumeMounts:
    - name: workdir
      mountPath: "/work-dir"
  dnsPolicy: Default
  volumes:
  - name: workdir
    emptyDir: {}
```

# 静态pod

静态Pod特点：

- Pod由特定节点上的kubelet管理

- 不能使用控制器

- Pod名称标识当前节点名称

在kubelet配置文件启用静态Pod：

```
vi /var/lib/kubelet/config.yaml
...
staticPodPath: /etc/kubernetes/manifests
...
```

将部署的pod yaml放到该目录会由kubelet自动创建

# 重启策略

- Always：当容器终止退出后，总是重启容器，默认策略。

- OnFailure：当容器异常退出（退出状态码非0）时，才重启容器。

- Never：当容器终止退出，从不重启容器。

# 健康检查

**健康检查有以下两种类型：**

- livenessProbe（存活检查）：如果检查失败，将杀死容器，根据Pod的restartPolicy来操作。

- readinessProbe（就绪检查）：如果检查失败，Kubernetes会把Pod从service endpoints中剔除。

**支持以下三种检查方法：**

- httpGet：发送HTTP请求，返回200-400范围状态码为成功。

- exec：执行Shell命令返回状态码是0为成功。

- tcpSocket：发起TCP Socket建立成功。

示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```