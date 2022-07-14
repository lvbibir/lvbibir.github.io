---
title: "glibc误升级后修复" 
date: 2022-07-14
lastmod: 2022-07-14
author: ["lvbibir"] 
categories: 
- 
tags: 
- pxe
description: "" #描述
weight: # 输入1可以顶置文章，用来给文章展示排序，不填就默认按时间排序
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

### 前言

记录一下在 OpenEuler 20.03 LTS aarch64 系统上误操作升级了 glibc 后紧急修复的步骤

### 起因

在使用 cephadm 安装 ceph v16.2 时升级了 python，系统默认版本是 3.7.4 ，升级后版本是 3.8.5，glibc 作为依赖同时进行了升级，系统默认版本是 2.28 ，升级后版本是 2.31，幸好记录及时，截图留存了软件包升级信息，如下

> 在没有十分把握的情况下不要用 yum install -y，使用 yum install 先判断好依赖安装带来的影响

![image-20220714155604727](https://image.lvbibir.cn/blog/image-20220714155604727.png)

升级过程未出任何问题，便没在意，可是后续 openssh 由于 glibc 的升级导致连接失败，一番 baidu 加 google 未解决 openssh 连接问题，于是便着手开始降级 glibc 至系统默认版本，从系统镜像中找到 glibc 相关的三个软件包

由于是版本降级，便采用 `rpm -Uvh --nodeps glibc*` 方式强制安装，至此，<font color='red'>系统崩溃</font>

系统几乎所有命令都无法使用，报错如下

![image-20220714162721479](https://image.lvbibir.cn/blog/image-20220714162721479.png)

出现这个问题的原因大致是因为强制安装并未完全成功，lib64 一些相关的库文件软链接丢失

```
[root@localhost ~]# ls -l /lib64/libc.so.6
lrwxrwxrwx 1 root root 12  7月 14 14:43 /lib64/libc.so.6 -> libc-2.28.so
```

这里出问题前软链接，链接到的还是 libc-2.31.so 





















