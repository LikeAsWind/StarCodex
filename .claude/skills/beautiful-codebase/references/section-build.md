# Section Build · 每节三阶段写法

> **何时读**：Phase 3 写首屏第一节时；Phase 4 每节循环时；Phase 5 复盘任意单节时。
>
> **配套文件**：`references/component-policy.md`（组件协议）·
> `references/raw-policy.md`（Raw 自由层规则）· `references/source-pointers.md`（节脚
> file:line 折叠面板）· `references/business-evidence-collection.md`（Step A.5 燃料）·
> `references/information-density.md`（reader profile 标配带宽）·
> `references/review-checklist.md`（Section Reviewer 完整清单）。
>
> **SubAgent prompt 模板**（本文件 §3 / §4 / §5 / §8 引用，作者抄出来发给 SubAgent）：
> - `prompts/step-a-evidence.md`
> - `prompts/step-a5-business.md`
> - `prompts/step-b-writing.md`
> - `prompts/section-reviewer.md`

本文件定义 `beautiful-codebase` 最核心的产线：**怎样把一个 bucket 变成一节 Section**。
它由"一节一文件铁律 + 三阶段写流程 + 两种开发模式 + Section Reviewer 消息返回"四部分
组成。**Phase 4 每开一节都要回看本文件**——下表四个 prompt 是抄给 SubAgent 的、不是
用来"理解后随手发挥"的。

---

## 1 · 一节一文件铁律

### 1.1 文件位置

每个 Section **必须**是独立组件文件，**坚决不允许**把多个 Section 写进同一个组件：

```text
<project>-analysis/article/
  Article.tsx                      # assembler（主 Agent 拥有）：import + 排序 + Section 编号校准
  Cover.tsx                        # 封面（Phase 3 主 Agent 写；scaffold 留壳）
  sections/
    01-verdict.tsx                 # export function SectionVerdict() { return <Section index="01" ...>...</Section> }
    01-evidence.md                 # Step A 输出（Evidence SubAgent 写）
    01-business.md                 # Step A.5 输出（Business Distillation SubAgent 写）
    02-glance.tsx                  # 第二节 .tsx
    02-evidence.md                 # 第二节 evidence
    02-business.md                 # 第二节 business
    ...
  raw-blocks/
    07-complexity-heatmap.tsx      # > 30 行的 Raw SVG / 复杂可视化抽出来，被对应 section import
```

**核心约定**：

- **`sections/NN-<slug>.tsx`** 是 Step B Writing SubAgent 的唯一交付物，导出一个 React
  组件，内部以 `<Section index="NN" title="...">…</Section>` 为根。`<slug>` 取 plan.md
  Outline 段写下的 kebab-case 短名（如 `verdict` / `architecture-map` /
  `module-walk-payments`）。
- **`sections/NN-evidence.md`** 与 **`sections/NN-business.md`** 与 tsx 同目录平级，
  分别是 Step A / Step A.5 的输出。**这两份 markdown 是该节的私有记忆**：放在 `sections/`
  下而不是 `discovery/` 下，是为了让"删一节 = 删一组同名文件"成立，便于失败重跑 +
  多 Agent 并行无碰撞。
- **`raw-blocks/NN-*.tsx`**：单节内 Raw 自由层 > 30 行的，抽到这里；由对应 section 文件
  `import` 后渲染。详见 `references/raw-policy.md` §4。

### 1.2 Section 文件是并行的单位

Phase 4 开发模式 B（多 Agent 并行）的物理前提就是"一节一文件"——subagent 各拥**一个**
section 文件，无论它在评估什么、写什么风格，都不会和别人的 section 文件冲突。这是文件
级别的隔离，不是靠"约定不要踩"的隔离。

### 1.3 Article.tsx 是 assembler，主 Agent 拥有

`Article.tsx` **只做组装**：

