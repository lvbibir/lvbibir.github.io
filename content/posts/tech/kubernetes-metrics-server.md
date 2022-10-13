---
title: "kubernetes | metrics-server部署" 
date: 2022-10-03
lastmod: 2022-10-03
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- monitor
- metrics
- cadvisor
description: "介绍kubernetes中metric-server监控组件的部署" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---
# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

cadvisor负责提供数据，已集成到k8s中

Metrics-server负责数据汇总，需额外安装

![Snipaste_2022-10-02_09-04-36](https://image.lvbibir.cn/blog/Snipaste_2022-10-02_09-04-36.png)

# metrics-server部署

下载yaml

```bash
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.0/components.yaml --no-check-certificate
mv components.yaml metrics-server.yaml
```

修改yaml

```yaml
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP # 第一处修改
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls # 第二处修改
        image: registry.aliyuncs.com/google_containers/metrics-server:v0.6.0 # 第三处修改
        imagePullPolicy: IfNotPresent
```

**--kubelet-insecure-tls**

不验证kubelet自签的证书

**--kubelet-preferred-address-types=InternalIP**

Metrics-server连接cadvisor默认通过主机名即node的名称进行连接，而Metric-server作为pod运行在集群中默认是无法解析的，所以这里修改成通过节点ip连接

部署metrics-server

```
[root@k8s-node1 ~]# kubectl apply -f metrics-server.yaml

[root@k8s-node1 ~]# kubectl get pods -n kube-system -l k8s-app=metrics-server
NAME                              READY   STATUS    RESTARTS   AGE
metrics-server-7f66b69ff6-bkfqg   1/1     Running   0          59s

[root@k8s-node1 ~]# kubectl top nodes
NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k8s-node1   226m         11%    2004Mi          54%
k8s-node2   97m          4%     1047Mi          28%
k8s-node3   98m          4%     1096Mi          29%
```

