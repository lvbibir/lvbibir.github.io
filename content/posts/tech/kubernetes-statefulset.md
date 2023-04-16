---
title: "kubernetes | statefulset控制器详解" 
date: 2023-04-12
lastmod: 2023-04-12
tags: 
- kubernetes
keywords:
- kubernetes
- statefulset
description: ""
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---

## 基础概念

StatefulSet 应用场景：分布式应用、集群

- 部署有状态应用

- 解决Pod独立生命周期，保持Pod启动顺序和唯一性

  - 稳定，唯一的网络标识符，持久存储
  - 有序，优雅的部署和扩展、删除和终止
  - 有序，滚动更新

StatefulSet 控制器的优势

- 稳定的存储
  - StatefulSet的存储卷使用VolumeClaimTemplate创建，称为卷申请模板，当StatefulSet使用VolumeClaimTemplate创建一个PersistentVolume时，同样也会为每个Pod分配并创建一个编号的PVC。该PVC和PV不会随着StatefulSet的删除而删除

- 稳定的网络ID
  - StatefulSet 中的每个 POD 名称固定：`<statefulset-name>-<number>`
  - 通过 serviceName 字段指定 Headless Service ，可以为每个 POD 分配一个固定的 DNS 解析，重启或者重建 POD 时虽然 ip 有所变动，但 DNS 解析会保持稳定

示例yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: statefulset-nginx
  labels:
    app: statefulset-nginx
spec:
  selector:
    app: statefulset-nginx
  clusterIP: None
  ports:
  - name: web
    port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: statefulset-nginx
spec:
  serviceName: "statefulset-nginx"
  replicas: 2
  selector:
    matchLabels:
      app: statefulset-nginx
  template:
    metadata:
      labels:
        app: statefulset-nginx
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: statefulset-nginx
        image: nginx:1.22.1
        imagePullPolicy: IfNotPresent
        ports:
        - name: web
          containerPort: 80
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      storageClassName: "nfs"
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
```

## 稳定的存储

可以看到与deployment不同，statefulset中的每个pod都分配到了独立的pv，且重启pod后存储对应关系不变

```bash
[root@k8s-node1 ~]# kubectl get pod,pvc,pv | awk  '{print $1}'
# pod NAME
pod/nfs-client-provisioner-66d6cb77fd-47hsf
pod/statefulset-nginx-0
pod/statefulset-nginx-1
# pvc NAME
persistentvolumeclaim/www-statefulset-nginx-0
persistentvolumeclaim/www-statefulset-nginx-1
# pv NAME
persistentvolume/pvc-17751fde-1b23-4535-98bb-a70342ddd6fe
persistentvolume/pvc-b7519f46-b2af-42e4-b66d-d7459be2e87c
[root@k8s-node1 ~]# ls  /nfs/
default-www-statefulset-nginx-0-pvc-17751fde-1b23-4535-98bb-a70342ddd6fe 
default-www-statefulset-nginx-1-pvc-b7519f46-b2af-42e4-b66d-d7459be2e87c
```

## 稳定的网络ID

手动删除pod后除了pod的ip会变动，主机名和dns解析都正常

```bash
# POD名字固定
[root@k8s-node1 ~]# kubectl get pods -l app=statefulset-nginx
NAME                  READY   STATUS    RESTARTS   AGE
statefulset-nginx-0   1/1     Running   0          5m18s
statefulset-nginx-1   1/1     Running   0          5m17s

# 主机名固定
[root@k8s-node1 ~]# for i in 0 1; do kubectl exec "statefulset-nginx-$i" -- hostname; done
statefulset-nginx-0
statefulset-nginx-1

# DNS解析固定
[root@k8s-node1 ~]# kubectl run -it --rm --restart=Never --image busybox:1.28 dns-test -- nslookup statefulset-nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      statefulset-nginx
Address 1: 10.244.107.230 statefulset-nginx-1.statefulset-nginx.default.svc.cluster.local
Address 2: 10.244.169.157 statefulset-nginx-0.statefulset-nginx.default.svc.cluster.local
pod "dns-test" deleted
```

## 暴露应用

由于使用的是 Headless Service ，无法使用 NodePort 的方式暴露应用端口，我们可以单独创建 service 来暴露特定 pod 应用

StatefulSet 控制器中的 pod 名称都是固定的： `<statefulset-name>-<number>` ，可以通过 `statefulset.kubernetes.io/pod-name` 标签固定 pod

示例如下

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ss-nginx-0
  labels:
    app: ss-nginx-0
spec:
  selector:
    statefulset.kubernetes.io/pod-name: statefulset-nginx-0
  type: NodePort
  ports:
  - name: web
    port: 80
    targetPort: 80
    nodePort: 30003
```

验证

```bash
[root@k8s-node1 ~]# kubectl get svc ss-nginx-0
NAME         TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
ss-nginx-0   NodePort   10.111.69.1   <none>        80:30003/TCP   3h53m
[root@k8s-node1 ~]# kubectl get ep ss-nginx-0
NAME         ENDPOINTS           AGE
ss-nginx-0   10.244.169.188:80   3h53m
```

