---
title: "loki (二) 部署" 
date: 2023-05-01
lastmod: 2024-01-28
tags:
  - kubernetes
keywords:
  - kubernetes
  - prometheus
description: "Loki 的部署, 对接 Grafana, traefik 采集监控示例" 
cover:
    image: "images/cover-loki.png"
---

# 0 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `loki-2.3.0` `promtail-2.3.0`

这次部署的 loki 整体架构如下, loki 使用 statefulset 的方式运行, promtail 以 daemonset 的方式运行在 k8s 集群的每个节点.

![img](/images/image-20260106-211318.jpeg)

# 1 promtail

## 1.1 部署

namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: logging
```

rbac

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loki-promtail
  labels:
    app: promtail
  namespace: logging

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    app: promtail
  name: promtail-clusterrole
  namespace: logging
rules:
- apiGroups: [""] 
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "watch", "list"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: promtail-clusterrolebinding
  labels:
    app: promtail
  namespace: logging
subjects:
  - kind: ServiceAccount
    name: loki-promtail
    namespace: logging
roleRef:
  kind: ClusterRole
  name: promtail-clusterrole
  apiGroup: rbac.authorization.k8s.io
```

configmap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-promtail
  namespace: logging
  labels:
    app: promtail
data:
  promtail.yaml: |
    client:                # 配置Promtail如何连接到Loki的实例
      backoff_config:      # 配置当请求失败时如何重试请求给Loki
        max_period: 5m
        max_retries: 10
        min_period: 500ms
      batchsize: 1048576      # 发送给Loki的最大批次大小(以字节为单位)
      batchwait: 1s           # 发送批处理前等待的最大时间（即使批次大小未达到最大值）
      external_labels: {}     # 所有发送给Loki的日志添加静态标签
      timeout: 10s            # 等待服务器响应请求的最大时间
    positions:
      filename: /run/promtail/positions.yaml
    server:
      http_listen_port: 3101
    target_config:
      sync_period: 10s
    scrape_configs:
    - job_name: kubernetes-pods-name
      pipeline_stages:
        - docker: {}
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_label_name
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ''
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
    - job_name: kubernetes-pods-app
      pipeline_stages:
        - docker: {}
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: drop
        regex: .+
        source_labels:
        - __meta_kubernetes_pod_label_name
      - source_labels:
        - __meta_kubernetes_pod_label_app
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ''
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
    - job_name: kubernetes-pods-direct-controllers
      pipeline_stages:
        - docker: {}
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: drop
        regex: .+
        separator: ''
        source_labels:
        - __meta_kubernetes_pod_label_name
        - __meta_kubernetes_pod_label_app
      - action: drop
        regex: '[0-9a-z-.]+-[0-9a-f]{8,10}'
        source_labels:
        - __meta_kubernetes_pod_controller_name
      - source_labels:
        - __meta_kubernetes_pod_controller_name
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ''
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
    - job_name: kubernetes-pods-indirect-controller
      pipeline_stages:
        - docker: {}
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: drop
        regex: .+
        separator: ''
        source_labels:
        - __meta_kubernetes_pod_label_name
        - __meta_kubernetes_pod_label_app
      - action: keep
        regex: '[0-9a-z-.]+-[0-9a-f]{8,10}'
        source_labels:
        - __meta_kubernetes_pod_controller_name
      - action: replace
        regex: '([0-9a-z-.]+)-[0-9a-f]{8,10}'
        source_labels:
        - __meta_kubernetes_pod_controller_name
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ''
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
    - job_name: kubernetes-pods-static
      pipeline_stages:
        - docker: {}
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: drop
        regex: ''
        source_labels:
        - __meta_kubernetes_pod_annotation_kubernetes_io_config_mirror
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_label_component
        target_label: __service__
      - source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: __host__
      - action: drop
        regex: ''
        source_labels:
        - __service__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - __meta_kubernetes_namespace
        - __service__
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_annotation_kubernetes_io_config_mirror
        - __meta_kubernetes_pod_container_name
        target_label: __path__