```tsx
import { Article, Hero, Lead } from "reacticle";
import { SectionVerdict } from "./sections/01-verdict";
import { SectionGlance } from "./sections/02-glance";
import { SectionDomain } from "./sections/02b-business-domain";
import { SectionArchitecture } from "./sections/03-architecture-map";
import { SectionModuleWalk } from "./sections/04-module-walk";
// ... 其它 Section import
import { Colophon } from "./sections/12-colophon";

export function ArticleDoc() {
  return (
    <Article toc width="regular">
      <Hero title="..." subtitle="..." meta={[...]} />
      <Lead>...</Lead>
      <SectionVerdict />
      <SectionGlance />
      <SectionDomain />
      <SectionArchitecture />
      <SectionModuleWalk />
      {/* ... */}
      <Colophon />
    </Article>
  );
}
```

`Article.tsx` 严禁出现"任何一节的具体内容"——只允许 `import` + 排序。所有 prose / 组件
都活在 `sections/NN-*.tsx` 里。

### 1.4 Section 序号校准

`<Section index="NN">` 的 `NN` 是**手写字符串**，组件不自动编号。规则：

- **全局序号归主 Agent (assembler) 所有**。Plan Outline 定下顺序后，主 Agent 在
  `Article.tsx` 排定 import 顺序、并据此把每个 Section 的 `index` 校准成
  `01 / 02 / 02b / 03 / ...`，以及每个 `<Subsection>` 的序号前缀对齐到所属 Section
  （第 04 节下只能是 `4.1 / 4.2 ...`）。
- **subagent 不自编全局序号**。Step B Writing SubAgent 的 prompt 里**主 Agent 直接告诉它
  "你是第 `<NN>` 章"**，subagent 用这个 `<NN>` 写 `Section index` 与本节 `<Subsection>`
  前缀；拿不准就留 plan 给的占位，最终由主 Agent 统一过一遍。
- **组装后必校验**：对照 TOC 显示与 plan.md Outline 顺序，确认序号连续单调、子节前缀
  正确。Technical Reviewer 的"章节序号全篇自洽"清单会复核一次。

---

## 2 · 三阶段写流程（核心）

```
   bucket + reader profile + Outline-row
                 │
                 ▼
  ┌─────────────────────────────────────┐
  │ Step A · Evidence SubAgent          │  读 repo（codegraph / rg / grep via lib/query.sh）
  │ 输出：sections/NN-evidence.md       │  verbatim 代码 + 工具查询结果，每段标 file:line
  └─────────────────────────────────────┘
                 │
                 ├──> discovery/business-evidence/  ← Phase 1 已写好的 6 类业务证据
                 │
                 ▼
  ┌─────────────────────────────────────┐
  │ Step A.5 · Business Distillation    │  读 evidence.md + business-evidence/（不读 repo）
  │ 输出：sections/NN-business.md       │  每条业务陈述带 [证据: file:line] + 显式"未知"段
  └─────────────────────────────────────┘
                 │
                 ▼
  ┌─────────────────────────────────────┐
  │ Step B · Writing SubAgent           │  **物理隔离 repo**：只允许读两份 md
  │ 输出：sections/NN-<slug>.tsx        │  prose 主体 + mermaid + inline + 严格 CodeBlock 上限
  └─────────────────────────────────────┘
                 │
                 ▼
  ┌─────────────────────────────────────┐
  │ Section Reviewer SubAgent           │  消息返回 pass/fail + 修复点，不写文件
  └─────────────────────────────────────┘
                 │
                 ▼
         主 Agent 直接修 → 汇报本节交付
```

**反幻觉绑定**：Step B 看不到源码，**只能根据 evidence.md / business.md 写**。它要引用
任何 file:line，必须能在两份 md 里找到；找不到就 STOP 并向主 Agent 报"我需要补充的证据
是 X"——主 Agent 决定是补一轮 Step A 还是改 Outline 把这个 claim 删掉。

### 2.1 三阶段的产出文件契约

