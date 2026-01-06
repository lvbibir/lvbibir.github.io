---
title: "docker | 简介以及基础概念" 
date: 2019-08-01
lastmod: 2024-01-27
tags:
  - docker
keywords:
  - linux
  - docker
description: "介绍 docker 的一些基础概念和优势" 
cover:
    image: "images/cover-docker.png" 
---

# 1 docker 简介

Docker 是一个开源项目，诞生于 2013 年初，最初是 dotCloud 公司内部的一个业余项目。它基于 Google 公司推出的 Go 语言实现。 项目后来加入了 Linux 基金会，遵从了 Apache 2.0 协议，项目代码在 [GitHub](<https://github.com/docker/docker>) 上进行维护。

Docker 自开源后受到广泛的关注和讨论，以至于 dotCloud 公司后来都改名为 Docker Inc。Redhat 已经在其 RHEL6.5 中集中支持 Docker；Google 也在其 PaaS 产品中广泛应用。

Docker 项目的目标是实现轻量级的操作系统虚拟化解决方案。 Docker 的基础是 Linux 容（LXC）等技术。

在 LXC 的基础上 Docker 进行了进一步的封装，让用户不需要去关心容器的管理，使得操作更为简便。用户操作 Docker 的容器就像操作一个快速轻量级的虚拟机一样简单。

下面的图片比较了 Docker 和传统虚拟化方式的不同之处，可见容器是在操作系统层面上实现虚拟化，直接复用本地主机的操作系统，而传统方式则是在硬件层面实现。

![在这里插入图片描述](/images/image-20190801-171754.png)

![在这里插入图片描述](/images/image-20190801-171806.png)

## 1.1 为什么要使用 docker

作为一种新兴的虚拟化方式，Docker 跟传统的虚拟化方式相比具有众多的优势。

首先，Docker 容器的启动可以在秒级实现，这相比传统的虚拟机方式要快得多。 其次，Docker 对系统资源的利用率很高，一台主机上可以同时运行数千个 Docker 容器。

容器除了运行其中应用外，基本不消耗额外的系统资源，使得应用的性能很高，同时系统的开销尽量小。传统虚拟机方式运行 10 个不同的应用就要起 10 个虚拟机，而 Docker 只需要启动 10 个隔离的应用即可。

具体说来，Docker 在如下几个方面具有较大的优势。

 1. 更快速的交付和部署
    - 对开发和运维（devop）人员来说，最希望的就是一次创建或配置，可以在任意地方正常运行。
    - 开发者可以使用一个标准的镜像来构建一套开发容器，开发完成之后，运维人员可以直接使用这个容器来部署代码。 Docker 可以快速创建容器，快速迭代应用程序，并让整个过程全程可见，使团队中的其他成员更容易理解应用程序是如何创建和工作的。 Docker 容器很轻很快！容器的启动时间是秒级的，大量地节约开发、测试、部署的时间。
2. 更高效的虚拟化
    - Docker 容器的运行不需要额外的 hypervisor 支持，它是内核级的虚拟化，因此可以实现更高的性能和效率。
3. 更轻松的迁移和扩展
    - Docker 容器几乎可以在任意的平台上运行，包括物理机、虚拟机、公有云、私有云、个人电脑、服务器等。 这种兼容性可以让用户把一个应用程序从一个平台直接迁移到另外一个。
4. 更简单的管理
    - 使用 Docker，只需要小小的修改，就可以替代以往大量的更新工作。所有的修改都以增量的方式被分发和更新，从而实现自动化并且高效的管理。

## 1.2 对比传统虚拟机

![miaoshu](/images/image-20190801-172821.png)

## 1.3 应用场景

1. 简化配置: 一次构建，多处运行
2. 提升开发效率
3. 应用隔离
4. 多租户环境: 为每个容器启用多个不同的容器
5. 快速的部署
6. 代码流水线管理
7. 代码调试

# 2 docker 镜像

docker 镜像是一套使用联合加载技术实现的层叠的只读文件系统，包含基础镜像和附加镜像层

## 2.1 为什么 docker 镜像很小

Linux 操作系统分别由两部分组成

1. 内核空间 (kernel)
2. 用户空间 (rootfs)

内核空间是 kernel,Linux 刚启动时会加载 bootfs 文件系统，之后 bootf 会被卸载掉，用户空间的文件系统是 rootfs,包含常见的目录，如/dev、/proc、/bin、/etc 等等

不同的 Linux 发行版本 (红帽，centos，ubuntu 等) 主要的区别是 rootfs, 多个 Linux 发行版本的 kernel 差别不大。

每个不同 linux 发行版的 docker 镜像只包含对应的 rootfs，所以比完整的系统镜像要小得多

## 2.2 docker 镜像的存储位置

/var/lib/docker(可以使用 docker info 来进行查看)

![在这里插入图片描述](/images/image-20190805-132020.png)

# 3 写时复制（copy on write）

当一个新容器启动时，读写层是没有任何数据的，当用户需要读取一些文件时，可以直接从只读层进行读取，只有当用户要修改只读层一些文件时，docker 才会将该文件从只读层复制出来放在读写层供使用者修改，只读层中的文件是没有改变的

# 4 repository 与 registry

Repository：本身是一个仓库，这个仓库里面可以放具体的镜像，是指具体的某个镜像的仓库，比如 Tomcat 下面有很多个版本的镜像，它们共同组成了 Tomcat 的 Repository。

Registry：镜像的仓库，比如官方的是 Docker Hub，它是开源的，也可以自己部署一个，Registry 上有很多的 Repository，Redis、Tomcat、MySQL 等等 Repository 组成了 Registry。

# 5 docker 的 C/S 模式

![在这里插入图片描述](/images/image-20190807-212649.png)

![在这里插入图片描述](/images/image-20190807-212705.png)

用户在 Docker Client 中运行 Docker 的各种命令，这些命令会传送给在 docker 宿主机上运行的 docker 守护进程，docker 的守护进程来实现 docker 的各种功能

启动 docker 服务后，docker 的守护进程会一直在后台运行

## 5.1 Remote API

docker 命令行接口是 docker 最常用的与守护进程进行通信的接口，docker 的二进制命令文件（例如 docker run）此时就是 docker 的 Client，docker 也提供了其他的接口：Remote API

用户可以通过编写程序调用 Remote API，与 docker 守护进程进行通信，将自己的程序与 docker 进行集成

 - RESTful 风格的 API：与大多数程序的 API 风格类似
 - STDIN、STDOUT、STDERR：Remote API 在某些复杂的情况下，也支持这三种方式来与 docker 守护进程进行通信
    ![如图就是使用自定义程序调用RemoteAPI与docker守护进程通信的C/S模式](/images/image-20190807-214053.png)

## 5.2 Client 与守护进程的连接方式

`unix:///var/run/docker.sock` 是默认的连接方式，可以通过配置修改为其他的 socket 连接方式

 1. unix:///var/run/docker.sock
 2. tcp://host:port
 3. fd://socketfd
    ![jianjie](/images/image-20190807-215138.png)
    用户可以通过 dokcer 的二进制命令接口或者自定义程序，自定义程序通过 Remote API 来调用 docker 守护进程，Client 与 Server 之间通过 Socket 来进行连接，这种连接意味着 Client 与 Server 既可以在同一台机器上运行，也可以在不同机器上运行，Client 可以通过远程的方式来连接 Server

以上