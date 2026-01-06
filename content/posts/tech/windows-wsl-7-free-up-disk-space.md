---
title: "wsl | 释放长久运行占用的磁盘空间"
date: 2025-04-24
lastmod: 2025-04-24
tags:
  - wsl
keywords:
  - windows
  - wsl
description: "wsl 运行一段时间后, windows 系统中的虚拟磁盘文件占用空间越来越大, 在 wsl 中删除文件也无法释放这部分空间, 几步操作轻松释放"
cover:
    image: "images/cover-wsl.png"
---

# 0 前言

[本文参考](https://zhuanlan.zhihu.com/p/641436638)

wsl 运行一段时间后, windows 系统中的虚拟磁盘文件占用空间越来越大, 在 wsl 中删除文件也无法释放这部分空间

# 1 释放空间

首先最重要是在 wsl 先清理自己不需要的大文件, 可以在 wsl 中执行如下命令查看当前目录下所有文件或者目录的占用空间, 然后一层层排查

```bash
sudo su -
cd /
for i in $(ls | grep -v mnt); do du -sh $i; done
```

删除完 wsl 中的大文件后, 在 powershell 中执行 `wsl --shutdown` 关闭 wsl

下一步是找到 wsl 虚拟磁盘文件的位置, 如果是按照博主之前的 [文章](https://www.lvbibir.cn/posts/tech/windows-wsl-1-install/) 操作安装 wsl 的朋友, 虚拟磁盘位置在 `D:\ubuntu\ext4.vhdx`

如果是默认安装的话, 磁盘文件位置大概在 `C:\Windows\User\<username>\AppData\Local\Packages\***Ubuntu***\LocalState\` 目录下

之后在 powershell 中执行如下操作即可压缩磁盘空间

```powershell
diskpart
select vdisk file='D:\ubuntu\ext4.vhdx'
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

应运行成功, 博主成功释放 100G 空间.

以上.
