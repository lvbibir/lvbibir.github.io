---
title: "wsl | win10 安装 wsl2"
date: 2024-01-10
lastmod: 2026-07-17
tags:
  - wsl
keywords:
  - windows
  - wsl
description: "win10 系统安装 wsl2(ubuntu2404)" 
cover:
    image: "images/cover-wsl.png"
---

# 0 前言

# 1 安装

## 1.1 打开系统功能

首先通过管理员打开 powershell 执行如下指令, 用于打开系统功能

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

然后在 `Microsoft Store` 中安装 `Windows Subsystem for Linux`

安装好之后重启

重启完成后在 powershell 执行

```powershell
wsl --set-default-version 2
```

## 安装 Ubuntu2404

下载 [wsl-dashboard](https://github.com/owu/wsl-dashboard/) 最新版本直接安装即可

# 2 配置

参考 [另一篇博文](https://www.lvbibir.cn/posts/tech/ubuntu-installation)

## 2.1 后台保活

如果没有任何活动的 wsl 终端, 每过一段时间 windows 会将 wsl 关闭, 导致想要使用的时候需要等它启动一段时间以及一些其他的问题

可以通过 vbs 脚本简单实现这个功能

```VBScript
Set shell = CreateObject("WScript.Shell")
' 这里的 Ubuntu 替换成你实际的发行版名称
' 0 代表隐藏运行，False 代表不需要等待进程结束
shell.Run "wsl.exe -d Ubuntu-20.04 -u root -- sleep infinity", 0, False
```

直接双击运行就可以了, 后台会跑一个无感的 wsl 进程

如果需要开机运行可以把这个 vbs 脚本放到开机自启目录中, 通过 `windows + r` 调出运行控制台, 然后输入 `shell:startup` 回车即可打开 windows 自启动目录.

以上
