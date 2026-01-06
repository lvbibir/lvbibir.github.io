---
title: "kubernetes | 日志" 
date: 2022-10-03
lastmod: 2024-01-28
tags:
  - kubernetes
keywords:
  - linux
  - centos
  - kubernetes
  - log
  - emptydir
  - sidebar
description: "介绍 kubernetes 中组件日志、标准输出类型的应用日志、文件类型的应用日志如何收集分析" 
cover:
    image: "images/cover-kubernetes.png"
---

# 0 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

kubelet logs 命令的流程

```plaintext
kubectl logs --请求--> apiserver --请求--> kubelet --读取--> container日志
```

k8s 日志包含两大类：

- k8s 系统的组件日志
- k8s 集群中部署的应用程序的日志
    - 标准输出
    - 日志文件

# 1 组件日志

```bash
journalctl -u kubelet
kubectl logs kube-proxy -n kube-system
/var/log/messages
```

# 2 pod 日志

## 2.1 标准输出

实时查看 pod 标准输出日志

```bash
kubectl logs [options] <podname>
kubectl logs -f <podname>
kubectl logs -f <podname> -c <containername>
kubectl logs --previous <podname> # 查看pod上次重启的日志
```

k8s 会将每个 pod 中每个 container 的日志记录到 pod 所在 node 的 `/var/log/pods` 目录中, 日志文件其实是 docker 保存的日志文件的一个软连接.

k8s 会为每个 pod 的每个 container 日志保留 2 份, 一份为 container 当前状态的日志, 另一份是 container 上一次生命周期的日志, 日志保留数量应该是由 k8s 的 gc 机制管控.

```bash
# k8s 日志
/var/log/pods/<pod namespace>_<pod name>_<pod uid>/<容器名称>/容器重启次数.log
# docker日志
/var/lib/docker/containers/<container-id>/<container-id>-json.log
```

示例

```bash
# 可以看到 calico-kube-controllers 这个 pod 重启了 7 次
[root@k8s-node1 ~]# kubectl get pods -n kube-system -l k8s-app=calico-kube-controllers
NAME                                       READY   STATUS    RESTARTS      AGE
calico-kube-controllers-6c76574f75-69flf   1/1     Running   7 (41h ago)   4d1h

# k8s 分别保存了编号 6 和 7 两个日志文件
[root@k8s-node3 ~]# ls -l /var/log/pods/kube-system_calico-kube-controllers-6c76574f75-69flf_066e1042-97a4-4547-8d2d-6580cbad40c5/calico-kube-controllers/
lrwxrwxrwx. 1 root root 165 Apr 20 14:31 6.log -> /var/lib/docker/containers/8ed4865daa5d984d9b7e3412f61251ce1a5e12e295fce1f14ee341c3f79b1afe/8ed4865daa5d984d9b7e3412f61251ce1a5e12e295fce1f14ee341c3f79b1afe-json.log
lrwxrwxrwx. 1 root root 165 Apr 23 10:23 7.log -> /var/lib/docker/containers/c30d353ee464efd853968dcd1524933aa214294303e5a7cd7828b0e86f0e94ec/c30d353ee464efd853968dcd1524933aa214294303e5a7cd7828b0e86f0e94ec-json.log

# 7 号日志文件是当前生命周期的日志
[root@k8s-node1 ~]# kubectl logs --tail=1 calico-kube-controllers-6c76574f75-69flf -n kube-system
2023-04-23 03:05:54.256 [INFO][1] resources.go 350: Main client watcher loop
[root@k8s-node3 calico-kube-controllers]# tail -n 1 7.log | python -m json.tool
{
    "log": "2023-04-23 03:05:54.256 [INFO][1] resources.go 350: Main client watcher loop\n",
    "stream": "stderr",
    "time": "2023-04-23T03:05:54.257447874Z"
}

# 6 号日志文件是上一次生命周期的日志
[root@k8s-node1 ~]# kubectl logs --tail=1 --previous calico-kube-controllers-6c76574f75-69flf -n kube-system
2023-04-21 08:57:20.637 [INFO][1] resources.go 350: Main client watcher loop
[root@k8s-node3 calico-kube-controllers]# tail -n 1 6.log | python -m json.tool
{
    "log": "2023-04-21 08:57:20.637 [INFO][1] resources.go 350: Main client watcher loop\n",
    "stream": "stderr",
    "time": "2023-04-21T08:57:20.637780663Z"
}
```

## 2.2 日志文件

比如 nginx 应用的日志一般保存在 accesss.log 和 error.log 日志中，这些日志是不会输出到标准输出的，可以采用如下两种方式进行采集

### 2.2.1 emptyDir 数据卷

创建 pod 时挂载 emptyDIr 类型的数据卷，用以持久化自定义的日志文件

需要先找到 pod 分配的节点

```bash
Kubectl get pods -o wide
```

再查看 pod 的 id

```bash
docker ps | grep pod-name 
# 或者
kubectl get pod <podname> -n <namespace> -o jsonpath='{.metadata.uid}'
```

pod 日志文件路径

```plaintext
/var/lib/kubelet/pods/<pod-id>/volumes/kubernetes.io~empty-dir
```

示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-logs-emptydir
spec:
  containers:
  - name: web
    image: nginx
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx/
  volumes:
  - name: logs
    emptyDir: {}
```

### 2.2.2 sidecar 边车容器

通过创建边车容器实现将应用原本的日志文件输出到标准输出

示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: web
    image: nginx:1.22.1
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx/
  - name: accesslog
    image: busybox:1.28
    command: ['/bin/sh', '-c', 'tail -f /opt/access.log']
    volumeMounts:
    - name: logs
      mountPath: /opt
  volumes:
  - name: logs
    emptyDir: {}
```

以上