```

daemonset

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: loki-promtail
  namespace: logging
  labels:
    app: promtail
spec:
  selector:
    matchLabels:
      app: promtail
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: promtail
    spec:
      serviceAccountName: loki-promtail
      containers:
        - name: promtail
          image: grafana/promtail:2.3.0
          imagePullPolicy: IfNotPresent
          args:
          - -config.file=/etc/promtail/promtail.yaml
          - -client.url=http://loki:3100/loki/api/v1/push
          env:
          - name: HOSTNAME
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: spec.nodeName
          volumeMounts:
          - mountPath: /etc/promtail
            name: config
          - mountPath: /run/promtail
            name: run
          - mountPath: /var/lib/docker/containers
            name: docker
            readOnly: true
          - mountPath: /var/log/pods
            name: pods
            readOnly: true
          ports:
          - containerPort: 3101
            name: http
            protocol: TCP
          securityContext:
            readOnlyRootFilesystem: true
            runAsGroup: 0
            runAsUser: 0
          readinessProbe:
            failureThreshold: 5
            httpGet:
              path: /ready
              port: http-metrics
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
      tolerations:
      - operator: Exists
      volumes:
        - name: config
          configMap:
            defaultMode: 420
            name: loki-promtail
        - name: run
          hostPath:
            path: /run/promtail
            type: ""
        - name: docker
          hostPath:
            path: /var/lib/docker/containers
        - name: pods
          hostPath:
            path: /var/log/pods
```

## 1.2 配置详解

主要解释一下 promtail 中的匹配规则, 因为采集的日志可以说非常地杂乱, 如何将应用日志分类就尤为重要, 可以说匹配规则是 `promtail` 的核心所在

通常我们分类 pod 的手段基本为 namespace + labels + controller , 在 loki 中也一样, 在上述 configmap 的配置中将 k8s 中的所有 pod 分为了五类:

- 定义了 label_name
- 未定义 label_name, 定义了 label_app
- 未定义 label_name & label_app, 由 Daemonset 控制
- 未定义 label_name & label_app, 由非 Daemonset 控制
- 未定义 label_name & label_app, 由 kubelet 直接控制

对应上述 configmap 中配置的五个 job:

- kubernetes-pods-name `job=namespace/label_name`
- kubernetes-pods-app `job=namespace/label_app`
- kubernetes-pods-direct-controllers `job=namespace/controller`
- kubernetes-pods-indirect-controllers `job=namespace/controller`
- kubernetes-pods-static `job=namespace/label_component`

每个指标数据将由上述规则分类, 添加一个 `job` 的 label

然后基于指标数据对应 pod 的所有 label 附加到指标数据上

```yaml
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
```

再加上指标数据本身携带的一些 label, 我们就可以对 pod 日志做一个十分细致的区分

# 2 loki

rbac

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loki
  namespace: logging

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: loki
  namespace: logging
rules:
- apiGroups:
  - extensions
  resourceNames:
  - loki
  resources:
  - podsecuritypolicies
  verbs:
  - use

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: loki
  namespace: logging
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: loki
subjects:
- kind: ServiceAccount
  name: loki
