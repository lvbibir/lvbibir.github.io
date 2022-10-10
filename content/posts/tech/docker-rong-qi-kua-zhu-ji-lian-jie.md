---
title: "docker | 容器的跨主机连接" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- docker
keywords:
- linux
- docker
- network
description: "介绍docker容器在不同宿主机下实现通信的几种方案" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

实现跨主机的docker容器之间的通讯：

1. 使用网桥实现跨主机的连接
2. docker原生的网络：overlay、macvlan
3. 第三方网络：flaanel、weave、calic
# 网桥

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190815125207352.png)

# open vswitch
# weave
# macvlan
 macvlan是Linux操作系统内核提供的网络虚拟化方案之一，更准确的说法是网卡虚拟化方案。它可以为一张物理网卡设置多个mac地址，相当于物理网卡施展了影分身之术，由一个变多个，同时要求物理网卡打开混杂模式。针对每个mac地址，都可以设置IP地址，本来是一块物理网卡连接到交换机，现在是多块虚拟网卡连接到交换机。

当容器需要直连入物理网络时，可以使用Macvlan。Macvlan本身不创建网络，本质上首先使宿主机物理网卡工作在‘混杂模式’，这样物理网卡的MAC地址将会失效，所有二层网络中的流量物理网卡都能收到。接下来就是在这张物理网卡上创建虚拟网卡，并为虚拟网卡指定MAC地址，实现一卡多用，在物理网络看来，每张虚拟网卡都是一个单独的接口。使用Macvlan有几点需要注意：

- 容器直接连接物理网络，由物理网络负责分配IP地址，可能的结果是物理网络IP地址被耗尽，另一个后果是网络性能问题，物理网络中接入的主机变多，广播包占比快速升高而引起的网络性能下降问题。
- 前边说过了，宿主机上的某张网上需要工作在‘混乱模式’下。
- 从长远来看bridge网络与overlay网络是更好的选择，原因就是虚拟网络应该与物理网络隔离而不是共享。

优缺点：
- 优点是性能非常好
- 缺点是地址需要手动分配

Macvlan网络有两种模式：bridge模式与802.1q trunk bridge模式。

- bridge模式，Macvlan网络流量直接使用宿主机物理网卡。
- 802.1q trunk bridge模式，Macvlan网络流量使用Docker动态创建的802.1q子接口，对于路由与过虑，这种模式能够提供更细粒度的控制

----------------
环境准备：
1. 两台centos7
2. docker版本：18.03
3. ip：192.168.0.53（node-1） 192.168.0.54（node-2）

