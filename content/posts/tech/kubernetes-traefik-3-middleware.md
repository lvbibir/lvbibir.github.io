---
title: "traefik (三) 中间件(Middleware)" 
date: 2023-04-18
lastmod: 2023-04-18
tags: 
- traefik
- kubernetes
keywords:
- kubernetes
- traefik
- ingressroute
description: "kubernetes 中使用 Traefik ingress 的 Middleware 实现重定向、白名单、用户认证、限流、熔断、压缩、自定义error页等操作" 
cover:
    image: "https://image.lvbibir.cn/blog/traefik.png"
---

# 0. 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`， `traefik-2.9.10`

示例中用到的 `myapp` 和 `secret` 资源请查看系列文章第二篇中的演示

# 1. 简介

[官方文档](https://doc.traefik.io/traefik/middlewares/overview/ )

Traefik Middlewares 是一个处于路由和后端服务之前的中间件，在外部流量进入 Traefik，且路由规则匹配成功后，将流量发送到对应的后端服务前，先将其发给中间件进行一系列处理（类似于过滤器链 Filter，进行一系列处理），例如，添加 Header 头信息、鉴权、流量转发、处理访问路径前缀、IP 白名单等等，经过一个或者多个中间件处理完成后，再发送给后端服务，这个就是中间件的作用。
Traefik内置了很多不同功能的Middleware，主要是针对HTTP和TCP，这里挑选几个比较常用的进行演示。

## 1.1 重定向-redirectScheme

[官方文档](https://doc.traefik.io/traefik/middlewares/http/redirectscheme/)

定义一个 ingressroute，包含一个自动将 http 跳转到 https 的中间件

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp2
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`myapp2.test.com`)
    kind: Rule
    services:
    - name: myapp2
      port: 80
    middlewares:
    - name: redirect-https-middleware   # 指定使用RedirectScheme中间件，完成http强制跳转至https
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: redirect-https-middleware
spec:
  redirectScheme:
    scheme: https   # 自动跳转到 https
```

测试，可以看到访问 http 自动 307 重定向到了 https

```bash
[root@k8s-node1 ~]# curl -I http://myapp2.test.com
HTTP/1.1 307 Temporary Redirect
Location: https://myapp2.test.com/
Date: Wed, 19 Apr 2023 07:58:34 GMT
Content-Length: 18
Content-Type: text/plain; charset=utf-8
```



## 1.2 去除请求路径前缀-stripPrefix

[官方文档](https://doc.traefik.io/traefik/middlewares/http/stripprefix/)

假设现在有这样一个需求，当访问 `http://myapp.test.com/v1` 时，流量调度至 myapp1。当访问 `http://myapp.test.com/v2` 时，流量调度至 myapp2。这种需求是非常常见的，在 NGINX 中，我们可以配置多个 Location 来定制规则，使用 Traefik 也可以这么做。但是定制不同的前缀后，由于应用本身并没有这些前缀，导致请求返回 404，这时候我们就需要对请求的 path 进行处理。

创建一个 IngressRoute，并设置两条规则，根据不同的访问路径代理至相对应的 service

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`myapp.test.com`) && PathPrefix(`/v1`)
    kind: Rule
    services:
    - name: myapp1
      port: 80
    middlewares:
    - name: prefix-url-middleware
  - match: Host(`myapp.test.com`) && PathPrefix(`/v2`)
    kind: Rule
    services:
    - name: myapp2
      port: 80
    middlewares:
    - name: prefix-url-middleware
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: prefix-url-middleware
spec:
  stripPrefix: # 去除前缀的中间件 stripPrefix，指定将请求路径中的v1、v2去除。
    prefixes: 
      - /v1
      - /v2
```

部署测试

```bash
[root@k8s-node1 ~]# curl http://myapp.test.com/v1
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
[root@k8s-node1 ~]# curl http://myapp.test.com/v2
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>

