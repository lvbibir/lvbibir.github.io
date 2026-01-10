[根目录](../../../CLAUDE.md) > [assets](../../) > [css](../) > **extended**

# CSS Extended 模块

> PaperMod 主题 CSS 扩展点, 自定义样式文件.

---

## 模块职责

PaperMod 主题预留的 CSS 扩展目录. 此目录下的所有 `.css` 文件会自动加载, 用于覆盖和扩展主题默认样式.

---

## 文件清单

| 文件 | 职责 | 行数 |
|------|------|------|
| `blank.css` | 核心样式, CSS 变量, 全局布局 | ~350 |
| `code.css` | 代码块样式, Mac 风格头部 | ~80 |
| `toc.css` | 目录样式, 响应式弹出 | ~250 |
| `friend-link.css` | 友链卡片样式 | ~60 |
| `reward.css` | 打赏按钮样式 | ~50 |
| `pagination.css` | 分页样式 | ~30 |
| `tag-cloud.css` | 标签云样式 | ~40 |
| `transition.css` | 动画效果 | ~20 |
| `comment.css` | 评论区样式 | ~30 |

---

## CSS 变量

定义在 `blank.css` 的 `:root`:

```css
:root {
    --footer-height: 160px;
    --hljs-bg: #1D1F21;
    --code-bg: rgba(0, 0, 0, 0.8);
    --article-width: 800px;
    --toc-width: 230px;
    --transition-duration: 0.2s;
    --box-shadow-default: 2px 2px 8px rgba(0, 0, 0, 0.2);
    --box-shadow-hover: 2px 2px 12px rgba(0, 0, 0, 0.3);
}
```

### 主题继承变量

来自 PaperMod 主题, 可在自定义 CSS 中使用:

| 变量 | 说明 |
|------|------|
| `--theme` | 背景色 |
| `--entry` | 卡片/容器背景 |
| `--primary` | 主要文字颜色 |
| `--secondary` | 次要文字颜色 |
| `--tertiary` | 第三级颜色 |
| `--content` | 内容文字颜色 |
| `--border` | 边框颜色 |
| `--radius` | 圆角半径 |
| `--gap` | 间距单位 |

---

## 核心样式说明

### blank.css

全局基础样式:
- 自定义字体 `JetBrainsLxgwNerdMono`
- 页面布局调整 (footer 高度, 文章宽度)
- 图片点击放大效果
- blockquote 样式
- 表格样式
- 深色模式适配

Hover 工具类:
```css
.hover-transition { transition: all var(--transition-duration) ease; }
.hover-shadow:hover { box-shadow: var(--box-shadow-hover); }
.hover-scale-sm:hover { transform: scale(1.02); }
.hover-scale-md:hover { transform: scale(1.05); }
.hover-scale-lg:hover { transform: scale(1.1); }
```

### code.css

Mac 风格代码块:
- 三个彩色圆点 (红, 黄, 绿)
- 语言类型显示
- 复制按钮定位

```css
.mac-tool { /* 代码块头部工具栏 */ }
.bb1 { background: #FF5E57; }  /* 红点 */
.bb2 { background: #FEBC2E; }  /* 黄点 */
.bb3 { background: #27C840; }  /* 绿点 */
.language-type { /* 语言标签 */ }
```

### toc.css

目录样式:
- 基础目录 (`.toc`)
- 宽屏固定模式 (`.toc-container.wide`)
- 移动端弹出模式 (`.toc-container.mobile-popup`)
- 切换按钮 (`.toc-toggle-btn`)
- 遮罩层 (`.toc-overlay`)
- 当前章节高亮 (`.active`)

---

## 响应式断点

主题默认断点:
- `768px` - 移动端/桌面端分界
- TOC 宽屏模式需要足够的视口宽度

---

## 深色模式

使用 `.dark` 类选择器:

```css
.dark .element {
    /* 深色模式样式 */
}
```

主题会自动根据用户偏好和手动切换添加/移除 `.dark` 类.

---

## 添加新样式

1. 在此目录创建新 `.css` 文件
2. PaperMod 会自动加载
3. 使用 CSS 变量保持一致性
4. 提供深色模式适配

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `../../../layouts/partials/` | 使用这些样式的模板 |
| `../../../themes/PaperMod/assets/css/` | 主题原始 CSS |
| `../../../config.yml` | 主题配置 |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-01-10 | 初始化模块文档 |
