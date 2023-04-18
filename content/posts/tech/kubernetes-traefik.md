---
title: "kubernetes | traefik ingress" 
date: 2023-04-17
lastmod: 2023-04-17
tags: 
- kubernetes
keywords:
- kubernetes
- traefik
- ingress
description: "kubernetes 中 Traefik ingress 的简介、部署、配置、应用示例(ingress, ingressRoute, Gateway API)、MiddleWare、负载均衡、灰度发布、流量复制。" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true
---

# 0. 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`， `traefik-2.5.7`

参考：

https://doc.traefik.io/traefik/v2.5/

https://blog.csdn.net/weixin_54720351/article/details/129714513

# 1. 简介

## 1.1 Traefik

Traefik 是一个为了让部署微服务更加便捷而诞生的现代HTTP反向代理、负载均衡工具。 它支持多种后台 ([Docker](https://www.docker.com/), [Swarm](https://docs.docker.com/swarm), [Kubernetes](http://kubernetes.io/), [Marathon](https://mesosphere.github.io/marathon/), [Mesos](https://github.com/apache/mesos), [Consul](https://www.consul.io/), [Etcd](https://coreos.com/etcd/), [Zookeeper](https://zookeeper.apache.org/), [BoltDB](https://github.com/boltdb/bolt), Rest API, file…) 来自动化、动态的应用它的配置文件设置。

![traefik-architecture](https://image.lvbibir.cn/blog/traefik-architecture.png)

Traefik 是一个边缘路由器，它会拦截外部的请求并根据逻辑规则选择不同的操作方式，这些规则决定着这些请求到底该如何处理。Traefik 提供自动发现能力，会实时检测服务，并自动更新路由规则。

![img](https://image.lvbibir.cn/blog/v2-b67cb6ed0ac457009296459fe974cef4_r.jpg)

从上图可知，请求首先会连接到 `entrypoints`，然后分析这些请求是否与定义的 `rules` 匹配，如果匹配，则会通过一系列`middlewares`，再到对应的 `services` 上。 

这就涉及到以下几个重要的核心组件:

- **[Providers](https://doc.traefik.io/traefik/providers/overview/)**
- **[Entrypoints](https://doc.traefik.io/traefik/routing/entrypoints/)**
- **[Routers](https://doc.traefik.io/traefik/routing/routers/)**
- **[Services](https://doc.traefik.io/traefik/routing/services/)**
- **[Middlewares](https://doc.traefik.io/traefik/middlewares/overview/)**

**Providers**

`Providers`是基础组件，Traefik的配置发现是通过它来实现的，它可以是协调器，容器引擎，云提供商或者键值存储。 

`Traefik`通过查询`Providers`的`API`来查询路由的相关信息，一旦检测到变化，就会动态的更新路由。 

**Entrypoints**

`Entrypoints`是`Traefik`的网络入口，它定义接收请求的接口，以及是否监听TCP或者UDP。 

**Routers**

`Routers`主要用于分析请求，并负责将这些请求连接到对应的服务上去，在这个过程中，Routers还可以使用Middlewares来更新请求，比如在把请求发到服务之前添加一些Headers。 

**Services**

`Services`负责配置如何到达最终将处理传入请求的实际服务。 

**Middlewares**

`Middlewares`用来修改请求或者根据请求来做出一些判断（authentication, rate limiting, headers, ...），中间件被附件到路由上，是一种在请求发送到你的**服务**之前（或者在服务的响应发送到客户端之前）调整请求的一种方法。 

## 1.2 Kubernetes Gateway API

Gateway API（之前叫 Service API）是由 SIG-NETWORK 社区管理的开源项目，项目地址：https://gateway-api.sigs.k8s.io/。主要原因是 Ingress 资源对象不能很好的满足网络需求，很多场景下 Ingress 控制器都需要通过定义 annotations 或者 crd 来进行功能扩展，这对于使用标准和支持是非常不利的，新推出的 Gateway API 旨在通过可扩展的面向角色的接口来增强服务网络。

![api-model](https://image.lvbibir.cn/blog/api-model.png)

Gateway API 是 Kubernetes 中的一个 API 资源集合，包括 GatewayClass、Gateway、HTTPRoute、TCPRoute、Service 等，这些资源共同为各种网络用例构建模型。

# 2. Traefik 部署

## 2.1 crd rbac configmap

/opt/traefik/crd.yml，内容较长直接复制 [官网yaml](https://doc.traefik.io/traefik/v2.5/reference/dynamic-configuration/kubernetes-crd/#definitions)

/opt/traefik/rbac.yml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: kube-system
  name: traefik-ingress-controller
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik-ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses/status
    verbs:
      - update
  - apiGroups:
      - traefik.containo.us
    resources:
      - middlewares
      - middlewaretcps
      - ingressroutes
      - traefikservices
      - ingressroutetcps
      - ingressrouteudps
      - tlsoptions
      - tlsstores
      - serverstransports
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
  - kind: ServiceAccount
    name: traefik-ingress-controller
    namespace: kube-system
```

/opt/traefik/configmap.yml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik
  namespace: kube-system
data:
  traefik.yaml: |-
    serversTransport:
      insecureSkipVerify: true          ## 略验证代理服务的 TLS 证书
    api:
      insecure: true                    ## 允许 HTTP 方式访问 API
      dashboard: true                   ## 启用 Dashboard
      debug: true                       ## 启用 Debug 调试模式
    metrics:
      prometheus: ""                    ## 配置 Prometheus 监控指标数据，并使用默认配置
    entryPoints:
      web:
        address: ":80"                  ## 配置 80 端口，并设置入口名称为 web
      websecure:
        address: ":443"                 ## 配置 443 端口，并设置入口名称为 websecure
      udpep:
        address: ":8084/udp"            ## 配置 8084 端口，并设置入口名称为 udpep，做为udp入口
    providers:
      kubernetesCRD: ""                 ## 启用 Kubernetes CRD 方式来配置路由规则
      kubernetesingress: ""             ## 启用 Kubernetes Ingress 方式来配置路由规则
      kubernetesGateway: ""             ## Kubernetes Gateway API 支持
    experimental:                       ## Kubernetes Gateway API 支持
      kubernetesGateway: true           ## Kubernetes Gateway API 支持
    log:
      filePath: ""                      ## 设置调试日志文件存储路径，如果为空则输出到控制台
      level: error                      ## 设置调试日志级别
      format: json                      ## 设置调试日志格式
    accessLog:
      filePath: ""                       ## 设置访问日志文件存储路径，如果为空则输出到控制台
      format: json                       ## 设置访问调试日志格式
      bufferingSize: 0                   ## 设置访问日志缓存行数
      filters:
        retryAttempts: true             ## 设置代理访问重试失败时，保留访问日志
        minDuration: 20                 ## 设置保留请求时间超过指定持续时间的访问日志
      fields:                           ## 设置访问日志中的字段是否保留（keep 保留、drop 不保留）
        defaultMode: keep               ## 设置默认保留访问日志字段
        names:
          ClientUsername: drop
        headers:
          defaultMode: keep             ## 设置 Header 中字段是否保留,设置默认保留 Header 中字段
          names:                        ## 针对 Header 中特别字段特别配置保留模式
            User-Agent: redact
            Authorization: drop
            Content-Type: keep
```

应用上述yaml

```bash
kubectl apply -f /opt/traefik/crd.yml
kubectl apply -f /opt/traefik/rbac.yml
kubectl apply -f /opt/traefik/configmap.yml
```

设置节点label，用于控制在哪些节点部署Traefik

```bash
kubectl label nodes --all IngressProxy=true
```

## 2.2 daemonset service

/opt/traefik/daemonset.yml

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  namespace: kube-system
  name: traefik
  labels:
    app: traefik
spec:
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-ingress-controller
      containers:
        - name: traefik
          image: traefik:v2.5.7
          args:
            - --configfile=/config/traefik.yaml
          volumeMounts:
            - mountPath: /config
              name: config
          ports:
            - name: web
              containerPort: 80
              hostPort: 80              ## 将容器端口绑定所在服务器的 80 端口
            - name: websecure
              containerPort: 443
              hostPort: 443             ## 将容器端口绑定所在服务器的 443 端口
            - name: udped
              protocol: UDP
              containerPort: 8084       ## 将容器端口绑定所在服务器的 8084 端口
              hostPort: 8084
            - name: admin
              containerPort: 8080       ## Traefik Dashboard 端口
      volumes:
        - name: config
          configMap:
            name: traefik
      tolerations:                      ## 设置容忍所有污点，防止节点被设置污点
        - operator: "Exists"
      nodeSelector:                     ## 设置node筛选器，在特定label的节点上启动
        IngressProxy: "true"
```

/opt/traefik/service.yml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: kube-system
spec:
  ports:
    - protocol: TCP
      name: web
      port: 80
    - protocol: TCP
      name: websecure
      port: 443
    - protocol: UDP
      name: udpep
      port: 8084
    - protocol: TCP
      name: admin
      port: 8080
  selector:
    app: traefik
```

应用上述yaml

```bash
kubectl apply -f /opt/traefik/daemonset.yml
kubectl apply -f /opt/traefik/service.yml
```

## 2.3 验证

```bash
[root@k8s-node1 ~]# kubectl get pod,cm,sa,svc -n kube-system | grep traefik
pod/traefik-92x8d                              1/1     Running   0              4h53m
pod/traefik-kfqgf                              1/1     Running   0              4h53m
pod/traefik-ldgnx                              1/1     Running   0              4h53m
configmap/traefik                              1      4h56m
serviceaccount/traefik-ingress-controller           1         4h56m
service/traefik          ClusterIP   10.96.240.41   <none>        80/TCP,8080/TCP,443/TCP        4h53m
```

# 3. Gateway API 部署

## 3.1 crd

内容较长，直接复制[官网yaml](https://doc.traefik.io/traefik/v2.5/reference/dynamic-configuration/kubernetes-gateway/#definitions)

```bash
[root@k8s-node1 traefik]# kubectl apply -f  gateway-api-crd.yml
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/tcproutes.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/tlsroutes.networking.x-k8s.io created
```

## 3.2 rbac

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gateway-role
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - gatewayclasses
      - gateways
      - httproutes
      - tcproutes
      - tlsroutes
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - gatewayclasses/status
      - gateways/status
      - httproutes/status
      - tcproutes/status
      - tlsroutes/status
    verbs:
      - update

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gateway-controller

roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: gateway-role
subjects:
  - kind: ServiceAccount
    name: traefik-ingress-controller
    namespace: default
```

应用yaml

```bash
[root@k8s-node1 traefik]# kubectl apply -f gateway-api-rbac.yml
clusterrole.rbac.authorization.k8s.io/gateway-role created
clusterrolebinding.rbac.authorization.k8s.io/gateway-controller created
```

# 4. traefik基础功能-路由

## 4.1 Traefik Dashboard

我们在之前的配置中开启了 Traefik 的 dashboard 功能，但是使用的 8080 端口我们并没有映射到 nodePort 上，所以目前暂时仅限集群内访问。接下来使用 `原生ingress` `ingressRoute` `Gateway API` 三种方式暴露我们的 dashboard

示例中用到的域名请自行映射，访问域名应看到如下页面

![](https://image.lvbibir.cn/blog/image-20230417162116287.png)

### 4.1.1 ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traefik-dashboard
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: ingress.traefik.local
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: traefik
            port:
              number: 8080
```

访问: http://ingress.traefik.local

### 4.1.2 ingressRoute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: kube-system
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`ingressroute.traefik.local`) && PathPrefix(`/`)
    kind: Rule
    services:
    - name: traefik
      port: 8080
```

访问：http://ingressroute.traefik.local

### 4.1.3 Gateway API

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
  - "gateway.traefik.local"
  rules:
  - matches:
    - path:
        type: Prefix
        value: /
    forwardTo:
    - serviceName: traefik 
      port: 8080
      weight: 1
```

访问：http://gateway.traefik.local

> 目前，Traefik 对 Gateway APIs 的实现是基于 v1alpha1 版本的规范，目前最新的规范是 v1alpha2，所以和最新的规范可能有一些出入的地方。

## 4.2 http 路由

创建两个应用 `foo` `bar` 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: foo
  labels:
    app: foo
spec:
  replicas: 3
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
              command: ["/bin/sh", "-c", "mkdir /usr/share/nginx/html/foo/ && echo 'foo' > /usr/share/nginx/html/foo/index.html"]
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
  replicas: 3
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
              command: ["/bin/sh", "-c", "mkdir /usr/share/nginx/html/bar/ && echo 'bar' > /usr/share/nginx/html/bar/index.html"]
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

创建 ingressRoute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: test
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`test.local`) && PathPrefix(`/foo`)
    kind: Rule
    services:
    - name: foo
      port: 80
  - match: Host(`test.local`) && PathPrefix(`/bar`)
    kind: Rule
    services:
    - name: bar
      port: 80
```

分别访问

- http://test.local/foo
- http://test.local/bar

```bash
[root@k8s-node1 traefik]# curl  http://test.local/foo/
foo
[root@k8s-node1 traefik]# curl  http://test.local/bar/
bar
```

## 4.3 https 路由

自签名证书

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=test.local"
```

创建 tls 类型的 secret

```bash
kubectl create secret tls test.local --cert=tls.crt --key=tls.key
```

创建 ingressRoute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: test-https
spec:
  entryPoints:
    - websecure     # 使用 https(443) 端口
  routes:
  - match: Host(`test.local`) && PathPrefix(`/foo`)
    kind: Rule
    services:
    - name: foo
      port: 80
  - match: Host(`test.local`) && PathPrefix(`/bar`)
    kind: Rule
    services:
    - name: bar
      port: 80
  tls:
    secretName: test-tls # 使用 tls 证书
```

分别访问

- https://test.local/foo
- https://test.local/bar

```bash
[root@k8s-node1 traefik]# curl -k https://test.local/foo/
foo
[root@k8s-node1 traefik]# curl -k https://test.local/bar/
bar
```

## 4.3 tcp 路由

### 4.3.1 部署mysql

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

### 4.3.2 traefik添加tcp端口

修改 configmap

```bash
[root@k8s-node1 traefik]# vim configmap.yml
    entryPoints:
      web:
        address: ":80"          ## 配置 80 端口，并设置入口名称为 web
      websecure:
        address: ":443"         ## 配置 443 端口，并设置入口名称为 websecure
      udpep:
        address: ":8084/udp"    ## 配置 8084 端口，并设置入口名称为 udpep，做为 udp 入口
      mysql:
        address: ":3306"        ## 配置 3306 端口，并设置入口名称为 mysql，作为 tcp 入口
[root@k8s-node1 traefik]# kubectl apply -f configmap.yml
configmap/traefik configured
```

修改 daemonset

```bash
[root@k8s-node1 traefik]# vim daemonset.yml
          ports:
            - name: web
              containerPort: 80
              hostPort: 80              ## 将容器端口绑定所在服务器的 80 端口
            - name: websecure
              containerPort: 443
              hostPort: 443             ## 将容器端口绑定所在服务器的 443 端口
            - name: udped
              protocol: UDP
              containerPort: 8084       ## 将容器端口绑定所在服务器的 8084 端口
              hostPort: 8084
            - name: admin
              containerPort: 8080       ## Traefik Dashboard 端口
            - name: mysql
              containerPort: 3306
              hostPort: 3306            ## 将容器端口绑定所在服务器的 3306 端口
[root@k8s-node1 traefik]# kubectl apply -f daemonset.yml
daemonset.apps/traefik configured
```

修改service

```bash
[root@k8s-node1 traefik]# vim service.yml
spec:
  ports:
    - protocol: TCP
      name: web
      port: 80
    - protocol: TCP
      name: websecure
      port: 443
    - protocol: UDP
      name: udpep
      port: 8084
    - protocol: TCP
      name: admin
      port: 8080
    - protocol: TCP
      name: mysql
      port: 3306
[root@k8s-node1 traefik]# kubectl apply -f service.yml
service/traefik configured
```

### 4.3.3 ingressRouteTCP

> SNI为服务名称标识，是 TLS 协议的扩展。因此，只有 TLS 路由才能使用该规则指定域名。但是，非 TLS 路由必须使用带有 `*` 的规则（每个域）来声明每个非 TLS 请求都将由路由进行处理。

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: mysql
  namespace: default
spec:
  entryPoints:
    - mysql
  routes:
  - match: HostSNI(`*`)
    services:
    - name: mysql
      port: 3306
```

集群外主机验证

- 添加 hosts 
- 以 root & abc123 访问 3306 端口

![image-20230418144253739](https://image.lvbibir.cn/blog/image-20230418144253739.png)

![image-20230418144547043](https://image.lvbibir.cn/blog/image-20230418144547043.png)

## 4.4 udp 路由

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
[root@k8s-node1 traefik]# echo "WHO" | socat - udp4-datagram:k8s-node1:8084
Hostname: whoamiudp-6ff7dd6fb9-5l8rd
IP: 127.0.0.1
IP: 10.244.107.243
[root@k8s-node1 traefik]# echo "test" | socat - udp4-datagram:1.1.1.1:8084
Received: test
```

# 5. traefik中间件Middleware

> https://doc.traefik.io/traefik/v2.5/middlewares/overview/

traefik 有丰富的中间件可以实现很多自定义功能，具体可看官方文档

## 5.1 IPWhiteList

> https://doc.traefik.io/traefik/v2.5/middlewares/http/ipwhitelist/

创建应用

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-ipwhitelist
  labels:
    app: test-ipwhitelist
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test-ipwhitelist
  template:
    metadata:
      labels:
        app: test-ipwhitelist
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: test-ipwhitelist
        image: nginx:1.22.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: test-ipwhitelist
  labels:
    app: test-ipwhitelist
spec:
  selector:
    app: test-ipwhitelist
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

创建 middleware 和 ingressroute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: test-ipwhitelist
spec:
  ipWhiteList:
    sourceRange:
      - 127.0.0.1
      - 10.244.0.0/16
      - 10.96.0.0/12
      - 1.1.1.0/24
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroutemiddle
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`middleware.test.com`) && PathPrefix(`/`)
    kind: Rule
    services:
    - name: test-ipwhitelist
      port: 80
      namespace: default
    middlewares:
    - name: test-ipwhitelist
```

测试

```bash
[root@k8s-node1 traefik]# curl -I http://middleware.test.com
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 615
Content-Type: text/html
Date: Tue, 18 Apr 2023 08:00:51 GMT
Etag: "634faf0c-267"
Last-Modified: Wed, 19 Oct 2022 08:02:20 GMT
Server: nginx/1.22.1
```

去掉白名单

```bash
[root@k8s-node1 traefik]# vim middleware/middleware-ingressroute.yml
      - 1.1.1.0/24 # 去掉这行
[root@k8s-node1 traefik]# kubectl apply -f middleware/middleware-ingressroute.yml
middleware.traefik.containo.us/test-ipwhitelist configured
ingressroute.traefik.containo.us/ingressroutemiddle unchanged
[root@k8s-node1 traefik]# curl -I http://middleware.test.com
HTTP/1.1 403 Forbidden
Date: Tue, 18 Apr 2023 08:01:42 GMT
Content-Length: 9
Content-Type: text/plain; charset=utf-8
```

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



