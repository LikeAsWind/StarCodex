# Harness · `beautiful-codebase` 工作流视角

> **何时读**：Phase 0 Intake 开场。这是整套 Skill 的"为什么这么排"——读完它，
> 你能回答"我现在在哪一阶段、下一阶段在等什么、checkpoint 卡的是什么决策"。

## 1 · 六问 · 进入本 Skill 前的快速判断

在写第一行代码之前，先用这六问把"是否进 Skill / 怎么进"定下来：

1. **是不是一个代码项目？** 用户给的是 path / repo URL / monorepo 子包；不是 PDF /
   网页 / 文档。**否** → 这是 beautiful-article 的事。
2. **目标产物是不是单文件 HTML 报告？** 是 → 进。是 dashboard / 应用 / wiki → 出。
3. **分析深度该走哪个 reader profile？** 30 分钟架构判断 → `architecture-review`；
   第二天 ship issue → `onboarding`；半年后还要找回决策 → `archaeology`。**这一题
   不在 Intake 直接定**，留到 Checkpoint 1 让用户独立确认；但脑子里要有候选。
4. **目标项目是否已经被 `codegraph init` 过？** 看 `.codegraph/`。是 → 无声走
   codegraph 层；否 → Phase 0 给用户 3 选项（见 §3）。
5. **是否要求 100% 覆盖？** size tier `>10k` 时**强制拒绝** 100% 覆盖（honesty
   rule）；其它 tier 由 reader profile 决定。
6. **目标语言是中文 / 英文 / 双语？** 默认中文 prose + 英文标识符；用户在 Phase 0
   自由文本里说"全英文"就遵守。

任一答案不明 → 停下问用户。**绝不**带着模糊前提启动，因为 Phase 1 的 Discover 一旦
开跑就是几十秒到几分钟的真实文件 I/O，方向错了等于浪费用户的等待。

## 2 · 状态文件约定

`<project>-analysis/` 下的所有文件都是 Skill 的**长期记忆**——CheckPoint 之间、
SubAgent 之间、跨会话之间，全部走磁盘文件传递；**不要只把决策放在聊天上下文里**，
你可能在某次会话被截断，但磁盘上的 `plan/plan.md` / `sections/NN-evidence.md` 仍然
活着。

| 文件 | 所有者 | 谁写 | 谁读 |
|---|---|---|---|
| `discovery/tools.json` | 主 Agent (Phase 0) | `probe-tools.sh` | tier-select |
| `discovery/tier.json` | 主 Agent (Phase 0) | `tier-select.sh` | 全 Phase 1/4 SubAgents |
| `discovery/inventory.json` | Phase 1 | `inventory.sh` | Phase 2 / Phase 5 Coverage Audit |
| `discovery/size-tier.json` | Phase 1 | `buckets.sh` | Phase 2 Plan |
| `discovery/buckets/*.json` | Phase 1 | `buckets.sh` | Phase 4 每节 Step A SubAgent |
| `discovery/business-evidence/*` | Phase 1 | `business-evidence.sh` | Phase 4 每节 Step A.5 SubAgent |
| `discovery/codebase-brief.md` | Phase 1 | `codebase-brief.sh` | **主 Agent (Phase 2)** |
| `plan/plan.md` | 主 Agent (Phase 2) | 主 Agent | 全 Phase 3/4 SubAgents |
| `article/Cover.tsx` / `Article.tsx` | 主 Agent | scaffold + Phase 3 主 Agent | 构建系统 |
| `article/sections/NN-*.tsx` | Phase 4 Step B SubAgent (per section) | Writing SubAgent | 构建系统 |
| `article/sections/NN-evidence.md` | Phase 4 Step A SubAgent | Evidence SubAgent | Step A.5 + Step B + Section Reviewer |
| `article/sections/NN-business.md` | Phase 4 Step A.5 SubAgent | Business SubAgent | Step B + Section Reviewer |
| `review/first-spread-review.md` | Phase 3 Reviewer SubAgent | First Spread Reviewer | 主 Agent |
| `review/final-review.md` | Phase 5 三视角 SubAgent | Editorial / Visual / Technical | 主 Agent |
| `review/repair-log.md` | 主 Agent (仅有修复时) | 主 Agent | 用户 |
| `analysis-snapshot.json` | Phase 6 | 主 Agent | 用户 / 归档 |

**铁律**：

- 主 Agent **不读源码**。它只读 `inventory.json` + `codebase-brief.md` + `plan.md` +
  在审核环节读 `NN-evidence.md`。源码是 SubAgents 的工作。
- Step B Writing SubAgent **物理隔离 repo 访问**——只允许读 `NN-evidence.md` +
  `NN-business.md`。
- Section Reviewer **以消息返回 pass/fail + 修复点**，不写 review 文件（否则一篇 7-15
  节的报告会留下 7-15 份没人会读的 markdown）。

## 3 · 三个硬 Checkpoint 的位置与作用

| Checkpoint | 何时 | 决策项数 | 必须独立确认（不能打包）的事 |
|---|---|---|---|
| **#1 Plan** | Phase 2 → Phase 3 之间 | 5 | reader profile / 主题 / 版式宽度 / 配图模式 / 封面 |
| **#2 First Spread** | Phase 3 → Phase 4 之间 | 2 | 验收结论 / 开发模式 A 或 B |
| **#3 Final** | Phase 5 → Phase 6 之间 | 1 | 交付决策（HTML / HTML+PDF / 局部再修 / 暂停） |

