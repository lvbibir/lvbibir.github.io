---
title: "编译安装crash(aarch64平台)" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- linux
- aarch64
keywords:
- linux
- aarch64
- crash
- 鲲鹏cpu
description: "" 
cover:
    image: "" 
---

# 环境：

操作系统：isoft-serveros-v5.1 aarch64版

软件版本：crash-7.2.8

cpu：华为鲲鹏920

## 软件包下载地址
https://ftp.gnu.org/gnu/termcap/termcap-1.3.tar.gz
https://github.com/crash-utility/crash/archive/refs/tags/7.2.8.tar.gz
https://ftp.gnu.org/gnu/gdb/gdb-7.6.tar.gz

# 1、安装 termcap
按照 https://blog.csdn.net/u010241497/article/details/82998887 中的方法修改tparam.c文件中的代码
```
./configure && make && make install
```

# 2、安装ncurses
挂载本地dnf源略

```
dnf install ncurses-libs
dnf install ncurses-devel
```

# 3、安装gbd

```
tar zxf  gdb-7.6.tar.gz
cd gdb-7.6
./configure
vim Makefile
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20210629164240551.png)
添加上述选项，跳过编译中的警告
```
make && make install
```

# 4、安装crash

```
tar zxf crash-7.2.8.tar.gz
cd crash-7.2.8/
make target=arm64
```