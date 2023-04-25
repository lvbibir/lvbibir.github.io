---
title: "prometheus (一) 简介及部署" 
date: 2023-04-22
lastmod: 2023-04-22
tags: 
- kubernetes
- prometheus
keywords:
- kubernetes
- prometheus
description: "kubernetes 中部署配置 kube-prometheus, 快速搭建一套包含 node_exporter prometheus grafana alertmanager 的监控体系 " 
cover:
    image: "https://image.lvbibir.cn/blog/prometheus.png"
---

# 0. 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `kube-prometheus-0.10` `prometheus-v2.32.1`

# 1. 简介

[Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator): 在 Kubernetes 上管理 Prometheus 集群。该项目的目的是简化和自动化基于 Prometheus 的 Kubernetes 集群监控堆栈的配置。

[kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) 提供了一个基于 Prometheus 和 Prometheus Operator 的完整集群监控堆栈的示例配置。这包括部署多个 Prometheus 和 Alertmanager 实例、用于收集节点指标的指标导出器（如 node_exporters)、将 Prometheus 链接到各种指标端点的目标配置，以及用于通知集群中潜在问题的示例警报规则。

Prometheus Operator 的一个核心特性是 `watch` Kubernetes API 服务器对特定对象的更改，并确保当前 Prometheus 部署与这些对象匹配。Operator 对以下自定义资源定义 (crd) 进行操作：

`monitoring.coreos.com/v1`:

- `Prometheus`: 它定义了 Prometheus 期望的部署。
- `Alertmanager`: 它定义了 AlertManager 期望的部署。
- `ThanosRuler`: 它定义了 ThanosRuler 期望的部署；如果有多个 Prometheus 实例，则通过 `ThanosRuler` 进行告警规则的统一管理。
- `ServiceMonitor`: Prometheus Operator 通过 `PodMonitor` 和 `ServiceMonitor` 实现对资源的监控，`ServiceMonitor` 用于通过 Service 对 K8S 中的任何资源进行监控，推荐首选 `ServiceMonitor`. 它声明性地指定了 Kubernetes service 应该如何被监控。Operator 根据 API 服务器中对象的当前状态自动生成 Prometheus 刮擦配置。
- `PodMonitor`: Prometheus Operator 通过 `PodMonitor` 和 `ServiceMonitor` 实现对资源的监控，`PodMonitor` 用于对 Pod 进行监控，推荐首选 `ServiceMonitor`. `PodMonitor` 声明性地指定了应该如何监视一组 pod。Operator 根据 API 服务器中对象的当前状态自动生成 Prometheus 刮擦配置。
- `Probe`: 它声明性地指定了应该如何监视 ingress 或静态目标组。Operator 根据定义自动生成 Prometheus 刮擦配置。
- `PrometheusRule`: 用于管理 Prometheus 告警规则；它定义了一套所需的 Prometheus 警报和/或记录规则。Prometheus 生成一个规则文件，可以被 Prometheus 实例使用。
- `AlertmanagerConfig`: 用于管理 AlertManager 配置文件，主要是告警发给谁；它声明性地指定 Alertmanager 配置的子部分，允许将警报路由到自定义接收器，并设置禁止规则。

Prometheus Operator 自动检测 Kubernetes API 服务器对上述任何对象的更改，并确保匹配的部署和配置保持同步。

# 2. 部署

kubernets 与 kube-prometheus 的兼容性关系如下

| kube-prometheus stack | Kubernetes 1.21 | Kubernetes 1.22 | Kubernetes 1.23 | Kubernetes 1.24 | Kubernetes 1.25 |
| --------------------- | --------------- | --------------- | --------------- | --------------- | --------------- |
| release-0.9           | ✔               | ✔               | ✗               | ✗               | ✗               |
| release-0.10          | ✗               | ✔               | ✔               | ✗               | ✗               |
| release-0.11          | ✗               | ✗               | ✔               | ✔               | ✗               |
| release-0.12          | ✗               | ✗               | ✗               | ✔               | ✔               |

kube-prometheus 项目提供的 yaml 中使用的镜像大部分是 quay.io 或者 k8s.gcr.io 等外网仓库的镜像，博主已经将所需镜像上传到了阿里云，且 fork 官方仓库后修改了 yaml 中的镜像仓库地址，可以直接拉取我修改后的 yaml

这里我的 k8s 测试集群版本是 1.22.3，所以我部署的是 release-0.10 版本的 kube-prometheus

```bash
[root@k8s-node1 opt]# cd /opt/ && git clone https://github.com/lvbibir/kube-prometheus -b release-0.10
[root@k8s-node1 kube-prometheus]# cd /opt/kube-prometheus/
[root@k8s-node1 kube-prometheus]# kubectl create  -f manifests/setup/
[root@k8s-node1 kube-prometheus]# kubectl create  -f manifests/
```

验证

```bash
[root@k8s-node1 kube-prometheus]# kubectl get pods -n monitoring
NAME                                   READY   STATUS    RESTARTS   AGE
alertmanager-main-0                    2/2     Running   0          5m16s
alertmanager-main-1                    2/2     Running   0          5m16s
alertmanager-main-2                    2/2     Running   0          5m16s
blackbox-exporter-7c8787786-r9lmv      3/3     Running   0          8m12s
grafana-795c6dd64b-8cspz               1/1     Running   0          8m11s
kube-state-metrics-56f79b8fdc-9p97x    3/3     Running   0          8m11s
node-exporter-4scm6                    2/2     Running   0          8m11s
node-exporter-7hlrp                    2/2     Running   0          8m11s
node-exporter-pph2d                    2/2     Running   0          8m11s
prometheus-adapter-5595dcc894-nmn2w    1/1     Running   0          8m10s
prometheus-adapter-5595dcc894-rzdhv    1/1     Running   0          8m10s
prometheus-k8s-0                       2/2     Running   0          5m15s
prometheus-k8s-1                       2/2     Running   0          5m15s
prometheus-operator-7575c94984-7r4l9   2/2     Running   0          8m10s

[root@k8s-node1 kube-prometheus]# kubectl get svc -n monitoring
NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
alertmanager-main       NodePort    10.104.94.103    <none>        9093:39093/TCP,8080:10422/TCP   9m12s
alertmanager-operated   ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP      6m16s
blackbox-exporter       ClusterIP   10.103.168.130   <none>        9115/TCP,19115/TCP              9m12s
grafana                 NodePort    10.108.134.168   <none>        3000:33000/TCP                  9m11s
kube-state-metrics      ClusterIP   None             <none>        8443/TCP,9443/TCP               9m11s
node-exporter           ClusterIP   None             <none>        9100/TCP                        9m11s
prometheus-adapter      ClusterIP   10.111.22.126    <none>        443/TCP                         9m10s
prometheus-k8s          NodePort    10.111.183.173   <none>        9090:39090/TCP,8080:43263/TCP   9m11s
prometheus-operated     ClusterIP   None             <none>        9090/TCP                        6m15s
prometheus-operator     ClusterIP   None             <none>        8443/TCP                        9m10s
```

可以通过 nodePort 访问 `alertmanager prometheus grafana`，也可以通过 ingress 将 grafana 暴露到外部

grafana 默认用户名密码为 admin/admin

![image-20230422131028713](https://image.lvbibir.cn/blog/image-20230422131028713.png)

