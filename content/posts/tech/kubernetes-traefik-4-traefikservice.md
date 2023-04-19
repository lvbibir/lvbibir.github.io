---
title: "traefik系列之四 | 服务(TraefikService)" 
date: 2023-04-19
lastmod: 2023-04-19
tags: 
- traefik
- kubernetes
keywords:
- kubernetes
- traefik
- service
- traefikservice
description: "kubernetes 中使用 Traefik ingress 的 TraefikService 实现加权轮询、灰度发布、流量复制、会话保持(粘性会话)等功能" 
cover:
    image: "https://image.lvbibir.cn/blog/traefik.png"
    hidden: true
    hiddenInSingle: true
---

# 0. 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`， `traefik-2.9.10`

# 6. traefik高级功能

## 6.1 负载均衡

创建两个 web 应用 `foo` `bar` 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: foo
  labels:
    app: foo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: foo
  template:
    metadata:
      labels:
        app: foo
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: foo
        image: nginx:1.22.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "echo 'foo' > /usr/share/nginx/html/index.html"]
---
apiVersion: v1
kind: Service
metadata:
  name: foo
  labels:
    app: foo
spec:
  selector:
    app: foo
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bar
  labels:
    app: bar
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bar
  template:
    metadata:
      labels:
        app: bar
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: bar
        image: nginx:1.22.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "echo 'bar' > /usr/share/nginx/html/index.html"]
---
apiVersion: v1
kind: Service
metadata:
  name: bar
  labels:
    app: bar
spec:
  selector:
    app: bar
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

创建 ingressroute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressrouteweblb
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`lb.test.com`) && PathPrefix(`/`)
    kind: Rule
    services:
    - name: foo
      port: 80
      namespace: default
    - name: bar
      port: 80
      namespace: default
```

验证

```bash
[root@k8s-node1 traefik]# vim /etc/hosts
[root@k8s-node1 traefik]# curl lb.test.com
foo
[root@k8s-node1 traefik]# curl lb.test.com
bar
[root@k8s-node1 traefik]# curl lb.test.com
foo
[root@k8s-node1 traefik]# curl lb.test.com
bar
```

## 6.2 灰度发布(加权轮询)

> 基于 6.1 负载均衡的基础上测试
>
> 灰度发布也称为金丝雀发布，让一部分即将上线的服务发布到线上，观察是否达到上线要求，主要通过加权轮询的方式实现。

创建 traefikservice

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: wrr
  namespace: default
spec:
  weighted:
    services:
      - name: foo    
        port: 80
        weight: 3          # 定义权重
        kind: Service      # 可选，默认就是 Service 
      - name: bar
        port: 80     
        weight: 1
```

创建 ingressroute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroutewrr
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`wrr.test.com`) && PathPrefix(`/`)
    kind: Rule
    services:
    - name: wrr
      namespace: default
      kind: TraefikService
```

测试结果如下，可以看到每 4 次访问会有 3 次流量落到 foo 应用， 1 次流量落到 bar 应用

```bash
[root@k8s-node1 traefik]# for i in {1..12}; do curl http://wrr.test.com; done
foo
foo
foo
bar
foo
foo
foo
bar
foo
foo
foo
bar
```

## 6.3 会话保持(粘性会话)

> 在 6.1 负载均衡案例的基础上实施
>
> 会话保持依赖于 traefikService 的加权轮询

创建 traefikServie 

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: sticky
  namespace: default
spec:
  weighted:
    services:
      - name: foo
        port: 80
        weight: 3          # 定义权重
        kind: Service      # 可选，默认就是 Service
      - name: bar
        port: 80
        weight: 1
    sticky:                 # 开启粘性会话
      cookie:               # 基于cookie区分客户端      
        name: test-cookie   # 指定客户端请求时，包含的cookie名称
```

创建 ingressroute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute-sticky
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`sticky.test.com`) && PathPrefix(`/`)
    kind: Rule
    services:
    - name: sticky
      namespace: default
      kind: TraefikService
```

客户端访问测试，携带 cookie

```yaml

```









## 6.4 流量复制

> 在 6.1 负载均衡案例基础之上实施
>
> 所谓的流量复制，也称为镜像服务是指将请求的流量按规则复制一份发送给其它服务，并且会忽略这部分请求的响应，这个功能在做一些压测或者问题复现的时候很有用。

创建 traefikservice

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: mirror-from-service
  namespace: default
spec:
  mirroring:
    name: foo       # 发送 100% 的请求到 Service "foo"
    port: 80
    mirrors:
      - name: bar   # 然后复制 20% 的请求到 "bar"
        port: 80
        percent: 20
```

创建 ingressroute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute-mirror
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`mirror.test.com`) && PathPrefix(`/`) 
    kind: Rule
    services:
    - name: mirror-from-service         
      namespace: default
      kind: TraefikService
```

测试如下，可以看到只有`foo` 应用会有数据返回

```bash
[root@k8s-node1 traefik]# for i in {1..20}; do curl http://mirror.test.com && sleep 1; done
foo
foo
......
```

`bar` 应用同样收到了请求，与预期相同，收到了 20% 的流量

```bash
[root@k8s-node1 ~]# kubectl logs -l app=bar
....
10.244.36.82 - - [18/Apr/2023:09:13:59 +0000] "GET / HTTP/1.1" 200 4 "-" "curl/7.29.0" "1.1.1.1"
10.244.36.82 - - [18/Apr/2023:09:14:04 +0000] "GET / HTTP/1.1" 200 4 "-" "curl/7.29.0" "1.1.1.1"
10.244.36.82 - - [18/Apr/2023:09:14:09 +0000] "GET / HTTP/1.1" 200 4 "-" "curl/7.29.0" "1.1.1.1"
10.244.36.82 - - [18/Apr/2023:09:14:14 +0000] "GET / HTTP/1.1" 200 4 "-" "curl/7.29.0" "1.1.1.1"
```



