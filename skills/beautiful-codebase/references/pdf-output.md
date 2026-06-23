# PDF Output · PDF 输出规范

> **何时读**: Checkpoint 3 选定输出 PDF 时；Phase 6 交付 PDF 时

## 1 · 生成方式

```bash
bash <skill>/scripts/html-to-pdf.sh <project>-analysis/article/article.html
```

使用 Chromium Puppeteer headless 打印。依赖 `scripts/pdf-print-overrides.css`。

## 2 · 打印样式

PDF 输出由 single-file HTML 自带 `@media print` 样式控制：

| 特征 | 方案 |
|------|------|
| 封面 | 3:4 占首页，`break-after: page` 让 TOC 从第二页开始 |
| 分页 | Section 之间 `break-before: page`（可选，通过 class 控制） |
| 颜色 | terminal 暗底？Tufte 亮底？跟随主题 token |
| 字体 | 跟随主题，不额外下载 |
| SVG | 保持内联，不缩放变形 |
| 超链接 | TOC 锚点可点击，外部链接可点击 |

## 3 · 限制

- 封面在 PDF 中保持 3:4（不被 Chromium print 拉伸）
- 暗底 terminal 主题 PDF 在黑白打印时可能对比度不足，通过 `pdf-print-overrides.css` 调整
- 内联 SVG 图表不要在 PDF 中出现裁切
