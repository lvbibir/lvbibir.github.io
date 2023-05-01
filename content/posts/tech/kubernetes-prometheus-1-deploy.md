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
description: "kubernetes 中部署配置 prometheus-operator, 快速搭建一套包含 node_exporter prometheus grafana alertmanager 的监控体系 " 
cover:
    image: "https://image.lvbibir.cn/blog/prometheus.png"
---

# 0. 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `kube-prometheus-0.10` `prometheus-v2.32.1`

# 1. 简介

## 1.1 prometheus operator

[Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator): 在 Kubernetes 上管理 Prometheus 集群。该项目的目的是简化和自动化基于 Prometheus 的 Kubernetes 集群监控堆栈的配置。

[所有 CRD 资源的 API 文档](https://prometheus-operator.dev/docs/operator/api/)

Prometheus Operator 的核心特性是 `watch` Kubernetes API 服务器对特定对象的更改，并确保当前 Prometheus 部署与这些对象匹配。

`monitoring.coreos.com/v1`:

- prometheus 相关
  - `Prometheus`: 配置 Prometheus statefulset 及 Prometheus 的一些配置。
  - `ServiceMonitor`: 用于通过 Service 对 K8S 中的资源进行监控，推荐首选 `ServiceMonitor`. 它声明性地指定了 Kubernetes service 应该如何被监控。
  - `PodMonitor`: 用于对 Pod 进行监控，推荐首选 `ServiceMonitor`. `PodMonitor` 声明性地指定了应该如何监视一组 pod。
  - `Probe`: 它声明性地指定了应该如何监视 ingress 或静态目标组. 一般用于黑盒监控.
  - `PrometheusRule`: 用于管理 Prometheus 告警规则；它定义了一套所需的 Prometheus 警报和/或记录规则。可以被 Prometheus 实例挂载使用。

- Alertmanager 相关
  - `Alertmanager`: 配置 AlertManager statefulset 及 AlertManager 的一些配置。
  - `AlertmanagerConfig`: 用于管理 AlertManager 配置文件；它声明性地指定 Alertmanager 配置的子部分，允许将警报路由到自定义接收器，并设置禁止规则。
- 其他
  - `ThanosRuler`: 管理 ThanosRuler deployment；

## 1.2 kube-prometheus

[kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) 提供了一个基于 Prometheus 和 Prometheus Operator 的完整集群监控堆栈的示例配置。这包括部署多个 Prometheus 和 Alertmanager 实例、用于收集节点指标的指标导出器（如 node_exporters)、将 Prometheus 链接到各种指标端点的目标配置，以及用于通知集群中潜在问题的示例警报规则。

# 2. 部署

kubernets 与 kube-prometheus 的兼容性关系如下

| kube-prometheus stack | Kubernetes 1.21 | Kubernetes 1.22 | Kubernetes 1.23 | Kubernetes 1.24 | Kubernetes 1.25 |
| --------------------- | --------------- | --------------- | --------------- | --------------- | --------------- |
| release-0.9           | ✔               | ✔               | ✗               | ✗               | ✗               |
| release-0.10          | ✗               | ✔               | ✔               | ✗               | ✗               |
| release-0.11          | ✗               | ✗               | ✔               | ✔               | ✗               |
| release-0.12          | ✗               | ✗               | ✗               | ✔               | ✔               |

kube-prometheus 项目提供的 yaml 中使用的镜像大部分是 quay.io 或者 k8s.gcr.io 等外网仓库的镜像，博主已经将所需镜像上传到了阿里云，且 fork 官方仓库后修改了 yaml 中的镜像仓库地址，可以直接拉取我修改后的 yaml

这里我的 k8s 测试集群版本是 1.22.3，部署 release-0.10 版本的 kube-prometheus

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

可以通过 nodePort 访问，也可以通过 ingress 将 grafana 暴露到外部

grafana 默认用户名密码为 admin/admin

![image-20230422131028713](https://image.lvbibir.cn/blog/image-20230422131028713.png)

# 3. 数据持久化

## 3.1 prometheus

prometheus 默认的数据文件使用的是 emptydir 方式进行的持久化, 我们改为 nfs

修改 `manifests/prometheus-prometheus.yaml`

在文件最后新增配置

```yaml
  retention: 15d          # 监控数据保存的时间为 15 天
  storage:                # 存储配置, 使用 nfs 的 storageClass
    volumeClaimTemplate:
      spec:
        storageClassName: "nfs"
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 10Gi
```

应用后查看新建的 pod 中的 volumes 信息

```bash
# pod.spec.container.volumeMounts
[root@k8s-node1 ~]# kubectl get pod prometheus-k8s-0 -n monitoring -o jsonpath='{.spec.containers[?(@.name=="prometheus")].volumeMounts[?(@.name=="prometheus-k8s-db")]}{"\n"}' | python -m json.tool
{
    "mountPath": "/prometheus",
    "name": "prometheus-k8s-db",
    "subPath": "prometheus-db"
}

# pod.spec.volumes
[root@k8s-node1 ~]# kubectl get pod prometheus-k8s-0 -n monitoring -o jsonpath='{.spec.volumes[?(@.name=="prometheus-k8s-db")]}' | python -m json.tool
{
    "name": "prometheus-k8s-db",
    "persistentVolumeClaim": {
        "claimName": "prometheus-k8s-db-prometheus-k8s-0"
    }
}
```

与传统 statefulset 不同的是, prometheus 识别到 `.spec.storage.volumeClaimTemplate` 配置后会自动将 prometheus 的数据文件挂载到自动创建的 pvc 上, 无需手动指定 name 然后挂载

## 3.2 alertmanager

与 prometheus 类似, 这里就不赘述了

`manifests/alertmanager-alertmanager.yaml`

```yaml
  storage:                # 存储配置, 使用 nfs 的 storageClass
    volumeClaimTemplate:
      spec:
        storageClassName: "nfs"
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
```

重新 apply 之后, 查看新生成 pod 的 volumes

```bash
# pod.spec.container.volumeMounts
[root@k8s-node1 ~]# kubectl get pod alertmanager-main-0 -n monitoring -o jsonpath='{.spec.containers[?(@.name=="alertmanager")].volumeMounts[?(@.name=="alertmanager-main-db")]}{"\n"}' | python -m json.tool
{
    "mountPath": "/alertmanager",
    "name": "alertmanager-main-db",
    "subPath": "alertmanager-db"
}

# pod.spec.volumes
[root@k8s-node1 ~]# kubectl get pod alertmanager-main-0 -n monitoring -o jsonpath='{.spec.volumes[?(@.name=="alertmanager-main-db")]}' | python -m json.tool
{
    "name": "alertmanager-main-db",
    "persistentVolumeClaim": {
        "claimName": "alertmanager-main-db-alertmanager-main-0"
    }
}
```

## 3.3 grafana

grafana 就是一个普通的 deployment 应用, 直接修改 yaml 中的 volume 配置即可

```bash
[root@k8s-node1 ~]# mkdir /nfs/kubernetes/grafana-data
[root@k8s-node1 ~]# chmod -R 777 /nfs/kubernetes/grafana-data
```

修改 `manifests/grafana-deployment.yaml` 直接将默认的 emptydir 修改为 nfs 即可

```yaml
      volumes:
      - name: grafana-storage
        nfs:
          server: k8s-node1
          path: /nfs/kubernetes/grafana-data
```

