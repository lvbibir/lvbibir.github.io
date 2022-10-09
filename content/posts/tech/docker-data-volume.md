---
title: "docker | 数据卷（data volume）" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- docker
keywords:
- linux
- docker
- docker volume
description: "介绍如何使用docker的数据卷和数据卷容器" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

# 什么是数据卷
docker的理念之一就是将应用与其运行的环境打包。通常docker容器的生命周期都是与在容器中运行的程序相一致的，我们对于数据的要求就是持久化；另一方面docker容器之间也需要一个共享文件的渠道。

 - 数据卷是经过特殊设计的目录，可以绕过联合文件系统（UFS），为一个或者过个容器提供服务
 - 数据卷设计的目的，在于数据的持久化，他完全独立于容器的生存周期，因此，docker不会在容器删除时删除其挂载的数据卷，也不会存在类似的垃圾收集机制，对容器引用的数据卷进行处理

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190814222305662.png)
从图片中：
1. 数据卷独立于docker容器存在，它存在于docker的宿主机中
2. 数据卷可以是目录，也可以是文件
3. docker容器可以利用数据卷与宿主机共享文件
4. 同一个数据卷可以支持多个容器的访问

# 数据卷的特点

 1. 数据卷在容器启动时初始化，如果容器使用的镜像在挂载点包含了数据，这些数据会拷贝到新初始化的数据卷中
 2. 数据卷可以在容器之间共享和重用
 3. 可以对数据卷里的内容直接进行修改
 4. 数据卷的变化不会影响镜像的更新
 5. 数据卷会一直存在，即使挂载数据卷的容器已经被删除

# 数据卷操作
## 为容器添加数据卷

    docker run -it -v HOST_DIRECTORY:CONTAINER_DIRETORY  IMAGE [COMMADN]

 - HOST-DIRECTORY：指定主机目录，不存在时即创建
 - CONTAINER：指定容器目录，不存在时即创建

示例：

```
[root@localhost ~]# docker run -it -v /docker/data_volume:/data_volume busybox /bin/sh
/ # touch /data_volume/test		#创建测试文件
/ # echo "lvbibir" > /data_volume/test
/ # cat /data_volume/test
lvbibir
[root@localhost ~]# cat /docker/data_volume/test		#验证测试文件
lvbibir
[root@localhost ~]# docker ps -l
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
be3fad8d789e        busybox             "/bin/sh"           6 minutes ago       Up 6 minutes                            elastic_boyd
[root@localhost ~]# docker inspect elastic_boyd
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190814225150794.png)
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190814225229862.png)

## 为数据卷添加访问权限

    docker run -it -v HOST_DIRECTORY:CONTAINER_DIRETORY:r/w  IMAGE [COMMADN]

 权限可以设置为：


 - ro：only-read，只读
 - wo：only-write，只写
 - rw：write and read，读写

 示例：

```
[root@localhost ~]# docker run -itd -v /docker/data_volume:/data_volume:ro busybox /bin/sh
3ee3a2b7a97c0a10125d46ee1135bf59af1d97932572d49fdd5c0bb64bf775a5
[root@localhost ~]# docker ps -l
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
3ee3a2b7a97c        busybox             "/bin/sh"           4 seconds ago       Up 3 seconds                            confident_hopper
[root@localhost ~]# docker inspect confident_hopper
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190814230039492.png)
## 使用dockerfile构建包含数据卷的镜像
dockerfile指令：
VOLUME ["HOST_DIRECTORY"]

 - dockerfile中配置数据卷无法指定映射到本地的目录
 - 构建好镜像启动容器时，数据卷会进行初始化，docker会在/var/lib/docker/volumes/下为数据卷创建新的随机名字的目录（不同版本该目录位置可能不同，具体以inspect查看到的为准）
 - 使用同一个镜像构建的多个容器，映射的本地目录也不一样
 - 通过数据卷容器来进行容器间的数据共享

示例：

```
[root@localhost ~]# cat Dockerfile
#For test data_volume
FROM busybox:latest
VOLUME ["/data_volume1","/data_volume2"]
CMD /bin/sh
[root@localhost ~]# docker build -t test/data_volume .
[root@localhost ~]#  docker run -itd --name test_data_volume_1 test/data_volume /bin/sh
ee8347a4bd3590e8cb65a28e1ebfc5d01e44f2ce70d33a2fa9bbc19782e34f21
[root@localhost ~]# docker exec test_data_volume_1 ls -l / | grep data_volume
drwxr-xr-x    2 root     root             6 Aug 14 15:20 data_volume1
drwxr-xr-x    2 root     root             6 Aug 14 15:20 data_volume2
[root@localhost ~]# docker inspect test_data_volume_1
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/2019081423235318.png)

```
[root@localhost ~]# docker run -itd --name test_data_volume_2 test/data_volume /bin/sh
b4f654706ea15e657cd61bb92d16fa6c6b8eb9129a68b1c9209ea21967175b24
[root@localhost ~]# docker exec test_data_volume_2 ls -l / | grep data_volume
drwxr-xr-x    2 root     root             6 Aug 14 15:24 data_volume1
drwxr-xr-x    2 root     root             6 Aug 14 15:24 data_volume2
[root@localhost ~]# docker inspect test_data_volume_2
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190814232550103.png)
# 数据卷容器

 - 一个命名的容器挂载了数据卷，其他容器通过挂载这个容器实现数据共享，挂载数据卷的容器，就叫做数据卷容器 
 - 使用数据卷容器而不是用数据卷直接挂载，可以不暴露宿主机的实际目录
 - 删除数据卷容器对于已经挂载了该容器的容器没有影响，因为数据卷容器只是传递了挂载信息，任何对于目录的更改都不需要通过数据卷容器

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190814233143592.png)
从图片中：

 - 数据卷容器挂载了一个本地目录，其他容器通过连接这个数据卷容器来实现数据的共享


