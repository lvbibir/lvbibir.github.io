---
title: "docker | 常见命令" 
date: 2019-08-01
lastmod: 2024-01-27
tags:
  - docker
keywords:
  - linux
  - docker
description: "基于 docker-18.03.0-ce 版本，介绍常见的 docker 命令及参数的使用方法" 
cover:
    image: "images/docker.png" 
---

# 1 容器操作

## 1.1 run

创建一个新的容器并运行一个命令

语法: docker run [OPTIONS] IMAGE [COMMAND] [ARG…]

OPTIONS 说明：

```bash
-a stdin: 指定标准输入输出内容类型，可选 STDIN/STDOUT/STDERR 三项；
-d: 后台运行容器，并返回容器ID；
-i: 以交互模式运行容器，通常与 -t 同时使用；
-P: 随机端口映射，容器内部端口随机映射到主机的高端口
-p: 指定端口映射，格式为：主机(宿主)端口:容器端口
	1. 只指定容器端口（宿主机端口随机映射）
	docker run -p 80 -it ubuntu /bin/bash
	2. 主机端口：容器端口
	docker run -p 8080:80 -it ubuntu /bin/bash
	3. IP：容器端口
	docker run -p 0.0.0.0:80 -it ubuntu /bin/bash
	4. IP：端口：容器端口
	dokcer run -p 0.0.0.0:8080:80 -it ubuntu /bin/bash
-t: 为容器重新分配一个伪输入终端，通常与 -i 同时使用；
--name="nginx-lb": 为容器指定一个名称；
--dns 8.8.8.8: 指定容器使用的DNS服务器，默认和宿主一致；
--dns-search example.com: 指定容器DNS搜索域名，默认和宿主一致；
-h "mars": 指定容器的hostname；
-e username="ritchie": 设置环境变量；
-env-file=[]: 从指定文件读入环境变量；
--cpuset="0-2" or --cpuset="0,1,2": 绑定容器到指定CPU运行；
-m :设置容器使用内存最大值；
--net="bridge": 指定容器的网络连接类型，支持 bridge/host/none/container: 四种类型；
--link=[]: 添加链接到另一个容器；
--expose=[]: 开放一个端口或一组端口；
--volume , -v: 绑定一个卷
    -v [hostpath]:containerpath:[ro|wo|rw]
    如果没有设置 hostpath 则挂载到 /var/lib/docker/volumes/<containerid>/ 目录下
    如果没有设置权限，默认 rw(读写)
```

实例

使用 docker 镜像 nginx:latest 以后台模式启动一个容器,并将容器命名为 mynginx。

```bash
docker run --name mynginx -d nginx:latest
```

使用镜像 nginx:latest 以后台模式启动一个容器,并将容器的 80 端口映射到主机随机端口。

```bash
docker run -P -d nginx:latest
```

使用镜像 nginx:latest，以后台模式启动一个容器,将容器的 80 端口映射到主机的 80 端口,主机的目录 /data 映射到容器的 /data。

```bash
docker run -p 80:80 -v /data:/data -d nginx:latest
```

绑定容器的 8080 端口，并将其映射到本地主机 127.0.0.1 的 80 端口上。

```bash
docker run -p 127.0.0.1:80:8080/tcp ubuntu bash
```

使用镜像 nginx:latest 以交互模式启动一个容器,在容器内执行/bin/bash 命令。

```bash
runoob@runoob:~$ docker run -it nginx:latest /bin/bash
root@b8573233d675:/# 
```

## 1.2 ps

列出容器

语法: docker ps [OPTIONS]

OPTIONS 说明：

```bash
-a: 显示所有的容器，包括未运行的。
-f: 根据条件过滤显示的内容。
--format: 指定返回值的模板文件。
-l: 显示最近创建的容器。
-n: 列出最近创建的n个容器。
--no-trunc: 不截断输出。
-q: 静默模式，只显示容器编号。
-s: 显示总的文件大小。
```

实例

列出所有在运行的容器信息。

