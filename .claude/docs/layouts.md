[根目录](../../../CLAUDE.md) > **layouts**

# Layouts 模块

> Hugo 模板覆盖和自定义组件, 扩展 PaperMod 主题功能.

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-02-02 | 完整扫描更新: 新增 Series 侧边栏, 响应式布局系统详解 |
| 2026-01-10 | 初始化模块文档 |

---

## 模块职责

通过 Hugo 的模板覆盖机制, 在不修改主题源码的情况下自定义布局和功能. 此目录下的文件会覆盖 `themes/PaperMod/layouts/` 中的同名文件.

---

## 目录结构

```
layouts/
├── _default/
│   ├── baseof.html           # 基础 HTML 结构 (27 行)
│   ├── single.html           # 文章页模板 (218 行, 核心布局)
│   ├── list.html             # 列表页模板 (126 行)
│   ├── archives.html         # 归档页模板
│   ├── search.html           # 搜索页模板
│   └── _markup/
│       ├── render-image.html # 图片渲染 (懒加载, 11 行)
│       └── render-link.html  # 链接渲染
├── partials/
│   ├── header.html           # 页头
│   ├── footer.html           # 页脚 (217 行, 统计/运行时间/代码复制)
│   ├── toc.html              # 目录组件 (100 行)
│   ├── toc_body.html         # 目录内容生成
│   ├── toc_inline.html       # 内嵌式目录
│   ├── series.html           # Series 侧边栏 (133 行, 核心特性)
│   ├── comments.html         # Twikoo 评论 (39 行)
│   ├── extend_head.html      # 自定义 head (39 行, 字体/懒加载)
│   ├── author.html           # 作者信息
│   ├── post_meta.html        # 文章元信息
│   ├── cover1.html           # 封面图
│   └── svg.html              # SVG 图标
└── shortcodes/
    └── friend.html           # 友链卡片 (14 行)
```

---

## 核心模板详解

### baseof.html (基础骨架)

**职责**: 定义页面 HTML 结构, 所有页面的基础模板.

**结构**:
```html
<!DOCTYPE html>
<html lang="{{ .Site.Language }}">
<head>
  {{- partial "head.html" . }}
</head>
<body class="...">
  {{- partialCached "header.html" . .Page -}}
  <main class="main">
    {{- block "main" . }}{{ end }}
  </main>
  {{ partialCached "footer.html" . ... -}}
</body>
</html>
```

**关键点**:
- `partialCached` 用于缓存 header/footer, 提升性能
- `body` class 根据页面类型动态添加 (list/post/dark)
- `block "main"` 由子模板 (single.html/list.html) 填充

---

### single.html (文章页核心)

**职责**: 文章详情页布局, 支持 Series/TOC 响应式布局.

**关键特性**:
1. **响应式网格系统** (`.post-grid`)
2. **Series 侧边栏** (左侧, 可选)
3. **文章内容** (中间)
4. **TOC 目录** (右侧, 可选)

**布局模式** (由 JS 动态切换):
```html
<div class="post-grid has-series has-toc">
  <!-- 模式由 CSS class 控制:
       pg--series-popup: 1 列 (Series 弹出)
       pg--series-two: 2 列 (Series + Content)
       pg--series-three: 3 列 (Series + Content + TOC)
       pg--toc-one: 1 列 (无 Series, TOC 内嵌)
       pg--toc-two: 2 列 (无 Series, Content + TOC)
  -->

  <aside class="post-grid__series">
    {{ partial "series.html" . }}
  </aside>

  <article class="post-single post-grid__content">
    <!-- 文章头部 -->
    <header class="post-header">
      {{ partial "breadcrumbs.html" . }}
      <h1>{{ .Title }}</h1>
      <div class="post-meta">...</div>
    </header>

    <!-- 文章内容 -->
    <div class="post-content">
      {{ .Content }}
    </div>

    <!-- 打赏按钮 -->
    {{ if .Param "reward" }}
      <div class="post-reward">...</div>
    {{ end }}

    <!-- 评论区 -->
    {{ if .Param "comments" }}
      {{ partial "comments.html" . }}
    {{ end }}
  </article>

  <aside class="post-grid__toc">
    {{ partial "toc.html" . }}
  </aside>
</div>

<script>
  // 响应式布局切换逻辑 (根据视口宽度和 CSS 变量)
  function applyLayout() {
    const w = grid.clientWidth;
    const seriesWidth = readVarPx(style, '--series-width', 350);
    const articleWidth = readVarPx(style, '--article-width', 800);
    const tocWidth = readVarPx(style, '--toc-width', 250);
    const contentGap = readVarPx(style, '--content-gap', 20);

    // 计算断点并切换模式
    if (hasSeries) {
      const bp2 = seriesWidth + contentGap + articleWidth;
      const bp3 = seriesWidth + contentGap + articleWidth + contentGap + tocWidth;
      if (hasToc && w >= bp3) mode = "pg--series-three";
      else if (w >= bp2) mode = "pg--series-two";
      else mode = "pg--series-popup";
    }
    // ...
  }
</script>
```

