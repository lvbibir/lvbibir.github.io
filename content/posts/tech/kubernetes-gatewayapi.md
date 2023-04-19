---
title: "kubernetes | Gateway API 简介及部署" 
date: 2023-04-16
lastmod: 2023-04-16
tags: 
- kubernetes
keywords:
- kubernetes
- gatewayapi
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---

# 1. 简介

Gateway API（之前叫 Service API）是由 SIG-NETWORK 社区管理的开源项目，项目地址：https://gateway-api.sigs.k8s.io/。主要原因是 Ingress 资源对象不能很好的满足网络需求，很多场景下 Ingress 控制器都需要通过定义 annotations 或者 crd 来进行功能扩展，这对于使用标准和支持是非常不利的，新推出的 Gateway API 旨在通过可扩展的面向角色的接口来增强服务网络。

![api-model](https://image.lvbibir.cn/blog/api-model.png)

Gateway API 是 Kubernetes 中的一个 API 资源集合，包括 GatewayClass、Gateway、HTTPRoute、TCPRoute、Service 等，这些资源共同为各种网络用例构建模型。

# 2. 部署

## 2.1 crd

内容较长，直接复制[官网yaml](https://doc.traefik.io/traefik/v2.5/reference/dynamic-configuration/kubernetes-gateway/#definitions)

```bash
[root@k8s-node1 traefik]# kubectl apply -f  gateway-api-crd.yml
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/tcproutes.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/tlsroutes.networking.x-k8s.io created
```

## 2.2 rbac

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gateway-role
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - gatewayclasses
      - gateways
      - httproutes
      - tcproutes
      - tlsroutes
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - gatewayclasses/status
      - gateways/status
      - httproutes/status
      - tcproutes/status
      - tlsroutes/status
    verbs:
      - update

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gateway-controller

roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: gateway-role
subjects:
  - kind: ServiceAccount
    name: traefik-ingress-controller
    namespace: default
```

应用yaml

```bash
[root@k8s-node1 traefik]# kubectl apply -f gateway-api-rbac.yml
clusterrole.rbac.authorization.k8s.io/gateway-role created
clusterrolebinding.rbac.authorization.k8s.io/gateway-controller created
```