[root@k8s-node1 ~]# kubectl logs -l app=myapp1 | tail -2
# 未添加插件的访问路径为 /v1/ 
10.244.36.64 - - [19/Apr/2023:08:02:03 +0000] "GET /v1/ HTTP/1.1" 404 169 "-" "curl/7.29.0" "1.1.1.1"
# 添加插件后的访问路径为 /
10.244.36.64 - - [19/Apr/2023:08:04:31 +0000] "GET / HTTP/1.1" 200 65 "-" "curl/7.29.0" "1.1.1.1"
```

## 1.3 白名单-IPWhiteList

[官方文档](https://doc.traefik.io/traefik/middlewares/http/ipwhitelist/)

为提高安全性，通常情况下一些管理员界面会设置 ip 访问白名单，只希望个别用户可以访问。

示例

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`myapp1.test.com`) 
    kind: Rule
    services:
    - name: myapp1
      port: 80
    middlewares:
    - name: ip-white-list-middleware
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: ip-white-list-middleware
spec:
  ipWhiteList:
    sourceRange:
      - 127.0.0.1/32
      - 1.1.1.253
```

测试

```bash
# 白名单外主机
[root@k8s-node1 ~]# curl -I http://myapp1.test.com
HTTP/1.1 403 Forbidden

# 白名单内主机
Admin@BJLPT0152 MINGW64 ~
$ ipconfig | grep 1.1.1.253
   IPv4 地址 . . . . . . . . . . . . : 1.1.1.253

Admin@BJLPT0152 MINGW64 ~
$ curl -i  http://myapp1.test.com
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
```

## 1.4 基础用户认证-basicAuth

[官方文档](https://doc.traefik.io/traefik/middlewares/http/basicauth/)

通常企业安全要求规范除了要对管理员页面限制访问ip外，还需要添加账号密码认证，而 traefik 默认没有提供账号密码认证功能，此时就可以通过BasicAuth 中间件完成用户认证，只有认证通过的授权用户才可以访问页面。

安装 htpasswd 工具生成密码文件

```bash
[root@k8s-node1 ~]# yum install -y httpd
[root@k8s-node1 ~]# htpasswd -bc basic-auth-secret-lvbibir lvbibir 123
Adding password for user lvbibir
[root@k8s-node1 ~]# kubectl create secret generic basic-auth-lvbibir --from-file=basic-auth-secret-lvbibir
secret/basic-auth-lvbibir created
```

创建 ingressroute，使用 basicAuth 中间件

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`myapp1.test.com`) 
    kind: Rule
    services:
    - name: myapp1
      port: 80
    middlewares:
    - name: basic-auth-middleware
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: basic-auth-middleware
spec:
  basicAuth:
    secret: basic-auth-lvbibir
```

访问测试，可以看到弹出界面提示需要输入用户名和密码，输入后回车显示正常页面

![image-20230419163142212](https://image.lvbibir.cn/blog/image-20230419163142212.png)



## 1.5 修改请求/响应头信息-headers

[官方文档](https://doc.traefik.io/traefik/middlewares/http/headers/)

为了提高业务的安全性，安全团队会定期进行漏洞扫描，其中有些 web 漏洞就需要通过修改响应头处理，traefik 的 Headers 中间件不仅可以修改返回客户端的响应头信息，还能修改反向代理后端 service 服务的请求头信息。

例如对 `https://myapp2.test.com` 提高安全策略，强制启用HSTS
HSTS：即 HTTP 严格传输安全响应头，收到该响应头的浏览器会在 63072000s（约 2 年）的时间内，只要访问该网站，即使输入的是 http，浏览器会自动跳转到 https。（HSTS 是浏览器端的跳转，之前的HTTP 重定向到 HTTPS是服务器端的跳转）

创建 ingressRoute 和 headers 中间件

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp2-tls
spec:
  entryPoints:
  - web
  - websecure
  routes:
  - match: Host(`myapp2.test.com`)
    kind: Rule
    services:
    - name: myapp2
      port: 80 
    middlewares:
      - name: hsts-header-middleware
  tls:
    secretName: myapp2-tls         # 指定tls证书名称
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: hsts-header-middleware
spec:
  headers:
    customResponseHeaders:
      Strict-Transport-Security: 'max-age=63072000'
