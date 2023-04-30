---
title: "prometheus (三) 服务发现" 
date: 2023-04-26
lastmod: 2023-04-26
tags: 
- kubernetes
- prometheus
keywords:
- kubernetes
- prometheus
description: "prometheus-operator 中的服务发现(serviceMonitor)机制, kubernetes_sd_config 配置, 以及 serviceMonitor 和 podMonitor 自定义资源的使用." 
cover:
    image: "https://image.lvbibir.cn/blog/prometheus.png"
---

# 0. 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `kube-prometheus-0.10` `prometheus-v2.32.1`

# 1. 简介

手动添加 job 配置未免过于繁琐, prometheus 支持很多种方式的服务发现, 在 k8s 中是通过 `kubernetes_sd_config` 配置实现的. 通过抓取 `k8s REST API` 自动发现我们部署在 k8s 集群中的 exporter 实例

在 prometheus-operator 中, 我们无需手动编辑配置文件添加 kubernetes_sd_config 配置, prometheus-operator 抽象了出了两种 CRD 资源:

- `serviceMonitor`: 创建 endpoints 级别的服务发现
- `podMonitor`: 创建 pod 级别的服务发现

通过对这两种 CRD 资源的管理实现 prometheus 动态的服务发现.

## 1.1 kubernetes_sd_config

[kubernets_sd_config 官方文档](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)

kubernetes_sd_config 目前支持 node service pod endpoints endpointslice ingress 6 种服务发现级别.

- `node` 适用于与主机相关的监控资源，如节点中运行的 Kubernetes 组件状态、节点上运行的容器状态等；
- `service` 和 `ingress` 适用于通过黑盒监控的场景，如对服务的可用性以及服务质量的监控；
- `endpoints` 和 `pod` 均可用于获取 Pod 实例的监控数据，如监控用户或者管理员部署的支持 Prometheus 的应用。 

每种发现模式都支持很多 label, prometheus 可以通过 `relabel_config` 分析这些标签进行标签重写或者丢弃 target

在 `kube-prometheus` 的模板配置中, 所有的 exporter 都是通过 endpoints 模式实现的.

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
endpoints ===> pods ===> pod-ip+port
  10            15            44
```

同样, 在 prometheus 后端看到的 targets 将会是 44 个, 然后按照 `relabel` 规则在这些所有的 target 中选择合适的 target 并进行 `active`

![image-20230425093636652](https://image.lvbibir.cn/blog/image-20230425093636652.png)

# 2. serviceMonitor CRD

## 2.1 node-exporter

以上节部署的 kube-prometheus 为例, 学习 prometheus 如何通过 endpoints 模式的服务发现来添加我们创建的 node-exporter 为 target

需要注意的是, 与一般部署的 node-exporter 不同, kube-prometheus 额外创建了一个 `headless service`, 随着 service 创建的 `endpoints` 将用于 prometheus 的自动发现.

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

查看 endpoints

```bash
[root@k8s-node1 ~]# kubectl get ep -n monitoring -l app.kubernetes.io/name=node-exporter
NAME                    ENDPOINTS                                                                 AGE
node-exporter           1.1.1.1:9100,1.1.1.2:9100,1.1.1.3:9100                                    10d
```

查看 serviceMonitor

```yaml
# cat manifests/nodeExporter-serviceMonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: node-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 1.3.1
  name: node-exporter
  namespace: monitoring
spec:
  endpoints:
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 15s
    port: https
    relabelings:
    - action: replace
      regex: (.*)
      replacement: $1
      sourceLabels:
      - __meta_kubernetes_pod_node_name
      targetLabel: instance
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
  jobLabel: app.kubernetes.io/name
  selector:
    matchLabels:              # 标签匹配规则, 符合 label 条件的 target 才会被 active
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: node-exporter
      app.kubernetes.io/part-of: kube-prometheus
