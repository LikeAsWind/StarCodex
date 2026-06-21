# PDF Output · `html-to-pdf.sh` 用法

> **何时读**：Phase 6 Delivery 当 Checkpoint 3 用户选了 "通过 · 同时导出 HTML + PDF" 时。

把交付的单页 HTML（`article/article.html`）转成 PDF。**PDF 是可选派生物**，HTML 始终
是主交付物（能离线打开、可分享、保留 mermaid 交互体验）。

> **Phase 6 入口推荐 `scripts/delivery.sh --pdf`**：它在 build + 单文件 invariant +
> snapshot 都通过之后再调本脚本。直接手跑 `html-to-pdf.sh` 仅适合事后补 PDF / 调样式
> 时的迭代场景。详见 `references/html-output.md` §9。

## 1 · 基本用法

```bash
# Phase 6 推荐入口：先 build / 验单文件 / 写 snapshot，最后导 PDF
bash <skill>/scripts/delivery.sh --workspace ./<project>-analysis --pdf

# 或者直接调 html-to-pdf.sh（适合 HTML 已经有了，单独迭代 PDF 样式）
# 在工作区根目录（先确保有 article/article.html）
npm run html

# 默认 article/article.html → article/article.pdf
bash <skill>/scripts/html-to-pdf.sh

# 自定义路径（位置参数 或 命名参数 都行）
bash <skill>/scripts/html-to-pdf.sh ./custom.html ./custom.pdf
bash <skill>/scripts/html-to-pdf.sh --input ./custom.html --output ./custom.pdf

# 看用法
bash <skill>/scripts/html-to-pdf.sh --help
```

| 参数 | 默认 | 说明 |
|---|---|---|
| `--input <path>` / 位置 1 | `article/article.html` | 输入 HTML（必须是 reacticle + Vite 单页产物）。 |
| `--output <path>` / 位置 2 | `article/article.pdf` | 输出 PDF 路径。 |
| `--help` / `-h` | — | 打印使用说明后退出。 |

## 2 · 前提条件

本机已装 chromium-family 浏览器之一（脚本自动按下列顺序探测，找到第一个就用）：

```
chromium / chromium-browser
google-chrome / google-chrome-stable / chrome
brave-browser / microsoft-edge
/Applications/Google Chrome.app/...
/Applications/Chromium.app/...
/Applications/Microsoft Edge.app/...
/Applications/Brave Browser.app/...
/Applications/Arc.app/...
/usr/bin/chromium / /snap/bin/chromium
/c/Program Files/Google/Chrome/Application/chrome.exe       (Windows)
/c/Program Files/Microsoft/Edge/Application/msedge.exe      (Windows)
```

**找不到任何浏览器** → 脚本不会爆，会把"已经注入了 print CSS 的临时 HTML 路径"打出来，
让用户手动 `Cmd+P` / `Ctrl+P` → "另存为 PDF"。

**零 npm 依赖**：不需要 puppeteer / playwright / weasyprint，只用系统已装的浏览器
headless 模式。这是脚本的核心约束之一。

## 3 · 注入的 print CSS（`pdf-print-overrides.css`）

脚本在 `<head>` 末尾注入 `scripts/pdf-print-overrides.css`，分 5 组：

| 组 | 作用 | 关键点 |
|---|---|---|
| **0 · 主题表面** | 保留主题底色（terminal 暗底必须保留） | `print-color-adjust: exact`；`.ra-root::before` 全屏暗底兜底 |
| **A · TOC 排版** | 把左右栅格 TOC 塌成"上下"，TOC 独占首屏后正文翻页 | `.ra-article-layout--with-toc { display: block }`；`.ra-toc { break-after: page }`；长 TOC 双列省纸 |
| **B · 分页行为** | 撤销 reacticle `break-inside: avoid-page`、避免标题孤儿、保护图表原子化 | B1 `.ra-section { break-inside: auto !important }`；B5 `figure / table / codeblock { break-inside: avoid }` |
| **C · 封面** | 保持 3:4 几何，封面之后强制翻页 | `.ra-cover { break-after: page }` |
| **D · 代码分析特化** | mermaid 分页 / Source Pointers 展开 / Coverage Annex 行完整 / 状态徽章保色 | D1 mermaid 块原子化；D3 `details.bc-source-pointers` 在 print 时强制展开（让 file:line trace 可见）；D4 Coverage Annex 行不撕 |

