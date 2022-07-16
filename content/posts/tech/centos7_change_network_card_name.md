---
title: "centos7修改网卡名称" 
date: 2022-02-01
lastmod: 2022-02-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- centos
description: "" 
weight: 
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: "" #图片路径：posts/tech/文章1/picture.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
---
# 前言

在使用kolla-ansible部署多节点openstack时，所有节点的外网网卡名称和管理网卡名称需要一样，其中两台是型号相同的物理机，网卡名无需变动，第三台是虚拟机，默认是ens\*形式的网卡，需要改成enp\*s\*f\*的格式

# 修改配置文件

```
vim /etc/sysconfig/network-scripts/ifcfg-ens32
```

![image-20220217101218208](https://image.lvbibir.cn/blog/image-20220217101218208.png)

# 配置网络规则命名文件

```
vim /etc/udev/rules.d/70-persistent-ipoib.rules
# 添加如下行，mac地址自行修改
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="00:0c:29:bc:1e:01", ATTR{type}=="1", KERNEL=="eth*", NAME="enp11s0f0"
```

# 配置grub并重启

```
vim /etc/default/grub
# 修改如下行
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=centos/root net.ifnames=0 rd.lvm.lv=centos/swap rhgb quiet"
```

![image-20220217101742169](https://image.lvbibir.cn/blog/image-20220217101742169.png)

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

![image-20220217101827575](https://image.lvbibir.cn/blog/image-20220217101827575.png)

之后直接reboot重启系统

![image-20220217101942955](https://image.lvbibir.cn/blog/image-20220217101942955.png)

# 参考

https://www.xmodulo.com/change-network-interface-name-centos7.html