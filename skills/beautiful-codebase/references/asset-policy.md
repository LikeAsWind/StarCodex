# Asset Policy · 内联资源策略

> **何时读**: Phase 3 写封面或表格时；Phase 4 每节决定是否引入自定义资源时

## 1 · 默认策略

`beautiful-codebase` 默认禁止加载任何外部资源。所有报告必须是 offline-first 的。

| 资源类型 | 默认策略 | 例外 |
|---------|---------|------|
| 图片 | ❌ 禁止 `<img src="https://...">` | 经 Checkpoint "配图模式" 明确选择的 base64 rasters |
| 字体 | ❌ 禁止 Google Fonts 动态加载 | 无 — 只用主题自带的 font-family token |
| CSS | ❌ 禁止 `<link rel="stylesheet" href="...">` | 无 — 所有样式单文件内联 |
| JS | ❌ 禁止 `<script src="...">` | 无 — 所有 JS 单文件内联 |
| SVG | ✅ 允许内联 `<svg>` | 所有 icon/illustration 必须内联，禁止 `<img src="icon.svg">` |

## 2 · 内联 SVG 政策

- 所有 SVG 图标/插图必须是内联的 `<svg>...</svg>`
- 不引用外部 SVG 文件或 URL
- 允许 base64 编码的 data URI（仅限 Checkpoint 选择了 ai-generated 配图模式）
- Base64 image 单张 ≤ 200KB 避免单文件膨胀

## 3 · 资产大小

| 类型 | 上限 | 超限处理 |
|------|------|---------|
| 单个 SVG 图表 | 50KB | >50KB → 简化，或拆为多个子图 |
| Base64 image | 200KB | >200KB → 通知主 Agent 决定降级还是保留 |
| 总 page weight | 5MB | >5MB → 通知用户，提供缩减方案 |
