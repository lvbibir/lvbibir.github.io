---
title: "关闭X服务本地监听的6000端口" 
date: 2022-01-01
lastmod: 2022-01-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- linux
- X
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

基于CVE-1999-0526漏洞的披露，对系统X服务的6000端口进行关闭

有三种方式：

- 修改系统/usr/bin/X内容，增加nolisten参数
- 开启系统防火墙，关闭6000端口的对外访问
- 禁用桌面(runlevel-5)，开机进入字符界面(runlevel-3)

# 修改/usr/bin/X脚本

## 关闭

```
rm -f /usr/bin/X

vim /usr/bin/X

###################
添加如下内容
#!/bin/bash
exec /usr/bin/Xorg "$@" -nolisten tcp
exit 0
####################

chmod 777 /usr/bin/X

kill -9 进程号 # ps -elf |grep X 显示的进程号
```

![image-20220214130429656](https://image.lvbibir.cn/blog/image-20220214130429656.png)

## 恢复

```
rm -f /usr/bin/X
ln -s /usr/bin/Xorg /usr/bin/X
kill -9 进程号 # pe -elf | grep Xorg 显示的进程号
```

![image-20220214130544760](https://image.lvbibir.cn/blog/image-20220214130544760.png)

<font color='red'>**在测试过程中出现过杀死X服务进程后没有自启的情况，可尝试使用 init 3 && init 5 尝试重新启动X服务**</font>

# 修改防火墙方式

```
# 开启除6000端口以外的所有端口(6000端口无法访问)
systemctl start firewalld
firewall-cmd --permanent --zone=public --add-port=1-65535/udp
firewall-cmd --permanent --zone=public --add-port=1-5999/tcp
firewall-cmd --permanent --zone=public --add-port=6001-65535/tcp
firewall-cmd --reload
firewall-cmd --list-all

# 恢复（6000端口可以访问）
firewall-cmd --permanent --zone=public --add-port=6000/tcp
firewall-cmd --reload
firewall-cmd --list-all
```

# 参考

https://bugzilla.redhat.com/show_bug.cgi?id=1647621
