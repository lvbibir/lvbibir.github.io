---
title: "centos7 | 修改网卡名称" 
date: 2022-02-01
lastmod: 2024-01-26
tags: 
  - linux
  - centos
keywords:
  - linux
  - centos
  - network
  - grub
description: "介绍如何在 centos7 的系统中通过配置网络规则命名文件的方式修改网卡的名称" 
cover:
    image: "https://image.lvbibir.cn/blog/default-cover.webp" 
---

# 0 前言

在使用 kolla-ansible 部署多节点 openstack 时，所有节点的外网网卡名称和管理网卡名称需要一样，其中两台是型号相同的物理机，网卡名无需变动，第三台是虚拟机，默认是 `ens*` 形式的网卡，需要改成 `enp*s*f*` 的格式

本文参考以下链接:

- [How to change a network interface name on CentOS 7](https://www.xmodulo.com/change-network-interface-name-centos7.html)

# 1 修改配置文件

```bash
vim /etc/sysconfig/network-scripts/ifcfg-ens32
```

![image-20220217101218208](https://image.lvbibir.cn/blog/image-20220217101218208.png)

# 3 配置网络规则命名文件

```bash
vim /etc/udev/rules.d/70-persistent-ipoib.rules
# 添加如下行，mac 地址自行修改
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="00:0c:29:bc:1e:01", ATTR{type}=="1", KERNEL=="eth*", NAME="enp11s0f0"
```

# 4 配置 grub 并重启

```bash
vim /etc/default/grub
# 修改如下行
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=centos/root net.ifnames=0 rd.lvm.lv=centos/swap rhgb quiet"
```

![image-20220217101742169](https://image.lvbibir.cn/blog/image-20220217101742169.png)

```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```

![image-20220217101827575](https://image.lvbibir.cn/blog/image-20220217101827575.png)

之后直接 reboot 重启系统

![image-20220217101942955](https://image.lvbibir.cn/blog/image-20220217101942955.png)

以上
