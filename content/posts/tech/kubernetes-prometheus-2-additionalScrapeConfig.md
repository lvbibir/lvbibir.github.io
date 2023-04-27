---
title: "prometheus (二) 静态配置" 
date: 2023-04-25
lastmod: 2023-04-25
tags: 
- kubernetes
- prometheus
keywords:
- kubernetes
- prometheus
description: "prometheus-operator 中使用 additionalScrapeConfig 添加自定义 job 和 target" 
cover:
    image: "https://image.lvbibir.cn/blog/prometheus.png"
---

# 0. 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `kube-prometheus-0.10` `prometheus-v2.32.1`

# 1. 简介

> https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/additional-scrape-config.md

使用原生的 prometheus 时, 我们创建 job 直接修改配置文件即可, 然而在 prometheus-operator 中所有的配置都抽象成了 k8s `CRD` 资源, 手动配置 job 需要:

- 创建 secret
- 在 prometheus CRD 资源中配置 `additionalScrapeConfigs`

# 2. 示例

## 2.1 node-exporter

添加 k8s 集群外的 node-exporter metrics

在 1.1.1.4 部署 node-exporter

```bash
docker run -d --name node-exporter \
-p 9100:9100 \
-v "/proc:/host/proc:ro" \
-v "/sys:/host/sys:ro"   \
-v "/:/rootfs:ro"        \
registry.cn-hangzhou.aliyuncs.com/lvbibir/node-exporter:v1.3.1 \
--path.sysfs=/host/sys \
--path.rootfs=/roofs 

# 验证可用性
[root@1-1-1-4 ~]# curl -s 1.1.1.4:9100/metrics | head -5
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0.000326036
go_gc_duration_seconds{quantile="0.25"} 0.000326036
go_gc_duration_seconds{quantile="0.5"} 0.000714158
```

创建 job 配置 `prometheus-additional.yaml`

```yaml
- job_name: "node-exporter"
  static_configs:
  - targets: 
    - "1.1.1.4:9100"
```

创建 secret `additional-scrape-configs.yaml`

```bash
[root@k8s-node1 demo]# kubectl create secret generic additional-scrape-configs --from-file=prometheus-additional.yaml --dry-run -oyaml > additional-scrape-configs.yaml
[root@k8s-node1 demo]# kubectl apply -f additional-scrape-configs.yaml -n monitoring
secret/additional-scrape-configs created
```

修改 prometheus 资源 `prometheus-prometheus.yaml` , 添加 `additionalScrapeConfigs`

```yaml
kind: Prometheus
spec:
  # 添加如下三行
  additionalScrapeConfigs:
    name: additional-scrape-configs  # secret name
    key: prometheus-additional.yaml  # secret key
```

更新一下 prometheus

```bash
[root@k8s-node1 demo]# kubectl apply -f  ../prometheus-prometheus.yaml
```

查看结果

![image-20230427151927477](https://image.lvbibir.cn/blog/image-20230427151927477.png)

# 3. 动态更新

后续所有的自定义配置直接更新现有的 secret 即可

比如在之前的 node-exporter 的 job 中新增一个 target

修改 `prometheus-additional.yaml` 

```yaml
- job_name: "node-exporter"
  static_configs:
  - targets:
    - "1.1.1.4:9100"
    - "192.168.17.99:59100"
```

更新 secret

```bash
[root@k8s-node1 demo]# kubectl create secret generic additional-scrape-configs --from-file=prometheus-additional.yaml --dry-run -oyaml > additional-scrape-configs.yaml
W0427 15:15:52.834817   88217 helpers.go:555] --dry-run is deprecated and can be replaced with --dry-run=client.
[root@k8s-node1 demo]# kubectl apply -f additional-scrape-configs.yaml -n monitoring
secret/additional-scrape-configs configured
```

prometheus 会自动重载配置

![image-20230427152718192](https://image.lvbibir.cn/blog/image-20230427152718192.png)