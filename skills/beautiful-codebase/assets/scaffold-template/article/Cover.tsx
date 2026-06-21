// Cover.tsx —— 代码分析报告封面（独立于 Article，位于 TOC + 正文 + colophon 之上）
//
// 这一文件是 report-specific 的（跟 Article.tsx / sections/*.tsx 同等地位）。
// 主 Agent 在 Phase 3 First Spread 把下面的【封面内容区】替换成按 **reader profile +
// 主题 + 项目主旨** 定制的设计。**外壳（3:4 比例、定位、PDF 分页）不要动**。
//
// 硬约束（详见 references/cover.md）：
//   1. **3:4 比例固定（屏幕 + PDF）**：不要改 aspectRatio；打印时 .ra-cover 会自动
//      独占首页。让内部元素用百分比 / aspect-ratio / inset 自适应，不要写绝对 px 高度。
//      允许在 3:4 外面再套一层全视口 frame（.ra-cover-frame），让屏幕视图里封面独占首屏。
//   2. **图文并茂**：必须有视觉元素 + 简短文字（标题 + 可选副题 / 小标签）。
//      **禁止纯文字封面**。
//   3. **主题忠实**：颜色 / 字号 / 字重 / 边框只能用 `--ra-*` token。terminal 主题下
//      可使用 `--ra-status-blue / --ra-status-violet / --ra-keyword` 等语义色。
//      切主题时封面要跟随刷新；不要写死颜色 / 字体名 / 像素字号。
//   4. **内容忠实**：封面的视觉主图与文字要呼应"这份报告是关于哪个项目、什么 reader
//      profile"。terminal 主题封面起手推荐：模块拓扑骨架 SVG + 项目名 + 副题。
//   5. **技术自由**：内联 SVG / CSS 几何 / Canvas / 复杂 React 组件 / 字体艺术 /
//      多层 gradient / mask / clip-path / 任意组合 —— 任选，最终效果好就行。**唯一禁止**：
//      远程图片（offline-first）。
//   6. **封面不承担正文**：不要把 Verdict 第一段、TOC、覆盖率塞进来 —— 封面只承担
//      "识别 + 风格信号 + 引起阅读欲望"。

export function Cover() {
  return (
    // ── 外层 frame ──
    // 屏幕：min-height: 100vh + flex 居中 → 3:4 封面独占首屏，
    //       Hero / Lead / Section 全部从第二屏开始。
    // 打印：page-break-after / break-after 让 PDF 第二页起承接 TOC + 正文。
    //       PDF 端 .ra-cover { break-after: page } 由 pdf-print-overrides.css C 段
    //       负责（两套机制，互不干扰）。
    <div
      className="ra-cover-frame"
      data-ra-cover-frame=""
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        pageBreakAfter: "always",
        breakAfter: "page",
      }}
    >
      <section
        className="ra-cover"
        aria-label="代码分析报告封面"
        data-ra-cover=""
        style={{
          // ── 3:4 内壳（请不要动） ──
          position: "relative",
          width: "100%",
          // 屏幕上像"一本立着的书"：限宽 48rem (768px)；同时**从视口高度反推宽度**
          // (100vh - 8rem) * 3/4，确保 3:4 封面**一屏看全、不用下拉**。
          maxWidth: "min(100%, 48rem, calc((100vh - 8rem) * 3 / 4))",
          margin: "0 auto",
          aspectRatio: "3 / 4",
          overflow: "hidden",
          background: "transparent",
          color: "var(--ra-color-fg, inherit)",
          borderRadius: "var(--ra-radius-md, 0)",
          border: "1px solid var(--ra-color-border, currentColor)",
          isolation: "isolate",
        }}
      >
        {/*
          ─── 封面内容区 · 在这里写 ───
          默认占位：terminal 主题起手——模块拓扑骨架 SVG + 项目名 + 副题。
          构建时**替换为按报告 + 主题定制的封面**。占位是"即使忘了替换也不会渲染出
          一团乱"，但**不能交付出去**。
        */}
        <CoverPlaceholder />
      </section>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────────
