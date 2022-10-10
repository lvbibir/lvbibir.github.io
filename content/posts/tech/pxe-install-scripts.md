---
title: "pxe 安装配置大全" 
date: 2022-07-12
lastmod: 2022-07-12
tags: 
- linux
keywords:
- linux
- pxe
- aarch64
- dhcp
description: "自己整理的一些工作中用到的不同系统对应的pxe配置方法" 
cover:
    image: "" 
---

# 前言

测试环境：

x86_64（amd ryzen 7 4800u）：vmware workstation V16.1.2

aarch64（kunpeng 920）： kvm-2.12

> 注意测试的网络环境中不要存在其他的dhcp服务
>
> 注意测试虚拟机内存尽量大于4G，否则会报错  `no space left` 或者测试机直接黑屏
>
> 注意 `ks.cfg` 尽量在当前环境先手动安装一台模板机，使用模板机生成的 ks 文件来进行修改，否则可能会有一些清理磁盘分区的破坏性操作，基本只需要将安装方式从`cdrom` 修改成 `install` 和 `url --url=http://......`

# 服务端配置

## 基础环境

系统版本：iSoft-ServerOS-V6.0-rc1

ip地址：1.1.1.21

网卡选择nat模式，注意关闭一下 workstation 自带的 dhcp，也可使用自定义的 `lan区段` 

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

这里由于 HW 行动的原因，外网 yum 源暂不可用，使用本地 yum 源安装相关软件包

```
mount -o loop /root/iSoft-Taiji-Server-OS-6.0-x86_64-rc1-202112311623.iso /mnt
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
 dnf install  dhcp-server tftp-server httpd syslinux-nonlinux
```

