---
title: "vscode | 常见问题"
date: 2022-06-01
lastmod: 2024-01-28
tags:
  - vscode
keywords:
  - vscode
  - windows
  - ssh
description: "记录一下 vscode 使用过程中一些常见的问题, 比如 remote ssh 使用密钥登录, vscode 右键菜单消失等问题"
cover:
    image: "images/default-cover.webp"
---

# 1 remote ssh 使用密钥

remote ssh 远程服务器时每次都要求输入密码, 可以通过密钥实现免密登录

修改 ssh 配置文件, 一般在 `C:\Users\<username>\.ssh\config`, 配置文件的路径取决于 remote ssh 使用的配置文件, 在文件内添加私钥的路径即可, 如下

```plaintext
Host lvbibir.cn
  HostName lvbibir.cn
  User root
  IdentityFile C:\Users\lvbibir\.ssh\id_rsa
```

# 2 右键菜单问题

前端时间突然发现文件和目录的右键菜单中的 `在 vscode 中打开` 消失, 可以将下述代码保存为 `.reg` 文件并以管理员运行, ==记得将目录修改为正确的 vscode 安装路径==

```plaintext
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\*\shell\VSCode]
@="Open with Code"
"Icon"="D:\\software\\Vscode\\Code.exe"

[HKEY_CLASSES_ROOT\*\shell\VSCode\command]
@="\"D:\\software\\Vscode\\Code.exe\" \"%1\""

Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\shell\VSCode]
@="Open with Code"
"Icon"="D:\\software\\Vscode\\Code.exe"

[HKEY_CLASSES_ROOT\Directory\shell\VSCode\command]
@="\"D:\\software\\Vscode\\Code.exe\" \"%V\""

Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode]
@="Open with Code"
"Icon"="D:\\software\\Vscode\\Code.exe"

[HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode\command]
@="\"D:\\software\\Vscode\\Code.exe\" \"%V\""

```

以上
