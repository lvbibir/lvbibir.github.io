---
title: "Claude Code 食用指南"
date: 2025-12-17
lastmod: 2025-12-30
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

# 1 mcp 和 skill 安装

```bash
claude
/plugin marketplace add iamzhihuix/happy-claude-skills 
/plugin marketplace add anthropics/skills
/plugin # 安装 context7 frontend-design browser

# 安装 exa 和 augment-context-engine mcp
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

所有 CLAUDE.md 文件是**叠加**的，冲突时后加载的优先。

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

## 2.2 配置示例

````markdown
# CLAUDE.md

## Defaults
- Reply in **Chinese** unless I explicitly ask for English.
- Always use **English punctuation** (e.g., `,` `.` `:` `;` `()` `""`), even when writing Chinese text or generating files with Chinese content.
- No emojis.
- Do not truncate important outputs (logs, diffs, stack traces, commands, or critical reasoning that affects safety/correctness).

## Refactor policy (legacy code)
- When existing code is a "big ball of mud" (hard to maintain, clearly bad design, full of hacks), prefer a **clean, full refactor** over stacking more patches on top of it.
- A refactor may completely replace internal structure (functions, modules, classes, data flow).
- By default, try to preserve externally observable behaviour.
  If you intentionally change behaviour or protocols, you MUST:
  - Call out clearly that this is a **behaviour/protocol change**.
  - Explain why the change is necessary and which code paths/consumers are affected.
  - Update or add tests to cover the new behaviour.

## Before touching code (mandatory)
1) Find reuse opportunities
   - Use semantic code search first via the Augment MCP server `augment-context-engine`, using its `codebase-retrieval` tool for repository/code search.
   - Confirm understanding with LSP: `goToDefinition`, `findReferences`.
   - Use Grep/Glob only for exact matches or filename patterns.

2) Trace impact
   - Use LSP `findReferences` to map the call/dependency chain and impact radius.

3) Run the "three questions" checklist (before implementation)
   - After research and impact analysis, but before changing code, always check:
     - Is this a real issue or just an assumption / over-design?
     - What existing code can be reused?
     - What might break, and who depends on this?
   - How much of this you surface in the reply depends on task size (see **Task sizing**).

## Red lines
- No copy-paste duplication.
- Do not break existing externally observable behaviour **unless**:
  - It is part of a deliberate refactor as described in the refactor policy, and
  - You clearly document the behavioural change and its impact.
- Do not proceed with a known-wrong approach.
- Critical paths must have explicit error handling.
- Never implement "blindly": always confirm understanding via code reading + references.

## Web research (no guessing)
If something is unfamiliar or likely version-sensitive, you MUST search the web instead of guessing:
- Use Exa: `mcp__exa__web_search_exa`.

Source priority:
1) Official docs / API reference.
2) Official changelog / release notes.
3) Upstream GitHub repository docs (README, `/docs`).
4) Community posts only if necessary to fill gaps.

Version rule:
- When behaviour may differ across versions, first identify the project's version (lockfile/config),
  then search docs specifically for that version.

## Task sizing
- **Simple**
  - Criteria — single file, clear requirement, < 20 lines changed, clearly local impact.
  - Handling — after doing the "Before touching code" steps (research + impact analysis + internal three-question checklist), you may execute directly with minimal explanation.
    A very short context line is enough; a full breakdown of the checklist is not required.

- **Medium**
  - Criteria — 2–5 files, or requires some research, or impact is not obviously local.
  - Handling — write a short plan (bullet points) → then implement.
  - Briefly surface the three-question checklist result in the reply (1–3 short lines describing real issue vs assumption, key reuse, and main impact).

- **Complex**
  - Criteria — architecture changes, multiple modules, high uncertainty or risk.
  - Handling — follow this workflow:
    1) **RESEARCH**: inspect code and facts only (no proposals yet).
    2) **PLAN**: present options + tradeoffs + recommendation; wait for my confirmation.
    3) **EXECUTE**: implement exactly the approved plan.
    4) **REVIEW**: self-check (tests, edge cases, cleanup).
  - The three-question checklist should be reflected in the RESEARCH/PLAN sections (problem reality, reuse opportunities, and impact analysis).

## Tool selection
- Semantic code search & understanding: MCP server `augment-context-engine`, tool `codebase-retrieval`.
- Definitions/references/impact: LSP (`goToDefinition`, `findReferences`).
- Exact string/regex search: Grep.
- Filename patterns: Glob.
- Docs & open-source lookup: `mcp__exa__web_search_exa`.

## Git
- Do not commit unless I explicitly ask.
- Do not push unless I explicitly ask.
- Before writing a commit message, glance at a few recent commits and match the repo's style:
  - `git log -n 5 --oneline`
- If there is no obvious existing style, use this default format:
  - `<type>(<scope>): <description>`
- Before any commit: run `git diff` and confirm the exact scope of changes.
- Never force-push to `main` / `master`.
- Do not add attribution lines in commit messages.

## Security
- Never hardcode secrets (keys/passwords/tokens).
- Never commit `.env` files or any credentials.
- Validate user input at trust boundaries (APIs, CLIs, external data sources).

## Quality & cleanup
- Prefer clarity and simplicity first (KISS); apply DRY to remove obvious copy-paste duplication when it does not hurt readability.
- If you change a function signature, update **all** call sites.
- After changes:
  - Remove temporary files.
  - Remove dead/commented-out code.
  - Remove unused imports.
  - Remove debug logging that is no longer needed.
- Run the smallest meaningful verification (lint/test/build) for the parts you touched.

## Python environment
Always use **uv** for Python environment and package management. Never use raw `pip`, `python -m venv`, or `virtualenv`.

Virtual environment priority (highest to lowest):
1) **Project-level**: If inside a project directory, use `uv init` to create `.venv` in project root. All dependencies install here.
2) **User-level**: If outside any project but need persistent Python, use `~/.venv`:
   ```bash
   uv venv ~/.venv
   source ~/.venv/bin/activate
   ```
3) **Temporary**: If a throwaway environment is acceptable, create in `/tmp`:
   ```bash
   uv venv /tmp/.venv-$(date +%s)
   ```

Common commands:
- Create project: `uv init`
- Add dependency: `uv add <package>`
- Run script: `uv run python script.py`
- Sync deps: `uv sync`

## Node.js environment
Always use **pnpm** for package management. Avoid npm/yarn unless explicitly required by the project.

Environment priority (highest to lowest):
1) **Project-level**: If inside a project with `package.json`, install locally:
   ```bash
   pnpm install
   ```
2) **User-level global**: For CLI tools needed across projects:
   ```bash
   pnpm add -g <package>
   ```
3) **Temporary execution**: For one-off scripts without polluting global:
   ```bash
   pnpm dlx <package>   # like npx but uses pnpm cache
   ```

Version management:
- Use **nvm** for Node.js version switching.
- Respect `.nvmrc` or `.node-version` if present in project.

## Shell / Platform
Auto-detect the runtime environment and adapt accordingly:

**Detection order:**
1) Check if running inside WSL: `grep -qi microsoft /proc/version`
2) Check if native Linux: `uname -s` returns `Linux` without WSL markers
3) Check if macOS: `uname -s` returns `Darwin`
4) Check if Windows (PowerShell/cmd): `$env:OS` or `%OS%` equals `Windows_NT`

**Default assumption:** If detection is unclear or fails, assume **WSL2 on Windows**.

**Platform-specific rules:**

| Platform | Shell syntax | Command chaining | Path format |
|----------|--------------|------------------|-------------|
| WSL2 / Linux / macOS | Bash/Zsh | `&&` or `;` | `/path/to/file` |
| Windows PowerShell | PowerShell | `;` (no `&&`) | `C:\path\to\file` |
| Windows cmd | cmd | `&&` or `&` | `C:\path\to\file` |

**Cross-platform notes:**
- In WSL2, access Windows paths via `/mnt/c/...`
- Quote paths containing spaces or non-ASCII characters on all platforms.
- When calling Windows executables from WSL2, use full path: `/mnt/c/Windows/System32/...`

````

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