CSS 是**独立文件**，调样式直接改 `scripts/pdf-print-overrides.css` 即可，不需要动 bash。

## 4 · 渲染流程

```
article.html  ──── awk 注入 print CSS ────  /tmp/article-print.html
                                                  │
                                                  ▼
              探测的浏览器 --headless --print-to-pdf
                                                  │
                                                  ▼
                                          article.pdf
```

Chrome 标志：

- `--headless=new` —— 新版无窗口模式；老 Chrome 自动回退到 `--headless`。
- `--no-pdf-header-footer` / `--print-to-pdf-no-header` —— 去掉浏览器自带的 URL /
  日期 / 页码（colophon 已经在文档里）。
- `--virtual-time-budget=8000` —— 给 mermaid + Raw 8 秒初始化时间。**比 beautiful-article
  的 5s 长**，因为 Section 05 可能有 50–100 张 flowchart，渲染更重。
- `--hide-scrollbars` / `--disable-gpu` / `--no-sandbox` —— 清洁渲染。

## 5 · terminal 主题在 PDF 中的表现

- terminal 是 **暗底主题**，打印费墨。Phase 6 Delivery 在生成 PDF 前应在文档首页加
  caveat（一句话 colophon 旁注："本 PDF 为暗底主题，建议屏幕阅读；如必须打印请用
  tufte / press 主题重新构建"）。
- 浏览器对 `print-color-adjust: exact` 的支持是必要前提；新版 Chromium / Edge 都
  支持，老版 Safari 不支持（PDF 会变白底 + 失去 risk-red / warn-amber 语义）。
- 解决方案：**如果用户主要诉求是打印**，在 Checkpoint 1 推荐 tufte 而不是 terminal。
- terminal PDF 在屏幕上看起来跟 HTML 一致，是这个工具链最佳的展示场景。

## 6 · 故障排除

| 症状 | 排查 |
|---|---|
| **找不到浏览器** | 脚本打印临时 HTML 路径，手动 Cmd+P。或装一个 chromium：`brew install chromium` / `apt install chromium-browser` / Windows 装 Chrome。 |
| **PDF 里 TOC 没分页 / 跟正文挤一起** | 升级浏览器到当前主版本（`break-after: page` 在老 Chromium 支持不一致）。 |
| **PDF 分页奇怪 / 大块空白页** | 通常是某个 Raw / mermaid 块被强制不分页导致整块下推。检查该块有没有 inline `style={{ breakInside: 'avoid' }}`；删掉或换更小的图。 |
| **mermaid 渲染不完整 / 是空白** | 加大 `--virtual-time-budget`（编辑脚本，从 8000 改到 12000+）。Section 05 charts 太多时分多次导出（一次 20 张以内）。 |
| **暗底主题在 PDF 里变白底** | 用户用了不支持 `print-color-adjust: exact` 的老浏览器。换 Chrome / Edge 最新版。 |
| **字体在 PDF 中变 fallback** | headless Chrome 默认不等远程字体加载；用 `@fontsource/*` 把字体 inline 进 HTML。本工作区默认就是这样配置的（见 `html-output.md` §3）。 |
| **Source Pointers `<details>` 在 PDF 里没展开** | CSS D3 段已经处理；若仍不行，看是不是自己写的 `<details>` 没加 `class="bc-source-pointers"` 或 `data-bc-source-pointers`。 |
| **Coverage Annex 行被撕开** | CSS D4 段已处理常见情况；若行内有非常长的单元格（300+ 字符），浏览器仍可能撕——折行或拆分单元格。 |

## 7 · 零 npm 依赖（设计权衡）

- ✓ 不引入 puppeteer / playwright（大型 npm 包，~150 MB 含 chromium）。
- ✓ 不引入 weasyprint（Python 依赖）。
- ✓ 只用系统 chromium 的 `--headless` 模式。
- ✗ 代价：用户必须自备 chromium。但服务器 / 开发机基本都有；CI 也容易装。

## 8 · 不在脚本里的事

- ❌ 不替用户判断"要不要 PDF"——这是 Checkpoint 3 用户独立选择项。
- ❌ 不在脚手架自动装任何 PDF 相关 npm 包（保持工作区轻量）。
- ❌ 不支持自定义页面尺寸 / 边距（Chromium `--print-to-pdf` 不暴露这些 flag；要改
  请走浏览器 GUI 打印）。
