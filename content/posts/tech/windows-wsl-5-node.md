---
title: "wsl | 安装配置 nodejs 环境"
date: 2024-01-23
lastmod: 2024-01-23
tags:
  - wsl
keywords:
  - windows
  - wsl
  - nodejs
  - npm
description: "wsl 中安装 nodejs 环境, 以及修改默认源等配置"
cover:
    image: "https://image.lvbibir.cn/blog/logo-wsl.png"
---

# 0.前言

在 wsl2 中安装配置 nodejs 环境

# 1.安装

在 [此页面](https://nodejs.org/en/download/) 选择 linux x64 版本的链接, 复制链接地址

链接及目录自行修改, 这里我将 nodejs 的目录放到了 wsl 用户主目录下

```bash
wget  https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz
mv node-v20.11.0-linux-x64 nodejs
mv nodejs ~/

cat >> ~/.bashrc <<- 'EOF'
export PATH=${HOME}/nodejs/bin:$PATH
EOF

source ~/.bashrc
```

测试

```bash
node -v
npm -v
```

# 2.配置

## 2.1 修改默认源地址

```bash
npm config set registry https://registry.npmmirror.com
npm config get registry
```
