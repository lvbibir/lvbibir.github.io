---
title: "docker | 三剑客之 swarm" 
date: 2019-08-01
lastmod: 2024-01-28
tags:
  - docker
keywords:
  - linux
  - docker
  - docker swarm
description: "介绍 docker swarm 集群的概述、使用和集群管理" 
cover:
    image: "images/docker.png" 
---

# 0 前言

本文参考以下链接:

- [Docker三剑客——Swarm](https://blog.csdn.net/anumbrella/article/details/80369913)
- [docker swarm 删除节点（解散集群）](https://blog.csdn.net/xiunai78/article/details/89471100)
- [截取已创建好的 swarm 集群的 token](https://blog.csdn.net/CSDN_duomaomao/article/details/73393541)

# 1 部署

## 1.1 环境准备

1. 准备 3 台 Ubuntu 系统主机 (即用于搭建集群的 3 个 Docker 机器)，每台机器上都需要安装 Docker 并且可以连接网络，同时要求 Docker 版本必须是 1.12 及以上，因为老版本不支持 Docker Swarm
2. 集群管理节点 Docker 机器的 IP 地址必须固定，集群中所有节点都能够访问该管理节点。
3. 集群节点之间必须使用相应的协议并保证其以下端口可用：
    - 用于集群管理通信的 TCP 端口 2377；
    - TCP 和 UDP 端口 7946，用于节点间的通信；
    - UDP 端口 4789，用于覆盖网络流量

为了进行本实例演示，此处按照要求安装了 3 台使用 centos7.4 系统的机器，这三台机器的主机名称分别为 manager1(作为管理节点)，worker1(作为工作节点)，worker2(作为工作节点),其 IP 地址分别如下：

| 主机名   | IP 地址        |
| -------- | ------------- |
| manager  | 192.168.0.101 |
| worker-1 | 192.168.0.102 |
| worker-2 | 192.168.0.103 |

## 1.2 创建集群

在 manager 上创建 swarm 集群

```bash
[root@node-1 ~]# docker swarm init --advertise-addr 192.168.0.101
```

使用 docker node ls 查看集群节点信息

```bash
[root@manager ~]# docker node ls
```

![在这里插入图片描述](/images/20190821213137271.png)

## 1.3 添加工作节点

在 worker1 和 worker2 中执行，加入 swarm 集群

```bash
docker swarm join --token SWMTKN-1-2zhqxsklcroivbpjzzntn5snsim79o5z7xzj4hzexk9phsz68q-d0seaxjgxpjebk8fdqt6d6yz5 192.168.0.101:2377
```

![在这里插入图片描述](/images/20190821214343274.png)

![在这里插入图片描述](/images/20190821214404237.png)

在管理节点上，使用 docker node ls 查看集群节点信息

```bash
[root@manager ~]# docker node ls
```

![在这里插入图片描述](/images/20190821214938383.png)

## 1.4 部署服务

在向 docker swarm 集群中部署服务时，既可以使用 docker hub 上自带的镜像来启动服务，也可以自己通过 dockerfile 的镜像来启动服务，如果使用自己的 dockerfile 构建的镜像来启动服务，那么必须先将镜像推送到 docker hub 中心仓库

这里，我们使用 docker hub 上自带的 alpine 镜像为例来部署集群服务

```bash
[root@manager ~]# docker service create --replicas 1 --name helloworld alpine ping docker.com
```

![在这里插入图片描述](/images/20190821215535816.png)

## 1.5 查看服务

当服务部署完成后，在管理节点上可以通过 docker service ls 查看当前集群中的服务列表信息

```bash
[root@manager ~]# docker service ls
```

![在这里插入图片描述](/images/20190821215734721.png)

使用 docker service inspect 查看部署的服务具体详情

```bash
[root@manager ~]# docker service inspect helloworl
```

使用 docker service ps 查看指定服务在集群节点上的分配和运行情况

```bash
[root@manager ~]# docker service ps helloworld
```

![在这里插入图片描述](/images/2019082122023695.png)

## 1.6 更改副本数量

在集群中部署的服务，如果只运行一个副本，就无法体现出集群的优势，并且一旦该机器或副本崩溃，该服务将无法访问，所以通常一个服务会启动多个副本

```bash
[root@manager ~]# docker service scale helloworld=5
```

![在这里插入图片描述](/images/2019082122061749.png)

更改完成后，就可以谈过 docker service ps 查看这五个服务副本在 3 个节点上的具体分布和运行情况

```bash
[root@manager ~]# docker service ps helloworld
```

![在这里插入图片描述](/images/20190821220742171.png)

## 1.7 删除服务

对于不需要的服务，我们可以进行删除

```bash
[root@manager ~]# docker service rm helloworld
```

## 1.8 访问服务

在管理节点上，执行 docker network ls 查看网络列表

```bash
[root@manager ~]# docker network ls
```

![在这里插入图片描述](/images/20190821221031576.png)

在管理节点上，创建 overlay 网络

```bash
[root@manager ~]# docker network create -d overlay ov_net
```

在管理节点上，再次部署服务

```bash
[root@manager ~]# docker service  create --network ov_net --name my-web --publish 8080:80 --replicas 2 nginx
```

![在这里插入图片描述](/images/20190821222655390.png)

访问 nginx 服务

![在这里插入图片描述](/images/20190821223028930.png)

![在这里插入图片描述](/images/20190821223039274.png)

![在这里插入图片描述](/images/20190821223050917.png)

以上
