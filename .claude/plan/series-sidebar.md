# 📋 实施计划：Series Sidebar (系列文章侧边栏)

## 任务类型

- [x] 前端 (→ Gemini)
- [ ] 后端 (→ Codex)
- [x] 全栈 (→ 并行)

---

## 技术方案

### 核心架构决策

采用 **CSS Grid 布局** 实现三栏响应式布局，替代现有的绝对定位方案。

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 布局方案 | CSS Grid | 可预测性强，维护性好，原生支持区域重排 |
| 数据来源 | `.GetTerms "tags"` | 高效，避免全站扫描 |
| 系列选择 | 首个 tag + `seriesTag` 覆盖 | 兼容现有内容，支持自定义 |
| 高亮类名 | `.series-current` | 避免与 TOC 的 `.active` 冲突 |

### 响应式断点

| 断点 | 宽度范围 | 布局 |
|------|----------|------|
| Wide | >1440px | 3列: Series \| Content \| TOC |
| Medium | 1024-1440px | 2列: (Series + TOC) \| Content |
| Small | <1024px | 1列: Series → Content，TOC 弹出模式 |

---

## 实施步骤

### Step 1: 添加 CSS 变量

**文件**: `assets/css/extended/blank.css`

**操作**: 修改

**说明**: 添加 `--series-width` 变量

```css
:root {
    /* 新增 */
    --series-width: 280px;
}
```

---

### Step 2: 创建 Series Partial

**文件**: `layouts/partials/series.html`

**操作**: 新建

**说明**: 系列文章列表组件，基于 tags 获取相关文章

**数据流**:
1. 优先使用 `.Params.seriesTag` (frontmatter 覆盖)
2. 回退到 `.GetTerms "tags"` 的第一个 tag
3. 获取该 tag 下的所有文章
4. 高亮当前文章

**边界条件处理**:
- 无 tags 且无 seriesTag → 不渲染
- seriesTag 指定的 tag 不存在 → 不渲染
- tag 下仅 1 篇文章 → 不渲染 (避免无意义的 UI)
- 50+ 篇文章 → CSS 限制高度 + 滚动

**伪代码**:
```go-html-template
{{- $terms := .GetTerms "tags" -}}
{{- $seriesTagParam := .Params.seriesTag | default "" -}}
{{- $termPage := nil -}}

{{- if $seriesTagParam -}}
  {{- $termPage = site.GetPage (printf "/tags/%s" ($seriesTagParam | urlize)) -}}
{{- else if gt (len $terms) 0 -}}
  {{- $termPage = index $terms 0 -}}
{{- end -}}

{{- with $termPage -}}
  {{- $pages := .Pages.ByDate -}}
  {{- if ge (len $pages) 2 -}}
    <nav class="series" aria-label="Series">
      <div class="series-heading">
        <span class="series-title">{{ .LinkTitle }}</span>
        <span class="series-count">{{ len $pages }}</span>
      </div>
      <ol class="series-list">
        {{- range $pages -}}
          {{- $isCurrent := eq .RelPermalink $.RelPermalink -}}
          <li class="series-item{{ if $isCurrent }} series-current{{ end }}">
            <a href="{{ .RelPermalink }}" title="{{ .Title | plainify }}">{{ .Title }}</a>
          </li>
        {{- end -}}
      </ol>
    </nav>
  {{- end -}}
{{- end -}}
```

---

### Step 3: 修改 Single 页面布局

**文件**: `layouts/_default/single.html`

**操作**: 修改

**说明**: 引入 Grid 容器，整合 Series 和 TOC

**关键变更**:
1. 添加 `.post-grid` 容器包裹内容
2. 捕获 series/toc partial 输出，条件渲染
3. 添加 `.has-series` / `.has-toc` 修饰类

**伪代码**:
```go-html-template
{{- $seriesHTML := partial "series.html" . -}}
{{- $tocHTML := "" -}}
{{- if (.Param "ShowToc") -}}
  {{- $tocHTML = partial "toc.html" . -}}
{{- end -}}

<article class="post-single">
  <div class="post-grid{{ if $seriesHTML }} has-series{{ end }}{{ if $tocHTML }} has-toc{{ end }}">
    {{- if $seriesHTML -}}
    <aside class="post-grid__series">{{ $seriesHTML }}</aside>
    {{- end -}}

    <div class="post-grid__content">
      <!-- 原有 header/cover/content/reward/footer 移入此处 -->
    </div>

    {{- if $tocHTML -}}
    <aside class="post-grid__toc">{{ $tocHTML }}</aside>
    {{- end -}}
  </div>
</article>
```

---

### Step 4: 创建 Series 样式 + Grid 布局

**文件**: `assets/css/extended/series.css`

**操作**: 新建

**说明**: Grid 布局定义 + Series 组件样式