```

上述的 serviceMonitor 将会为 prometheus 生成一个 job, 使用了 endpoints 模式的 kubernetes_sd_config, 用于自动发现集群内符合条件的 node-exporter

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
#####  自动发现的配置 #########  
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
###### 以下是匹配规则, 如果不满足 label 匹配规则就丢弃 target, 对应 serviceMonitor 配置的 matchlabels ######
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

在 prometheus 的服务发现界面可以看到采集到的所有 target, 每个 target 就对应了一个 `pod-ip+Port` ,每个 target 含有许多原始标签, `relebal_config` 就是针对这些标签进行筛选和重写等其他操作.

endpoints 级别的标签

![image-20230424175715511](https://image.lvbibir.cn/blog/image-20230424175715511.png)

service 和 pod 级别的标签

![image-20230424175819756](https://image.lvbibir.cn/blog/image-20230424175819756.png)

查看自动注册到 prometheus 的 node-exporter

![image-20230425085217041](https://image.lvbibir.cn/blog/image-20230425085217041.png)

可以发现:

- 经过 keep 规则成功从 44 个 target 中筛选到了对应的 node-exporter 
- 经过 replace 规则之后 target-labels 有了更好的可读性

## 2.2 traefik

接下来演示一下通过创建 `serviceMonitor` 实现采集 traefik 的 metrics 指标, traefik 安装请参考 [traefik系列文章](https://www.lvbibir.cn/tags/traefik/) 

在配置中开启 metric

![image-20230426155759486](https://image.lvbibir.cn/blog/image-20230426155759486.png)

访问测试

```bash
[root@k8s-node1 ~]# kubectl get svc traefik-metrics -n traefik
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
traefik-metrics   ClusterIP   10.103.102.23   <none>        9100/TCP   19s
[root@k8s-node1 ~]#
[root@k8s-node1 ~]# curl -s 10.103.102.23:9100/metrics | head -5
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 4.8217e-05
go_gc_duration_seconds{quantile="0.25"} 7.3819e-05
go_gc_duration_seconds{quantile="0.5"} 0.000203355
```

### 2.2.1 rbac

创建一个用于访问 traefik 命名空间的 role

修改 `manifests/prometheus-roleSpecificNamespaces.yaml`, 新增如下配置

```yaml
- apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    labels:
      app.kubernetes.io/component: prometheus
      app.kubernetes.io/instance: k8s
      app.kubernetes.io/name: prometheus
      app.kubernetes.io/part-of: kube-prometheus
      app.kubernetes.io/version: 2.32.1
    name: prometheus-k8s
    namespace: traefik
  rules:
  - apiGroups:
    - ""
    resources:
    - services
    - endpoints
    - pods
    verbs:
    - get
    - list
    - watch
  - apiGroups:
    - extensions
    resources:
    - ingresses
    verbs:
    - get
    - list
    - watch
  - apiGroups:
    - networking.k8s.io
    resources:
    - ingresses
    verbs:
    - get
    - list
    - watch
```

将上一步创建的 role 与 serviceAccount `prometheus-k8s` 绑定

修改 `manifests/prometheus-roleBindingSpecificNamespaces.yaml`, 新增如下配置

```yaml
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    labels:
      app.kubernetes.io/component: prometheus
      app.kubernetes.io/instance: k8s
      app.kubernetes.io/name: prometheus
      app.kubernetes.io/part-of: kube-prometheus
      app.kubernetes.io/version: 2.32.1
    name: prometheus-k8s
    namespace: traefik
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: prometheus-k8s
  subjects:
  - kind: ServiceAccount
    name: prometheus-k8s
    namespace: monitoring
```

验证

```bash
[root@k8s-node1 kube-prometheus]# kubectl get role,rolebinding -n traefik
NAME                                            CREATED AT
role.rbac.authorization.k8s.io/prometheus-k8s   2023-04-26T06:50:22Z

NAME                                                   ROLE                  AGE
rolebinding.rbac.authorization.k8s.io/prometheus-k8s   Role/prometheus-k8s   75m
```

### 2.2.2 serviceMonitor

创建 serviceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: traefik
  namespace: monitoring
  labels:
    app.kubernetes.io/name: traefik
spec:
  jobLabel: app.kubernetes.io/name
  endpoints:
  - interval: 15s
    port: metrics         # endpoint(service) 中定义的 portName
    path: /metrics        # metrics 访问路径
  namespaceSelector:      # endpoint 的 namespace
    matchNames:
    - traefik
  selector:
    matchLabels:
      app: traefik-metrics # endpoint 的 label 筛选
```