- ❌ 不动 reacticle 源码（注入 CSS 比改库更轻量、跟版本解耦）。

## 9 · Phase G 三类高频失败的快速诊断

下面三类问题是 Phase H dogfood 反复出现的"PDF 看起来不对"，每个都配对了应该改的
具体 CSS 文件 / 规则段。改完无须重 build，再跑一次 `html-to-pdf.sh` 就行。

### 9.1 Mermaid 分页被截断 / edge 出现在两页之间

**症状**：Section 05 一张 flowchart 上面 5 个节点在第 N 页底部、下面 3 个节点在第 N+1
页顶部，连线被纸缝切成两段；或 mermaid 图被强行压缩到 30% 大小。

**根因**：通常是 mermaid SVG 容器没被 `break-inside: avoid` 保护，或 SVG 超过单页可
用高度（A4 ~ 700px 内容区）。

**该看哪条规则**：

- `scripts/pdf-print-overrides.css` 的 **D1 段**（mermaid 块原子化，
  `.mermaid, [data-bc-mermaid] { break-inside: avoid }`）。
- 仍然撕开 → 通常是单图就比一页大。**不修 CSS**，去 evidence 阶段把这条 flowchart
  拆成两张（"上游链路 / 下游链路"），不要靠 print CSS 救巨型图。
- 临时验证：在 DevTools 的 Print Preview 里检查目标节点容器的
  `break-inside` computed value 是否真的是 `avoid`。reacticle 默认会给
  `.ra-section` 加 `break-inside: avoid-page`，被本脚本 B1 用 `!important` 撤掉，所以
  mermaid 必须自己拿到 `avoid`——D1 段就是干这个的。

### 9.2 封面没占满第一页 / 第二页才是 TOC

**症状**：封面 3:4 显示正常，但右下角 / 底部有大块空白；TOC 跟封面挤在第一页，或
封面被推到第二页。

**根因**：

- 封面之后没有强制翻页 → 看 `pdf-print-overrides.css` **C 段**
  （`.ra-cover { break-after: page; break-inside: avoid }`）是否生效。
- 封面被 inline `style={{ height: ... }}` 写死像素高度 → 不同打印缩放下变形；按
  `references/cover.md` 的"硬约束"用百分比 / `aspect-ratio` 撑高。
- 用户在 `article/Cover.tsx` 加了远程图片或 base64 巨图，加载超时被 headless 浏览器
  截在半渲染态 → 加大 `html-to-pdf.sh` 里的 `--virtual-time-budget`（默认 8000ms，
  可改到 12000+），或换 inline SVG。

**该看哪条规则**：`pdf-print-overrides.css` C 段 + `references/cover.md` §硬约束 1（3:4
+ PDF 独占首页）+ §硬约束 5（offline-first / 无远程图）。

### 9.3 Source Pointers `<details>` 在 PDF 里保持折叠

**症状**：每节末尾的"Source Pointers"折叠面板在 HTML 里能展开看 file:line trace，
但 PDF 里只剩一行 summary，trace 不可见——读者无法追溯证据。

**根因**：浏览器对 `<details open>` 的 print 行为不统一。本脚本通过 CSS 强制展开，
但前提是 `<details>` 元素带上了 class / data attr 让 CSS 抓到。

**该看哪条规则**：

- `scripts/pdf-print-overrides.css` **D3 段**——它的选择器是
  `details.bc-source-pointers, details[data-bc-source-pointers]`。
- 检查 `article/sections/NN-*.tsx`：Source Pointers 折叠面板必须是
  `<details className="bc-source-pointers">` 或 `<details data-bc-source-pointers>`。
- 如果用了 Reacticle `<Aside>` / `<Details>` 等组件而非原生 `<details>`，需要在
  D3 段加对应选择器（先确认渲染产物的 DOM，再扩 selector）。
- 验证方法：浏览器 Print Preview 里搜索 "Source Pointers"，看面板是否展开。

> 三类失败的共同原则：**不动 reacticle 源码、不动 `html-to-pdf.sh` 本体，只改
> `pdf-print-overrides.css` 的对应 D 段**。Phase B 把 CSS 抽成独立文件就是为了让
> 调样式不需要重构脚本。
