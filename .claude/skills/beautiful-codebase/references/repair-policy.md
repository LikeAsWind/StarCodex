# Repair Policy · 最小切片修复

> **何时读**：Phase 5 终审输出 fail 项时；Section Reviewer 返回 fail 时；用户反馈"某一
> 处不对"时。
>
> **配套**：`references/review-checklist.md`（审查清单）·
> `scripts/audit/*.sh`（机械审计脚本）。

修复的核心原则只有一条：**最小切片**。一份代码分析报告有 7–15 节、每节包含 .tsx +
evidence.md + business.md + 可能的 raw-blocks + 可能的 SourcePointers JSON——任何一处
fail，都有"刚好够"的修复粒度。错过这个粒度往大处修 = 重做整篇 = 浪费 + 引入新问题；
错过这个粒度往小处修 = 抹一处症状 = 留下隐患。

---

## 1 · 最小切片原则

**铁律**：

- **一处反馈，一处修。** 用户反馈 Section 04 的某段不对，**只改** Section 04 那段。
  不动 Section 03 / 05；不动 plan.md；不动 Article.tsx 排序；不动主题。
- **能改 .tsx 就不改 evidence**，能改 evidence 就不改 plan，能改 plan 就不改 Outline
  决策（已经过 Checkpoint 1 用户确认）。**修复层级越高，破坏面越大、回归成本越高**。
- **不重写整篇**。即使发现的问题在多个 Section 都出现，也是各 Section 独立修，而不是
  "我重新写一遍整份报告"——后者代价是 N 倍 SubAgent 调用 + 一份完全新的内容（可能
  引入新问题）。

---

## 2 · 修复允许改什么

按破坏面从小到大列出。**优先用上面的手段**——能在小层级解决就不进大层级：

| 层级 | 可改文件 | 何时允许 |
|---|---|---|
| 1 · Section 内容 | `article/sections/<NN>-<slug>.tsx`（prose / mermaid / table / inline / CodeBlock —— 受 Q9b 密度上限约束） | 任何 fail 项：claim 漏引用、密度超限、序号写错、SourcePointers 数组缺漏、prose 风格欠佳。**绝大多数修复在这一层** |
| 1 · SourcePointers 数据 | `article/sections/<NN>-pointers.json`（若已 generated）或 .tsx 内 inline `pointers` 数组 | SourcePointers 不全 / role 标错 / 链接拼错 |
| 1 · 单节 Raw 块 | `article/raw-blocks/<NN>-*.tsx` | 单节内 Raw 跑偏（颜色野生、SVG 失真、Mermaid init 缺主题 token） |
| 2 · Section 证据（重跑 Step A） | `article/sections/<NN>-evidence.md` | **必要时**：Claim Trace 报 evidence drift（源文件已变）；Verbatim re-grep 不一致 |
| 2 · Section 业务（重跑 Step A.5） | `article/sections/<NN>-business.md` | **必要时**：业务陈述无引用且 evidence 里其实有相关 evidence 没被 Step A.5 吸收 |
| 3 · Article.tsx assembler | `article/Article.tsx` | 仅当 Section 排序变更（新增 / 移除 / 重排 Section）。**不改任何 Section 的具体内容** |
| 3 · plan.md | `plan/plan.md` | 仅当 Checkpoint 3 用户**显式同意**结构性改动（如临时新增 / 删除某 Section）；否则禁止 |
| 4 · 主题切换 | `article/main.tsx` 的 `<ThemeProvider theme>` + Colophon 主题名 | 仅当 Checkpoint 1 之后用户**显式同意**换主题（回到 Checkpoint 1 重做） |

---

## 3 · 修复禁止做什么

- **禁止**：用户只反馈一处问题就**重写整篇**。报告的内容架构由 plan.md + Checkpoint 锁
  定，单点反馈不触发结构重写。
- **禁止**：为了修视觉而改动**已确认的 Outline / Section 编号 / Section 列表**。视觉
  问题在 Section 内部或主题层修，不污染结构。
