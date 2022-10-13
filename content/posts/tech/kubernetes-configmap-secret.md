---
title: "kubernetes | configmap & secret" 
date: 2022-10-07
lastmod: 2022-10-07
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- configmap
- secret
description: "介绍kubernetes中的configmap和secret应用" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---

# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# ConfigMap

创建ConfigMap后，数据实际会存储在k8s中的Etcd中，然后通过创建pod时引用该数据。

应用场景：应用程序配置

pod使用ConfigMap数据有两种方式：

- 变量注入
- 数据卷挂载

![Snipaste_2022-10-07_15-58-31](https://image.lvbibir.cn/blog/Snipaste_2022-10-07_15-58-31.png)

yaml示例

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-demo
data:
  abc: "123"
  cde: "456"
  redis.properties: |
    port: 6379
    host: 1.1.1.4
    password: 123456
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap
spec:
  containers:
  - name: demo
    image: nginx:1.19
    env:
    - name: ABCD
      valueFrom:
        configMapKeyRef:
          name: configmap-demo
          key: abc
    - name: CDEF
      valueFrom:
        configMapKeyRef:
          name: configmap-demo
          key: cde
    volumeMounts:
    - name: config
      mountPath: "/config"
      readOnly: true
  volumes:
  - name: config
    configMap:
      name: configmap-demo
      items:
      - key: "redis.properties"
        path: "redis.properties" # 挂载文件名
```

容器内验证

```
[root@k8s-node1 ~]# kubectl exec -it pod-configmap -- bash
root@pod-configmap:/# echo $ABCD
123
root@pod-configmap:/# echo $CDEF
456
root@pod-configmap:/# cat /config/redis.properties
port: 6379
host: 1.1.1.4
password: 123456
```

# Secret

与ConfigMap类似，区别在于Secret主要存储敏感数据，所有的数据都会经过base64编码。

Secret支持三种数据类型：

- docker-registry：存储镜像仓库认证信息
- generic：从文件、目录或者字符串创建，例如存储用户名密码
- tls：存储证书，例如HTTPS证书

示例

将用户名和密码进行编码

```
[root@k8s-node1 ~]# echo -n 'admin' | base64
YWRtaW4=
[root@k8s-node1 ~]# echo -n '123.com' | base64
MTIzLmNvbQ==
```

secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-pass
type: Opaque
data:
  username: YWRtaW4=
  password: MTIzLmNvbQ==
```

pod-secret.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret-demo
spec:
  containers:
  - name: demo
    image: nginx:1.19
    env:
    - name: USER # 变量名
      valueFrom:
        secretKeyRef:
          name: db-pass
          key: username
    - name: PASS # 变量名
      valueFrom:
        secretKeyRef:
          name: db-pass
          key: password
    volumeMounts:
    - name: config
      mountPath: "/config"
      readOnly: true
  volumes:
  - name: config
    secret:
      secretName: db-pass
      items:
      - key: password
        path: my-password # 挂载文件名
```

验证

```
[root@k8s-node1 ~]# kubectl apply -f secret.yaml
secret/db-pass created
[root@k8s-node1 ~]# kubectl apply -f pod-secret.yaml
pod/pod-secret-demo created

[root@k8s-node1 ~]# kubectl exec -it pod-secret-demo -- bash
root@pod-secret-demo:/# echo $USER
admin
root@pod-secret-demo:/# echo $PASS
123.com
root@pod-secret-demo:/# cat /config/my-password
123.com
```



















