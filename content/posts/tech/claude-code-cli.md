---
title: "Claude Code 完整配置指南"
date: 2025-12-17
lastmod: 2026-02-02
tags:
  - AI
  - Claude
keywords:
  - claude code
  - anthropic
description: "Claude Code CLI 完整配置指南，包含快速配置流程、核心工具详解、扩展生态系统和实用技巧，助你打造高效的 AI 编程环境"
cover:
    image: "images/cover-claude.png"
---

# 0 前言

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) 是 Anthropic 官方推出的 CLI 工具，可以在终端中与 Claude 进行交互，完成代码编写、文件操作、问题解答等任务。

我的工具流:

| 类别        | 工具                                                          | 用途            |
| --------- | ----------------------------------------------------------- | ------------- |
| **系统环境**  | Windows + WSL2 + Ubuntu 20.04                               | 基础运行环境        |
| **运行环境**  | VSCode + Claude Code CLI                                    | 主要开发界面        |
| **反重力逆向** | [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) | API 代理服务      |
| **配置管理**  | [cc-switch](https://github.com/farion1231/cc-switch)        | 快速切换供应商及提示词管理 |
| **工作流优化** | [ZCF](https://github.com/UfoMiao/zcf)                       | 专业工作流和技能包管理   |
| **界面美化**  | [CCometixLine](https://github.com/Haleclipse/CCometixLine)  | 状态栏主题美化       |

# 1 快速开始

**配置流程**:

1. 清理旧版本重新安装 (按需执行)

    ```bash
    pnpm add -g @anthropic-ai/claude-code
    rm -rf ~/.claude*
    pnpm remove -g @anthropic-ai/claude-code
    ```

2. zcf 工作流 (⚠️ 会覆盖全局 CLAUDE.md, 注意备份)

    ```bash
    npx -y zcf
    # 选择 2 导入工作流
    ```

3. ccline 状态栏美化

    ```bash
    pnpm add -g @cometix/ccline
    ccline
    ```

4. ccswitch
    - api 供应商
    - 通用配置 [配置示例](https://gist.github.com/lvbibir/cc11892a004772b55526aa4b3602876f#file-claude-settings-json)
    - mcp, 见下文 4.3
    - 提示词 [配置示例](https://gist.github.com/lvbibir/cc11892a004772b55526aa4b3602876f#file-claude-md)
    - 跳过初次安装确认
    - 应用到 VSCode 插件

5. skills 安装
    - 执行 `claude` , `/plugin`
    - 在 Marketplace 中添加 anthropics/skills
    - 在 Discover 中搜索并安装:
        - document-skills: 文档处理技能包
        - frontend-design: 前端设计工具

# 2 核心工具详解

## 2.1 ZCF 工作流

[项目地址](https://github.com/UfoMiao/zcf)

**功能概述:**
ZCF 是 Claude Code 的强大工作流管理工具，提供完整的开发工作流解决方案。

**核心特性:**
- **六阶段开发流程**: 研究 → 构思 → 计划 → 执行 → 优化 → 评审
- **智能技能包**: 预定义的开发模板和最佳实践
- **个性化输出**: 多种 AI 输出风格（如猫娘工程师风格）
- **Git 集成**: 智能提交信息生成和版本管理
- **项目初始化**: 自动生成 AI 上下文和索引

**安装与配置:**

```bash
# 启动配置向导
npx -y zcf 
# 选择选项:
# 1. 创建新配置
# 2. 导入预设工作流 (推荐)
# 3. 更新现有配置
```

**主要工作流命令:**

| 命令 | 功能 | 适用场景 |
|------|------|----------|
| `/zcf:workflow` | 六阶段结构化开发 | 复杂功能开发、架构设计 |
| `/zcf:feat` | 新功能开发流程 | 快速功能迭代 |
| `/git-commit` | 智能 Git 提交 | 自动生成规范的提交信息 |
| `/git-rollback` | 交互式版本回滚 | 安全的版本管理 |
| `/init-project` | 项目 AI 上下文初始化 | 新项目或现有项目优化 |

**使用示例:**

```bash
# 启动专业开发工作流
/zcf:workflow 实现用户认证系统

# 快速功能开发
/zcf:feat 添加用户头像上传功能

# 智能 Git 提交 (分析改动并生成 conventional commit)
/git-commit

# 项目初始化 (生成 CLAUDE.md 和项目索引)
/init-project
```

## 2.2 CCLine 状态栏

**功能特点:**
- 多种精美主题可选
- 自定义颜色和样式配置
- 实时显示当前状态和配置信息

**安装配置:**

```bash
# 安装 CCometixLine
pnpm add -g @cometix/ccline

# patch
claude doctor # 查看 Invoked 路径的地址
ccline --patch /home/lvbibir/.local/share/pnpm/global/5/.pnpm/@anthropic-ai+claude-code@2.1.14/node_modules/@anthropic-ai/claude-code/cli.js
```

Claude code 集成, 选择一种方式配置:

1. 直接在 `~/.claude/setting.json` 中编辑
2. 在 cc-switch 配置文件的通用配置中添加设置:

```json
{
  "statusLine": {
    "type": "command",
    "command": "ccline",
    "padding": 0
  }
}
```

# 3 CLAUDE.md 配置

CLAUDE.md 是 Claude Code 的核心配置文件，采用层级加载机制。

**文件层级与优先级:**

| 级别 | 路径 | 用途 | 优先级 |
|------|------|------|--------|
| **企业策略** | Enterprise policy | 企业级规则 | 最高 |
| **项目规则** | `.claude/rules/*.md` | 团队共享规则 | 高 |
| **项目配置** | `./CLAUDE.md` 或 `./.claude/CLAUDE.md` | 项目特定配置 | 中 |
| **用户配置** | `~/.claude/CLAUDE.md` | 个人全局偏好 | 低 |
| **项目本地** | `./CLAUDE.local.md` | 个人项目偏好 | 最低 |

**配置加载机制:**
- 所有 CLAUDE.md 文件是**叠加的**，冲突时后加载的优先
- 从当前工作目录开始递归向上查找
- 子目录中的配置在操作该目录文件时才纳入上下文

**全局配置示例:**

我的全局 CLAUDE.md [配置示例](https://gist.github.com/lvbibir/cc11892a004772b55526aa4b3602876f#file-claude-md)，直接写入 `~/.claude/CLAUDE.md` 文件即可。

**高级功能:**

**1. 文件导入**

```plaintext
# 导入项目概览和可用命令
See @README for project overview and @package.json for available npm commands.

# 导入个人偏好设置
@~/.claude/my-project-instructions.md
```

**2. 模块化规则**

```plaintext
project-root/
└── .claude/
    └── rules/
        ├── coding-standards.md
        ├── testing-guidelines.md
        └── deployment-rules.md
```

**配置建议:**

| 场景 | 建议存放位置 | 说明 |
|------|-------------|------|
| 个人代码风格偏好 | `~/.claude/CLAUDE.md` | 全局生效 |
| 项目架构说明、编码标准 | `./CLAUDE.md` | 提交到 git，团队共享 |
| 个人私有配置 | `./CLAUDE.local.md` | 加入 .gitignore |

**常用管理命令:**

| 命令 | 功能 |
|------|------|
| `/init` | 自动生成 CLAUDE.md 文件 |
| `/memory` | 查看当前加载的内存文件 |

# 4 MCP 服务器配置

## 4.1 Exa 网络搜索

**功能特点:**
- 比内置 websearch 更精准的搜索结果
- 支持代码搜索和技术文档检索
- 新用户免费 $10 额度

**安装配置:**

访问 <https://dashboard.exa.ai/> 获取 API Key

```bash
claude mcp add-json --scope user exa '{
  "args": [
    "-y",
    "exa-mcp-server"
  ],
  "command": "npx",
  "env": {
    "EXA_API_KEY": "-------"
  }
}'
```

**使用示例:**

```bash
# 搜索最新的 React 18 文档
搜索 React 18 新特性和最佳实践

# 查找特定库的使用示例
帮我搜索 Next.js 14 App Router 的实际项目案例

# 技术问题解决
搜索 TypeScript 泛型约束的高级用法
```

## 4.2 ACE 代码理解

**功能特点:**
- 最强的代码语义搜索和理解
- 支持跨文件的代码关系分析
- 智能代码补全和重构建议

**方案一: LinuxDo 中转站** ([参考文档](https://linux.do/t/topic/1360514))

```bash
claude mcp add-json --scope user augment-context-engine '{
  "args": [
    "-y",
    "ace-tool",
    "--base-url",
    "https://acemcp.heroman.wtf/relay/",
    "--token",
    "ace_d84f6fbbec634e841a579599f563da744f2abc42"
  ],
  "command": "npx"
}'
```

**方案二: 开源平替方案**

```bash
claude mcp add-json --scope user ripgrep '{
  "args": [
    "-y",
    "mcp-ripgrep"
  ],
  "command": "npx"
}'

# Code Index - 代码索引和分析
claude mcp add-json --scope user code-index '{
  "args": [
    "code-index-mcp"
  ],
  "command": "uvx"
}'
```

**使用示例:**

```bash
# 代码理解
分析这个项目的认证流程是如何实现的

# 函数查找
找到所有处理用户登录的相关函数

# 依赖分析
这个组件被哪些地方引用了?

# 重构建议
帮我重构这个函数，提高可读性和性能
```

## 4.3 Context7 文档查询

**功能特点:**
- 实时获取最新的库文档和 API 参考
- 支持多种编程语言和框架
- 提供代码示例和最佳实践

**安装配置**:

```bash
npm install -g @upstash/context7-mcp
# 或使用 npx (无需全局安装)
npx @upstash/context7-mcp

claude mcp add-json --scope user context7 '{
  "args": [
    "-y",
    "@upstash/context7-mcp"
  ],
  "command": "npx"
}'
```

**使用示例:**

```bash
# 查询特定库的文档
/context7 查询 React useEffect 的最新用法

# API 参考查询
帮我查询 Express.js 中间件的完整 API 文档

# 版本特定查询
查询 Next.js 14 中 App Router 的路由配置方法
```

# 5 Skills

## 5.1 plugin 方式

```bash
/plugin
# 在 Marketplace 中添加 anthropics/skills
# 在 Discover 中搜索并安装:
# - document-skills: 文档处理 skill
# - frontend-design: 前端设计工具 skill
```

**Plugin 特点:**
- **自动发现**: Claude 会根据任务需求自动选择合适的 Skills
- **模块化**: 每个 Plugin 可包含多种组件 (Commands、Agents、Skills、Hooks)
- **可扩展**: 支持自定义开发和第三方 Plugin

## 5.2 npx skills 方式

[skill.sh 官网](https://skills.sh/)

这种方式安装 skills 很方便

```bash
npx -y skills add https://github.com/anthropics/skills --skill frontend-design
npx -y skills add https://github.com/anthropics/skills --skill pptx docx xlsx pdf
```

# 6 WSL2 性能优化

**问题症状:**
- Claude Code 在 WSL2 中响应缓慢
- 每次按键都有明显延迟
- 周期性卡顿现象

**根本原因:** ([参考原文](https://linux.do/t/topic/956128))

WSL2 会将 Windows 的 PATH 追加到 Linux 的 `$PATH` 中，使 Linux 终端可以直接运行 `powershell.exe` 等 Windows 程序。Claude Code 检测到 `$PATH` 中的 `powershell.exe` 后，会反复调用它来获取 Windows 用户目录。由于 WSL2 中从 Linux 启动 Windows 程序的延迟较高，导致每次按键都需要等待该调用完成，从而引发周期性卡顿。

**解决方案:**

创建一个 `powershell.exe` 的包装脚本，对于 Claude Code 的特定查询直接返回缓存结果，避免实际调用 Windows PowerShell。

**一键修复脚本:**

```bash
TOOL_DIR="$HOME/tools"
mkdir -p "$TOOL_DIR"

cat << 'EOF' > "$TOOL_DIR/powershell.exe"
#!/bin/bash
if [[ "$1" == "-Command" && "$2" == "\$env:USERPROFILE" ]]; then 
    echo "C:\\Users\\Administrator" 
else
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe "$@"
fi
EOF

chmod +x "$TOOL_DIR/powershell.exe"

echo '# Claude Code WSL2 fix' >> ~/.bashrc
echo 'export PATH=$HOME/tools:$PATH' >> ~/.bashrc

source ~/.bashrc
```

**验证修复效果:**

```bash
# 重启终端后检查包装脚本是否生效
which powershell.exe
# 应该显示: /home/username/tools/powershell.exe

# 测试 Claude Code 响应速度
claude
# 应该明显感觉到响应速度提升
```

以上.