```

访问测试

```bash
[root@k8s-node1 ~]# curl -kI https://myapp2.test.com
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 65
Content-Type: text/html
Date: Wed, 19 Apr 2023 08:37:07 GMT
Etag: "5a9251f0-41"
Last-Modified: Sun, 25 Feb 2018 06:04:32 GMT
Server: nginx/1.12.2
Strict-Transport-Security: max-age=63072000   # headers 插件添加的响应头
```

## 1.6 限流-rateLimit

[官方文档](https://doc.traefik.io/traefik/middlewares/http/ratelimit/)

在实际生产环境中，流量限制也是经常用到的，它可以用作安全目的，比如可以减慢暴力密码破解的速率。通过将传入请求的速率限制为真实用户的典型值，并标识目标URL地址(通过日志)，还可以用来抵御 DDOS 攻击。更常见的情况，该功能被用来保护下游应用服务器不被同时太多用户请求所压垮。

创建 ingressRoute 和 rateLimit 中间件

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp1
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`myapp1.test.com`)
    kind: Rule
    services:
    - name: myapp1  
      port: 80   
    middlewares:
      - name: rate-limit-middleware
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit-middleware
spec: 
  rateLimit:    # 指定 1s 内请求数平均值不大于 10 个，高峰最大值不大于 50 个。
    burst: 10
    average: 50
```

压力测试，使用ab工具进行压力测试，一共请求 100 次，每次并发 10。测试结果失败的请求为 72 次，总耗时 0.409 秒

```bash
[root@k8s-node1 ~]# ab -n 100 -c 10 "http://myapp1.test.com/"

Concurrency Level:      10
Time taken for tests:   0.409 seconds
Complete requests:      100
Failed requests:        72
   (Connect: 0, Receive: 0, Length: 72, Exceptions: 0)
Non-2xx responses:      72
```

## 1.7 熔断-circuitBreaker

[官方文档](https://doc.traefik.io/traefik/middlewares/http/circuitbreaker/)

服务熔断的作用类似于保险丝，当某服务出现不可用或响应超时的情况时，为了防止整个系统出现雪崩，暂时停止对该服务的调用。

熔断器三种状态

- Closed：关闭状态，所有请求都正常访问。
- Open：打开状态，所有请求都会被降级。traefik 会对请求情况计数，当一定时间内失败请求百分比达到阈值，则触发熔断，断路器会完全打开。
- Recovering：半开恢复状态，open 状态不是永久的，打开后会进入休眠时间。随后断路器会自动进入半开状态。此时会释放部分请求通过，若这些请求都是健康的，则会完全关闭断路器，否则继续保持打开，再次进行休眠计时

服务熔断原理(断路器的原理)
统计用户在指定的时间范围（默认10s）之内的请求总数达到指定的数量之后，如果不健康的请求(超时、异常)占总请求数量的百分比（50%）达到了指定的阈值之后，就会触发熔断。触发熔断，断路器就会打开(open),此时所有请求都不能通过。在5s之后，断路器会恢复到半开状态(half open)，会允许少量请求通过，如果这些请求都是健康的，那么断路器会回到关闭状态(close).如果这些请求还是失败的请求,断路器还是恢复到打开的状态(open).

traefik支持的触发器

- NetworkErrorRatio：网络错误率
- ResponseCodeRatio：状态代码比率
- LatencyAtQuantileMS：分位数的延迟（以毫秒为单位）

创建 ingressRoute ，添加 circuitBreaker 中间件，指定 50% 的请求比例响应时间大于 1MS 时熔断。

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp1
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`myapp1.test.com`)
    kind: Rule
    services:
    - name: myapp1  
      port: 80   
    middlewares:
      - name: circuit-breaker-middleware
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: circuit-breaker-middleware
spec:
  circuitBreaker:
    expression: LatencyAtQuantileMS(50.0) > 1
```

压力测试，一共请求 1000 次，每次并发 100 次。触发熔断机制，测试结果失败的请求为 999 次，总耗时 1.742 秒。

```bash
[root@k8s-node1 traefik]# ab -n 1000 -c 100  "http://myapp1.test.com/"
Concurrency Level:      100
Time taken for tests:   1.742 seconds
Complete requests:      1000
Failed requests:        999
   (Connect: 0, Receive: 0, Length: 2, Exceptions: 0)
