---
title: "prometheus (六) Alertmanager" 
date: 2023-04-29
lastmod: 2023-04-29
tags: 
- kubernetes
- prometheus
keywords:
- kubernetes
- prometheus
- alertmanager
description: "prometheus 架构中的 Alertmanager 介绍, 以及使用 alertmanagerconfig CRD 资源配置 Alertmanager" 
cover:
    image: "https://image.lvbibir.cn/blog/prometheus.png"
---

# 0. 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `kube-prometheus-0.10` `prometheus-v2.32.1`

# 1. alertmanager

prometheus 架构中采集数据和发送告警是独立出来的, 告警触发后将信息转发到独立的组件 `alertmanager`, 由 alertmanager 对报警进行统一处理, 最后通过接收器 `recevier` 发送给指定用户

## 1.1 工作机制

Alertmanager 收到告警信息后:

- 进行分组 `group`
- 通过定义好的路由 `routing` 转发到正确的接收器 `recevier`
- `recevier` 通过 `email` `dingtalk` `wechat` 等方式通知给定义好的接收人

![img](https://image.lvbibir.cn/blog/1302413-20220630105727154-187545105.png)



## 1.2 四大功能

分组(Grouping): 将同类型的告警进行分组, 合并多条告警到一个通知中

抑制(Inhibition): 当某条告警已经发送, 停止重复发送由此告警引起的其他异常或者故障

静默(Silences): 根据标签快速对告警进行静默处理, 如果告警符合静默的配置, Alertmanager则不会发送告警通知

路由(route): 用于配置 Alertmanager 如何处理传入的特定类型的告警通知

## 1.3 配置详解

```yaml
global:
  # 经过此时间后，如果尚未更新告警，则将告警声明为已恢复。(即 prometheus 没有向 alertmanager 发送告警了)
  resolve_timeout: 5m
  # 配置发送邮件信息
  smtp_smarthost: 'smtp.qq.com:465'
  smtp_from: '742899387@qq.com'
  smtp_auth_username: '742899387@qq.com'
  smtp_auth_password: 'password'
  smtp_require_tls: false
 
# 读取告警通知模板的目录。
templates: 
- '/etc/alertmanager/template/*.tmpl'
 
# 所有报警都会进入到这个根路由下，可以根据根路由下的子路由设置报警分发策略
route:
  # 先解释一下分组，分组就是将多条告警信息聚合成一条发送，这样就不会收到连续的报警了。
  # 将传入的告警按标签分组(标签在 prometheus 中的 rules 中定义)，例如：
  # 接收到的告警信息里面有许多具有 cluster=A 和 alertname=LatencyHigh 的标签，这些个告警将被分为一个组。
  #
  # 如果不想使用分组，可以这样写group_by: [...]
  group_by: ['alertname', 'cluster', 'service']
 
  # 第一组告警发送通知需要等待的时间，这种方式可以确保有足够的时间为同一分组获取多个告警，然后一起触发这个告警信息。
  group_wait: 30s
 
  # 发送第一个告警后，等待"group_interval"发送一组新告警。
  group_interval: 5m
 
  # 分组内发送相同告警的时间间隔。这里的配置是每3小时发送告警到分组中。举个例子：收到告警后，一个分组被创建，等待5分钟发送组内告警，如果后续组内的告警信息相同,这些告警会在3小时后发送，但是3小时内这些告警不会被发送。
  repeat_interval: 3h 
 
  # 这里先说一下，告警发送是需要指定接收器的，接收器在receivers中配置，接收器可以是email、webhook、pagerduty、wechat等等。一个接收器可以有多种发送方式。
  # 指定默认的接收器
  receiver: team-X-mails
 
  
  # 下面配置的是子路由，子路由的属性继承于根路由(即上面的配置)，在子路由中可以覆盖根路由的配置
 
  # 下面是子路由的配置
  routes:
  # 使用正则的方式匹配告警标签
  - match_re:
      # 这里可以匹配出标签含有 service=foo1 或 service=foo2 或 service=baz 的告警
      service: ^(foo1|foo2|baz)$
    # 指定接收器为 team-X-mails
    receiver: team-X-mails
    # 这里配置的是子路由的子路由，当满足父路由的的匹配时，这条子路由会进一步匹配出 severity=critical 的告警，并使用 team-X-pager 接收器发送告警，没有匹配到的告警会由父路由进行处理。
    routes:
    - match:
        severity: critical
      receiver: team-X-pager
 
  # 这里也是一条子路由，会匹配出标签含有 service=files 的告警，并使用 team-Y-mails 接收器发送告警
  - match:
      service: files
    receiver: team-Y-mails
    # 这里配置的是子路由的子路由，当满足父路由的的匹配时，这条子路由会进一步匹配出 severity=critical 的告警，并使用 team-Y-pager 接收器发送告警，没有匹配到的会由父路由进行处理。
    routes:
    - match:
        severity: critical
      receiver: team-Y-pager
 
  # 该路由处理来自数据库服务的所有警报。如果没有团队来处理，则默认为数据库团队。
  - match:
      # 首先匹配标签service=database
      service: database
    # 指定接收器
    receiver: team-DB-pager
    # 根据受影响的数据库对告警进行分组
    group_by: [alertname, cluster, database]
    routes:
    - match:
        owner: team-X
      receiver: team-X-pager
      # 告警是否继续匹配后续的同级路由节点，默认false，下面如果也可以匹配成功，会向两种接收器都发送告警信息(猜测。。。)
      continue: true
    - match:
        owner: team-Y
      receiver: team-Y-pager
 
 
# 下面是关于inhibit(抑制)的配置，先说一下抑制是什么：抑制规则允许在另一个警报正在触发的情况下使一组告警静音。其实可以理解为告警依赖。比如一台数据库服务器掉电了，会导致db监控告警、网络告警等等，可以配置抑制规则如果服务器本身down了，那么其他的报警就不会被发送出来。
 
inhibit_rules:
#下面配置的含义：当有多条告警在告警组里时，并且他们的标签alertname,cluster,service都相等，如果severity: 'critical'的告警产生了，那么就会抑制severity: 'warning'的告警。
- source_match:  # 源告警(我理解是根据这个报警来抑制target_match中匹配的告警)
    severity: 'critical' # 标签匹配满足severity=critical的告警作为源告警
  target_match:  # 目标告警(被抑制的告警)
    severity: 'warning'  # 告警必须满足标签匹配severity=warning才会被抑制。
  equal: ['alertname', 'cluster', 'service']  # 必须在源告警和目标告警中具有相等值的标签才能使抑制生效。(即源告警和目标告警中这三个标签的值相等'alertname', 'cluster', 'service')
 
 
# 下面配置的是接收器
receivers:
# 接收器的名称、通过邮件的方式发送、
- name: 'team-X-mails'
  email_configs:
    # 发送给哪些人
  - to: 'team-X+alerts@example.org'
    # 是否通知已解决的警报
    send_resolved: true
 
# 接收器的名称、通过邮件和pagerduty的方式发送、发送给哪些人，指定pagerduty的service_key
- name: 'team-X-pager'
  email_configs:
  - to: 'team-X+alerts-critical@example.org'
  pagerduty_configs:
  - service_key: <team-X-key>
 
# 接收器的名称、通过邮件的方式发送、发送给哪些人
- name: 'team-Y-mails'
  email_configs:
  - to: 'team-Y+alerts@example.org'
 
# 接收器的名称、通过pagerduty的方式发送、指定pagerduty的service_key
- name: 'team-Y-pager'
  pagerduty_configs:
  - service_key: <team-Y-key>
 
# 一个接收器配置多种发送方式
- name: 'ops'
  webhook_configs:
  - url: 'http://prometheus-webhook-dingtalk.kube-ops.svc.cluster.local:8060/dingtalk/webhook1/send'
    send_resolved: true
  email_configs:
  - to: '742899387@qq.com'
    send_resolved: true
  - to: 'soulchild@soulchild.cn'
    send_resolved: true
```

## 1.4 Alertmanager CRD

Prometheus Operator 为 alertmanager 抽象了两个 CRD资源:

- `alertmanager` CRD: 基于 statefulset, 实现 alertmanager 的部署以及扩容缩容
- `alertmanagerconfig` CRD: 实现模块化修改 alertmanager 的配置 

通过 alertManager CRD 部署的实例配置文件由 `secret/alertmanager-main-generated` 提供

```bash
# kubectl get pod alertmanager-main-0 -n monitoring -o jsonpath='{.spec.volumes[?(@.name=="config-volume")]}' | python -m json.tool
{
    "name": "config-volume",
    "secret": {
        "defaultMode": 420,
        "secretName": "alertmanager-main-generated"
    }
}

# kubectl get secret alertmanager-main-generated -n monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 --decode
"global":
  "resolve_timeout": "5m"
"inhibit_rules":
- "equal":
  - "namespace"
  - "alertname"
  "source_matchers":
......
```

secret `alertmanager-main-generated` 是自动生成的, 基于 secret `alertmanager-main` 和 CRD `alertmanagerConfig` 

```bash
[root@k8s-node1 manifests]# kubectl explain alertmanager.spec.configSecret
DESCRIPTION:
     ConfigSecret is the name of a Kubernetes Secret in the same namespace as
     the Alertmanager object, which contains configuration for this Alertmanager
     instance. Defaults to 'alertmanager-<alertmanager-name>' The secret is
     mounted into /etc/alertmanager/config.
```

综上, 修改 alertmanager 配置可以修改 secret `alertmanager-main` 或者 CRD `alertmanagerconfig`

# 2. 示例

## 2.1 secret

新建 `alertmanager.yaml` 配置文件

```yaml
global:
  resolve_timeout: 5m
  smtp_from: '15810243114@163.com'
  smtp_smarthost: 'smtp.163.com:25'
  smtp_auth_username: '15810243114@163.com'
  smtp_auth_password: '******'
  smtp_require_tls: false
  smtp_hello: '163.com'
route:
  receiver: Default
  group_by:
  - namespace
  continue: false
  routes:
  - receiver: Critical
    matchers:
    - severity="critical"
    continue: false
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
inhibit_rules:
- source_matchers:
  - severity="critical"
  target_matchers:
  - severity=~"warning|info"
  equal:
  - namespace
  - alertname
- source_matchers:
  - severity="warning"
  target_matchers:
  - severity="info"
  equal:
  - namespace
  - alertname
receivers:
- name: Default
  email_configs:
  - to: 'lvbibir@foxmail.com'
    send_resolved: true
- name: Critical
  email_configs:
  - to: 'lvbibir@foxmail.com'
    send_resolved: true
```

修改 secret alertmanager-main

```bash
kubectl create secret generic additional-scrape-configs -n monitoring --from-file=prometheus-additional.yaml  > additional-scrape-configs.yaml
kubectl apply -f additional-scrape-configs.yaml 
```

查看生成的 secret alertmanager-main-generated

```bash
kubectl get secret alertmanager-main-generated -n monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 --decode
```

之后 prometheus-operator 会自动更新 alertmanager 的配置

```bash
# kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus-operator | tail -1
level=info ts=2023-04-30T11:43:01.104579363Z caller=operator.go:741 component=alertmanageroperator key=monitoring/main msg="sync alertmanager"
```

## 2.2 alertmanagerconfig

默认情况下配置 alertmanager 是无法获取到的, 我们需要先修改一下 alertmanager 实例, 添加标签选择器

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
spec:
  alertmanagerConfigSelector:
    matchLabels:
      alertmanager: main
```

创建 alertmanager CRD 资源

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: dinghook
  namespace: monitoring
  labels:
    alertmanager: main
spec:
  receivers:
  - name: web
    webhookConfigs:
    - url: http://dingtalk-hook-web
      sendResolved: true
  - name: db
    webhookConfigs:
    - url: http://dingtalk-hook-db
      sendResolved: true
  route:
    groupBy: ["app"]
    groupWait: 30s
    groupInterval: 5m
    repeatInterval: 12h
    continue: false
    receiver: web
    routes:
    - matchers:
      - name: app
        value: nginx
      receiver: web
    - matchers:
      - name: app
        value: mysql
      receiver: db
```

同样的, prometheus-operator 会更新 alertmanager 配置

```bash
# kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus-operator | tail -1
level=info ts=2023-04-30T11:55:00.309492873Z caller=operator.go:741 component=alertmanageroperator key=monitoring/main msg="sync alertmanager"
```

查看最后生成的配置

```yaml
# kubectl get secret alertmanager-main-generated -n monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 --decode
global:
  resolve_timeout: 5m
  smtp_from: 15810243114@163.com
  smtp_hello: 163.com
  smtp_smarthost: smtp.163.com:25
  smtp_auth_username: 15810243114@163.com
  smtp_auth_password: *********
  smtp_require_tls: false
route:
  receiver: Default
  group_by:
  - namespace
  routes:
  - receiver: monitoring-dinghook-web
    group_by:
    - app
    matchers:
    - namespace="monitoring" # 指定匹配了 namespace 
    continue: true           # continue 也没有按照预设配置
    routes:
    - receiver: monitoring-dinghook-web
      match:
        app: nginx
    - receiver: monitoring-dinghook-db
      match:
        app: mysql
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 12h
  - receiver: Critical
    matchers:
    - severity="critical"
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
inhibit_rules:
- target_matchers:
  - severity=~"warning|info"
  source_matchers:
  - severity="critical"
  equal:
  - namespace
  - alertname
- target_matchers:
  - severity="info"
  source_matchers:
  - severity="warning"
  equal:
  - namespace
  - alertname
receivers:
- name: Default
  email_configs:
  - send_resolved: true
    to: lvbibir@foxmail.com
- name: Critical
  email_configs:
  - send_resolved: true
    to: lvbibir@foxmail.com
- name: monitoring-dinghook-web
  webhook_configs:
  - send_resolved: true
    url: http://dingtalk-hook-web
- name: monitoring-dinghook-db
  webhook_configs:
  - send_resolved: true
    url: http://dingtalk-hook-db
templates: []
```

目前 alertmanagerconfig 这个 CRD 使用起来感觉有点麻烦, 一级 route 目前只能按照 namespace 筛选, 而且 `continue` 也只能设置成 `false` , 而且无法指定其他配置中的 receiver, 比如全局配置中的 `Default`

```bash
[root@k8s-node1 ~]# kubectl explain alertmanagerconfig.spec.route.continue
DESCRIPTION:
     Boolean indicating whether an alert should continue matching subsequent
     sibling nodes. It will always be overridden to true for the first-level
     route by the Prometheus operator.
[root@k8s-node1 ~]# kubectl explain alertmanagerconfig.spec.route.matchers
DESCRIPTION:
     List of matchers that the alert’s labels should match. For the first
     level route, the operator removes any existing equality and regexp matcher
     on the `namespace` label and adds a `namespace: <object namespace>`
     matcher.
```

## 2.3 告警模板

alertmanager 收到的告警大概长这个样子

![image-20230430212127175](https://image.lvbibir.cn/blog/image-20230430212127175.png)

alertmanager CRD 支持 `configMaps` 参数, 会自动挂载到 `/etc/alertmanager/configmaps` 目录, 我们可以将模板文件配置成 configmap

```bash
[root@k8s-node1 ~]# kubectl explain alertmanager.spec.configMaps
DESCRIPTION:
     ConfigMaps is a list of ConfigMaps in the same namespace as the
     Alertmanager object, which shall be mounted into the Alertmanager Pods. The
     ConfigMaps are mounted into /etc/alertmanager/configmaps/<configmap-name>.
```

创建模板文件 email.tmpl

```html
{{ define "email.html" }}
{{- if gt (len .Alerts.Firing) 0 -}}
{{- range $index, $alert := .Alerts -}}
========= ERROR ==========<br>
告警名称：{{ .Labels.alertname }}<br>
告警级别：{{ .Labels.severity }}<br>
告警机器：{{ .Labels.instance }} {{ .Labels.device }}<br>
告警详情：{{ .Annotations.summary }}<br>
告警时间：{{ (.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }}<br>
========= END ==========<br>
{{- end }}
{{- end }}
{{- if gt (len .Alerts.Resolved) 0 -}}
{{- range $index, $alert := .Alerts -}}
========= INFO ==========<br>
告警名称：{{ .Labels.alertname }}<br>
告警级别：{{ .Labels.severity }}<br>
告警机器：{{ .Labels.instance }}<br>
告警详情：{{ .Annotations.summary }}<br>
告警时间：{{ (.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }}<br>
恢复时间：{{ (.EndsAt.Add 28800e9).Format "2006-01-02 15:04:05" }}<br>
========= END ==========<br>
{{- end }}
{{- end }}
{{- end }}
```

创建 configmap

```bash
kubectl create configmap alertmanager-templates --from-file=email.tmpl --dry-run -o yaml -n monitoring > alertmanager-configmap-templates.yaml
kubectl apply -f alertmanager-configmap-templates.yaml
```

更新 alertmanager 示例, 添加 configmap

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
spec:
  alertmanagerConfigSelector:
    matchLabels:
      alertmanager: main
  configMaps:
  - alertmanager-templates
```

查看挂载

```bash
# kubectl get pod -n monitoring alertmanager-main-0 -o jsonpath="{.spec.volumes[?(@.name=='configmap-alertmanager-templates')]}" | python -m json.tool
{
    "configMap": {
        "defaultMode": 420,
        "name": "alertmanager-templates"
    },
    "name": "configmap-alertmanager-templates"
}
```

查看容器内的路径

```bash
# kubectl exec -it alertmanager-main-0 -n monitoring -- sh
/alertmanager $ cat /etc/alertmanager/configmaps/alertmanager-templates/email.tmpl
```

修改 alertmanager.yaml 配置文件, 指定模板文件

```yaml
receivers:
- name: Default
  email_configs:
  - to: 'lvbibir@foxmail.com'
    send_resolved: true
    html: '{{ template "email.html" . }}' # 添加 与模板中的 define 对应
- name: Critical
  email_configs:
  - to: 'lvbibir@foxmail.com'
    send_resolved: true
    html: '{{ template "email.html" . }}' # 添加 与模板中的 define 对应
templates:
  - '/etc/alertmanager/configmaps/alertmanager-templates/*.tmpl'
```

更新 secret

```bash
kubectl create secret generic alertmanager-main -n monitoring --from-file=alertmanager.yaml --dry-run -oyaml > alertmanager-main-secret.yaml
kubectl apply -f alertmanager-main-secret.yaml 
```

查看配置是否生效, 在 webUI 界面查看

![image-20230430222734192](https://image.lvbibir.cn/blog/image-20230430222734192.png)

查看新生成的告警邮件

- 告警邮件
  ![image-20230430223704567](https://image.lvbibir.cn/blog/image-20230430223704567.png)

- 恢复邮件
  ![image-20230430223637098](https://image.lvbibir.cn/blog/image-20230430223637098.png)