**收集决策的方式**（与 beautiful-article 共享，但再次强调）：

- **优先 `AskQuestion` 工具**：每个决策项作为一个独立 question；用户用选择卡逐项确认。
- **无 `AskQuestion` 工具**：在消息里**编号列出**每个问题，每个独占一段，写清推荐项 +
  理由 + 备选项，明确说"我等你逐项答复后再继续"，**不要继续做任何后续工作**。
- **绝不**：把多项决策打包成一个"全部 OK 吗？" yes/no。AI 可以推荐，**不能跳过让用户
  选**。

特别地，**Phase 0 的 codegraph init 决策**也是一个隐式 Checkpoint —— 当 tier =
`codegraph-installed` 时必须给 3 选项（init / downgrade / stop），**绝不静默执行
`codegraph init`**。

## 4 · SubAgent 调度图

```
Phase 1 Discover
└─ (脚本，无 SubAgent)
   inventory.sh / buckets.sh / business-evidence.sh / codebase-brief.sh

Phase 3 First Spread (一个节)
├─ Step A   Evidence SubAgent      → sections/01-evidence.md
├─ Step A.5 Business SubAgent      → sections/01-business.md
├─ Step B   Writing SubAgent       → sections/01-verdict.tsx
└─ Reviewer First Spread Reviewer  → review/first-spread-review.md  ★写文件

Phase 4 每节
├─ Step A   Evidence SubAgent      → sections/NN-evidence.md
├─ Step A.5 Business SubAgent      → sections/NN-business.md
├─ Step B   Writing SubAgent       → sections/NN-<slug>.tsx
└─ Reviewer Section Reviewer       → 消息返回 pass/fail            ★不写文件

Phase 5 终审
├─ Editorial  Reviewer  → review/final-review.md (Editorial 段)
├─ Visual     Reviewer  → review/final-review.md (Visual 段)
├─ Technical  Reviewer  → review/final-review.md (Technical 段)
└─ 三脚本审计：scripts/audit/{coverage,freshness,density}.sh
```

**SubAgent 创建 prompt 模板见 `references/review-checklist.md` 和
`references/section-build.md`。** 创建 Writing SubAgent 时**禁止透传任何 repo 搜索 /
读取的工具**——这是反幻觉的物理防线。

## 5 · 工具 tier 切换的全局视角

| Tier | Discover 精度 | Section 05 入口扫描 | Section 03 架构图 |
|---|---|---|---|
| `codegraph-indexed` | 最高：语义级符号、callers/callees | 按 annotation 精准识别 | 真实模块依赖图 |
| `codegraph-installed` | **不直接用**——必须先在 Phase 0 给 3 选项 | — | — |
| `rg` | 文本正则；symbol 查询降级为文本匹配 | 按预设正则扫描 | 按目录层级近似 |
| `grep` | 关键字扫描；速度慢、精度低 | 关键字命中即认为是入口 | 同上 |

**重要心法**：tier 不是越高越好——它影响**精度**但不影响**报告形态**。低 tier 也能输
出可用的报告，只是某些 Section 会显式降级：

- Section 05 入口表里会出现"工具 tier=rg, 角色识别为关键字匹配；可能漏报"caveat。
- Section 03 架构图节点会按目录而非语义模块组织，并在标题注明"目录推断"。
- Section 07 复杂度数据可能退化为 LOC + 嵌套深度（见 `complexity-tools.md`）。

**绝不**：因为 tier 低就拒绝产出。用户的语境可能完全不需要 codegraph 精度（例如 Python
脚本集合 < 100 文件），rg 已经够用。

## 6 · 与 `beautiful-article` 的差异速查表

| 维度 | beautiful-article | beautiful-codebase |
|---|---|---|
| 源 | URL / PDF / DOCX / Markdown / 截图 | 一个真实代码 repo |
| Phase 1 名字 | Source → Markdown | **Discover** (probe / inventory / buckets / business-evidence / brief) |
| 写作阶段 | 两阶段（Evidence → Writing） | **三阶段**（Evidence → Business Distillation → Writing） |
| 反幻觉机制 | inventory + verbatim 引用 | inventory + verbatim 引用 + Writing SubAgent 物理隔离 repo + Coverage Audit + Freshness Audit + Code-Density Audit |
| 主导可视化 | Raw 自由层（SVG / canvas / React） | **Mermaid** 优先（架构 / 调用链 / 业务实体），SVG 仅留给 cover + Section 07 热图 |
| 主题 | tufte / press / shannon / vignelli / knuth / ... | **terminal**（新增 · code-native）/ tufte / press |
| reader profile | 文章类型（longform / briefing / essay / ...）含信息比例 | **三种**：architecture-review / onboarding / archaeology |
| Section 命名 | 编辑性叙事章节 | 固定 13 节框架（按 profile 选必选/可选） |
| 业务陈述 | 不区分 | **必须** `[证据: file:line]` 引用，否则归"业务背景未知"段 |
| Tools | source-to-markdown.py 等 | probe-tools.sh + lib/query.sh + scripts/discover/*.sh + scripts/audit/*.sh |
| 失败重跑 | 全文重写 | **单节单点重跑**（每节 evidence/business/writing 独立落盘） |

更细的对照见 SKILL.md 顶部"工作流总览"段；这里只列差异速查。
