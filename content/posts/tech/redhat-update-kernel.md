---
title: "redhat服务器升级内核" 
date: 2021-09-01
lastmod: 2021-09-01
tags: 
- linux
keywords:
- linux
- redhat
- kernel
description: "" 
cover:
    image: "" 
---
# 前言

按指定要求安装升级内核，保证grub2启动时为默认项目

# 第一步

确认当前操作系统的内核版本

[root@server0 ~]# uname -r 
3.10.0-123.el7.x86_64  

# 第二步

下载准备升级的内核文件，比如说内核已存在于某个 Yum 仓库：http://content.example.com/rhel7.0/x86_64/errata

此时只要添加这个 Yum 源就可以直接下载了。

[root@server0 ~]# yum-config-manager --add-repo="http://content.example.com/rhel7.0/x86_64/errata" 

若是第一次配置，还需要导入红帽公钥

[root@server0 ~]# rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-* 

# 第三步

查找内核，并确认 Yum 仓库中的内核是否为需要升级的内核

[root@server0 ~]# yum list kernel 

# 第四步

安装新的内核，若内核文件很大，那安装时间就相对漫长一些。

[root@server0 ~]# yum -y install kernel 

# 第五步
检查新内核是否为默认启动内核（若是安装高版本号的内核，默认都会作为优先启动内核）

[root@server0 ~]# grub2-editenv list 
saved_entry=Red Hat Enterprise Linux Server (3.10.0-123.1.2.el7.x86_64) 7.0 (Maipo)  

当前默认启动内核已经是刚才升级的内核！如果要手动调整内核启动顺序，需要再进行设置一番。

# 第六步
确认当前操作系统有几个启动内核

当前操作系统有三个内核，其中第一个内核版本为 3.10.0-123.1.2.el7.x86_64，也就是我们刚才升级的内核；第二个内核版本为 3.10.0-123.el7.x86_64，是最初查看的内核版本。

现在设置第二个内核（3.10.0-123.el7.x86_64）为默认启动内核

[root@server0 ~]# grub2-set-default "Red Hat Enterprise Linux Server, with Linux 3.10.0-123.el7.x86_64"  

然后确认一下是否设置成功

[root@server0 ~]# grub2-editenv list  

saved_entry=Red Hat Enterprise Linux Server, with Linux 3.10.0-123.el7.x86_64  

重启检查新内核

[root@server0 ~]# uname -r