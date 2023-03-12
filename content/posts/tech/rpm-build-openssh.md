---
title: "openssh源码打包编译成rpm包" 
date: 2021-09-01
lastmod: 2022-09-05
tags: 
- linux
keywords:
- linux
- rpm
- openssh
- 源码
- rpm构建
description: "记录一下不同系统环境下通过源码构建openssh rpm包的过程" 
cover:
    image: "" 
---
# openssh-8.7p1

## 编译环境

编译平台：	vmware workstation

系统版本：	普华服务器操作系统v4.2

系统内核：	3.10.0-327.el7.isoft.x86_64

软件版本：	

- openssh-8.7p1.tar.gz
- x11-ssh-askpass-1.2.4.1.tar.gz

## 编译步骤

yum安装依赖工具

```
yum install wget vim gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts -y
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

## 使用

```
tar zxf openssh-8.7p1.rpm.x86_64.tar.gz
./run.sh
```

# openssh-9.0p1

## 编译环境

编译平台：	vmware workstation

系统版本：	普华服务器操作系统v3.0

系统内核：	

- 2.6.32-279.el6.isoft.x86_64  
- 2.6.32-504.el6.isoft.x86_64

软件版本：	

- openssh-9.0p1.tar.gz
- x11-ssh-askpass-1.2.4.1.tar.gz

> 这两个内核版本步骤基本一样，区别在于 279 内核需要升级 `openssl` 

## 编译步骤

添加阿里云yum源和本地yum源

```
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

yum安装依赖工具

```
yum clean all
yum makecache
yum install wget vim gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts 
```

创建编译目录

```
mkdir -p /root/rpmbuild/{SOURCES,SPECS}
```

下载openssh编译包和x11-ssh-askpass依赖包并解压修改配置

```
cd /root/rpmbuild/SOURCES

wget https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable/openssh-9.0p1.tar.gz
wget https://src.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz --no-check-certificate

tar -zxf openssh-9.0p1.tar.gz

cp openssh-9.0p1/contrib/redhat/openssh.spec  /root/rpmbuild/SPECS/

sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
```

添加缺少的文件

```
cd /root/rpmbuild/SOURCES/openssh-9.0p1/contrib/redhat
cp sshd.init sshd.init.old
cp sshd.pam sshd.pam.old
```

重新打包，否则会报错找不到 sshd.pam.old 和 sshd.init.old