- node-1   node-2
- 注意：node-1使用的物理网卡是ens33，node-2使用的是ens32
```
[root@node-1 ~]# ip link show ens33
[root@node-1 ~]# ip link set ens32 promisc on
#开启混杂模式，保证多个ip可以通过
[root@node-1 ~]# docker network create -d macvlan --subnet 10.0.0.0/24 --gateway=10.0.0.1 -o parent=ens33 mac_net1
[root@node-1 ~]# docker network ls
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190818182057577.png)


- node-1

```
docker run -itd --name bbox-1 --ip 10.0.0.11 --network mac_net1 busybox
```
- node-2

```
docker run -itd --name bbox-2 --ip 10.0.0.12 --network mac_net1 busybox
```
- node-1

```
[root@node-1 ~]# docker exec bbox-1 ping 10.0.0.12
[root@node-1 ~]# docker exec bbox-1 ping bbox-2
```
可以ping通ip，但是无法ping通主机名，因为它没有dns解析
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190818182937702.png)

```
[root@node-1 ~]# brctl show
```
因为macvlan不依赖于bridge网络，所以查看不到新的桥接网络
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190818183048914.png)

    [root@node-1 ~]# docker exec bbox-1  ip link

查看到eth0连接到了if2
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190818183317728.png)

    [root@node-1 ~]# ip link show ens33

可以查看到ens33的编号是2，即bbox-1容器的eth0网卡连接到了ens33物理网卡
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190818183502889.png)

```
[root@node-1 ~]# docker network create  -d macvlan -o parent=ens33 mac_net2
Error response from daemon: network dm-b34ee1020a96 is already using parent interface ens33
```
再创建macvlan网络时发现已经无法再创建，即一块网卡只能添加一个macvlan的地址
## 一块网卡绑定多个macvlan地址
```
[root@node-1 ~]# modinfo 8021q
# 查看内核是否支持802.1q封装
[root@node-1 ~]# modprobe 8021q
# 如果上条命令执行后没有结果，使用该命令加载该模块
```

- node-1

```
[root@node-1 ~]# vim /etc/sysconfig/network-scripts/ifcfg-ens33
BOOTPROTO=manual
```
修改为不需要ip的manual模式
- node-2

```
[root@node-2 ~]# vim /etc/sysconfig/network-scripts/ifcfg-ens32
BOOTPROTO=manual
```
- node-1

添加两块虚拟网卡，注意与实际的ens32网卡的网段区分开
ens32使用的是192.168.0.0/24网段，虚拟网卡使用的是192.168.1.0/24和192.168.2.0/24
```
[root@node-1 ~]# cp -p /etc/sysconfig/network-scripts/ifcfg-ens33 /etc/sysconfig/network-scripts/ifcfg-ens33.10
[root@node-1 ~]# vim /etc/sysconfig/network-scripts/ifcfg-ens33.10
BOOTPROTO=none
NAME=ens33.10
DEVICE=ens33.10
ONBOOT=yes
IPADDR=192.168.1.10
PREFIX=24
NETWORK=192.168.1.0
VLAN=yes
[root@node-1 ~]# cp -p /etc/sysconfig/network-scripts/ifcfg-ens33.10 /etc/sysconfig/network-scripts/ifcfg-ens33.20
[root@node-1 ~]# vim /etc/sysconfig/network-scripts/ifcfg-ens33.20
BOOTPROTO=none
NAME=ens33.20
DEVICE=ens33.20
ONBOOT=yes
IPADDR=192.168.2.10
PREFIX=24
NETWORK=192.168.2.0
VLAN=yes
[root@node-1 ~]# ifup ens33.10
[root@node-1 ~]# ifup ens33.20
[root@node-1 ~]# scp /etc/sysconfig/network-scripts/ifcfg-ens33.10 192.168.0.54:/etc/sysconfig/network-scripts/ifcfg-ens32.10
[root@node-1 ~]# scp /etc/sysconfig/network-scripts/ifcfg-ens33.20 192.168.0.54:/etc/sysconfig/network-scripts/ifcfg-ens32.20
```
- node-2

```
[root@node-2 ~]# vim /etc/sysconfig/network-scripts/ifcfg-ens32.10
BOOTPROTO=none
NAME=ens32.10
DEVICE=ens32.10
ONBOOT=yes
IPADDR=192.168.1.20
PREFIX=24
NETWORK=192.168.1.0
VLAN=yes
[root@node-2 ~]# vim /etc/sysconfig/network-scripts/ifcfg-ens32.20
BOOTPROTO=none
NAME=ens32.20
DEVICE=ens32.20
ONBOOT=yes
IPADDR=192.168.2.20
PREFIX=24
NETWORK=192.168.2.0
VLAN=yes
[root@node-2 ~]# ifup ens32.10
[root@node-2 ~]# ifup ens32.20
```
- node-1

```
[root@node-1 ~]# docker network create -d macvlan --subnet 172.16.11.0/24 --gateway 172.16.11.1 -o parent=ens33.10 mac_net11
[root@node-1 ~]# docker network create -d macvlan --subnet 172.16.12.0/24 --gateway 172.16.12.1 -o parent=ens33.20 mac_net12
```
- node-2

```
[root@node-2 ~]# docker network create -d macvlan --subnet 172.16.11.0/24 --gateway 172.16.11.1 -o parent=ens32.10 mac_net11
[root@node-2 ~]# docker network create -d macvlan --subnet 172.16.12.0/24 --gateway 172.16.12.1 -o parent=ens32.20 mac_net12
```
- node-1

```
[root@node-2 ~]# docker run -itd --name bbox-11 --ip=172.16.11.11 --network mac_net11 busybox
[root@node-2 ~]# docker run -itd --name bbox-12 --ip=172.16.12.11 --network mac_net12 busybox
```
- node-2

```
[root@node-2 ~]# docker run -itd --name bbox-21 --ip=172.16.11.12 --network mac_net11 busybox
[root@node-2 ~]# docker run -itd --name bbox-22 --ip=172.16.12.12 --network mac_net12 busybox
```
- node-1

```
[root@node-1 ~]# docker exec bbox-11 ping 172.16.11.12
PING 172.16.11.12 (172.16.11.12): 56 data bytes
64 bytes from 172.16.11.12: seq=0 ttl=64 time=0.867 ms
64 bytes from 172.16.11.12: seq=1 ttl=64 time=1.074 ms
64 bytes from 172.16.11.12: seq=2 ttl=64 time=1.145 ms
64 bytes from 172.16.11.12: seq=3 ttl=64 time=0.938 ms
^C
[root@node-1 ~]# docker exec bbox-12 ping 172.16.12.12
PING 172.16.12.12 (172.16.12.12): 56 data bytes
64 bytes from 172.16.12.12: seq=0 ttl=64 time=0.858 ms
64 bytes from 172.16.12.12: seq=1 ttl=64 time=1.140 ms
64 bytes from 172.16.12.12: seq=2 ttl=64 time=0.818 ms
64 bytes from 172.16.12.12: seq=3 ttl=64 time=1.056 ms
^C
```
- 在两台系统进行修改，添加网关，修改防火墙策略
- node-1中记得将ens32更换为ens33

 

       ifconfig ens32.10 172.16.10.1 netmask 255.255.255.0
        ifconfig ens32.20 172.16.20.1 netmask 255.255.255.0
        iptables -t nat -A POSTROUTING -o ens32.10 -j MASQUERADE
        iptables -t nat -A POSTROUTING -o ens32 -j MASQUERADE
        
        iptables -A FORWARD -i ens32.10 -o ens32 -m state --state RELATE,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i ens32 -o ens32.10 -m state --state RELATE,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i ens32.10 -o ens32 -j ACCEPT
        iptables -A FORWARD -i ens32 -o ens32.10 -j ACCEPT

# overlay
 **一、跨主机网络概述**
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819130602900.png)
**二、准备overlay环境**
为支持容器的跨主机通信，Docker提供了overlay driver。Docker overlay网络需要一个key-value数据库用于保存网络状态信息，包括Network、Endpoint、IP等。Consul、Etcd和ZooKeeper都是Docker支持的key-value软件，这里我们使用Consul


**1. 环境描述**
| 节点   | 系统版本  | docker版本     | 角色   | IP地址        |
| ------ | --------- | -------------- | ------ | ------------- |
| node-1 | centos7.4 | docker-18.03.0 | consul | 192.168.0.101 |
| node-2 | centos7.4 | docker-18.03.0 | host   | 192.168.0.102 |
| node-3 | centos7.4 | docker-18.03.0 | host   | 192.168.0.103 |


**2. 创建consul**

- node-1;

```
[root@node-1 ~]# docker run -d -p 8500:8500 -h consul --name consul progrium/consul -server -bootstrap
```
容器启动后可以通过192.168.0.101:8500访问到consul
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819224043952.png)
**3. 修改docker配置文件**
修改node-2和node-3的docker daemon的配置文件/etc/systemd/system/docker.service

```
[root@node-2 ~]# vim  /etc/systemd/system/docker.service
ExecStart=/usr/bin/dockerd  -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock --cluster-store=consul://192.168.0.101:8500 --cluster-advertise=ens32:2376
[root@node-2 ~]# systemctl daemon-reload
[root@node-2 ~]# systemctl restart docker
```
- -H ：tcp：允许tcp连接daemon
-H：unix：默认的socket连接方式，支持远程的同时，本地也可以连接
 -  --cluster-store 指定consul的地址
 -  --cluster-advertise 告知consul自己的连接地址

node-2和node-3会自动注册到consul数据库中。
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819225334857.png)

**三、创建overlay网络
1、在node-2中创建网络**
在node-2中创建overlay网络ov_net1

```
[root@node-2 ~]# docker network create -d overlay ov_net1
```
- -d overlay：指定driver为overlay

```
[root@node-2 ~]# docker network ls
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819225928983.png)

