---
title: "python | 使用 uv 管理你的 python 环境"
date: 2025-12-23
lastmod: 2025-12-23
tags:
  - python
  - uv
keywords:
  - uv
  - python
  - 虚拟环境
  - 依赖管理
description: "介绍使用 uv 管理 Python 版本, 第三方模块和项目依赖"
cover:
    image: "https://image.lvbibir.cn/blog/logo-python.png" 
---

# 0 前言

本文基于 linux 环境所写, 采用 win10 中的 wsl2, 系统版本是 ubuntu-20.04, 已经很少使用 windows 原生环境开发了, 所以没有 windows 版本的教程, 但殊途同归, 大体过程是一样的

[uv](https://github.com/astral-sh/uv) 是一个用 Rust 编写的极速 Python 包管理器, 可替代 pip, pip-tools, pipx, poetry, pyenv, virtualenv 等工具

# 1 安装 uv

官方脚本安装

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

pip 安装

```bash
pip install uv
```

配置 PyPI 镜像源 (加速第三方包下载)

```bash
mkdir -p ~/.config/uv
cat > ~/.config/uv/uv.toml << 'EOF'
[[index]]
url = "https://mirrors.aliyun.com/pypi/simple"
default = true
EOF
```

# 2 Python 版本管理

列出可安装的版本

```bash
uv python list
```

安装指定版本

```bash
uv python install 3.12
uv python install 3.11.4
```

卸载指定版本

```bash
uv python uninstall 3.11
```

查看已安装版本

```bash
uv python list --only-installed
```

固定项目 Python 版本, 会创建 `.python-version` 文件

```bash
uv python pin 3.12
```

# 3 第三方模块管理

## 3.1 虚拟环境

创建虚拟环境

```bash
uv venv                        # 默认 .venv
uv venv --python 3.14.2 .venv    # 指定 python 版本
```

激活/退出虚拟环境

```bash
source .venv/bin/activate      # 激活
deactivate                     # 退出
```

## 3.2 安装模块

使用 `uv add` 项目依赖管理, `uv add` 会同时更新 `pyproject.toml` 和 `uv.lock`

```bash
uv add requests                         # 安装并添加到依赖
uv add requests==2.28.0                 # 指定版本
uv add --dev pytest                     # 添加开发依赖
uv remove requests                      # 移除依赖
```

也可以使用 uv pip 的方式, 但是不推荐在项目中使用, 非常不益于管理

使用 `uv pip` (类似传统 pip), `uv pip` 不会安装到系统 Python, 查找顺序: 已激活的虚拟环境 -> 当前目录 `.venv` -> 父目录 `.venv` -> 报错

```bash
uv pip install requests                 # 安装
uv pip install requests==2.28.0         # 安装指定版本
uv pip install --upgrade requests       # 升级
uv pip uninstall requests               # 卸载
```

# 4 项目依赖管理

## 4.1 初始化项目

```bash
uv init myproject              # 创建新项目
cd myproject
```

生成的项目结构

```plaintext
myproject/
├── .python-version            # Python 版本
├── pyproject.toml             # 项目配置和依赖声明
├── README.md
└── src/
    └── myproject/
        └── __init__.py
```

## 4.2 核心命令

| 命令 | 作用 |
|------|------|
| `uv add <pkg>` | 添加依赖到 pyproject.toml 并安装 |
| `uv remove <pkg>` | 移除依赖 |
| `uv lock` | 根据 pyproject.toml 生成/更新 uv.lock |
| `uv sync` | 根据 uv.lock 同步安装依赖到虚拟环境 |

## 4.3 uv lock 详解

`uv lock` 解析 `pyproject.toml` 中声明的依赖, 生成精确的 `uv.lock` 锁文件

```bash
uv lock                        # 生成/更新锁文件
uv lock --upgrade              # 升级所有依赖到最新版本
uv lock --upgrade-package requests  # 仅升级指定包
```

- `pyproject.toml`: 声明依赖范围, 如 `requests>=2.28`
- `uv.lock`: 记录精确版本和哈希, 确保可复现安装

## 4.4 uv sync 详解

`uv sync` 根据 `uv.lock` 将依赖精确安装到虚拟环境

```bash
uv sync                        # 同步所有依赖
uv sync --frozen               # 严格按 uv.lock 安装, 不更新锁文件
uv sync --no-dev               # 不安装开发依赖
```

# 5 常用工作流

## 5.1 新项目

```bash
uv init myproject && cd myproject
uv add requests pandas
uv run python main.py          # 直接运行, 自动处理虚拟环境
```

## 5.2 克隆已有项目

```bash
git clone <repo>
cd <repo>
uv sync                        # 根据 uv.lock 安装依赖
```

> `uv sync` 会自动读取 `.python-version`, 下载对应 Python 版本 (如未安装), 创建 `.venv`, 并安装依赖, 无需手动操作

## 5.3 更新依赖

```bash
uv lock --upgrade              # 更新所有依赖版本
uv sync                        # 同步到环境
```

## 5.4 已有项目迁移到 uv

从 requirements.txt 迁移

```bash
cd existing-project
uv init                        # 初始化, 生成 pyproject.toml
uv add -r requirements.txt     # 从 requirements.txt 导入依赖
rm requirements.txt            # 可选, 删除旧文件
```

从 pip/virtualenv 迁移

```bash
cd existing-project
uv init
uv venv                        # 创建新的虚拟环境
uv add package1 package2       # 手动添加依赖
```

从 poetry 迁移 (已有 pyproject.toml)

```bash
cd existing-project
rm poetry.lock                 # 删除 poetry 锁文件
uv lock                        # 生成 uv.lock
uv sync                        # 安装依赖
```

以上
