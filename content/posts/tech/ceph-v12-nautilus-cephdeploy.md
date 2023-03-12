---
title: "centos7 部署 ceph-v12 (nautilus) + dashboard" 
date: 2021-12-01
lastmod: 2021-12-01
tags: 
- linux
- centos
- ceph
keywords:
- linux
- centos
- ceph
description: "介绍在centos7环境中通过ceph-deploy部署ceph集群（nautilus）和可视化的dashboard" 
cover:
    image: "https://image.lvbibir.cn/blog/ceph.png" 
---
# 基本环境

- 物理环境：Vmware Workstaion
- 系统版本：Centos-7.9-Minimal
- 两个osd节点添加一块虚拟磁盘，建议不小于20G

| ip              | hostname                | services                        |
| --------------- | ----------------------- | ------------------------------- |
| 192.168.150.101 | ceph-admin(ceph-deploy) | mds1、mon1、mon_mgr、ntp-server |
| 192.168.150.102 | ceph-node1              | osd1                            |
| 192.168.150.103 | ceph-node2              | osd2                            |

# 前期配置

**以下操作所有节点都需执行**

**修改主机名**

```bash
hostnamectl set-hostname ceph-admin
bash
hostnamectl set-hostname ceph-node1
bash
hostnamectl set-hostname ceph-node2
bash
```

**修改hosts文件**

```
vim /etc/hosts

192.168.150.101 ceph-admin
192.168.150.102 ceph-node1
192.168.150.103 ceph-node2
```

**关闭防火墙和selinux、修改yum源及安装一些常用工具**

这里提供了一个简单的系统初始化脚本用来做上述操作，适用于Centos7

```
chmod 777 init.sh
./init.sh
```

```bash
#!/bin/bash

echo "========start============="
sed -i '/SELINUX/s/enforcing/disabled/' /etc/sysconfig/selinux
setenforce 0
iptables -F
systemctl disable firewalld
systemctl stop firewalld

echo "====dowload wget========="
yum install -y wget

echo "====backup repo==========="
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/ 

echo "====dowload aliyum-repo===="
wget http://mirrors.aliyun.com/repo/Centos-7.repo -O /etc/yum.repos.d/Centos-Base.repo
wget http://mirrors.aliyun.com/repo/epel-7.repo -O /etc/yum.repos.d/epel.repo

echo "====upgrade yum============"
yum clean all
yum makecache fast

echo "====dowload tools========="
yum install -y net-tools vim bash-completion

echo "=========finish============"
```

**每个节点安装和配置NTP（官方推荐的是集群的所有节点全部安装并配置 NTP，需要保证各节点的系统时间一致。没有自己部署ntp服务器，就在线同步NTP）**

```bash
yum install chrony -y
systemctl start chronyd
systemctl enable chronyd
```

ceph-admin

```
vim /etc/chrony.conf
systemctl restart chronyd
chronyc sources
```

这里使用阿里云的ntp服务器

