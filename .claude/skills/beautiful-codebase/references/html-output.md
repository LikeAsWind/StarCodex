# HTML Output · 单文件 HTML 构建与交付

> **何时读**：构建预览时（Phase 3 / 4）/ Phase 6 Delivery 时。

工作区是一个 Vite + React + TS 项目，从 npm 消费 `reacticle` 最新发布版。报告源在
`article/Article.tsx`（由 `article/main.tsx` 挂载，主题在此固定），最终交付物是单页
HTML `article/article.html` —— **CSS + JS 全部 inline，断网可打开、可分享**。

## 1 · 命令一览

| 命令（在工作区根目录） | 用途 |
|---|---|
| `npm run dev` | 起 Vite 预览，Phase 3 / 4 边写边看（默认 http://localhost:5173）。 |
| `npm run typecheck` | `tsc --noEmit` 仅类型检查；CI / 提交前快速验。 |
| `npm run build` | `tsc --noEmit` + 构建自包含单页 HTML → `dist/index.html`（CSS + JS inline）。TS 报错会让构建失败，避免错误漏进交付物。 |
| `npm run html` | 复用 `npm run build`，再把单页 HTML 复制到 `article/article.html`（**交付物**）。 |

## 2 · 单文件原理

构建链路：

```
article/Article.tsx + sections/*.tsx + Cover.tsx
         │
         ▼  Vite + @vitejs/plugin-react
         │
         ▼  vite-plugin-singlefile  ── CSS / JS / 图片 base64 全部 inline
         │
         ▼
   dist/index.html  ──── npm run html ─── article/article.html
```

`vite-plugin-singlefile` 在 build 阶段把所有外链资源（CSS / JS / 小图）转成
data URL / inline `<style>` / inline `<script>`，最终产物是**单个 .html 文件**，
没有任何 `<link rel="stylesheet">` 或 `<script src="">` 指向外部资源。

## 3 · 资产 inline 策略

- **图片**：Vite 自动把小图转为 base64 data URL。大图（封面用的复杂插画）建议
  保持 SVG，直接写进 `Cover.tsx` 的 JSX 里（不需要走文件系统）。
- **字体**：terminal 主题使用 JetBrains Mono / Inter，通过 `@fontsource/*` 安装到
  本地后由 Vite inline。**不**依赖 Google Fonts / 任何 CDN，离线打开必须不掉字体。
- **Mermaid**：mermaid 库作为 npm 依赖被打进 JS bundle；图渲染在客户端首次打开时执行
  （JS 跑完才出现 SVG）。这点会影响 PDF 渲染时机，见 `pdf-output.md` 故障排除。

## 4 · Mermaid 在单文件 HTML 中的渲染

- mermaid 是 client-side 渲染：HTML 加载后由 JS 读 `<div class="mermaid">` 内的
  DSL 文本，渲染为 SVG。
- 这意味着**第一次打开页面时会有 ~200ms 的"图表占位 → 真图"切换**。属正常现象。
- 主题色由 mermaid 自身 `themeVariables` 控制，但我们通过 CSS 变量 `--ra-*` 注入；
  在工作区的 `article/main.tsx` 里有 `mermaid.initialize({ theme: 'base', themeVariables: { ... } })`。
- terminal 主题对应的 mermaid theme variables 包含暗底 + 语义色（risk red / warn
  amber / status green），具体见 `theme-profiles/terminal.md`。

## 5 · 离线打开自检

构建后必须验证以下条件（Phase 6 Delivery 第一步）：

- [ ] 关掉网络 / 拔网线 / `npm run html` 之后用 `file://` 协议打开 `article/article.html`。
- [ ] mermaid 图全部渲染（不要停在 `flowchart TD ...` 的 DSL 文本上）。
- [ ] 字体正确（不是 fallback 到系统 sans-serif）。
- [ ] 所有 SVG / 图标显示。
- [ ] TOC 链接可点（锚点跳转）。
- [ ] 浏览器控制台无 404 / no-such-resource 红字。