```bash
runoob@runoob:~$ docker ps
CONTAINER ID   IMAGE          COMMAND                ...  PORTS                    NAMES
09b93464c2f7   nginx:latest   "nginx -g 'daemon off" ...  80/tcp, 443/tcp          myrunoob
96f7f14e99ab   mysql:5.6      "docker-entrypoint.sh" ...  0.0.0.0:3306->3306/tcp   mymysql
```

列出最近创建的 5 个容器信息。

```bash
runoob@runoob:~$ docker ps -n 5
CONTAINER ID        IMAGE               COMMAND                   CREATED           
09b93464c2f7        nginx:latest        "nginx -g 'daemon off"    2 days ago   ...     
b8573233d675        nginx:latest        "/bin/bash"               2 days ago   ...     
b1a0703e41e7        nginx:latest        "nginx -g 'daemon off"    2 days ago   ...    
f46fb1dec520        5c6e1090e771        "/bin/sh -c 'set -x \t"   2 days ago   ...   
a63b4a5597de        860c279d2fec        "bash"                    2 days ago   ...
```

列出所有创建的容器 ID。

```bash
runoob@runoob:~$ docker ps -a -q
09b93464c2f7
b8573233d675
b1a0703e41e7
f46fb1dec520
a63b4a5597de
6a4aa42e947b
de7bb36e7968
43a432b73776
664a8ab1a585
ba52eb632bbd
```

## 1.3 inspect

docker inspect : 获取容器/镜像的元数据。

语法: docker inspect [OPTIONS] NAME|ID [NAME|ID…]

OPTIONS 说明：

```bash
-f :指定返回值的模板文件。
-s :显示总的文件大小。
--type json:为指定类型返回JSON。
--format :以指定格式返回数据
```

获取所有容器的 ip 地址

```bash
docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
```

获取某个容器的挂载信息

```bash
docker inspect --format='{{json .Mounts}}' demo-volume-2 | python -m json.tool
```

## 1.4 start/stop/restart

启动的容器; 停止容器; 重启容器

语法: docker start|stop|restart [OPTIONS] CONTAINER [CONTAINER…]

实例

```bash
# 启动已被停止的容器 myrunoob
docker start myrunoob

# 停止运行中的容器 myrunoob
docker stop myrunoob

# 重启容器 myrunoob
docker restart myrunoob
```

## 1.5 rm

删除一个或多少容器

语法: docker rm [OPTIONS] CONTAINER [CONTAINER…]

OPTIONS 说明：

```bash
-f :通过SIGKILL信号强制删除一个运行中的容器
-l :移除容器间的网络连接，而非容器本身
-v :-v 删除与容器关联的卷
```

实例

强制删除容器 db01、db02

```bash
docker rm -f db01 db02
```

移除容器 nginx01 对容器 db01 的连接，连接名 db

```bash
docker rm -l db 
```

删除容器 nginx01,并删除容器挂载的数据卷

```bash
docker rm -v nginx01
```

## 1.6 attach

连接到正在运行中的容器。

语法: docker attach [OPTIONS] CONTAINER

要 attach 上去的容器必须正在运行，可以同时连接上同一个 container 来共享屏幕（与 screen 命令的 attach 类似）。

官方文档中说 attach 后可以通过 CTRL-C 来 detach，但实际上经过我的测试，如果 container 当前在运行 bash，CTRL-C 自然是当前行的输入，没有退出；如果 container 当前正在前台运行进程，如输出 nginx 的 access.log 日志，CTRL-C 不仅会导致退出容器，而且还 stop 了。这不是我们想要的，detach 的意思按理应该是脱离容器终端，但容器依然运行。好在 attach 是可以带上 --sig-proxy=false 来确保 CTRL-D 或 CTRL-C 不会关闭容器。

实例

容器 mynginx 将访问日志指到标准输出，连接到容器查看访问信息。

```bash
runoob@runoob:~$ docker attach --sig-proxy=false mynginx
192.168.239.1 - - [10/Jul/2016:16:54:26 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.93 Safari/537.36" "-"
```

## 1.7 logs

docker logs : 获取容器的日志

