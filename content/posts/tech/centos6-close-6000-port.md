---
title: "centos6关闭本地监听的6000端口" 
date: 2022-01-01
lastmod: 2022-01-01
tags: 
- linux
- CVE
keywords:
- linux
- CVE
description: "介绍如何在centos6中修复CVE-1999-0526披露的漏洞" 
cover:
    image: "" 
---
# 前言

基于CVE-1999-0526漏洞的披露，对系统X服务的6000端口进行关闭

有三种方式：

- 修改系统/usr/bin/X内容，增加nolisten参数
- 开启系统防火墙，关闭6000端口的对外访问
- 禁用桌面(runlevel-5)，开机进入字符界面(runlevel-3)

# 修改/usr/bin/X脚本

## 关闭

```
rm -f /usr/bin/X

vim /usr/bin/X

###################
添加如下内容
#!/bin/bash
exec /usr/bin/Xorg "$@" -nolisten tcp
exit 0
####################

chmod 777 /usr/bin/X

kill -9 进程号 # ps -elf |grep X 显示的进程号
```

![image-20220214130429656](https://image.lvbibir.cn/blog/image-20220214130429656.png)

## 恢复

```
rm -f /usr/bin/X
ln -s /usr/bin/Xorg /usr/bin/X
kill -9 进程号 # pe -elf | grep Xorg 显示的进程号
```

![image-20220214130544760](https://image.lvbibir.cn/blog/image-20220214130544760.png)

<font color='red'>**在测试过程中出现过杀死X服务进程后没有自启的情况，可尝试使用 init 3 && init 5 尝试重新启动X服务**</font>

# 修改防火墙方式

```
# 开启除6000端口以外的所有端口(6000端口无法访问)
systemctl start firewalld
firewall-cmd --permanent --zone=public --add-port=1-65535/udp
firewall-cmd --permanent --zone=public --add-port=1-5999/tcp
firewall-cmd --permanent --zone=public --add-port=6001-65535/tcp
firewall-cmd --reload
firewall-cmd --list-all

# 恢复（6000端口可以访问）
firewall-cmd --permanent --zone=public --add-port=6000/tcp
firewall-cmd --reload
firewall-cmd --list-all
```

# 参考

https://bugzilla.redhat.com/show_bug.cgi?id=1647621