- **禁止**：为了压缩信息而删除 plan.md 标"必须保留"的内容。reader profile 标配的信息
  保留比例是承诺，不能为了节省字数随手砍。
- **禁止**：在某节"修复"中改动相邻节"补救"差距。"04 的 Risks 没写够"不能去 03 加
  Risks 段——4 的事就在 4 里修。
- **禁止**：手 patch `evidence.md` 的代码引用块（破坏反幻觉防线）。evidence drift 必须
  重跑 Step A SubAgent。
- **禁止**：为绕过 density audit 把 `<CodeBlock>` 改包成 `<Raw html=...>` 来逃避计数。
  这是规避不是修复。真不行就把 prose 写好让 CodeBlock 不必要。
- **禁止**：重跑全部 SubAgent。代价 N 倍、价值零（成功的 Section 没必要重做）。

---

## 4 · 修复对照表（fail 项 → 最小修复手段）

| 审计 fail 项 | 最小修复 | 是否重派 SubAgent | 回归 |
|---|---|---|---|
| Section Reviewer §1 Claim 没引用 | 主 Agent 改 .tsx prose：加 `[evidence]` 引用或重写 | 否 | 重跑 Section Reviewer |
| Section Reviewer §2 Verbatim re-grep 不一致 | 重跑 Step A Evidence SubAgent；其后 Step A.5 / Step B 也需重跑 | **是 · 重跑 Step A** | 重跑 Section Reviewer |
| Section Reviewer §3 业务陈述无引用 | (a) prose 改：加 `[证据]` 引用；(b) evidence 缺：重跑 Step A.5 | 视情况 | 重跑 Section Reviewer |
| Section Reviewer §4 密度超限 | 改 .tsx：删 CodeBlock / 缩短 / 改 `<Code inline>` / 改 prose | 否 | 重跑 density.sh + Section Reviewer |
| Section Reviewer §5 SourcePointers 缺 / role 错 | 改 .tsx `pointers` 数组（或重跑 `source-pointers-gen.sh`） | 否 | 重跑 Section Reviewer |
| Section Reviewer §6 序号不自洽 | 改 .tsx `<Section index>` / `<Subsection index>` 字符串 | 否 | 重跑 Section Reviewer |
| First Spread Reviewer 封面问题 | 改 `article/Cover.tsx` | 否 | 重跑 First Spread Reviewer |
| First Spread Reviewer 首屏 Hero 信息缺 | 改 `article/Article.tsx` 的 `<Hero>` / `<Lead>` | 否 | 重跑 First Spread Reviewer |
| Editorial Reviewer reader profile 偏离 | 内容层修：补 / 删 Section 段；可能涉及多节 | 否（除非 evidence 真的缺） | 重跑 Editorial + 涉及节的 Section Reviewer |
| Editorial Reviewer 业务-Job 缺 | 该节改 .tsx prose 或重跑 Step A.5 | 视情况 | 重跑该节 Section Reviewer + Editorial |
| Visual Reviewer 主题不忠实 | 改触发的 .tsx / Raw block：用 `--ra-*` token 替换野生颜色 | 否 | 重跑 Visual |
| Visual Reviewer Mermaid 节点过多 | 拆图：把一张 mermaid 拆成 2 张；可能需要重写 prose 衔接 | 否 | 重跑 Visual + 该节 Section Reviewer |
| Visual Reviewer 移动端溢出 | 改该 Section 的 layout：宽度 / table 滚动包装 | 否 | 重跑 Visual |
| Technical Reviewer 构建失败 | 修 TypeScript / 缺失 import / 死引用 | 否 | 重跑 `npm run build` |
| Technical Reviewer 序号全篇不自洽 | 主 Agent 通读全部 Section 校准；同步 `Article.tsx` 顺序 | 否 | 重跑 Technical |
| Technical Reviewer Coverage missing 非空 | 把 missing 文件加进 Section 11 Coverage Annex；重跑 `coverage.sh` | 否 | 重跑 Technical + coverage.sh |
| Technical Reviewer Freshness drifted | 不需修复——把 freshness-summary.md 嵌入 footer 即可 | 否 | 重跑 Technical |
| Technical Reviewer SourcePointers 链接错 | 改 `analysis-snapshot.json` 的 `remote.branch` / `remote.baseUrl` | 否 | 重跑 Technical |
| Coverage Audit missing | 同 Technical 行 | 否 | 重跑 coverage.sh |
| Claim Trace evidence drift | **重跑 Step A**（不能手 patch） | **是** | 重跑该节 Section Reviewer + claim-trace.sh |
| Density Audit 超限 | 改 .tsx | 否 | 重跑 density.sh |

