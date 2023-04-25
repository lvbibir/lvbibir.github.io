---
title: "prometheus (二) 服务发现(serviceMonitor)" 
date: 2023-04-25
lastmod: 2023-04-25
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

> https://prometheus.io/docs/prometheus/latest/configuration/configuration/

prometheus 支持很多种方式的服务发现, 在 k8s 中是通过 `kubernete_sd_config` 配置实现的. 

通过抓取 `k8s REST API` 实现将我们部署的 `exporter(数据采集客户端)` 实例自动注册到 `promtheus` 而无需手动添加 `target` 

# 2. kubernetes_sd_config

> https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config

kubernetes_sd_config 目前支持 node service pod endpoints endpointslice ingress 6 种服务发现模式. `node` 适用于与主机相关的监控资源，如节点中运行的 Kubernetes 组件状态、节点上运行的容器状态等；`service` 和 `ingress` 适用于通过黑盒监控的场景，如对服务的可用性以及服务质量的监控；`endpoints` 和 `pod` 均可用于获取 Pod 实例的监控数据，如监控用户或者管理员部署的支持 Prometheus 的应用。 

在 `kube-prometheus` 中, 所有的 target 都是通过 endpoints 模式进行的服务发现.

每种发现模式都支持很多 label, prometheus 可以通过 `relabel_config` 分析这些标签进行标签重写或者丢弃 target

以比较常用的 endpoints 为例, endpoints 支持的标签如下所示

- `__meta_kubernetes_namespace`: The namespace of the endpoints object.
- `__meta_kubernetes_endpoints_name`: The names of the endpoints object.
- `__meta_kubernetes_endpoints_label_<labelname>`: Each label from the endpoints object.
- `__meta_kubernetes_endpoints_labelpresent_<labelname>`: `true` for each label from the endpoints object.
- 如果 pod+port 刚好是 endpoint 对应的, 则会附加如下标签
  - `__meta_kubernetes_endpoint_hostname`: Hostname of the endpoint.
  - `__meta_kubernetes_endpoint_node_name`: Name of the node hosting the endpoint.
  - `__meta_kubernetes_endpoint_ready`: Set to `true` or `false` for the endpoint's ready state.
  - `__meta_kubernetes_endpoint_port_name`: Name of the endpoint port.
  - `__meta_kubernetes_endpoint_port_protocol`: Protocol of the endpoint port.
  - `__meta_kubernetes_endpoint_address_target_kind`: Kind of the endpoint address target.
  - `__meta_kubernetes_endpoint_address_target_name`: Name of the endpoint address target.

- 如果该 endpoints 是由 service 创建的, 那么所有 service 发现模式的标签也会被附加上
- 如果该 endpoints 的后端是 pod 提供服务, 那么所有 pod 发现模式的标签也会被附加上

endpoints 模式的自动发现会添加 endpoints 后端所有 pod 暴露出来的所有 port. 如下所示

```bash
# 共有 10 个 endpoints, 后端包含 15 个 pod, 所有 ip+port 的组合有 44 个
endpoints ===> pods ===> ip+port
  10            15        44
```

同样, 在 prometheus 后端看到的 targets 将会是 44 个, 然后按照 `relabel` 规则在这些所有的 target 中选择合适的 target 并进行 `active`

