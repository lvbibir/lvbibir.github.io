---
title: "traefik (四) 服务(TraefikService)" 
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
---

# 0. 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`， `traefik-2.9.10`

示例中用到的 `myapp` 和 `secret` 资源请查看系列文章第二篇中的演示

# 1. 简介

traefik 的路由规则就可以实现 4 层和 7 层的基本负载均衡操作，使用 [IngressRoute](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute) [IngressRouteTCP](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroutetcp) [IngressRouteUDP](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressrouteudp) 资源即可。但是如果想要实现 `加权轮询、流量复制` 等高级操作，traefik 抽象出了一个 [TraefikService](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-traefikservice) 资源。此时整体流量走向为：外部流量先通过 entryPoints 端口进入 traefik，然后由 IngressRoute/IngressRouteTCP/IngressRouteUDP 匹配后进入 `TraefikService`，在 `TraefikService` 这一层实现加权轮循和流量复制，最后将请求转发至 kubernetes 的 service。

除此之外 traefik 还支持 7 层的粘性会话、健康检查、传递请求头、响应转发、故障转移等操作。

# 2. 灰度发布 (加权轮询)

[官方文档](https://doc.traefik.io/traefik/routing/services/#weighted-round-robin-service)

灰度发布也称为金丝雀发布，让一部分即将上线的服务发布到线上，观察是否达到上线要求，主要通过加权轮询的方式实现。

创建 traefikService 和 inressRoute 资源，实现 wrr 加权轮询

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
  - match: Host(`myapp.test.com`) && PathPrefix(`/`)
    kind: Rule
    services:
    - name: wrr
      namespace: default
      kind: TraefikService
---
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: wrr
  namespace: default
spec:
  weighted:
    services:
      - name: myapp1    
        port: 80
        weight: 1          # 定义权重
        kind: Service      # 可选，默认就是 Service 
      - name: myapp2
        port: 80     
        weight: 2
```

测试结果如下，可以看到每 3 次访问会有 1 次流量落到 v1 应用， 2 次流量落到 v2 应用

```bash
[root@k8s-node1 ~]# for i in {1..9}; do curl http://myapp.test.com && sleep 1; done
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
```

# 3. 会话保持 (粘性会话)

[官方文档](https://doc.traefik.io/traefik/routing/services/#servers)

> 会话保持功能依赖加权轮询功能

当我们使用 traefik 的负载均衡时，默认情况下轮循多个 k8s 的 service 服务，如果用户对同一内容的多次请求，可能被转发到了不同的后端服务器。假设用户发出请求被分配至服务器 A，保存了一些信息在 session 中，该用户再次发送请求被分配到服务器 B，要用之前保存的信息，若服务器 A 和 B 之间没有 session 粘滞，那么服务器 B 就拿不到之前的信息，这样会导致一些问题。traefik 同样也支持粘性会话，可以让用户在一次会话周期内的所有请求始终转发到一台特定的后端服务器上。

创建 traefikervie 和 ingressRoute，实现基于 cookie 的会话保持

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
  - match: Host(`myapp.test.com`) && PathPrefix(`/`)
    kind: Rule
    services:
    - name: sticky
      namespace: default
      kind: TraefikService
---
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: sticky
  namespace: default
spec:
  weighted:
    services:
      - name: myapp1
        port: 80
        weight: 1          # 定义权重
      - name: myapp2
        port: 80
        weight: 2
    sticky:                 # 开启粘性会话
      cookie:               # 基于cookie区分客户端      
        name: test-cookie   # 指定客户端请求时，包含的cookie名称
```

客户端访问测试，携带 cookie

```yaml
[root@k8s-node1 ~]# for i in {1..5}; do curl -b "test-cookie=default-myapp2-80" http://myapp.test.com; done
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>

[root@k8s-node1 ~]# for i in {1..5}; do curl -b "test-cookie=default-myapp1-80" http://myapp.test.com; done
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
```

# 4. 流量复制

[官方文档](https://doc.traefik.io/traefik/routing/services/#mirroring-service)

所谓的流量复制，也称为镜像服务是指将请求的流量按规则复制一份发送给其它服务，并且会忽略这部分请求的响应，这个功能在做一些压测或者问题复现的时候很有用。

创建 traefikService 和 ingressRoute

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
  - match: Host(`myapp.test.com`) && PathPrefix(`/`) 
    kind: Rule
    services:
    - name: mirror-from-service         
      namespace: default
      kind: TraefikService
---
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: mirror-from-service
  namespace: default
spec:
  mirroring:
    name: myapp1       # 发送 100% 的请求到 myapp1
    port: 80
    mirrors:
      - name: myapp2   # 然后复制 10% 的请求到 myapp2
        port: 80
        percent: 10,
```

测试如下，可以看到只有 `myapp1` 应用会有数据返回

```bash
[root@k8s-node1 ~]# for i in {1..20}; do curl http://myapp.test.com && sleep 1; done
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
.......
```

`myapp2` 应用同样收到了请求，与预期相同，收到了 10% 的流量，

```bash
[root@k8s-node1 ~]# kubectl logs -l app=bar
....
10.244.36.64 - - [20/Apr/2023:07:04:33 +0000] "GET / HTTP/1.1" 200 65 "-" "curl/7.29.0" "1.1.1.1"
10.244.36.64 - - [20/Apr/2023:07:04:43 +0000] "GET / HTTP/1.1" 200 65 "-" "curl/7.29.0" "1.1.1.1"
```