**2、node-3查看创建的网络**
注意到ov_net1的 SCOPE 为 global，而其他网络为 local 。在node-3上查看存在的网络:

```
[root@node-3 ~]# docker network ls
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819230148207.png)
node-3上也能看到ov_net1，只是因为创建ov_net1时将overlay网络信息存入了consul，node-3从consul读取到了新网络数据。之后ov_net1的任何变化都会同步到node-2和node-3.
**3、查看ov_net1详细信息**

```
[root@node-2 ~]# docker network inspect ov_net1
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819230439425.png)
IPAM 是指 IP Address Management，docker自动为 ov_net1 分配的 IP 空间为 10.0.0.0/24
**四、在overlay中运行容器**
**1、创建容器 bbox-1**
在 node-2 上运行一个 busybox 容器并连接到 ov_net1.

```
[root@node-2 ~]# docker run -itd --name bbox-1 --network ov_net1 busybox
```
**2、查看 bbox-1 网络配置**

```
[root@node-2 ~]# docker exec bbox-1 ip r
default via 172.18.0.1 dev eth1
10.0.0.0/24 dev eth0 scope link  src 10.0.0.2
172.18.0.0/16 dev eth1 scope link  src 172.18.0.2
```
- bbox-1 有两个网络接口，eth0 和 eth1
- eth0 IP 为 10.0.0.2，连接的是overlay网络 ov_net1 
- eth1 IP 为 172.18.0.2
- 容器的默认路由是走 eth1，其实，docker 会创建一个 bridge 网络 “docker_gwbridge”，为所有连接到 overlay 网络的容器提供访问外网的能力