```
cd /root/rpmbuild/SOURCES/
tar zcf openssh-9.0p1.tar.gz openssh-9.0p1
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

> 注意，从这步开始两个内核版本的后续操作不太相同

### 2.6.32-279.el6.isoft.x86_64

准备目录

```
mkdir -pv /root/openssh-9.0p1-rpms/openssl-1.0.1e-rpms/
cp /root/rpmbuild/RPMS/x86_64/* /root/openssh-9.0p1-rpms/
```

下载 openssl-1.0.1e 离线包

这步由于之前安装编译的依赖的时候已经安装过，可以用全新的系统重新下载 openssl-1.0.1e 的依赖

```
yum install -y yum-plugin-downloadonly
yum install openssl openssl-devel --downloadonly --downloaddir=/root/openssh-9.0p1-rpms/openssl-1.0.1e-rpms/
```

编写升级脚本

```
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

```
tar zcf /root/openssh-9.0p1-rpms.tar.gz /root/openssh-9.0p1-rpms
```

### 2.6.32-504.el6.isoft.x86_64

准备目录

```
mkdir  /root/openssh-9.0p1-rpms/
cp /root/rpmbuild/RPMS/x86_64/* /root/openssh-9.0p1-rpms/
```

编写升级脚本

```
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

```
tar zcf /root/openssh-9.0p1-rpms.tar.gz /root/openssh-9.0p1-rpms
```

## 使用

```
tar zxf openssh-9.0p1-rpms.tar.gz
cd openssh-9.0p1-rpms
sh run.sh
```

# openssh-8.6p1-aarch64

## 编译环境
系统版本：普华服务器操作系统openeuler版

系统内核：4.19.90-2003.4.0.0036.oe1.aarch64

软件版本：

- openssh-8.6p1.tar.gz    

- x11-ssh-askpass-1.2.4.1.tar.gz

## 编译步骤
dnf安装依赖工具

```
dnf install gdb imake libXt-devel gtk2-devel  rpm-build zlib-devel openssl-devel gcc perl-devel pam-devel unzip krb5-devel  libX11-devel  initscripts -y
```

创建编译目录

```
mkdir -p /root/rpmbuild/{SOURCES,SPECS}
```

下载openssh编译包和x11-ssh-askpass依赖包并解压修改配置

```
cd /root/rpmbuild/SOURCES
wget https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-8.6p1.tar.gz
wget https://src.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz

tar -zxvf openssh-8.6p1.tar.gz  

cp openssh-8.6p1/contrib/redhat/openssh.spec  /root/rpmbuild/SPECS/
sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" /root/rpmbuild/SPECS/openssh.spec
```

准备编译

```
vim /root/rpmbuild/SPECS/openssh.spec 注释掉 BuildRequires: openssl-devel < 1.1 这一行
修改下面两行 
%attr(4711,root,root) %{_libexecdir}/openssh/ssh-sk-helper
%attr(0644,root,root) %{_mandir}/man8/ssh-sk-helper.8.gz
```

开始编译

```
rpmbuild -ba /root/rpmbuild/SPECS/openssh.spec 
```

操作验证

```
cd /root/rpmbuild/RPMS/aarch64
vim run.sh 
```
```
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
```
chmod 755 run.sh
./run.sh
ssh -V 
OpenSSH_8.6p1, OpenSSL 1.1.1d  10 Sep 2019
```
从版本看，ssh已经升级成功。但是每次重启服务都会提示sshd的unit文件发生改变，需要执行systemctl daemon-reload。执行完reload后重启sshd依旧报错Warning: The unit file, source configuration file or drop-ins of sshd.service changed on disk. Run 'systemctl daemon-reload' to reload units.
![在这里插入图片描述](https://image.lvbibir.cn/blog/20210701164624435.png)

先不管这个问题，测试下sshd服务是否正常。

用终端连接试试

![在这里插入图片描述](https://image.lvbibir.cn/blog/20210701165555515.png)
一切正常，如果出现PAM unable to dlopen(/usr/lib64/security/pam_stack.so): /usr/lib64/security/pam_stack.so: cannot open shared object file: No such file or directory类似报错，需要还原原先的/etc/pam.d/sshd文件

继续看之前那个报错，一般这种错误为服务的配置文件或者unit文件发生改变，需要执行daemon-reload重新加载一下，逐个排查

查看配置文件
![在这里插入图片描述](https://image.lvbibir.cn/blog/20210701170122697.png)

查看unit文件
![在这里插入图片描述](https://image.lvbibir.cn/blog/2021070117022510.png)
没有找到sshd.service的unit文件，find查找一下
![在这里插入图片描述](https://image.lvbibir.cn/blog/20210701170414796.png)
第一个文件是老版本ssh的残留的自启的unit链接文件，已经失效了。第三个和第四个文件都是第二个文件的链接文件。	
不知为何我们自己编译的ssh安装后unit文件会放到这个位置，后续再研究，尝试自己写一份unit文件，试试能不能恢复sshd。

备份unit文件

```
[root@localhost ~]# cp /run/systemd/generator.late/sshd.service /root/sshd.service-20210702
```
查看unit文件中的控制参数和pid文件位置等
![在这里插入图片描述](https://image.lvbibir.cn/blog/20210702092434815.png)
自建一个unit文件，放到/usr/lib/systemd/system目录

```
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

```
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

## 参考

[systemd和sysv的服务管理](https://blog.csdn.net/weixin_30412577/article/details/97964940?utm_medium=distribute.pc_relevant.none-task-blog-2~default~BlogCommendFromMachineLearnPai2~default-1.control&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2~default~BlogCommendFromMachineLearnPai2~default-1.control)

[systemd-sysv-generator 中文手册](https://www.wenjiangs.com/doc/systemd-systemd-sysv-generator)



