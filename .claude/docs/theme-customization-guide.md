# 主题定制指南

> 完整的博客主题定制教程，从基础到高级

---

## 📋 目录

- [快速开始](#快速开始)
- [颜色定制](#颜色定制)
- [布局定制](#布局定制)
- [字体定制](#字体定制)
- [动画定制](#动画定制)
- [组件定制](#组件定制)
- [深色模式定制](#深色模式定制)
- [高级定制](#高级定制)
- [常见问题](#常见问题)

---

## 🚀 快速开始

### 定制流程

```
1. 修改 CSS 变量 (推荐)
   ↓
2. 覆盖样式规则 (进阶)
   ↓
3. 修改模板文件 (高级)
```

### 文件位置

| 类型 | 路径 | 说明 |
|------|------|------|
| CSS 变量 | `assets/css/extended/blank.css` | 核心变量定义 |
| 自定义样式 | `assets/css/extended/*.css` | 扩展样式文件 |
| 模板文件 | `layouts/` | 覆盖主题模板 |
| 配置文件 | `config.yml` | 主题配置 |

---

## 🎨 颜色定制

### 1. 修改主题色

**位置**: `assets/css/extended/blank.css`

```css
:root {
    /* 修改主题强调色 */
    --lv-accent: #42b983;        /* 改为你喜欢的颜色 */
    --lv-accent-rgb: 66, 185, 131; /* 对应的 RGB 值 */
}
```

**示例：改为蓝色主题**
```css
:root {
    --lv-accent: #3498db;
    --lv-accent-rgb: 52, 152, 219;
}
```

**效果范围**:
- 链接高亮颜色
- TOC 当前项高亮
- 引用块左边框
- 按钮强调色

### 2. 修改边框颜色

```css
:root {
    /* 浅色边框 */
    --lv-border-light: #ddd;

    /* 表格边框 */
    --lv-border-table: #979da3;
}

/* 深色模式 */
.dark {
    --lv-border-light: rgba(255, 255, 255, 0.1);
}
```

### 3. 修改文本颜色

```css
:root {
    /* 次要文本 */
    --lv-text-muted: #777;

    /* 悬停文本 */
    --lv-text-hover: rgb(108, 108, 108);
}

/* 深色模式 */
.dark {
    --lv-text-muted: rgba(180, 181, 182, 0.6);
    --lv-text-hover: rgba(180, 181, 182, 0.8);
}
```

### 4. 修改代码块颜色

```css
:root {
    /* 代码块背景 (浅色) */
    --code-bg: rgb(240, 240, 240);

    /* 代码高亮背景 (深色) */
    --hljs-bg: rgb(44, 44, 44);

    /* 代码块边框 */
    --code-bg-border: rgb(200, 200, 200);
}
```

---

## 📐 布局定制

### 1. 修改内容宽度

```css
:root {
    /* 文章内容宽度 */
    --article-width: 800px;  /* 默认 800px，可改为 900px 或 1000px */

    /* TOC 宽度 */
    --toc-width: 250px;      /* 默认 250px */

    /* Series 侧边栏宽度 */
    --series-width: 350px;   /* 默认 350px */
}
```

**示例：宽屏布局**
```css
:root {
    --article-width: 1000px;  /* 更宽的内容区 */
    --toc-width: 300px;       /* 更宽的 TOC */
    --series-width: 400px;    /* 更宽的 Series */
}
```

### 2. 修改间距

```css
:root {
    /* 通用间距单位 */
    --gap: 24px;  /* 默认 24px，可改为 16px 或 32px */
}
```

**效果范围**:
- 页面内边距
- 元素间距
- 网格间距

### 3. 修改页脚高度

```css
:root {
    --footer-height: 90px;  /* 默认 90px */
}
```

---

## 🔤 字体定制

### 1. 修改字体

**位置**: `assets/css/extended/blank.css`

```css
:root {
    /* 等宽字体 (代码和正文) */
    --lv-font-mono: JetBrainsLxgwNerdMono;
}

body {
    font-family: var(--lv-font-mono);
    font-size: 18px;        /* 基础字号 */
    line-height: 1.6;       /* 行高 */
}
```

**示例：使用系统字体**
```css
:root {
    --lv-font-mono: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
```

**示例：使用 Google Fonts**
```css
/* 1. 在 layouts/partials/extend_head.html 添加 */
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;700&display=swap" rel="stylesheet">

/* 2. 在 blank.css 修改 */
:root {
    --lv-font-mono: 'Noto Sans SC', sans-serif;
}
```

### 2. 修改字号

```css
body {
    font-size: 18px;  /* 基础字号，默认 18px */
}

.post-content h1 { font-size: 30px; }
.post-content h2 { font-size: 28px; }
.post-content h3 { font-size: 26px; }
.post-content h4 { font-size: 22px; }
.post-content h5 { font-size: 18px; }
.post-content h6 { font-size: 15px; }
```

---

## ⏱️ 动画定制

### 1. 修改动画速度

```css
:root {
    /* 标准动画时长 */
    --transition-duration: 0.4s;  /* 默认 0.4s，可改为 0.3s 或 0.5s */

    /* 快速动画 */
    --lv-transition-fast: 0.3s;

    /* 慢速动画 */
    --lv-transition-slow: 1s;

    /* 旋转动画 */
    --lv-transition-rotate: 0.9s;
}
```

**示例：更快的动画**
```css
:root {
    --transition-duration: 0.2s;
    --lv-transition-fast: 0.15s;
    --lv-transition-slow: 0.5s;
}
```

### 2. 修改缩放比例

```css
:root {
    /* 文章卡片 */
    --lv-scale-sm: 1.02;   /* 默认 1.02，可改为 1.05 */

    /* Logo */
    --lv-scale-md: 1.06;

    /* 友链卡片 */
    --lv-scale-friend: 1.08;

    /* 按钮 */
    --lv-scale: 1.1;

    /* 分页按钮 */
    --lv-scale-lg: 1.2;

    /* 图片点击 */
    --lv-scale-media-active: 1.35;
}
```

### 3. 禁用动画

```css
/* 全局禁用动画 */
* {
    transition: none !important;
    animation: none !important;
}
```

---

## 📐 圆角定制

### 修改圆角大小

```css
:root {
    /* 小圆角 (友链卡片, Mac 代码点) */
    --lv-radius-sm: 5px;   /* 默认 5px */

    /* 中圆角 (图片, 滚动条) */
    --lv-radius-md: 10px;  /* 默认 10px */

    /* 大圆角 (Logo 头像) */
    --lv-radius-lg: 25px;  /* 默认 25px */

    /* 图片圆角 */
    --lv-radius-media: 10px;
}
```

**示例：更圆润的风格**
```css
:root {
    --lv-radius-sm: 8px;
    --lv-radius-md: 15px;
    --lv-radius-lg: 50%;  /* 完全圆形 */
    --lv-radius-media: 15px;
}
```

**示例：方形风格**
```css
:root {
    --lv-radius-sm: 0;
    --lv-radius-md: 0;
    --lv-radius-lg: 0;
    --lv-radius-media: 0;
}
```

---

## 🌓 深色模式定制

### 1. 修改深色模式颜色

**位置**: `assets/css/extended/blank.css`

```css
.dark {
    /* 文本颜色 */
    --lv-color-text-muted: rgba(180, 181, 182, 0.8);

    /* 边框颜色 */
    --lv-border-light: rgba(255, 255, 255, 0.1);

    /* 次要文本 */
    --lv-text-muted: rgba(180, 181, 182, 0.6);

    /* 悬停文本 */
    --lv-text-hover: rgba(180, 181, 182, 0.8);
}
```

### 2. 添加深色模式专属样式

```css
/* 深色模式下的图片透明度 */
.dark img {
    opacity: 0.8;
}

/* 深色模式下的卡片背景 */
.dark .card {
    background: var(--entry);
    border-color: var(--border);
}
```

### 3. 禁用深色模式

**位置**: `config.yml`

```yaml
params:
  # 禁用深色模式切换
  disableThemeToggle: true
  # 强制使用浅色模式
  defaultTheme: light
```

---

## 🎯 组件定制

### 1. 卡片样式定制

**位置**: `assets/css/extended/blank.css` 或新建 `custom-card.css`

```css
/* 修改卡片样式 */
.post-entry {
    background: var(--entry);
    border: 2px solid var(--lv-border-light);  /* 加粗边框 */
    border-radius: var(--lv-radius-md);
    padding: calc(var(--gap) * 1.5);           /* 增加内边距 */
    transition: var(--lv-transition-shadow-transform);
}

.post-entry:hover {
    transform: scale(var(--lv-scale-sm));
    box-shadow: var(--box-shadow-hover);
    border-color: var(--lv-accent);            /* 悬停时边框变色 */
}
```

### 2. 按钮样式定制

```css
/* 修改按钮样式 */
.button {
    background: linear-gradient(135deg, var(--lv-accent) 0%, #2980b9 100%);  /* 渐变背景 */
    color: var(--white);
    border: none;
    border-radius: var(--lv-radius-sm);
    padding: 12px 24px;
    font-weight: 600;
    transition: var(--lv-transition-shadow-transform);
}

.button:hover {
    transform: scale(var(--lv-scale)) translateY(-2px);  /* 上浮效果 */
    box-shadow: 0 8px 16px rgba(var(--lv-accent-rgb), 0.3);
}
```

### 3. 代码块样式定制

```css
/* 修改代码块样式 */
.post-content pre code {
    background: var(--hljs-bg);
    border-left: 4px solid var(--lv-accent);  /* 添加左边框 */
    padding-left: 16px;
}

/* 修改 Mac 风格点颜色 */
.bb1 { background: #ff5f56; }  /* 红色 */
.bb2 { background: #ffbd2e; }  /* 黄色 */
.bb3 { background: #27c93f; }  /* 绿色 */
```

### 4. TOC 样式定制

```css
/* 修改 TOC 样式 */
.toc {
    background: var(--entry);
    border: 1px solid var(--lv-border-light);
    border-radius: var(--lv-radius-md);
    padding: 16px;
}

/* 修改 TOC 高亮颜色 */
.toc a.active {
    color: var(--lv-accent);
    font-weight: 700;
    border-bottom: 2px solid var(--lv-accent);
}
```

### 5. Series 侧边栏定制

```css
/* 修改 Series 样式 */
.series {
    background: var(--entry);
    border: 1px solid var(--lv-border-light);
    border-radius: var(--lv-radius-md);
}

/* 修改当前文章高亮 */
.series-current {
    background: rgba(var(--lv-accent-rgb), 0.15);  /* 更明显的高亮 */
    border-left: 4px solid var(--lv-accent);
    padding-left: 12px;
}
```

---

## 🔧 高级定制

### 1. 创建自定义 CSS 文件

**步骤**:
1. 在 `assets/css/extended/` 创建新文件，如 `my-custom.css`
2. PaperMod 会自动加载（按字母顺序）
3. 使用 CSS 变量保持一致性

**示例**: `assets/css/extended/my-custom.css`
```css
/* 自定义样式 */
.my-feature {
    background: var(--entry);
    border: 1px solid var(--lv-border-light);
    border-radius: var(--lv-radius-md);
    padding: var(--gap);
    transition: var(--lv-transition-shadow-transform);
}

.my-feature:hover {
    transform: scale(var(--lv-scale-sm));
    box-shadow: var(--box-shadow-hover);
}

/* 深色模式适配 */
.dark .my-feature {
    background: var(--code-bg);
    border-color: var(--lv-border-light);
}
```

### 2. 覆盖主题模板

**步骤**:
1. 从 `themes/PaperMod/layouts/` 复制模板到 `layouts/`
2. 修改复制的文件
3. Hugo 会优先使用 `layouts/` 中的文件

**示例**: 修改文章头部
```
1. 复制 themes/PaperMod/layouts/_default/single.html
   到 layouts/_default/single.html
2. 修改 layouts/_default/single.html
3. Hugo 会使用修改后的版本
```

### 3. 添加自定义 Shortcode

**位置**: `layouts/shortcodes/`

**示例**: 创建提示框 shortcode

`layouts/shortcodes/tip.html`:
```html
<div class="custom-tip" style="
    background: rgba(var(--lv-accent-rgb), 0.1);
    border-left: 4px solid var(--lv-accent);
    padding: 16px;
    margin: 20px 0;
    border-radius: var(--lv-radius-sm);
">
    <strong>💡 提示：</strong> {{ .Inner | markdownify }}
</div>
```

**使用**:
```markdown
{{< tip >}}
这是一个提示框
{{< /tip >}}
```

### 4. 性能优化

**添加 will-change**:
```css
/* 为频繁动画的元素添加性能提示 */
.frequently-animated {
    will-change: transform;
}

/* 动画结束后移除 */
.frequently-animated.animation-done {
    will-change: auto;
}
```

**注意**: `will-change` 会占用内存，不要滥用！

---

## 🎨 主题预设

### 预设 1: 极简黑白

```css
:root {
    --lv-accent: #000;
    --lv-accent-rgb: 0, 0, 0;
    --lv-border-light: #e0e0e0;
    --lv-text-muted: #666;
    --lv-radius-sm: 0;
    --lv-radius-md: 0;
    --lv-radius-lg: 0;
    --lv-radius-media: 0;
}
```

### 预设 2: 温暖橙色

```css
:root {
    --lv-accent: #ff6b35;
    --lv-accent-rgb: 255, 107, 53;
    --lv-border-light: #ffe5d9;
    --lv-text-muted: #8b4513;
    --lv-radius-sm: 8px;
    --lv-radius-md: 12px;
    --lv-radius-lg: 30px;
}
```

### 预设 3: 科技蓝

```css
:root {
    --lv-accent: #00d4ff;
    --lv-accent-rgb: 0, 212, 255;
    --lv-border-light: #e3f2fd;
    --lv-text-muted: #546e7a;
    --lv-radius-sm: 4px;
    --lv-radius-md: 8px;
    --lv-radius-lg: 20px;
}
```

### 预设 4: 自然绿 (默认)

```css
:root {
    --lv-accent: #42b983;
    --lv-accent-rgb: 66, 185, 131;
    --lv-border-light: #ddd;
    --lv-text-muted: #777;
    --lv-radius-sm: 5px;
    --lv-radius-md: 10px;
    --lv-radius-lg: 25px;
}
```

---

## ❓ 常见问题

### Q1: 修改后没有生效？

**A**: 检查以下几点：
1. 清除浏览器缓存 (Ctrl+Shift+R)
2. 重启 Hugo 服务器 (`hugo server -D`)
3. 检查 CSS 语法是否正确
4. 检查变量名是否拼写正确

### Q2: 如何只修改某个页面的样式？

**A**: 使用页面特定的 class：
```css
/* 只在首页生效 */
.home .element {
    /* 样式 */
}

/* 只在文章页生效 */
.post .element {
    /* 样式 */
}
```

### Q3: 如何恢复默认样式？

**A**:
1. 删除或注释掉自定义的 CSS
2. 或者从 Git 恢复原始文件：
```bash
git checkout assets/css/extended/blank.css
```

### Q4: 深色模式颜色不对？

**A**: 确保在 `.dark` 选择器中定义了对应的变量：
```css
.dark {
    --lv-border-light: rgba(255, 255, 255, 0.1);
    --lv-text-muted: rgba(180, 181, 182, 0.6);
}
```

### Q5: 如何调试 CSS？

**A**: 使用浏览器开发者工具：
1. 按 F12 打开开发者工具
2. 选择 Elements 标签
3. 查看 Computed 面板查看最终样式
4. 查看 Styles 面板查看 CSS 变量值

### Q6: 如何查看 CSS 变量的值？

**A**: 在浏览器控制台执行：
```javascript
getComputedStyle(document.documentElement).getPropertyValue('--lv-accent')
// 输出: "#42b983"
```

### Q7: 如何添加自定义字体？

**A**:
1. 将字体文件放在 `static/fonts/`
2. 在 CSS 中定义 @font-face
3. 修改 `--lv-font-mono` 变量

```css
@font-face {
    font-family: 'MyCustomFont';
    src: url('/fonts/MyCustomFont.woff2') format('woff2');
}

:root {
    --lv-font-mono: 'MyCustomFont', sans-serif;
}
```

---

## 📚 相关资源

- [CSS 变量快速参考](./css-variables-reference.md)
- [CSS Extended 模块文档](../docs/css-extended.md)
- [Hugo 官方文档](https://gohugo.io/documentation/)
- [PaperMod 主题文档](https://github.com/adityatelange/hugo-PaperMod/wiki)

---

## 💡 定制技巧

### 1. 使用浏览器实时预览

在浏览器开发者工具中直接修改 CSS 变量，实时查看效果：

```javascript
// 在控制台执行
document.documentElement.style.setProperty('--lv-accent', '#ff0000');
```

### 2. 保持一致性

- 始终使用 CSS 变量
- 遵循命名规范 (`--lv-` 前缀)
- 保持深色模式适配

### 3. 渐进增强

- 先修改变量（简单）
- 再覆盖样式（进阶）
- 最后修改模板（高级）

### 4. 备份原始文件

在修改前备份：
```bash
cp assets/css/extended/blank.css assets/css/extended/blank.css.bak
```

---

**最后更新**: 2026-02-02
**版本**: 1.0.0
**作者**: lvbibir
