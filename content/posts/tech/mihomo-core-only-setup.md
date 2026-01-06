---
title: "windows | mihomo 内核独立部署指南"
date: 2025-12-10
lastmod: 2025-12-15
tags:
  - windows
  - proxy
  - mihomo
keywords:
  - clash
  - mihomo
  - 代理
  - windows
description: "在 Windows 系统上使用 mihomo 内核独立部署代理服务, 无需依赖 GUI 客户端, 轻量高效"
cover:
    image: "images/cover-mihomo.png"
---

# 0 前言

mihomo (原 Clash.Meta) 是一个基于 Go 语言开发的高性能代理内核, 支持多种代理协议. 相比于使用 Clash Verge, Clash for Windows 等 GUI 客户端, 直接使用 mihomo 内核有以下优势:

- **轻量高效**: 无需运行 Electron 等重量级框架, 内存占用更低
- **启动更快**: 纯内核启动速度远快于 GUI 客户端
- **灵活可控**: 通过脚本管理, 可以更灵活地控制启停和配置
- **稳定性好**: 减少了 GUI 层面可能带来的问题

本文将介绍如何在 Windows 系统上独立部署 mihomo 内核, 并通过 PowerShell 脚本进行管理.

# 1 下载 mihomo 内核

前往 [mihomo releases](https://github.com/MetaCubeX/mihomo/releases) 页面下载最新版本.

根据你的系统架构选择对应的版本, windows 一般选择 `mihomo-windows-amd64-<version>.zip` 即可

下载后解压到你喜欢的目录, 例如: `D:\software\1-portable\mihomo\`

解压后目录结构如下:

```plaintext
mihomo/
├── mihomo-windows-amd64.exe    # mihomo 内核主程序
├── mihomo.yaml                 # 配置文件 (需自行创建)
└── mihomo-manager.ps1          # 管理脚本 (需自行创建)
```

# 2 配置文件

在 mihomo 目录下新建 `mihomo.yaml` 配置文件.

可参考 [我的配置](https://github.com/lvbibir/clash/blob/master/mihomo.yaml), 根据你的实际需求进行修改.

# 3 管理脚本

## 3.1 创建管理脚本

在 mihomo 目录下新建 `mihomo-manager.ps1` 脚本文件.

可参考 [我的脚本](https://github.com/lvbibir/clash/blob/master/mihomo-manager.ps1)

## 3.2 配置 PowerShell 执行策略

PowerShell 脚本默认无法直接运行, 需要修改执行策略.

以管理员身份打开 PowerShell, 执行:

```powershell
Set-ExecutionPolicy RemoteSigned
```

执行策略说明:

- **Restricted**: 默认策略, 不允许运行任何脚本
- **RemoteSigned**: 本地脚本可以运行, 从网络下载的脚本需要数字签名
- **Unrestricted**: 允许运行所有脚本 (不推荐)

## 3.3 设置脚本打开方式

为了方便双击运行脚本或通过 utools 等工具快捷调用:

1. 右键点击 `mihomo-manager.ps1` 文件
2. 选择 " 打开方式 " -> " 选择其他应用 "
3. 找到 PowerShell 并选择
4. 勾选 " 始终使用此应用打开 .ps1 文件 "

## 3.4 使用管理脚本

可以通过以下方式运行脚本:

**方式一: 双击运行**

直接双击 `mihomo-manager.ps1` 文件, 会弹出交互式菜单.

**方式二: 命令行运行**

在 PowerShell 中执行:

```powershell
.\mihomo-manager.ps1 start    # 启动 mihomo
.\mihomo-manager.ps1 stop     # 停止 mihomo
.\mihomo-manager.ps1 restart  # 重启 mihomo
.\mihomo-manager.ps1 status   # 查看运行状态
.\mihomo-manager.ps1 reload   # 重载配置文件
.\mihomo-manager.ps1 help     # 查看帮助信息
```

# 4 Web UI 管理

启动 mihomo 后, 如果按照我的配置应该已经自动下载好了 webui, 直接访问下面的地址就可以访问了, 如果没有正常下载请手动下载后解压到 mihomo 的 ui 目录.

访问地址: [http://127.0.0.1:9090/ui/zashboard/#/setup](http://127.0.0.1:9090/ui/zashboard/#/setup)

# 5 开机自启动

## 5.1 使用 EarlyStart (推荐)

如果你需要 mihomo 在系统启动早期就运行 (例如 OneDrive 等软件依赖代理), 推荐使用 [EarlyStart](https://github.com/sylveon/EarlyStart).

详细配置方法可参考我的这篇博客: [windows | 自定义开机快速启动项](https://www.lvbibir.cn/posts/tech/windows-early-auto-start/)

在 `%USERPROFILE%\.earlystart` 文件中添加:

```plaintext
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "D:\software\1-portable\mihomo\mihomo-manager.ps1" start
```

## 5.2 使用任务计划程序

1. 打开 " 任务计划程序 "
2. 创建基本任务
3. 触发器选择 " 计算机启动时 "
4. 操作选择 " 启动程序 "
5. 程序填写: `powershell.exe`
6. 参数填写: `-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "D:\software\1-portable\mihomo\mihomo-manager.ps1" start`

## 5.3 注册为系统服务

如果需要更稳定的后台运行方式, 可以使用 [NSSM](https://nssm.cc/) 将 mihomo 注册为 Windows 服务.

```powershell
# 下载 nssm 后执行
nssm install mihomo "D:\software\1-portable\mihomo\mihomo-windows-amd64.exe"
nssm set mihomo AppDirectory "D:\software\1-portable\mihomo"
nssm set mihomo AppParameters "-d ."
nssm start mihomo
```

# 6 总结

通过以上步骤, 你已经成功在 Windows 上部署了 mihomo 内核. 相比 GUI 客户端, 这种方式更加轻量和灵活, 适合追求简洁高效的用户.

相关链接:

- [mihomo 官方仓库](https://github.com/MetaCubeX/mihomo)
- [mihomo 官方文档](https://wiki.metacubex.one/)
- [我的配置文件](https://github.com/lvbibir/clash)

以上