| 阶段 | 输出 | 行数预算 | 谁可读 |
|---|---|---|---|
| Step A | `NN-evidence.md` | ≤ 300 行 | Step A.5 · Step B · Section Reviewer · Phase 5 Coverage Audit |
| Step A.5 | `NN-business.md` | ≤ 150 行 | Step B · Section Reviewer · Final Editorial Reviewer |
| Step B | `NN-<slug>.tsx` | 弹性（一节正文） | `Article.tsx` · 构建系统 · 读者 |

**行数硬上限**是设计稳态：超出 = 信号，主 Agent 必须重切桶 / 重写 Outline，**不要**
默默放过。详见 §6 失败重跑。

---

## 3 · Step A · Evidence Collection SubAgent

**完整 prompt 模板** → `prompts/step-a-evidence.md`。主 Agent 派活时把整段
prompt **原样**发给 SubAgent，替换 `<NN>` / `<slug>` / `<bucket-file>` 等占位。
**不要"理解后改写"**——prompt 是反幻觉合约的一部分。

**契约速查**：

- 输入：bucket JSON + tier 标签 + 本节 Outline 行 + reader profile。
- 工具：必须走 `scripts/lib/query.sh` 提供的 `bc_query_files` / `bc_query_symbols` /
  `bc_query_text` 封装，**禁止**直接调 `codegraph` / `rg` / `grep`。
- 输出：`<NN>-evidence.md`，按"Files in scope / Symbol queries / Verbatim source
  excerpts / Cross-references / Comments worth surfacing"5 段结构写；每段 verbatim
  代码标 `file:line-line`；工具 JSON 输出原样保留。
- 行数：**≤ 300 行**。超 = `BUCKET_TOO_LARGE` 信号，主 Agent 重切桶（见 §6）。
- **不写 prose**——任何"这段代码是…/我认为…"立即失败。解释是 Step B 的工作。

### 3.1 行数预算 = 重切桶信号

如果 Step A 真的 `BUCKET_TOO_LARGE`，主 Agent 的处理：

1. 看 `discovery/buckets/<bucket-file>.json` 的 `files` 字段，按目录 / 模块边界一分为二。
2. 在 `plan/plan.md` Outline 段把本节拆成两节（如 `04-module-walk-payments-core` +
   `04-module-walk-payments-fulfillment`），刷新 Section 编号；
3. 重新派两轮 Step A。
4. **不要**让 SubAgent "压缩" evidence。压缩 = 信息丢失 = 反幻觉防线失效。

---

## 4 · Step A.5 · Business Distillation SubAgent

**完整 prompt 模板** → `prompts/step-a5-business.md`。这一步是 `beautiful-codebase`
相对 `beautiful-article` 独有的：把"代码事实"翻译成"业务事实"，但**只翻译能引用的
部分**，不能引用的全部进"业务背景未知/不充分"段。

**契约速查**：

- 输入：`<NN>-evidence.md` + `discovery/business-evidence/`（6 类证据：comments /
  tests / schema / configs / docs / commit-themes）+ 本节 Outline 行业务-Job 字段。
- **禁止读 repo 源码**——SubAgent 工具里没有 Read 任意路径 / Glob / Grep；只允许读
  `discovery/` 与本节 evidence.md。
- 输出：`<NN>-business.md`，4 段固定结构：
  - §1 业务背景
  - §2 关键业务规则（每条带 `[证据: file:line]`）
  - §3 涉及的业务实体（表格）
  - §4 业务背景未知/不充分
- 行数：**≤ 150 行**。
- **confident-tone 无引用 = 失败**——任何"本节实现了 X 业务"必须紧跟 `[证据: ...]`。
- 没有任何业务证据可循 → 回报 `BUSINESS_EVIDENCE_EMPTY`，主 Agent 走 §4.1 路径。

### 4.1 业务证据为空的处理

