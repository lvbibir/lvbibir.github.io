---
title: "docker | 网络简介" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- docker
keywords:
- linux
- docker
- network
description: "docker的网络结构简介 | 同一宿主机的docker容器之间是如何通信的" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

# 概述

1. 独立容器网络：none host
none网络最为安全，只有localback接口
host网络只和物理机相连，保证跟物理机相连的网络效率	跟物理机完全一样（网络协议栈与主机名）
2. 容器间的网络：bridge [docker bridge详解](https://blog.csdn.net/qq_27068845/article/details/80893318)
docker启动时默认会有一个docker0网桥，该网桥就是桥接模式的体现
用户也可以自建bridge网络，建立后dokcer也会创建一个网桥

4. 跨主机的容器间的网络：macvlan overlay
5. 第三方网络：flannel weave calic
# docker0
安装了docker的系统，使用ifconfig可以查看到docker0设备，docker守护进程就是通过docker0为容器提供网络连接的各种服务
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811124731281.png)
docker0实际上是linux虚拟网桥（交换机)
网桥是数据链路层的设备，它通过mac地址来对网络进行划分，并且在不同的网络之间传递数据

linux虚拟网桥的特点：
1. 可以设置ip地址（二层的网桥可以设置三层的ip地址）
2. 相当于拥有一个隐藏的虚拟网卡



![在这里插入图片描述](https://image.lvbibir.cn/blog/2019081112483089.png)

docker0的地址划分：
1. IP：172.17.0.1（各版本可能不同） 子网掩码：255.255.0.0
2. MAC：02:42:00:00:00:00 到 02:42:ff:ff:ff:ff（各版本可能不同）
3. 总共提供了65534个地址

每当一个容器启动时，docker守护进程会创建网络连接的两端，一端在容器内创建eth0网卡，另一端在dokcer0网桥中开启一个端口veth*


![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811130803531.png)

查看网桥设备需要预先安装bridge-utils软件包

```
[root@localhost ~]# yum install -y bridge-utils
[root@localhost ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
docker0         8000.024247d799bf       no
virbr0          8000.525400b76fd4       yes             virbr0-nic
```

开启一个容器，查看网络设置：

```
[root@localhost ~]# docker run -it --name nwt1 centos /bin/bash
[root@0ef32e882bcf /]# ifconfig
bash: ifconfig: command not found
[root@0ef32e882bcf /]# yum install -y net-tools
[root@0ef32e882bcf /]# ifconfig
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811133220548.png)
ctrl+p，ctrl+q 让这个人继续后台运行
再查看一下网桥

```
[root@localhost ~]# brctl show
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811133457224.png)

```
[root@localhost ~]# ifconfig
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811133611993.png)
## 自定义docker0
当默认docker0的ip或者网段与主机环境发生冲突时，可以修改docker0的地址和网段来进行自定义

```
ifconfig docker0 IP netmask NETMASK
```

```
[root@localhost ~]# ifconfig docker0 192.168.200.1 netmask 255.255.255.0
[root@localhost ~]# ifconfig
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811134011802.png)

```
[root@localhost ~]# systemctl restart docker
[root@localhost ~]# docker run -it centos /bin/bash
[root@a5c6ebf79340 /]# yum install -y net-tools
[root@a5c6ebf79340 /]# ifconfig
```

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811135908809.png)
	
## 自定义虚拟网桥
添加虚拟网桥：
1. brctl addbr br0
2. ifconfig br0 IP netmask NETMASK

更改docker守护进程的启动配置
1. /lib/systemd/system/docker.service中添加-b=br0

```
[root@localhost ~]# brctl addbr br0
[root@localhost ~]# ifconfig br0 192.168.100.1 netmask 255.255.255.0
[root@localhost ~]# ifconfig
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811140448102.png)

```
[root@localhost ~]# vim /lib/systemd/system/docker.service
ExecStart=/usr/bin/dockerd -b=br0
[root@localhost ~]# systemctl daemon-reload
[root@localhost ~]# systemctl restart docker
[root@localhost ~]# ps -ef | grep docker
root       4156      1  1 14:06 ?        00:00:00 /usr/bin/dockerd -b=br0
root       4161   4156  0 14:06 ?        00:00:00 docker-containerd --config /var/run/docker/containerd/containerd.toml
root       4263   1558  0 14:06 pts/0    00:00:00 grep --color=auto docker
```
开启一个容器

```
[root@localhost ~]# docker run -it --name nwt3 centos /bin/bash
[root@d70269c9557e /]# yum install -y net-tools
[root@d70269c9557e /]# ifconfig
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811141504468.png)
# 同一宿主机间容器的连接
1. 允许单台主机内所有容器互联（默认情况）
2. 拒绝容器间连接
3. 允许特定容器间的连接
## 允许单台主机内所有容器互联（默认情况）
--icc=true    默认为true，即允许同一宿主机下所有容器之间网络连通

```
[root@localhost ~]# docker run -itd --name test1 busybox /bin/sh
7ec641b21b66b6472f4e92cfaa7f9c0674c4322a5265a05e272ae180b0d4687c
[root@localhost ~]# docker exec test1 ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02
          inet addr:172.17.0.2  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:648 (648.0 B)  TX bytes:0 (0.0 B)

[root@localhost ~]# docker run -itd --name test2 busybox /bin/sh
fee0ff3e7f82cd1fa06eea11d850251931dff4dff2f0c7ee3e5a9904532beeb6
[root@localhost ~]# docker exec test2 ping 172.17.0.2 -c 4
PING 172.17.0.2 (172.17.0.2): 56 data bytes
64 bytes from 172.17.0.2: seq=0 ttl=64 time=0.133 ms
64 bytes from 172.17.0.2: seq=1 ttl=64 time=0.136 ms
64 bytes from 172.17.0.2: seq=2 ttl=64 time=0.264 ms
64 bytes from 172.17.0.2: seq=3 ttl=64 time=0.163 ms

--- 172.17.0.2 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.133/0.174/0.264 ms    
```
容器的ip是不可靠的连接
可以使用--link选项来连接两个容器

