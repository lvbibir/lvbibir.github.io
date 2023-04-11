---
title: "docker | dockerfile最佳实践" 
date: 2023-04-11
lastmod: 2023-04-11
tags: 
- docker
keywords:
- docker
- dockerfile
- tini
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

## 前言

在使用 Docker 的过程中，编写 Dockerfile 是非常重要的一部分工作。合理编写 Dockerfile 会使我们构建出来的 Docker image 拥有更佳的性能和健壮性

目标:

- 更快的构建速度
- 更小的 Docker 镜像大小
- 更少的 Docker 镜像层
- 充分利用镜像缓存
- 增加 Dockerfile 可读性
- 让 Docker 容器使用起来更简单

总结

- 编写.dockerignore 文件
- 容器只运行单个应用
- 将多个 RUN 指令合并为一个
- 基础镜像的标签不要用 latest
- 每个 RUN 指令后删除多余文件
- 选择合适的基础镜像(alpine 版本最好)
- 设置 WORKDIR 和 CMD
- 使用 ENTRYPOINT (可选)
- 在 entrypoint 脚本中使用 exec
- COPY 与 ADD 优先使用前者
- 合理调整 COPY 与 RUN 的顺序
- 设置默认的环境变量，映射端口和数据卷
- 使用 LABEL 设置镜像元数据
- 添加 HEALTHCHECK

可以说每条 Dockerfile 指令都有相关的优化项，这里就不一一赘述了，下面仅列举一些常见且重要的设置

参考内容：

- https://blog.fundebug.com/2017/05/15/write-excellent-dockerfile/

## CMD和ENTRYPOINT

我们大概可以总结出下面几条规律：

- 如果 ENTRYPOINT 使用了 shell 模式，CMD 指令会被忽略。
- 如果 ENTRYPOINT 使用了 exec 模式，CMD 指定的内容被追加为 ENTRYPOINT 指定命令的参数。
- 如果 ENTRYPOINT 使用了 exec 模式，CMD 也应该使用 exec 模式。

真实的情况要远比这三条规律复杂，好在 docker 给出了[官方的解释](https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact)，如下图所示：

