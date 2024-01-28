---
title: "wsl | win10 安装 wsl2"
date: 2024-01-10
lastmod: 2024-01-28
tags:
  - wsl
keywords:
  - windows
  - wsl
description: "win10 系统安装 wsl2(ubuntu-20.04) 到 D 盘以及更换系统源到清华源"
cover:
    image: "https://image.lvbibir.cn/blog/logo-wsl.png"
---

# 0 前言

本文内容参考以下链接:

- <https://zhuanlan.zhihu.com/p/466001838>
- <https://learn.microsoft.com/zh-cn/windows/wsl/install-manual>

今天不小心把我电脑的 wsl 误删了, 刚好重装记录一下安装步骤

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

## 1.2 安装内核更新包

点击 [此链接](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi) 下载内核更新包, 右击安装即可

## 1.3 安装 wsl 到 D 盘

> 如果不需要装到其他盘, 1.3 的步骤无需操作
> 直接 powershell 执行 wsl --install -d Ubuntu-20.04 即可

通过 chrome 或者 IDM 输入 `https://aka.ms/wslubuntu2004` 下载安装包, chrome 可能会提示未经验证, 直接无视后保存即可

或者执行如下 powershell 命令下载

```powershell
cd D:\
Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu.appx -UseBasicParsing
# 或者使用 curl 下载
curl.exe -L -o ubuntu-2004.appx https://aka.ms/wslubuntu2004
```

将下载后的文件后缀直接改为 zip, , 再将 `x64` 的 appx 文件后缀改成 zip, 将此 zip 解压到指定目录, 此目录就是后续 ubuntu 存放数据的地方, 我这里放到了 `D:\ubuntu` 目录

最后执行解压后的 exe 进行安装, 按照提示设置账号密码即可

```powershell
cd D:\ubuntu
.\ubuntu2004.exe
```

## 1.4 更换系统源

cmd 或者 powershell 中执行 wsl 进入 ubuntu, 更换系统源

```bash
sudo apt-get install --only-upgrade ca-certificates
sudo cp /etc/apt/sources.list /etc/apt/sources.list.origin

sudo cat > /etc/apt/sources.list <<- 'EOF'
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
EOF

sudo apt-get update
```

以上