```
docker run --link=[CONTAINER_NAME]:[ALIAS] [IMAGE] [COMMAND]
```
--link后面的test3指连接到test3容器，nt是为test3创建了一个别名
新建两个容器进行测试
```
[root@localhost ~]# docker run -itd --name test3 busybox /bin/sh
1fd4e373dba17fdf1fa93121e08ea2f1f32d8f4116339c072a72a73574b0926f
[root@localhost ~]# docker run -itd --name test4 --link=test3:nt  busybox /bin/sh
c04b9b759bd4cc9af54000a742df58c8369a7f1bfc8862a8325481f1d61db135
[root@localhost ~]#
[root@localhost ~]# docker exec test4 ping nt -c 4
PING nt (172.17.0.4): 56 data bytes
64 bytes from 172.17.0.4: seq=0 ttl=64 time=0.256 ms
64 bytes from 172.17.0.4: seq=1 ttl=64 time=0.196 ms
64 bytes from 172.17.0.4: seq=2 ttl=64 time=0.164 ms
64 bytes from 172.17.0.4: seq=3 ttl=64 time=0.148 ms

--- nt ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.148/0.191/0.256 ms
```
--link选项对容器做了如下改变：
1. 修改了env环境变量
2. 修改了hosts文件


```
[root@localhost ~]# docker exec test4 env
[root@localhost ~]# docker exec test4 cat /etc/hosts
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811182505450.png)
删除之前使用的test1与test2容器，这两个容器占用的ip释放，重启test3后，使用最新的ip地址

```
[root@localhost ~]# docker rm -f test1
test1
[root@localhost ~]# docker rm -f test2
test2
[root@localhost ~]# docker restart test3
test3
[root@localhost ~]# docker exec test3 ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02
          inet addr:172.17.0.2  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:648 (648.0 B)  TX bytes:0 (0.0 B)
```
可以看到随着test3的ip地址发生改变，test4容器中的hosts文件也随之改变

```
[root@localhost ~]# docker exec test4 cat /etc/hosts
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190811183004484.png)
## 拒绝容器间连接
修改守护进程的启动选项：--icc=false

```
[root@localhost ~]# vim /lib/systemd/system/docker.service
ExecStart=/usr/bin/dockerd   --icc=false
[root@localhost ~]# systemctl daemon-reload
[root@localhost ~]# systemctl restart docker
```
新建两个容器进行测试，可以看到无法ping通

```
[root@localhost ~]# docker run -itd --name test10 busybox /bin/sh
700f026459206531b0fda811a43bc12af2f0815dc695f317a1f52939bfada2a1
[root@localhost ~]# docker run -itd --name test11 busybox /bin/sh
792cc31481739e1b2537597bc54c76737333bf95412dac2209e050f35d276dd4
[root@localhost ~]# docker exec test10 ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:06
          inet addr:172.17.0.6  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:648 (648.0 B)  TX bytes:0 (0.0 B)

[root@localhost ~]# docker exec test11 ping 172.16.0.6
^C
```
## 允许特定容器间的连接
修改守护进程选项：
1. --icc=false
2. --iptables=true	#允许docker容器配置添加到linux的iptables设置中
3. --link

只有设置了--link的两个容器间才可以互通

```
[root@localhost ~]# vim /lib/systemd/system/docker.service
ExecStart=/usr/bin/dockerd   --icc=false --iptables=true
[root@localhost ~]# systemctl daemon-reload
[root@localhost ~]# systemctl restart docker
```
新建两个容器进行验证

```
[root@localhost ~]# docker run -itd --name test21  busybox /bin/sh
77f56db227acaa590f729c12a4852d3131f1729851ea8c613a670effbfa512ad

[root@localhost ~]# docker run -itd --name test22 --link=test21:nt busybox /bin/sh
f4e346387588198cafcfd1d6a2c330a20375b746d05c08bf06e100f9af294a9e

[root@localhost ~]# docker exec test22 ping nt -c 4
PING nt (172.17.0.2): 56 data bytes
64 bytes from 172.17.0.2: seq=0 ttl=64 time=0.201 ms
64 bytes from 172.17.0.2: seq=1 ttl=64 time=0.164 ms
64 bytes from 172.17.0.2: seq=2 ttl=64 time=0.195 ms
64 bytes from 172.17.0.2: seq=3 ttl=64 time=0.188 ms

--- nt ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.164/0.187/0.201 ms

[root@localhost ~]# docker exec test22 ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:03
          inet addr:172.17.0.3  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:14 errors:0 dropped:0 overruns:0 frame:0
          TX packets:6 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1124 (1.0 KiB)  TX bytes:476 (476.0 B)

[root@localhost ~]# docker exec test21 ping 172.17.0.3 -c 4
PING 172.17.0.3 (172.17.0.3): 56 data bytes
64 bytes from 172.17.0.3: seq=0 ttl=64 time=0.181 ms
64 bytes from 172.17.0.3: seq=1 ttl=64 time=0.168 ms
64 bytes from 172.17.0.3: seq=2 ttl=64 time=0.109 ms
64 bytes from 172.17.0.3: seq=3 ttl=64 time=0.226 ms

--- 172.17.0.3 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.109/0.171/0.226 ms
```