**断点计算**:
- **2 列**: `seriesWidth + gap + articleWidth` (默认: 350 + 20 + 800 = 1170px)
- **3 列**: `seriesWidth + gap + articleWidth + gap + tocWidth` (默认: 1420px)

---

### list.html (列表页)

**职责**: 首页/分类页/标签页文章列表.

**特性**:
- 按 `weight` (降序) + `lastmod` (降序) 排序
- 支持分页 (每页 15 篇, 配置在 `config.yml`)
- 自定义分页样式 (显示首页/上一页/当前页/下一页/末页)

**排序逻辑**:
```go
{{- $pages = $pages.ByLastmod.Reverse }}  // 先按更新时间倒序
{{- $pages = sort $pages "Weight" "desc" }}  // 再按权重倒序
```

---

### series.html (Series 侧边栏)

**职责**: 系列文章导航, 支持 3 种响应式布局.

**识别逻辑**:
1. 优先使用 frontmatter `seriesTag` 参数
2. 其次使用 `series` taxonomy
3. 最后使用第一个 `tag`

**结构**:
```html
<button id="series-toggle-btn" class="series-toggle-btn">
  <!-- 窄屏时显示的切换按钮 -->
</button>

<div id="series-overlay" class="series-overlay">
  <!-- 遮罩层 -->
</div>

<nav id="series-container" class="series">
  <button id="series-close-btn" class="series-close-btn">
    <!-- 关闭按钮 -->
  </button>

  <div class="series-heading">
    <span class="series-icon">📚</span>
    <span class="series-title">{{ .LinkTitle }}</span>
    <span class="series-count">({{ len $pages }})</span>
  </div>

  <ol class="series-list">
    {{- range $pages -}}
      <li class="series-item{{ if $isCurrent }} series-current{{ end }}">
        <a href="{{ .RelPermalink }}">{{ .Title }}</a>
        {{- if and $isCurrent $tocBody -}}
        <div class="series-toc">
          {{ $tocBody }}  <!-- 嵌入式 TOC (2 列模式) -->
        </div>
        {{- end -}}
      </li>
    {{- end -}}
  </ol>
</nav>

<script>
  // 弹出/关闭逻辑
  function openSeries() { /* ... */ }
  function closeSeries() { /* ... */ }
  // ESC 键关闭
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeSeries();
  });
</script>
```

**交互**:
- 窄屏: 点击左下角按钮弹出, ESC/遮罩/链接点击关闭
- 中屏: 固定左侧, TOC 嵌入当前文章下方
- 宽屏: 固定左侧, TOC 独立右侧

---

### toc.html (目录组件)

**职责**: 生成响应式目录, 支持滚动同步高亮.

**结构**:
```html
<div class="toc-container">
  <div class="toc">
    <details {{ if .Param "TocOpen" }} open{{ end }}>
      <summary>文章目录</summary>
      {{ partial "toc_body.html" . }}
    </details>
  </div>
</div>

<script>
  // Scroll Spy: 高亮当前章节
  function computeActiveId() {
    let current = headings[0].id;
    for (const h of headings) {
      if (h.getBoundingClientRect().top <= threshold) {
        current = h.id;
        continue;
      }
      break;
    }
    return current;
  }

  function setActive(id) {
    // 移除旧高亮, 添加新高亮
    linkMap.get(activeId).forEach(a => a.classList.remove('active'));
    linkMap.get(id).forEach(a => a.classList.add('active'));
  }
</script>
```

**Scroll Spy 逻辑**:
- 监听 `scroll` 事件 (使用 `requestAnimationFrame` 节流)
- 计算当前可见的最顶部标题
- 同步高亮所有 TOC (侧边栏 + Series 嵌入式 + 内嵌式)

