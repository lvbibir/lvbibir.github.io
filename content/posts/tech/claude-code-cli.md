---
title: "Claude Code CLI 常用功能和操作"
date: 2025-12-17
lastmod: 2025-12-24
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
    image: "https://image.lvbibir.cn/blog/logo-claude.png" 
---

# 0 前言

Claude Code 是 Anthropic 官方推出的 CLI 工具, 可以在终端中与 Claude 进行交互, 完成代码编写、文件操作、问题解答等任务

本文主要介绍在 bash 等终端中直接执行 `claude` 命令后的交互界面功能

# 1 安装和启动

## 1.1 安装

```bash
npm install -g @anthropic-ai/claude-code
```

## 1.2 自定义 baseurl 和 apikey

```bash
export ANTHROPIC_BASE_URL=""
export ANTHROPIC_AUTH_TOKEN=""
```

## 1.3 启动

```bash
# 直接启动交互模式
claude

# 带参数启动
claude --model opus
claude --help
claude --version
```

## 1.4 常用命令行参数

| 参数                | 说明                          |
| ----------------- | --------------------------- |
| `--version`       | 显示版本信息                      |
| `--help`          | 显示帮助信息                      |
| `--model <model>` | 指定使用的模型 (sonnet/opus/haiku) |
| `--verbose`       | 启用详细输出                      |
| `--debug`         | 启用调试模式                      |

# 2 斜杠命令

在交互界面中输入 `/` 开头的命令可以执行特定操作

## 2.1 内置命令

| 命令 | 说明 |
|------|------|
| `/help` | 显示帮助信息和可用命令 |
| `/exit` 或 `/quit` | 退出 Claude Code |
| `/clear` | 清除当前会话历史 |
| `/compact` | 压缩/总结当前会话以节省上下文 |
| `/model` | 查看或切换当前使用的模型 |
| `/settings` | 查看或修改设置 |
| `/feedback` | 提交反馈或功能请求 |
| `/version` | 显示版本信息 |

## 2.2 自定义命令

可以在项目的 `.claude/commands/` 目录下创建自定义斜杠命令

例如创建 `.claude/commands/review.md`:

```markdown
请审查当前分支的代码变更, 重点关注:
1. 代码质量
2. 潜在 bug
3. 安全问题
```

之后在交互界面中输入 `/review` 即可执行该命令

# 3 快捷键

## 3.1 基本操作

| 快捷键 | 说明 |
|--------|------|
| `Ctrl+C` | 中断当前操作 |
| `Ctrl+D` | 退出 Claude Code (在空行时) |
| `↑/↓` | 浏览命令历史 |
| `Tab` | 自动补全命令和路径 |
| `Ctrl+L` | 清屏 |

## 3.2 编辑操作

| 快捷键 | 说明 |
|--------|------|
| `Ctrl+A` | 移动到行首 |
| `Ctrl+E` | 移动到行尾 |
| `Ctrl+K` | 删除从光标到行尾的内容 |
| `Ctrl+U` | 删除从行首到光标的内容 |
| `Ctrl+W` | 删除前一个单词 |

## 3.3 多行输入

| 快捷键 | 说明 |
|--------|------|
| `Shift+Enter` | 换行 (进入多行输入模式) |
| `Ctrl+Enter` | 提交多行输入 |
| `Escape` | 取消多行输入 |

# 4 输入方式

## 4.1 文本输入

直接在提示符后输入文本即可与 Claude 对话

```plaintext
> 帮我写一个 Python 函数计算斐波那契数列
```

## 4.2 多行输入

使用 `Shift+Enter` 可以输入多行内容, 适合粘贴代码块或长文本

## 4.3 文件引用

可以直接引用项目中的文件路径, Claude 会自动读取文件内容

```plaintext
> 请帮我审查 src/main.py 这个文件
```

## 4.4 图片输入

支持拖拽图片文件到终端, 或者直接输入图片路径, Claude 可以分析图片内容

```plaintext
> 请分析这张截图 /path/to/screenshot.png
```

# 5 配置

## 5.1 配置文件位置

- 全局配置: `~/.claude/settings.json`
- 项目配置: `.claude/settings.json`

## 5.2 常用配置项

```json
{
  "model": "opus",
  "temperature": 0.7,
  "max_tokens": 4096
}
```

## 5.3 CLAUDE.md 文件

在项目根目录创建 `CLAUDE.md` 文件, 可以为 Claude 提供项目上下文信息

```markdown
# 项目说明

这是一个 Python Web 项目, 使用 FastAPI 框架

## 代码规范

- 使用 black 格式化代码
- 使用 mypy 进行类型检查
```

# 6 Hooks

Hooks 允许在特定事件发生时执行自定义脚本

## 6.1 配置位置

在 `.claude/settings.json` 中配置:

```json
{
  "hooks": {
    "pre-tool-call": "echo 'Tool call starting'",
    "post-tool-call": "echo 'Tool call completed'"
  }
}
```

## 6.2 可用的 Hook 类型

- `pre-tool-call`: 工具调用前执行
- `post-tool-call`: 工具调用后执行
- `user-prompt-submit`: 用户提交输入时执行

# 7 MCP Servers

MCP (Model Context Protocol) 允许扩展 Claude Code 的能力

## 7.1 配置 MCP Server

在 `.claude/settings.json` 中配置:

```json
{
  "mcpServers": {
    "ide": {
      "command": "node",
      "args": ["/path/to/mcp-server.js"]
    }
  }
}
```

## 7.2 常用 MCP Server

- IDE 集成: 与 VS Code 等编辑器集成
- 数据库: 连接和查询数据库
- API: 调用外部 API

# 8 实用技巧

## 8.1 会话管理

- 使用 `/clear` 清除历史开始新对话
- 使用 `/compact` 压缩长对话以节省上下文

## 8.2 模型切换

根据任务复杂度选择合适的模型:

- `haiku`: 简单快速的任务
- `sonnet`: 日常开发任务 (默认)
- `opus`: 复杂推理和高质量输出

```plaintext
/model opus
```

## 8.3 Git 集成

Claude Code 会自动识别 Git 仓库, 可以:

- 查看 git status 和 diff
- 创建 commit 和 PR
- 审查代码变更

## 8.4 批量操作

可以一次性描述多个任务, Claude 会按顺序执行:

```plaintext
> 1. 修复 src/utils.py 中的类型错误
> 2. 添加单元测试
> 3. 运行测试确保通过
```

以上
