---
title: "wsl | bashrc 环境变量不正确加载的处理方法"
date: 2024-01-11
lastmod: 2024-01-13
tags:
  - wsl
keywords:
  - windows
  - wsl
  - bashrc
  - environment
description: "wsl2 使用过程中 .bashrc 无法正确加载的解决办法"
cover:
    image: "https://source.unsplash.com/random/400x200?code"
---

# 0.前言

装完 wsl 后发现用户目录下的 `.bashrc` 文件总是无法正常读取, github 上关于此问题的 [讨论](https://github.com/microsoft/WSL/issues/3279) 也没有比较好的解决方法

# 1.解决办法

我这里取巧了一下, 在 `.bash_profile` 中再调用一下 `.bashrc`, 如下

```bash
echo >> ${HOME}/.bash_profile <<- 'EOF'
source ${HOME}/.bashrc
EOF

source ${HOME}/.bash_profile
```

以上
