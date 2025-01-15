---
title: "openssh 源码打包编译成 rpm 包" 
date: 2021-09-01
lastmod: 2024-02-01
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
yum install wget vim gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts --downloadonly --downloaddir=/opt/openssh-9.5/openssh-9.5p1-update-script/resource
rpm -Uvh /opt/openssh-9.5/openssh-9.5p1-update-script/resource/*.rpm
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
cd /opt/openssh-9.5/openssh-rpms-main/; bash compile.sh
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
yum localinstall -y resource/openssh-*.rpm
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

# 2 openssh-8.7p1

## 2.1 编译环境

- 编译平台：	vmware workstation
- 系统版本：	普华服务器操作系统 v4.2
- 系统内核：	3.10.0-327.el7.isoft.x86_64

软件版本：

- openssh-8.7p1.tar.gz
- x11-ssh-askpass-1.2.4.1.tar.gz

## 2.2 编译步骤

yum 安装依赖工具

```bash
yum install wget vim gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts -y
```

创建编译目录

```bash
mkdir -p /root/rpmbuild/{SOURCES,SPECS}
```

下载 openssh 编译包和 x11-ssh-askpass 依赖包并解压修改配置

```bash
cd /root/rpmbuild/SOURCES

wget https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-8.7p1.tar.gz
wget https://src.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz

tar -zxvf openssh-8.7p1.tar.gz  

cp openssh-8.7p1/contrib/redhat/openssh.spec  /root/rpmbuild/SPECS/

sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
```

准备编译

```bash
vim /root/rpmbuild/SPECS/openssh.spec 
注释掉 BuildRequires: openssl-devel < 1.1 这一行
```

开始编译

```bash
rpmbuild -ba /root/rpmbuild/SPECS/openssh.spec 
```

操作验证

```bash
cd /root/rpmbuild/RPMS/x86_64/

vim run.sh

#!/bin/bash

set -e

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

## 2.3 升级脚本

```bash
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

使用

```bash
tar zxf openssh-8.7p1.rpm.x86_64.tar.gz
./run.sh
```

# 3 openssh-9.0p1

## 3.1 编译环境

编译平台：	vmware workstation

系统版本：	普华服务器操作系统 v3.0

系统内核：

- 2.6.32-279.el6.isoft.x86_64
- 2.6.32-504.el6.isoft.x86_64

软件版本：

- openssh-9.0p1.tar.gz
- x11-ssh-askpass-1.2.4.1.tar.gz

> 这两个内核版本步骤基本一样，区别在于 279 内核需要升级 `openssl`

## 3.2 编译步骤

添加阿里云 yum 源和本地 yum 源

```bash
# 阿里yum源
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-6.10.repo
# 本地yum源
mount /dev/sr0 /mnt/
cat > /etc/yum.repos.d/local.repo <<EOF
[local]
name=local
baseurl=file:///mnt
gpgcheck=0
enabled=1
EOF
```

yum 安装依赖工具

```bash
yum clean all
yum makecache
yum install wget vim gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts 
```

创建编译目录

```bash
mkdir -p /root/rpmbuild/{SOURCES,SPECS}
```

下载 openssh 编译包和 x11-ssh-askpass 依赖包并解压修改配置

```bash
cd /root/rpmbuild/SOURCES

wget https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable/openssh-9.0p1.tar.gz
wget https://src.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz --no-check-certificate

tar -zxf openssh-9.0p1.tar.gz

cp openssh-9.0p1/contrib/redhat/openssh.spec  /root/rpmbuild/SPECS/

sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
```

添加缺少的文件

```bash
cd /root/rpmbuild/SOURCES/openssh-9.0p1/contrib/redhat
cp sshd.init sshd.init.old
cp sshd.pam sshd.pam.old
```

重新打包，否则会报错找不到 sshd.pam.old 和 sshd.init.old

```bash
cd /root/rpmbuild/SOURCES/
tar zcf openssh-9.0p1.tar.gz openssh-9.0p1
```

准备编译

```bash
vim /root/rpmbuild/SPECS/openssh.spec 
注释掉 BuildRequires: openssl-devel < 1.1 这一行
```

开始编译

```bash
rpmbuild -ba /root/rpmbuild/SPECS/openssh.spec 
```

> 注意，从这步开始两个内核版本的后续操作不太相同

### 3.2.1 2.6.32-279.el6.isoft.x86_64

准备目录

```bash
mkdir -pv /root/openssh-9.0p1-rpms/openssl-1.0.1e-rpms/
cp /root/rpmbuild/RPMS/x86_64/* /root/openssh-9.0p1-rpms/
```

下载 openssl-1.0.1e 离线包

这步由于之前安装编译的依赖的时候已经安装过，可以用全新的系统重新下载 openssl-1.0.1e 的依赖

```bash
yum install -y yum-plugin-downloadonly
yum install openssl openssl-devel --downloadonly --downloaddir=/root/openssh-9.0p1-rpms/openssl-1.0.1e-rpms/
```

编写升级脚本

```bash
cat > /root/openssh-9.0p1-rpms/run.sh <<EOF
#!/bin/bash
set -e
cp /etc/pam.d/sshd   /etc/pam.d/sshd_bak
cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
rpm -e --nodeps libsepol-2.0.41-4.el6.isoft.x86_64
rpm -Uvh ./openssl-1.0.1e-rpms/*.rpm
rpm -Uvh ./*.rpm
cp /etc/pam.d/sshd_bak /etc/pam.d/sshd
cp /etc/ssh/sshd_config_bak /etc/ssh/sshd_config
rm -rf /etc/ssh/ssh*key
service sshd restart
ssh -V
EOF

chmod 755 /root/openssh-9.0p1-rpms/run.sh
```

打包

```bash
tar zcf /root/openssh-9.0p1-rpms.tar.gz /root/openssh-9.0p1-rpms
```

### 3.2.2 2.6.32-504.el6.isoft.x86_64

准备目录

```bash
mkdir  /root/openssh-9.0p1-rpms/
cp /root/rpmbuild/RPMS/x86_64/* /root/openssh-9.0p1-rpms/
```

编写升级脚本

```bash
cat > /root/openssh-9.0p1-rpms/run.sh <<EOF
#!/bin/bash
set -e
ssh -V
/bin/cp /etc/pam.d/sshd   /etc/pam.d/sshd_bak
/bin/cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
rpm -Uvh ./*.rpm
/bin/cp /etc/pam.d/sshd_bak /etc/pam.d/sshd
/bin/cp /etc/ssh/sshd_config_bak /etc/ssh/sshd_config
rm -rf /etc/ssh/ssh*key
service sshd restart
ssh -V
EOF

chmod 755 /root/openssh-9.0p1-rpms/run.sh
```

打包

```bash
tar zcf /root/openssh-9.0p1-rpms.tar.gz /root/openssh-9.0p1-rpms
```

## 3.3 使用

```bash
tar zxf openssh-9.0p1-rpms.tar.gz
cd openssh-9.0p1-rpms
sh run.sh
```

# 4 openssh-8.6p1-aarch64

## 4.1 编译环境

- 系统版本：普华服务器操作系统 openeuler 版
- 系统内核：4.19.90-2003.4.0.0036.oe1.aarch64
- 软件版本：
    - openssh-8.6p1.tar.gz
    - x11-ssh-askpass-1.2.4.1.tar.gz

## 4.2 编译步骤

dnf 安装依赖工具

```bash
dnf install gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts -y
```

创建编译目录

```bash
mkdir -p /root/rpmbuild/{SOURCES,SPECS}
```

下载 openssh 编译包和 x11-ssh-askpass 依赖包并解压修改配置

```bash
cd /root/rpmbuild/SOURCES
wget https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-8.6p1.tar.gz
wget https://src.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz

tar -zxvf openssh-8.6p1.tar.gz  

cp openssh-8.6p1/contrib/redhat/openssh.spec  /root/rpmbuild/SPECS/
sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
```

准备编译

```bash
vim /root/rpmbuild/SPECS/openssh.spec 注释掉 BuildRequires: openssl-devel < 1.1 这一行
修改下面两行 
%attr(4711,root,root) %{_libexecdir}/openssh/ssh-sk-helper
%attr(0644,root,root) %{_mandir}/man8/ssh-sk-helper.8.gz
```

开始编译

```bash
rpmbuild -ba /root/rpmbuild/SPECS/openssh.spec 
```

操作验证

```bash
cd /root/rpmbuild/RPMS/aarch64
vim run.sh 
```

```bash
#!/bin/bash
cp /etc/pam.d/sshd   /etc/pam.d/sshd_bak
cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
rpm -Uvh ./*.rpm
cp -r  /etc/pam.d/sshd_bak /etc/pam.d/
cp /etc/ssh/sshd_config_bak /etc/ssh/sshd_config
rm -rf /etc/ssh/ssh*key
systemctl daemon-reload
systemctl restart sshd
```

```bash
chmod 755 run.sh
./run.sh
ssh -V 
OpenSSH_8.6p1, OpenSSL 1.1.1d  10 Sep 2019
```

从版本看，ssh 已经升级成功。但是每次重启服务都会提示 sshd 的 unit 文件发生改变，需要执行 systemctl daemon-reload。执行完 reload 后重启 sshd 依旧报错 Warning: The unit file, source configuration file or drop-ins of sshd.service changed on disk. Run 'systemctl daemon-reload' to reload units.

![在这里插入图片描述](https://image.lvbibir.cn/blog/20210701164624435.png)

先不管这个问题，测试下 sshd 服务是否正常。

用终端连接试试

![在这里插入图片描述](https://image.lvbibir.cn/blog/20210701165555515.png)

一切正常，如果出现 PAM unable to dlopen(/usr/lib64/security/pam_stack.so): /usr/lib64/security/pam_stack.so: cannot open shared object file: No such file or directory 类似报错，需要还原原先的/etc/pam.d/sshd 文件

继续看之前那个报错，一般这种错误为服务的配置文件或者 unit 文件发生改变，需要执行 daemon-reload 重新加载一下，逐个排查

查看配置文件

![在这里插入图片描述](https://image.lvbibir.cn/blog/20210701170122697.png)

查看 unit 文件

![在这里插入图片描述](https://image.lvbibir.cn/blog/2021070117022510.png)

没有找到 sshd.service 的 unit 文件，find 查找一下

![在这里插入图片描述](https://image.lvbibir.cn/blog/20210701170414796.png)

第一个文件是老版本 ssh 的残留的自启的 unit 链接文件，已经失效了。第三个和第四个文件都是第二个文件的链接文件。

不知为何我们自己编译的 ssh 安装后 unit 文件会放到这个位置，后续再研究，尝试自己写一份 unit 文件，试试能不能恢复 sshd。

备份 unit 文件

```bash
[root@localhost ~]# cp /run/systemd/generator.late/sshd.service /root/sshd.service-20210702
```

查看 unit 文件中的控制参数和 pid 文件位置等

![在这里插入图片描述](https://image.lvbibir.cn/blog/20210702092434815.png)

自建一个 unit 文件，放到/usr/lib/systemd/system 目录

```bash
[root@localhost ~]# vim /usr/lib/systemd/system/sshd.service

[UNIT]
Description=OpenSSH server daemon
After=network.target sshd-keygen.target
Wants=sshd-keygen.target

[Service]
Type=forking
ExecStart=/etc/rc.d/init.d/sshd start
ExecReload=/etc/rc.d/init.d/sshd restart
ExecStop=/etc/rc.d/init.d/sshd stop
PrivateTmp=True

[Install]
WantedBy=multi-user.target

[root@localhost ~]# systemctl daemon-reload
[root@localhost ~]# systemctl restart sshd
[root@localhost ~]# systemctl status sshd
[root@localhost ~]# ssh -V
OpenSSH_8.6p1, OpenSSL 1.1.1d  10 Sep 2019
```

![在这里插入图片描述](https://image.lvbibir.cn/blog/20210702094722872.png)

打包归档

```bash
[root@localhost ~]# cp  /usr/lib/systemd/system/sshd.service  /root/rpmbuild/RPMS/aarch64/
[root@localhost ~]# cd /root/rpmbuild/RPMS/aarch64/
[root@localhost aarch64]# ls

openssh-8.6p1-1.isoft.isoft.aarch64.rpm                openssh-debugsource-8.6p1-1.isoft.isoft.aarch64.rpm
openssh-askpass-8.6p1-1.isoft.isoft.aarch64.rpm        openssh-server-8.6p1-1.isoft.isoft.aarch64.rpm
openssh-askpass-gnome-8.6p1-1.isoft.isoft.aarch64.rpm  run.sh
openssh-clients-8.6p1-1.isoft.isoft.aarch64.rpm        sshd.service
openssh-debuginfo-8.6p1-1.isoft.isoft.aarch64.rpm

[root@localhost aarch64]# vim run.sh

#!/bin/bash
cp /etc/pam.d/sshd   /etc/pam.d/sshd_bak
cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
rpm -Uvh ./*.rpm
cp /etc/pam.d/sshd_bak /etc/pam.d/
cp /etc/ssh/sshd_config_bak /etc/ssh/sshd_config
cp ./sshd.service  /usr/lib/systemd/system/sshd.service
rm -rf /etc/ssh/ssh*key
systemctl daemon-reload
systemctl restart sshd
systemctl enable sshd

[root@localhost aarch64]# tar zcvf openssh-8.6p1-rpm-aarch64.tar.gz ./*
[root@localhost aarch64]# mv openssh-8.6p1-rpm-aarch64.tar.gz /root
```

以上
