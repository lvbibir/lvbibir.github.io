# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hugo 静态博客, 基于 PaperMod 主题 (源自 sulv 修改版). 内容使用中文, 通过 Obsidian 编写后同步至 Hugo.

- 站点地址: https://www.lvbibir.cn
- 主题仓库: https://github.com/adityatelange/hugo-PaperMod
- 模板仓库: https://github.com/xyming108/sulv-hugo-papermod

## Commands

### 开发

```bash
# 从 Obsidian 同步内容并启动开发服务器 (包含草稿)
./update-file.sh

# 仅启动开发服务器
hugo server -D
```

### 构建与部署

```bash
# 构建并部署到远程服务器
./upload-file.sh

# 仅构建静态文件
hugo -F --cleanDestinationDir
```

## Content Workflow

内容源自 Windows OneDrive 中的 Obsidian vault:
- 文章: `/mnt/c/Users/lvbibir/OneDrive/1-lvbibir/obsidian/lvbibir/blog/` -> `content/posts/`
- 图片: `/mnt/c/Users/lvbibir/OneDrive/1-lvbibir/obsidian/lvbibir/images/` -> `static/images/`

文章分类目录:
- `content/posts/tech/` - 技术文章
- `content/posts/blog/` - 建站相关
- `content/posts/read/` - 读书笔记
- `content/posts/life/` - 生活记录

## Architecture

### 自定义布局 (覆盖 PaperMod 主题)

| 文件 | 用途 |
|------|------|
| `layouts/partials/toc.html` | 自定义目录 (支持宽屏侧边栏 + 移动端弹出) |
| `layouts/partials/comments.html` | Twikoo 评论系统集成 |
| `layouts/partials/extend_head.html` | 自定义字体 + 图片懒加载脚本 |
| `layouts/shortcodes/friend.html` | 友链卡片 shortcode |
| `layouts/_default/_markup/render-image.html` | 图片懒加载渲染 |

### 第三方集成

| 功能 | 实现 |
|------|------|
| 评论系统 | Twikoo (self-hosted, `static/js/twikoo/`) |
| 说说页面 | Artitalk (LeanCloud 后端, `static/js/artitalk/`) |
| 字体 | JetBrains Mono + LXGW 混合字体 (`static/fonts/`) |

### 配置要点 (config.yml)

- `hasCJKLanguage: true` - 中文字数统计
- `markup.goldmark.renderer.unsafe: true` - 允许 Markdown 中嵌入 HTML
- `permalinks.post: "/:title/"` - 文章 URL 格式
- `params.ShowToc: true` + `TocOpen: true` - 默认展开目录

## Front Matter

文章常用 front matter:

```yaml
---
title: "文章标题"
date: 2024-01-01
lastmod: 2024-01-02  # 可选, 显示更新时间
tags: [tag1, tag2]
description: "文章摘要"
cover:
    image: "/images/xxx.png"  # 可选, 封面图
draft: false
---
```

## Shortcodes

友链使用:
```
{{< friend name="名称" url="https://..." logo="/images/xxx.png" word="描述" >}}
```