语法: docker logs [OPTIONS] CONTAINER

OPTIONS 说明：

```bash
-f : 跟踪日志输出。类似 tail 命令的 -f 选项
--since :显示某个开始时间的所有日志
-t : 显示时间戳
--tail :仅列出最新N条容器日志
```

实例

跟踪查看容器 mynginx 的日志输出。

```bash
runoob@runoob:~$ docker logs -f mynginx
192.168.239.1 - - [10/Jul/2016:16:53:33 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.93 Safari/537.36" "-"
2016/07/10 16:53:33 [error] 5#5: *1 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 192.168.239.1, server: localhost, request: "GET /favicon.ico HTTP/1.1", host: "192.168.239.130", referrer: "http://192.168.239.130/"
192.168.239.1 - - [10/Jul/2016:16:53:33 +0000] "GET /favicon.ico HTTP/1.1" 404 571 "http://192.168.239.130/" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.93 Safari/537.36" "-"
192.168.239.1 - - [10/Jul/2016:16:53:59 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.93 Safari/537.36" "-"
...
```

查看容器 mynginx 从 2016 年 7 月 1 日后的最新 10 条日志。

```bash
docker logs --since="2016-07-01" --tail=10 mynginx
```

## 1.8 top

查看容器中运行的进程信息，支持 ps 命令参数。

语法: docker top [OPTIONS] CONTAINER [ps OPTIONS]

容器运行时不一定有/bin/bash 终端来交互执行 top 命令，而且容器还不一定有 top 命令，可以使用 docker top 来实现查看 container 中正在运行的进程。

实例

查看容器 mymysql 的进程信息。

```bash
runoob@runoob:~/mysql$ docker top mymysql
UID    PID    PPID    C      STIME   TTY  TIME       CMD
999    40347  40331   18     00:58   ?    00:00:02   mysqld
```

查看所有运行容器的进程信息。

```bash
for i in  `docker ps |grep Up|awk '{print $1}'`;do echo \ &&docker top $i; done
```

## 1.9 exec

在运行的容器中执行命令

语法: docker exec [OPTIONS] CONTAINER COMMAND [ARG…]

OPTIONS 说明：

```bash
-d :分离模式: 在后台运行
-i :即使没有附加也保持STDIN 打开
-t :分配一个伪终端
```

实例

在容器 mynginx 中以交互模式执行容器内 /root/runoob.sh 脚本:

```bash
runoob@runoob:~$ docker exec -it mynginx /bin/sh /root/runoob.sh
http://www.runoob.com/
```

在容器 mynginx 中开启一个交互模式的终端:

```bash
runoob@runoob:~$ docker exec -i -t  mynginx /bin/bash
root@b1a0703e41e7:/#
```

也可以通过 docker ps -a 命令查看已经在运行的容器，然后使用容器 ID 进入容器。

查看已经在运行的容器 ID：

```bash
 docker ps -a 
...
9df70f9a0714        openjdk             "/usercode/script.sh…" 
...
```

第一列的 9df70f9a0714 就是容器 ID。

通过 exec 命令对指定的容器执行 bash:

```bash
docker exec -it 9df70f9a0714 /bin/bash
```

## 1.10 kill

杀掉一个运行中的容器。

语法: docker kill [OPTIONS] CONTAINER [CONTAINER…]

OPTIONS 说明：

```bash
-s :向容器发送一个信号
```

实例

杀掉运行中的容器 mynginx

```bash
runoob@runoob:~$ docker kill -s KILL mynginx
mynginx
```

# 2 镜像操作

## 2.1 images

docker images : 列出本地镜像。

语法: docker images [OPTIONS] [REPOSITORY[:TAG]]

OPTIONS 说明：

```bash
-a :列出本地所有的镜像（含中间映像层，默认情况下，过滤掉中间映像层）；
--digests :显示镜像的摘要信息；
-f :显示满足条件的镜像；
--format :指定返回值的模板文件；
--no-trunc :显示完整的镜像信息；
-q :只显示镜像ID。
```

实例

查看本地镜像列表。

