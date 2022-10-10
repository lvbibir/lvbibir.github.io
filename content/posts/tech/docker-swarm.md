---
title: "docker | 三剑客之swarm" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- docker
keywords:
- linux
- docker
- docker swarm
description: "介绍docker-swarm集群的概述、使用和集群管理" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---



# docker swarm 概述

[https://blog.csdn.net/anumbrella/article/details/80369913](https://blog.csdn.net/anumbrella/article/details/80369913)
# docker swarm 使用
## 环境搭建
1. 准备3台Ubuntu系统主机(即用于搭建集群的3个Docker机器)，每台机器上都需要安装Docker并且可以连接网络，同时要求Docker版本必须是1.12及以上，因为老版本不支持Docker Swarm
2. 集群管理节点Docker机器的IP地址必须固定，集群中所有节点都能够访问该管理节点。
3. 集群节点之间必须使用相应的协议并保证其以下端口可用：
   		1. 用于集群管理通信的TCP端口2377；
		2. TCP 和UDP 端口7946，用于节点间的通信；
		3. UDP 端口 4789，用于覆盖网络流量

为了进行本实例演示，此处按照要求安装了3台使用centos7.4系统的机器，这三台机器的主机名称分别为manager1(作为管理节点)，worker1(作为工作节点)，worker2(作为工作节点),其IP地址分别如下：
| 主机名   | IP地址        |
| -------- | ------------- |
| manager  | 192.168.0.101 |
| worker-1 | 192.168.0.102 |
| worker-2 | 192.168.0.103 |

## 创建 Docker Swarm集群
1. 在 manager 上创建 swarm 	集群

```
[root@node-1 ~]# docker swarm init --advertise-addr 192.168.0.101
```
2. 使用 docker node ls 查看集群节点信息

```
[root@manager ~]# docker node ls
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821213137271.png)
## 向 Docker Swarm集群添加工作节点
1. 在 worker1 和 worker2 中执行米慧玲，加入 swarm 集群

```
docker swarm join --token SWMTKN-1-2zhqxsklcroivbpjzzntn5snsim79o5z7xzj4hzexk9phsz68q-d0seaxjgxpjebk8fdqt6d6yz5 192.168.0.101:2377
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821214343274.png)

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821214404237.png)
2. 在管理节点上，使用 docker node ls 查看集群节点信息

```
[root@manager ~]# docker node ls
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821214938383.png)
## 向 Docker Swarm集群部署服务
在向 docker swarm 集群中部署服务时，既可以使用 docker hub 上自带的镜像来启动服务，也可以自己通过 dockerfile 的镜像来启动服务，如果使用自己的 dockerfile 构建的镜像来启动服务，那么必须先将镜像推送到 docker hub 中心仓库
这里，我们使用 docker hub 上自带的 alpine 镜像为例来部署集群服务

```
[root@manager ~]# docker service create --replicas 1 --name helloworld alpine ping docker.com
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821215535816.png)


## 查看Docker Swarm 集群中的服务

1. 当服务部署完成后，在管理节点上可以通过 docker service ls 查看当前集群中的服务列表信息

```
[root@manager ~]# docker service ls
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821215734721.png)

2. 使用 docker service inspect 查看部署的服务具体详情

```
[root@manager ~]# docker service inspect helloworl
```
3. 使用 docker service ps 查看指定服务在集群节点上的分配和运行情况

```
[root@manager ~]# docker service ps helloworld
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/2019082122023695.png)
## 更改 Docker Swarm 集群服务样本数量

在集群中部署的服务，如果只运行一个副本，就无法体现出集群的优势，并且一旦该机器或副本崩溃，该服务将无法访问，所以通常一个服务会启动多个副本

```
[root@manager ~]# docker service scale helloworld=5
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/2019082122061749.png)

3. 更改完成后，就可以谈过 docker service ps 查看这五个服务副本在3个节点上的具体分布和运行情况

```
[root@manager ~]# docker service ps helloworld
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821220742171.png)
## 删除服务
对于不需要的服务，我们可以进行删除

```
[root@manager ~]# docker service rm helloworld
```

## 访问服务
1. 在管理节点上，执行 docker network ls 查看网络列表

```
[root@manager ~]# docker network ls
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821221031576.png)

2. 在管理节点上，创建 overlay 网络

```
[root@manager ~]# docker network create -d overlay ov_net
```
3. 在管理节点上，再次部署服务

```
[root@manager ~]# docker service  create --network ov_net --name my-web --publish 8080:80 --replicas 2 nginx
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821222655390.png)

4. 访问 nginx 服务
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821223028930.png)
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821223039274.png)

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190821223050917.png)

# 参考

[docker swarm删除节点（解散集群）](https://blog.csdn.net/xiunai78/article/details/89471100)
[截取已创建好的 swarm 集群的 token](https://blog.csdn.net/CSDN_duomaomao/article/details/73393541)