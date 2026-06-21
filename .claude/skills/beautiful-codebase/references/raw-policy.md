# Raw Policy · Raw 自由层规则（代码分析特化）

> **何时读**：Phase 4 写每节时，当你想脱离 reacticle 组件协议、用裸 HTML / SVG /
> 自定义 React 实现某段视觉时；Section 07 SVG 复杂度热图 / 封面 / 极少数 Mermaid
> 表达不了的图。
>
> **配套文件**：`references/component-policy.md`（先确认想做的事不能用组件做） ·
> `theme-profiles/<id>.md`（拿 `--ra-*` token） · `references/section-build.md` §1.1
> （`raw-blocks/` 文件位置）。

Reacticle 的 `<Raw>` 自由层在 `beautiful-article` 里被广泛使用——文章是创作媒介，自由
层是表现力的核心。**`beautiful-codebase` 把它收紧**：报告是关于真实代码的事实陈述，
自由层是**保留逃生口**，不是常规组件。所以本文件本质上是"什么时候**不允许**用 Raw"
的清单。

## 1 · Raw 何时允许

只在以下场景允许：

1. **Section 07 Code Health Heatmap · SVG 复杂度热图** —— Mermaid 表达不了；颜色映射
   到 `--ra-status-*` token，矩形格子大小映射到 LOC / 复杂度。
2. **Cover · 封面题图** —— SVG 题图或 SVG + HTML 排版的书封式封面（详见
   `references/cover.md` 已说明的硬约束）。
3. **极少数 Mermaid 表达不了的可视化** —— 例如真实数据折线对比、需要精确像素布局的
   时序对比图。**举证责任在作者**：你要说清"为什么 Mermaid 不行"。
4. **微小排版增强** —— 一个并排对比小框、一段需要 hover 揭示的细节折叠面板（如果
   `<Callout>` / `<Detail>` 已经能做就不要 Raw）。

## 2 · Raw 何时禁止

下面这些一律 fail，Section Reviewer 抽查时会直接拒掉：

| 禁止做的事 | 为什么 |
|---|---|
| 终端命令打字机效果 | 报告不是 demo；装饰 |
| 代码雨 / matrix 字符流 | 同上 |
| 粒子背景 / 霓虹发光 / CRT 滤镜 | 同上；违反 terminal 主题"克制"原则 |
| 滚动揭示 / 自动播放动画 | 报告应可静态打印；动画干扰阅读 |
| 用 Raw 复刻 `<Mermaid>` / `<SourcePointers>` / `<CodeBlock>` | 已经有组件了 |
| Section 05 入口流程图用 Raw SVG 画 | **必须** Mermaid；统一渲染管线 + 主题 token |
| 复杂表单 / dashboard / 完整产品原型 | 报告不是应用 |
| 引入 React state / useEffect 做"实时" / "可调" 模型 | 报告是 snapshot；不要做交互 |
| 外部 `<img src="https://...">` | 单文件 HTML 不能联网；asset-policy 默认 `none` |
| 外部 `<script src="https://cdn...">` | 单文件 HTML 不能依赖 CDN |
| 行内 `style={{color: "#abc"}}` / `style="background: rgb(...)"` | 违反 token 驱动 |
| 在 Raw 里 `<style>` 重定义 `--ra-*` token | 破坏主题切换 |

## 3 · Raw 必须用主题 token

无例外：所有颜色 / 字体 / 间距 / 圆角必须取自主题变量（`var(--ra-terminal-bg)` /
`var(--ra-status-red)` / `var(--ra-mono-text)` / `var(--ra-space-4)` ...），从
`theme-profiles/<id>.md` §2 Token 表抄。Raw 里写颜色的 only 允许格式：

```tsx
<rect fill="var(--ra-status-red)" />
<div style={{ color: "var(--ra-terminal-fg)", padding: "var(--ra-space-3)" }}>...</div>
```

**唯一例外**：SVG 的 `viewBox` / `width` / `height` / `x` / `y` / `cx` / `cy` 等几何
属性允许用 number / px / rem 字面量——它们是几何参数不是设计 token。

## 4 · 大块 Raw 隔离到 `raw-blocks/`

> 30 行的 Raw 必须抽到 `<project>-analysis/article/raw-blocks/NN-<slug>.tsx`，由对应
section 文件 import：