```bash
runoob@runoob:~$ docker images
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
mymysql                 v1                  37af1236adef        5 minutes ago       329 MB
runoob/ubuntu           v4                  1c06aa18edee        2 days ago          142.1 MB
<none>                  <none>              5c6e1090e771        2 days ago          165.9 MB
httpd                   latest              ed38aaffef30        11 days ago         195.1 MB
alpine                  latest              4e38e38c8ce0        2 weeks ago         4.799 MB
mongo                   3.2                 282fd552add6        3 weeks ago         336.1 MB
redis                   latest              4465e4bcad80        3 weeks ago         185.7 MB
php                     5.6-fpm             025041cd3aa5        3 weeks ago         456.3 MB
python                  3.5                 045767ddf24a        3 weeks ago         684.1 MB
...
```

列出本地镜像中 REPOSITORY 为 ubuntu 的镜像列表。

```bash
root@runoob:~# docker images  ubuntu
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              14.04               90d5884b1ee0        9 weeks ago         188 MB
ubuntu              15.10               4e3b13c8a266        3 months ago        136.3 MB
```

## 2.2 inspect

获取容器/镜像的元数据。

语法: docker inspect [OPTIONS] NAME|ID [NAME|ID…]

OPTIONS 说明：

```bash
-f :指定返回值的模板文件。
-s :显示总的文件大小。
--type :为指定类型返回JSON。
--format :以指定格式返回数据
```

实例

获取镜像 mysql:5.6 的元信息。

```bash
runoob@runoob:~$ docker inspect mysql:5.6
[
    {
        "Id": "sha256:2c0964ec182ae9a045f866bbc2553087f6e42bfc16074a74fb820af235f070ec",
        "RepoTags": [
            "mysql:5.6"
        ],
        "RepoDigests": [],
        "Parent": "",
        "Comment": "",
        "Created": "2016-05-24T04:01:41.168371815Z",
        "Container": "e0924bc460ff97787f34610115e9363e6363b30b8efa406e28eb495ab199ca54",
        "ContainerConfig": {
            "Hostname": "b0cf605c7757",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "ExposedPorts": {
                "3306/tcp": {}
            },
...
```

## 2.3 rmi

删除本地一个或多少镜像。

语法: docker rmi [OPTIONS] IMAGE [IMAGE…]

OPTIONS 说明：

```bash
-f :强制删除；
--no-prune :不移除该镜像的过程镜像，默认移除；
```

注：IMAGE 可以使用 [仓库：标签] 的格式，也可以使用镜像 ID，可以同时删除多个镜像

1、使用 [仓库：标签] 的格式：删除一个标签。当一个镜像文件有多个标签时，删除完所有的标签，镜像文件也随之删除

2、使用镜像 ID 的格式：先将该镜像文件的所有标签删除，再删除镜像文件

删除所有镜像

```bash
docker rmi $(docker images -q)
```

删除某个仓库的所有镜像

```bash
docker rmi $(docker images -q ubuntu)
```

实例

强制删除本地镜像 runoob/ubuntu:v4。

```bash
root@runoob:~# docker rmi -f runoob/ubuntu:v4
Untagged: runoob/ubuntu:v4
Deleted: sha256:1c06aa18edee44230f93a90a7d88139235de12cd4c089d41eed8419b503072be
Deleted: sha256:85feb446e89a28d58ee7d80ea5ce367eebb7cec70f0ec18aa4faa874cbd97c73
```

## 2.4 search

语法: docker search [OPTIONS] TERM

OPTIONS 说明：

```bash
--automated :只列出 automated build类型的镜像；
--no-trunc :显示完整的镜像描述；
-s :列出收藏数不小于指定值的镜像。
```

实例

从 Docker Hub 查找所有镜像名包含 java，并且收藏数大于 10 的镜像

