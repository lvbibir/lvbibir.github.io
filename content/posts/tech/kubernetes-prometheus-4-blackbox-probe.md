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
description: "prometheus-operator 中使用 additionalScrapeConfig 添加自定义 job 和 target" 
cover:
    image: "https://image.lvbibir.cn/blog/prometheus.png"
---

> Probe CRD 的 API 文档: 
>
> https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.Probe

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





