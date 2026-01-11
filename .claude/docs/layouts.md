[根目录](../CLAUDE.md) > **layouts**

# Layouts 模块

> Hugo 模板覆盖和自定义组件, 扩展 PaperMod 主题功能.

---

## 模块职责

通过 Hugo 的模板覆盖机制, 在不修改主题源码的情况下自定义布局和功能. 此目录下的文件会覆盖 `themes/PaperMod/layouts/` 中的同名文件.

---

## 目录结构

```
layouts/
├── _default/
│   ├── baseof.html       # 基础 HTML 结构
│   ├── single.html       # 文章页模板
│   ├── list.html         # 列表页模板
│   ├── archives.html     # 归档页模板
│   ├── search.html       # 搜索页模板
│   └── _markup/
│       └── render-image.html  # 图片渲染 (懒加载)
├── partials/
│   ├── header.html       # 页头
│   ├── footer.html       # 页脚 (统计, 运行时间, 代码复制)
│   ├── toc.html          # 目录组件 (~300 行)
│   ├── comments.html     # Twikoo 评论
│   ├── reward.html       # 打赏按钮
│   ├── extend_head.html  # 自定义 head (字体, 懒加载 JS)
│   └── extend_footer.html
└── shortcodes/
    └── friend.html       # 友链卡片 shortcode
```

---

## 核心模板

### baseof.html

基础 HTML 骨架, 定义页面结构:

```html
<!DOCTYPE html>
<html lang="{{ .Site.Language }}">
<head>{{- partial "head.html" . }}</head>
<body class="...">
  {{- partialCached "header.html" . .Page -}}
  <main class="main">{{- block "main" . }}{{ end }}</main>
  {{ partialCached "footer.html" . ... -}}
</body>
</html>
```

### single.html

文章页模板, 包含:
- 文章元信息 (日期, 字数, 阅读时间)
- 目录 (TOC)
- 文章内容
- 打赏按钮
- 评论区
- 上下篇导航

### toc.html

响应式目录组件, 特性:
- 桌面端: 左侧固定悬浮
- 移动端: 右下角按钮触发弹出
- 滚动时高亮当前章节
- ESC 键关闭, 点击遮罩关闭

---

## 关键 Partials

| 文件 | 功能 |
|------|------|
| `extend_head.html` | 加载自定义字体 (JetBrainsLxgwNerdMono), 图片懒加载 JS |
| `footer.html` | 网站运行时间, 不蒜子统计, 阅读进度, 代码复制按钮 |
| `comments.html` | Twikoo 评论系统初始化 |
| `reward.html` | 微信/支付宝打赏二维码 |
| `toc.html` | 目录生成和交互逻辑 |

---

## 图片懒加载

`_markup/render-image.html` 覆盖默认图片渲染:

```html
<img class="lazyload"
     src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
     data-src="{{ .Destination | safeURL }}"
     alt="{{ .Text }}" />
<noscript>
  <img src="{{ .Destination | safeURL }}" alt="{{ .Text }}" />
</noscript>
```

懒加载 JS (在 `extend_head.html` 中):
- 使用 IntersectionObserver API
- 图片进入视口时替换 `src` 为 `data-src`

---

## Shortcodes

### friend.html (友链卡片)

用法:
```markdown
{{</* friend name="站点名" url="https://..." logo="/images/..." word="描述" */>}}
```

生成带头像, 名称, 描述的卡片链接.

---

## 模板变量

常用 Hugo 变量:

| 变量 | 说明 |
|------|------|
| `.Site.Params.xxx` | config.yml 中的 params |
| `.Title` | 页面标题 |
| `.Content` | 渲染后的内容 |
| `.TableOfContents` | 自动生成的目录 HTML |
| `.Param "ShowToc"` | 获取参数 (支持 frontmatter 覆盖) |

---

## 修改指南

1. **覆盖主题模板**: 复制 `themes/PaperMod/layouts/` 中的文件到此目录同路径
2. **添加 partial**: 在 `partials/` 下创建, 用 `{{ partial "name.html" . }}` 引用
3. **添加 shortcode**: 在 `shortcodes/` 下创建, 用 `{{</* name */>}}` 调用
4. **修改图片渲染**: 编辑 `_default/_markup/render-image.html`

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `../config.yml` | 模板参数配置 |
| `../assets/css/extended/` | 配套 CSS 样式 |
| `../themes/PaperMod/layouts/` | 原始主题模板 (参考) |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-01-10 | 初始化模块文档 |
