---
title: "traefik (二) 路由(ingressRoute)" 
date: 2023-04-18
lastmod: 2023-04-18
tags: 
  - traefik
  - kubernetes
keywords:
  - kubernetes
  - traefik
  - ingressroute
description: "kubernetes 中使用 Traefik ingress 的 ingressRoute 代理 http、https、tcp、udp" 
cover:
    image: "https://image.lvbibir.cn/blog/traefik.png"
---

# 0. 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`， `traefik-2.9.10`

# 1. 简介

[官方文档](https://doc.traefik.io/traefik/routing/overview/)

## 1.1 三种方式

Traefik 创建路由规则有多种方式，比如：

- 原生 `Ingress` 写法
- 使用 CRD `IngressRoute` 方式
- 使用 `GatewayAPI` 的方式

相较于原生 Ingress 写法，ingressRoute 是 2.1 以后新增功能，简单来说，他们都支持路径 (path) 路由和域名 (host) HTTP 路由，以及 HTTPS 配置，区别在于 IngressRoute 需要定义 CRD 扩展，但是它支持了 TCP、UDP 路由以及中间件等新特性，强烈推荐使用 ingressRoute

## 1.2 匹配规则

| 规则                                                         | 描述                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| Headers(`key`, `value`)                                      | 检查 headers 中是否有一个键为 key 值为 value 的键值对              |
| HeadersRegexp(`key`, `regexp`)                               | 检查 headers 中是否有一个键位 key 值为正则表达式匹配的键值对     |
| Host(`example.com`, …)                                       | 检查请求的域名是否包含在特定的域名中                         |
| HostRegexp(`example.com`, `{subdomain:[a-z]+}.example.com`, …) | 检查请求的域名是否包含在特定的正则表达式域名中               |
| Method(`GET`, …)                                             | 检查请求方法是否为给定的 methods(GET、POST、PUT、DELETE、PATCH) 中 |
| Path(`/path`, `/articles/{cat:[a-z]+}/{id:[0-9]+}`, …)       | 匹配特定的请求路径，它接受一系列文字和正则表达式路径         |
| PathPrefix(`/products/`, `/articles/{cat:[a-z]+}/{id:[0-9]+}`) | 匹配特定的前缀路径，它接受一系列文字和正则表达式前缀路径     |
| Query(`foo=bar`, `bar=baz`)                                  | 匹配查询字符串参数，接受 key=value 的键值对                    |
| ClientIP(`10.0.0.0/16`, `::1`)                               | 如果请求客户端 IP 是给定的 IP/CIDR 之一，则匹配。它接受 IPv4、IPv6 和网段格式。 |

# 2. dashboard 案例

之前的部署章节中我们是以 nodePort 和 service nodePort 的方式访问的 traefik 的 dashboard，接下来以三种方式演示通过域名访问 dashboard

## 2.1 ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traefik-dashboard
  namespace: traefik
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: ingress.test.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: traefik
            port:
              number: 9000
```

访问: [http://ingress.test.com](http://ingress.test.com)

## 2.2 ingressRoute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: dashboard
  namespace: traefik
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`traefik.test.com`)
    kind: Rule
    services:
    - name: api@internal
      kind: TraefikService
      namespace: traefik
```

访问：[http://traefik.test.com](http://traefik.test.com)

## 2.3 Gateway API

> 目前，Traefik 对 Gateway APIs 的实现是基于 v1alpha1 版本的规范，目前最新的规范是 v1alpha2，所以和最新的规范可能有一些出入的地方。

创建 gatewayClass

```yaml
apiVersion: networking.x-k8s.io/v1alpha1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controller: traefik.io/gateway-controller
```

创建 gateway

```yaml
apiVersion: networking.x-k8s.io/v1alpha1
kind: Gateway
metadata: 
  name: http-gateway
  namespace: kube-system 
spec: 
  gatewayClassName: traefik
  listeners: 
  - protocol: HTTP
    port: 80 
    routes: 
      kind: HTTPRoute
      namespaces:
        from: All
      selector:
        matchLabels:
          app: traefik
```

创建 httproute

```yaml
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: traefik-dashboard
  namespace: kube-system
  labels:
    app: traefik
spec:
  hostnames:
  - "gateway.test.com"
  rules:
  - matches:
    - path:
        type: Prefix
        value: /
    forwardTo:
    - serviceName: traefik
      port: 9000
      weight: 1
```

访问：[http://gateway.test.com](http://gateway.test.com)

# 3. myapp 环境准备

myapp1

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp1
spec:
  selector:
    matchLabels:
      app: myapp1
  template:
    metadata:
      labels:
        app: myapp1
    spec:
      containers:
      - name: myapp1
        image: ikubernetes/myapp:v1
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: myapp1
spec:
  type: ClusterIP
  selector:
    app: myapp1
  ports:
  - port: 80
    targetPort: 80
```

myapp2

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp2
spec:
  selector:
    matchLabels:
      app: myapp2
  template:
    metadata:
      labels:
        app: myapp2
    spec:
      containers:
      - name: myapp2
        image: ikubernetes/myapp:v2
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: myapp2
spec:
  type: ClusterIP
  selector:
    app: myapp2
  ports:
  - port: 80
    targetPort: 80
```

创建资源并访问测试

```bash
[root@k8s-node1 ~]# vim demo/app/myapp1.yml
[root@k8s-node1 ~]# vim demo/app/myapp2.yml
[root@k8s-node1 ~]# kubectl apply -f demo/app/
deployment.apps/myapp1 created
service/myapp1 created
deployment.apps/myapp2 created
service/myapp2 created
[root@k8s-node1 ~]# kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP   12d
myapp1       ClusterIP   10.100.229.135   <none>        80/TCP    33s
myapp2       ClusterIP   10.96.56.49      <none>        80/TCP    33s
[root@k8s-node1 ~]# curl 10.100.229.135
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
[root@k8s-node1 ~]# curl 10.96.56.49
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
```

# 4. ingressRoute

## 4.1 http 路由

实现目标：集群外部用户通过访问 [http://myapp1.test.com](http://myapp1.test.com) 域名时，将请求代理至 myapp1 应用。

创建 ingressRoute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp1
spec:
  entryPoints:
  - web              # 与 configmap 中定义的 entrypoint 名字相同
  routes:
  - match: Host(`myapp1.test.com`) # 域名
    kind: Rule
    services:
      - name: myapp1  # 与svc的name一致
        port: 80      # 与svc的port一致
```

部署

```bash
[root@k8s-node1 ~]# vim demo/ingressroute/http-myapp1.yml
[root@k8s-node1 ~]# kubectl apply -f demo/ingressroute/http-myapp1.yml
ingressroute.traefik.containo.us/myapp1 created
```

访问测试

![image-20230419131939361](https://image.lvbibir.cn/blog/image-20230419131939361.png)

## 4.2 https 路由

自签名证书

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=myapp2.test.com"
```

创建 tls 类型的 secret

```bash
kubectl create secret tls myapp2-tls --cert=tls.crt --key=tls.key
```

创建 ingressRoute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp2
spec:
  entryPoints:
    - websecure                    # 监听 websecure 这个入口点，也就是通过 443 端口来访问
  routes:
  - match: Host(`myapp2.test.com`)
    kind: Rule
    services:
    - name: myapp2
      port: 80
  tls:
    secretName: myapp2-tls         # 指定tls证书名称
```

部署

```bash
[root@k8s-node1 ~]# vim demo/ingressroute/https-myapp2.yml
[root@k8s-node1 ~]# kubectl apply -f  demo/ingressroute/https-myapp2.yml
ingressroute.traefik.containo.us/myapp2 created
```

访问测试，由于是自签名证书，所以会提示不安全

![image-20230419132537993](https://image.lvbibir.cn/blog/image-20230419132537993.png)

# 5. ingressRouteTCP

[ingreeRouteTCP 官方文档](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroutetcp)

## 5.1 不带 TLS 证书

部署 mysql

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql
  labels:
    app: mysql
  namespace: default
data:
  my.cnf: |
    [mysqld]
    character-set-server = utf8mb4
    collation-server = utf8mb4_unicode_ci
    skip-character-set-client-handshake = 1
    default-storage-engine = INNODB
    max_allowed_packet = 500M
    explicit_defaults_for_timestamp = 1
    long_query_time = 10
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mysql
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        imagePullPolicy: IfNotPresent
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: abc123
        ports:
        - containerPort: 3306
        volumeMounts:
        - mountPath: /etc/mysql/conf.d/my.cnf
          subPath: my.cnf
          name: cm
      volumes:
        - name: cm
          configMap:
            name: mysql
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: default
spec:
  ports:
    - port: 3306
      protocol: TCP
      targetPort: 3306
  selector:
    app: mysql
```

ingressRouteTCP

> SNI 为服务名称标识，是 TLS 协议的扩展。因此，只有 TLS 路由才能使用该规则指定域名。非 TLS 路由使用带有 `*` 的规则来声明每个非 TLS 请求都将由路由进行处理。

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: mysql
  namespace: default
spec:
  entryPoints:
    - tcpep  # 9200 端口
  routes:
  - match: HostSNI(`*`) # 由于 Traefik 中使用 TCP 路由配置需要 SNI，而 SNI 又是依赖 TLS 的，所以我们需要配置证书才行，如果没有证书的话，我们可以使用通配符*(适配ip)进行配置
    services:
    - name: mysql
      port: 3306
```

部署

```bash
[root@k8s-node1 ~]# vim demo/ingressrouteTCP/mysql.yml
[root@k8s-node1 ~]# kubectl apply -f demo/ingressrouteTCP/mysql.yml
configmap/mysql created
deployment.apps/mysql created
service/mysql created
[root@k8s-node1 ~]# vim demo/ingressrouteTCP/route.yml
[root@k8s-node1 ~]# kubectl apply -f  demo/ingressrouteTCP/route.yml
ingressroutetcp.traefik.containo.us/mysql created
```

集群外主机验证

- 添加 hosts (mysql.test.com)
- 以 root & abc123 访问 9200 端口

![image-20230419134852960](https://image.lvbibir.cn/blog/image-20230419134852960.png)

![image-20230419134929324](https://image.lvbibir.cn/blog/image-20230419134929324.png)

## 5.2 带 TLS 证书

大多数情况下 tcp 路由不需要配置 TLS ，下面仅演示两个关键步骤

创建 tls 类型的 secret

```bash
 kubectl create secret tls redis-tls --key=redis.key --cert=redis.crt
```

创建 ingressRouteTCP，需要携带 secret

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: redis
spec:
  entryPoints:
    - redisep
  routes:
  - match: HostSNI(`redis.test.com`)
    services:
    - name: redis
      port: 6379
  tls:
    secretName: redis-tls
```

# 6. ingressRouteUDP

创建应用

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: whoamiudp
  labels:
    app: whoamiudp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoamiudp
  template:
    metadata:
      labels:
        app: whoamiudp
    spec:
      containers:
        - name: whoamiudp
          image: traefik/whoamiudp:latest
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: whoamiudp
spec:
  ports:
    - port: 8080
      protocol: UDP
  selector:
    app: whoamiudp
```

配置 ingressRouteUDP

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteUDP
metadata:
  name: whoamiudp
spec:
  entryPoints:                  
    - udpep
  routes:                      
  - services:                  
    - name: whoamiudp                 
      port: 8080
```

直接访问 svc 验证

```bash
[root@k8s-node1 traefik]# kubectl get svc whoamiudp
NAME        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
whoamiudp   ClusterIP   10.96.119.116   <none>        8080/UDP   2m22s
[root@k8s-node1 traefik]# echo "WHO" | socat - udp4-datagram:10.96.119.116:8080
Hostname: whoamiudp-6ff7dd6fb9-8qfc7
IP: 127.0.0.1
IP: 10.244.169.174
[root@k8s-node1 traefik]# echo "test" | socat - udp4-datagram:10.96.119.116:8080
Received: test
```

访问 udp 路由验证

```bash
[root@k8s-node1 traefik]# echo "WHO" | socat - udp4-datagram:k8s-node1:9300
Hostname: whoamiudp-6ff7dd6fb9-5l8rd
IP: 127.0.0.1
IP: 10.244.107.243
[root@k8s-node1 traefik]# echo "test" | socat - udp4-datagram:1.1.1.1:9300
Received: test
```

# 7. 负载均衡

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp1
spec:
  entryPoints:
  - web              # 与 configmap 中定义的 entrypoint 名字相同
  routes:
  - match: Host(`lb.test.com`) # 域名
    kind: Rule
    services:
      - name: myapp1  # 与svc的name一致
        port: 80      # 与svc的port一致
      - name: myapp2  # 与svc的name一致
        port: 80      # 与svc的port一致
```

部署

```bash
[root@k8s-node1 ~]# vim demo/lb/lb.yml
[root@k8s-node1 ~]# kubectl apply -f  demo/lb/lb.yml
ingressroute.traefik.containo.us/myapp1 created
```

访问测试，可以发现循环相应 myapp1 和 myapp2 的内容

```bash
[root@k8s-node1 ~]# curl http://lb.test.com
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
[root@k8s-node1 ~]# curl http://lb.test.com
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
[root@k8s-node1 ~]# curl http://lb.test.com
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
[root@k8s-node1 ~]# curl http://lb.test.com
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
```
