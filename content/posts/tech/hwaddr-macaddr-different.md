---
title: "hwaddr和macaddr的区别" 
date: 2021-07-01
lastmod: 2021-07-01
tags: 
- linux
keywords:
- linux
- hwaddr
- macaddr
description: "" 
cover:
    image: "" 
---
- 环境：centos7.8

在centos中可以在如下文件中查看一个NIC的配置 ： /etc/sysconfig/network-scripts/ifcfg-N

HWADDR=, 其中 以AA:BB:CC:DD:EE:FF形式的以太网设备的硬件地址.在有多个网卡设备的机器上，这个字段是非常有用的，它保证设备接口被分配了正确的设备名 ，而不考虑每个网卡模块被配置的加载顺序.这个字段不能和MACADDR一起使用. 

MACADDR=, 其中 以AA:BB:CC:DD:EE:FF形式的以太网设备的硬件地址.在有多个网卡设备的机器上.这个字段用于给一个接口分配一个MAC地址，覆盖物理分配的MAC地址 . *这个字段不能和HWADDR一起使用*.

**简单总结一下：**

1. MACADDR是**系统的网卡物理地址**，因为在接收数据包时需要根据这个值来做包过滤。
2. HWADDR是**网卡的硬件物理地址**，只有厂家才能修改
3. 可以用MACADDR来覆盖HWADDR，但这两个参数不能同时使用
4. ifconfig和nmcli等网络命令中显示的物理地址其实是MACADDR的值，虽然显示的名称写的是HWADDR(ether)。

![image-20210729101107333](https://image.lvbibir.cn/blog/image-20210729101107333.png)

修改网卡的mac地址

```
#sudo vim  /etc/sysconfig/network-scripts/ifcfg-ens32
注释其中的"HWADDR=xx:xx:xx:xx:xx:xx"
添加或者修改"MACADDR=xx:xx:xx:xx:xx:xx"
 
如果没有删除或者注释掉HWADDR，当HWADDR与MACADDR地地不同时，启动不了网络服务的提示：　“Bringing up interface eth0: Device eth0 has different MAC address than expected,ignoring.”
故正确的操作是将HWADDR删除或注释掉，改成MACADDR
```

- 查看系统初始的mac地址即HWADDR

把配置文件中的MACADDR注释或者删除掉，不用配置HWADDR，重启网络服务后用命令查看到的mac地址就是网卡的HWADDR



# 参考

https://blog.csdn.net/rikeyone/article/details/108406865

https://zhidao.baidu.com/question/505133906.html

https://blog.csdn.net/caize340724/article/details/100958968?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_title~default-1.control&spm=1001.2101.3001.4242
