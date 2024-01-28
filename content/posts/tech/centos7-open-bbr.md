---
title: "centos7 | 开启 bbr 算法" 
date: 2021-08-01
lastmod: 2024-01-27
tags: 
  - linux
  - centos
keywords:
  - linux
  - centos
  - bbr
  - kernel
description: "介绍在 CentOS7 上部署 BBR 的详细过程" 
cover:
    image: "https://source.unsplash.com/random/400x200?code" 
---

# 0 前言

BBR 简介：（Bottleneck Bandwidth and RTT）是一种新的拥塞控制算法，由 Google 开发。有了 BBR，Linux 服务器可以显着提高吞吐量并减少连接延迟

本文参考以下链接:

- [介绍在 CentOS7 上部署 BBR 的详细过程](https://blog.csdn.net/desertworm/article/details/116759380)

# 1 更新内核

查看当前内核版本

```bash
uname -r
```

显示当前内核为 3.10.0，因此我们需要更新内核

使用 ELRepo RPM 仓库升级内核

```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org                 //无返回内容
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
```

使用 ELRepo repo 更新安装 5.12.3 内核

```bash
yum --enablerepo=elrepo-kernel install kernel-ml -y
```

更新完成后，执行如下命令，确认更新结果

```bash
rpm -qa | grep kernel
# kernel-ml-5.12.3-1.el7.elrepo.x86_64
```

通过设置默认引导为 grub2 ，来启用 5.12.3 内核

```bash
egrep ^menuentry /etc/grub2.cfg | cut -f 2 -d '\'
```

根据显示结果得知 5.12.3 内核处于行首，对应行号为 0 执行以下命令将其设置为默认引导项

``` bash
grub2-set-default 0
```

重启系统并确认内核版本

```bash
reboot
uname -r
```

至此完成内核更新与默认引导设置

# 2 启用 BBR

执行命令查看当前拥塞控制算法

```bash
sysctl -n net.ipv4.tcp_congestion_control
```

启用 BBR 算法，需要对 sysctl.conf 配置文件进行修改，依次执行以下每行命令

```bash
echo 'net.core.default_qdisc=fq' | tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' | tee -a /etc/sysctl.conf
sysctl -p
```

进行 BBR 的启用验证

```bash
sysctl net.ipv4.tcp_available_congestion_control
sysctl -n net.ipv4.tcp_congestion_control
```

最后检查 BBR 模块是否已经加载

```bash
lsmod | grep bbr
```

以上