---

### footer.html (页脚)

**职责**: 页脚信息, 统计, 交互脚本.

**功能模块**:
1. **网站信息**: Hugo/PaperMod/阿里云 logo
2. **运行时间**: 自 2021-07-13 起实时计算
3. **访问统计**: 不蒜子 (总访客/总访问量)
4. **ICP 备案**: 链接到工信部
5. **返回顶部**: 带阅读进度百分比
6. **代码复制**: Mac 风格代码块头部 + 复制按钮

**代码复制实现**:
```javascript
document.querySelectorAll('pre > code').forEach((codeblock) => {
  const copybutton = document.createElement('button');
  copybutton.classList.add('copy-code');
  copybutton.innerText = '📄复制';

  copybutton.addEventListener('click', (cb) => {
    const range = document.createRange();
    range.selectNodeContents(codeblock);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    document.execCommand('copy');
    copybutton.innerText = '👌🏻已复制!';
    setTimeout(() => {
      copybutton.innerText = '📄复制';
    }, 2000);
  });

  // Mac 风格头部
  let macTool = document.createElement("div");
  macTool.setAttribute('class', 'mac-tool');
  // 添加红黄绿三个圆点 + 语言标签
  // ...
});
```

---

### extend_head.html (自定义 head)

**职责**: 加载自定义资源, 图片懒加载脚本.

**内容**:
```html
<!-- 自定义字体 -->
<link rel="stylesheet" href="/fonts/JetBrainsLxgwNerdMono/all.css" />

<!-- 图片懒加载 -->
<script>
document.addEventListener('DOMContentLoaded', function() {
  const lazyImages = document.querySelectorAll('img.lazyload');

  if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver(function(entries, observer) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          const img = entry.target;
          img.src = img.dataset.src;  // 替换 src
          img.classList.remove('lazyload');
          img.classList.add('lazyloaded');
          imageObserver.unobserve(img);
        }
      });
    }, {
      rootMargin: '50px 0px',  // 提前 50px 加载
      threshold: 0.01
    });

    lazyImages.forEach(img => imageObserver.observe(img));
  } else {
    // 降级: 直接加载
    lazyImages.forEach(img => img.src = img.dataset.src);
  }
});
</script>
```

---

### comments.html (评论系统)

**职责**: Twikoo 评论系统初始化.

**配置**:
```html
<div id="tcomment"></div>

<script src="/js/twikoo/{{ .Site.Params.twikoo.version }}/twikoo.min.js"></script>

<script>
  twikoo.init({
    envId: "https://www.lvbibir.cn/twikoo/",
    el: "#tcomment",
    lang: 'zh-CN',
    path: window.TWIKOO_MAGIC_PATH || window.location.pathname
  });
</script>
```

---

## 图片懒加载

### render-image.html

**职责**: 覆盖 Markdown 图片渲染, 添加懒加载属性.

**实现**:
```html
<img
  class="lazyload"
  src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
  data-src="{{ .Destination | safeURL }}"
  alt="{{ .Text }}"
  {{ with .Title }}title="{{ . }}"{{ end }}
  decoding="async"
/>
<noscript>
  <img src="{{ .Destination | safeURL }}" alt="{{ .Text }}" />
</noscript>
```

**原理**:
- `src` 设为 1x1 透明 GIF (base64)
- 真实 URL 存在 `data-src`
- JS (在 `extend_head.html`) 监听图片进入视口, 替换 `src`

---

## Shortcodes

### friend.html (友链卡片)

**用法**:
```markdown
{{< friend name="站点名称" url="https://example.com" logo="/images/logo.png" word="站点描述" >}}
```

**实现**:
```html
{{- if .IsNamedParams -}}
<a target="_blank" href={{ .Get "url" }} title={{ .Get "name" }} class="friendurl">
  <div class="frienddiv">
    <div class="frienddivleft">
      <img class="myfriend" src={{ .Get "logo" }} />
    </div>
    <div class="frienddivright">
      <div class="friendname">{{- .Get "name" -}}</div>
      <div class="friendinfo">{{- .Get "word" -}}</div>
    </div>
  </div>
</a>
{{- end }}
```

**样式**: 见 `assets/css/extended/friend-link.css`

---

## 模板变量

### 常用 Hugo 变量