## 6 · 与 PDF 导出的衔接

- `article.html` 是 **主交付物**，是所有 PDF 的"上游"。
- PDF 是 **可选** 派生物：仅当 Checkpoint 3 用户选了 "通过 · 同时导出 HTML + PDF" 才生成。
- 两份文件并存于 `article/`：
  ```
  article/article.html   ← 始终有
  article/article.pdf    ← Checkpoint 3 选 PDF 才有
  ```
- PDF 导出命令见 `pdf-output.md`：`bash <skill>/scripts/html-to-pdf.sh`。
- **不要** 把 PDF 当主交付（它是静态快照，Section 05 mermaid 交互的鼠标 hover
  / 折叠 details 都会变成"初始态"）。

## 7 · analysis-snapshot.json

Phase 6 同时产出 `<target>/analysis-snapshot.json`，给后续 diff / 复跑用：

```json
{
  "skill": "beautiful-codebase",
  "skillVersion": "0.1.0",
  "generatedAt": "2026-06-21T10:30:00+08:00",
  "target": "C:/.../StarCodex",
  "tools": { "tier": "codegraph-indexed", "codegraph": "1.0.1", "rg": "15.1.0" },
  "inventoryHash": "sha256:abcd...",
  "sizeTier": "1k-10k",
  "readerProfile": "architecture-review",
  "theme": "terminal",
  "coverEnabled": true,
  "sectionsRendered": ["01-verdict", "02b-business-domain", "03-architecture-map", ...],
  "coverageAuditPassed": true,
  "freshnessDiff": { "added": [], "removed": [], "modified": [] }
}
```

它的最低承诺：让"今天的报告"可以和"下周复跑的报告"做有意义的 diff。

## 8 · 故障排除

| 症状 | 排查 |
|---|---|
| `npm run html` 失败 | 先跑 `npm run typecheck`，多数情况是 TSX 类型错。 |
| 打开 HTML 后 mermaid 不渲染 | 看控制台报错；常见是 mermaid DSL 语法不合法（少了 `flowchart TD` 头 / 节点 id 含非法字符）。 |
| 字体在线 OK / 离线 fallback | 检查 `package.json` 是否有 `@fontsource/*`；不要使用 Google Fonts CDN。 |
| 单文件超过 5 MB | 找一下 base64 图，看有没有不必要的大 PNG。SVG 通常很小，PNG / JPG 几兆就要替换为 inline SVG 或外部引用（但外部引用会破坏单文件离线性，慎用）。 |
| HTML 在某些浏览器（IE11 / 老 Safari）打不开 | reacticle + Vite 目标是现代浏览器；这是预期，不修。 |

## 9 · Delivery Checklist —— Phase 6 入口是 `delivery.sh`

不要散着手跑 `npm run html` / 写 snapshot / 跑 audit / 调 pdf。**Phase 6 的 canonical
入口是 `scripts/delivery.sh`**——它把 §1 的 build + §5 的离线自检 + Phase 5 审计闸 +
§7 的 `analysis-snapshot.json` + 可选 PDF 串成一条命令，并在任何一步失败时给出明确的
退出码（见脚本头注释）：

```bash
# 默认：审计闸 → build → snapshot
bash <skill>/scripts/delivery.sh --workspace ./<project>-analysis

# Checkpoint 3 用户选了"HTML + PDF"
bash <skill>/scripts/delivery.sh --workspace ./<project>-analysis --pdf

# Phase 5 已经跑过审计、确认 pass，只想 build + snapshot
bash <skill>/scripts/delivery.sh --workspace ./<project>-analysis --skip-audits
```