![image-20230410160304323](https://image.lvbibir.cn/blog/image-20230410160304323.png)

## 容器的优雅退出

众所周知，docker容器本质上是一个个进程，进程的优雅退出需要考虑的是如何正确处理 `SIGTERM` 信号，关于这点在我的另一篇博文中介绍过 [kill命令详解以及linux中的信号](https://www.lvbibir.cn/posts/tech/linux-command-kill)

无论是 `docker stop` 还是在 `kubernetes` 中使用容器，一般关闭容器都是向容器内的 1 号进程发送 `SIGTERM` 信号，等待容器自行进行资源清理等操作，等待时间 docker 默认 10s，k8s 默认 30s，如果容器仍未退出，则发送 `SIGKILL` 信号强制杀死进程

综上，我们只需要考虑 2 点

1. 应用程序如何处理信号

   这就需要在应用程序中定义对信号的处理逻辑了，包括对每个信号如何处理如何转发给子进程等。

2. 应用程序如何获取信号

docker 容器的一号进程是由 `CMD` `ENTRYPOINT` 这两个指令决定的，所以正确使用这两个指令十分关键

`CMD` 和 `ENTRYPOINT` 分别都有 `exec` 和 `shell` 两种格式：

- 使用 `exec` 格式时，我们执行的命令就是一号进程
- 使用 `shell` 格式时，实际会以 `/bin/sh -c command arg...` 的方式运行，这种情况下容器的一号进程将会是 `/bin/sh`，当收到信号时 `/bin/sh` 不会将信号转发给我们的应用程序，导致意料之外的错误，所以十分不推荐使用 `shell` 格式

我们还可以使用 tini 作为 init 系统管理进程


> 官方地址：https://github.com/krallin/tini
>
> Tini (Tiny but Independent) 是一个小型的、可执行的程序，它的主要目的是作为一个 init 系统的替代品，用于在容器中启动应用程序。
>
> 在容器中启动应用程序时，通常会使用 init 系统来管理进程。然而，由于容器的特殊性，传统的 init 系统可能无法完全满足容器化应用程序的需求。Tini 作为一个小巧而独立的程序，可以帮助解决容器启动时可能遇到的各种问题，如僵尸进程、信号处理等。
>
> 在 Docker 中使用 Tini 的主要意义在于提高容器的稳定性和可靠性。Tini 可以确保容器中的应用程序在启动和退出时正确处理信号，避免僵尸进程和其它常见问题的出现。此外，Tini 还可以有效地限制容器中的资源使用，避免应用程序崩溃或者占用过多的系统资源，从而提高容器的可用性和可维护性。
>
> 总之，使用 Tini 可以让容器中的应用程序更加健壮、稳定和可靠，这对于运行生产环境中的应用程序非常重要。

使用示例

```dockerfile
FROM nginx
ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini  /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

Alpine Linux

```dockerfile
RUN apk add --no-cache tini
# Tini is now available at /sbin/tini
ENTRYPOINT ["/sbin/tini", "--"]
```

NixOS

```dockerfile
nix-env --install tini
```

Debian

```dockerfile
apt-get install tini
```

Arch Linux

```dockerfile
pacaur -S tini
```

## RUN指令

`RUN` 指令一般用于安装配置软件包等操作，通常需要比较多的步骤，如果每条命令都单独用 `RUN` 指令去跑会导致镜像层数非常多，所以尽可能将所有 `RUN` 指令拼接起来是当前的事实标准

也要将 `RUN` 指令中生产的一些附属文件删除以缩小最终镜像的大小

如下示例

```dockerfile
FROM debian:stretch

RUN set -x; buildDeps='gcc libc6-dev make wget' \
    && apt-get update \
    && apt-get install -y $buildDeps \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz" \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && rm -rf /var/lib/apt/lists/* \
    && rm redis.tar.gz \
    && rm -r /usr/src/redis \
    && apt-get purge -y --auto-remove $buildDeps
```

## 多阶段构建

很多时候我们的应用容器会包含 `构建` 和 `运行` 两大功能，而运行所需要的依赖数量明显少于构建时的依赖，我们最终的 image 交付物有运行环境就足够了

在很多的场景中，我们都会制作两个 Dockerfile 分别用于构建和运行，文件交付起来十分麻烦

在 `Docker Engine 17.05` 中引入了多阶段构建，以此降低构建复杂度，同时使缩小镜像尺寸更为简单

如下示例，go 程序编译完后几乎不需要任何依赖环境即可运行

```dockerfile
# 阶段1
FROM golang:1.16
WORKDIR /go/src
COPY app.go ./
RUN go build app.go -o myapp

# 阶段2，引用空镜像 scratch 
FROM scratch
WORKDIR /server
# 复制文件，通过编号引用，0 代表阶段 1
COPY --from=0 /go/src/myapp ./ 
CMD ["./myapp"]
```

上述例子可以修改一下，可读性更强

```dockerfile
# 阶段1命名为builder
FROM golang:1.16 as builder
WORKDIR /go/src
COPY app.go ./
RUN go build app.go -o myapp

# 阶段2，引用空镜像 scratch 
FROM scratch
WORKDIR /server
# 复制文件，通过名称引用
COPY --from=builder /go/src/myapp ./ 
CMD ["./myapp"]
```

只构建某个阶段

构建镜像时，不一定需要构建整个 Dockerfile，我们可以通过`--target`参数指定某个目标阶段构建，比如我们开发阶段我们只构建builder阶段进行测试。

```bash
docker build --target builder -t builder_app:v1 .
```

使用外部镜像

```docker
COPY --from  httpd:latest /usr/local/apache2/conf/httpd.conf ./httpd.conf
```

从上一阶段创建新的阶段

```dockerfile
# 阶段1命名为builder
FROM golang:1.16 as builder
WORKDIR /go/src
COPY app.go ./
RUN go build app.go -o myapp

# 阶段2，引用阶段1再进行一次构建
FROM builder as builder_ex
ADD dest.tar ./
...
```

