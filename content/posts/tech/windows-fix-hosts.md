---
title: "windows | hosts 文件修复" 
date: 2022-10-09
lastmod: 2024-01-28
tags:
  - windows
keywords:
  - windows
  - host
  - cmd
description: "介绍 win10 中修复 hosts 文件的方法"
cover:
    image: "images/default-cover.webp"
---

之前本地做一些测试的时候多次修改过 `hosts` 文件，导致 hosts 文件出现了某些问题，按照网上很多方式自建 hosts 文件、修改编码格式、包括使用一些第三方工具修复都没有作用，记录一下成功修复 hosts 文件的步骤

使用管理员权限打开命令提示符

![image-20221009105124283](/images/image-20221009105124283.png)

执行如下代码

```powershell
for /f %P in ('dir %windir%\WinSxS\hosts /b /s') do copy %P %windir%\System32\drivers\etc & echo %P & Notepad %P
```

以上
