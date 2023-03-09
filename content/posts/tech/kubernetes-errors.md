---
title: "kubernetes | 常见报错解决" 
date: 2023-03-06
lastmod: 2023-03-06
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
description: "kubernetes常见报错及解决" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---

# 1. NodeNotReady

## 1.1 Image garbage collection failed once

[参考地址](https://stackoverflow.com/questions/62020493/kubernetes-1-18-warning-imagegcfailed-error-failed-to-get-imagefs-info-unable-t?newreg=6012e8d3a8494d7d816cf2d6606ed1b2)

报错：

```
# kubectl describe node k8s-node01

Events:
  Type    Reason                   Age   From     Message
  ----    ------                   ----  ----     -------
  Normal  Starting                 11m   kubelet  Starting kubelet.
  Normal  NodeHasSufficientMemory  11m   kubelet  Node k8s-node01 status is now: NodeHasSufficientMemory
  Normal  NodeHasNoDiskPressure    11m   kubelet  Node k8s-node01 status is now: NodeHasNoDiskPressure
  Normal  NodeHasSufficientPID     11m   kubelet  Node k8s-node01 status is now: NodeHasSufficientPID
  Normal  NodeAllocatableEnforced  11m   kubelet  Updated Node Allocatable limit across pods
  
# journalctl -u kubelet | grep garbage

Mar 06 09:50:33 k8s-node01 kubelet[45471]: E0306 09:50:33.106476   45471 kubelet.go:1343] "Image garbage collection failed once. Stats initialization may not have completed yet" err="failed to get imageFs info: unable to find data in memory cache"
```

解决：

1. 未部署CNI组件

2. docker镜像或容器未能正确删除导致的

```
docker system prune
systemctl stop kubelet
systemctl stop docker
systemctl start docker
systemctl start kubelet
```

