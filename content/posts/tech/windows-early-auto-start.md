---
title: "windows | 自定义开机快速启动项" 
date: 2023-08-14
lastmod: 2023-08-14
tags: 
- windows
keywords:
- windows
description: "" 
---

# 0. 前言

最近注意到 windows 系统中当 onedrive 和 clash 同时开机自启时会导致 onedrive 无法自动登录, 需要退出 onedrive 重新启动一下才能正常登录.

出现这个问题的原因是 onedrive 启动速度要比 clash 快, 导致 onedrive 启动时访问不到 clash. 其实只要将这两个其中一个不设置为开机自启即可解决, 但是这两个都是刚需, 放下任何一个都会不舒服.

一番 google 下来, 大部分的解决方案都是添加 windows 的计划任务, 我尝试了半天也没办法无法成功, 最后终于找到了满足需求的 [解决方案](https://meta.appinn.net/t/topic/13337/2), 使用 [EarlyStart](https://github.com/sylveon/EarlyStart) 实现在 windows explorer 启动前就启动自定义的软件.

同时还能顺便解决之前感觉有点不舒服的两个问题:

- [TranslucentTB](https://github.com/TranslucentTB/TranslucentTB): 自启动时会慢一拍, 刚进系统时任务栏没有透明, 等个几秒启动后才能正常
- [utools](https://www.u.tools/): 同样的, 进系统后第一时间不能使用, 得等几秒启动后才行

# 1. 安装 EarlyStart

下载 [EarlyStart.zip](https://github.com/sylveon/EarlyStart/releases/download/1.0.0/EarlyStart.zip)

解压后使用管理员打开 powershell 并进入安装目录

```powershell
cd D:\software\1-portable\EarlyStart
# 安装
C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe .\EarlyStart.exe
# 卸载
C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /u .\EarlyStart.exe
```

![image-20230815025246249](https://image.lvbibir.cn/blog/image-20230815025246249.png)

# 2. 配置启动项

首先将要配置快速启动的应用默认的开机自启给关掉

在用户目录 `C:\Users\<username>` 创建一个名为 `.earlystart` 的文件, 每一行输入一个 exe 的路径

![image-20230815025643880](https://image.lvbibir.cn/blog/image-20230815025643880.png)

然后还需要修改一下账户配置

![image-20230815025823228](https://image.lvbibir.cn/blog/image-20230815025823228.png)

配置完成之后重启系统即可

以上.