**伪代码**:
```css
/* 允许单页宽度扩展 */
.post-single {
  max-width: none;
}

.post-grid {
  display: grid;
  gap: var(--gap);
  align-items: start;
  margin: 0 auto;
  width: min(100%, calc(var(--series-width) + var(--article-width) + var(--toc-width) + var(--gap) * 6));
}

/* Wide: 3 columns */
@media (min-width: 1441px) {
  .post-grid.has-series.has-toc {
    grid-template-columns: var(--series-width) minmax(0, var(--article-width)) var(--toc-width);
    grid-template-areas: "series content toc";
  }
  /* ... 其他组合 */
}

/* Medium: TOC under Series */
@media (min-width: 1024px) and (max-width: 1440px) {
  .post-grid.has-series.has-toc {
    grid-template-columns: var(--series-width) minmax(0, var(--article-width));
    grid-template-areas:
      "series content"
      "toc content";
  }
}

/* Small: single column */
@media (max-width: 1023px) {
  .post-grid {
    grid-template-columns: minmax(0, 1fr);
    grid-template-areas:
      "series"
      "content"
      "toc";
  }
}

/* Series UI */
.series {
  border: 1px solid var(--border);
  background: var(--entry);
  border-radius: var(--radius);
  padding: 12px;
}

.series-list {
  max-height: 70vh;
  overflow-y: auto;
}

.series-current a {
  color: var(--primary);
  font-weight: 600;
}
```

---

### Step 5: 重构 TOC JavaScript

**文件**: `layouts/partials/toc.html`

**操作**: 修改

**说明**: 简化宽度判定逻辑，使用 `matchMedia()` 替代 `scrollWidth` 计算

**关键变更**:
1. 移除 `checkTocPosition()` 中的宽度计算
2. 使用 `matchMedia()` 监听断点变化
3. 保留: 滚动高亮、移动端弹出、ESC/overlay 关闭

**伪代码**:
```javascript
const mSmall = window.matchMedia('(max-width: 1023px)');
const mMedium = window.matchMedia('(min-width: 1024px) and (max-width: 1440px)');
const mWide = window.matchMedia('(min-width: 1441px)');

function getMode() {
  if (mSmall.matches) return 'small';
  if (mMedium.matches) return 'medium';
  return 'wide';
}

function applyMode(mode) {
  tocContainer.classList.remove('wide', 'mobile-popup', 'collapsed');
  if (mode === 'small') {
    tocContainer.classList.add('collapsed');
  }
}

[mSmall, mMedium, mWide].forEach(mq =>
  mq.addEventListener('change', () => applyMode(getMode()))
);
```

---

### Step 6: 更新 TOC CSS

**文件**: `assets/css/extended/toc.css`

**操作**: 修改

**说明**: 移除绝对定位，适配 Grid 布局

**关键变更**:
1. `.toc-container.wide` 不再使用 `position: absolute`
2. 使用 `position: sticky` 实现固定效果
3. 保留 `.mobile-popup` 样式不变

**伪代码**:
```css
/* 移除旧的绝对定位 */
.toc-container.wide {
  position: static;
  height: auto;
  right: auto;
  width: 100%;
}

/* Grid 内的 sticky 定位 */
.post-grid__toc .toc {
  position: sticky;
  top: var(--gap);
}
```

---

## 关键文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `assets/css/extended/blank.css` | 修改 | 添加 `--series-width` 变量 |
| `layouts/partials/series.html` | 新建 | 系列文章列表组件 |
| `layouts/_default/single.html` | 修改 | 引入 Grid 容器 |
| `assets/css/extended/series.css` | 新建 | Grid 布局 + Series 样式 |
| `layouts/partials/toc.html` | 修改 | 简化 JS，适配 Grid |
| `assets/css/extended/toc.css` | 修改 | 移除绝对定位 |

---

## 风险与缓解

| 风险 | 缓解措施 |
|------|----------|
| 现有 TOC 行为回归 | 保留移动端弹出逻辑，仅修改宽度判定方式 |
| 大 tag 列表性能 | CSS 限制 `max-height: 70vh` + `overflow-y: auto` |
| `.active` 类名冲突 | Series 使用独立的 `.series-current` 类 |
| 长标题溢出 | 使用 `-webkit-line-clamp: 2` + `title` 属性 |
| 无 tags 文章布局异常 | 条件渲染 + `.has-series` 修饰类控制 Grid |

---

## 测试用例

### 内容矩阵
- [ ] 无 tags 的文章
- [ ] 单 tag 且仅 1 篇文章
- [ ] 单 tag 且多篇文章
- [ ] 多 tags 的文章 (默认取第一个)
- [ ] 使用 `seriesTag` 覆盖的文章
- [ ] `seriesTag` 指向不存在的 tag
- [ ] tag 下 50+ 篇文章
- [ ] 超长标题文章

### 断点测试
- [ ] 1600px: 3列布局
- [ ] 1280px: 2列布局 (TOC 在 Series 下方)
- [ ] 375px: 单列 + TOC 弹出

### 主题测试
- [ ] Light 模式
- [ ] Dark 模式

---

## SESSION_ID (供 /ccg:execute 使用)

- CODEX_SESSION: `019c0e51-fcac-7502-b835-c5794b06462d`
- GEMINI_SESSION: `2d9c982f-d53e-4142-b3a3-033ea4e7b2d0`