```
[root@node-2 ~]# docker network ls
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819231543466.png)

```
[root@node-2 ~]# docker network inspect docker_gwbridge
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819232009799.png)
从 docker network inspect docker_gwbridge 输出可确认 docker_gwbridge 的 IP 地址范围是 172.18.0.0/16，当前连接的容器就是 bbox-1（172.18.0.2）
而且此网络的网关就是网桥 docker_gwbridge 的 IP 172.18.0.1

```
[root@node-2 ~]# ifconfig docker_gwbridge
docker_gwbridge: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.18.0.1  netmask 255.255.0.0  broadcast 172.18.255.255
        inet6 fe80::42:c5ff:fe45:937  prefixlen 64  scopeid 0x20<link>
        ether 02:42:c5:45:09:37  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
这样容器 bbox-1 就可以通过docker_gwbridge 访问外网

```
[root@node-2 ~]# docker exec bbox-1 ping -c 4 www.baidu.com
PING www.baidu.com (182.61.200.6): 56 data bytes
64 bytes from 182.61.200.6: seq=0 ttl=53 time=6.721 ms
64 bytes from 182.61.200.6: seq=1 ttl=53 time=7.954 ms
64 bytes from 182.61.200.6: seq=2 ttl=53 time=11.723 ms
64 bytes from 182.61.200.6: seq=3 ttl=53 time=15.105 ms

--- www.baidu.com ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 6.721/10.375/15.105 ms
```
**五、overlay网络连通性**
**1、node-3 中 运行 bbox-2**

```
[root@node-3 ~]# docker run -itd --name bbox-2 --network ov_net1 busybox
```
**2、查看 bbox-2 路由情况**

```
[root@node-3 ~]# docker exec bbox-2 ip r
default via 172.18.0.1 dev eth1
10.0.0.0/24 dev eth0 scope link  src 10.0.0.3
172.18.0.0/16 dev eth1 scope link  src 172.18.0.2
```
**3、互通测试**

```
[root@node-3 ~]# docker exec bbox-2 ping -c 4 10.0.0.2
PING 10.0.0.2 (10.0.0.2): 56 data bytes
64 bytes from 10.0.0.2: seq=0 ttl=64 time=2.628 ms
64 bytes from 10.0.0.2: seq=1 ttl=64 time=1.004 ms
64 bytes from 10.0.0.2: seq=2 ttl=64 time=1.277 ms
64 bytes from 10.0.0.2: seq=3 ttl=64 time=1.505 ms

