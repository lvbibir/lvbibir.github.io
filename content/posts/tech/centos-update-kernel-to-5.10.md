---
title: "centos7.5 升级内核至 5.10" 
date: 2022-01-01
lastmod: 2022-01-01
tags: 
- linux
- centos
keywords:
- linux
- centos
- kernel
description: "" 
cover:
    image: "" 
---
查看内核版本

```
[dpl@test1 ~]$ cat /etc/redhat-release 
Red Hat Enterprise Linux Server release 7.5 (Maipo)
```

下载内核

https://elrepo.org/linux/kernel/el7/x86_64/RPMS/ 下载自己所需的内核
更新版本：5.10.81

内核版本介绍：


| lt   | longterm的缩写 | 长期维护版 |
| ---- | -------------- | ---------- |
| ml | mainline的缩写 | 最新稳定版 |


使用 wget 命令下载内核 RPM 包

```
[dpl@test1 ~]# wget https://dl.lamp.sh/kernel/el7/kernel-ml-5.10.81-1.el7.x86_64.rpm
[dpl@test1 ~]# wget https://dl.lamp.sh/kernel/el7/kernel-ml-devel-5.10.81-1.el7.x86_64.rpm
```

安装内核

```
yum localinstall -y kernel-ml-5.10.81-1.el7.x86_64.rpm kernel-ml-devel-5.10.81-1.el7.x86_64.rpm
```

查看所有可用内核启动项

```
[dpl@test1 ~] awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
0 : CentOS Linux (5.10.81-1.el7.x86_64) 7 (Core)
1 : CentOS Linux (3.10.0-1160.21.1.el7.x86_64) 7 (Core)
2 : CentOS Linux (3.10.0-957.el7.x86_64) 7 (Core)
3 : CentOS Linux (0-rescue-9a4efd5deb094f5d8a9a259066ff4f3d) 7 (Core)
```

记下 5.11.9 内核前面的序号，修改启动项需要

修改默认启动项

默认启动项由`/etc/default/grub`中的 GRUB_DEFAULT 控制，如果 GRUB_DEFAULT=saved，则该参数将存在 /boot/grub2/grubenv

输入`grub2-editenv list`命令查看默认启动项

```
[root@localhost ~]# grub2-editenv list
saved_entry=CentOS Linux (3.10.0-1060.el7.x86_64) 7 (Core)
```

输入 grub2-set-default 命令修改默认启动项，0表示5.11.9内核的序号

```
[dpl@test1 ~]# grub2-set-default 0
```

再次查看默认启动项，发现默认启动项已经改成了0

```
10.81-1.el7.elrepo.x86_64

[dpl@test1 ~]# uname -r
5.10.81-1.el7.elrepo.x86_64
```


参考：https://blog.csdn.net/cqchengdan/article/details/106031823

