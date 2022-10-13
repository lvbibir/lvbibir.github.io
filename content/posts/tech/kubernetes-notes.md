---
title: "kubernetes | 杂记" 
date: 2022-10-01
lastmod: 2022-10-01
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
description: "介绍kubectl命令的一些用法、yaml编写技巧等" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---

# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

# 其他

用于控制是否优先本地寻找镜像

```
imagePullPolicy: IfNotPresent
```

# kubectl命令

kubectl命令的自动补全

```
yum install bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
```

一些常用命令

```
# 查看某个资源的详细信息
kubectl describe <type> <name> -n <namespace>
# 查看pod的日志
kubectl logs <pod> -n <namespace>
# 查看当前支持的api版本
kubectl api-versions
```

## kubectl get

```
# 查看所有支持的资源
kubectl api-resources
# 查看集群健康状态
kubectl get cs
# 查看service资源
kubectl get svc/services
# 查看service映射的pod的端口和ip
kubectl get cp/endpoints
kubectl get ns/namespace
# 查看pod
kubectl get pod <podname> -n <namespace>
  -w/--watch: # 实时更新，类似tail的-f选项
  -o wide: # 查看更为详细的信息，比如ip和分配的节点
  -o jsonpath='{.metadata.uid}' # 查看pod的id
```

## kubectl create

```
kubectl create <resource> [Options]
  --dry-run=client:  仅尝试运行，不实际运行
  -o, --output='': 输出为指定的格式
```

# namespace

k8s与docker的namespace不同

docker中的namespace用于容器间的资源隔离

k8s中的namespace用于

- k8s的抽象资源间的资源隔离，比如pods、控制器、service等

- 资源隔离后，对这一组资源进行权限控制

创建命名空间及一系列资源

```
[root@k8s-node1 ~]# kubectl create namespace test
namespace/test created
[root@k8s-node1 ~]# kubectl create deployment my-dep --image=lizhenliang/java-demo --replicas=3 -n test
deployment.apps/my-dep created
[root@k8s-node1 ~]# kubectl expose deployment my-dep --port=80 --target-port=8080 --type=NodePort -n test
service/my-dep exposed
[root@k8s-node1 ~]# kubectl get pods,deployment,svc -n test
NAME                          READY   STATUS    RESTARTS   AGE
pod/my-dep-5f8dfc8c78-7w5nz   1/1     Running   0          41s
pod/my-dep-5f8dfc8c78-gt65r   1/1     Running   0          41s
pod/my-dep-5f8dfc8c78-n4vjd   1/1     Running   0          41s

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-dep   3/3     3            3           41s

NAME             TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/my-dep   NodePort   10.110.205.138   <none>        80:31890/TCP   17s
```


# yaml编写

通过创建资源获取yaml

```
kubectl create deployment web --image=nginx:1.19 --dry-run=client -o yaml > deploy.yaml
```

通过已有资源获取yaml

```
kubectl get deployment nginx-deployment -o yaml > deploy2.yaml
```

查看api中的资源及解释

```
kubectl explain pods.spec.container
kubectl explain deployment
```

## yaml报错排查

```
error: error parsing pod-configmap.yaml: error converting YAML to JSON: yaml: line 19: did not find expected '-' indicator
```

解决

由于yaml文件列表对齐不统一导致的

yaml文件格式要对齐，同一级别的对象要放在同一列，几个空格不重要，不要用tab制表符

```yaml
# 格式1
ports:
  - port: 80
  
# 格式2
ports:
- port: 80
```

