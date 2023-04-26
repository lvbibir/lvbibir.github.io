---
title: "prometheus (三) 静态配置(probe)" 
date: 2023-04-26
lastmod: 2023-04-26
tags: 
- kubernetes
- prometheus
keywords:
- kubernetes
- prometheus
description: "prometheus-operator 中使用 CRD 资源 Probe 添加自定义 job 和 target" 
cover:
    image: "https://image.lvbibir.cn/blog/prometheus.png"
---

# 0. 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `kube-prometheus-0.10` `prometheus-v2.32.1`

# 1. 简介

k8s 集群内的 metrics 可以方便地使用 serviceMonitor 自动发现, 很多时候我们还需要添加集群外的 metrics, 通常情况下我们直接配置 prometheus 添加 `staticConfig` 即可, 然而在 prometheus-operator 中所有的配置都抽象成了 k8s `CRD` 资源, 而负责静态配置的 CRD 是 `Probe`

> Probe CRD 的 API 文档: 
>
> https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.Probe

# 2. 示例

## 2.1 node-exporter

添加 k8s 集群外的 node-exporter

在 1.1.1.4 部署 node-exporter

```bash
docker run -d --name node-exporter \
--restart=always \
-p 9100:9100 \
-v "/proc:/host/proc:ro" \
-v "/sys:/host/sys:ro"   \
-v "/:/rootfs:ro"        \
registry.cn-hangzhou.aliyuncs.com/lvbibir/node-exporter:v1.3.1

[root@1-1-1-4 ~]# curl -s 1.1.1.4:9100/metrics | head -5
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0.000326036
go_gc_duration_seconds{quantile="0.25"} 0.000326036
go_gc_duration_seconds{quantile="0.5"} 0.000714158
```

在 k8s 集群创建 Probe

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Probe
metadata:
  name: demo-probe-node-exporter
  namespace: monitoring
spec:
  jobName: demo-probe-node-exporter
  interval: 10s
  prober:
    url: localhost
    path: /metrics
  metricRelabelings:
  - sourceLabels: [__address__]
    targetLabel: target
  targets:
    staticConfig:
      static:
      - 1.1.1.4:9100
      relabelingConfigs:
      - sourceLabels: [__param_target]
        targetLabel: instance
      - sourceLabels: [__param_target]
        targetLabel: __address__
```

应用完上述配置文件后, 查看 prometheus

![image-20230426170408001](https://image.lvbibir.cn/blog/image-20230426170408001.png)

简单查询一下 `count(node_cpu_seconds_total{instance="1.1.1.4:9100",mode='system'})`

![image-20230426171733278](https://image.lvbibir.cn/blog/image-20230426171733278.png)













