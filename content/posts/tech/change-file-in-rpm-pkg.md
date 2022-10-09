---
title: "通过反编译修改rpm包内的文件" 
date: 2021-12-01
lastmod: 2021-12-01
tags: 
- linux
keywords:
- linux
- rpm
description: "" 
cover:
    image: "" 
---
# 前言

要修改rpm包中的文件，对于自己编译的rpm包，只需要在源码中修改好然后重新编译即可。而对于并不是自己编译的rpm包，且不熟悉编译环境的情况下，可以使用rpm-build和rpm-rebuild工具反编译来修改rpm中的文件

这里使用ceph-mgr软件包进行演示

# 安装rpm-build&rpmrebuild

rpmrebuild官网：http://rpmrebuild.sourceforge.net

rpmrebuild下载地址：https://sourceforge.net/projects/rpmrebuild/files/rpmrebuild/2.15/rpmrebuild-2.15.tar.gz/download

解压rpmrebuild

```
[root@localhost ~]# mkdir -p /data/rpmbuild
[root@localhost ~]# tar zxf rpmrebuild-2.15.tar.gz  -C /data/rpmbuild/
[root@localhost ~]# ll /opt/rpmrebuild/
```

rpm-build直接使用yum安装即可

```
[root@localhost ~]# yum install -y rpm-build
```

# 反编译&修改&重新编译

安装准备重新打包的rpm

```
[root@localhost ~]# rpm -ivh ceph-mgr-12.2.13-0.el7.x86_64.rpm
```

查看rpm的安装名称

```
[root@localhost ~]# rpm -qa |grep mgr
ceph-mgr-12.2.13-0.el7.x86_64
```

配置rpm编译目录

```
vim ~/.rpmmacros

%_topdir /data/rpmbuild
```

创建目录

````
mkdir  /data/rpmbuild/BUILDROOT
mkdir  /data/rpmbuild/SPECS
````

执行脚本

```
[root@localhost ~]# cd /data/rpmbuild/
[root@localhost rpmbuild]# ./rpmrebuild.sh -s SPECS/abc.spec ceph-mgr
[root@localhost rpmbuild]# cd
```

解压原版RPM包

```
[root@localhost ~]# rpm2cpio ceph-mgr-12.2.13-0.el7.x86_64.rpm |cpio -idv
```

这里软件包解压后是两个目录

![image-20211206162209187](https://image.lvbibir.cn/blog/image-20211206162209187.png)

根据需求替换修改解压后的文件，这里我替换两个文件`/root/usr/lib64/ceph/mgr/dashboard/static/Ceph_Logo_Standard_RGB_White_120411_fa.png`和`/root/usr/lib64/ceph/mgr/dashboard/static/logo-mini.png`，并给原先的文件做一个备份

```
[root@localhost static]# mv logo-mini.png logo-mini.png.bak
[root@localhost static]# mv Ceph_Logo_Standard_RGB_White_120411_fa.png Ceph_Logo_Standard_RGB_White_120411_fa.png.bak
[root@localhost static]# cp kubernetes-logo.svg logo-mini.png
[root@localhost static]# cp kubernetes-logo.svg Ceph_Logo_Standard_RGB_White_120411_fa.png
```

修改abc.spec文件

找到原文件所在的行，添加备份文件

```
[root@localhost ~]# vim /data/rpmbuild/SPECS/abc.spec
```

![image-20211206164745856](https://image.lvbibir.cn/blog/image-20211206164745856.png)

![image-20211206164843805](https://image.lvbibir.cn/blog/image-20211206164843805.png)

这里创建的bbb目录是临时使用，编译过程肯定会报错，因为路径不对，根据报错修改路径

```
[root@localhost ~]# mkdir -p /data/rpmbuild/BUILDROOT/bbb/
[root@localhost ~]# mv ./usr/ /data/rpmbuild/BUILDROOT/bbb/
[root@localhost ~]# mv ./var/ /data/rpmbuild/BUILDROOT/bbb/
[root@localhost ~]# rpmbuild -ba /data/rpmbuild/SPECS/abc.spec
```

这里可以看到他请求的路径

![image-20211206163921954](https://image.lvbibir.cn/blog/image-20211206163921954.png)

修改目录名

```
[root@localhost ~]# mv /data/rpmbuild/BUILDROOT/bbb/ /data/rpmbuild/BUILDROOT/ceph-mgr-12.2.13-0.el7.x86_64
```

再次编译

```
[root@localhost ~]# rpmbuild -ba /data/rpmbuild/SPECS/abc.spec
```

生成的rpm位置在/data/rpmbuild/RPMS/

![image-20211206163618292](https://image.lvbibir.cn/blog/image-20211206163618292.png)

查看原rpm包的文件

```
[root@localhost ~]# cd /usr/lib64/ceph/mgr/dashboard/static
[root@localhost static]# ll
total 16
drwxr-xr-x 5 root root  117 Dec  6 03:11 AdminLTE-2.3.7
-rw-r--r-- 1 root root 4801 Jan 30  2020 Ceph_Logo_Standard_RGB_White_120411_fa.png
-rw-r--r-- 1 root root 1150 Jan 30  2020 favicon.ico
drwxr-xr-x 7 root root   94 Dec  6 03:11 libs
-rw-r--r-- 1 root root 1811 Jan 30  2020 logo-mini.png
```

安装新rpm包，查看文件

```
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
-rw-r--r-- 1 root root 1877 Dec  6 03:44 logo-mini.png
-rw-r--r-- 1 root root 1811 Dec  6 03:41 logo-mini.png.bak
```

至此，rpm包中的文件修改以及重新打包的所有步骤都已完成

# 参考

https://www.cnblogs.com/felixzh/p/10564895.html