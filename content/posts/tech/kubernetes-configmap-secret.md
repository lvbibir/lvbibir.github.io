---
title: "kubernetes | configmap & secret" 
date: 2022-10-07
lastmod: 2024-01-28
tags:
  - kubernetes
keywords:
  - kubernetes
  - configmap
  - secret
description: "介绍kubernetes中的configmap和secret应用" 
cover:
    image: "images/logo-kubernetes.png"
---

# 0 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# 1 ConfigMap

创建 ConfigMap 后，数据实际会存储在 k8s 中的 Etcd 中，然后通过创建 pod 时引用该数据。

应用场景：应用程序配置

pod 使用 ConfigMap 数据有两种方式：

- 变量注入
- 数据卷挂载

![Snipaste_2022-10-07_15-58-31](/images/Snipaste_2022-10-07_15-58-31.png)

可以通过读取目录或者文件快速创建 configmap

```bash
kubectl create configmap <configmap-name> \
--from-file=[key-name]=<path>   \ # key 不指定时使用文件名作为 key 文件内容作为 value，path 既可以文件也可以是目录
--from-env-file=<path>          \ # 文件内容应是 key=value 的形式，逐行读取
--from-literal=<key>=<value>    \ # 通过指定的键值对创建 configmap
```

yaml 示例

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

```bash
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

# 2 Secret

与 ConfigMap 类似，区别在于 Secret 主要存储敏感数据，所有的数据都会经过 base64 编码。

Secret 支持三种数据类型：

- docker-registry：存储镜像仓库认证信息
- generic：从文件、目录或者字符串创建，例如存储用户名密码
- tls：存储证书，例如 HTTPS 证书

示例

将用户名和密码进行编码

```bash
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

```bash
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

以上