--- 10.0.0.2 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 1.004/1.603/2.628 ms
```
可见 overlay 网络中的容器可以直接通信，同时docker也实现了DNS服务
**4、实现原理**
docker 会为每个 overlay 网络创建一个独立的 network namespace，其中会有一个 linux bridge br0， veth pair 一端连接到容器中（即 eth0），另一端连接到 namespace 的 br0 上。
br0 除了连接所有的 veth pair，还会连接一个 vxlan 设备，用于与其他 host 建立 vxlan tunnel。容器之间的数据就是通过这个 tunnel 通信的。逻辑网络拓扑结构如图所示：
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190819233352547.png)

```
[root@node-2 ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
docker0         8000.024217edc413       no
docker_gwbridge         8000.0242c5450937       no              vethc59120e
virbr0          8000.525400b76fd4       yes             virbr0-nic
[root@node-3 ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
docker0         8000.0242ef3c7df7       no
docker_gwbridge         8000.0242c81afaee       no              vethf4562a9
virbr0          8000.525400c28478       yes             virbr0-nic
```
要查看 overlay 网络的 namespace 可以在 node-2 和 node-3 上执行 ip netns（请确保在此之前执行过 ln -s /var/run/docker/netns /var/run/netns），可以看到两个 node 上有一个相同的 namespace "1-dd91de7599"

```
[root@node-2 ~]# ln -s /var/run/docker/netns /var/run/netns
[root@node-2 ~]# ip netns
6889f61efc4b (id: 1)
1-dd91de7599 (id: 0)
```

```
[root@node-3 ~]# ln -s /var/run/docker/netns /var/run/netns
[root@node-3 ~]# ip netns
8e4722847745 (id: 1)
1-dd91de7599 (id: 0)
```
"1-dd91de7599" 这就是 ov_net1 的 namespace，查看 namespace 中的 br0 上的设备

```
[root@node-2 ~]# ip netns exec 1-dd91de7599 brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.0e7576c7c035       no              veth0
                                                        vxlan0
```
**六、overlay网络隔离**
不同的 overlay 网络是相互隔离的。我们创建第二个 overlay 网络 ov_net2 并运行容器 bbox-3
**1、创建网络 ov_net2**

```
[root@node-2 ~]# docker network create -d overlay ov_net2
```
**2、启动容器 bbox-3**

```
[root@node-2 ~]# docker run -itd --name bbox-3 --network ov_net2 busybox
```
**3、查看 bbox-3 网络**
bbox-3 分配到的 IP 是 10.0.1.2，尝试 ping bbox-1（10.0.0.2）

```
[root@node-2 ~]# docker exec -it bbox-3 ip r
default via 172.18.0.1 dev eth1
10.0.1.0/24 dev eth0 scope link  src 10.0.1.2
172.18.0.0/16 dev eth1 scope link  src 172.18.0.3
```

```
[root@node-2 ~]# docker exec -it bbox-3 ping -c 4 10.0.0.2
PING 10.0.0.2 (10.0.0.2): 56 data bytes

--- 10.0.0.2 ping statistics ---
4 packets transmitted, 0 packets received, 100% packet loss
[root@node-2 ~]# docker exec -it bbox-3 ping -c 4 172.18.0.2
PING 172.18.0.2 (172.18.0.2): 56 data bytes

--- 172.18.0.2 ping statistics ---
4 packets transmitted, 0 packets received, 100% packet loss
```
ping 失败，可见不同 overlay 网络之间是隔离的，即使通过 docker_gwbridge 也不能通信
如果要实现 bbox-3 和 bbox-1 通信，可以将   bbox-3 也连接到 ov_net1
这时 bbox-3 同时连接到了 ov_net1 和 ov_net2 上

```
[root@node-2 ~]# docker network connect ov_net1 bbox-3
[root@node-2 ~]# docker exec bbox-3 ip r
default via 172.18.0.1 dev eth1
10.0.0.0/24 dev eth2 scope link  src 10.0.0.4
10.0.1.0/24 dev eth0 scope link  src 10.0.1.2
172.18.0.0/16 dev eth1 scope link  src 172.18.0.3
[root@node-2 ~]# docker exec bbox-3 ping -c 4 10.0.0.2
PING 10.0.0.2 (10.0.0.2): 56 data bytes
64 bytes from 10.0.0.2: seq=0 ttl=64 time=0.184 ms
64 bytes from 10.0.0.2: seq=1 ttl=64 time=0.158 ms
64 bytes from 10.0.0.2: seq=2 ttl=64 time=0.162 ms
64 bytes from 10.0.0.2: seq=3 ttl=64 time=0.093 ms

--- 10.0.0.2 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.093/0.149/0.184 ms
```
docker 默认为 overlay 网络分配 24 位掩码的子网（10.0.X.0/24），所有主机共享这个 subnet，容器启动时会顺序从此空间分配 IP。当然我们也可以通过 --subnet 指定 IP 空间。

```
docker network create -d overlay --subnet 10.22.1.0/24 ov_net
```