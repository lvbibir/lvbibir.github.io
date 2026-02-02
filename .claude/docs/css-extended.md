[根目录](../../../CLAUDE.md) > [assets](../../) > [css](../) > **extended**

# CSS Extended 模块

> PaperMod 主题 CSS 扩展点, 自定义样式文件.

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-02-02 | CSS 变量系统优化: 新增 Border/Text/Overlay/Radius 变量, 统一硬编码值, 添加性能优化 (will-change) |
| 2026-02-02 | 完整扫描更新: 新增 Series 样式详解, 响应式布局 CSS 说明 |
| 2026-01-10 | 初始化模块文档 |

---

## 模块职责

PaperMod 主题预留的 CSS 扩展目录. 此目录下的所有 `.css` 文件会自动加载, 用于覆盖和扩展主题默认样式.

---

## 文件清单

| 文件 | 职责 | 行数 | 关键特性 |
|------|------|------|----------|
| `blank.css` | 核心样式, CSS 变量, 全局布局 | ~342 | 字体, 颜色, 间距, Hover 工具类 |
| `series.css` | Series 侧边栏样式 | ~412 | 3 种布局模式, 响应式网格 |
| `toc.css` | 目录样式 | ~100 | 滚动同步, 高亮, 侧边栏/内嵌模式 |
| `code.css` | 代码块样式 | ~101 | Mac 风格头部, 复制按钮 |
| `friend-link.css` | 友链卡片样式 | ~104 | Hover 动画, 响应式 |
| `reward.css` | 打赏按钮样式 | ~50 | 二维码弹出 |
| `pagination.css` | 分页样式 | ~30 | 页码按钮 |
| `tag-cloud.css` | 标签云样式 | ~40 | 标签大小渐变 |
| `transition.css` | 动画效果 | ~20 | 通用过渡 |
| `comment.css` | 评论区样式 | ~30 | Twikoo 适配 |

---

## CSS 变量

### 自定义变量 (定义在 blank.css)

```css
:root {
    /* Layout */
    --footer-height: 90px;
    --article-width: 800px;
    --toc-width: 250px;
    --series-width: 350px;

    /* Colors */
    --hljs-bg: rgb(44, 44, 44);           /* 代码块背景 (深色) */
    --code-bg: rgb(240, 240, 240);        /* 代码块背景 (浅色) */
    --code-bg-border: rgb(200, 200, 200); /* 代码块边框 */
    --black: rgb(0, 0, 0);
    --white: rgb(255, 255, 255);
    --tag: rgb(235, 235, 235);

    /* Accent */
    --lv-accent: #42b983;
    --lv-accent-rgb: 66, 185, 131;

    /* Border Colors */
    --lv-border-light: #ddd;
    --lv-border-table: #979da3;

    /* Text Colors */
    --lv-text-muted: #777;
    --lv-text-hover: rgb(108, 108, 108);

    /* Overlay & Shadow */
    --lv-overlay-bg: rgba(0, 0, 0, 0.5);
    --lv-shadow-dark: rgba(0, 0, 0, 0.15);

    /* Typography */
    --lv-font-mono: JetBrainsLxgwNerdMono;

    /* Radius */
    --lv-radius-sm: 5px;
    --lv-radius-md: 10px;
    --lv-radius-lg: 25px;
    --lv-radius-media: 10px;

    /* Scale */
    --lv-scale-sm: 1.02;
    --lv-scale-md: 1.06;
    --lv-scale-friend: 1.08;
    --lv-scale: 1.1;
    --lv-scale-lg: 1.2;
    --lv-scale-media-active: 1.35;

    /* Spacing */
    --gap: 24px;

    /* Motion */
    --transition-duration: 0.4s;
    --lv-transition-fast: 0.3s;
    --lv-transition-slow: 1s;
    --lv-transition-rotate: 0.9s;
    --lv-transition-transform: transform var(--transition-duration) ease;
    --lv-transition-color: color var(--lv-transition-fast) ease;
    --lv-transition-shadow-transform: box-shadow var(--transition-duration) ease, transform var(--transition-duration) ease;
    --lv-transition-shadow-transform-slow: box-shadow var(--lv-transition-slow) ease, transform var(--lv-transition-slow) ease;

    --box-shadow-default: 0px 2px 4px rgb(5 10 15 / 40%), 0px 7px 13px -3px rgb(5 10 15 / 30%);
    --box-shadow-hover: 0px 4px 8px rgb(5 10 15 / 40%), 0px 7px 13px -3px rgb(5 10 15 / 30%);
    --box-shadow-light: 1px 2px 2px 1px rgb(144 164 174 / 60%);
}

.dark {
    /* Dark Mode Colors */
    --lv-color-text-muted: rgba(180, 181, 182, 0.8);
    --lv-border-light: rgba(255, 255, 255, 0.1);
    --lv-text-muted: rgba(180, 181, 182, 0.6);
    --lv-text-hover: rgba(180, 181, 182, 0.8);
}
```