// 占位实现 —— 主 Agent 把 <CoverPlaceholder /> 替换成本报告真正的封面。
// ────────────────────────────────────────────────────────────────────
function CoverPlaceholder() {
  return (
    <>
      {/* terminal 主题封面起手：模块拓扑骨架——发丝级网格 + 几个节点 + 连线，
       *  用 status-blue / status-violet 语义色。其它主题封面起手见
       *  references/cover.md。视觉技术由你选，效果好就行。 */}
      <svg
        viewBox="0 0 1200 1600"
        preserveAspectRatio="xMidYMid slice"
        aria-hidden="true"
        style={{
          position: "absolute",
          inset: 0,
          width: "100%",
          height: "100%",
          color: "var(--ra-color-border, currentColor)",
          opacity: 0.7,
          zIndex: 0,
        }}
      >
        <defs>
          <pattern id="bc-cover-grid" width="80" height="80" patternUnits="userSpaceOnUse">
            <path d="M 80 0 L 0 0 0 80" fill="none" stroke="currentColor" strokeWidth="0.4" />
          </pattern>
        </defs>
        <rect width="1200" height="1600" fill="url(#bc-cover-grid)" />
        {/* Module topology nodes (placeholder; replace with project-specific
            shape derived from Section 03 Architecture Map). */}
        <g stroke="var(--ra-status-blue, currentColor)" strokeWidth="1.5" fill="none">
          <line x1="200" y1="1180" x2="500" y2="1280" />
          <line x1="500" y1="1280" x2="800" y2="1180" />
          <line x1="500" y1="1280" x2="500" y2="1450" />
          <line x1="800" y1="1180" x2="1000" y2="1320" />
        </g>
        <g fill="var(--ra-status-blue, currentColor)" opacity="0.85">
          <circle cx="200" cy="1180" r="14" />
          <circle cx="500" cy="1280" r="18" />
          <circle cx="800" cy="1180" r="14" />
          <circle cx="500" cy="1450" r="14" />
          <circle cx="1000" cy="1320" r="14" />
        </g>
        <circle
          cx="900"
          cy="500"
          r="160"
          fill="var(--ra-status-violet, currentColor)"
          opacity="0.18"
        />
      </svg>

      {/* Text layer */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          zIndex: 1,
          display: "grid",
          alignContent: "center",
          justifyItems: "start",
          padding:
            "var(--ra-space-7, 3rem) var(--ra-space-8, 4rem) var(--ra-space-7, 3rem) var(--ra-space-8, 4rem)",
          gap: "var(--ra-space-3, 0.75rem)",
        }}
      >
        <span
          style={{
            fontSize: "var(--ra-text-xs, 0.75rem)",
            letterSpacing: "0.22em",
            textTransform: "uppercase",
            fontFamily: "var(--ra-mono-display, ui-monospace, monospace)",
            color: "var(--ra-color-muted, inherit)",
            opacity: 0.85,
          }}
        >
          BEAUTIFUL CODEBASE · 3 : 4 · PLACEHOLDER
        </span>
        <h1
          style={{
            margin: 0,
            fontSize: "clamp(1.6rem, 4.6vw, var(--ra-text-4xl, 3rem))",
            lineHeight: 1.05,
            fontWeight: "var(--ra-font-weight-bold, 700)",
            color: "var(--ra-color-fg, inherit)",
            maxWidth: "75%",
          }}
        >
          按 reader profile + 主题，在此处设计封面
        </h1>
        <p
          style={{
            margin: 0,
            fontSize: "var(--ra-text-sm, 0.95rem)",
            color: "var(--ra-color-muted, inherit)",
            maxWidth: "75%",
            lineHeight: 1.4,
          }}
        >
          先读 <code>references/cover.md</code> 与选定主题的{" "}
          <code>theme-profiles/&lt;id&gt;.md</code>，再替换本占位。terminal 主题封面起手推荐
          "模块拓扑骨架"，可在此基础上替换节点为本项目的真实顶层模块。
        </p>
      </div>
    </>
  );
}