```tsx
// article/raw-blocks/07-complexity-heatmap.tsx
export function ComplexityHeatmap({ data }: { data: HeatmapCell[] }) {
  return (
    <svg viewBox="0 0 800 400" width="100%" role="img" aria-label="复杂度热图">
      {data.map((cell) => (
        <rect
          key={cell.id}
          x={cell.x} y={cell.y} width={cell.w} height={cell.h}
          fill={`var(--ra-status-${cell.severity})`}
        />
      ))}
    </svg>
  );
}

// article/sections/07-code-health.tsx
import { Section } from "reacticle";
import { ComplexityHeatmap } from "../raw-blocks/07-complexity-heatmap";

export function SectionCodeHealth() {
  const data = /* 从 discovery/complexity.jsonl 解析 */;
  return (
    <Section index="07" title="Code Health Heatmap">
      <p>...</p>
      <ComplexityHeatmap data={data} />
      <p>...</p>
    </Section>
  );
}
```

**好处**：

- Section 文件保持可读（不被 200 行 SVG 撑爆）。
- 多 Agent 并行下不会因为巨型 Raw 块阻塞重读。
- 单独修复 / 单独 review Raw 块更容易。

## 5 · Raw 与 Mermaid 的关系

**Mermaid 优先 · Raw 兜底**。

| 想画的图 | 用什么 |
|---|---|
| 业务实体关系 | `<Mermaid>` `graph LR` |
| 模块依赖 | `<Mermaid>` `graph` |
| 入口流程 / 调用链 | `<Mermaid>` `flowchart TD`（Section 05 必须） |
| 时序图 | `<Mermaid>` `sequenceDiagram` |
| 简单状态机 | `<Mermaid>` `stateDiagram-v2` |
| 复杂度 / 热度二维网格 | Raw SVG（mermaid 不支持密集格子） |
| 真实数据折线对比 | Raw SVG（mermaid 支持有限） |
| 封面题图 | Raw SVG / Raw HTML |

只在右栏的 3 类场景考虑 Raw；其它都先试 Mermaid。

## 6 · Raw 5 条自检（写完每个 Raw 块都跑一遍）

- [ ] **删掉它，报告理解会变差吗？** 不会 → 砍掉（你是在做装饰）。
- [ ] **只用 `--ra-*` token 了吗？** 翻一遍源码搜 `#` 和 `rgb(`，不应找到（SVG 几何属性除外）。
- [ ] **没有它，prose 段落本身能不能读？** 不能 → 你做的是装饰柱，砍掉。
- [ ] **移动端能读吗？** 浏览器开 mobile viewport 看，Raw 块不应破坏栏宽。
- [ ] **打印能读吗？** 黑白打印（terminal 主题暗底！）状态下颜色对比是否仍可辨？详见
  `references/pdf-output.md`"暗底打印 caveat"段。

任何一条答否 → 改完或砍掉。**不要带着已知问题交付**——Section Reviewer 会发现。

## 7 · 一个反例

```tsx
// ❌ 这是 raw-policy 禁止的
<Raw>
  <div style={{
    background: "#0E1116",                    // ❌ 硬编码颜色
    color: "#00FF00",                          // ❌ 终端绿装饰；非语义色
    fontFamily: "Courier New, monospace",     // ❌ 不用 token
    animation: "typing 2s steps(40) infinite" // ❌ 打字机动画装饰
  }}>
    {`> Analyzing codebase...`}
  </div>
</Raw>
```

正确做法：直接 `<Callout tone="info">本节由分析 SubAgent 自动生成</Callout>` —— 一行
组件解决，无 Raw。

## 8 · 一个正例

```tsx
// ✅ 合理：Section 07 复杂度热图必须 Raw，Mermaid 表达不了密集网格
export function ComplexityHeatmap({ cells }: { cells: Cell[] }) {
  return (
    <svg viewBox="0 0 800 400" width="100%" role="img"
         aria-label="按文件聚合的圈复杂度热图">
      {cells.map((c) => (
        <rect key={c.path}
              x={c.x} y={c.y} width={c.w} height={c.h}
              fill={`var(--ra-status-${c.tier})`}>
          <title>{c.path} · CC={c.cc}</title>
        </rect>
      ))}
    </svg>
  );
}
```

颜色 token、几何参数 number、`<title>` 元素做 hover tooltip + 可访问性、无装饰动画。
通过。