Write errors:           0
Non-2xx responses:      999
```

## 1.8 自定义错误页-errorPages

[官方文档](https://doc.traefik.io/traefik/middlewares/http/errorpages/)

在实际的业务中，肯定会存在 `4XX` `5XX` 相关的错误异常，如果每个应用都开发一个单独的错误页，无疑大大增加了开发成本，traefik 同样也支持自定义错误页，但是需要注意的是，错误页面不是由 traefik 存储处理，而是通过定义中间件，将错误的请求重定向到其他的页面。

首先，我们先创建一个应用。这个web应用的功能是：

- 当请求 / 时，返回状态码为 200
- 当请求 /400 时，返回 400 状态码
- 当请求 /500 时，返回 500 状态码

创建 deployment svc

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask
spec:
  selector:
    matchLabels:
      app: flask
  template:
    metadata:
      labels:
        app: flask
    spec:
      containers:
      - name: flask
        image: cuiliang0302/request-code:v2.0
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: flask
spec:
  type: ClusterIP
  selector:
    app: flask
  ports:
  - port: 5000
    targetPort: 5000
```

创建 ingressRoute

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: flask
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`flask.test.com`)
    kind: Rule
    services:
    - name: flask  
      port: 5000 
```

访问测试，模拟 400 500 错误

```bash
[root@k8s-node1 ~]# curl -I http://flask.test.com
HTTP/1.1 200 OK

[root@k8s-node1 ~]# curl -I http://flask.test.com/400
HTTP/1.1 400 Bad Request

[root@k8s-node1 ~]# curl -I http://flask.test.com/500
HTTP/1.1 500 Internal Server Error

[root@k8s-node1 ~]# curl -I http://flask.test.com/404
HTTP/1.1 404 Not Found
```

现在提出一个新的需求，当我访问flask项目时，如果错误码为400，返回myapp1的页面，如果错误码为500，返回myapp2的页面(前提是myapp1和myapp2服务已创建)。

创建 errors 中间件

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: errors5
spec:
  errors:
    status:
      - "500-599"
    # query: /{status}.html   # 可以为每个页面定义一个状态码，也可以指定5XX使用统一页面返回
    query : /                 # 指定返回myapp2的请求路径
    service:
      name: myapp2
      port: 80
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: errors4
spec:
  errors:
    status:
      - "400-499"
    # query: /{status}.html   # 可以为每个页面定义一个状态码，也可以指定5XX使用统一页面返回
    query : /                 # 指定返回myapp1的请求路径
    service:
      name: myapp1
      port: 80
```

修改 ingressRoute 

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: flask
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`flask.test.com`)
    kind: Rule
    services:
    - name: flask  
      port: 5000
    middlewares:
      - name: errors4
      - name: errors5
```

访问测试，可以看到 400 页面和 500 页面已经成功重定向了

```bash
[root@k8s-node1 ~]# curl http://flask.test.com/
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>flask</title>
</head>
<body>
<h1>hello flask</h1>
<img src="/static/photo.jpg" alt="photo">
</body>
</html>

[root@k8s-node1 ~]# curl http://flask.test.com/400
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>

[root@k8s-node1 ~]# curl http://flask.test.com/500
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>
```

## 1.9 数据压缩-compress

[官方文档](https://doc.traefik.io/traefik/middlewares/http/compress/)

有时候客户端和服务器之间会传输比较大的报文数据，这时候就占用较大的网络带宽和时长。为了节省带宽，加速报文的响应速速，可以将传输的报文数据先进行压缩，然后再进行传输，traefik也同样支持数据压缩。

traefik 默认只对大于 1024 字节，且请求标头包含 `Accept-Encoding gzip` 的资源进行压缩。可以指定排除特定类型不启用压缩或者根据内容大小来决定是否压缩。

继续使用上面创建的flask应用，现在创建中间件并修改 ingressRoute，使用默认配置策略即可。

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: flask
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`flask.test.com`)
    kind: Rule
    services:
    - name: flask  
      port: 5000
    middlewares:
      - name: compress
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: compress
spec:
  compress: {}  
```

访问测试

html 文件小于 1024 字节，未开启压缩

![image-20230419175108058](https://image.lvbibir.cn/blog/image-20230419175108058.png)

图片资源大于 1024 字节，开启了压缩

![image-20230419175324586](https://image.lvbibir.cn/blog/image-20230419175324586.png)