`BUSINESS_EVIDENCE_EMPTY` 不是失败——是诚实。某些项目就是纯技术工程（CLI 工具 /
codegen / build tool）。主 Agent 收到这条信号后：

- 在 `plan/plan.md` Outline 段把本节"业务-Job"字段改为"本节业务未知，仅做技术解释"
  （或如果是 Section 02b 整节，按 PRD AC9 标 "本项目无业务实体, 跳过"）。
- Step B prompt 里加入硬指令："本节业务证据为空，**禁止**在 prose 里写任何业务断语；
  prose 只能描述技术结构。"

---

## 5 · Step B · Writing SubAgent

**完整 prompt 模板** → `prompts/step-b-writing.md`。这是反幻觉最后一道物理防线。
**主 Agent 派活时禁止透传任何文件搜索 / repo 读取工具**——Step B SubAgent 只能读两份
指定 markdown，**没有** `Read` 任意路径 / `Glob` / `Grep` 源码的权限。

**契约速查**：

- 输入：`<NN>-evidence.md` + `<NN>-business.md` + plan.md 本节段 + 选定主题 md +
  本文件 §3 / §4 / §5 引用的 3 份 reference（component-policy / raw-policy /
  source-pointers）。
- **禁止读 repo 源码 / 不在 evidence 里的 file:line**——发现想引用的 file:line 不在
  evidence.md → 回报 `EVIDENCE_GAP`，**不要凭印象写**。
- 输出：`sections/<NN>-<slug>.tsx`，单文件 React 组件，根是
  `<Section index="<NN>" title="...">`，节脚必须 `<SourcePointers>`。
- Q9b 代码密度上限（**硬约束**）：
  - `<CodeBlock>` ≤ 1 块/节（Section 04 / 05 例外 ≤ 2）；每块 ≤ 8 行。
  - 替换优先级 `prose → mermaid → table → <Code inline> → <CodeBlock>`，**始终选
    左边的**。
  - `<Code inline>` 不计上限，鼓励大量使用。
  - `<Mermaid>` 不计入 CodeBlock 上限。
- 主题 token：颜色 / 字体 / 间距走 `--ra-*`，**禁**裸 inline style 含 hex。

### 5.1 Step B 不能读 repo 是合约不是建议

主 Agent 在派 Step B 时**禁止把任何源码 Read / Glob / Grep 工具透传给 SubAgent**。
在 Claude Code 环境里，这意味着：

- Step B SubAgent 的 prompt 之外，只允许它读 `<project>-analysis/article/sections/<NN>-evidence.md`
  和 `<project>-analysis/article/sections/<NN>-business.md` 两个绝对路径。
- 如果环境无法做 per-subagent 工具过滤（比如某些 host 一律放开 Read），那么 prompt
  里"不读 repo"就**只是合约**——这时主 Agent 必须在 Section Reviewer 阶段抽查 5 个
  prose 引用的 file:line 是否真的来自 evidence.md / business.md，发现来自其他文件就
  整节重写。

物理隔离 > 合约隔离；能物理就物理。

---

## 6 · 失败与重跑

| 失败信号 | 来源 | 主 Agent 处理 |
|---|---|---|
| `BUCKET_TOO_LARGE` | Step A | 重切桶（按目录 / 模块边界），刷新 plan.md Outline 序号，重派 Step A |
| Step A 自检不通过（如发明 file:line） | 主 Agent 抽查 evidence.md | 重派同一个 SubAgent，并把"自检 fail 项"作为新 prompt 末尾段强调 |
| `BUSINESS_EVIDENCE_EMPTY` | Step A.5 | 不是失败；改 plan.md 该节"业务-Job"为"业务未知"；Step B prompt 加"禁止业务断语"硬指令 |
| Step A.5 自检不通过（confident 无引用） | 主 Agent 抽查 business.md | 重派同一个 SubAgent，附 fail 项 |
| `EVIDENCE_GAP` | Step B | 选 a/b：a) 重派 Step A 补充该 file:line 周围的 verbatim → 重派 Step B；b) 调整 Outline 把该 claim 删除 → 重派 Step B |
| Step B 密度审计 fail（Section Reviewer 报）| Section Reviewer | 最多重派 1 次 Step B（prompt 末尾加"上一次 fail 原因 + 必须降到 ≤ X 块/≤ Y 行"）；二次仍 fail → 主 Agent 在 plan.md 该节加 `flag: density-relaxed` 备注后放行，留到 Phase 5 终审 |
| Step B `<Section index>` 与 `<NN>` 不一致 | 主 Agent assembler 校准 | 直接改文件里那一行，**不**重派 SubAgent |

