---
title: "docker | 三剑客之 machine" 
date: 2019-08-01
lastmod: 2024-01-27
tags:
  - docker
keywords:
  - linux
  - docker
  - docker machine
description: "docker machine 简介以及实战" 
cover:
    image: "images/logo-docker.png" 
---

# 0 前言

本文参考以下链接:

- [docker 三剑客之 machine](https://blog.csdn.net/Anumbrella/article/details/80640517)

# 1 Docker Machine 简介

Docker Machine 是 Docker 官方编排（Orchestration）项目之一，负责在多种平台上快速安装 Docker 环境。

Docker Machine 支持在常规 Linux 操作系统、虚拟化平台、openstack、公有云等不同环境下安装配置 dockerhost。

Docker Machine 项目基于 Go 语言实现，目前在 Github 上的 [维护地址](https://github.com/docker/machine/)

# 2 Docker Machine 实践

## 2.1 环境准备

- 三台 centos7，两台新系统，一台装有 docker
    - machine：192.168.1.101
    - host1:192.168.1.127
    - host2:192.168.1.180
- 保证三台 centos7 可以连接到外网

## 2.2 安装 machine

```bash
base=https://github.com/docker/machine/releases/download/v0.14.0 && curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine && sudo install /tmp/docker-machine /usr/local/bin/docker-machine	
```

下载并安装 doker-machine，路径在 /usr/local/bin 下

## 2.3 创建 machine

machine 指的是 docker daemon 主机，其实就是在 host 上安装和部署 docker。

创建流程：

1. 安装 docker 软件包
2. ssh 免密登陆远程主机
3. 复制证书
4. 配置 docker daemon
5. 启动 docker

## 2.4 免密登录

```bash
ssh-keygen
ssh-copy-id  目标ip

[root@server5 ~]# ssh-keygen 
[root@server5 ~]# ssh-copy-id 192.168.1.127
[root@server5 ~]# ssh-copy-id 192.168.1.180
```

测试：

```bash
ssh 192.168.1.127
ssh 192.168.1.180
```

### 2.4.1 创建主机

```bash
docker-machine create --driver generic --generic-ip-address=192.168.1.127 host1
```

以上
