---
title: "docker | 简介以及基础概念" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- docker
keywords:
- linux
- docker
description: "介绍docker的一些基础概念和优势" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

# docker简介

Docker 是一个开源项目，诞生于 2013 年初，最初是 dotCloud 公司内部的一个业余项目。它基于 Google 公司推出的 Go 语言实现。 项目后来加入了 Linux 基金会，遵从了 Apache 2.0 协议，项目代码在GitHub (https://github.com/docker/docker) 上进行维护。 
Docker 自开源后受到广泛的关注和讨论，以至于 dotCloud 公司后来都改名为 Docker Inc。Redhat 已经在其RHEL6.5 中集中支持 Docker；Google 也在其 PaaS 产品中广泛应用。 
Docker 项目的目标是实现轻量级的操作系统虚拟化解决方案。 Docker 的基础是 Linux 容（LXC）等技术。 
在 LXC 的基础上 Docker 进行了进一步的封装，让用户不需要去关心容器的管理，使得操作更为简便。用户操作 Docker 的容器就像操作一个快速轻量级的虚拟机一样简单。 
下面的图片比较了 Docker 和传统虚拟化方式的不同之处，可见容器是在操作系统层面上实现虚拟化，直接复用本地主机的操作系统，而传统方式则是在硬件层面实现。

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190801171754742.png)
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190801171806881.png)

## 为什么要使用docker
作为一种新兴的虚拟化方式，Docker 跟传统的虚拟化方式相比具有众多的优势。
首先，Docker 容器的启动可以在秒级实现，这相比传统的虚拟机方式要快得多。 其次，Docker 对系统资源的
利用率很高，一台主机上可以同时运行数千个 Docker 容器。
容器除了运行其中应用外，基本不消耗额外的系统资源，使得应用的性能很高，同时系统的开销尽量小。传统虚
拟机方式运行 10 个不同的应用就要起 10 个虚拟机，而Docker 只需要启动 10 个隔离的应用即可。
具体说来，Docker 在如下几个方面具有较大的优势。

 1. 更快速的交付和部署
 对开发和运维（devop）人员来说，最希望的就是一次创建或配置，可以在任意地方正常运行。
    开发者可以使用一个标准的镜像来构建一套开发容器，开发完成之后，运维人员可以直接使用这个容器来部署代码。 Docker 可以快速创建容器，快速迭代应用程序，并让整个过程全程可见，使团队中的其他成员更容易理解应用程序是如何创建和工作的。 Docker 容器很轻很快！容器的启动时间是秒级的，大量地节约开发、测试、部署的时间。
2. 更高效的虚拟化
Docker 容器的运行不需要额外的 hypervisor 支持，它是内核级的虚拟化，因此可以实现更高的性能和效率。
3. 更轻松的迁移和扩展
Docker 容器几乎可以在任意的平台上运行，包括物理机、虚拟机、公有云、私有云、个人电脑、服务器等。 这种兼容性可以让用户把一个应用程序从一个平台直接迁移到另外一个。
4. 更简单的管理
使用 Docker，只需要小小的修改，就可以替代以往大量的更新工作。所有的修改都以增量的方式被分发和更新，从而实现自动化并且高效的管理。
## 对比传统虚拟机
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190801172821208.png)
## docker的应用场景
1. 简化配置
一次构建，多处运行
2. 提升开发效率
3. 应用隔离
4. 多租户环境
为每个容器启用多个不同的容器
5. 快速的部署
6. 代码流水线管理
7. 代码调试
# docker镜像

docker镜像是一套使用联合加载技术实现的层叠的只读文件系统，包含基础镜像和附加镜像层

## 为什么docker镜像很小

Linux操作系统分别由两部分组成
1.内核空间(kernel)
2.用户空间(rootfs)
内核空间是kernel,Linux刚启动时会加载bootfs文件系统，之后bootf会被卸载掉，
用户空间的文件系统是rootfs,包含常见的目录，如/dev、/proc、/bin、/etc等等
不同的Linux发行版本(红帽，centos，ubuntu等)主要的区别是rootfs, 多个Linux发行版本的kernel差别不大。
每个不同linux发行版的docker镜像只包含对应的rootfs，所以比完整的系统镜像要小得多
## docker镜像的存储位置
/var/lib/docker(可以使用docker info来进行查看)
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190805132020599.png)

# 写时复制（copy on write）

当一个新容器启动时，读写层是没有任何数据的，当用户需要读取一些文件时，可以直接从只读层进行读取，只有当用户要修改只读层一些文件时，docker才会将该文件从只读层复制出来放在读写层供使用者修改，只读层中的文件是没有改变的

# 仓库（repository）与仓库注册服务器（registry）

Repository：本身是一个仓库，这个仓库里面可以放具体的镜像，是指具体的某个镜像的仓库，比如Tomcat下面有很多个版本的镜像，它们共同组成了Tomcat的Repository。

Registry：镜像的仓库，比如官方的是Docker Hub，它是开源的，也可以自己部署一个，Registry上有很多的Repository，Redis、Tomcat、MySQL等等Repository组成了Registry。

# docker的C/S模式
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190807212649783.png)
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190807212705313.png)
用户在Docker Client中运行Docker的各种命令，这些命令会传送给在docker宿主机上运行的docker守护进程，docker的守护进程来实现docker的各种功能
启动docker服务后，docker的守护进程会一直在后台运行

## Remote API
docker命令行接口是docker最常用的与守护进程进行通信的接口，docker的二进制命令文件（例如docker run）此时就是docker的Client，docker也提供了其他的接口：Remote API
用户可以通过编写程序调用Remote API，与docker守护进程进行通信，将自己的程序与docker进行集成

 - RESTful风格的API：与大多数程序的API风格类似
 - STDIN、STDOUT、STDERR：Remote API在某些复杂的情况下，也支持这三种方式来与docker守护进程进行通信
![如图就是使用自定义程序调用RemoteAPI与docker守护进程通信的C/S模式](https://image.lvbibir.cn/blog/20190807214053413.png)
如图就是使用自定义程序调用Remote API与docker守护进程通信的C/S模式


## Client与守护进程的连接方式
unix:///var/run/docker.sock是默认的连接方式，可以通过配置修改为其他的socket连接方式
 1. unix:///var/run/docker.sock
 2. tcp://host:port
 3. fd://socketfd
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190807215138905.png)
用户可以通过dokcer的二进制命令接口或者自定义程序，自定义程序通过Remote API来调用docker守护进程，Client与Server之间通过Socket来进行连接，这种连接意味着Client与Server既可以在同一台机器上运行，也可以在不同机器上运行，Client可以通过远程的方式来连接Server