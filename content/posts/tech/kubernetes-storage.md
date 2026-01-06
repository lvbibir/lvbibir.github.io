---
title: "kubernetes | 存储" 
date: 2022-10-07
lastmod: 2024-01-28
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
description: "介绍 kubernetes 中的存储使用简介，例如 emptydir、hostpath、NFS、pv、pvc、statefulset 控制器" 
cover:
    image: "images/kubernetes.png"
---

# 0 前言

基于 `centos7.9`，`docker-ce-20.10.18`，`kubelet-1.22.3-0`

为什么需要数据卷

1. 启动时需要的初始数据，录入配置文件
2. 启动过程中产生的临时数据，该临时数据需要多个容器间共享
3. 启动过程中产生的持久化数据，例如 mysql 的 data

数据卷概述

- kubernetes 中的 volume 提供了在容器中挂载外部存储的能力
- Pod 需要设置卷来源（spec.volume）和挂载点（spec.containers.volumeMounts）两个信息后才可以使用相应的 Volume

常用的数据卷：

- 本地（hostPath，emptyDir）
- 网络（NFS，Ceph，GlusterFS）
- 公有云（AWS EBS）
- K8S 资源（configmap，secret）

# 1 emptyDir（临时存储卷）

emptyDir 卷：是一个临时存储卷，与 Pod 生命周期绑定一起，如果 Pod 删除了卷也会被删除。

应用场景：Pod 中容器之间数据共享

emptyDir 的实际存储路径在 pod 所在节点的 `/var/lib/kubelet/pods/<pod-id>/volumes/kubernetes.io~empty-dir` 目录下

查看 pod 的 uid

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

# 2 hostPath（节点存储卷）

hostPath 卷：挂载 Node 文件系统（Pod 所在节点）上文件或者目录到 Pod 中的容器。

应用场景：Pod 中容器需要访问宿主机文件

示例 yaml

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

# 3 NFS（网络存储卷）

NFS 卷提供对 NFS 挂载支持，可以自动将 NFS 共享路径挂载到 Pod 中

配置 nfs 服务端，

```bash
yum install nfs-utils # nfs-utils包每个节点都需安装
mkdir -p /nfs
echo "/nfs 1.1.1.0/24(rw,async,no_root_squash)" >> /etc/exports
# 格式：NFS共享的目录 客户端地址1(参数1,参数2,...) 客户端地址2(参数1,参数2,...))
systemctl enable --now nfs
systemctl enable --now rpcbind
```

- 常用选项：
  - ro：客户端挂载后，其权限为只读，默认选项；
  - rw: 读写权限；
  - sync：同时将数据写入到内存与硬盘中；
  - async：异步，优先将数据保存到内存，然后再写入硬盘；
  - Secure：要求请求源的端口小于 1024
- 用户映射：
  - root_squash: 当 NFS 客户端使用 root 用户访问时，映射到 NFS 服务器的匿名用户；
  - no_root_squash: 当 NFS 客户端使用 root 用户访问时，映射到 NFS 服务器的 root 用户；
  - all_squash: 全部用户都映射为服务器端的匿名用户；
  - anonuid=UID：将客户端登录用户映射为此处指定的用户 uid；
  - anongid=GID：将客户端登录用户映射为此处指定的用户 gid

客户端测试

```bash
[root@k8s-node2 ~]# mount -t nfs k8s-node1:/nfs /mnt/
[root@k8s-node2 ~]# df -hT | grep k8s-node1
k8s-node1:/nfs nfs4       44G  4.0G   41G   9% /mnt
```

示例 yaml

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
          path: /nfs/
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
[root@k8s-node1 ~]# echo "hello, nfs" > /nfs/index.html
[root@k8s-node1 ~]# curl 10.97.209.119
hello, nfs
```

# 4 pv 和 pvc（持久存储卷）

## 4.1 基础概念

- PersistentVolume（PV）：存储资源创建和使用抽象化，使得存储作为集群中的资源管理
- PersistentVolumeClaim（PVC）：让用户不需要关心具体的 Volume 实现细节

![image-20221006103106669](/images/image-20221006103106669.png)

pvc 如何匹配到 pv

- 存储空间的请求
    - 匹配最接近的 pv，如果没有满足条件的 pv，则 pod 处于 pending 状态
- 访问模式的设置

存储空间字段能否限制实际可用容量

- 不能，存储空间字段只用于匹配到 pv，具体可用容量取决于网络存储

## 4.2 pv 生命周期

AccessModes（访问模式）：

AccessModes 是用来对 PV 进行访问模式的设置，用于描述用户应用对存储资源的访问权限，访问权限包括下面几种方式：

- ReadWriteOnce（RWO）：可被一个 node 读写挂载
- ReadOnlyMany（ROX）：可被多个 node 只读挂载
- ReadWriteMany（RWX）：可被多个 node 读写挂载

RECLAIM POLICY（回收策略）：

目前 PV 支持的策略有三种：

- Retain（保留）： 保留数据，需要管理员手工清理数据
- Recycle（回收）：清除 PV 中的数据，效果相当于执行 rm -rf /ifs/kuberneres/*
- Delete（删除）：与 PV 相连的后端存储同时删除

STATUS（状态）：

一个 PV 的生命周期中，可能会处于 4 中不同的阶段：

- Available（可用）：表示可用状态，还未被任何 PVC 绑定
- Bound（已绑定）：表示 PV 已经被 PVC 绑定
- Released（已释放）：PVC 被删除，但是资源还未被集群重新声明
- Failed（失败）： 表示该 PV 的自动回收失败

pv 示例

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
    path: /nfs
```