**单节失败不影响其它节**——每节产出独立落盘，重跑只针对失败那一节。这是"一节一文件"
铁律的回报。

---

## 7 · 两种开发模式（Checkpoint 2 选定）

### 7.1 Dev mode A · 单 Agent 顺序（默认 · 最稳 · 风格最统一）

主 Agent 顺序对 02 / 02b / 03 / 04 / ... 每节循环：

```
for each section in plan.outline:
   主 Agent 派 Step A SubAgent  → wait for NN-evidence.md
   主 Agent 派 Step A.5 SubAgent → wait for NN-business.md
   主 Agent 派 Step B SubAgent   → wait for NN-<slug>.tsx
   主 Agent 派 Section Reviewer  → wait for pass/fail 消息
   if fail：按 §6 重派失败那一步
   主 Agent 更新 Article.tsx 的 import + 序号
```

适用：风格统一性比速度重要；首次跑 / Checkpoint 2 没明确选 B 时的默认。

### 7.2 Dev mode B · 多 Agent 并行（最快 · 风格轻微差异）

并行调度规则：

- **Step A 可以全部并行**：所有未做的 section 同时派 Step A SubAgent；它们彼此读不同的
  桶，互不影响。
- **Step A.5 可以全部并行**：等同一节 Step A 完成即可派该节 Step A.5；A.5 之间无依赖
  （每个只读自己的 evidence.md + 共享的 business-evidence/）。
- **Step B 跨节并行，节内串行**：每节 Step B 必须等本节 A + A.5 完成；不同节的 Step B
  可同时跑，因为每个 Step B 只写一个独立 .tsx 文件。
- **Section Reviewer 跨节并行**：每节完成 Step B 即可派 Reviewer；它只读本节三件产出。

并行上限建议：**每轮 N ≤ 5**——再多容易触发上下文 / API rate 抖动。N 由主 Agent 按
环境调整。

主 Agent 在并行模式下**承担合并 + 稳定性**：

- 维护 `Article.tsx` 的 import + Section 顺序（唯一组装点，避免文件冲突）。
- 主 Agent 不应在并行轮内修改 `Article.tsx`；改在每一轮"并行交付"完成后一次性合并。
- 每轮并行后跑 `npm run typecheck` + `npm run build`，修构建错误。
- 兜底主题与风格：颜色 / 字体 / 间距走 token，气质不跑偏（通过对所有交付 .tsx 抽样
  审一眼，必要时把某节"风格异类"的 SubAgent 重派一次）。
- 解决相邻 Section 的衔接：如果 04 末段和 05 开头出现重复论点，主 Agent 决定哪段砍。

### 7.3 并行 Step B SubAgent 的 prompt 增量

`prompts/step-b-writing.md` 末尾已带"多 Agent 并行模式下的额外硬指令"段——主 Agent 在
Dev mode B 派活时把这一段一并发出，强调"只改这一个文件，不要触碰 Article.tsx 或别的
section 文件"。

### 7.4 Dev mode 切换

Checkpoint 2 已选 A 后想换 B（或反之）：主 Agent 在新一节开工前提示用户"目前 A
模式，要切到 B 吗？"——**不要静默切换**。已交付的节不重做；切换只影响后续节。