```

configmap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki
  namespace: logging
  labels:
    app: loki
data:
  loki.yaml: |
    auth_enabled: false
    ingester:
      chunk_idle_period: 3m        # 如果块没有达到最大的块大小，那么在刷新之前，块应该在内存中不更新多长时间
      chunk_block_size: 262144
      chunk_retain_period: 1m      # 块刷新后应该在内存中保留多长时间
      max_transfer_retries: 0      # Number of times to try and transfer chunks when leaving before falling back to flushing to the store. Zero = no transfers are done.
      lifecycler:                  # 配置ingester的生命周期，以及在哪里注册以进行发现
        ring:
          kvstore:
            store: inmemory        # 用于ring的后端存储，支持consul、etcd、inmemory
          replication_factor: 1    # 写入和读取的ingesters数量，至少为1（为了冗余和弹性，默认情况下为3)
    limits_config:
      enforce_metric_name: false
      reject_old_samples: true      # 旧样品是否会被拒绝
      reject_old_samples_max_age: 168h      # 拒绝旧样本的最大时限
    schema_config:                    # 配置从特定时间段开始应该使用哪些索引模式
      configs:
      - from: 2020-10-24           # 创建索引的日期。如果这是唯一的schema_config，则使用过去的日期，否则使用希望切换模式时的日期
        store: boltdb-shipper      # 索引使用哪个存储，如：cassandra, bigtable, dynamodb，或boltdb
        object_store: filesystem   # 用于块的存储，如：gcs, s3， inmemory, filesystem, cassandra，如果省略，默认值与store相同
        schema: v11
        index:                # 配置如何更新和存储索引
          prefix: index_      # 所有周期表的前缀
          period: 24h         # 表周期
    server:
      http_listen_port: 3100
    storage_config:            # 为索引和块配置一个或多个存储
      boltdb_shipper:
        active_index_directory: /data/loki/boltdb-shipper-active
        cache_location: /data/loki/boltdb-shipper-cache
        cache_ttl: 24h
        shared_store: filesystem
      filesystem:
        directory: /data/loki/chunks
    chunk_store_config:             # 配置如何缓存块，以及在将它们保存到存储之前等待多长时间
      max_look_back_period: 0s      # 限制查询数据的时间，默认是禁用的，这个值应该小于或等于table_manager.retention_period中的值
    table_manager:
      retention_deletes_enabled: true   # 日志保留周期开关，用于表保留删除
      retention_period: 48h             # 日志保留周期，保留期必须是索引/块的倍数
    compactor:
      working_directory: /data/loki/boltdb-shipper-compactor
      shared_store: filesystem
    ruler:
      storage:
        type: local
        local:
          directory: /etc/loki/rules/rules1.yaml
      rule_path: /tmp/loki/rules-temp
      alertmanager_url: http://alertmanager-main.monitoring.svc:9093
      ring:
        kvstore:
          store: inmemory
      enable_api: true
      enable_alertmanager_v2: true
```

statefulset service, 注意修改 storageClass 为自己的

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: loki
  namespace: logging
  labels:
    app: loki
spec:
  type: ClusterIP
  ports:
    - port: 3100
      protocol: TCP
      name: http
      targetPort: http
  selector:
    app: loki
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: loki
  namespace: logging
  labels:
    app: loki