pvc 示例

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
[root@k8s-node1 ~]# echo "pvc for NFS is successful" > /nfs/index.html
[root@k8s-node1 ~]# kubectl get svc -l app=demo-pvc
NAME       TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
demo-pvc   ClusterIP   10.97.28.93   <none>        80/TCP    102s
[root@k8s-node1 ~]# curl 10.97.28.93
pvc for NFS is successful
```

## 4.3 pv 动态供给

之前的 PV 使用方式称为静态供给，需要 K8s 运维工程师提前创建一堆 PV，供开发者使用

因此，K8s 开始支持 PV 动态供给，使用 StorageClass 对象实现。

[查看 k8s 原生支持的共享存储](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner)

![image-20221006112111133](/images/image-20221006112111133.png)

**基于 NFS 实现自动创建 pv 插件**

自动创建的 pv 挂载路径为 `<nfs-path>/<namespace>-<pvc-name>-<pv-name>`

- pvc-name：默认情况下为 yaml 中自定义的 pvc-name，使用 statefulset 控制器时 pvc 的名字为 `<volumeClaimTemplates-name>-<pod-name>`
- pv-name：pv 的名字为 `pvc-<pvc-uid>`

k8s-1.20 版本后默认禁止使用 selfLink，需要打开一下

修改 k8s 的 apiserver 参数，改完 apiserver 会自动重启

```plaintext
[root@k8s-node1 ~]#  vi /etc/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
···
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
    - --feature-gates=RemoveSelfLink=false # 添加这个配置
```

### 4.3.1 部署 NFS 插件

> 此组件是对 nfs-client-provisioner 的扩展，nfs-client-provisioner 已经不提供更新，且 nfs-client-provisioner 的 Github 仓库已经迁移到 [NFS-Subdir-External-Provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) 的仓库

rbac

创建 `nfs-rbac.yml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  namespace: kube-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: kube-system
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: kube-system
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: kube-system
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
```

nfs-subdir-external-provisioner

创建 `nfs-provisioner-deploy.yml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  namespace: kube-system
  labels:
    app: nfs-client-provisioner
spec:
  replicas: 1
  strategy: 
    type: Recreate     # 设置升级策略为删除再创建(默认为滚动更新)
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
      - name: nfs-client-provisioner
        #image: gcr.io/k8s-staging-sig-storage/nfs-subdir-external-provisioner:v4.0.0
        image: registry.cn-hangzhou.aliyuncs.com/lvbibir/nfs-subdir-external-provisioner:v4.0.2
        volumeMounts:
        - name: nfs-client-root
          mountPath: /persistentvolumes
        env:
        - name: PROVISIONER_NAME     # Provisioner的名称,以后设置的storageclass要和这个保持一致
          value: nfs-client 
        - name: NFS_SERVER           # NFS服务器地址,需和valumes参数中配置的保持一致
          value: 1.1.1.1
        - name: NFS_PATH             # NFS服务器数据存储目录,需和valumes参数中配置的保持一致
          value: /nfs/kubernetes
      volumes:
      - name: nfs-client-root
        nfs:
          server: 1.1.1.1            # NFS服务器地址
          path: /nfs/kubernetes      # NFS服务器数据存储目录
```

storageClass

创建 `nfs-sc.yml`

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"  ## 是否设置为默认的storageclass
provisioner: nfs-client                                   ## 动态卷分配者名称，必须和deployment的PROVISIONER_NAME变量中设置的Name一致
parameters:
  archiveOnDelete: "false"                                 ## 设置为"false"时删除PVC不会保留数据,"true"则保留数据
mountOptions: 
  - hard                                                  ## 指定为硬挂载方式
  - nfsvers=4                                             ## 指定NFS版本,这个需要根据NFS Server版本号设置
```

创建上述资源

```bash
[root@k8s-node1 nfs]# mkdir /nfs/kubernetes/
[root@k8s-node1 nfs]# kubectl apply -f .
deployment.apps/nfs-client-provisioner created
serviceaccount/nfs-client-provisioner created
clusterrole.rbac.authorization.k8s.io/nfs-client-provisioner-runner created
clusterrolebinding.rbac.authorization.k8s.io/run-nfs-client-provisioner created
role.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
rolebinding.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
storageclass.storage.k8s.io/nfs created
```

### 4.3.2 示例

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
  storageClassName: "nfs"
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
[root@k8s-node1 ~]# ls -l /nfs/
total 4
drwxrwxrwx. 2 root root  6 Apr 11 17:37 default-pvc-auto-pvc-22b65e10-ab97-47eb-aaa1-6c354a749a55
```

以上