### 主题继承变量 (来自 PaperMod)

| 变量 | 说明 | 浅色模式 | 深色模式 |
|------|------|----------|----------|
| `--theme` | 背景色 | #fff | #1e1e1e |
| `--entry` | 卡片/容器背景 | #f8f8f8 | #2e2e2e |
| `--primary` | 主要文字颜色 | #333 | #ddd |
| `--secondary` | 次要文字颜色 | #666 | #aaa |
| `--tertiary` | 第三级颜色 | #999 | #777 |
| `--content` | 内容文字颜色 | #222 | #eee |
| `--border` | 边框颜色 | #e0e0e0 | #444 |
| `--radius` | 圆角半径 | 8px | 8px |
| `--gap` | 间距单位 | 24px | 24px |

---

## 核心样式详解

### blank.css (全局基础)

**职责**: 全局样式, CSS 变量, 工具类.

**主要内容**:

1. **字体设置**
```css
body {
    font-size: 18px;
    line-height: 1.6;
    font-family: JetBrainsLxgwNerdMono;
}

.post-content {
    font-family: JetBrainsLxgwNerdMono;
}
```

2. **标题样式**
```css
.post-content h1 {
    font-size: 30px;
    border-bottom: 1px solid #ddd;
}

.post-content h2 {
    font-size: 28px;
    border-bottom: 1px solid #ddd;
}

.post-content h3 {
    font-size: 26px;
    border-bottom: 1px solid #ddd;
}
```

3. **图片效果**
```css
img {
    border-radius: 10px;
}

.dark img {
    opacity: 0.8;
}

/* 点击放大 */
img:active {
    transform: scale(1.35, 1.35);
}
```

4. **引用块**
```css
.post-content blockquote {
    border-left: 4px solid #42b983;
    padding: 1px 15px;
    color: #777;
    background-color: rgba(66, 185, 131, .1);
}
```

5. **表格样式**
```css
.post-content table tr {
    border: 1px solid #979da3 !important;
}

.post-content table tr:nth-child(2n),
.post-content thead {
    background-color: var(--code-bg);
}
```

6. **Hover 工具类**
```css
/* 基础过渡 */
.hover-transition {
    transition: box-shadow var(--transition-duration) ease,
                transform var(--transition-duration) ease;
}

/* 带阴影 */
.hover-shadow {
    transition: box-shadow var(--transition-duration) ease,
                transform var(--transition-duration) ease;
    box-shadow: var(--box-shadow-default);
}

.hover-shadow:hover {
    box-shadow: var(--box-shadow-hover);
}

/* 缩放效果 */
.hover-scale-sm:hover { transform: scale(1.02); }  /* 文章卡片 */
.hover-scale-md:hover { transform: scale(1.06); }  /* Logo */
.hover-scale:hover { transform: scale(1.1); }      /* 按钮 */
.hover-scale-lg:hover { transform: scale(1.2); }   /* 分页按钮 */
```

---

### series.css (Series 侧边栏)

**职责**: 系列文章侧边栏样式, 支持 3 种响应式布局.

**布局模式**:

1. **弹出模式** (`pg--series-popup`)
```css
.post-grid.pg--series-popup .series {
    position: fixed;
    left: 0;
    top: 0;
    bottom: 0;
    width: min(var(--series-width), 85vw);
    z-index: 200;
    transform: translateX(-100%);  /* 默认隐藏 */
    transition: transform 0.3s ease;
}

.post-grid.pg--series-popup .series.is-open {
    transform: translateX(0);  /* 弹出 */
}

.post-grid.pg--series-popup .series-toggle-btn {
    display: flex;  /* 显示切换按钮 */
    position: fixed;
    left: 30px;
    bottom: 110px;
}

.post-grid.pg--series-popup .series-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: 199;
}

.post-grid.pg--series-popup .series-overlay.is-open {
    display: block;
    opacity: 1;
}
```

