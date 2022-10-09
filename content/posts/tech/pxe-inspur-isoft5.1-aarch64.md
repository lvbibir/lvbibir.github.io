---
title: "pxe 安装 isoft-5.1(aarch64)" 
date: 2021-08-01
lastmod: 2021-08-01
tags: 
- linux
keywords:
- linux
- pxe
- aarch64
- dhcp
description: "" 
cover:
    image: "" 
---
# pxe环境

dhcp+tftp+http

pxe-server：isoft-serveros-v4.2（3.10.0-957.el7.isoft.x86_64）

引导的iso：isoft-serveros-aarch64-oe1-v5.1（4.19.90-2003.4.0.0036.oe1.aarch64）

物理服务器：浪潮 Inspur

# dhcpd.conf配置

```shell
[root@localhost isoft-5.1-arm]# vim /etc/dhcp/dhcpd.conf

default-lease-time 43200;
max-lease-time 345600;
option space PXE;
option arch code 93 = unsigned integer 16;

option routers 192.168.1.1;
option subnet-mask 255.255.255.0;
option broadcast-address 192.168.1.255;
option time-offset -18000;

ddns-update-style none;
allow client-updates;
allow booting;
allow bootp;

next-server 192.168.1.1;
if option arch = 00:07 or arch = 00:09 {
        filename "x86/bootx64.efi";
} else   {
        filename "arm/grubaa64.efi";
}
shared-network works {
  subnet 192.168.1.0 netmask 255.255.255.0 {
          range dynamic-bootp 192.168.1.221 192.168.1.253;
  }
}
```

# grub.cfg配置

```shell
[root@localhost tftpboot]# vim arm/grub.cfg

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

search --no-floppy --set=root -l 'iSoftServerOS-5.1-aarch64'

### BEGIN /etc/grub.d/10_linux ###
menuentry 'Install iSoftServerOS 5.1 with GUI mode' --class red --class gnu-linux --class gnu --class os {
#        linux /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=iSoftServerOS-5.1-aarch64 ro inst.geoloc=0 selinux=0
#        initrd /images/pxeboot/initrd.img
        linux /arm51/vmlinuz ip=dhcp method=http://192.168.1.1/isoft-5.1-arm ks=http://192.168.1.1/isoft-5.1-arm/anaconda-ks.cfg
        initrd /arm51/initrd.img
}
#menuentry 'Install iSoftServerOS 5.1 for ZF with GUI mode' --class red --class gnu-linux --class gnu --class os {
#       linux /arm51-zf/vmlinuz ip=dhcp  method=http://192.168.1.1/isoft-5.1-zfarm
#       initrd /arm51-zf/initrd.img
#}
```

# ks.cfg配置

```shell
[root@localhost isoft-5.1-arm]# vim anaconda-ks.cfg

lang zh_CN.UTF-8

# Network information
network  --bootproto=dhcp --device=eno1 --ipv6=auto --no-activate
network  --bootproto=dhcp --device=eno2 --ipv6=auto
network  --bootproto=dhcp --device=eno3 --ipv6=auto
network  --bootproto=dhcp --device=eno4 --ipv6=auto
network  --bootproto=dhcp --device=enp22s0f0 --ipv6=auto
network  --bootproto=dhcp --device=enp22s0f1 --ipv6=auto
network  --bootproto=dhcp --device=enp22s0f2 --ipv6=auto
network  --bootproto=dhcp --device=enp22s0f3 --ipv6=auto
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted $6$afv9h6qEnQTq3WSl$GHtOmvLkHrBin8vTWLbRaa2r.Ur9mUQR7XypWRoEWZYCwwJ2MnuMPxpNiNLSG1vSa5qBODHJcqIUUWkHm0IVl.
# SELinux configuration
selinux --disabled
# X Window System configuration information
xconfig  --startxonboot
# Run the Setup Agent on first boot
firstboot --enable
# System services
services --enabled="chronyd"
# System timezone
timezone Asia/Shanghai --isUtc
user --groups=wheel --name=testuser --password=$6$9SyzoTjQU2syj2Bk$SQ4WZAV/go3KeX6rJN3cieNpY4l7aU2wHxad75yWlbKBh.ithhrU/jfA09JUq7cb10D0QTCwtClmItfg/N47t. --iscrypted --gecos="testuser"
# Disk partitioning information
part /boot/efi --fstype="efi" --ondisk=sda --size=200 --fsoptions="umask=0077,shortname=winnt"
part pv.521 --fstype="lvmpv" --ondisk=sda --size=913974
part /boot --fstype="ext4" --ondisk=sda --size=1024
volgroup isoftserveros --pesize=4096 pv.521
logvol /home --fstype="xfs" --size=756272 --name=home --vgname=isoftserveros
logvol swap --fstype="swap" --size=4096 --name=swap --vgname=isoftserveros
logvol / --fstype="xfs" --size=153600 --name=root --vgname=isoftserveros

%packages
@^mate-desktop-environment
@additional-devel
@development
@file-server
@headless-management
@legacy-unix
@network-server
@network-tools
@scientific
@security-tools
@system-tools
@virtual-tools

%end


%anaconda
pwpolicy root --minlen=8 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=8 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=8 --minquality=1 --notstrict --nochanges --notempty
%end

reboot
```