部署

```bash
[root@k8s-node1 kube-prometheus]# kubectl apply -f  manifests/traefik-serviceMonitor.yml
[root@k8s-node1 kube-prometheus]# kubectl get serviceMonitor -n monitoring -l app.kubernetes.io/name=traefik
NAME      AGE
traefik   4m7s
```

### 2.2.3 验证

prometheus 的 configuration 界面自动生成的配置如下

```yaml
- job_name: serviceMonitor/monitoring/traefik/0
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  follow_redirects: true
  relabel_configs:
  - source_labels: [job]
    separator: ;
    regex: (.*)
    target_label: __tmp_prometheus_job_name
    replacement: $1
    action: replace
  - source_labels: [__meta_kubernetes_service_label_app, __meta_kubernetes_service_labelpresent_app]
    separator: ;
    regex: (traefik-metrics);true
    replacement: $1
    action: keep
  - source_labels: [__meta_kubernetes_endpoint_port_name]
    separator: ;
    regex: metrics
    replacement: $1
    action: keep
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
    replacement: metrics
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
  kubernetes_sd_configs:
  - role: endpoints
    kubeconfig_file: ""
    follow_redirects: true
    namespaces:
      names:
      - traefik
```

Service Discovery 界面

![image-20230426161824709](https://image.lvbibir.cn/blog/image-20230426161824709.png)

Targets 界面

![image-20230426161849710](https://image.lvbibir.cn/blog/image-20230426161849710.png)

# 3. podMonitor CRD

## 3.1 calico-node

以 calico 为例, 使用 podMonitor 资源监控 calico-node 

calico 中核心的组件是 Felix，它负责设置路由表和 ACL 规则，同时还负责提供网络健康状况的数据；这些数据会被写入etcd。
由此可见，监控 calico 的核心便是监控 felix，felix 相当于 calico 的大脑。

如下所示, 一般 calico-node 都是使用 daemonset 方式部署在集群中的

```bash
[root@k8s-node1 ~]# kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
NAME                READY   STATUS    RESTARTS        AGE     IP        NODE        NOMINATED NODE   READINESS GATES
calico-node-8p9w5   1/1     Running   2 (5d16h ago)   7d23h   1.1.1.2   k8s-node2   <none>           <none>
calico-node-bw2kb   1/1     Running   2 (5d16h ago)   7d23h   1.1.1.1   k8s-node1   <none>           <none>
calico-node-gt688   1/1     Running   2 (5d16h ago)   7d23h   1.1.1.3   k8s-node3   <none>           <none>
```

calico-node 默认是没有打开 metrics 监听的, 我们修改 calico 的 daemonset 配置文件, 可以直接修改部署时的 yaml, 也可以 `kubectl edit ds calico-node -n kube-system`

```yaml
kind: DaemonSet
spec:
  template:
    spec:
      containers:
        - name: calico-node
          env:
          #  添加如下配置, 开启 FELIX 的 metrics 的监听端口为 9101 (9100 端口被 node-exporter 占据了)
            - name: FELIX_PROMETHEUSMETRICSENABLED
              value: "True"
            - name: FELIX_PROMETHEUSMETRICSPORT
              value: "9101"
          ports:
          - containerPort: 9101
            name: metrics
            protocol: TCP
```

修改完等待 calico-node 的 pod 重新部署, 然后访问测试

```bash
[root@k8s-node1 ~]# curl -s k8s-node2:9101/metrics | head -6
# HELP felix_active_local_endpoints Number of active endpoints on this host.
# TYPE felix_active_local_endpoints gauge
felix_active_local_endpoints 9
# HELP felix_active_local_policies Number of active policies on this host.
# TYPE felix_active_local_policies gauge
felix_active_local_policies 0
```

由于 kube-prometheus 默认已经帮我们创建了基于 `kube-sysetm` 命名空间的授权, 我们无需再额外配置

创建 podMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  labels:
    app.kubernetes.io/name: calico-node
  name: calico-node
  namespace: monitoring
spec:
  jobLabel: app.kubernetes.io/name
  podMetricsEndpoints:
  - interval: 15s
    path: /metrics
    port: metrics           # 确保与 calico-node 的 containerPort 名称一致
  namespaceSelector:
    matchNames:
    - kube-system           # 确保命名空间正确
  selector:
    matchLabels: 
      k8s-app: calico-node  # 确保 label 配置正确
```

查看 prometheus

![image-20230427100740612](https://image.lvbibir.cn/blog/image-20230427100740612.png)



# 4. 集群范围的自动发现

当我们的 k8s 集群中 service 和 pod 达到一定规模后手动一个一个创建 serviceMonitor 和 podMonitor 不免又麻烦了起来, 我们可以使用不限制 namespace 的 kubernetes_sd_configs 实现集群范围内自动发现所有的 exporter 实例

接下来的演示中我们监控集群范围内的所有 endpoints, 并且将带有 `prometheus.io/scrape=true` 这个 `annotations ` 的 service 注册到 prometheus

## 4.1 rbac

由于需要访问访问集群范围内的资源对象, 继续使用 role+roleBinding 模式显然不适合, prometheus-k8s 这个 serviceAccount 还绑定一个名为 prometheus-k8s 的 clusterRole, 该 clusterRole 默认权限是不够的, 添加需要的权限:

```yaml
# vim manifests/prometheus-clusterRole.yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app.kubernetes.io/component: prometheus
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 2.32.1
  name: prometheus-k8s
  namespace: monitoring
rules:
- apiGroups:
  - ""
  resources:
  - nodes
  - services
  - endpoints
  - pods
  - nodes/metrics
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - configmaps
  - nodes/metrics
  verbs:
  - get
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  
# kubectl apply -f manifests/prometheus-clusterRole.yaml
```

## 4.2 自动发现配置

通过上一篇文章中的 `additionalScrapeConfigs` 添加自动发现配置

```yaml
# vim prometheus-additional.yaml

- job_name: 'kubernetes-service-endpoints'
  kubernetes_sd_configs:
  - role: endpoints
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
    action: keep
    regex: true
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
    action: replace
    target_label: __scheme__
    regex: (https?)
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
    action: replace
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
    action: replace
    target_label: __address__
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: $1:$2
  - action: labelmap
    regex: __meta_kubernetes_service_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    action: replace
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_service_name]
    action: replace
    target_label: kubernetes_name
```

修改 secret

```bash
kubectl create secret generic additional-scrape-configs -n monitoring --from-file=prometheus-additional.yaml  > additional-scrape-configs.yaml
kubectl apply -f additional-scrape-configs.yaml 
```

确保 prometheus CRD 中添加了 `additionalScrapeConfigs` 配置

```yaml
kind: Prometheus
spec:
  additionalScrapeConfigs:
    name: additional-scrape-configs  # secret name
    key: prometheus-additional.yaml  # secret key
```

## 4.3 验证

service kube-dns 默认有 `prometheus.io/scrape=true` 这个注解, 已经成功注册:

![image-20230427164311865](https://image.lvbibir.cn/blog/image-20230427164311865.png)

创建一个示例应用

```yaml
# vim node-exporter-deploy-svc.yml

apiVersion: v1
kind: Namespace
metadata:
  name: test
---
apiVersion: v1
kind: Service
metadata:
  name: test-node-exporter
  namespace: test
  labels:
    app: test-node-exporter
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9200"
spec:
  selector:
    app: test-node-exporter
  ports:
  - name: metrics
    port: 9200
    targetPort: metrics
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-node-exporter
  namespace: test
  labels:
    app: test-node-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-node-exporter
  template:
    metadata:
      labels:
        app: test-node-exporter
    spec:
      containers:
      - args:
        - --web.listen-address=:9200
        image: registry.cn-hangzhou.aliyuncs.com/lvbibir/node-exporter:v1.3.1
        name: node-exporter
        ports:
        - name: metrics
          containerPort: 9200

# kubectl apply -f node-exporter-deploy-svc.yml
```

如下, 我们部署的 node-exporter 已经成功注册, 只要 service 设置了 `annotations` 即可

![image-20230427171357838](https://image.lvbibir.cn/blog/image-20230427171357838.png)























