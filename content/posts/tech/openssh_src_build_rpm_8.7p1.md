---
title: "openssh源码打包编译成rpm包（8.7p1）" #标题
date: 2021-09-01T00:00:00+08:00 #创建时间
lastmod: 2021-09-01T00:00:00+08:00 #更新时间
author: ["lvbibir"] #作者
categories: 
- 
tags: 
- openssh
- ssh
- rpm
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
# 编译环境

编译平台：	vmware workstation
系统版本：	普华服务器操作系统v4.0
系统内核：	3.10.0-327.el7.isoft.x86_64
软件版本：	openssh-8.7p1.tar.gz
						x11-ssh-askpass-1.2.4.1.tar.gz

# 编译步骤

yum安装依赖工具

```
yum install gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts -y
```

创建编译目录

```
mkdir -p /root/rpmbuild/{SOURCES,SPECS}
```

下载openssh编译包和x11-ssh-askpass依赖包并解压修改配置

```
cd /root/rpmbuild/SOURCES

wget https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-8.7p1.tar.gz
wget https://src.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz

tar -zxvf openssh-8.7p1.tar.gz  

cp openssh-8.7p1/contrib/redhat/openssh.spec  /root/rpmbuild/SPECS/

sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec

```

准备编译

```
vim /root/rpmbuild/SPECS/openssh.spec 
注释掉 BuildRequires: openssl-devel < 1.1 这一行
```

开始编译

```
rpmbuild -ba /root/rpmbuild/SPECS/openssh.spec 
```

操作验证

```
cd /root/rpmbuild/RPMS/x86_64/

vim run.sh

#!/bin/bash
cp /etc/pam.d/sshd   /etc/pam.d/sshd_bak
cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
rpm -Uvh ./*.rpm
cp -r  /etc/pam.d/sshd_bak /etc/pam.d/
cp /etc/ssh/sshd_config_bak /etc/ssh/sshd_config
rm -rf /etc/ssh/ssh*key
systemctl daemon-reload
systemctl restart sshd

chmod 755 run.sh
./run.sh
ssh -V 
```

打包归档

```
[root@localhost ~]# cd /root/rpmbuild/RPMS/x86_64/
[root@localhost x86_64]# ls

openssh-8.7p1-1.el7.isoft.x86_64.rpm
openssh-askpass-8.7p1-1.el7.isoft.x86_64.rpm
openssh-askpass-gnome-8.7p1-1.el7.isoft.x86_64.rpm
openssh-clients-8.7p1-1.el7.isoft.x86_64.rpm
openssh-debuginfo-8.7p1-1.el7.isoft.x86_64.rpm
openssh-server-8.7p1-1.el7.isoft.x86_64.rpm
run.sh

[root@localhost x86_64]# vim run.sh

#!/bin/bash
cp /etc/pam.d/sshd   /etc/pam.d/sshd_bak
cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
rpm -Uvh ./*.rpm
cp -r  /etc/pam.d/sshd_bak /etc/pam.d/
cp /etc/ssh/sshd_config_bak /etc/ssh/sshd_config
rm -rf /etc/ssh/ssh*key
systemctl daemon-reload
systemctl restart sshd

[root@localhost x86_64]# tar zcvf openssh-8.7p1.rpm.x86_64.tar.gz ./*
[root@localhost x86_64]# mv openssh-8.7p1.rpm.x86_64.tar.gz /root
```

# 使用

```
tar zxf openssh-8.7p1.rpm.x86_64.tar.gz
./run.sh
```

