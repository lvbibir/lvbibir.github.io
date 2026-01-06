---
title: "wsl | win10 安装 wsl2"
date: 2024-01-10
lastmod: 2025-12-25
tags:
  - wsl
keywords:
  - windows
  - wsl
description: "win10 系统安装 wsl2(ubuntu-20.04) 到 D 盘以及更换系统源到清华源"
cover:
    image: "images/logo-wsl.png"
---

# 0 前言

本文内容参考以下链接:

- <https://zhuanlan.zhihu.com/p/466001838>
- <https://learn.microsoft.com/zh-cn/windows/wsl/install-manual>

今天不小心把我电脑的 wsl 误删了, 刚好重装记录一下安装步骤

```bash
# 这种方式似乎也可以, 未验证
# https://linux.do/t/topic/1015067
wsl --install ubuntu-24.04 --name ubuntu-24.04 --location D:\ubuntu
```

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

# 2 配置

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

## 2.2 alias 配置

```bash
cat .bashrc
alias ll='ls -l'
alias di='sudo docker images'
alias dp='sudo docker ps'
alias dc='sudo docker compose'
alias python='echo "dont use python! use uv run"'
alias pip='echo "dont use pip! use uv pip or uv add"'
```

以上