spec:
  podManagementPolicy: OrderedReady
  replicas: 1
  selector:
    matchLabels:
      app: loki
  serviceName: loki
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: loki
    spec:
      serviceAccountName: loki
      securityContext:
          fsGroup: 10001
          runAsGroup: 10001
          runAsNonRoot: true
          runAsUser: 10001
      initContainers: []
      containers:
        - name: loki
          image: grafana/loki:2.3.0
          imagePullPolicy: IfNotPresent
          args:
            - -config.file=/etc/loki/loki.yaml
          volumeMounts:
            - name: config
              mountPath: /etc/loki
            - name: storage
              mountPath: /data
          ports:
            - name: http-metrics
              containerPort: 3100
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /ready
              port: http-metrics
              scheme: HTTP
            initialDelaySeconds: 45
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ready
              port: http-metrics
              scheme: HTTP
            initialDelaySeconds: 45
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          securityContext:
            readOnlyRootFilesystem: true
      terminationGracePeriodSeconds: 4800
      volumes:
        - name: config
          configMap:
            defaultMode: 420
            name: loki
  volumeClaimTemplates:
  - metadata:
      name: storage
      labels:
        app: loki
      annotations:
        volume.beta.kubernetes.io/storage-class: "nfs" # 注意修改 storageClass 名称
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: "2Gi"
```

应用所有配置文件, 上述配置是 loki 针对 k8s 的一套比较标准的配置, 所以目前的配置仅能抓取 k8s 中所有 pod 发送到 `stdout` 和 `stderr` 的信息, 如果需要抓取日志文件还需另外配置.

```bash
[root@k8s-node1 ~]# kubectl apply -f /opt/loki/
[root@k8s-node1 ~]# kubectl get pods -n logging
NAME                  READY   STATUS    RESTARTS   AGE
loki-0                1/1     Running   0          3m29s
loki-promtail-4kskw   1/1     Running   0          3m36s
loki-promtail-p7qzr   1/1     Running   0          3m36s
loki-promtail-wc5f7   1/1     Running   0          3m37s
[root@k8s-node1 ~]# kubectl get svc -n logging
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
loki         ClusterIP   10.105.115.178   <none>        3100/TCP         4m26s
```

# 3 Grafana

grafana 部署请参考博主的 [prometheus 系列文章](https://www.lvbibir.cn/tags/prometheus/)

## 3.1 配置

在 grafana 中添加 loki 作为 data source, 这里我的 grafana 是直接部署在 k8s 中的, 所以可以通过 `<svc-name>.<namespace>` 访问到 loki

![image-20230422144554668](/images/image-20230422-144554.png)

在 Explore => loki => `{job="kube-system/kube-apiserver"}` 可以看到 k8s 的 api-server 相关日志

![image-20230423164457090](/images/image-20230423-164457.png)

## 3.1 光标跳动问题

在 grafana 中手动写 logQL 查询数据时总会出现光标要么一直往行首跳, 要么一直往行尾跳, [Github](https://github.com/grafana/grafana/issues/54942) 也有很多人遇到了同样的问题, 社区仍未解决该问题, 目前可以通过 F12 控制台输入一条指令单次地修复这个问题, 指令如下

```javascript
document.querySelectorAll(".slate-query-field > div")[0]['style'].removeProperty('-webkit-user-modify');
```

![image-20230501182103342](/images/image-20230501-182103.png)

# 4 dashboard 示例

## 4.1 traefik

traefik 部署参考博主的 [traefik 系列文章](https://www.lvbibir.cn/tags/traefik)

如下图所示, 已经可以看到收集到的 traefik 日志

![image-20230422145419822](/images/image-20230422-145419.png)

我们还可以通过 dashboard 实时展示 traefik 的信息, 在 grafana 导入 [13713 号模板](https://grafana.com/grafana/dashboards/13713)

此 dashboard 默认的 traefik 的采集语句是 `{job="/var/log/traefik.log"}` , 我们需要按照实际情况进行修改, 这里我改成了 `{app="traefik/traefik"}`

![image-20230422150345420](/images/image-20230422-150345.png)

导入修改好的 yaml, 选择数据源

![image-20230422145730804](/images/image-20230422-145730.png)

可以看到已经可以正常展示数据了

![image-20230422150456882](/images/image-20230422-150456.png)

但是还有一个小报错, 是因为这个 dashboard 依赖 `grafana-piechart-panel` 这个插件, 我们在 grafana 容器内执行安装插件

```bash
[root@k8s-node1 manifests]# kubectl exec -it grafana-78bb4557f5-7rbbq -n monitoring -- grafana-cli plugins install grafana-piechart-panel
✔ Downloaded grafana-piechart-panel v1.6.4 zip successfully

Please restart Grafana after installing plugins. Refer to Grafana documentation for instructions if necessary.

[root@k8s-node1 manifests]# kubectl delete pod grafana-78bb4557f5-7rbbq -n monitoring
pod "grafana-78bb4557f5-7rbbq" deleted
```

等待重建 pod, 可以看到这里已经可以正常显示了

![image-20230422153000965](/images/image-20230422-153000.png)

以上
