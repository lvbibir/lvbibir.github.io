---
title: "cephadm 离线安装 ceph-v16 (Pacific) (openeuler)" 
date: 2022-08-19
lastmod: 2022-08-19
tags: 
- linux
- ceph
- docker
keywords:
- linux
- ceph
- docker
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/ceph.png" 
---

# 前言

> 适用于 Centos8/openeuler + docker 

安装 cephadm、ceph-common 的过程就不赘述了，主要探讨如何实现 cephadm 离线安装 ceph v16.2.8

# 一、离线 rpm 包和 docker 镜像的获取

1. 找一台有外网的测试机（尽量跟生产系统的环境一致）通过 yum 安装 cephadm、ceph-common、docker 等需要的 rpm 包，注意使用  `downloadonly` 参数先下载好 rpm 包和对应的依赖，然后再通过 `yum localinstall`  安装

2. 使用 `cephadm bootstrap` 初始化单节点 ceph 集群，过程中会下载好需要的 docker 镜像

初始化完成后就可以使用 `cephadm rm-cluster --force --zap-osds --fsid <fsid>` 把现在的集群删除了，暂时用不到

# 二、修改 docker 镜像

我们需要修改的镜像只有 `quay.io/ceph/ceph:v16` 这个镜像，采用 `docker commit` 的方式修改

先运行一个容器用于修改文件

```
[root@node-128 ~]# docker run -itd --name test quay.io/ceph/ceph:v16
520af9cf98688d1eb1f572c28c4c60db4f231e4dbf6b3594c54c3892494e5d6c
[root@node-128 ~]# docker exec -it test /bin/bash
# 容器操作
[root@520af9cf9868 /]# find /usr/ -name serve.py
/usr/share/ceph/mgr/cephadm/serve.py
/usr/lib/python3.6/site-packages/pecan/commands/serve.py
[root@520af9cf9868 /]# vi /usr/share/ceph/mgr/cephadm/serve.py
```

如下，注释三行，大约 937 行

![image-20220819162607128](https://image.lvbibir.cn/blog/image-20220819162607128.png)

如下，三处修改大约位于 1342 行

1. 注释 if 语句

2. 修改 cepadm 命令的 `pull` 为 `inspect-image`

3. 获取 container 数据改为直接写死

![image-20220819162743610](https://image.lvbibir.cn/blog/image-20220819162743610.png)

至此，已修改完毕，将容器提交为新的镜像

```
docker commit -m "修改 /usr/share/ceph/mgr/cephadm/serve.py 文件" -a "lvbibir" test ceph:v16

[root@node-128 ~]# docker images
REPOSITORY                         TAG       IMAGE ID       CREATED         SIZE
ceph                               v16       c654e94b4c3f   3 days ago      1.23GB
quay.io/ceph/ceph                  v16       e8311b759ac3   3 months ago    1.23GB
quay.io/ceph/ceph-grafana          8.3.5     dad864ee21e9   4 months ago    558MB
quay.io/prometheus/prometheus      v2.33.4   514e6a882f6e   5 months ago    204MB
quay.io/prometheus/node-exporter   v1.3.1    1dbe0e931976   8 months ago    20.9MB
quay.io/prometheus/alertmanager    v0.23.0   ba2b418f427c   11 months ago   57.5MB
```

然后将原先的镜像删除，将修改后的镜像改为原先的镜像 tag

```
docker rmi quay.io/ceph/ceph:v16
docker tag ceph:v16 quay.io/ceph/ceph:v16
docker rmi ceph:v16

[root@ceph-x86-node3 ~]# docker images
REPOSITORY                         TAG       IMAGE ID       CREATED         SIZE
quay.io/ceph/ceph                  v16       c654e94b4c3f   4 days ago      1.23GB
quay.io/ceph/ceph-grafana          8.3.5     dad864ee21e9   4 months ago    558MB
quay.io/prometheus/prometheus      v2.33.4   514e6a882f6e   5 months ago    204MB
quay.io/prometheus/node-exporter   v1.3.1    1dbe0e931976   8 months ago    20.9MB
quay.io/prometheus/alertmanager    v0.23.0   ba2b418f427c   11 months ago   57.5MB
```

在 [本博客另一篇文章](https://www.lvbibir.cn/posts/tech/docker-import-export-image/) 有脚本可以方便的批量导入导出镜像

# 三、测试

将之前下载的 rpm 包和导出的 docker 镜像进行归档压缩，上传至无法访问外网的环境，之后就与在线部署 ceph 集群的步骤一样了











