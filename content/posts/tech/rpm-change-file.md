---
title: "通过反编译修改 rpm 包内的文件" 
date: 2021-12-01
lastmod: 2024-01-28
tags:
  - linux
keywords:
  - linux
  - rpm
description: "" 
cover:
    image: "images/cover-default.webp" 
---

# 0 前言

本文参考以下链接:

- [修改 rpm 中的文件重新打包](https://www.cnblogs.com/felixzh/p/10564895.html)

要修改 rpm 包中的文件，对于自己编译的 rpm 包，只需要在源码中修改好然后重新编译即可。而对于并不是自己编译的 rpm 包，且不熟悉编译环境的情况下，可以使用 rpm-build 和 rpm-rebuild 工具反编译来修改 rpm 中的文件

这里使用 ceph-mgr 软件包进行演示

# 1 安装 rpm-build&rpmrebuild

[rpmrebuild 官网](http://rpmrebuild.sourceforge.net) [rpmrebuild 下载地址](https://sourceforge.net/projects/rpmrebuild/files/rpmrebuild/2.15/rpmrebuild-2.15.tar.gz/download)

解压 rpmrebuild

```bash
[root@localhost ~]# mkdir -p /data/rpmbuild
[root@localhost ~]# tar zxf rpmrebuild-2.15.tar.gz  -C /data/rpmbuild/
[root@localhost ~]# ll /opt/rpmrebuild/
```

rpm-build 直接使用 yum 安装即可

```bash
[root@localhost ~]# yum install -y rpm-build
```

# 2 反编译&修改&重新编译

安装准备重新打包的 rpm

```bash
[root@localhost ~]# rpm -ivh ceph-mgr-12.2.13-0.el7.x86_64.rpm
```

查看 rpm 的安装名称

```bash
[root@localhost ~]# rpm -qa |grep mgr
ceph-mgr-12.2.13-0.el7.x86_64
```

配置 rpm 编译目录

```bash
vim ~/.rpmmacros

%_topdir /data/rpmbuild
```

创建目录

````
mkdir  /data/rpmbuild/BUILDROOT
mkdir  /data/rpmbuild/SPECS
````

执行脚本

```bash
[root@localhost ~]# cd /data/rpmbuild/
[root@localhost rpmbuild]# ./rpmrebuild.sh -s SPECS/abc.spec ceph-mgr
[root@localhost rpmbuild]# cd
```

解压原版 RPM 包

```bash
[root@localhost ~]# rpm2cpio ceph-mgr-12.2.13-0.el7.x86_64.rpm |cpio -idv
```

这里软件包解压后是两个目录

![image-20211206162209187](/images/image-20211206-162209.png)

根据需求替换修改解压后的文件，这里我替换两个文件 `/root/usr/lib64/ceph/mgr/dashboard/static/Ceph_Logo_Standard_RGB_White_120411_fa.png` 和 `/root/usr/lib64/ceph/mgr/dashboard/static/cover-mini.png`，并给原先的文件做一个备份

```bash
[root@localhost static]# mv cover-mini.png cover-mini.png.bak
[root@localhost static]# mv Ceph_Logo_Standard_RGB_White_120411_fa.png Ceph_Logo_Standard_RGB_White_120411_fa.png.bak
[root@localhost static]# cp kubernetes-logo.svg cover-mini.png
[root@localhost static]# cp kubernetes-logo.svg Ceph_Logo_Standard_RGB_White_120411_fa.png
```

修改 abc.spec 文件

找到原文件所在的行，添加备份文件

```bash
[root@localhost ~]# vim /data/rpmbuild/SPECS/abc.spec
```

![image-20211206164745856](/images/image-20211206-164745.png)

![image-20211206164843805](/images/image-20211206-164843.png)

这里创建的 bbb 目录是临时使用，编译过程肯定会报错，因为路径不对，根据报错修改路径

```bash
[root@localhost ~]# mkdir -p /data/rpmbuild/BUILDROOT/bbb/
[root@localhost ~]# mv ./usr/ /data/rpmbuild/BUILDROOT/bbb/
[root@localhost ~]# mv ./var/ /data/rpmbuild/BUILDROOT/bbb/
[root@localhost ~]# rpmbuild -ba /data/rpmbuild/SPECS/abc.spec
```

这里可以看到他请求的路径

![image-20211206163921954](/images/image-20211206-163921.png)

修改目录名

```bash
[root@localhost ~]# mv /data/rpmbuild/BUILDROOT/bbb/ /data/rpmbuild/BUILDROOT/ceph-mgr-12.2.13-0.el7.x86_64
```

再次编译

```bash
[root@localhost ~]# rpmbuild -ba /data/rpmbuild/SPECS/abc.spec
```

生成的 rpm 位置在/data/rpmbuild/RPMS/

![image-20211206163618292](/images/image-20211206-163618.png)

查看原 rpm 包的文件

```bash
[root@localhost ~]# cd /usr/lib64/ceph/mgr/dashboard/static
[root@localhost static]# ll
total 16
drwxr-xr-x 5 root root  117 Dec  6 03:11 AdminLTE-2.3.7
-rw-r--r-- 1 root root 4801 Jan 30  2020 Ceph_Logo_Standard_RGB_White_120411_fa.png
-rw-r--r-- 1 root root 1150 Jan 30  2020 favicon.ico
drwxr-xr-x 7 root root   94 Dec  6 03:11 libs
-rw-r--r-- 1 root root 1811 Jan 30  2020 cover-mini.png
```

安装新 rpm 包，查看文件

```bash
[root@localhost ~]# cd /data/rpmbuild/RPMS/x86_64
[root@localhost x86_64]# rpm -e --nodeps ceph-mgr
[root@localhost x86_64]# rpm -ivh ceph-mgr-12.2.13-0.el7.x86_64.rpm
[root@localhost x86_64]# cd /usr/lib64/ceph/mgr/dashboard/static
[root@localhost static]# ll
total 24
drwxr-xr-x 5 root root  117 Dec  6 03:53 AdminLTE-2.3.7
-rw-r--r-- 1 root root 1877 Dec  6 03:44 Ceph_Logo_Standard_RGB_White_120411_fa.png
-rw-r--r-- 1 root root 4801 Dec  6 03:41 Ceph_Logo_Standard_RGB_White_120411_fa.png.bak
-rw-r--r-- 1 root root 1150 Dec  6 03:41 favicon.ico
drwxr-xr-x 7 root root   94 Dec  6 03:53 libs
-rw-r--r-- 1 root root 1877 Dec  6 03:44 cover-mini.png
-rw-r--r-- 1 root root 1811 Dec  6 03:41 cover-mini.png.bak
```

至此，rpm 包中的文件修改以及重新打包的所有步骤都已完成

以上
