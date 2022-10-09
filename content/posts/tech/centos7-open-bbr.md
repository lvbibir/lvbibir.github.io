---
title: "centos7开启bbr算法" 
date: 2021-08-01
lastmod: 2021-08-01
tags: 
- linux
- centos
keywords:
- linux
- centos
- bbr
- kernel
description: "" 
cover:
    image: "" 
---
# 前言

介绍在CentOS7上部署BBR的详细过程

BBR简介：（Bottleneck Bandwidth and RTT）是一种新的拥塞控制算法，由Google开发。有了BBR，Linux服务器可以显着提高吞吐量并减少连接延迟

# 1. 查看当前内核版本

```
uname -r
```

显示当前内核为3.10.0，因此我们需要更新内核

# 2. 使用 ELRepo RPM 仓库升级内核

```
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org                 //无返回内容
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
```

使用ELRepo repo更新安装5.12.3内核

`yum --enablerepo=elrepo-kernel install kernel-ml -y`

更新完成后，执行如下命令，确认更新结果

`rpm -qa | grep kernel`

`kernel-ml-5.12.3-1.el7.elrepo.x86_64`  //为更新后文件版本

# 3. 通过设置默认引导为 grub2 ，来启用5.12.3内核

`egrep ^menuentry /etc/grub2.cfg | cut -f 2 -d \'`

根据显示结果得知5.12.3内核处于行首，对应行号为 0 执行以下命令将其设置为默认引导项

`grub2-set-default 0`

# 4. 重启系统并确认内核版本

`shutdown -r now    or    reboot`

当服务器重新联机时，请进行root登录并重新运行uname命令以确认您当前内核版本

`uname -r`

至此完成内核更新与默认引导设置

# 5. 启用BBR

执行命令查看当前拥塞控制算法

`sysctl -n net.ipv4.tcp_congestion_control`

启用 BBR 算法，需要对 sysctl.conf 配置文件进行修改，依次执行以下每行命令

```
echo 'net.core.default_qdisc=fq' | tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' | tee -a /etc/sysctl.conf
sysctl -p
```

进行BBR的启用验证

```
sysctl net.ipv4.tcp_available_congestion_control
sysctl -n net.ipv4.tcp_congestion_control
```

最后检查BBR模块是否已经加载

`lsmod | grep bbr`

至此，BBR的部署已全部完成。

# 参考

https://blog.csdn.net/desertworm/article/details/116759380