![image-20211206142640253](https://image.lvbibir.cn/blog/image-20211206142640253.png)

ceph-node1、ceph-node2

```
vim /etc/chrony.conf
systemctl restart chronyd
chronyc sources
```

这里指定ceph-admin节点的ip即可

![image-20211206142908590](https://image.lvbibir.cn/blog/image-20211206142908590.png)

**添加ceph源**

```bash
yum -y install epel-release
rpm --import http://mirrors.163.com/ceph/keys/release.asc
rpm -Uvh --replacepkgs http://mirrors.163.com/ceph/rpm-nautilus/el7/noarch/ceph-release-1-1.el7.noarch.rpm
```

```
[Ceph]
name=Ceph packages for $basearch
baseurl=http://download.ceph.com/rpm-nautilus/el7/$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc

[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://download.ceph.com/rpm-nautilus/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=http://download.ceph.com/rpm-nautilus/el7/SRPMS
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
```

# 磁盘准备

以下操作在osd节点（ceph-node1、ceph-node2）执行

```
# 检查磁盘
[root@ceph-node1 ~]# fdisk -l /dev/sdb

Disk /dev/sdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

# 格式化磁盘
[root@ceph-node1 ~]# parted -s /dev/sdb mklabel gpt mkpart primary xfs 0% 100%
[root@ceph-node1 ~]# mkfs.xfs /dev/sdb -f
meta-data=/dev/sdb               isize=512    agcount=4, agsize=1310720 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=5242880, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

查看磁盘格式
[root@ceph-node1 ~]# blkid -o value -s TYPE /dev/sdb
xfs
```

# 安装ceph集群

**配置ssh免密**

```bash
[root@ceph-admin ~]# ssh-keygen
# 一路回车
[root@ceph-admin ~]# ssh-copy-id root@ceph-node1
[root@ceph-admin ~]# ssh-copy-id root@ceph-node2
```

**安装ceph-deploy**

```bash
[root@ceph-admin ~]# yum install -y python2-pip
[root@ceph-admin ~]# yum install -y ceph-deploy
```

**创建文件夹用户存放集群文件**

```bash
[root@ceph-admin ~]# mkdir /root/my-ceph
[root@ceph-admin ~]# cd /root/my-ceph/
```

**创建集群（后面填写monit节点的主机名，这里monit节点和管理节点是同一台机器，即ceph-admin）**

```
[root@ceph-admin my-ceph]# ceph-deploy new ceph-admin

[ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
[ceph_deploy.cli][INFO  ] Invoked (2.0.1): /usr/bin/ceph-deploy new ceph-admin
[ceph_deploy.cli][INFO  ] ceph-deploy options:
[ceph_deploy.cli][INFO  ]  username                      : None
[ceph_deploy.cli][INFO  ]  func                          : <function new at 0x7f2217df3de8>
[ceph_deploy.cli][INFO  ]  verbose                       : False
[ceph_deploy.cli][INFO  ]  overwrite_conf                : False
[ceph_deploy.cli][INFO  ]  quiet                         : False
[ceph_deploy.cli][INFO  ]  cd_conf                       : <ceph_deploy.conf.cephdeploy.Conf instance at 0x7f221756e4d0>
[ceph_deploy.cli][INFO  ]  cluster                       : ceph
[ceph_deploy.cli][INFO  ]  ssh_copykey                   : True
[ceph_deploy.cli][INFO  ]  mon                           : ['ceph-admin']
[ceph_deploy.cli][INFO  ]  public_network                : None
[ceph_deploy.cli][INFO  ]  ceph_conf                     : None
[ceph_deploy.cli][INFO  ]  cluster_network               : None
[ceph_deploy.cli][INFO  ]  default_release               : False
[ceph_deploy.cli][INFO  ]  fsid                          : None
[ceph_deploy.new][DEBUG ] Creating new cluster named ceph
[ceph_deploy.new][INFO  ] making sure passwordless SSH succeeds
[ceph-admin][DEBUG ] connected to host: ceph-admin
[ceph-admin][DEBUG ] detect platform information from remote host
[ceph-admin][DEBUG ] detect machine type
[ceph-admin][DEBUG ] find the location of an executable
[ceph-admin][INFO  ] Running command: /usr/sbin/ip link show
[ceph-admin][INFO  ] Running command: /usr/sbin/ip addr show
[ceph-admin][DEBUG ] IP addresses found: [u'192.168.150.101']
[ceph_deploy.new][DEBUG ] Resolving host ceph-admin
[ceph_deploy.new][DEBUG ] Monitor ceph-admin at 192.168.150.101
[ceph_deploy.new][DEBUG ] Monitor initial members are ['ceph-admin']
[ceph_deploy.new][DEBUG ] Monitor addrs are ['192.168.150.101']
[ceph_deploy.new][DEBUG ] Creating a random mon key...
[ceph_deploy.new][DEBUG ] Writing monitor keyring to ceph.mon.keyring...
[ceph_deploy.new][DEBUG ] Writing initial config to ceph.conf...

```

**修改集群配置文件**

注意：mon_host必须和public network 网络是同网段内

```
[root@ceph-admin my-ceph]# vim ceph.conf
# 添加如下两行内容
......
public_network = 192.168.150.0/24
osd_pool_default_size = 2
```

**开始安装**

```bash
[root@ceph-admin my-ceph]# ceph-deploy install --release nautilus ceph-admin ceph-node1 ceph-node2

# 出现以下提示说明安装成功

[ceph-node2][DEBUG ] Complete!
[ceph-node2][INFO  ] Running command: ceph --version
[ceph-node2][DEBUG ] ceph version 12.2.13 (584a20eb0237c657dc0567da126be145106aa47e) nautilus (stable)
```

**初始化monit监控节点，并收集所有密钥**

```
[root@ceph-admin my-ceph]# ceph-deploy mon create-initial
[root@ceph-admin my-ceph]# ceph-deploy gatherkeys ceph-admin
```

**检查OSD节点上所有可用的磁盘**

```
[root@ceph-admin my-ceph]# ceph-deploy disk list ceph-node1 ceph-node2
```

**删除所有osd节点上的分区、准备osd及激活osd**

主机上有多块磁盘要作为osd时：`ceph-deploy osd create ceph-node21 --data /dev/sdb --data /dev/sdc`

```
[root@ceph-admin my-ceph]# ceph-deploy osd create ceph-node1 --data /dev/sdb
[root@ceph-admin my-ceph]# ceph-deploy osd create ceph-node2 --data /dev/sdb
```

**在两个osd节点上通过命令已显示磁盘已成功mount**

```
[root@ceph-node1 ~]# lsblk
NAME                                                                                                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                                                                                                     8:0    0   20G  0 disk
├─sda1                                                                                                  8:1    0    1G  0 part /boot
└─sda2                                                                                                  8:2    0   19G  0 part
  ├─centos-root                                                                                       253:0    0   17G  0 lvm  /
  └─centos-swap                                                                                       253:1    0    2G  0 lvm  [SWAP]
sdb                                                                                                     8:16   0   20G  0 disk
└─ceph--2bb0ec8d--547c--42c2--9858--08ccfd043bd4-osd--block--33e8dba4--6dfc--4753--b9ba--0d0c54166f0c 253:2    0   20G  0 lvm
sr0                             
```

**查看osd**

```
[root@ceph-admin my-ceph]# ceph-deploy disk list ceph-node1 ceph-node2
......
......
[ceph-node1][INFO  ] Disk /dev/mapper/ceph--2bb0ec8d--547c--42c2--9858--08ccfd043bd4-osd--block--33e8dba4--6dfc--4753--b9ba--0d0c54166f0c: 21.5 GB, 21470642176 bytes, 41934848 sectors
......
......
[ceph-node2][INFO  ] Disk /dev/mapper/ceph--f9a95e6c--fc7b--46b4--a835--dd997c0d6335-osd--block--db903124--4c01--40d7--8a58--b26e17c1db29: 21.5 GB, 21470642176 bytes, 41934848 sectors
```

**同步集群文件，这样就可以在所有节点执行ceph命令了**

```
[root@ceph-admin my-ceph]# ceph-deploy admin ceph-admin ceph-node1 ceph-node2
```

**在其他节点查看osd的目录树**

```
[root@ceph-node1 ~]# ceph osd tree
ID CLASS WEIGHT  TYPE NAME           STATUS REWEIGHT PRI-AFF
-1       0.03897 root default
-3       0.01949     host ceph-node1
 0   hdd 0.01949         osd.0           up  1.00000 1.00000
-5       0.01949     host ceph-node2
 1   hdd 0.01949         osd.1           up  1.00000 1.00000
```

**配置mgr**

```
[root@ceph-admin my-ceph]# ceph-deploy mgr create ceph-admin
```

**查看集群状态和集群service状态**

此时是HEALTH_WARN状态，是由于启用了不安全模式

```
[root@ceph-admin my-ceph]# ceph health
HEALTH_WARN mon is allowing insecure global_id reclaim
[root@ceph-admin my-ceph]# ceph -s
  cluster:
    id:     fd816347-598c-4ed6-b356-591a618a0bdc
    health: HEALTH_WARN
            mon is allowing insecure global_id reclaim

  services:
    mon: 1 daemons, quorum ceph-admin (age 3h)
    mgr: mon_mgr(active, since 17s)
    osd: 2 osds: 2 up (since 3m), 2 in (since 3m)

  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   2.0 GiB used, 38 GiB / 40 GiB avail
    pgs:
```

**禁用不安全模式**

```
[root@ceph-admin my-ceph]# ceph config set mon auth_allow_insecure_global_id_reclaim false
[root@ceph-admin my-ceph]# ceph health
HEALTH_OK
```

# 开启dashboard

```
[root@ceph-admin my-ceph]# yum install -y ceph-mgr-dashboard
[root@ceph-admin my-ceph]# ceph mgr module enable dashboard
# 创建自签证书
[root@ceph-admin my-ceph]# ceph dashboard create-self-signed-cert
# 创建密码文件
[root@ceph-admin my-ceph]# echo abc123 > ./dashboard_user_pw
# 创建dashboard的登录用户
[root@ceph-admin my-ceph]# ceph dashboard ac-user-create admin -i ./dashboard_user_pw administrator
{"username": "admin", "lastUpdate": 1646037503, "name": null, "roles": ["administrator"], "password": "$2b$12$jGsvau8jFMb4pDwLU/t8KO1sKvmBMcNUYycbXusmgkvTQzlzrMyKi", "email": null}
[root@ceph-admin my-ceph]# ceph mgr services
{
    "dashboard": "https://ceph-admin:8443/"
}
```

测试访问

![image-20220228164616847](https://image.lvbibir.cn/blog/image-20220228164616847.png)

![image-20220228164746181](https://image.lvbibir.cn/blog/image-20220228164746181.png)

上图中测试环境是win10+chrome，同事反应mac+chrome会出现无法访问的情况，原因是我们使用的自签证书，浏览器并不信任此证书，可以通过以下两种方式解决

1. 关闭dashboard的ssl访问

2. 下载证书配置浏览器信任证书

## 关闭dashboard的ssl访问

```
[root@ceph-admin my-ceph]# ceph config set mgr mgr/dashboard/ssl false
[root@ceph-admin my-ceph]# ceph mgr module disable dashboard
[root@ceph-admin my-ceph]# ceph mgr module enable dashboard
[root@ceph-admin my-ceph]# ceph mgr services
{
    "dashboard": "http://ceph-admin:8080/"
}
```

如果出现`Module 'dashboard' has failed: IOError("Port 8443 not free on '::'",)`这种报错，需要重启下mgr：`systemctl restart ceph-mgr@ceph-admin`

测试访问

![image-20220228171237208](https://image.lvbibir.cn/blog/image-20220228171237208.png)

## 开启rgw管理功能

默认object gateway功能没有开启

![](https://image.lvbibir.cn/blog/image-20220302111303281.png)

创建rgw实例

```
ceph-deploy rgw create ceph-admin
```

默认运行端口是7480

![image-20220302112418486](https://image.lvbibir.cn/blog/image-20220302112418486.png)

![image-20220302112515398](https://image.lvbibir.cn/blog/image-20220302112515398.png)

创建rgw用户

```
[root@ceph-admin my-ceph]# radosgw-admin user create --uid=rgw --display-name=rgw --system
```

![image-20220302111512864](https://image.lvbibir.cn/blog/image-20220302111512864.png)

提供dashboard证书

```
[root@ceph-admin my-ceph]# echo UI2T50HNZUCVVYYZNDHP > rgw_user_access_key
[root@ceph-admin my-ceph]# echo 11rg0WbXuh2Svexck3vJKs19u1UQINixDWIpN5Dq > rgw_user_secret_key
[root@ceph-admin my-ceph]# ceph dashboard set-rgw-api-access-key -i rgw_user_access_key
Option RGW_API_ACCESS_KEY updated
[root@ceph-admin my-ceph]# ceph dashboard set-rgw-api-secret-key -i rgw_user_secret_key
Option RGW_API_SECRET_KEY updated
```

禁用ssl

```
[root@ceph-admin my-ceph]# ceph dashboard set-rgw-api-ssl-verify False
Option RGW_API_SSL_VERIFY updated
```

启用rgw

```
[root@ceph-admin my-ceph]# ceph dashboard set-rgw-api-host 192.168.150.101
Option RGW_API_HOST updated
[root@ceph-admin my-ceph]# ceph dashboard set-rgw-api-port 7480
Option RGW_API_PORT updated
[root@ceph-admin my-ceph]# ceph dashboard set-rgw-api-scheme http
Option RGW_API_SCHEME updated
[root@ceph-admin my-ceph]# ceph dashboard set-rgw-api-user-id rgw
Option RGW_API_USER_ID updated
[root@ceph-admin my-ceph]# systemctl restart ceph-radosgw.target
```

验证

目前object gateway功能已成功开启

![image-20220302112635543](https://image.lvbibir.cn/blog/image-20220302112635543.png)

![image-20220302112655052](https://image.lvbibir.cn/blog/image-20220302112655052.png)

![image-20220302112707308](https://image.lvbibir.cn/blog/image-20220302112707308.png)

# 其他

## **清除ceph集群**

清除安装包

```
[root@ceph-admin ~]# ceph-deploy purge ceph-admin ceph-node1 ceph-node2
```

清除配置信息

```
[root@ceph-admin ~]# ceph-deploy purgedata ceph-admin ceph-node1 ceph-node2
[root@ceph-admin ~]# ceph-deploy forgetkeys
```

每个节点删除残留的配置文件

```
rm -rf /var/lib/ceph/osd/*
rm -rf /var/lib/ceph/mon/*
rm -rf /var/lib/ceph/mds/*
rm -rf /var/lib/ceph/bootstrap-mds/*
rm -rf /var/lib/ceph/bootstrap-osd/*
rm -rf /var/lib/ceph/bootstrap-mon/*
rm -rf /var/lib/ceph/tmp/*
rm -rf /etc/ceph/*
rm -rf /var/run/ceph/*
```

清理磁盘设备(/dev/mapper/ceph*)

```
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %
```

## dashboard无法访问的问题

在关闭dashboard的https后，出现了一个很奇怪的问题，使用chrome浏览器无法访问dashboard了，edge或者使用chrome无痕模式可以正常访问，期间尝试了各种方法包括重新配置dashboard和清理chrome浏览器的缓存和cookie等方式都没有解决问题，结果第二天起来打开环境一看自己好了（淦）

问题情况见下图

![GIF 2022-3-1 15-21-48](https://image.lvbibir.cn/blog/GIF%202022-3-1%2015-21-48.gif)

日志报错：

![image-20220302105649313](https://image.lvbibir.cn/blog/image-20220302105649313.png)

## 同步ceph配置文件

```
ceph-deploy --overwrite-conf config push ceph-node{1,2,3,4}
```

## 添加mon节点和mgr节点

```
ceph-deploy mon create ceph-node{1,2,3,4}
ceph-deploy mgr create ceph-node{1,2,3,4}
```

记得修改配置文件

![image-20220420102326624](http://image.lvbibir.cn/blog/image-20220420102326624.png)

之后同步配置文件

```
ceph-deploy --overwrite-conf config push ceph-node{1,2,3,4}
```

# 参考

https://www.cnblogs.com/kevingrace/p/9141432.html

https://www.cnblogs.com/weijie0717/p/8378485.html

https://www.cnblogs.com/weijie0717/p/8383938.html

https://blog.csdn.net/qq_40017427/article/details/106235456