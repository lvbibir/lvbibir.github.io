---
title: "docker | 三剑客之machine" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- docker
keywords:
- linux
- docker
- docker machine
description: "docker machine简介以及实战" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

# Docker Machine简介

Docker Machine 是 Docker 官方编排（Orchestration）项目之一，负责在多种平台上快速安装 Docker环境。
Docker Machine支持在常规Linux操作系统、虚拟化平台、openstack、公有云等不同环境下安装配置dockerhost。
Docker Machine 项目基于 Go 语言实现，目前在 Github 上的维护地址：[https://github.com/docker/machine/](https://github.com/docker/machine/)
# Docker Machine实践

## 环境准备
- 三台centos7，两台新系统，一台装有docker
ip：
machine：192.168.1.101
host1:192.168.1.127
host2:192.168.1.180
- 保证三台centos7可以连接到外网

## 下载并安装machine

    base=https://github.com/docker/machine/releases/download/v0.14.0 && curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine && sudo install /tmp/docker-machine /usr/local/bin/docker-machine	

下载并安装doker-machine，路径在/usr/local/bin下
## 创建machine
machine指的是docker daemon主机，其实就是在host上安装和部署docker。

- 创建流程：
1. 安装docker软件包
2. ssh免密登陆远程主机
3. 复制证书
4. 配置docker daemon
5. 启动docker

## 创建machine要求免密登录远程主机

```
ssh-keygen
ssh-copy-id  目标ip

[root@server5 ~]# ssh-keygen 
[root@server5 ~]# ssh-copy-id 192.168.1.127
[root@server5 ~]# ssh-copy-id 192.168.1.180
```
测试：

```
ssh 192.168.1.127
ssh 192.168.1.180
```
### 创建主机（离线安装需要在目标主机提前安装好docker软件包）

```
docker-machine create --driver generic --generic-ip-address=192.168.1.127 host1
```

# 参考

[docker三剑客之machine](https://blog.csdn.net/Anumbrella/article/details/80640517)