2. **2 列模式** (`pg--series-two`)
```css
.post-grid.pg--series-two {
    display: grid;
    column-gap: 0;
    align-items: start;
    /* 网格列: Series | gap | 左空白 | Content | 右空白 */
    --pg-left: clamp(0px, calc((100% - var(--article-width)) / 2 - var(--series-width) - var(--content-gap)), 99999px);
    grid-template-columns: var(--series-width) var(--content-gap) minmax(0, var(--pg-left)) minmax(0, var(--article-width)) minmax(0, 1fr);
}

.post-grid.pg--series-two .post-grid__series {
    grid-column: 1;
    position: sticky;
    top: var(--header-height);
    height: calc(100vh - var(--header-height) - var(--post-grid-top-offset));
}

.post-grid.pg--series-two .post-grid__content {
    grid-column: 4;
}

/* 2 列模式: TOC 嵌入 Series */
.post-grid.pg--series-two .series-toc {
    display: block;  /* 显示嵌入式 TOC */
}
```

3. **3 列模式** (`pg--series-three`)
```css
.post-grid.pg--series-three {
    display: grid;
    column-gap: 0;
    /* 网格列: Series | gap | 左空白 | Content | gap | TOC | 右空白 */
    --pg-left: clamp(0px, calc((100% - var(--article-width)) / 2 - var(--series-width) - var(--content-gap)), 99999px);
    grid-template-columns: var(--series-width) var(--content-gap) minmax(0, var(--pg-left)) minmax(0, var(--article-width)) var(--content-gap) var(--toc-width) minmax(0, 1fr);
}

.post-grid.pg--series-three .post-grid__series {
    grid-column: 1;
}

.post-grid.pg--series-three .post-grid__content {
    grid-column: 4;
}

.post-grid.pg--series-three .post-grid__toc {
    grid-column: 6;
    display: block;  /* 显示独立 TOC */
}

/* 3 列模式: 隐藏嵌入式 TOC */
.post-grid.pg--series-three .series-toc {
    display: none;
}
```

**Series 组件样式**:
```css
.series {
    box-sizing: border-box;
    border: 1px solid var(--border);
    background: var(--entry);
    border-radius: var(--radius);
    padding: 12px;
    overflow-y: auto;
}

.series-heading {
    display: flex;
    align-items: center;
    gap: 8px;
    padding-bottom: 10px;
    border-bottom: 1px solid var(--border);
}

.series-title {
    font-weight: 600;
    font-size: 0.95rem;
    color: var(--primary);
}

.series-list {
    margin: 0;
    padding: 0;
    list-style: none;
}

.series-item {
    padding: 6px 0;
    border-bottom: 1px dashed var(--border);
}

/* 当前文章高亮 */
.series-current {
    background: rgba(var(--primary-rgb, 66, 185, 131), 0.1);
    margin: 0 -12px;
    padding: 6px 12px;
    border-radius: var(--radius);
}

.series-current > a {
    color: var(--primary);
    font-weight: 600;
}
```

**嵌入式 TOC**:
```css
.series-toc {
    margin-top: 8px;
    border-left: 2px solid var(--border);
    padding-left: 8px;
}

.series-toc ul {
    padding-left: 12px;
    list-style: none;
}

.series-toc li {
    padding: 2px 0;
    font-size: 0.85rem;
}

.series-toc a {
    color: var(--secondary);
    text-decoration: none;
}

.series-toc a:hover {
    color: var(--primary);
}
```

---

### toc.css (目录样式)

**职责**: 目录组件样式, 支持侧边栏和内嵌模式.

**基础样式**:
```css
.toc {
    margin: 0 0 40px 0;
    border: 1.2px solid var(--border);
    background: var(--entry);
    border-radius: var(--radius);
    padding: 0.4em;
}

.toc details summary {
    cursor: pointer;
    list-style: none;
    user-select: none;
}

.toc details summary::before {
    content: "➡️ ";
}

.toc details[open] summary::before {
    content: "⬇️ ";
}
```

