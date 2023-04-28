---
title: "prometheus (四) 黑盒监控" 
date: 2023-04-27
lastmod: 2023-04-27
tags: 
- kubernetes
- prometheus
keywords:
- kubernetes
- prometheus
description: "prometheus-operator 中使用 probe CRD 资源和 blackbox 添加黑盒监控项" 
cover:
    image: "https://image.lvbibir.cn/blog/prometheus.png"
---

# 0. 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `kube-prometheus-0.10` `prometheus-v2.32.1`

# 1. 简介

[Probe 的 API 文档](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.Probe) 

## 1.1 白盒监控vs黑盒监控

白盒监控: 我们监控主机的资源用量、容器的运行状态、数据库中间件的运行数据、自动发现 Kubernetes 集群中的资源等等，这些都是支持业务和服务的基础设施，通过白盒能够了解其内部的实际运行状态，通过对监控指标的观察能够预判可能出现的问题，从而对潜在的不确定因素进行优化

黑盒监控: 以用户的身份测试服务的外部可见性，常见的黑盒监控包括 `HTTP 探针` `TCP 探针` 等用于检测站点或者服务的可访问性，以及访问效率等。

黑盒监控相较于白盒监控最大的不同在于黑盒监控是以故障为导向当故障发生时，黑盒监控能快速发现故障，而白盒监控则侧重于主动发现或者预测潜在的问题。一个完善的监控目标是要能够从白盒的角度发现潜在问题，能够在黑盒的角度快速发现已经发生的问题。

## 1.2 blackbox exporter