| 变量 | 说明 | 示例 |
|------|------|------|
| `.Site.Params.xxx` | config.yml 中的 params | `.Site.Params.ShowToc` |
| `.Title` | 页面标题 | `{{ .Title }}` |
| `.Content` | 渲染后的内容 | `{{ .Content }}` |
| `.TableOfContents` | 自动生成的目录 HTML | `{{ .TableOfContents }}` |
| `.Param "key"` | 获取参数 (支持 frontmatter 覆盖) | `.Param "ShowToc"` |
| `.GetTerms "tags"` | 获取分类项 | `{{ range .GetTerms "tags" }}` |
| `.RelPermalink` | 相对永久链接 | `/posts/article-name/` |
| `.Date` | 发布日期 | `{{ .Date.Format "2006-01-02" }}` |
| `.Lastmod` | 最后修改日期 | `{{ .Lastmod }}` |

### 条件判断

```go
{{- if .Param "ShowToc" -}}
  {{ partial "toc.html" . }}
{{- end -}}

{{- with .Description -}}
  <div class="post-description">{{ . }}</div>
{{- end -}}

{{- range $index, $page := $pages -}}
  {{ if eq $index 0 }}首篇{{ end }}
{{- end -}}
```

---

## 修改指南

### 覆盖主题模板

1. 复制 `themes/PaperMod/layouts/` 中的文件到 `layouts/` 同路径
2. 修改复制后的文件
3. Hugo 会优先使用 `layouts/` 中的版本

### 添加 Partial

1. 在 `layouts/partials/` 下创建 `.html` 文件
2. 在模板中引用: `{{ partial "name.html" . }}`
3. 传递上下文: `.` 表示当前页面上下文

### 添加 Shortcode

1. 在 `layouts/shortcodes/` 下创建 `.html` 文件
2. 在 Markdown 中使用: `{{< name param="value" >}}`
3. 获取参数: `.Get "param"`

### 修改图片渲染

编辑 `layouts/_default/_markup/render-image.html`, 自定义 `<img>` 标签输出.

---

## 性能优化

### partialCached

对于不变的组件 (header/footer), 使用 `partialCached` 缓存:

```go
{{- partialCached "header.html" . .Page -}}
{{- partialCached "footer.html" . .Layout .Kind (.Param "hideFooter") -}}
```

**缓存键**: 后续参数作为缓存键, 确保不同页面类型使用不同缓存.

### 懒加载

- 图片: IntersectionObserver API
- 字体: `font-display: swap` (在 CSS 中)
- JS: `defer` 或 `async` 属性

---

## 调试技巧

### 查看变量

```go
{{ printf "%#v" . }}  <!-- 打印当前上下文 -->
{{ printf "%#v" .Params }}  <!-- 打印 frontmatter 参数 -->
```

### 检查条件

```go
{{- if .Param "ShowToc" -}}
  <!-- TOC 已启用 -->
{{- else -}}
  <!-- TOC 已禁用 -->
{{- end -}}
```

### 浏览器开发者工具

- 检查 `.post-grid` 的 class, 判断当前布局模式
- 查看 CSS 变量: `getComputedStyle(document.documentElement).getPropertyValue('--series-width')`
- 监听事件: `monitorEvents(document, 'scroll')`

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `../config.yml` | 模板参数配置 |
| `../assets/css/extended/` | 配套 CSS 样式 |
| `../themes/PaperMod/layouts/` | 原始主题模板 (参考) |
| `../i18n/en.yaml` | 翻译文件 |

---

## 常见问题

### Q: 如何禁用某个页面的 TOC?

A: 在 frontmatter 中设置 `ShowToc: false`.

### Q: 如何自定义 Series 识别逻辑?

A: 在 frontmatter 中设置 `seriesTag: "标签名"`, 优先级最高.

### Q: 如何修改代码块样式?

A: 编辑 `assets/css/extended/code.css` 和 `footer.html` 中的 JS.

### Q: 如何添加新的 shortcode?

A: 在 `layouts/shortcodes/` 下创建 `.html` 文件, 参考 `friend.html`.

---

## 下一步

- 补扫未读取的 partials: `breadcrumbs.html`, `post_nav_links.html`, `anchored_headings.html`
- 了解主题原始模板: 查看 `themes/PaperMod/layouts/` 对比差异
- 学习 Hugo 模板语法: https://gohugo.io/templates/