**滚动容器**:
```css
.toc .inner {
    margin: 0 0 0 20px;
    padding: 0;
    font-size: 16px;
    max-height: 83vh;
    overflow-y: auto;
    user-select: none;
}

/* 侧边栏模式: 调整高度 */
.post-grid.pg--toc-two .toc .inner,
.post-grid.pg--series-three .toc .inner {
    max-height: calc(83vh - var(--post-grid-top-offset, 0px));
}

.toc .inner::-webkit-scrollbar-thumb {
    background: var(--border);
    border: 8px solid var(--theme);
    border-radius: var(--radius);
}
```

**高亮样式**:
```css
.toc a.active,
.series-toc a.active {
    color: #42b983;
    font-size: 100%;
    font-weight: 600;
    border-bottom: 1px solid transparent;
    padding-bottom: 0.1rem;
    border-bottom-color: #42b983;
}

.dark .toc a.active,
.dark .series-toc a.active {
    color: var(--content);
}
```

**内嵌模式隐藏**:
```css
/* 2 列模式 (无 Series): 隐藏内嵌 TOC */
.post-grid.pg--toc-two .toc--inline {
    display: none;
}
```

---

### code.css (代码块样式)

**职责**: Mac 风格代码块, 复制按钮.

**代码块基础**:
```css
.post-content code {
    font-family: JetBrainsLxgwNerdMono;
    margin: 0px;
    padding: 2px 5px;
    font-size: 0.92rem;
}

.post-content pre code {
    max-height: 40em;
    font-size: 0.75em;
    border-top-left-radius: unset;
    border-top-right-radius: unset;
    border-bottom-left-radius: var(--radius);
    border-bottom-right-radius: var(--radius);
}

.post-content .highlight:not(table),
.post-content pre {
    margin: 50px 0 0 0;
}
```

**Mac 风格头部**:
```css
.mac-tool {
    background: var(--hljs-bg);
    border-top-left-radius: var(--radius);
    border-top-right-radius: var(--radius);
    width: 100%;
    position: absolute;
    top: -25px;
    height: 25px;
}

.mac {
    width: 10px;
    height: 10px;
    border-radius: 5px;
    float: left;
    margin: 10px 0 0 5px;
}

.bb1 { background: #ef4943; margin-left: 10px; }  /* 红点 */
.bb2 { background: #f5b228; }                      /* 黄点 */
.bb3 { background: #20d032; }                      /* 绿点 */

.language-type {
    color: rgba(255, 255, 255, 0.8);
    position: absolute;
    right: 80px;
    font-size: 0.9em;
}
```

**复制按钮**:
```css
.copy-code {
    display: block;
    position: absolute;
    top: -22px;
    right: 8px;
    z-index: 1;
    color: rgba(255, 255, 255, 0.8);
    background: unset;
    border-radius: var(--radius);
    padding: 0 5px;
    font-size: 14px;
    user-select: none;
}
```

---

### friend-link.css (友链卡片)

**职责**: 友链卡片样式, Hover 动画.

**卡片布局**:
```css
.frienddiv {
    overflow: auto;
    height: 100px;
    width: 49%;
    display: inline-block !important;
    border-radius: 5px;
    background: none;
    transition: box-shadow var(--transition-duration) ease,
                transform var(--transition-duration) ease;
}

.frienddiv:hover {
    background: var(--theme);
    transform: scale(1.08);
    transition: box-shadow 1s ease, transform 1s ease;
}

.dark .frienddiv:hover {
    background: var(--code-bg);
}
```

**头像旋转**:
```css
.myfriend {
    width: 56px !important;
    height: 56px !important;
    border-radius: 50% !important;
    padding: 2px;
    margin-top: 20px !important;
    margin-left: 14px !important;
    background-color: #fff;
}

.frienddiv:hover .frienddivleft img {
    transition: 0.9s !important;
    transform: rotate(360deg) !important;
}
```

**响应式**:
```css
@media screen and (max-width: 600px) {
    .friendinfo {
        display: none;  /* 隐藏描述 */
    }

    .frienddivleft {
        width: 84px;
        margin: auto;
    }

    .friendname {
        font-size: 18px;
    }
}
```

---

## 响应式断点

### 主题默认断点

- `768px` - 移动端/桌面端分界
- `1024px` - 平板/桌面分界