![image-20230425093636652](https://image.lvbibir.cn/blog/image-20230425093636652.png)

## 2.1 node-exporter

以上节部署的 kube-prometheus 为例, 演示 prometheus 如何通过 endpoints 模式的服务发现添加我们创建的 node-exporter 为 target

需要注意的是, 与一般部署的 node-exporter 不同, 额外创建了一个 `headless service` 用于 prometheus 的自动发现, 随着 service 创建的 `endpoints` 也会继承 labels 用于后续的操作.

```yaml
# cat manifests/nodeExporter-service.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: node-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 1.3.1
  name: node-exporter
  namespace: monitoring
spec:
  clusterIP: None
  ports:
  - name: https
    port: 9100
    targetPort: https
  selector:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: node-exporter
    app.kubernetes.io/part-of: kube-prometheus
```

k8s 中查看 endpoints

```bash
[root@k8s-node1 ~]# kubectl get ep -n monitoring -l app.kubernetes.io/name=node-exporter
NAME                    ENDPOINTS                                                                 AGE
node-exporter           1.1.1.1:9100,1.1.1.2:9100,1.1.1.3:9100                                    10d
```

prometheus 中配置 kubernetes_sd_config, 自动发现 monitoring 命名空间内的 endpoints 的所有后端 pod

```yaml
- job_name: serviceMonitor/monitoring/node-exporter/0
  kubernetes_sd_configs:
    - role: endpoints
      kubeconfig_file: ""
      follow_redirects: true
      namespaces:
        names:
        - monitoring
```

在 prometheus 的服务发现界面可以看到采集到的所有 target, 每个 target 含有许多标签, `relebal_config` 就是针对这些标签进行筛选和其他操作.

![image-20230424175715511](https://image.lvbibir.cn/blog/image-20230424175715511.png)

service 和 pod 级别的标签

![image-20230424175819756](https://image.lvbibir.cn/blog/image-20230424175819756.png)

如下是 `kube-promenteus` 中自动发现 node-exporter 的完整配置, 包含了标签匹配规则(确保匹配到正确的target), 标签重写规则(可读性更强)

可通过 [http://1.1.1.1:39090/config](http://1.1.1.1:39090/config) 界面查看

```yaml
- job_name: serviceMonitor/monitoring/node-exporter/0
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: https
  authorization:
    type: Bearer
    credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  tls_config:
    insecure_skip_verify: true
  follow_redirects: true
  kubernetes_sd_configs:
  - role: endpoints
    kubeconfig_file: ""
    follow_redirects: true
    namespaces:
      names:
      - monitoring
  relabel_configs:
  - source_labels: [job]
    separator: ;
    regex: (.*)
    target_label: __tmp_prometheus_job_name
    replacement: $1
    action: replace
###### 以下是匹配规则, 如果不满足 label 匹配规则就丢弃 target ######
  - source_labels: [__meta_kubernetes_service_label_app_kubernetes_io_component, __meta_kubernetes_service_labelpresent_app_kubernetes_io_component]
    separator: ;
    regex: (exporter);true
    replacement: $1
    action: keep # 如果不满足, 丢弃此 target
  - source_labels: [__meta_kubernetes_service_label_app_kubernetes_io_name, __meta_kubernetes_service_labelpresent_app_kubernetes_io_name]
    separator: ;
    regex: (node-exporter);true
    replacement: $1
    action: keep
  - source_labels: [__meta_kubernetes_service_label_app_kubernetes_io_part_of, __meta_kubernetes_service_labelpresent_app_kubernetes_io_part_of]
    separator: ;
    regex: (kube-prometheus);true
    replacement: $1
    action: keep
  - source_labels: [__meta_kubernetes_endpoint_port_name]
    separator: ;
    regex: https
    replacement: $1
    action: keep
##### 以下是 replace 替换标签的操作, 可以使我们的 target 标签有更好的可读性 #####
  - source_labels: [__meta_kubernetes_endpoint_address_target_kind, __meta_kubernetes_endpoint_address_target_name]
    separator: ;
    regex: Node;(.*)
    target_label: node
    replacement: ${1}
    action: replace
  - source_labels: [__meta_kubernetes_endpoint_address_target_kind, __meta_kubernetes_endpoint_address_target_name]
    separator: ;
    regex: Pod;(.*)
    target_label: pod
    replacement: ${1}
    action: replace
  - source_labels: [__meta_kubernetes_namespace]
    separator: ;
    regex: (.*)
    target_label: namespace
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_service_name]
    separator: ;
    regex: (.*)
    target_label: service
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_pod_name]
    separator: ;
    regex: (.*)
    target_label: pod
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_pod_container_name]
    separator: ;
    regex: (.*)
    target_label: container
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_service_name]
    separator: ;
    regex: (.*)
    target_label: job
    replacement: ${1}
    action: replace
  - source_labels: [__meta_kubernetes_service_label_app_kubernetes_io_name]
    separator: ;
    regex: (.+)
    target_label: job
    replacement: ${1}
    action: replace
  - separator: ;
    regex: (.*)
    target_label: endpoint
    replacement: https
    action: replace
  - source_labels: [__meta_kubernetes_pod_node_name]
    separator: ;
    regex: (.*)
    target_label: instance
    replacement: $1
    action: replace
  - source_labels: [__address__]
    separator: ;
    regex: (.*)
    modulus: 1
    target_label: __tmp_hash
    replacement: $1
    action: hashmod
  - source_labels: [__tmp_hash]
    separator: ;
    regex: "0"
    replacement: $1
    action: keep
```

查看自动注册到 prometheus 的 node-exporter

![image-20230425085217041](https://image.lvbibir.cn/blog/image-20230425085217041.png)

可以发现:

- 经过 keep 规则成功从 44 个 target 中筛选到了对应的 node-exporter 
- 经过 replace 规则之后 target-labels 有了更好的可读性
