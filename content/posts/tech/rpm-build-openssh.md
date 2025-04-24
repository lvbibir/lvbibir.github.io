---
title: "openssh 源码打包编译成 rpm 包" 
date: 2021-09-01
lastmod: 2025-04-24
tags:
  - linux
keywords:
  - linux
  - rpm
  - openssh
  - 源码
  - rpm构建
description: "记录一下不同系统环境下通过源码构建 openssh rpm 包的过程" 
cover:
    image: "https://image.lvbibir.cn/blog/default-cover.webp" 
---

# 0 前言

本文参考以下链接:

- [systemd 和 sysv 的服务管理](https://blog.csdn.net/weixin_30412577/article/details/97964940)
- [systemd-sysv-generator 中文手册](https://www.wenjiangs.com/doc/systemd-systemd-sysv-generator)
- [openssh 编译 rpm](https://www.zhihu.com/question/434396809/answer/3186833677)

# 1 openssh-9.5p1

## 1.1 编译环境

- 编译平台: 华为私有云
- 系统版本: 麒麟 v7.4
- 系统内核: 3.10.0-693.43.1.el7.x86_64

软件版本:

- openssh-9.5p1.tar.gz
- openssl-3.0.11.tar.gz
- x11-ssh-askpass-1.2.4.1.tar.gz

[编译脚本项目地址](https://github.com/boypt/openssh-rpms)

## 1.2 编译步骤

添加 yum 源略, 云平台自带 yum 源

创建工作目录

```bash
mkdir -p /opt/openssh-9.5/openssh-9.5p1-update-script/resource
```

下载 [编译脚本](https://codeload.github.com/boypt/openssh-rpms/zip/refs/heads/main), 上传至服务器 `/opt/openssh-9.5` 目录并解压

```bash
cd /opt/openssh-9.5; unzip openssh-rpms-main.zip
```

yum 安装依赖工具

```bash
yum clean all; yum makecache
yum install wget vim gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl perl-IPC-Cmd perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts
```

默认 openssh 源码中是没有 ssh-copy-id 相关参数的，如果直接编译安装，会发现安装后没有 ssh-copy-id 命令，因此如果需要用到该命令，需要修改编译参数控制文件 openssh.spec, 本次安装使用的操作系统是 el7 系列的

```bash
vim /opt/openssh-9.5/openssh-rpms-main/el7/SPECS/openssh.spec
```

如下位置添加一行

```plaintext
install -m755 contrib/ssh-copy-id $RPM_BUILD_ROOT/usr/bin/ssh-copy-id
```

![image-20231114160828131](https://image.lvbibir.cn/blog/image-20231114-160828.png)

第二处添加

```plaintext
%attr(0755,root,root) %{_bindir}/ssh-copy-id
```

![image-20231114161012601](https://image.lvbibir.cn/blog/image-20231114-161012.png)

下载各源码包上传至服务器 `/opt/openssh-9.5/openssh-rpms-main/downloads`

- [openssh](https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable/openssh-9.5p1.tar.gz)
- [openssl](https://www.openssl.org/source/openssl-3.0.11.tar.gz)
- [x11-ssh-askpass](https://src.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz)

![image-20231114161838284](https://image.lvbibir.cn/blog/image-20231114-161838.png)

执行编译打包脚本

```bash
cd /opt/openssh-9.5/openssh-rpms-main/
# 修改 version.env 文件, 使版本号对应
cat version.env
bash compile.sh
```

脚本应正常运行, 查看编译后的 rpm 包

```bash
cd /opt/openssh-9.5/openssh-rpms-main/el7/RPMS/x86_64/; ls
```

![image-20231114162423846](https://image.lvbibir.cn/blog/image-20231114-162423.png)

## 1.3 升级脚本

拷贝编译后的包到 resource 目录

```bash
cp /opt/openssh-9.5/openssh-rpms-main/el7/RPMS/x86_64/*.rpm /opt/openssh-9.5/openssh-9.5p1-update-script/resource/
```

编写升级脚本

```bash
cat > /opt/openssh-9.5/openssh-9.5p1-update-script/run.sh <<EOF
#!/bin/bash
#
# Author  : lvbibir
# Email   : lvbibir@gmail.com
# Version : V1.0
# Time    : 2023-11-14 16:48:30
# Desc    : A script for update ssh

set -e
ssh -V
/bin/cp /etc/pam.d/sshd /etc/pam.d/sshd_bak
/bin/cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
# 如有 yum 源推荐使用 yum 方式
# yum localinstall -y resource/openssh-*.rpm
rpm -Uvh resource/openssh-*.rpm
/bin/cp /etc/pam.d/sshd_bak /etc/pam.d/sshd
/bin/cp /etc/ssh/sshd_config_bak /etc/ssh/sshd_config
rm -rf /etc/ssh/ssh*key
systemctl daemon-reload
systemctl restart sshd
ssh -V

EOF

chmod 755 /opt/openssh-9.5/openssh-9.5p1-update-script/run.sh
```

打包

```bash
cd /opt/openssh-9.5/
tar zcf openssh-9.5p1-update-script.tar.gz openssh-9.5p1-update-script
```

上传压缩包至服务器 `/opt/` 目录

```bash
cd /opt; tar zxf openssh-9.5p1-update-script.tar.gz
cd /opt/openssh-9.5p1-update-script/; sh run.sh
```

以上.
