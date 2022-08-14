---
title: "pxe安装isoft6.0及icloud1.0（Centos8）" 
date: 2022-07-12
lastmod: 2022-07-12
author: ["lvbibir"] 
categories: 
- 
tags: 
- pxe
description: "" 
weight: 
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

# 前言

测试环境：

x86_64：vmware workstation V16.1.2

aarch64： kvm-2.12

> 注意测试的网络环境中不要存在其他的dhcp服务

# 服务端配置

## 系统安装

系统安装过程略，系统版本：iSoft-ServerOS-V6.0-rc1

网卡选择nat模式，注意关闭一下 workstation 自带的 dhcp，ip：1.1.1.21

![](https://image.lvbibir.cn/blog/image-20220712100835390.png)

## 	关闭防火墙及selinux

```shell
iptables -F
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
```

## 安装相关的软件包

这里由于HW行动的原因，外网yum源暂不可用，使用本地yum源安装相关软件包

```
mount -o loop /dev/sr0 /mnt
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/isoft* /etc/yum.repos.d/bak/

cat > /etc/yum.repos.d/local.repo <<EOF
[local]
name=local
baseurl=file:///mnt
gpgcheck=0
enabled=1
EOF

dnf clean all
dnf makecache
```

![image-20220712141522049](https://image.lvbibir.cn/blog/image-20220712141522049.png)

cenots8安装syslinux时需要加 --nonlinux后缀，centos7则不需要

```
 dnf install -y dhcp-server tftp-server httpd syslinux-nonlinux
```

![image-20220712141810455](https://image.lvbibir.cn/blog/image-20220712141810455.png)

## http服务配置

```
chmod 755 -R /var/www/html/
systemctl start httpd
systemctl enable httpd
mkdir /var/www/html/ks/
```

能访问到httpd即可

## tftp服务配置

```
systemctl start tftp
systemctl enable tftp

/usr/bin/cp /usr/share/syslinux/menu.c32 /var/lib/tftpboot/
/usr/bin/cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
mkdir /var/lib/tftpboot/pxelinux.cfg
```

## dhcp服务配置

vim /etc/dhcp/dhcpd.conf

```
option domain-name "example.org";
option domain-name-servers 8.8.8.8, 114.114.114.114;

default-lease-time 84600;
max-lease-time 100000;

log-facility local7;

subnet 1.1.1.0 netmask 255.255.255.0 {
  range 1.1.1.100 1.1.1.200;
  option routers 1.1.1.253;
  next-server 1.1.1.21; # 本机ip（tftpserver的ip）
  filename "pxelinux.0";
}
```

```
systemctl start dhcpd
systemctl enable dhcpd
```

# isoft_6.0_x86

## http服务配置

创建目录

```
# 创建目录
mkdir -p /var/www/html/isoft_6.0/isos/x86_64/

# 挂载镜像文件
mount -o loop /dev/sr0 /var/www/html/isoft_6.0/isos/x86_64/

# 上传ks.cfg应答文件
vim /var/www/html/ks/ks-isoft-6.0.cfg
chmod 644 /var/www/html/ks/ks-isoft-6.0.cfg
```

ks.cfg文件内容

```
# Use graphical install
graphical

install
url --url=http://1.1.1.21/isoft_6.0/isos/x86_64/

%packages
@^graphical-server-environment

%end

# Keyboard layouts
keyboard --xlayouts='cn'
# System language
lang zh_CN.UTF-8

# Network information
network  --bootproto=static --device=ens33 --bootproto=dhcp --ipv6=auto --activate
network  --hostname=localhost.localdomain

# Run the Setup Agent on first boot
firstboot --enable

ignoredisk --only-use=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel

# System timezone
timezone Asia/Shanghai --isUtc

# Root password
rootpw --iscrypted $6$w6X5WYQDyMeAizfs$TFKls9Kuj4Jv6PNKcMZ2BmB1Z/dvRCRkGD9uzm0n8te2UwDgdPCPGkUxCPvExKGenCMINTMcjSH55bCWYDiHx.

%addon com_redhat_kdump --disable --reserve-mb='128'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

reboot
```

## tftp服务配置

```
# 拷贝内核启动文件
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/vmlinuz /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/initrd.img /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/vesamenu.c32 /var/lib/tftpboot/

# 拷贝菜单配置文件
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default

# 下面这三个文件centos7可以不要，centos8对于这三个文件有一定依赖性
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/ldlinux.c32 /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/libutil.c32 /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/libcom32.c32 /var/lib/tftpboot/
```

vim /var/lib/tftpboot/pxelinux.cfg/default

```
default vesamenu.c32
timeout 30

menu title iSoft-Taiji Server OS 6.0

label linux
  menu label ^Install iSoft-Taiji Server OS 6.0
  menu default
  kernel vmlinuz
  append initrd=initrd.img ks=http://1.1.1.21/ks/ks-isoft-6.0.cfg
```

## 测试

注意测试虚拟机内存需要4G左右，否则会报错  `no space left`

# icloud_1.0_x86

为服务端虚拟机添加 CD/DVD 设备，挂载 i-cloud 系统镜像，系统中识别为 `/dev/sr1` 设备

> 默认添加的设备是 SCSI 类型的，需要重启修改成 IDE 才能生效

## http服务配置

```
# 挂载镜像
mount -o loop /dev/sr1 /var/www/html/icloud_1.0/isos/x86_64/

# 上传ks.cfg应答文件
vim /var/www/html/ks/ks-i-cloud.cfg
chmod 644 /var/www/html/ks/ks-i-cloud.cfg
```

ks.cfg文件内容

```
#version=RHEL8
ignoredisk --only-use=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel --drives=sda
# Use graphical install
graphical
# Use CDROM installation media
install
url --url=http://1.1.1.21/icloud_1.0/isos/x86_64/
# Keyboard layouts
keyboard --vckeymap=us --xlayouts=''
# System language
lang zh_CN.UTF-8

# Root password
rootpw --iscrypted 123.com
# Run the Setup Agent on first boot
firstboot --enable
# Do not configure the X Window System
skipx
# System services
services --enabled="chronyd"
# System timezone
timezone Asia/Shanghai --isUtc

%packages
@^vmserver-compute-node
%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
```

## tftp服务配置

```
# 提取 menu.c32 和 pxelinux.0
cp /var/www/html/icloud_1.0/isos/x86_64/Packages/syslinux-nonlinux-6.04-4.el8.isoft.noarch.rpm /root/
rpm2cpio syslinux-nonlinux-6.04-4.el8.isoft.noarch.rpm | cpio -idv ./usr/share/syslinux/menu.c32
rpm2cpio syslinux-nonlinux-6.04-4.el8.isoft.noarch.rpm | cpio -idv ./usr/share/syslinux/pxelinux.0
/usr/bin/cp /root/usr/share/syslinux/menu.c32 /var/lib/tftpboot/
/usr/bin/cp /root/usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

# 拷贝内核启动文件
/usr/bin/cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/vmlinuz /var/lib/tftpboot/
/usr/bin/cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/initrd.img /var/lib/tftpboot/
/usr/bin/cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/vesamenu.c32 /var/lib/tftpboot/

# 拷贝菜单配置文件
cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default

# 下面这三个文件centos7可以不要，centos8对于这三个文件有一定依赖性
/usr/bin/cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/ldlinux.c32 /var/lib/tftpboot/
/usr/bin/cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/libutil.c32 /var/lib/tftpboot/
/usr/bin/cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/libcom32.c32 /var/lib/tftpboot/
```

vim /var/lib/tftpboot/pxelinux.cfg/default

```
default menu.c32
timeout 30
menu title i-CloudOS 1.0

label linux
  menu label ^Install i-CloudOS 1.0
  menu default
  kernel vmlinuz
  append initrd=initrd.img ks=http://1.1.1.21/icloud_1.0/isos/x86_64/ks.cfg
```

# isoft_6.0_aarch64

## http服务配置

创建目录

```
# 创建目录
mkdir -p /var/www/html/isoft_6.0/isos/aarch64/

# 挂载镜像文件
mount -o loop /dev/sr0 /var/www/html/isoft_6.0/isos/aarch64/

# 上传ks.cfg应答文件
vim /var/www/html/ks/ks-isoft-6.0.cfg
chmod 644 /var/www/html/ks/ks-isoft-6.0.cfg
```

ks.cfg文件内容

```
#version=DEVEL
ignoredisk --only-use=vda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel
# Use graphical install
graphical
# Use CDROM installation media
install
url --url=http://1.1.1.21/isoft_6.0/isos/aarch64
# Keyboard layouts
keyboard --vckeymap=cn --xlayouts='cn'
# System language
lang zh_CN.UTF-8

# Network information
network  --bootproto=static --device=enp3s0 --bootproto=dhcp --ipv6=auto --activate
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted $6$x94MGsfCoFdE/G4O$MEakgOwtq0O5i4pRIVzXntKQuMJVh9CJ3anhZKl8YZhZDtSXhzuMk5mpDr3wu..rDareWgy5tjsepCaGiPK3g/
# X Window System configuration information
xconfig  --startxonboot
# Run the Setup Agent on first boot
firstboot --enable
# System services
services --enabled="chronyd"
# System timezone
timezone Asia/Shanghai --isUtc

%packages
@^mate-desktop-environment

%end


%anaconda
pwpolicy root --minlen=8 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=8 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=8 --minquality=1 --notstrict --nochanges --notempty
%end

reboot
```

## tftp服务配置

```
rm -rf /var/lib/tftpboot/*

/usr/bin/cp /var/www/html/isoft_6.0/isos/aarch64/EFI/BOOT/grub.cfg /var/lib/tftpboot/
/usr/bin/cp /var/www/html/isoft_6.0/isos/aarch64/EFI/BOOT/grubaa64.efi /var/lib/tftpboot/
/usr/bin/cp /var/www/html/isoft_6.0/isos/aarch64/images/pxeboot/vmlinuz /var/lib/tftpboot/
/usr/bin/cp /var/www/html/isoft_6.0/isos/aarch64/images/pxeboot/initrd.img /var/lib/tftpboot/

chmod -R 644 /var/lib/tftpboot/*
systemctl restart tftp
```

vim /var/lib/tftpboot/grub.cfg

```
set default="0"

function load_video {
  if [ x$feature_all_video_module = xy ]; then
    insmod all_video
  else
    insmod efi_gop
    insmod efi_uga
    insmod ieee1275_fb
    insmod vbe
    insmod vga
    insmod video_bochs
    insmod video_cirrus
  fi
}

load_video
set gfxpayload=keep
insmod gzio
insmod part_gpt
insmod ext2

set timeout=60
### END /etc/grub.d/00_header ###

search --no-floppy --set=root -l 'iSoft-Taiji-Server-OS-6.0'

### BEGIN /etc/grub.d/10_linux ###
menuentry 'Install iSoft-Taiji-Server-OS 6.0 with GUI mode' --class red --class gnu-linux --class gnu --class os {
        linux  /vmlinuz ip=dhcp inst.repo=http://1.1.1.21/isoft_6.0/isos/aarch64/ inst.ks=http://1.1.1.21/ks/ks-isoft-6.0-aarch64.cfg
        initrd /initrd.img
}
}
```

## dhcp服务配置

vim /etc/dhcp/dhcpd.conf

```
option domain-name "example.org";
option domain-name-servers 8.8.8.8, 114.114.114.114;

default-lease-time 84600;
max-lease-time 100000;

log-facility local7;

subnet 1.1.1.0 netmask 255.255.255.0 {
  range 1.1.1.100 1.1.1.200;
  option routers 1.1.1.253;
  next-server 1.1.1.21; # 本机ip（tftpserver的ip）
  filename "grubaa64.efi"; 
}
```

```
systemctl restart dhcpd
```



# 参考

https://blog.csdn.net/weixin_45651006/article/details/103067283

https://blog.csdn.net/qq_44839276/article/details/106980334