---

## 8 · Section Reviewer SubAgent（消息返回 · 不写文件）

**完整 prompt 模板** → `prompts/section-reviewer.md`。每节 Step B 完成后立即派
Reviewer。**消息返回 pass/fail + 修复点**——**不写** `review/section-NN-review.md`
文件。一份报告 7-15 节，留 N 份 review 文件无人会读。完整 checklist 见
`references/review-checklist.md` §3。

**审计项速查**（详细 prompt 见 `prompts/section-reviewer.md`）：

1. Claim Audit · 抽 5 条技术断言回溯到 evidence.md。
2. Verbatim re-grep · 抽 evidence.md 3 个代码块在 repo 里再 grep 确认一致。
3. 业务引用核查 · 抽 3 条业务陈述回溯到 business.md。
4. 代码密度审计 · 数 `<CodeBlock>` 数量 + 每块行数 + code-char 占比，对照 Q9b 上限。
5. Source Pointers 完整性 · 节脚 `<SourcePointers>` 非空且 file:line 都能在
   evidence/business.md 找到。
6. 序号自洽 · `<Section index>` 与派活 `<NN>` 一致；`<Subsection>` 前缀对齐。
7. 与前后节衔接（best-effort）。

### 8.1 Reviewer 不写文件的原因

一份报告可能有 7-15 节，留 7-15 个 `review/section-NN-review.md` 文件**没人会读**——
连主 Agent 自己都不会再回头看。所以 Section Reviewer 的契约就是"消息往返 + 一次性修复"。
留档的是 **`review/first-spread-review.md`** 与 **`review/final-review.md`**（Phase 3 /
Phase 5 的两道独立眼睛），它们写文件，因为内容真的会被回看。

---

## 9 · 与 Phase 5 / 终审的关系

Phase 4 Section Reviewer 只看**本节自洽 + 反幻觉**，**不看**：

- 全文 Coverage（每个 inventory 文件是否都被某节 evidence.md / Coverage Annex 收纳）—— 走
  `scripts/audit/coverage.sh`（Phase F）。
- 全文 Freshness（自 Phase 1 以来 repo 是否变了）—— 走 `scripts/audit/freshness.sh`
  （Phase F）。
- 全文风格一致 / 编辑性 / 视觉气质统一 —— 走 Phase 5 三视角 SubAgent。

也就是说：**节级审过 ≠ 报告可交付**。Phase 4 走完 = 所有节都过了局部体检；Phase 5
是体检之外的"整体观感 + 全文审计"。两层都得过才能进 Checkpoint 3。

---

## 10 · 一键速查表

| 我在做什么 | 看哪份文件 |
|---|---|
| 派 Step A SubAgent | `prompts/step-a-evidence.md`（本文件 §3 给契约速查） |
| 派 Step A.5 SubAgent | `prompts/step-a5-business.md`（本文件 §4 给契约速查） |
| 派 Step B SubAgent | `prompts/step-b-writing.md`（本文件 §5 给契约速查 + "no repo access" 物理隔离规则） |
| 派 Section Reviewer | `prompts/section-reviewer.md`（本文件 §8 给审计项速查） |
| 选开发模式 | 本文件 §7（Checkpoint 2 已选定后写进 plan.md Brief） |
| 重派失败节 | 本文件 §6 失败与重跑表 |
| 校准 Section 序号 | 本文件 §1.4 |
| 写节脚 Source Pointers | `references/source-pointers.md` |
| 选用什么组件 / 守 Q9b | `references/component-policy.md` |
| Raw 自由层 | `references/raw-policy.md` |

整套 Phase 4 / Phase 3 第一节的"怎么写"都在上面 + 这三份配套 reference + `prompts/`
四份模板里。**不要**凭"我对这套规则的印象"派 SubAgent——把 prompt 模板原样发出去，
是这套 Skill 反幻觉合约的物理实现。
