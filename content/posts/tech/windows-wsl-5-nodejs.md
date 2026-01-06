---
title: "wsl | 安装配置 nodejs 环境"
date: 2024-01-23
lastmod: 2025-12-18
tags:
  - wsl
keywords:
  - windows
  - wsl
  - nodejs
  - npm
description: "wsl 中安装 nodejs 环境, 以及修改默认源等配置"
cover:
    image: "images/cover-wsl.png"
---

# 0 前言

在 wsl2 中安装配置 nodejs 环境, 使用 nvm 管理版本

# 1 安装

```bash
# 自动获取最新版本的 nvm 并安装
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/install.sh" | bash
source ~/.bashrc # 或者重新进一下终端
nvm -v
```

安装 nodejs

```bash
nvm install --lts
nvm use --lts
node --version
```

# 2 配置

## 2.1 修改默认源地址

```bash
npm config set registry https://registry.npmmirror.com
npm config get registry
```

## 2.2 安装组件

```bash
npm install -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli
npm install -g @openai/codex
```

以上
