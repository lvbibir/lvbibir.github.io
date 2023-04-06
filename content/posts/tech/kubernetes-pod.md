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

# 1. 基本概念

- 最小部署单元

- 一组容器的集合

- 一个Pod中的容器共享网络命名空间

- Pod是短暂的

# 2. 存在意义

Pod为亲密性应用而存在。

亲密性应用场景：

- 两个应用之间发生文件交互

- 两个应用需要通过127.0.0.1或者socket通信（典型组合：nginx+php） 

- 两个应用需要发生频繁的调用

# 3. 容器分类

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
  name: pod-init
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
    command: ["wget", "-O", "/work-dir/index.html", "http://www.baidu.com/index.html"]
    volumeMounts:
    - name: workdir
      mountPath: "/work-dir"
  volumes:
  - name: workdir
    emptyDir: {}
```

# 4. 静态pod

静态Pod特点：

- Pod由特定节点上的kubelet管理

- 不能使用控制器

- Pod名称标识当前节点名称

在kubelet配置文件启用静态Pod：

```bash
vi /var/lib/kubelet/config.yaml
...
staticPodPath: /etc/kubernetes/manifests
...
```

将部署的pod yaml放到该目录会由kubelet自动创建

# 5. 重启策略

- Always：当容器终止退出后，总是重启容器，默认策略。

- OnFailure：当容器异常退出（退出状态码非0）时，才重启容器。

- Never：当容器终止退出，从不重启容器。

# 6. 健康检查

**健康检查有以下两种类型：**

- livenessProbe(存活探针): 如果检查失败，将杀死并重建容器，根据Pod的restartPolicy来操作.

- readinessProbe(就绪探针): 如果检查失败，Kubernetes会把Pod暂时从service endpoints中剔除.

- startupProbe(启动探针): 如果检查失败，将杀死并重建容器，根据Pod的restartPolicy来操作. 用于启动非常慢的应用，如果使用了启动探针，则禁用所有其他探针, 直到它成功为止.

**支持以下四种检查方法：**

- httpGet：发送HTTP请求，返回200-400范围状态码为成功。
- exec：执行Shell命令返回状态码是0为成功。
- tcpSocket：发起TCP Socket建立成功。
- gRPC：需要应用程序支持，[参考](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#%E5%AE%9A%E4%B9%89-grpc-%E5%AD%98%E6%B4%BB%E6%8E%A2%E9%92%88)

探针配置:

- initialDelaySeconds: 容器启动后要等待多少秒后存活和就绪探测器才被初始化, 默认是0秒, 最小值是0.
- periodSeconds: 执行探测的时间间隔.默认是10秒, 最小值是1.
- timeoutSeconds: 探测的超时后等待多少秒. 默认值是1秒. 最小值是1.
- successThreshold: 探测器在失败后, 被视为成功的最小连续成功数. 默认值是1. 存活探测的这个值必须是1。最小值是1.
- failureThreshold: 当Pod启动了并且探测到失败的重试次数. 存活探测情况下的放弃就意味着重新启动容器. 就绪探测情况下的放弃Pod会被打上未就绪的标签, 默认值是3, 最小值是1.

## 6.1 liveness

linveness实际触发重启需要的时间 = 失败次数 * 间隔时间 + 等待容器优雅退出的宽限期(默认30s，docker默认是10s) 

`failureThreshold` * `periodSeconds` + `terminationGracePeriodSeconds`

livenessProbe示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-livenessprobe
  namespace: default
spec:
  restartPolicy: OnFailure
  # 等待容器优雅退出的时长，超出该时间后强制杀死，默认值30s
  terminationGracePeriodSeconds: 10
  containers:
  - name: busybox
    image: busybox
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh", "-c", "touch /tmp/healthy; sleep 10; rm -rf /tmp/healthy; sleep 600"]
    livenessProbe:
      exec:
        command: ["test", "-e", "/tmp/healthy"]
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 2
```

运行结果可以看到在两分钟的时间里重启了4次，每次30s

```bash
[root@k8s-node1 opt]# kubectl get pods
NAME           READY   STATUS    RESTARTS     AGE
liveness-pod   1/1     Running   4 (2s ago)   2m2s
```

1. POD运行的前10s检查一直成功
2. 在POD启动的第15s第一次检查失败
3. 第20s第二次检查失败，给容器发送停止信号
4. 等待10s后强制重启容器