## 数据卷容器操作
### 挂载数据卷容器

```
docker run -it --volumes-from [CONTAINER] IMAGE [COMMAND]
```

 - CONTAINER必须是已经挂载了卷组的容器，dockerfile和-v两个方式都可以
 - CONTAINER可以未运行，但必须存在

示例：
创建数据卷容器
```
[root@localhost ~]# cat Dockerfile
#For test data_volume
FROM busybox:latest
VOLUME ["/data_volume1","/data_volume2"]
CMD /bin/sh
[root@localhost ~]# docker build -t test/data_volume .
[root@localhost ~]# docker run -it --name  data_volume_container  test/data_volume /bin/sh
/ # touch /data_volume1/test1
/ # touch /data_volume2/test2
/ # exit
```
创建一个容器，挂载数据卷容器进行验证

```
[root@localhost ~]# docker run -itd --name test_dvc_1 --volumes-from data_volume_container busybox /bin/sh
6c4afa29df7ef226da7f1f0d394a356d53b92e3b20fa6c4632e7197ba393612c
[root@localhost ~]# docker exec test_dvc_1 ls /data_volume1/
test1
[root@localhost ~]# docker exec test_dvc_1 ls /data_volume2/
test2
```
使用这个新容器对挂载的目录进行更改

```
[root@localhost ~]# docker exec test_dvc touch /data_volume1/test2
[root@localhost ~]# docker exec test_dvc ls /data_volume1/
test1
test2
```
再创建一个新容器验证上一个容器对挂载目录的更改是否生效

```
[root@localhost ~]# docker run -itd --name test_dvc_2 --volumes-from data_volume_container busybox /bin/sh
276c24ecd6ee62f35abf24855ffc5416b9abe987c1bb693ec57bf27d241383d2
[root@localhost ~]# docker exec test_dvc_2 ls /data_volume1
test1
test2
```

```
[root@localhost ~]# docker inspect --format="{{.Mounts}}"  test_dvc_1
[{volume 1aca4270e7c9ba34b3978638a6bf9e8259c294508207e89b3b9cbb529f4dd4be /var/lib/docker/volumes/1aca4270e7c9ba34b3978638a6bf9e8259c294508207e89b3b9cbb529f4dd4be/_data /data_volume1 local  true } {volume d6ebda8735e2c76857d199bd1b96d11c9802d39557d2028bac60f0ec42efc764 /var/lib/docker/volumes/d6ebda8735e2c76857d199bd1b96d11c9802d39557d2028bac60f0ec42efc764/_data /data_volume2 local  true }]
[root@localhost ~]# docker inspect --format="{{.Mounts}}"  test_dvc_2
[{volume d6ebda8735e2c76857d199bd1b96d11c9802d39557d2028bac60f0ec42efc764 /var/lib/docker/volumes/d6ebda8735e2c76857d199bd1b96d11c9802d39557d2028bac60f0ec42efc764/_data /data_volume2 local  true } {volume 1aca4270e7c9ba34b3978638a6bf9e8259c294508207e89b3b9cbb529f4dd4be /var/lib/docker/volumes/1aca4270e7c9ba34b3978638a6bf9e8259c294508207e89b3b9cbb529f4dd4be/_data /data_volume1 local  true }]
```

```
[root@localhost ~]# docker inspect test_dvc_1
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190814235937849.png)
```
[root@localhost ~]# docker inspect test_dvc_2
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190815000004723.png)

### 删除数据卷容器
删除数据卷容器后，已经挂载了这个数据卷容器的容器不受任何影响
数据卷容器只传递链接信息，挂载的数据并不需要通过数据卷容器来进行传输

# 数据卷的备份和还原
## 数据备份
备份这个数据卷容器挂载的所有目录
```
docker run --volumes-from [container] -v $(pwd):/backup [image] tar cvf /backup/backup.tar [container data volume]
```

 - -v $(pwd):/backup：挂载一个数据卷用于存放备份文件
 - tar命令：将数据卷容器挂载的目录进行压缩，备份到/backup目录

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190815123643835.png)
## 数据还原

```
docker run --volumes-from [container] -v $(pwd):/backup [image] tar xvf /backup/backup.tar [container data volume]
```