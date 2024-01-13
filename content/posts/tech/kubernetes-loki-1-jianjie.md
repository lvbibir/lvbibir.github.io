---
title: "loki (一) 简介" 
date: 2023-04-30
lastmod: 2023-04-30
tags: 
  - kubernetes
keywords:
  - kubernetes
  - prometheus
  - loki
description: "loki 开源日志的优缺点及架构; loki 的四个角色; prometail 简介; 日志告警" 
cover:
    image: "https://image.lvbibir.cn/blog/loki.png"
---

# 0. 前言

基于 `centos7.9` `docker-ce-20.10.18` `kubelet-1.22.3-0` `loki-2.3.0` `promtail-2.3.0`

# 1. 简介

[项目地址](https://github.com/grafana/loki/) [官方文档](https://grafana.com/docs/loki/latest/)

Loki 是 Grafana Labs 团队最新的开源项目，是一个水平可扩展，高可用性，多租户的日志聚合系统。它的设计非常经济高效且易于操作，因为它不会为日志内容编制索引，而是为每个日志流编制一组标签，专门为 [Prometheus](https://cloud.tencent.com/product/tmp?from=20065&from_column=20065) 和 Kubernetes 用户做了相关优化。该项目受 Prometheus 启发，官方的介绍就是： `Like Prometheus, But For Logs.`

# 2. 优缺点

与其他日志聚合系统相比， Loki 具有下面的一些特性:

- 低索引开销
  - 不对日志进行全文索引。通过存储压缩非结构化日志和仅索引元数据，Loki 操作起来会更简单，更省成本。
  - 这样做可以大幅降低索引资源开销, es 无论你查不查，巨大的索引开销必须时刻承担

- 并发查询
  - 为了弥补没有全文索引带来的查询降速使用，Loki 将把查询分解成较小的分片，可以理解为并发的 grep

- 和 prometheus 采用相同的标签，对接 alertmanager
  - Loki 和 Prometheus 之间的标签一致是 Loki 的超级能力之一

- 受到 Grafana 原生支持
  - 避免 kibana 和 grafana 来回切换

- 服务发现
  - 支持与 prometheus 一样的服务发现功能, 特别适合储存 Kubernetes Pod 日志
  - 无需使用日志落盘或者 sidecar

当然, 它也有一定的缺点:

- 技术比较新颖，相对应的论坛不是非常活跃。

- 功能单一，只针对日志的查看，筛选有好的表现，对于数据的处理以及清洗没有 ELK 强大，同时与 ELK 相比，对于后期，ELK 可以连用各种技术进行日志的大数据处理，但是 loki 不行。

# 3. 架构

## 3.1 整体架构

![1c8596771859db9599e7f0d92187a4c5.webp](https://image.lvbibir.cn/blog/1c8596771859db9599e7f0d92187a4c5.webp)

在 Loki 架构中有以下几个概念：

- Grafana：相当于 EFK 中的 Kibana ，用于 UI 的展示。
- Loki：相当于 EFK 中的 ElasticSearch ，用于存储日志和处理查询。
- Promtail：相当于 EFK 中的 Filebeat/Fluentd ，用于采集日志并将其发送给 Loki 。
- LogQL：Loki 提供的日志查询语言，类似 Prometheus 的 PromQL，而且 Loki 支持 LogQL 查询直接转换为 Prometheus 指标。

## 3.2 promtail

[官方文档](https://grafana.com/docs/loki/latest/clients/promtail/)

promtail 是 loki 架构中最常用的采集器, 相当于 EFK 中的 filebeat/fluentd

它的主要工作流程:

- 使用 fsnotify 监听指定目录下（例如：/var/log/*.log）的文件创建与删除
- 对每个活跃的日志文件起一个 goroutine 进行类似 tail -f 的读取，读取到的内容发送给 channel
- 有一个单独的 goroutine 会读取 channel 中的日志行，分批并附加上标签后推送给 Loki

## 3.3 loki

![img](https://image.lvbibir.cn/blog/536ff8e45540a38aceec8b0457b581b0.png)

Loki 采用读写分离架构，关键组件有：

- Distributor 分发器：日志数据传输的“第一站”，Distributor 分发器接收到日志数据后，根据元数据和 hash 算法，将日志分批并行地发送到多个 Ingester 接收器上
- Ingester 接收器：接收器是一个有状态的组件，在日志进入时对其进行 gzip 压缩操作，并负责构建和刷新 chunck 块，当 chunk 块达到一定的数量或者时间后，就会刷新 chunk 块和对应的 Index 索引存储到数据库中
- Querier 查询器：给定一个时间范围和标签选择器，Querier 查询器可以从数据库中查看 Index 索引以确定哪些 chunck 块匹配，并通过 greps 将结果显示出来，它还会直接从 Ingester 接收器获取尚未刷新的最新数据
- Query frontend 查询前端：查询前端是一个可选的组件，运行在 Querier 查询器之前，起到缓存，均衡调度的功能，用于加速日志查询

Loki 提供了两种部署方式：

- 单体模式，ALL IN ONE：Loki 支持单一进程模式，可在一个进程中运行所有必需的组件。单进程模式非常适合测试 Loki 或以小规模运行。不过尽管每个组件都以相同的进程运行，但它们仍将通过本地网络相互连接进行组件之间的通信（grpc）。使用 Helm 部署就是采用的该模式。
- 微服务模式：为了实现水平可伸缩性，Loki 支持组件拆分为单独的组件分开部署，从而使它们彼此独立地扩展。每个组件都产生一个用于内部请求的 gRPC 服务器和一个用于外部 API 请求的 HTTP 服务，所有组件都带有 HTTP 服务器，但是大多数只暴露就绪接口、运行状况和指标端点。

# 4. 日志告警

Loki 支持三种模式创建日志告警：

- 在 Promtail 中的 pipeline 管道的 metrics 的阶段，根据需求增加一个监控指标，然后使用 Prometheus 结合 Alertmanager 完成监控报警。
- 通过 Loki 自带的报警功能（ Ruler 组件）可以持续查询一个 rules 规则，并将超过阈值的事件推送给 AlertManager 或者其他 Webhook 服务。
- 将 LogQL 查询转换为 Prometheus 指标。可以通过 Grafana 自带的 Alert rules & notifications，定义有关 LogQL 指标的报警，推送到 Notification channels（ Prometheus Alertmanager ， Webhook 等）。
