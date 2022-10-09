---
title: "docker | 跨主机访问" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- docker
keywords:
- linux
- docker
description: "实现docker客户端与另一台主机上的docker守护进程进行通信" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

# 环境准备
主机版本为Centos7.4，docker版本为docker-ce-18.09.7-3.el7.x86_64
node1：192.168.0.111
node2：192.168.0.107
1. 两台安装docker的环境
2. 保证两台主机上的docker的Client API与Server APi版本一致

# 修改daemon.json配置文件，添加label，用于区别两台docker主机
node1：

```
[root@localhost ~]# vim /etc/docker/daemon.json
{
"registry-mirrors": ["http://f1361db2.m.daocloud.io"],    
"labels": ["-label nodeName=node1"]          #添加label
}
```
查看效果

```
[root@localhost ~]# systemctl restart docker
[root@localhost ~]# docker info
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190810222537259.png)
node2;
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190810223150493.png)

# 修改Client与守护进程通信的方式（修改为tcp的方式）
修改通信方式共有三种方式：
1. 修改daemon.json文件，添加host键值对
添加："hosts": ["tcp://0.0.0.0:2375"]
开放本机ip的2375端口，可以让其他docker主机的client进行连接
2. 修改/lib/systemd/system/docker.service文件，添加-H启动参数
修改：ExecStart=/usr/bin/docker -H tcp://0.0.0.0:2375
3. 使用dokcerd启动docker，添加-H参数
dockerd -H tcp://0.0.0.0:2375

Centos7中/etc/docker/daemon.json会被docker.service的配置文件覆盖，直接添加daemon.json不起作用
所以我使用的是第二种方式

node1：

```
[root@localhost ~]# vim /lib/systemd/system/docker.service
ExecStart=/usr/bin/docker -H tcp://0.0.0.0:2375 
[root@localhost ~]# systemctl daemon-reload
[root@localhost ~]# systemctl restart docker
[root@localhost ~]# ps -ef | grep docker
root       5775      1  3 23:17 ?        00:00:00 /usr/bin/dockerd -H tcp://0.0.0.0:2375
root       5779   5775  0 23:17 ?        00:00:00 docker-containerd --config /var/run/docker/containerd/containerd.toml
root       5879   3919  0 23:17 pts/1    00:00:00 grep --color=auto docker
```

# 远程访问
node2：

```
[root@localhost ~]# curl http://192.168.0.111:2375/info
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190810232112308.png)


```
[root@localhost ~]# docker -H tcp://192.168.0.111:2375 info
```

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190810232347323.png)

如果频繁使用-H选项未免太过于麻烦，可以修改DOCKER_HOST这个环境变量的值，node2就可以像使用本地的docker一样来远程连接node1的守护进程

```
[root@localhost ~]# export DOCKER_HOST="tcp://192.168.0.111:2375"
[root@localhost ~]# docker info
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190810232828582.png)
当无需再远程连接node1的守护进程时，将DOCKER_HOST环境变量置空即可

```
[root@localhost ~]# export DOCKER_HOST=""
[root@localhost ~]# docker info
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190810233039709.png)



node1：
因为node1设置了修改Client与守护进程的通信方式，所以本地无法再通过默认的socket进行连接，必须使用-H选项通过tcp来进行连接，也可以通过DOCKER_HOST来修改
```
[root@localhost ~]# docker info
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
[root@localhost ~]# docker -H 0.0.0.0:2375 info
```
如果本机依旧希望使用默认的socket进行连接，可以在/lib/systemd/system/docker.service中再添加一个-H选项

```
[root@localhost ~]# vim /lib/systemd/system/docker.service
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
[root@localhost ~]# systemctl daemon-reload
[root@localhost ~]# systemctl restart docker
[root@localhost ~]# ps -ef | grep docker
root       6462      1  2 23:40 ?        00:00:00 /usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
root       6467   6462  0 23:40 ?        00:00:00 docker-containerd --config /var/run/docker/containerd/containerd.toml
root       6567   3919  0 23:40 pts/1    00:00:00 grep --color=auto docker
[root@localhost ~]# docker info
```