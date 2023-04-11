---
title: "docker | dockerfile指令详解" 
date: 2023-04-09
lastmod: 2023-04-11
tags: 
- docker
keywords:
- docker
- dockerfile
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

## 前言

Dockerfile用于构建docker镜像, 实际上就是把在linux下的命令操作写到了Dockerfile中, 通过Dockerfile去执行设置好的操作命令, 保证通过Dockerfile的构建镜像是一致的.

Dockerfile 是一个文本文件，其内包含了一条条的指令(`Instruction`)，每一条指令构建一层，因此每一条指令的内容，就是描述该层应当如何构建。

参考内容：

- https://yeasy.gitbook.io/docker_practice/image/dockerfile

## FROM 指定基础镜像

命令格式

```dockerfile
FROM IMAGE[:TAG][@DIGEST]
```

我们可以用任意已存在的镜像为基础构建我们的自定义镜像

比如:

- 系统镜像: `centos`, `ubuntu`, `debian`, `alpine`

- 应用镜像: `nginx`, `redis`, `mongo`, `mysql`, `httpd`
- 运行环境镜像: `php`, `java`, `golang`
- 工具镜像: `busybox`

示例

```dockerfile
# tag 默认使用 latest 
FROM alpine

# 指定 tag
FROM alpine:3.17.3

# 指定 digest
FROM alpine@sha256:b6ca290b6b4cdcca5b3db3ffa338ee0285c11744b4a6abaa9627746ee3291d8d

# 同时指定 tag 和 digest
FROM alpine:3.17.3@sha256:b6ca290b6b4cdcca5b3db3ffa338ee0285c11744b4a6abaa9627746ee3291d8d
```

