---
title: "kubernetes | 存储" 
date: 2022-10-07
lastmod: 2022-10-07
tags: 
- kubernetes
keywords:
- linux
- centos
- kubernetes
- storage
- emptydir
- hostpath
- NFS
- pv
- pvc
- statefulset
description: "介绍kubernetes中的存储使用简介，例如emptydir、hostpath、NFS、pv、pvc、statefulset控制器" 
cover:
    image: "https://image.lvbibir.cn/blog/kubernetes.png"
    hidden: true
    hiddenInSingle: true 
---
# 前言

基于`centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

**为什么需要数据卷**

1. 启动时需要的初始数据，录入配置文件

2. 启动过程中产生的临时数据，该临时数据需要多个容器间共享

3. 启动过程中产生的持久化数据，例如mysql的data

**数据卷概述**

- kubernetes中的volume提供了在容器中挂载外部存储的能力
- Pod需要设置卷来源（spec.volume）和挂载点（spec.containers.volumeMounts）两个信息后才可以使用相应的Volume

常用的数据卷：

- 本地（hostPath，emptyDir） 

- 网络（NFS，Ceph，GlusterFS） 

- 公有云（AWS EBS） 

- K8S资源（configmap，secret）

# emptyDir（临时存储卷）

emptyDir卷：是一个临时存储卷，与Pod生命周期绑定一起，如果Pod删除了卷也会被删除。

应用场景：Pod中容器之间数据共享

emptyDir的实际存储路径在pod所在节点的`/var/lib/kubelet/pods/<pod-id>/volumes/kubernetes.io~empty-dir`目录下

查看pod的uid

```bash
kubectl get pod <pod-name> -o jsonpath='{.metadata.uid}'
```

示例如下

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-emptydir
spec:
  terminationGracePeriodSeconds: 5
  containers:
  - name: write
    image: busybox
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh", "-c", "for i in $(seq 100); do echo $i >> /data/hello; sleep 1; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  - name: read
    image: busybox
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh", "-c", "tail -f /data/hello"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}
```

查看日志

```bash
[root@k8s-node1 ~]# kubectl logs -f demo-emptydir -c read 
1
2
3
...
```

# hostPath（节点存储卷）

hostPath卷：挂载Node文件系统（Pod所在节点）上文件或者目录到Pod中的容器。

应用场景：Pod中容器需要访问宿主机文件

示例yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-hostpath
spec:
  terminationGracePeriodSeconds: 5
  containers:
  - name: busybox
    image: busybox
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh", "-c", "sleep 36000"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    hostPath:
      path: /tmp
      type: Directory
```

# NFS（网络存储卷）

NFS卷提供对NFS挂载支持，可以自动将NFS共享路径挂载到Pod中

配置nfs服务端，

```bash
yum install nfs-utils # nfs-utils包每个节点都需安装
mkdir -p /ifs/kubernetes
echo "/ifs/kubernetes *(rw,no_root_squash)" >> /etc/exports
systemctl start nfs && systemctl enable nfs
```

客户端测试

```bash
[root@k8s-node2 ~]# mount -t nfs k8s-node1:/ifs/kubernetes /mnt/
[root@k8s-node2 ~]# df -hT | grep k8s-node1
k8s-node1:/ifs/kubernetes nfs4       44G  4.0G   41G   9% /mnt
```

示例yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-nfs
  labels:
    app: demo-nfs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-nfs
  template:
    metadata:
      labels:
        app: demo-nfs
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: demo-nfs
        image: nginx:1.22.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: www
        nfs:
          server: k8s-node1
          path: /ifs/kubernetes/
---
apiVersion: v1
kind: Service
metadata:
  name: demo-nfs
  labels:
    app: demo-nfs
spec:
  selector:
    app: demo-nfs
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30003
  type: NodePort
```

验证

```bash
[root@k8s-node1 ~]# kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
demo-nfs     NodePort    10.97.209.119   <none>        80:30003/TCP   5m41s
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        5d2h
[root@k8s-node1 ~]# echo "hello, nfs" > /ifs/kubernetes/index.html
[root@k8s-node1 ~]# curl 10.97.209.119
hello, nfs
```

# pv和pvc（持久存储卷）

## 基础概念

- PersistentVolume（PV）：存储资源创建和使用抽象化，使得存储作为集群中的资源管理

- PersistentVolumeClaim（PVC）：让用户不需要关心具体的Volume实现细节