[Blackbox Exporter](https://github.com/prometheus/blackbox_exporter) 是 Prometheus 社区提供的官方黑盒监控解决方案，其允许用户通过 `HTTP` `HTTPS` `DNS` `TCP` `ICMP` 以及 `gPRC` 的方式对 `endpoints` 端点进行探测。

在 kube-prometheus 的默认配置中已经部署了 Blackbox Exporter 以供用户使用

```bash
[root@k8s-node1 kube-prometheus]# ls manifests/blackboxExporter-* | cat
manifests/blackboxExporter-clusterRoleBinding.yaml
manifests/blackboxExporter-clusterRole.yaml
manifests/blackboxExporter-configuration.yaml
manifests/blackboxExporter-deployment.yaml
manifests/blackboxExporter-serviceAccount.yaml
manifests/blackboxExporter-serviceMonitor.yaml
manifests/blackboxExporter-service.yaml
```

## 1.3 Probe CRD

prometheus-operator 提供了一个 Probe CRD 对象，可以用来进行黑盒监控，具体的探测功能由 Blackbox-exporter 实现。

Probe 支持 `staticConfig` 和 `ingress` 两种配置方式, 使用 ingress 时可以自动发现 ingress 代理的 url 并进行探测

大概步骤:

- 首先，用户创建一个 Probe CRD 对象，对象中指定探测方式、探测目标等参数；
- 然后，prometheus-operator watch 到 Probe 对象创建，然后生成对应的 prometheus 拉取配置，reload 到prometheus 中；
- 最后，prometheus 使用 url=/probe?target={探测目标}&module={探测方式}，拉取 blackbox-exporter ，此时 blackbox-exporter 会对目标进行探测，并以 metrics 格式返回探测结果；

![3526046601-63e4a22006154_fix732](https://image.lvbibir.cn/blog/3526046601-63e4a22006154_fix732.png)

# 2. 示例

## 2.1 staticConfig

### 2.1.1 kube-dns

使用黑盒监控监测 kube-dns 的可用性

默认配置下的 blackbox exporter 未开启 `dns` 模块, 我们手动开启一下

修改 blackboxExporter-configuration.yaml 文件, 添加 dns 模块

```yaml
apiVersion: v1
data:
  config.yml: |-
    "modules":
      "dns":  # DNS 检测模块
        "prober": "dns"
        "dns":
          "transport_protocol": "tcp"  # 默认是 udp
          "preferred_ip_protocol": "ip4"  # 默认是 ip6
          "query_name": "kubernetes.default.svc.cluster.local"
```

更新 configmap 配置文件, prometheus-opertor 会 watch 到更新然后通过 pod 中的 `module-configmap-reloader` 容器通知 blackbox-exporter 重载配置

```bash
# 每个 blackbox-exporter POD 中有三个 container
[root@k8s-node1 manifests]# kubectl get pods -n monitoring -l app.kubernetes.io/name=blackbox-exporter \
-o jsonpath='{.items[*].spec.containers[*].name}{"\n"}'
blackbox-exporter module-configmap-reloader kube-rbac-proxy

[root@k8s-node1 manifests]# kubectl apply -f  blackboxExporter-configuration.yaml
configmap/blackbox-exporter-configuration configured
[root@k8s-node1 manifests]# kubectl logs -n monitoring -l app.kubernetes.io/name=blackbox-exporter | tail -2
level=info ts=2023-04-23T02:23:49.614Z caller=tls_config.go:191 msg="TLS is disabled." http2=false
level=info ts=2023-04-28T06:40:48.168Z caller=main.go:278 msg="Reloaded config file"
```

创建 Probe CRD 资源

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Probe
metadata:
  name: blackbox-kube-dns
  namespace: monitoring
spec:
  jobName: blackbox-kube-dns
  interval: 10s
  module: dns
  prober:                        # 指定blackbox的地址
    url: blackbox-exporter:19115 # blackbox-exporter 的 地址 和 端口
    path: /probe                 # 路径
  targets:
    staticConfig:
      static:
      - kube-dns.kube-system:53   # 要检测的 url
```

查看生成的 target

![image-20230428151921527](https://image.lvbibir.cn/blog/image-20230428151921527.png)

现在可以通过:

- `probe_success{job="blackbox-kube-dns"}` 查看服务状态是否可用
- `probe_dns_lookup_time_seconds{job='blackbox-kube-dns'}` DNS解析耗时

查看 blackbox exporter 一次 dns 探测生成的 metrics 指标

![image-20230428160521908](https://image.lvbibir.cn/blog/image-20230428160521908.png)

### 2.2.1 http

http 探测一般使用 `http_2xx` 模块, 虽然默认有这个模块, 但是默认的配置不太合理, 我们修改一下

```yaml
apiVersion: v1
data:
  config.yml: |-
    "modules":
      "dns":  # DNS 检测模块
        "prober": "dns"
        "dns":
          "transport_protocol": "tcp"  # 默认是 udp
          "preferred_ip_protocol": "ip4"  # 默认是 ip6
          "query_name": "kubernetes.default.svc.cluster.local"
      "http_2xx":
        "http":
          "preferred_ip_protocol": "ip4"
          "valid_status_codes": "[200]"    # 最好加上状态码, 方便 grafana 展示数据
          "valid_http_versions": ["HTTP/1.1", "HTTP/2"]
          "method": "GET"
        "prober": "http"
```

更新配置

```bash
[root@k8s-node1 manifests]# kubectl apply -f  blackboxExporter-configuration.yaml
configmap/blackbox-exporter-configuration configured
```

快速创建一个 nginx 应用

```bash
kubectl create deployment nginx --image=nginx:1.22.1 --port=80
kubectl expose deployment nginx --name=nginx --port=80 --target-port=80
```

创建 Probe 资源

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Probe
metadata:
  name: blackbox-http-nginx
  namespace: monitoring
spec:
  jobName: blackbox-http-nginx 
  prober:
    url: blackbox-exporter:19115
    path: /probe
  module: http_2xx # 配置文件中的检测模块
  targets: 
    staticConfig:
      static:
        - nginx.default
```

查看生成的 target

![image-20230428162821972](https://image.lvbibir.cn/blog/image-20230428162821972.png)

查看一次 http 探测生成的 metrics 指标

![image-20230428163153649](https://image.lvbibir.cn/blog/image-20230428163153649.png)

## 2.2 ingress

接下来使用 ingrss 自动发现实现集群内的 ingress 并进行黑盒探测

先创建两个 web 应用

```bash
kubectl create deployment web-1 --image=nginx:1.22.1 --port=80
kubectl expose deployment web-1 --name=web-1 --port=80 --target-port=80

kubectl create deployment web-2 --image=nginx:1.22.1 --port=80
kubectl expose deployment web-2 --name=web-2 --port=80 --target-port=80
```

创建 ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-web
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: web1.test.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: web-1
            port:
              number: 80
  - host: web2.test.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: web-2
            port:
              number: 80              
```

部署并访问测试

```bash
[root@k8s-node1 manifests]# curl -sI web1.test.com | head -1
HTTP/1.1 200 OK
[root@k8s-node1 manifests]# curl -sI web2.test.com | head -1
HTTP/1.1 200 OK
```

创建 probe

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Probe
metadata:
  name: blackbox-http-nginx
  namespace: monitoring
spec:
  jobName: blackbox-http-nginx 
  prober:
    url: blackbox-exporter:19115
    path: /probe
  module: http_2xx # 配置文件中的检测模块
  targets:
    ingress:
```