### Series/TOC 断点 (动态计算)

由 `single.html` 中的 JS 根据 CSS 变量实时计算:

```javascript
// 2 列断点
const bp2 = seriesWidth + contentGap + articleWidth;
// 默认: 350 + 20 + 800 = 1170px

// 3 列断点
const bp3 = seriesWidth + contentGap + articleWidth + contentGap + tocWidth;
// 默认: 350 + 20 + 800 + 20 + 250 = 1440px
```

---

## 深色模式

### 使用 `.dark` 类选择器

```css
.dark .element {
    /* 深色模式样式 */
}
```

### 常见深色模式适配

```css
.dark body,
.dark a,
.dark .post-title {
    color: rgba(180, 181, 182, 0.8);
}

.dark img {
    opacity: 0.8;
}

.dark .series {
    background: var(--entry);
}

.dark .series-item > a {
    color: rgba(180, 181, 182, 0.8);
}

.dark .series-item > a:hover,
.dark .series-current > a {
    color: var(--primary);
}
```

---

## 添加新样式

### 步骤

1. 在 `assets/css/extended/` 创建新 `.css` 文件
2. PaperMod 会自动加载 (按字母顺序)
3. 使用 CSS 变量保持一致性
4. 提供深色模式适配
5. 为动画元素添加性能优化

### 示例

```css
/* assets/css/extended/my-feature.css */

/* 使用 CSS 变量 */
.my-element {
    background: var(--entry);
    border: 1px solid var(--lv-border-light);
    border-radius: var(--lv-radius-md);
    padding: var(--gap);
    transition: var(--lv-transition-shadow-transform);
    will-change: transform;  /* 性能优化 */
}

.my-element:hover {
    box-shadow: var(--box-shadow-hover);
    transform: scale(var(--lv-scale));
}

/* 深色模式适配 */
.dark .my-element {
    background: var(--code-bg);
    border-color: var(--lv-border-light);
}
```

---

## 性能优化

### CSS 优化

1. **使用 CSS 变量**: 减少重复, 便于维护
2. **避免深层嵌套**: 最多 3 层
3. **使用 `will-change`**: 提示浏览器优化动画
4. **合并选择器**: 减少规则数量

### 动画优化

```css
/* 使用 transform 和 opacity (GPU 加速) */
.element {
    transition: var(--lv-transition-transform);
    will-change: transform;  /* 提示浏览器优化 */
}

/* 避免使用 width/height/margin (触发重排) */
```

### will-change 使用指南

**已添加 will-change 的元素**:
- `.hover-scale-*` 系列 (通用缩放工具类)
- `.series` (Series 侧边栏滑动)
- `.frienddivleft img` (友链头像旋转)

**注意事项**:
- `will-change` 会占用内存, 不要滥用
- 只在真正需要优化的动画元素上使用
- 动画结束后可以移除 `will-change`

---

## 调试技巧

### 查看 CSS 变量

```javascript
// 浏览器控制台
getComputedStyle(document.documentElement).getPropertyValue('--series-width')
// "350px"
```

### 检查布局模式

```javascript
// 查看当前布局模式
document.querySelector('.post-grid').className
// "post-grid has-series has-toc pg--series-three"
```

### 强制深色模式

```javascript
// 添加 .dark 类
document.body.classList.add('dark')
```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `../../../layouts/partials/` | 使用这些样式的模板 |
| `../../../themes/PaperMod/assets/css/` | 主题原始 CSS |
| `../../../config.yml` | 主题配置 |

---

## 常见问题

### Q: 如何修改 Series 宽度?

A: 修改 `blank.css` 中的 `--series-width` 变量.

### Q: 如何禁用某个 CSS 文件?

A: 重命名文件扩展名 (如 `.css.bak`) 或删除文件.

### Q: 如何覆盖主题默认样式?

A: 在 `extended/` 下创建同名 CSS 文件, 使用更高优先级的选择器.

### Q: 如何调试响应式布局?

A: 使用浏览器开发者工具的响应式设计模式, 调整视口宽度观察断点切换.

---

## 下一步

- 学习 CSS Grid 布局: https://css-tricks.com/snippets/css/complete-guide-grid/
- 了解 CSS 变量: https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties
- 优化动画性能: https://web.dev/animations-guide/
