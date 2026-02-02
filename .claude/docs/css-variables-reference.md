# CSS 变量快速参考卡片

> 快速查找和使用博客主题的 CSS 变量

---

## 📐 布局 (Layout)

| 变量 | 值 | 用途 |
|------|-----|------|
| `--footer-height` | 90px | 页脚高度 |
| `--article-width` | 800px | 文章内容宽度 |
| `--toc-width` | 250px | 目录侧边栏宽度 |
| `--series-width` | 350px | 系列侧边栏宽度 |
| `--gap` | 24px | 通用间距单位 |

**使用示例**:
```css
.my-container {
    max-width: var(--article-width);
    padding: var(--gap);
}
```

---

## 🎨 颜色 (Colors)

### 基础颜色

| 变量 | 值 | 用途 |
|------|-----|------|
| `--hljs-bg` | rgb(44, 44, 44) | 代码高亮背景 (深色) |
| `--code-bg` | rgb(240, 240, 240) | 代码块背景 (浅色) |
| `--code-bg-border` | rgb(200, 200, 200) | 代码块边框 |
| `--black` | rgb(0, 0, 0) | 纯黑色 |
| `--white` | rgb(255, 255, 255) | 纯白色 |
| `--tag` | rgb(235, 235, 235) | 标签背景色 |

### 主题色 (Accent)

| 变量 | 值 | 用途 |
|------|-----|------|
| `--lv-accent` | #42b983 | 主题强调色 (绿色) |
| `--lv-accent-rgb` | 66, 185, 131 | 主题色 RGB 值 (用于透明度) |

**使用示例**:
```css
.highlight {
    color: var(--lv-accent);
    background: rgba(var(--lv-accent-rgb), 0.1);
}
```

### 边框颜色 (Border Colors)

| 变量 | 值 | 用途 |
|------|-----|------|
| `--lv-border-light` | #ddd | 浅色边框 |
| `--lv-border-table` | #979da3 | 表格边框 |

**深色模式自动适配**:
```css
.dark {
    --lv-border-light: rgba(255, 255, 255, 0.1);
}
```

### 文本颜色 (Text Colors)

| 变量 | 值 | 用途 |
|------|-----|------|
| `--lv-text-muted` | #777 | 次要文本颜色 |
| `--lv-text-hover` | rgb(108, 108, 108) | 悬停文本颜色 |

**深色模式自动适配**:
```css
.dark {
    --lv-text-muted: rgba(180, 181, 182, 0.6);
    --lv-text-hover: rgba(180, 181, 182, 0.8);
}
```

### 遮罩与阴影 (Overlay & Shadow)

| 变量 | 值 | 用途 |
|------|-----|------|
| `--lv-overlay-bg` | rgba(0, 0, 0, 0.5) | 遮罩层背景 |
| `--lv-shadow-dark` | rgba(0, 0, 0, 0.15) | 深色阴影 |

---

## 🔤 字体 (Typography)

| 变量 | 值 | 用途 |
|------|-----|------|
| `--lv-font-mono` | JetBrainsLxgwNerdMono | 等宽字体 (代码/正文) |

**使用示例**:
```css
.code-block {
    font-family: var(--lv-font-mono);
}
```

---

## 📐 圆角 (Radius)

| 变量 | 值 | 适用场景 |
|------|-----|----------|
| `--lv-radius-sm` | 5px | 小元素 (友链卡片, Mac 代码点) |
| `--lv-radius-md` | 10px | 中等元素 (图片, 滚动条) |
| `--lv-radius-lg` | 25px | 大元素 (Logo 头像) |
| `--lv-radius-media` | 10px | 图片圆角 (通用) |

**使用示例**:
```css
.card {
    border-radius: var(--lv-radius-sm);
}

.avatar {
    border-radius: var(--lv-radius-lg);
}

img {
    border-radius: var(--lv-radius-media);
}
```

---

## 📏 缩放 (Scale)

| 变量 | 值 | 适用场景 |
|------|-----|----------|
| `--lv-scale-sm` | 1.02 | 文章卡片 hover |
| `--lv-scale-md` | 1.06 | Logo hover |
| `--lv-scale-friend` | 1.08 | 友链卡片 hover |
| `--lv-scale` | 1.1 | 按钮 hover (标准) |
| `--lv-scale-lg` | 1.2 | 分页按钮 hover |
| `--lv-scale-media-active` | 1.35 | 图片点击放大 |

**使用示例**:
```css
.button {
    transition: transform 0.3s ease;
}

.button:hover {
    transform: scale(var(--lv-scale));
}
```

---

## ⏱️ 动画 (Motion)

### 时长 (Duration)

| 变量 | 值 | 适用场景 |
|------|-----|----------|
| `--transition-duration` | 0.4s | 标准动画时长 |
| `--lv-transition-fast` | 0.3s | 快速动画 (遮罩, 弹出) |
| `--lv-transition-slow` | 1s | 慢速动画 (友链卡片) |
| `--lv-transition-rotate` | 0.9s | 旋转动画 (友链头像) |

### 组合过渡 (Transition Presets)

| 变量 | 值 | 适用场景 |
|------|-----|----------|
| `--lv-transition-transform` | transform 0.4s ease | 变换动画 |
| `--lv-transition-color` | color 0.3s ease | 颜色过渡 |
| `--lv-transition-shadow-transform` | box-shadow + transform | 阴影+变换组合 |
| `--lv-transition-shadow-transform-slow` | 慢速阴影+变换 | 慢速组合动画 |

**使用示例**:
```css
.card {
    transition: var(--lv-transition-shadow-transform);
}

.card:hover {
    transform: scale(var(--lv-scale-sm));
    box-shadow: var(--box-shadow-hover);
}

.link {
    transition: var(--lv-transition-color);
}

.link:hover {
    color: var(--lv-accent);
}
```

