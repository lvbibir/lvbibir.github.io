---
title: "atd服务报错 Failed with result ‘exit-code’" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- linux
- 故障处理
keywords:
- linux
- atd
- 故障处理
description: "因为一次不小心的手动执行导致的" 
cover:
    image: "" 
---



有需求需要测试下 at 单次计划任务，系统环境 isoftserveros-v5.1-oe1-aarch64

系统默认没有at软件包，使用本地yum源安装：

```
yum -y install at
```
安装完后不小心执行了下atd
```
atd
```
因为at计划任务需要atd守护进程运行
```
systemctl start atd
systemctl enable atd
```
开始测试at计划任务，发现无论如何就是不执行
开始进行排查
![在这里插入图片描述](https://image.lvbibir.cn/blog/20210624154625704.png)

在Process行可以看到atd的后台进程是通过命令 /usr/sbin/atd -f $OPTS 运行的

![在这里插入图片描述](https://image.lvbibir.cn/blog/2021062415480962.png)

发现了之前手动执行的atd，这个时候systemctl restart atd也无法杀死这个进程并开启新的守护进程

尝试kill掉这个进程，再起atd服务

```
kill 27337
systemctl restart atd
systemctl status atd
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/2021062415512739.png)

已经正常运行了