---

## 5 · 修复后回归（最小回归原则）

**铁律**：修复后**只重跑触及到的范围的审计**——不要重跑整个 Phase 5。

| 修复涉及 | 必跑回归 |
|---|---|
| 单节 .tsx prose / pointers / 序号 | 该节 Section Reviewer + （若密度变化）`density.sh --section <NN>` |
| 单节 Step A 重跑 | 该节 Step A.5 + Step B 也要重跑（A 的输出变了，下游必须刷）→ 重跑该节 Section Reviewer |
| 单节 Step A.5 重跑 | 单节 Step B 也要重跑 → 重跑该节 Section Reviewer |
| Article.tsx 排序变更 | 整体 typecheck + Technical Reviewer 的 §4 序号 + §7 死引用两项 |
| 主题切换 | Visual Reviewer 完整重跑（不必跑 Editorial / Technical） |
| Coverage Annex 增项 | `coverage.sh` + Technical Reviewer §8 |
| Freshness drift | `freshness.sh` + Technical Reviewer §8（无需 Editorial / Visual） |

修复跑完所有需要的回归后再向用户汇报：**"做完了 + 自检结论 + 改了什么"**——不要在中途
"我先改了 .tsx，回归还没跑就报告 pass"。

---

## 6 · 何时写 `review/repair-log.md`

**仅当有实际修复发生才写**。一次过 / 无修复 = 不写文件。

格式（追加式 · 每次修复加一段）：

```markdown
## <YYYY-MM-DD HH:MM> · <反馈源：Section Reviewer / Final Editorial / 用户 / Coverage 脚本>

- **问题**：<一句话>
- **定位层**：<内容 / 视觉 / 构建 / 证据 / 结构>
- **最小修复单位**：<sections/04-module-walk.tsx · prose 第 3 段 / raw-blocks/07-heatmap.tsx 颜色 / Article.tsx import 顺序 ...>
- **改动**：<具体改了什么；如必要贴 git diff 行号或要点>
- **回归**：<跑了哪些脚本 / Reviewer；都 pass>
- **是否重派 SubAgent**：<否 / 是：Step A 重跑（理由）>
```

---

## 7 · 极端情况：发现根本问题需要回到 Checkpoint

有时审计会暴露"根上有问题"——比如 reader profile 选错、主题选错、Outline 漏掉了关键
模块。**这种时候不能在 Phase 5 内"硬修"**，必须：

1. 把发现暴露给用户（不要私下决定回退）；
2. 在消息里**显式问用户**："这个问题在 Plan 层。要么回到 Checkpoint 1 重做 plan，要
   么我们接受这份报告作为现状（不删现有 Section，只在 Coverage Annex 补充说明）。请你
   选。"——优先 `AskQuestion`，无工具则编号列出，**停下等答复**。
3. 用户选 "回到 Checkpoint 1" → 主 Agent 重写 plan.md，**重新走 Checkpoint 1**，之前
   已完成的 Section 视新 plan 决定是否复用（多数情况能复用 80%+）；
4. 用户选 "接受现状" → 主 Agent 在 footer / Coverage Annex 写明这个 limitation；不悄
   悄删 Section。

**禁止**：Agent 私自决定"我觉得重做更好"就回退 Checkpoint —— Checkpoint 是用户授权的
契约，Agent 不能单方面撕。
