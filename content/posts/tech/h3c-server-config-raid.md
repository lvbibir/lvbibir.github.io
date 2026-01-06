---
title: "H3C 服务器配置 raid" 
date: 2021-08-01
lastmod: 2024-01-28
tags:
  - linux
keywords:
  - linux
  - 服务器
  - raid
  - H3C
description: "记录一下 H3C 服务器配置 raid 的过程" 
cover:
    image: "images/cover-default.webp" 
---

1. 进入 bios 修改启动模式，将 UEFI 改为 Legacy bios
2. 重启服务器，ctrl + r 进入 lsi 阵列卡管理

![img](/images/image004(08-26-10-12-53).jpg)

1. 选择对应阵列卡

![img](/images/image005(08-26-10-12-53).jpg)

1. 配置逻辑盘

![img](/images/image006(08-26-10-12-53).jpg)

1. 配置完逻辑盘后可以选择从某一块逻辑盘启动

Ctrl-P 进入到 ctrl mgmt. -> TAB 切换到 boot device

![img](/images/image007(08-26-10-12-53).jpg)

回车后可以看到当前的逻辑盘，上下选择要引导的逻辑盘即可。

![img](/images/image008(08-26-10-12-53).jpg)

Apply 保存退出完成。

![img](/images/image009(08-26-10-12-53).jpg)

以上
