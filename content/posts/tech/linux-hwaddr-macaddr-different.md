---
title: "linux | hwaddr 和 macaddr 的区别" 
date: 2021-07-01
lastmod: 2024-01-28
tags:
  - linux
keywords:
  - linux
  - hwaddr
  - macaddr
description: "" 
cover:
    image: "images/default-cover.webp" 
---

# 0 前言

本文参考以下链接:

- [网卡的 HWADDR 和 MACADDR 的区别](https://blog.csdn.net/rikeyone/article/details/108406865)
- [LINUX 系统中 HWaddr 和 macaddr 什么区别](https://zhidao.baidu.com/question/505133906.html)
- [Linux 永久生效 MAC](https://blog.csdn.net/caize340724/article/details/100958968)

# 1 详解

环境：centos7.8

在 centos 中可以在如下文件中查看一个 NIC 的配置 ： /etc/sysconfig/network-scripts/ifcfg-N

HWADDR=, 其中 以 AA:BB:CC:DD:EE:FF 形式的以太网设备的硬件地址.在有多个网卡设备的机器上，这个字段是非常有用的，它保证设备接口被分配了正确的设备名 ，而不考虑每个网卡模块被配置的加载顺序.这个字段不能和 MACADDR 一起使用.

MACADDR=, 其中 以 AA:BB:CC:DD:EE:FF 形式的以太网设备的硬件地址.在有多个网卡设备的机器上.这个字段用于给一个接口分配一个 MAC 地址，覆盖物理分配的 MAC 地址 . *这个字段不能和 HWADDR 一起使用*.

简单总结一下：

1. MACADDR 是系统的网卡物理地址，因为在接收数据包时需要根据这个值来做包过滤。
2. HWADDR 是网卡的硬件物理地址，只有厂家才能修改
3. 可以用 MACADDR 来覆盖 HWADDR，但这两个参数不能同时使用
4. ifconfig 和 nmcli 等网络命令中显示的物理地址其实是 MACADDR 的值，虽然显示的名称写的是 HWADDR(ether)。

![image-20210729101107333](/images/image-20210729101107333.png)

修改网卡的 mac 地址

```plaintext
#sudo vim  /etc/sysconfig/network-scripts/ifcfg-ens32
注释其中的"HWADDR=xx:xx:xx:xx:xx:xx"
添加或者修改"MACADDR=xx:xx:xx:xx:xx:xx"
 
如果没有删除或者注释掉HWADDR，当HWADDR与MACADDR地地不同时，启动不了网络服务的提示：　“Bringing up interface eth0: Device eth0 has different MAC address than expected,ignoring.”
故正确的操作是将HWADDR删除或注释掉，改成MACADDR
```

- 查看系统初始的 mac 地址即 HWADDR

把配置文件中的 MACADDR 注释或者删除掉，不用配置 HWADDR，重启网络服务后用命令查看到的 mac 地址就是网卡的 HWADDR

以上
