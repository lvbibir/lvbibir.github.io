---
title: "glibc 误升级后修复" 
date: 2022-07-14
lastmod: 2022-07-14
tags: 
- linux
- 故障处理
keywords:
- linux
- glibc
- 故障处理
description: "记录一下在 OpenEuler 20.03 LTS aarch64 系统上误操作升级了 glibc 后紧急修复的步骤" 
cover:
    image: "" 
---

# 起因

在使用 cephadm 安装 ceph v16.2 时升级了 python，系统默认版本是 3.7.4 ，升级后版本是 3.8.5，glibc 作为依赖同时进行了升级，系统默认版本是 2.28 ，升级后版本是 2.31，幸好记录及时，截图留存了软件包升级信息，如下

> 在没有十分把握的情况下不要用 yum install -y，使用 yum install 先判断好依赖安装带来的影响

![image-20220714155604727](https://image.lvbibir.cn/blog/image-20220714155604727.png)

升级过程未出任何问题，便没在意，可是后续 openssh 由于 glibc 的升级导致连接失败，一番 baidu 加 google 未解决 openssh 连接问题，于是便着手开始降级 glibc 至系统默认版本，从系统镜像中找到 glibc 相关的三个软件包

由于是版本降级，脑子一热便采用 `rpm -Uvh --nodeps glibc*` 方式强制安装，至此，<font color='red'>系统崩溃</font>

系统几乎所有命令都无法使用，报错如下

![image-20220714162721479](https://image.lvbibir.cn/blog/image-20220714162721479.png)

出现这个问题的原因大致是因为强制安装并未完全成功，lib64 一些相关的库文件软链接丢失

```
[root@localhost ~]# ls -l /lib64/libc.so.6
lrwxrwxrwx 1 root root 12  7月 14 14:43 /lib64/libc.so.6 -> libc-2.28.so # 恢复前这里是 libc-2.31.so
```

在强制安装 glibc-2.28 时， libc-2.31.so 已经被替换成了 libc-2.28.so ，由于安装失败  libc.so.6 链接到的还是 libc-2.31.so，自然会报错 `no such file` 

# 恢复

系统绝大部分命令都是依赖 libc.so.6 的，我们可以通过  `export LD_PRELOAD="库文件路径"`  设置优先使用的库

```
export LD_PRELOAD=/lib64/libc-2.28.so
```

此时 ls 、cd、mv 等基础命令以及最重要的 ln 链接命令已经可以使用了，接下来就是恢复软链接

```
rm -f /lib64/libc.so.6
ln -s /lib64/libc-2.28.so /lib64/libc.so.6
```

但是 yum 命令依赖的几个库软链接还没有恢复，按照报错提示跟上述步骤一样，先删除掉依赖的库文件，再重新软链接过去

之后就是重新 yum localinstall 安装一下未安装成功的 glic ，之前强制安装时已经将高版本的 glibc 清理掉了，这里重新安装很顺利 

> 也许之前使用 yum localinstall 安装可能就不会出现这个问题了，rpm --nodeps 也要少用~

```
yum localinstall glibc*
```

软件包安装过程中没有报错，经测试系统一切正常，openssh 也可以正常连接了

以上，系统恢复正常





