![image-20220712141810455](https://image.lvbibir.cn/blog/image-20220712141810455.png)

## http服务配置

```
mkdir /var/www/html/ks/
chmod 755 -R /var/www/html/
systemctl start httpd
systemctl enable httpd
```

能访问到 httpd 即可

## tftp服务配置

```
systemctl start tftp
systemctl enable tftp
```

## dhcp服务配置

> x86_64 架构和 aarch64 架构的 dhcp 的配置略有不同，按照下文分别配置

```
systemctl enable dhcpd
```

# x86_64

## 服务端配置

### dhcp 服务配置

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
systemctl restart dhcpd
```

## isoft_4.2_x86

### http服务配置

创建目录

```
# 创建目录
mkdir -p /var/www/html/isoft_4.2/isos/x86_64/

# 挂载镜像文件
mount -o loop /root/iSoft-Server-OS-4.2-x86_64-201907051149.iso /var/www/html/isoft_4.2/isos/x86_64/

# 创建ks.cfg应答文件
vim /var/www/html/ks/ks-isoft-4.2-x86.cfg
chmod -R 755 /var/www/html
```

ks.cfg文件内容

```
#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
install
url --url=http://1.1.1.21/isoft_4.2/isos/x86_64/
# Use graphical install
graphical
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=cn --xlayouts='cn'
# System language
lang zh_CN.UTF-8

# Network information
network  --bootproto=dhcp --device=ens32 --onboot=off --ipv6=auto --no-activate
network  --hostname=localhost.localdomain

# Root password
rootpw --iscrypted $6$9yXT2.jd8oofY89W$q1nVQ4rRfAE937KeG5bHCAP3iI3GgyVJJF/MN5Ipe9omdXIEjelaTQSPplr9E9aFOGG17F3GkzIzNnifvjdO20
# System services
services --enabled="chronyd"
# System timezone
timezone Asia/Shanghai --isUtc
# X Window System configuration information
xconfig  --startxonboot
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel

%packages
@^gnome-desktop-environment
@base
@core
@desktop-debugging
@dial-up
@directory-client
@fonts
@gnome-desktop
@guest-agents
@guest-desktop-agents
@input-methods
@internet-browser
@java-platform
@multimedia
@network-file-system-client
@networkmanager-submodules
@print-client
@x11
chrony
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

reboot
```

### tftp服务配置

```
rm -rf /var/lib/tftpboot/*
rm -rf /root/usr
mkdir /var/lib/tftpboot/pxelinux.cfg

# 提取 menu.c32 和 pxelinux.0
cp /var/www/html/icloud_1.0/isos/x86_64/Packages/syslinux-nonlinux-6.04-4.el8.isoft.noarch.rpm /root/
rpm2cpio syslinux-4.05-15.el7.isoft.x86_64.rpm | cpio -idv ./usr/share/syslinux/menu.c32
rpm2cpio syslinux-4.05-15.el7.isoft.x86_64.rpm | cpio -idv ./usr/share/syslinux/pxelinux.0
cp /root/usr/share/syslinux/menu.c32 /var/lib/tftpboot/
cp /root/usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

# 拷贝内核启动文件
cp /var/www/html/isoft_4.2/isos/x86_64/isolinux/vmlinuz /var/lib/tftpboot/
cp /var/www/html/isoft_4.2/isos/x86_64/isolinux/initrd.img /var/lib/tftpboot/
cp /var/www/html/isoft_4.2/isos/x86_64/isolinux/vesamenu.c32 /var/lib/tftpboot/

# 拷贝菜单配置文件
cp /var/www/html/isoft_4.2/isos/x86_64/isolinux/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default

chmod -R 755 /var/lib/tftpboot/*
systemctl restart tftp
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
  append initrd=initrd.img ks=http://1.1.1.21/ks/ks-isoft-6.0-x86.cfg
```

## isoft_6.0-rc1_x86

### http服务配置

创建目录

```
# 创建目录
mkdir -p /var/www/html/isoft_6.0/isos/x86_64/

# 挂载镜像文件
mount -o loop /root/iSoft-Taiji-Server-OS-6.0-x86_64-rc1-202112311623.iso /var/www/html/isoft_6.0/isos/x86_64/

# 创建ks.cfg应答文件
vim /var/www/html/ks/ks-isoft-6.0-x86.cfg
chmod -R 755 /var/www/html
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

### tftp服务配置

```
rm -rf /var/lib/tftpboot/*
rm -rf /root/usr
mkdir /var/lib/tftpboot/pxelinux.cfg

# 提取 menu.c32 和 pxelinux.0
cp /var/www/html/isoft_6.0/isos/x86_64/Packages/syslinux-nonlinux-6.04-7.oe1.isoft.noarch /root/
rpm2cpio syslinux-nonlinux-6.04-7.oe1.isoft.noarch | cpio -idv ./usr/share/syslinux/menu.c32
rpm2cpio syslinux-nonlinux-6.04-7.oe1.isoft.noarch | cpio -idv ./usr/share/syslinux/pxelinux.0
cp /root/usr/share/syslinux/menu.c32 /var/lib/tftpboot/
cp /root/usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

# 拷贝内核启动文件
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/vmlinuz /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/initrd.img /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/vesamenu.c32 /var/lib/tftpboot/

# 拷贝菜单配置文件
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default

cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/ldlinux.c32 /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/libutil.c32 /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/x86_64/isolinux/libcom32.c32 /var/lib/tftpboot/

chmod -R 755 /var/lib/tftpboot/*
systemctl restart tftp
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
  append initrd=initrd.img ks=http://1.1.1.21/ks/ks-isoft-6.0-x86.cfg
```

## icloud_1.0_x86

### http服务配置

```
mkdir -p /var/www/html/icloud_1.0/isos/x86_64/

# 挂载镜像
mount -o loop /root/i-CloudOS-1.0-x86_64-202108131137.iso /var/www/html/icloud_1.0/isos/x86_64/

# 创建ks.cfg应答文件
vim /var/www/html/ks/ks-icloud-1.0-x86.cfg
chmod -R 755 /var/www/html
```

ks-icloud-1.0-x86.cfg 文件内容

```
#version=RHEL8
ignoredisk --only-use=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel
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

reboot
```

### tftp服务配置

```
rm -rf /var/lib/tftpboot/*
rm -rf /root/usr
mkdir /var/lib/tftpboot/pxelinux.cfg

# 提取 menu.c32 和 pxelinux.0
cp /var/www/html/icloud_1.0/isos/x86_64/Packages/syslinux-nonlinux-6.04-4.el8.isoft.noarch.rpm /root/
rpm2cpio syslinux-nonlinux-6.04-4.el8.isoft.noarch.rpm | cpio -idv ./usr/share/syslinux/menu.c32
rpm2cpio syslinux-nonlinux-6.04-4.el8.isoft.noarch.rpm | cpio -idv ./usr/share/syslinux/pxelinux.0
cp /root/usr/share/syslinux/menu.c32 /var/lib/tftpboot/
cp /root/usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

# 拷贝内核启动文件
cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/vmlinuz /var/lib/tftpboot/
cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/initrd.img /var/lib/tftpboot/
cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/vesamenu.c32 /var/lib/tftpboot/

# 拷贝菜单配置文件
cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default

# 下面这三个文件centos7可以不要，centos8对于这三个文件有一定依赖性
cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/ldlinux.c32 /var/lib/tftpboot/
cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/libutil.c32 /var/lib/tftpboot/
cp /var/www/html/icloud_1.0/isos/x86_64/isolinux/libcom32.c32 /var/lib/tftpboot/

chmod -R 755 /var/lib/tftpboot/*
systemctl restart tftp
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
  append initrd=initrd.img ks=http://1.1.1.21/icloud_1.0/isos/x86_64/ks-icloud-1.0-x86.cfg
```

## openeuler_20.03-LTS-SP1_x86

### http服务配置

创建目录

```
# 创建目录
mkdir -p /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/

# 挂载镜像文件
mount -o loop /root/iSoft-Taiji-Server-OS-6.0-x86_64-rc1-202112311623.iso /var/www/html/isoft_6.0/isos/x86_64/

# 创建ks.cfg应答文件
vim /var/www/html/ks/ks-openeuler-20.03-LTS-x86.cfg
chmod -R 755 /var/www/html
```

/var/www/html/ks/ks-openeuler-20.03-LTS-x86.cfg 文件内容

```
# Use graphical install
graphical

install
url --url=http://1.1.1.21/openeuler_20.03-LTS-SP1/isos/x86_64/

%packages
@^minimal-environment

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

### tftp服务配置

```
rm -rf /var/lib/tftpboot/*
rm -rf /root/usr
mkdir /var/lib/tftpboot/pxelinux.cfg

# 提取 menu.c32 和 pxelinux.0
cp /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/Packages/syslinux-nonlinux-6.04-5.oe1.noarch.rpm /root/
rpm2cpio syslinux-nonlinux-6.04-5.oe1.noarch.rpm | cpio -idv ./usr/share/syslinux/menu.c32
rpm2cpio syslinux-nonlinux-6.04-5.oe1.noarch.rpm | cpio -idv ./usr/share/syslinux/pxelinux.0
cp /root/usr/share/syslinux/menu.c32 /var/lib/tftpboot/
cp /root/usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

# 拷贝内核启动文件
cp /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/isolinux/vmlinuz /var/lib/tftpboot/
cp /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/isolinux/initrd.img /var/lib/tftpboot/
cp /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/isolinux/vesamenu.c32 /var/lib/tftpboot/

# 拷贝菜单配置文件
cp /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/isolinux/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default

cp /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/isolinux/ldlinux.c32 /var/lib/tftpboot/
cp /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/isolinux/libutil.c32 /var/lib/tftpboot/
cp /var/www/html/openeuler_20.03-LTS-SP1/isos/x86_64/isolinux/libcom32.c32 /var/lib/tftpboot/

chmod -R 755 /var/lib/tftpboot/*
systemctl restart tftp
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
  append initrd=initrd.img ks=http://1.1.1.21/ks/ks-isoft-6.0-x86.cfg
```

# aarch64

## 服务端配置

### dhcp服务配置

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

## isoft_6.0_aarch64

### http服务配置

创建目录

```
# 创建目录
mkdir -p /var/www/html/isoft_6.0/isos/aarch64/

# 挂载镜像文件
mount -o loop /root/iSoft-Taiji-Server-OS-6.0-aarch64-202201240952.iso /var/www/html/isoft_6.0/isos/aarch64/

# 创建ks.cfg应答文件
vim /var/www/html/ks/ks-isoft-6.0-aarch64.cfg
chmod -R 755 /var/www/html
```

ks-isoft-6.0-aarch64.cfg 文件内容

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

### tftp服务配置

```bash
rm -rf /var/lib/tftpboot/*

cp /var/www/html/isoft_6.0/isos/aarch64/EFI/BOOT/grub.cfg /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/aarch64/EFI/BOOT/grubaa64.efi /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/aarch64/images/pxeboot/vmlinuz /var/lib/tftpboot/
cp /var/www/html/isoft_6.0/isos/aarch64/images/pxeboot/initrd.img /var/lib/tftpboot/

chmod -R 755 /var/lib/tftpboot/*
systemctl restart tftp
```

vim /var/lib/tftpboot/grub.cfg

```
set default="1"

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

set timeout=6
### END /etc/grub.d/00_header ###

search --no-floppy --set=root -l 'iSoft-Taiji-Server-OS-6.0'

### BEGIN /etc/grub.d/10_linux ###
menuentry 'Install iSoft-Taiji-Server-OS 6.0 with GUI mode' --class red --class gnu-linux --class gnu --class os {
        set root=(tftp,1.1.1.21)
        linux  /vmlinuz ro inst.geoloc=0 console=ttyAMA0 console=tty0 rd.iscsi.waitnet=0  inst.repo=http://1.1.1.21/isoft_6.0/isos/aarch64/ inst.ks=http://1.1.1.21/ks/ks-isoft-6.0-aarch64.cfg
        initrd /initrd.img
}
}
```

## icloud_1.0_aarch64

> 这里 iso 没有直接挂载到 apache 目录，是因为该 iso 文件 Packages 目录中有个别软件包没有读取权限，直接挂载无法修改权限

### http服务配置

创建目录

```
# 创建目录
mkdir -p /var/www/html/icloud_1.0/isos/aarch64/

# 挂载镜像文件
mount -o loop /root/iCloudOS-1.0-aarch64-2021-0805-1423-test-1.iso /mnt/
cp -r /mnt/* /var/www/html/icloud_1.0/isos/aarch64/

# 上传 ks.cfg 应答文件
vim /var/www/html/ks/ks-icloud-1.0-aarch64.cfg
chmod -R 755 /var/www/html
```

ks-icloud-1.0-aarch64.cfg 文件内容

```
#version=RHEL8
ignoredisk --only-use=vda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel
# Use graphical install
graphical
# Use CDROM installation media
install
url --url=http://1.1.1.21/icloud_1.0/isos/aarch64/
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

reboot
```

### tftp服务配置

```
rm -rf /var/lib/tftpboot/*

cp /var/www/html/icloud_1.0/isos/aarch64/EFI/BOOT/grub.cfg /var/lib/tftpboot/
cp /var/www/html/icloud_1.0/isos/aarch64/EFI/BOOT/grubaa64.efi /var/lib/tftpboot/
cp /var/www/html/icloud_1.0/isos/aarch64/images/pxeboot/vmlinuz /var/lib/tftpboot/
cp /var/www/html/icloud_1.0/isos/aarch64/images/pxeboot/initrd.img /var/lib/tftpboot/

chmod -R 755 /var/lib/tftpboot/*
systemctl restart tftp
```

vim /var/lib/tftpboot/grub.cfg

```
set default="1"

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

set timeout=6
### END /etc/grub.d/00_header ###

search --no-floppy --set=root -l 'iCloudOS-1.0-aarch64'

### BEGIN /etc/grub.d/10_linux ###
menuentry 'Install iCloudOS 1.0 with GUI mode' --class red --class gnu-linux --class gnu --class os {
        set root=(tftp,1.1.1.21)
        linux  /vmlinuz ro inst.geoloc=0 console=ttyAMA0 console=tty0 rd.iscsi.waitnet=0 inst.repo=http://1.1.1.21/icloud_1.0/isos/aarch64 inst.ks=http://1.1.1.21/ks/ks-icloud-1.0-aarch64.cfg
        initrd /initrd.img
}
```

## openeuler_20.03-LTS_aarch64

### http服务配置

创建目录

```
# 创建目录
mkdir -p /var/www/html/openeuler_20.03-LTS/isos/aarch64/

# 挂载镜像文件
mount -o loop /root/openEuler-20.03-LTS-aarch64-dvd.iso /var/www/html/openeuler_20.03-LTS/isos/aarch64/

# 创建ks.cfg应答文件
vim /var/www/html/ks/ks-openeuler-20.03-LTS-aarch64.cfg
chmod -R 755 /var/www/html
```

ks-openeuler-20.03-LTS-aarch64.cfg 文件内容

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
url --url=http://1.1.1.21/openeuler_20.03-LTS/isos/aarch64
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
@^minimal-environment

%end


%anaconda
pwpolicy root --minlen=8 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=8 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=8 --minquality=1 --notstrict --nochanges --notempty
%end

reboot
```

### tftp服务配置

```bash
rm -rf /var/lib/tftpboot/*

cp /var/www/html/openeuler_20.03-LTS/isos/aarch64/EFI/BOOT/grub.cfg /var/lib/tftpboot/
cp /var/www/html/openeuler_20.03-LTS/isos/aarch64/EFI/BOOT/grubaa64.efi /var/lib/tftpboot/
cp /var/www/html/openeuler_20.03-LTS/isos/aarch64/images/pxeboot/vmlinuz /var/lib/tftpboot/
cp /var/www/html/openeuler_20.03-LTS/isos/aarch64/images/pxeboot/initrd.img /var/lib/tftpboot/

chmod -R 755 /var/lib/tftpboot/*
systemctl restart tftp
```

vim /var/lib/tftpboot/grub.cfg

```
set default="1"

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

search --no-floppy --set=root -l 'openEuler-20.03-LTS-aarch64'

### BEGIN /etc/grub.d/10_linux ###
menuentry 'Install openEuler 20.03 LTS' --class red --class gnu-linux --class gnu --class os {
        set root=(tftp,1.1.1.21)
        linux  /vmlinuz ro inst.geoloc=0 console=ttyAMA0 console=tty0 rd.iscsi.waitnet=0  inst.repo=http://1.1.1.21/openeuler_20.03-LTS/isos/aarch64/ inst.ks=http://1.1.1.21/ks/ks-openeuler-20.03-LTS-aarch64.cfg
        initrd /initrd.img
}
}
```

# 参考

https://docs.openeuler.org/zh/docs/20.03_LTS_SP1/docs/Installation/%E4%BD%BF%E7%94%A8kickstart%E8%87%AA%E5%8A%A8%E5%8C%96%E5%AE%89%E8%A3%85.html

https://blog.csdn.net/weixin_45651006/article/details/103067283

https://blog.csdn.net/qq_44839276/article/details/106980334