![image-20221006103106669](https://image.lvbibir.cn/blog/image-20221006103106669.png)

pvc如何匹配到pv

- 存储空间的请求

  匹配最接近的pv，如果没有满足条件的pv，则pod处于pending状态

- 访问模式的设置

存储空间字段能否限制实际可用容量

- 不能，存储空间字段只用于匹配到pv，具体可用容量取决于网络存储

## pv生命周期

**AccessModes（访问模式）：**

AccessModes 是用来对 PV 进行访问模式的设置，用于描述用户应用对存储资源的访问权限，访问权限包括下面几种方式：

- ReadWriteOnce（RWO）：可被一个 node 读写挂载

- ReadOnlyMany（ROX）：可被多个 node 只读挂载

- ReadWriteMany（RWX）：可被多个 node 读写挂载

**RECLAIM POLICY（回收策略）：**

目前 PV 支持的策略有三种：

- Retain（保留）： 保留数据，需要管理员手工清理数据

- Recycle（回收）：清除 PV 中的数据，效果相当于执行 rm -rf /ifs/kuberneres/*

- Delete（删除）：与 PV 相连的后端存储同时删除

**STATUS（状态）：**

一个 PV 的生命周期中，可能会处于4中不同的阶段：

- Available（可用）：表示可用状态，还未被任何 PVC 绑定

- Bound（已绑定）：表示 PV 已经被 PVC 绑定

- Released（已释放）：PVC 被删除，但是资源还未被集群重新声明

- Failed（失败）： 表示该 PV 的自动回收失败

pv示例

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: demo-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteMany
  nfs:
    server: k8s-node1
    path: /ifs/kubernetes
```

pvc示例

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```

deployment & service 示例

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-pvc
  labels:
    app: demo-pvc
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-pvc
  template:
    metadata:
      labels:
        app: demo-pvc
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: demo-pvc
        image: nginx:1.22.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: www-pvc
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: www-pvc
        persistentVolumeClaim:
          claimName: demo-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: demo-pvc
  labels:
    app: demo-pvc
spec:
  selector:
    app: demo-pvc
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

验证

```bash
[root@k8s-node1 ~]# echo "pvc for NFS is successful" > /ifs/kubernetes/index.html
[root@k8s-node1 ~]# kubectl get svc -l app=demo-pvc
NAME       TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
demo-pvc   ClusterIP   10.97.28.93   <none>        80/TCP    102s
[root@k8s-node1 ~]# curl 10.97.28.93
pvc for NFS is successful
```

## pv动态供给

之前的PV使用方式称为静态供给，需要K8s运维工程师提前创建一堆PV，供开发者使用

因此，K8s开始支持PV动态供给，使用StorageClass对象实现。

> 查看k8s原生支持的共享存储：https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner

![image-20221006112111133](https://image.lvbibir.cn/blog/image-20221006112111133.png)

**基于NFS实现自动创建pv插件**

自动创建的pv挂载路径为`<nfs-path>/<namespace>-<pvc-name>-<pv-name>`

- pvc-name：默认情况下为yaml中自定义的pvc-name，使用statefulset控制器时pvc的名字为`<volumeClaimTemplates-name>-<pod-name>`
- pv-name：pv的名字为`pvc-<pvc-uid>`

k8s-1.20版本后默认禁止使用selfLink，需要打开一下

修改k8s的apiserver参数，改完 apiserver 会自动重启

```
[root@k8s-node1 ~]#  vi /etc/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
···
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
    - --feature-gates=RemoveSelfLink=false # 添加这个配置
```

### 部署NFS插件

下载插件

```
git clone https://github.com/kubernetes-incubator/external-storage
cd external-storage/nfs-client/deploy
```

deployment.yaml

```yaml
            - name: NFS_SERVER
              value: 1.1.1.1 # 修改ip地址，nfs服务器
      volumes:
        - name: nfs-client-root
          nfs:
            server: 1.1.1.1 # 修改ip地址，nfs服务器
            path: /ifs/kubernetes
```

class.yaml

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: fuseim.pri/ifs 
parameters:
  archiveOnDelete: "true" # 默认是flase，设置为true可以使pv自动删除后保留数据，数据挂载目录会重命名为archived-<name>
```

部署插件

```bash
# 授权访问apiserver
kubectl apply -f rbac.yaml 
# 部署插件
kubectl apply -f deployment.yaml 
# 创建存储类
kubectl apply -f class.yaml
# 查看创建的存储类
kubectl get storageclasses | sc
```

### 示例

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-auto-pv
  labels:
    app: demo-auto-pv
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-auto-pv
  template:
    metadata:
      labels:
        app: demo-auto-pv
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: demo-auto-pv
        image: nginx:1.22.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: www
        persistentVolumeClaim:
          claimName: pvc-auto
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-auto
spec:
  storageClassName: "managed-nfs-storage"
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

测试验证

```bash
[root@k8s-node1 ~]# kubectl get pods
NAME                                          READY   STATUS    RESTARTS   AGE
pod/demo-auto-pv-7c974689b4-4cwr6             1/1     Running   0          47s
pod/demo-auto-pv-7c974689b4-bb9v8             1/1     Running   0          47s
pod/demo-auto-pv-7c974689b4-p525n             1/1     Running   0          47s
pod/nfs-client-provisioner-66d6cb77fd-47hsf   1/1     Running   0          4m15s
[root@k8s-node1 ~]# kubectl get pvc
NAME                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
persistentvolumeclaim/pvc-auto   Bound    pvc-22b65e10-ab97-47eb-aaa1-6c354a749a55   2Gi        RWO            managed-nfs-storage   47s
[root@k8s-node1 ~]# kubectl get pv
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS          REASON   AGE
persistentvolume/pvc-22b65e10-ab97-47eb-aaa1-6c354a749a55   2Gi        RWO            Delete           Bound    default/pvc-auto   managed-nfs-storage            47s
[root@k8s-node1 ~]# ls -l /ifs/kubernetes/
total 4
drwxrwxrwx. 2 root root  6 Apr 11 17:37 default-pvc-auto-pvc-22b65e10-ab97-47eb-aaa1-6c354a749a55
-rw-r--r--. 1 root root 26 Apr 11 17:22 index.htmlc
```

# StatefulSet控制器

StatefulSet应用场景：分布式应用、数据库集群

- 部署有状态应用

- 解决Pod独立生命周期，保持Pod启动顺序和唯一性

- - 稳定，唯一的网络标识符，持久存储

  - 有序，优雅的部署和扩展、删除和终止
  - 有序，滚动更新

**StatefulSet控制器的优势**

- 稳定的网络ID

使用Headless Service（相比普通Service只是将spec.clusterIP定义为None）来维护Pod网络身份。并且添加serviceName: “nginx”字段指定StatefulSet控制器要使用这个Headless Service。

DNS解析名称：`<statefulsetName-index>.<service><namespace>.svc.cluster.local`

- 稳定的存储

StatefulSet的存储卷使用VolumeClaimTemplate创建，称为卷申请模板，当StatefulSet使用VolumeClaimTemplate创建一个PersistentVolume时，同样也会为每个Pod分配并创建一个编号的PVC。该PVC和PV不会随着StatefulSet的删除而删除

示例yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: statefulset-nginx
  labels:
    app: statefulset-nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: statefulset-nginx
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
      containers:
      - name: statefulset-nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "managed-nfs-storage"
      resources:
        requests:
          storage: 1Gi
```

测试验证

- 稳定的存储

可以看到与deployment不同，statefulset中的每个pod都分配到了独立的pv，且重启pod后存储对应关系不变

```
[root@k8s-node1 ~]# kubectl get pod,pvc,pv | awk -F' ' '{print $1}'
# POD NAME
pod/statefulset-nginx-0
pod/statefulset-nginx-1
# PVC NAME
persistentvolumeclaim/www-statefulset-nginx-0
persistentvolumeclaim/www-statefulset-nginx-1
# PV NAME
persistentvolume/pvc-098ab1c2-fd72-45d2-86e5-387950f05278
persistentvolume/pvc-b06ce47f-2839-48e7-9999-3cbb8978494a
[root@k8s-node1 ~]# ls /ifs/kubernetes/
default-www-statefulset-nginx-0-pvc-098ab1c2-fd72-45d2-86e5-387950f05278
default-www-statefulset-nginx-1-pvc-b06ce47f-2839-48e7-9999-3cbb8978494a
```

- 稳定的网络ID

手动删除pod后除了pod的ip会变动，主机名和dns解析都正常

```
# POD名字固定
[root@k8s-node1 ~]# kubectl get pods -l app=statefulset-nginx
NAME                  READY   STATUS    RESTARTS   AGE
statefulset-nginx-0   1/1     Running   0          5m18s
statefulset-nginx-1   1/1     Running   0          5m17s

# 主机名固定
[root@k8s-node1 ~]# for i in 0 1; do kubectl exec "statefulset-nginx-$i" -- sh -c 'hostname'; done
statefulset-nginx-0
statefulset-nginx-1

# dns解析固定
[root@k8s-node1 ~]# kubectl run -i --tty --image busybox:1.28 dns-test --restart=Never --rm nslookup statefulset-nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      statefulset-nginx
Address 1: 10.244.169.152 statefulset-nginx-1.statefulset-nginx.default.svc.cluster.local
Address 2: 10.244.107.222 statefulset-nginx-0.statefulset-nginx.default.svc.cluster.local
```