| 步骤 | 阻断？ | 失败时的退出码 |
|---|---|---|
| 1 · workspace probe（inventory / plan / Article.tsx / package.json） | 阻断 | 1 |
| 2 · `audit/coverage.sh`（任何缺失 → fail） | 阻断 | 2 |
| 2 · `audit/density.sh --all`（任何 section 违规 → fail） | 阻断 | 2 |
| 2 · `audit/freshness.sh` | 信息（不阻断） | — |
| 3 · `npm run build` + `npm run html`（如有） | 阻断 | 3 |
| 3 · 单文件 invariant（外部 `<script src=>` 与 `<link rel=stylesheet href=>` 必须为 0） | 阻断 | 4 |
| 4 · 写 `analysis-snapshot.json` | 永远尝试，best-effort | — |
| 5 · `--pdf` 时调 `html-to-pdf.sh` | 阻断（仅当 `--pdf`） | 5 |

`delivery.sh` 把单文件 invariant 用一行 grep 强制：

```bash
# 在生成的 article/article.html 中执行
grep -c '<script[^>]*\bsrc='                    article/article.html  # 必须为 0
grep -c '<link[^>]*rel="?stylesheet"?[^>]*href=' article/article.html  # 必须为 0
```

任何一个 > 0 都意味着 `vite-plugin-singlefile` 没有 inline 完所有外链资源——通常是
`vite.config.ts` 配置漂移或新加的依赖不被 plugin 捕获。修后重跑 `delivery.sh`。

## 10 · `analysis-snapshot.json` Schema（v0.1.0）

`delivery.sh` 在 Step 4 写入 `<workspace>/analysis-snapshot.json`。所有字段都来自磁盘
artifact（inventory / tier / coverage / freshness / plan），如果某字段抓不到就退化为
`"see plan/plan.md"` 或 `"unknown"` / `null`——**不静默猜测**。

```json
{
  "skill": "beautiful-codebase",
  "skillVersion": "0.1.0",
  "deliveredAt": "2026-06-21T10:30:00Z",
  "discoverSnapshot": "2026-06-21T10:00:00Z",
  "workspace": "/abs/path/to/<project>-analysis",
  "target":    "/abs/path/to/<project>",
  "tools": {
    "tier":          "codegraph-indexed",
    "codegraph":     "1.0.1",
    "codegraphSha":  "<sha1 of target/.codegraph HEAD if available, else empty>",
    "rg":            "15.1.0",
    "grep":          "3.0"
  },
  "sizeTier":       "1k-10k",
  "analyzedFiles":  482,
  "readerProfile":  "architecture-review",
  "theme":          "terminal",
  "width":          "regular",
  "assetMode":      "none",
  "sectionsRendered": ["01-verdict", "02b-business-domain", "03-architecture-map", "…"],
  "coverage": {
    "verdict":     "pass",
    "coveragePct": 100.00
  },
  "freshness": {
    "verdict":       "fresh",
    "addedCount":    0,
    "removedCount":  0,
    "modifiedCount": 0,
    "summaryFile":   "review/freshness-summary.md"
  },
  "audits": "re-ran coverage + density + freshness",
  "html": {
    "path":                "article/article.html",
    "sizeBytes":           1234567,
    "externalScripts":     0,
    "externalStylesheets": 0
  }
}
```

字段约定：

- **`discoverSnapshot`** —— Phase 1 写入 `inventory.json` 的 ISO 时间；用于和
  `deliveredAt` 算 staleness。
- **`tools.codegraphSha`** —— 仅在 tier=`codegraph-indexed` 且 `target/.codegraph` 是
  git 仓库时填；其它情况是空串。它是"复跑能否得到同一份 inventory"的真凭。
- **`coverage` / `freshness`** —— 直接读 `review/coverage.json` / `review/freshness.json`；
  Phase 5 没跑过时退化为 `not-run` + `null`。
- **`readerProfile` / `theme` / `width` / `assetMode`** —— best-effort 从 `plan/plan.md`
  抓 Brief 段，抓不到就写 `"see plan/plan.md"`。**不替用户编造**。

这份 snapshot 的最低承诺：让"今天的报告"可以和"下周复跑的报告"做有意义的 diff
（diff `discoverSnapshot` / `coveragePct` / `sectionsRendered` / `freshness.*Count`
就够了）。
