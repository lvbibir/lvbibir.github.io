---
title: "Claude Code 食用指南"
date: 2025-12-17
lastmod: 2025-12-31
tags:
  - AI
  - 工具
keywords:
  - claude code
  - cli
  - anthropic
  - ai assistant
description: "介绍 Claude Code CLI 交互界面的常用功能和操作, 包含斜杠命令、快捷键、命令行参数、多行输入等实用技巧"
cover:
    image: "images/logo-claude.png" 
---

# 0 前言

Claude Code 是 Anthropic 官方推出的 CLI 工具, 可以在终端中与 Claude 进行交互, 完成代码编写、文件操作、问题解答等任务

# 1 mcp 和 skill 安装

## 1.1 plugin

```bash
claude
/plugin marketplace add iamzhihuix/happy-claude-skills 
/plugin marketplace add anthropics/skills
/plugin # 直接搜索安装 context7 frontend-design browser
```

## 1.2 mcp

访问 [Exa Dashboard](https://dashboard.exa.ai/), 创建一个 API key

```bash
# 将 YOUR_EXA_API_KEY 替换为你实际获取的 Key
claude mcp add-json --scope user exa \
'{"command":"npx","args":["-y","exa-mcp-server"],"env":{"EXA_API_KEY":"YOUR_EXA_API_KEY"}}'
```

[参考文档](https://linux.do/t/topic/1360514) [ACE 中转站](https://acemcp.heroman.wtf/)

```bash
npm install -g ace-tool

claude mcp add-json --scope user augment-context-engine \
'{"command":"ace-tool","args":["--base-url","https://acemcp.heroman.wtf/relay/","--token","YOU_API_KEY"]}'

# 替代方案, ripgrep+code-index
claude mcp add-json --scope user ripgrep \
'{"command":"npx","args":["-y","mcp-ripgrep@latest"]}'
claude mcp add-json --scope user code-index \
'{"command":"uvx","args":["code-index-mcp"]}'
```

# 2 CLAUDE.md

## 2.1 加载顺序

### 2.1.1 文件位置

| 级别    | 路径                                    | 用途                      |
| ----- | ------------------------------------- | ----------------------- |
| 全局用户级 | `~/.claude/CLAUDE.md`                 | 适用于所有项目的个人偏好            |
| 项目级   | `./CLAUDE.md` 或 `./.claude/CLAUDE.md` | 团队共享的项目指令               |
| 项目本地级 | `./CLAUDE.local.md`                   | 个人的项目偏好（应加入 .gitignore） |

### 2.1.2 加载优先级

优先级从低到高（后加载的会覆盖或补充先加载的）：

```plaintext
全局用户级 → 项目级 → 项目本地级
```

所有 CLAUDE.md 文件是叠加的，冲突时后加载的优先。

### 2.1.3 目录层级支持

*向上递归查找*

从当前工作目录开始递归向上查找，读取沿途发现的所有 `CLAUDE.md` 或 `CLAUDE.local.md`。

示例：在 `foo/bar/` 下运行时，会同时加载：

- `foo/CLAUDE.md`
- `foo/bar/CLAUDE.md`

*子目录按需加载*

子目录中的 `CLAUDE.md` 不会在启动时立即加载，而是在读取或操作该子目录下的文件时才纳入上下文。

### 2.1.4 常用操作

| 操作        | 说明                |     |
| --------- | ----------------- | --- |
| `/init`   | 自动生成 CLAUDE.md 文件 |     |
| `/memory` | 查看当前加载的内存文件       |     |

### 2.1.5 使用建议

| 场景              | 建议存放位置                              |
| --------------- | ----------------------------------- |
| 个人代码风格偏好        | `~/.claude/CLAUDE.md`               |
| 项目架构说明、编码标准     | `./CLAUDE.md` (提交到 git)             |
| 个人私有配置（如测试 URL） | `./CLAUDE.local.md` (加入 .gitignore) |

# 3 修复 wsl2 运行卡顿的问题

[参考原文链接](https://linux.do/t/topic/956128)

原因是因为 WSL2 会将 Windows 的 Path 追加到 Linux 的 $PATH，使 Linux 终端可直接运行 powershell.exe 等 Windows 程序。而 Claude Code 会检测 $PATH，发现 powershell.exe 后，会反复调用它获取 Windows 用户目录。但 WSL2 中从 Linux 启动 Windows 程序延迟高，导致每次按键都需等待该调用，引发周期性卡顿。

解决办法, 直接复制下面的代码块到 wsl2 中执行即可

```bash
# 设置工作目录（可选，默认 ~/bin）
# export CLAUDE_FIX_DIR=~/bin

(
TOOL_DIR="${CLAUDE_FIX_DIR:-$HOME/bin}"
TOOL_PATH="$TOOL_DIR/powershell.exe"

# 创建目录
mkdir -p "$TOOL_DIR"

# 创建包装脚本
cat << 'EOF' > "$TOOL_PATH"
#!/bin/bash
if [[ "$1" == "-Command" && "$2" == "\$env:USERPROFILE" ]]; then
  echo "C:\\Users\\Administrator"
else
  /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe "$@"
fi
EOF

chmod +x "$TOOL_PATH"

# 确定 shell 配置文件
if [[ "$SHELL" == */zsh ]]; then
  CONFIG_FILE="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
  CONFIG_FILE="$HOME/.bashrc"
else
  echo "未知的 shell: $SHELL，请手动添加 PATH"
  exit 1
fi

# 幂等性检查：仅在未添加时插入
EXPORT_LINE="export PATH=\"$TOOL_DIR:\$PATH\""
if ! grep -qF "$TOOL_DIR" "$CONFIG_FILE" 2>/dev/null; then
  echo "" >> "$CONFIG_FILE"
  echo "# Claude Code WSL2 fix" >> "$CONFIG_FILE"
  echo "$EXPORT_LINE" >> "$CONFIG_FILE"
  echo "已添加 PATH 到 $CONFIG_FILE"
else
  echo "PATH 已存在于 $CONFIG_FILE，跳过"
fi

echo ""
echo "修复完成！请执行以下命令使配置生效："
echo "  source $CONFIG_FILE"
)
```

# 4 状态栏美化

[项目文档](https://github.com/Haleclipse/CCometixLine/blob/master/README.zh.md)

```bash
npm install -g @cometix/ccline
ccline --patch ~/.nvm/versions/node/v24.12.0/lib/node_modules/@anthropic-ai/claude-code/cli.js
```

cc-switch 写入通用配置文件

```yaml
{
  "includeCoAuthoredBy": false,
  "statusLine": {
    "type": "command", 
    "command": "~/.claude/ccline/ccline",
    "padding": 0
  }
}
```
