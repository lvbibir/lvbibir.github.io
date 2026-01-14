---
title: "nodejs | fnm + pnpm 开发环境配置"
date: 2024-01-23
lastmod: 2026-01-14
tags:
  - nodejs
keywords:
  - nodejs
  - fnm
  - pnpm
  - bun
description: "使用 fnm 管理 Node.js 版本, pnpm 管理依赖, 包含网络优化与警告抑制配置"
cover:
    image: "images/cover-nodejs.svg"
---

# 0 前言

Node.js 版本管理工具主要有 nvm 和 fnm 两种选择:

- **fnm**: Rust 编写, 启动速度快, 跨平台支持好, 内存占用小, 推荐优先使用
- **nvm**: 社区成熟稳定, 文档和生态丰富, 但 shell 脚本实现导致启动较慢, 且不原生支持 Windows

两者都支持 `.nvmrc` 和 `.node-version` 文件, 可根据项目自动切换版本.

---

Node.js 包管理工具主要有 npm, yarn, pnpm, bun 四种选择:

- **pnpm**: 硬链接 + 符号链接共享依赖, 安装速度快, 磁盘占用最小, 严格的依赖隔离避免幽灵依赖, 推荐优先使用
- **bun**: Zig 编写的全能工具 (运行时 + 包管理 + 打包 + 测试), 安装速度极快, 但生态较新, 部分 Node.js API 兼容性待完善
- **yarn**: Facebook 开发, 并行安装速度快, lockfile 可靠, 但 v1 和 v2+ 架构差异大, 功能与 npm 趋同
- **npm**: Node.js 内置, 零配置开箱即用, 生态最成熟, 但安装速度较慢, node_modules 扁平化导致幽灵依赖问题

# 1 安装 nodejs

fnm 和 nvm 二选一即可, 建议使用 fnm

## 1.1 fnm

```bash
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc

fnm install 24 # 安装 v24 的最新版
fnm default 24 # 设置全局默认的 node 版本为 v24
```

修改 `~/.bashrc`, 添加 `--use-on-cd` 参数, 可以在切换目录的时候自动识别 `.nvmrc` 和 `.node-version`, fnm 可以自动切换版本

```bash

# fnm
FNM_PATH="${HOME}/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env --use-on-cd`"
fi
```

## 1.2 nvm

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

# 2 安装 pnpm

```bash
npm install -g pnpm
pnpm setup
source ~/.bashrc
```

# 3 pnpm 配置优化

## 3.1 网络配置

```bash
# 镜像源 (国内推荐 npmmirror, 海外保持官方源)
pnpm config set --global registry https://registry.npmmirror.com
pnpm config set --global registry https://registry.npmjs.org
# 网络超时与重试
pnpm config set --global fetch-retries 5
pnpm config set --global fetch-retry-maxtimeout 120000
pnpm config set --global fetch-timeout 180000
pnpm config set --global prefer-offline true
```

## 3.2 抑制警告

pnpm 安装时常见大量 WARNING, 主要来源于 peer dependencies 和 deprecated 包.

```bash
# 日志级别设为 error, 只显示错误
# 自动安装 peer dependencies, 减少 missing peer 警告
# 出现 peer dependencies 问题不阻断安装
pnpm config set --global loglevel error
pnpm config set --global auto-install-peers true
pnpm config set --global strict-peer-dependencies false
```

# 4 安装组件

```bash
pnpm install -g @anthropic-ai/claude-code
pnpm install -g @google/gemini-cli
pnpm install -g @openai/codex
```

以上