### 阴影 (Shadow)

| 变量 | 值 | 适用场景 |
|------|-----|----------|
| `--box-shadow-default` | 0px 2px 4px... | 默认阴影 |
| `--box-shadow-hover` | 0px 4px 8px... | 悬停阴影 (更深) |
| `--box-shadow-light` | 1px 2px 2px... | 轻阴影 |

---

## 🌓 深色模式 (Dark Mode)

### 深色模式专属变量

| 变量 | 浅色模式值 | 深色模式值 |
|------|-----------|-----------|
| `--lv-color-text-muted` | - | rgba(180, 181, 182, 0.8) |
| `--lv-border-light` | #ddd | rgba(255, 255, 255, 0.1) |
| `--lv-text-muted` | #777 | rgba(180, 181, 182, 0.6) |
| `--lv-text-hover` | rgb(108, 108, 108) | rgba(180, 181, 182, 0.8) |

**使用方式**:
```css
/* 浅色模式 */
.element {
    border: 1px solid var(--lv-border-light);
    color: var(--lv-text-muted);
}

/* 深色模式自动适配 */
.dark .element {
    /* 变量值自动切换，无需额外代码 */
}
```

---

## 🛠️ 主题继承变量 (来自 PaperMod)

| 变量 | 浅色模式 | 深色模式 | 说明 |
|------|----------|----------|------|
| `--theme` | #fff | #1e1e1e | 背景色 |
| `--entry` | #f8f8f8 | #2e2e2e | 卡片/容器背景 |
| `--primary` | #333 | #ddd | 主要文字颜色 |
| `--secondary` | #666 | #aaa | 次要文字颜色 |
| `--tertiary` | #999 | #777 | 第三级颜色 |
| `--content` | #222 | #eee | 内容文字颜色 |
| `--border` | #e0e0e0 | #444 | 边框颜色 |
| `--radius` | 8px | 8px | 圆角半径 |

---

## 🎯 常用组合模式

### 卡片样式
```css
.card {
    background: var(--entry);
    border: 1px solid var(--lv-border-light);
    border-radius: var(--lv-radius-md);
    padding: var(--gap);
    transition: var(--lv-transition-shadow-transform);
    box-shadow: var(--box-shadow-default);
}

.card:hover {
    transform: scale(var(--lv-scale-sm));
    box-shadow: var(--box-shadow-hover);
}
```

### 按钮样式
```css
.button {
    background: var(--lv-accent);
    color: var(--white);
    border-radius: var(--lv-radius-sm);
    padding: 8px 16px;
    transition: var(--lv-transition-shadow-transform);
}

.button:hover {
    transform: scale(var(--lv-scale));
    box-shadow: var(--box-shadow-hover);
}
```

### 链接样式
```css
.link {
    color: var(--secondary);
    transition: var(--lv-transition-color);
}

.link:hover {
    color: var(--lv-accent);
}
```

### 图片样式
```css
img {
    border-radius: var(--lv-radius-media);
    transition: var(--lv-transition-transform);
}

img:active {
    transform: scale(var(--lv-scale-media-active));
}
```

---

## 📱 响应式断点参考

| 断点 | 宽度 | 说明 |
|------|------|------|
| 移动端 | < 768px | 单列布局 |
| 平板 | 768px - 1024px | 2 列布局 |
| 桌面端 | > 1024px | 3 列布局 |
| Series 2 列 | > 1170px | Series + Content |
| Series 3 列 | > 1440px | Series + Content + TOC |

---

## 🔍 快速查找

### 按用途查找

**颜色相关**: `--lv-accent`, `--lv-border-*`, `--lv-text-*`, `--lv-overlay-bg`
**尺寸相关**: `--article-width`, `--toc-width`, `--series-width`, `--gap`
**圆角相关**: `--lv-radius-sm/md/lg/media`
**动画相关**: `--lv-transition-*`, `--lv-scale-*`
**阴影相关**: `--box-shadow-*`, `--lv-shadow-dark`

### 按场景查找

**卡片组件**: `--entry`, `--lv-border-light`, `--lv-radius-md`, `--lv-scale-sm`
**按钮组件**: `--lv-accent`, `--lv-radius-sm`, `--lv-scale`
**代码块**: `--hljs-bg`, `--code-bg`, `--lv-font-mono`, `--lv-radius-sm`
**图片**: `--lv-radius-media`, `--lv-scale-media-active`
**友链**: `--lv-scale-friend`, `--lv-transition-rotate`

---

## 💡 最佳实践

### ✅ 推荐做法

```css
/* 使用变量 */
.element {
    color: var(--lv-text-muted);
    border-radius: var(--lv-radius-sm);
    transition: var(--lv-transition-color);
}

/* 组合使用 */
.card {
    background: var(--entry);
    border: 1px solid var(--lv-border-light);
    padding: var(--gap);
}
```

### ❌ 避免做法

```css
/* 硬编码颜色 */
.element {
    color: #777;  /* ❌ 应使用 var(--lv-text-muted) */
}

/* 硬编码圆角 */
.card {
    border-radius: 5px;  /* ❌ 应使用 var(--lv-radius-sm) */
}

/* 硬编码动画时长 */
.button {
    transition: color 0.3s ease;  /* ❌ 应使用 var(--lv-transition-color) */
}
```

---

## 🔗 相关文档

- [CSS Extended 模块文档](./css-extended.md)
- [主题定制指南](./theme-customization-guide.md)
- [项目总览](../../CLAUDE.md)

---

**最后更新**: 2026-02-02
**版本**: 1.0.0