除了选择现有镜像为基础镜像外，Docker还存在一个特殊的镜像，名为 `scratch`。这个镜像无法从别处拉取, 可以理解为是Docker自 [1.5.0](https://github.com/moby/moby/pull/8827) 版本开始的自带镜像, 它仅包含一个空的文件系统.

scratch镜像一般用于构建基础镜像, 比如官方镜像`Ubuntu`

## COPY 复制文件

格式:

- `COPY [--chown=<user>:<group>] <源路径1> [源路径2] ... <目标路径>`
- `COPY [--chown=<user>:<group>] ["<源路径1>", "[源路径2]", ..., "<目标路径>"]`

`COPY` 指令将从构建上下文目录中 `<源路径>` 的文件/目录复制到新的镜像层内的 `<目标路径>` 位置.

`<源路径>` 可以是多个，甚至可以是通配符，其通配符规则要满足 Go 的 [filepath.Match](https://golang.org/pkg/path/filepath/#Match) 规则，如：

```dockerfile
COPY hom* /mydir/
COPY hom?.txt /mydir/
```

`<目标路径>` 可以是容器内的绝对路径，也可以是相对于工作目录的相对路径（工作目录可以用 `WORKDIR` 指令来指定）。目标路径不需要事先创建，如果目录不存在会在复制文件前先行创建缺失目录。

此外，还需要注意一点，使用 `COPY` 指令，源文件的各种元数据都会保留。比如读、写、执行权限、文件变更时间等。这个特性对于镜像定制很有用。特别是构建相关文件都在使用 Git 进行管理的时候。

在使用该指令的时候还可以加上 `--chown=<user>:<group>` 选项来改变文件的所属用户及所属组。

```dockerfile
COPY --chown=55:mygroup files* /mydir/
COPY --chown=bin files* /mydir/
COPY --chown=1 files* /mydir/
COPY --chown=10:11 files* /mydir/
```

## ADD 更高级的复制文件

`ADD` 指令和 `COPY` 的格式和性质基本一致。同样支持 `--chown=<user>:<group>` 指令修改属主和属组。

但是在 `COPY` 基础上增加了一些功能:

- `<源路径>` 可以是一个 `URL`，这种情况下，Docker 引擎会试图去下载这个链接的文件放到 `<目标路径>` 去。下载后的文件权限自动设置为 `600`，如果这并不是想要的权限，那么还需要增加额外的一层 `RUN` 进行权限调整.
- 如果 `<源路径>` 为一个 `tar` 压缩文件的话，压缩格式为 `gzip`, `bzip2` 以及 `xz` 的情况下，`ADD` 指令将会自动解压缩这个压缩文件到 `<目标路径>` 去。

在 Docker 官方的 [Dockerfile 最佳实践文档]() 中要求，尽可能的使用 `COPY`，因为 `COPY` 的语义很明确，就是复制文件而已，而 `ADD` 则包含了更复杂的功能，其行为也不一定很清晰。最适合使用 `ADD` 的场合，就是所提及的需要自动解压缩的场合。

另外需要注意的是，`ADD` 指令会令镜像构建缓存失效，从而可能会令镜像构建变得比较缓慢。

## RUN 执行命令

格式:

- shell格式:`RUN [command] <parameter1> <parameter2> ...`, 等价于在linux中执行`/bin/sh -c "command parameter1 parameter2 ..."`

  ```dockerfile
  RUN ls -l
  ```

- exec格式:`RUN ["command", "parameter1", "parameter2"...]`, 不会通过shell执行, 所以像`$HOME`这样的变量就无法获取.

  ```dockerfile
  RUN ["ls", "-l"]
  RUN ["/bin/sh", "-c", "ls -l"] # 可以获取环境变量
  ```

RUN指令用于指定构建镜像时执行的命令, Dockerfile允许多个RUN指令, 并且每个RUN指令都会创建一个镜像层.

RUN指令一般用于安装配置软件包等操作, 为避免镜像层数过多, 一般RUN指令使用shell格式且使用换行符来执行多个命令，且尽量将 `RUN` 指令产生的附属物删除以缩小镜像大小

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

## CMD 容器启动命令

`CMD` 指令的格式和 `RUN` 相似，也是两种格式：

- `shell` 格式：`CMD [command] <parameters>`
- `exec` 格式：`CMD ["command", "<parameter1>", "parameter2", ...]`
- 参数列表格式：`CMD ["参数1", "参数2"...]`。在指定了 `ENTRYPOINT` 指令后，用 `CMD` 指定具体的参数。

`CMD` 指令用于设置容器启动时 <font color="red">默认执行</font> 的指令，一般会设置为应用程序的启动脚本或者工具镜像的`bash`，设置了多条`CMD`指令时，只有最后一条 `CMD` 会被执行。

在运行时可以指定新的命令来替代镜像设置中的这个默认命令，比如，`ubuntu` 镜像默认的 `CMD` 是 `/bin/bash`，如果我们直接 `docker run -it ubuntu` 的话，会直接进入 `bash`。我们也可以在运行时指定运行别的命令，如 `docker run -it ubuntu cat /etc/os-release`。这就是用 `cat /etc/os-release` 命令替换了默认的 `/bin/bash` 命令了，会输出系统版本信息。

在指令格式上，一般推荐使用 `exec` 格式，这类格式在解析时会被解析为 JSON 数组，因此一定要使用双引号 `"`，而不要使用单引号。

例如一般`nginx`容器的`CMD`指令:

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

## ENTRYPOINT 入口点

`ENTRYPOINT` 的格式和 `RUN` 指令格式一样，分为 `exec` 格式和 `shell` 格式。

- `shell` 格式：`ENTRYPOINT [command] <parameters>`
- `exec` 格式：`ENTRYPOINT ["command", "<parameter1>", "<parameter2>", ...]`

`ENTRYPOINT` 的目的和 `CMD` 一样，都是在指定容器启动程序及参数。`ENTRYPOINT` 在运行时也可以替代，不过比 `CMD` 要略显繁琐，需要通过 `docker run` 的参数 `--entrypoint` 来指定。

当指定了 `ENTRYPOINT` 且使用的是 `exec` 格式时，`CMD` 的含义就发生了改变，不再是直接的运行其命令，而是将 `CMD` 的内容作为参数传给 `ENTRYPOINT` 指令，换句话说实际执行时，将变为：

```dockerfile
ENTRYPOINT ["command", "<parameter1>", "<parameter2>", "CMD"]
```

以下示例将展示 `CMD` 指令作为参数传给 `ENTRYPOINT` 的场景

场景一：我们自己构建了一个用于查看外网 ip 和归属地的镜像

```dockerfile
FROM alpine
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk --update add curl
CMD [ "-s" ]
ENTRYPOINT [ "curl", "http://myip.ipip.net" ]
```

构建

```bash
docker build -t busybox-curl .
```

以两种方式运行

```bash
# 容器中实际执行的指令为 curl http://myip.ipip.net -s
[root@lvbibir learn]# docker run -it --rm busybox-curl
当前 IP：101.201.150.47  来自于：中国 北京 北京  阿里云

# 容器中实际执行的指令为 curl http://myip.ipip.net -i
[root@lvbibir learn]# docker run -it --rm busybox-curl -i
HTTP/1.1 200 OK
Date: Mon, 10 Apr 2023 03:21:59 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 72
Connection: keep-alive
Node: ipip-myip5
X-Cache: BYPASS
X-Request-Id: e309720b9197e8b94cec18b409c69d1d
Server: WAF
Connection: close
Accept-Ranges: bytes

当前 IP：101.201.150.47  来自于：中国 北京 北京  阿里云
```

场景二：应用运行前的准备工作

启动容器就是启动主进程，但有些时候，启动主进程前，需要一些准备工作。

比如 `mysql` 类的数据库，可能需要一些数据库配置、初始化的工作，这些工作要在最终的 mysql 服务器运行之前解决。

此外，可能希望避免使用 `root` 用户去启动服务，从而提高安全性，而在启动服务前还需要以 `root` 身份执行一些必要的准备工作，最后切换到服务用户身份启动服务。或者除了服务外，其它命令依旧可以使用 `root` 身份执行，方便调试等。

这些准备工作是和容器 `CMD` 无关的，无论 `CMD` 为什么，都需要事先进行一个预处理的工作。这种情况下，可以写一个脚本，然后放入 `ENTRYPOINT` 中去执行，而这个脚本会将接到的参数（也就是 `<CMD>`）作为命令，在脚本最后执行。比如官方镜像 `redis` 中就是这么做的：

```dockerfile
FROM alpine:3.4
...
RUN addgroup -S redis && adduser -S -G redis redis
...
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 6379
CMD [ "redis-server" ]
```

可以看到其中为了 redis 服务创建了 redis 用户，并在最后指定了 `ENTRYPOINT` 为 `docker-entrypoint.sh` 脚本：

```bash
#!/bin/sh
...
# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	find . \! -user redis -exec chown redis '{}' +
	exec gosu redis "$0" "$@"
fi

exec "$@"
```

该脚本的内容就是根据 `CMD` 的内容来判断，如果是 `redis-server` 的话，则切换到 `redis` 用户身份启动服务器，否则依旧使用 `root` 身份执行。比如：

```bash
[root@lvbibir learn]# docker run -it redis id
uid=0(root) gid=0(root) groups=0(root)
```

## ENV 设置环境变量

格式有两种：

- `ENV <key> <value>`
- `ENV <key1>=<value1> <key2>=<value2>...`

`ENV` 用于设置环境变量，既可以在 Dockerfile 中调用，也可以在构建完的容器运行时中使用。

支持的指令： `ADD`、`COPY`、`ENV`、`EXPOSE`、`FROM`、`LABEL`、`USER`、`WORKDIR`、`VOLUME`、`STOPSIGNAL`、`ONBUILD`、`RUN`

下面这个例子中演示了如何换行，以及对含有空格的值用双引号括起来的办法，这和 Shell 下的行为是一致的。

```dockerfile
ENV VERSION=1.0 DEBUG=on \
    NAME="Happy Feet"
```

示例

```dockerfile
FROM alpine
ENV VERSION=1.0 \
    DEBUG=on \
    NAME="Happy Feet"
RUN echo "name: ${NAME}" > /test \
    && echo "version: ${VERSION}" >> /test
```

构建

```bash
[root@lvbibir learn]# docker build -t demo-env .
```

构建时调用了环境变量

```bash
[root@lvbibir learn]# docker run -it --rm demo-env cat /test
name: Happy Feet
version: 1.0
```

构建后的容器运行时中调用，这里需要使用 `/bin/sh -c` 的方式，不然无法读取变量。且对 `$` 进行转义，不然读取的将会是宿主机的变量

```bash
[root@lvbibir learn]# docker run -it --rm demo-env /bin/sh -c "echo \${DEBUG}"
on
```

## ARG 构建参数

构建参数和 `ENV` 的效果一样，都是设置环境变量。所不同的是，`ARG` 所设置的构建环境的环境变量，在将来容器运行时是不会存在这些环境变量的。但是不要因此就使用 `ARG` 保存密码之类的信息，因为 `docker history` 还是可以看到所有值的。

`Dockerfile` 中的 `ARG` 指令是定义参数名称，以及定义其默认值。该默认值可以在构建命令 `docker build` 中用 `--build-arg <参数名>=<值>` 来覆盖。

灵活的使用 `ARG` 指令，能够在不修改 Dockerfile 的情况下，构建出不同的镜像。

ARG 指令有生效范围，如果在 `FROM` 指令之前指定，那么只能用于 `FROM` 指令中，`FROM` 指令可以是多个

```dockerfile
ARG DOCKER_USERNAME=library
FROM ${DOCKER_USERNAME}/alpine
RUN set -x ; echo ${DOCKER_USERNAME}
```

使用上述 Dockerfile 会发现无法输出 `${DOCKER_USERNAME}` 变量的值，要想正常输出，你必须在 `FROM` 之后再次指定 `ARG`，如下示例

```dockerfile
# 只在 FROM 中生效
ARG DOCKER_USERNAME=library
FROM ${DOCKER_USERNAME}/alpine

# 要想在 FROM 之后使用，必须再次指定
ARG DOCKER_USERNAME=library
RUN set -x ; echo ${DOCKER_USERNAME}
```

如下示例，变量将会在每个 `FROM` 指令中生效

```dockerfile
# 这个变量在每个 FROM 中都生效
ARG DOCKER_USERNAME=library

FROM ${DOCKER_USERNAME}/alpine
RUN set -x ; echo 1

FROM ${DOCKER_USERNAME}/alpine
RUN set -x ; echo 2
```

如下示例，对于在各个阶段中使用的变量都必须在每个阶段分别指定

```dockerfile
ARG DOCKER_USERNAME=library
FROM ${DOCKER_USERNAME}/alpine

# 在FROM 之后使用变量，必须在每个阶段分别指定
ARG DOCKER_USERNAME=library
RUN set -x ; echo ${DOCKER_USERNAME}

FROM ${DOCKER_USERNAME}/alpine
# 在FROM 之后使用变量，必须在每个阶段分别指定
ARG DOCKER_USERNAME=library
RUN set -x ; echo ${DOCKER_USERNAME}
```

## VOLUME 定义匿名卷

格式为：

- `VOLUME ["<路径1>", "<路径2>"...]`
- `VOLUME <路径>`

容器运行时应该尽量保持容器存储层不发生写操作，对于数据库类需要保存动态数据的应用，其数据库文件应该保存于卷(volume)中。

为了防止运行时用户忘记将动态文件所保存目录挂载为卷，在 `Dockerfile` 中，我们可以事先指定某些目录挂载为匿名卷，这样在运行时如果用户不指定挂载，其应用也可以正常运行，不会向容器存储层写入大量数据，从而保证了容器存储层的无状态化。

`VOLUME` 创建的匿名卷会挂载到系统 `/var/lib/docker/volumes/<CONTAINER-ID>/<_VOLUME>` 目录下，且不会随着容器删除而删除，需要手动删除

如下示例

```dockerfile
FROM alpine
VOLUME /data
```

构建运行

```bash
[root@lvbibir learn]# docker build -t demo-volume .
[root@lvbibir learn]# docker run -itd --name=demo-volume demo-volume 
[root@lvbibir learn]# docker exec -it demo-volume ls -ld /data
drwxr-xr-x    2 root     root          4096 Apr 10 05:24 /data
```

查看挂载目录

```bash
[root@lvbibir learn]# docker inspect --format='{{json .Mounts}}' demo-volume | python -m json.tool
[
    {
        "Destination": "/data",
        "Driver": "local",
        "Mode": "",
        "Name": "49cf915dd297292e3d0e4b2c7a66ead6875cfb0dbd010de15189040ab1158b3b",
        "Propagation": "",
        "RW": true,
        "Source": "/var/lib/docker/volumes/49cf915dd297292e3d0e4b2c7a66ead6875cfb0dbd010de15189040ab1158b3b/_data",
        "Type": "volume"
    }
]
```

如下示例，运行容器时，可以指定 `-v` 参数将目录挂载到指定位置

```bash
[root@lvbibir learn]# docker run -itd -v /mydata:/data --name demo-volume-2 demo-volume
[root@lvbibir learn]# docker inspect --format='{{json .Mounts}}' demo-volume-2 | python -m json.tool
[
    {
        "Destination": "/data",
        "Mode": "",
        "Propagation": "rprivate",
        "RW": true,
        "Source": "/mydata",
        "Type": "bind"
    }
]
```

## EXPOSE 暴露端口

格式为 `EXPOSE <端口1> [端口2] ...`

`EXPOSE` 指令是声明容器运行时提供服务的端口，这只是一个声明，在容器运行时并不会因为这个声明应用就会开启这个端口的服务

在 Dockerfile 中写入这样的声明有两个好处：

- 一个是帮助镜像使用者理解这个镜像服务的守护端口，以方便配置映射；
- 另一个用处则是在运行时使用随机端口映射时，也就是 `docker run -P` 时，会自动随机映射 `EXPOSE` 的端口。

要将 `EXPOSE` 和在运行时使用 `-p <宿主端口>:<容器端口>` 区分开来。`-p`，是映射宿主端口和容器端口，换句话说，就是将容器的对应端口服务公开给外界访问，而 `EXPOSE` 仅仅是声明容器打算使用什么端口而已，并不会自动在宿主进行端口映射。

## WORKDIR 指定工作目录

格式为 `WORKDIR <路径>`

使用 `WORKDIR` 指令可以来指定工作目录（或者称为当前目录），以后各层的当前目录就被改为指定的目录，如该目录不存在，`WORKDIR` 会帮你建立目录

如下示例，是一个常见的错误，`world.txt` 最终会在 `/app` 目录下，而不是期望的 `/app/demo` 目录

```dockerfile
WORKDIR /app
RUN mkdir demo && cd demo
RUN echo "hello" > world.txt
```

上述需求可以进行如下优化，推荐使用第二种写法

```dockerfile
WORKDIR /app/demo
RUN echo "hello" > world.txt

# 或者
WORKDIR /app
RUN mkdir demo \
    && echo "hello" > demo/world.txt

# 或者
WORKDIR /app
RUN mkdir demo \
    && cd demo \
    && echo "hello" > demo/world.txt
```

如果你的 `WORKDIR` 指令使用的相对路径，那么所切换的路径与之前的 `WORKDIR` 有关

如下示例，`pwd` 的输出将会是 `/a/b/c`

```dockerfile
WORKDIR /a
WORKDIR b
WORKDIR c

RUN pwd
```

## USER 指定当前用户

格式：`USER <用户名>[:<用户组>]`

`USER` 指令和 `WORKDIR` 相似，都是改变环境状态并影响以后的层。`WORKDIR` 是改变工作目录，`USER` 则是改变之后层的执行 `RUN`, `CMD` 以及 `ENTRYPOINT` 这类命令的身份。

注意，`USER` 只是帮助你切换到指定用户而已，这个用户必须是事先建立好的，否则无法切换。

```dockerfile
RUN groupadd -r redis && useradd -r -g redis redis
USER redis
RUN [ "redis-server" ]
```

如果以 `root` 执行的脚本，在执行期间希望改变身份，比如希望以某个已经建立好的用户来运行某个服务进程，不要使用 `su` 或者 `sudo`，这些都需要比较麻烦的配置，而且在 TTY 缺失的环境下经常出错。建议使用 [gosu](https://github.com/tianon/gosu)

不过更推荐的还是 [上文](#entrypoint-入口点) 中提到过的通过 `ENTRYPOINT` 脚本的方式

使用 `gosu` 示例

```dockerfile
# 建立 redis 用户，并使用 gosu 换另一个用户执行命令
RUN groupadd -r redis && useradd -r -g redis redis
# 下载 gosu
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
# 设置 CMD，并以另外的用户执行
CMD [ "exec", "gosu", "redis", "redis-server" ]
```

## HEALTHCHECK 健康检查

格式：

- `HEALTHCHECK [选项] CMD <命令>`：设置检查容器健康状况的命令
- `HEALTHCHECK NONE`：如果基础镜像有健康检查指令，使用这行可以屏蔽掉其健康检查指令

`HEALTHCHECK` 指令是告诉 Docker 应该如何进行判断容器的状态是否正常，这是 Docker 1.12 引入的新指令。

在没有 `HEALTHCHECK` 指令前，Docker 引擎只可以通过容器内主进程是否退出来判断容器是否状态异常。很多情况下这没问题，但是如果程序进入死锁状态，或者死循环状态，应用进程并不退出，但是该容器已经无法提供服务了。在 1.12 以前，Docker 不会检测到容器的这种状态，从而不会重新调度，导致可能会有部分容器已经无法提供服务了却还在接受用户请求。

`HEALTHCHECK` 支持下列选项：

- `--interval=<间隔>`：两次健康检查的间隔，默认为 30 秒；
- `--timeout=<时长>`：健康检查命令运行超时时间，如果超过这个时间，本次健康检查就被视为失败，默认 30 秒；
- `--retries=<次数>`：当连续失败指定次数后，则将容器状态视为 `unhealthy`，默认 3 次。

和 `CMD`, `ENTRYPOINT` 一样，`HEALTHCHECK` 只可以出现一次，如果写了多个，只有最后一个生效。

在 `HEALTHCHECK [选项] CMD` 后面的命令，格式和 `ENTRYPOINT` 一样，分为 `shell` 格式，和 `exec` 格式。命令的返回值决定了该次健康检查的成功与否：

- `0`：成功；
- `1`：失败；
- `2`：保留，不要使用这个值。

如下示例，假设我们有个镜像是个最简单的 Web 服务，我们希望增加健康检查来判断其 Web 服务是否在正常工作，我们可以用 `curl` 来帮助判断

```dockerfile
FROM nginx
HEALTHCHECK --interval=5s --timeout=3s --retries=3\
  CMD curl -fs http://localhost/ || exit 1
```

构建运行

```bash
[root@lvbibir learn]# docker build -t myweb .
[root@lvbibir learn]# docker run -d --name demo-myweb -p 800:80 myweb

# 此时是 starting 状态
[root@lvbibir learn]# docker ps | grep myweb
e6f585df60a6   myweb  "/docker-entrypoint.…"   About a minute ago   Up 2 seconds (health: starting)   0.0.0.0:800->80/tcp  demo-myweb

# 等待几秒变为 healthy 状态
[root@lvbibir learn]# docker ps | grep myweb
e6f585df60a6 myweb "/docker-entrypoint.…"   2 minutes ago Up About a minute (healthy)  0.0.0.0:800->80/tcp  demo-myweb
```

删除 `index.html` 文件模拟故障

```bash
[root@lvbibir learn]# docker exec -it demo-myweb rm -f /usr/share/nginx/html/index.html

# 状态变为unhealthy
[root@lvbibir learn]# docker ps | grep myweb
e6f585df60a6  myweb  "/docker-entrypoint.…"   6 minutes ago   Up 5 minutes (unhealthy)  0.0.0.0:800->80/tcp   demo-myweb
```

为了帮助排障，健康检查命令的输出（包括 `stdout` 以及 `stderr`）都会被存储于健康状态里，可以用 `docker inspect` 来查看。

```bash
[root@lvbibir learn]# docker inspect --format '{{json .State.Health}}' demo-myweb | python -m json.tool
{
    "FailingStreak": 25,
    "Log": [
        {
            "End": "2023-04-10T14:41:51.393698555+08:00",
            "ExitCode": 1,
            "Output": "",
            "Start": "2023-04-10T14:41:51.285647058+08:00"
        },
        {
            "End": "2023-04-10T14:41:56.504282619+08:00",
            "ExitCode": 1,
            "Output": "",
            "Start": "2023-04-10T14:41:56.401745529+08:00"
        },
...........
    ],
    "Status": "unhealthy"
}
```

恢复文件 

```bash
[root@lvbibir learn]# docker exec -it demo-myweb /bin/bash
root@e6f585df60a6:/# echo test > /usr/share/nginx/html/index.html
root@e6f585df60a6:/#
exit

[root@lvbibir learn]# docker inspect --format '{{json .State.Health}}' demo-myweb | python -m json.tool
{
    "FailingStreak": 0,
    "Log": [
        {
            "End": "2023-04-10T14:48:30.482498808+08:00",
            "ExitCode": 0,
            "Output": "test\n",
            "Start": "2023-04-10T14:48:30.378197999+08:00"
        },
        {
            "End": "2023-04-10T14:48:35.599150547+08:00",
            "ExitCode": 0,
            "Output": "test\n",
            "Start": "2023-04-10T14:48:35.490433323+08:00"
        },
.......
    ],
    "Status": "healthy"
}
```

## ONBUILD 为他人作嫁衣裳

格式：`ONBUILD <其它指令>`。

`ONBUILD` 是一个特殊的指令，它后面跟的是其它指令，比如 `RUN`, `COPY` 等，而这些指令，在当前镜像构建时并不会被执行。只有当以当前镜像为基础镜像，去构建下一级镜像的时候才会被执行。

`Dockerfile` 中的其它指令都是为了定制当前镜像而准备的，唯有 `ONBUILD` 是为了帮助别人定制自己而准备的。

假设我们要制作 Node.js 所写的应用的镜像。我们都知道 Node.js 使用 `npm` 进行包管理，所有依赖、配置、启动信息等会放到 `package.json` 文件里。在拿到程序代码后，需要先进行 `npm install` 才可以获得所有需要的依赖。然后就可以通过 `npm start` 来启动应用。因此，一般来说会这样写 `Dockerfile`：

```dockerfile
FROM node:slim
WORKDIR /app
COPY ./package.json /app
RUN [ "npm", "install" ]
COPY . /app/
CMD [ "npm", "start" ]
```

把这个 `Dockerfile` 放到 Node.js 项目的根目录，构建好镜像后，就可以直接拿来启动容器运行。但是如果我们还有第二个 Node.js 项目也差不多呢？好吧，那就再把这个 `Dockerfile` 复制到第二个项目里。那如果有第三个项目呢？再复制么？文件的副本越多，版本控制就越困难，让我们继续看这样的场景维护的问题。

如果第一个 Node.js 项目在开发过程中，发现这个 `Dockerfile` 里存在问题，比如敲错字了、或者需要安装额外的包，然后开发人员修复了这个 `Dockerfile`，再次构建，问题解决。第一个项目没问题了，但是第二个项目呢？虽然最初 `Dockerfile` 是复制、粘贴自第一个项目的，但是并不会因为第一个项目修复了他们的 `Dockerfile`，而第二个项目的 `Dockerfile` 就会被自动修复。

那么我们可不可以做一个基础镜像，然后各个项目使用这个基础镜像呢？这样基础镜像更新，各个项目不用同步 `Dockerfile` 的变化，重新构建后就继承了基础镜像的更新？好吧，可以，让我们看看这样的结果。

基础镜像(my-node) `Dockerfile`

```dockerfile
FROM node:slim
WORKDIR /app
CMD [ "npm", "start" ]
```

应用镜像(my-app1) `Dockerfile`

```dockerfile
FROM my-node
COPY ./package.json /app
RUN [ "npm", "install" ]
COPY . /app/
```

基础镜像变化后，各个项目都用这个 `Dockerfile` 重新构建镜像，会继承基础镜像的更新。

那么，问题解决了么？没有。准确说，只解决了一半。如果这个 `Dockerfile` 里面有些东西需要调整呢？比如 `npm install` 都需要加一些参数，那怎么办？这一行 `RUN` 是不可能放入基础镜像的，因为涉及到了当前项目的 `./package.json`，难道又要一个个修改么？所以说，这样制作基础镜像，只解决了原来的 `Dockerfile` 的前4条指令的变化问题，而后面三条指令的变化则完全没办法处理。

`ONBUILD` 可以解决这个问题。让我们用 `ONBUILD` 重新写一下基础镜像的 `Dockerfile`:

```dockerfile
FROM node:slim
WORKDIR /app
ONBUILD COPY ./package.json /app
ONBUILD RUN [ "npm", "install" ]
ONBUILD COPY . /app/
CMD [ "npm", "start" ]
```

应用镜像 `Dcokerfile`

```dockerfile
FROM my-node
```

是的，只有这么一行。当在各个项目目录中，用这个只有一行的 `Dockerfile` 构建镜像时，之前基础镜像的那三行 `ONBUILD` 就会开始执行，成功的将当前项目的代码复制进镜像、并且针对本项目执行 `npm install`，生成应用镜像。

## LABEL 为镜像添加元数据

`LABEL` 指令用来给镜像以键值对的形式添加一些元数据（metadata）。

```dockerfile
LABEL <key>=<value> <key>=<value> <key>=<value> ...
```

我们还可以用一些标签来申明镜像的作者、文档地址等：

```dockerfile
LABEL org.opencontainers.image.authors="yeasy"
LABEL org.opencontainers.image.documentation="https://yeasy.gitbooks.io"
```

具体可以参考 https://github.com/opencontainers/image-spec/blob/master/annotations.md

## SHELL 指定shell

格式：`SHELL ["executable", "parameters"]`

`SHELL` 指令可以指定 `RUN` `ENTRYPOINT` `CMD` 指令的 shell，Linux 中默认为 `["/bin/sh", "-c"]

如下示例，两个 `RUN` 运行同一命令，第二个 `RUN` 运行的命令会打印出每条命令并当遇到错误时退出。

```dockerfile
SHELL ["/bin/sh", "-c"]
RUN lll ; ls

SHELL ["/bin/sh", "-cex"]
RUN lll ; ls
```

如下示例，当 `ENTRYPOINT` `CMD` 以 shell 格式指定时，`SHELL` 指令所指定的 shell 也会成为这两个指令的 shell

```dockerfile
SHELL ["/bin/sh", "-cex"]

# /bin/sh -cex "nginx"
ENTRYPOINT nginx

# /bin/sh -cex "nginx"
CMD nginx
```



