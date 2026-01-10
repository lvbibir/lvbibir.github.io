[根目录](../CLAUDE.md) > **content**

# Content 模块

> 博客内容文件, 使用 Markdown 格式, 按分类组织.

---

## 模块职责

存放所有博客文章和特殊页面的 Markdown 源文件. Hugo 根据此目录结构生成站点.

---

## 目录结构

```
content/
├── posts/
│   ├── _index.md        # 文章列表页配置
│   ├── tech/            # 技术文章 (~100+ 篇)
│   │   └── _index.md    # 分类配置 (weight: 1)
│   ├── blog/            # 建站相关 (7 篇)
│   │   └── _index.md    # 分类配置 (weight: 2)
│   ├── life/            # 生活感悟 (2 篇)
│   │   └── _index.md    # 分类配置 (weight: 3)
│   └── read/            # 读书笔记 (3 篇)
│       └── _index.md    # 分类配置 (weight: 4)
├── about.md             # 关于页面
├── archives.md          # 归档页面
├── search.md            # 搜索页面
├── talk.md              # 说说页面
└── tags/
    └── _index.md        # 标签页配置
```

---

## Frontmatter 规范

### 标准文章

```yaml
---
title: "文章标题"
date: 2024-01-01           # 发布日期
lastmod: 2024-01-10        # 最后修改日期
author: "lvbibir"
tags: ["linux", "docker"]  # 标签列表
description: "文章简述"     # 用于 SEO 和列表摘要
weight: 1                  # 排序权重 (可选, 数字越小越靠前)
cover:
    image: ""              # 封面图片路径
hidemeta: false            # 是否隐藏元信息
---
```

### 分类首页 (_index.md)

```yaml
---
title: "分类名称"
description: "分类描述"
weight: 1                  # 分类排序
---
```

### 特殊页面

```yaml
---
title: "页面标题"
layout: "archives"         # 指定布局: archives, search, about, links
hidemeta: true
---
```

---

## 文章分类说明

| 分类 | 目录 | 权重 | 内容 |
|------|------|------|------|
| 技术 | `posts/tech/` | 1 | Linux, Docker, K8s, Shell, Python 等技术文章 |
| 建站 | `posts/blog/` | 2 | Hugo 博客搭建, 主题配置, 部署相关 |
| 生活 | `posts/life/` | 3 | 生活感悟, 个人随笔 |
| 阅读 | `posts/read/` | 4 | 读书笔记, 书评 |

---

## 命名约定

| 规则 | 示例 |
|------|------|
| 小写字母 | `docker-usage.md` |
| 连字符分隔 | `k8s-pod-lifecycle.md` |
| 描述性名称 | `linux-shell-script-basics.md` |
| 禁止空格和中文 | ~~`docker 使用.md`~~ |

---

## 常用 Shortcodes

### 友链卡片

```markdown
{{</* friend name="站点名称" url="https://example.com" logo="/images/logo.png" word="站点描述" */>}}
```

### 图片

```markdown
![alt text](/images/example.png)
```

图片会自动应用懒加载 (通过 `render-image.html` 模板).

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `../config.yml` | 站点配置, 包含 permalink 规则 |
| `../layouts/_default/single.html` | 文章页模板 |
| `../layouts/_default/list.html` | 列表页模板 |
| `../layouts/shortcodes/` | 自定义 shortcode |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-01-10 | 初始化模块文档 |