```bash
runoob@runoob:~$ docker search -s 10 java
NAME                  DESCRIPTION                           STARS   OFFICIAL   AUTOMATED
java                  Java is a concurrent, class-based...   1037    [OK]       
anapsix/alpine-java   Oracle Java 8 (and 7) with GLIBC ...   115                [OK]
develar/java                                                 46                 [OK]
isuper/java-oracle    This repository contains all java...   38                 [OK]
lwieske/java-8        Oracle Java 8 Container - Full + ...   27                 [OK]
nimmis/java-centos    This is docker images of CentOS 7...   13                 [OK]
```

## 2.5 pull

docker pull [OPTIONS] NAME[:TAG|@DIGEST]

OPTIONS 说明：

```bash
-a :拉取所有 tagged 镜像
--disable-content-trust :忽略镜像的校验,默认开启
```

实例

从 Docker Hub 下载 java 最新版镜像。

```bash
docker pull java
```

从 Docker Hub 下载 REPOSITORY 为 java 的所有镜像。

```bash
docker pull -a java
```

## 2.6 push

将本地的镜像上传到镜像仓库,要先登陆到镜像仓库

语法: docker push [OPTIONS] NAME[:TAG]

OPTIONS 说明：

```bash
--disable-content-trust :忽略镜像的校验,默认开启
```

实例

上传本地镜像 myapache:v1 到镜像仓库中。

```bash
docker push myapache:v1
```

## 2.7 commit

从容器创建一个新的镜像。

语法: docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]

OPTIONS 说明：

```bash
-a :提交的镜像作者；
-c :使用Dockerfile指令来创建镜像；
-m :提交时的说明文字；
-p :在commit时，将容器暂停。
```

实例

将容器 a404c6c174a2 保存为新的镜像,并添加提交人信息和说明信息。

```bash
runoob@runoob:~$ docker commit -a "runoob.com" -m "my apache" a404c6c174a2  mymysql:v1 
sha256:37af1236adef1544e8886be23010b66577647a40bc02c0885a6600b33ee28057
runoob@runoob:~$ docker images mymysql:v1
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
mymysql             v1                  37af1236adef        15 seconds ago      329 MB
```

## 2.8 build

用于使用 Dockerfile 创建镜像。

语法: docker build [OPTIONS] PATH | URL | -

OPTIONS 说明：

```bash
--build-arg=[] :设置镜像创建时的变量；
--cpu-shares :设置 cpu 使用权重；
--cpu-period :限制 CPU CFS周期；
--cpu-quota :限制 CPU CFS配额；
--cpuset-cpus :指定使用的CPU id；
--cpuset-mems :指定使用的内存 id；
--disable-content-trust :忽略校验，默认开启；
-f :指定要使用的Dockerfile路径；
--force-rm :设置镜像过程中删除中间容器；
--isolation :使用容器隔离技术；
--label=[] :设置镜像使用的元数据；
-m :设置内存最大值；
--memory-swap :设置Swap的最大值为内存+swap，"-1"表示不限swap；
--no-cache :创建镜像的过程不使用缓存；
--pull :尝试去更新镜像的新版本；
--quiet, -q :安静模式，成功后只输出镜像 ID；
--rm :设置镜像成功后删除中间容器；
--shm-size :设置/dev/shm的大小，默认值是64M；
--ulimit :Ulimit配置。
--tag, -t: 镜像的名字及标签，通常 name:tag 或者 name 格式；可以在一次构建中为一个镜像设置多个标签。
--network: 默认 default。在构建期间设置RUN指令的网络模式
```

实例

使用当前目录的 Dockerfile 创建镜像，标签为 runoob/ubuntu:v1。

```bash
docker build -t runoob/ubuntu:v1 . 
```

使用 URL github.com/creack/docker-firefox 的 Dockerfile 创建镜像。

```bash
docker build github.com/creack/docker-firefox
```

也可以通过 -f Dockerfile 文件的位置：

```bash
$ docker build -f /path/to/a/Dockerfile .
```

在 Docker 守护进程执行 Dockerfile 中的指令前，首先会对 Dockerfile 进行语法检查，有语法错误时会返回：

```bash
$ docker build -t test/myapp .
Sending build context to Docker daemon 2.048 kB
Error response from daemon: Unknown instruction: RUNCMD
```

以上
