# Reader Profile · `architecture-review`（30 分钟做架构判断）

> **何时读**：Checkpoint 1 用户选 `architecture-review` 后；写 `plan/plan.md` 时；
> Phase 4 每节回看自己的 Business-Job 与必选 Section 时；以及 size tier `>10k`
> 自动给出降级建议时。
>
> **配套文件**：`references/plan-template.md`（落盘模板）、`references/theme-selection.md`
> （主题搭配矩阵）、`references/information-density.md`（保留比例 / 视觉密度）、
> `theme-profiles/terminal.md`（默认主题）。

## 1 · Profile intent · 这份报告给谁读、读完做什么决定

`architecture-review` 服务的是 **senior engineer / 架构师 / tech lead** ——他们手上同时
有 3-5 个项目要评，**每个项目愿意花的时间上限就是 30 分钟**。读这份报告的目的是做出
一个三选一的判断：

- **接管**：值得继续投入、当前结构能撑住下一个季度的需求增长；可以放心让团队接手维护。
- **重构**：核心思路对，但有 1-3 个结构性问题（边界混乱 / 风险点集中 / 测试缺位），
  需要先安排一波重构再继续投入。
- **PoC 价值 / 弃用**：不值得继续投入，可考虑替换、归档、或仅保留作为概念验证学习样本。

任何让读者读了 30 分钟还不能在这三个选项里选一个的报告，对这个 profile 都是失败的。
Verdict（01）+ Risks（08）+ Decisions（09）这三节承担"判断锚点"的角色；其余 Section
都是为这三节提供支撑证据的"展开材料"。

`architecture-review` profile 的隐含承诺是：**读者不需要自己再去翻代码**。所有判断依据
都已经在报告里、并能溯源到 `file:line`。

## 2 · 默认 Section 列表（13 节 · 7 必 + 6 选）

下面这张表是 Plan SubAgent 写 Outline 时的起点。每行带 **必/选** 标签、**期望长度
（按渲染后正文行计，不含 Mermaid 代码）**、**必选视觉块**、**一句话职责**。

| #   | Section                          | 必/选 | 行数估算 | 必选视觉块                       | 一句话职责 |
|-----|----------------------------------|-------|----------|----------------------------------|------------|
| 00  | Cover                            | 必    | (封面)   | 主视觉 + 项目身份                | 视觉钩子；眯眼看 3 秒能猜出报告内容 |
| 01  | Verdict                          | 必    | 30-60    | 1 个判断徽章 + 3 条要点          | 一句话告诉读者"接管 / 重构 / PoC" |
| 02  | Project at a Glance              | 选    | 40-80    | 1 张速览表（语言占比 / LOC）     | 给读者快速建立项目体量 / 语言 / 节奏的 mental model |
| 02b | Business Domain Map              | 必    | 30-60    | 1 张 `graph LR` 业务实体图       | 用 schema / 枚举 / 模块命名勾出业务实体关系 |
| 03  | Architecture Map                 | 必    | 60-100   | 1 张模块依赖 mermaid 图          | 让读者一眼看出系统的层次 / 边界 / 依赖方向 |
| 04  | Module Walk-through              | 必    | 200-400  | 每子节 1 张 Section 03 子图       | 一桶一子节地走过所有 bucket，技术 + 业务两线交织 |
| 05  | Exposed Entry Points             | 选    | 100-300  | 每入口 1 张 `flowchart TD`       | 把外部请求的入口全部画出来（最多 50-100 张图） |
| 06  | Tech Stack Audit (CVE)           | 选    | 60-120   | 1 张依赖表 + CVE 徽章            | 列依赖 / 版本 / CVE 高分项 |
| 07  | Code Health Heatmap              | 选    | 40-80    | 1 张 SVG 复杂度热图              | 把每文件 / 模块的圈复杂度可视化 |
| 08  | Risks & Hot Spots                | 必    | 80-150   | 风险徽章组 + 3-7 条具体风险      | Verdict 的"为什么"，每条风险带证据与影响面 |
| 09  | Decisions That Matter            | 选    | 40-100   | 决策表 / 时间线                  | 把 commit / 注释 / PR / docs 里推得出的设计决策列出来 |
| 10  | Open Questions                   | 选    | 30-60    | 列表                             | 显式列出读不懂的地方，留给后续提问 |
| 11  | Coverage Annex                   | 必    | 50-200   | 1 张覆盖表                       | 所有未在前面 Section 出现的 inventory 文件登记 |
| 12  | Colophon                         | 必    | 5-10     | (无 · 文字)                      | 不可移除的署名 + 主题 |

**总行数估算**：典型 `100-1k` 文件项目走 7 必 + 3-4 选 = 10-11 节，渲染后正文约
700-1200 行（不含 Mermaid 与表格）。

## 3 · Section 分配规则（bucket → Section）

Plan 在写 Outline 时按下列规则把 `discovery/buckets/*.json` 映射到 Section：

- **Section 04 Module Walk-through**：**一桶一子节**。子节编号 `04.NN <bucket-slug>`，
  例如 `04.03 pkg-auth`。每子节必须引用 `bucket-NN-<slug>.json` 中的 `scope` + `loc`
  + `isEntryHeavy` 字段，并在 plan.md Outline 行的"引用 bucket"列列出 bucket id。
- **Section 03 Architecture Map**：节点 = bucket 列表中的 `scope`，边 = `_summary.json`
  或 codegraph 的模块依赖。**禁止**出现 inventory 中不存在的模块名（Plan 自检铁律 3）。
- **Section 05 Exposed Entry Points**：**仅当** `discovery/codebase-brief.md` 的
  "Entry-point sniff" 段统计到 ≥ 3 个入口时才渲染；否则 Plan 应把它放到 Coverage Annex
  并写一行"本项目无显式入口（纯 library / 内部脚本），跳过 Section 05"。
- **Section 08 Risks & Hot Spots**：每条风险必须能引用至少一个 bucket / 文件 + 一段
  `business-evidence/comments.jsonl` 或 `commit-themes.md` 的证据；不允许"经验性风险
  填空"。
- **Section 11 Coverage Annex**：所有未在 04 / 05 出现的 inventory 文件（含 excluded
  文件，标 `excluded_reason`）必须在这里列出。Plan 阶段写一行"待 Coverage Audit 自动
  填充"即可，Phase 5 由 `scripts/audit/coverage.sh` 校验。

## 4 · 可选 Section 自动决策规则（按 size-tier）

Plan 读取 `discovery/size-tier.json` 后按下表决定 6 个可选 Section 的"默认开关"。
用户在 Checkpoint 1 可以用自由文本覆盖（"我要看 Section 06" / "去掉 Section 07"）。

| size tier | 02 Glance | 05 Entry | 06 Stack | 07 Heatmap | 09 Decisions | 10 Open Q | 备注 |
|-----------|-----------|----------|----------|------------|--------------|-----------|------|
| `<100`    | **关**    | 关（除非检测到 ≥ 3 入口）| **关** | **关** | 关 | 开（小项目通常有开放问题） | 小项目去掉抽象的"全局视角"，直接看 03 / 04 即可 |
| `100-1k`  | 开        | 开（默认）| 开    | 开（若 lizard / radon 可用） | 开 | 选开 | 默认完整组合 |
| `1k-10k`  | 开        | 开        | 开    | 开（必开 · 帮读者锁定热区） | 开 | 选开 | 中大型项目 Section 07 价值最高 |
| `>10k`    | 开        | 开（但建议按 role 分卷） | 开 | 开（必开） | **关**（信号噪音比太低） | 选开 | `>10k` 时 Coverage Annex 必须非常醒目；**禁止声称 100% coverage** |

**`>10k` 诚实规则的额外约束**（PRD R3.6 + 工作流总览）：

1. Plan Brief 段必须写一行"size tier `>10k`,reader profile 推荐降级到
   `archaeology · 70%`,**Coverage Annex 强制醒目**,不会声称 100% coverage"。
2. Verdict 段不能出现"全面分析"/"完整覆盖"/"百分百"等强承诺词；用"按 ~70% 抽样分析"
   或"代表性 bucket 覆盖"。
3. Coverage Annex 在 TOC 中升级为 H2 加粗，并在 Section 头部出现一个 `[INCOMPLETE]`
   徽章（terminal 主题的 `--ra-warn-amber` 色），文案"本报告覆盖 ~XX%（XXX / YYY 文
   件）。未覆盖部分见下表"。

## 5 · 每节 Business-Job 提示词（Plan SubAgent 用）

每节在 plan.md Outline 行里**必须**写一句 Business-Job ——告诉 Writing SubAgent
"这一节的业务角度是什么"。下表是 architecture-review profile 的标准模板（Plan 可
按项目实际改写，但不能空着）：

| Section | Business-Job 模板（一句话） |
|---------|------------------------------|
| 01 Verdict | 一句话告诉读者**这个项目值不值得继续投入**，并给出"接管 / 重构 / PoC"三选一 |
| 02 Glance | 用语言占比 / 提交节奏 / 团队规模等元数据**回答"这是一个什么体量、什么生命周期阶段的项目"** |
| 02b Business Domain | 用 DB schema / 枚举 / 模块命名**勾出业务实体之间的关系**，让读者知道"这套代码在为哪个业务建模" |
| 03 Architecture | 用模块依赖图回答"**核心业务能力被组织成几层 / 几个模块**" |
| 04 Module Walk | 每个 bucket 回答"**这个模块在业务上承担什么职责 / 哪条业务规则在这里**" |
| 05 Entry Points | 每个入口回答"**外部调用从哪里进、走完哪些业务规则、最终落在哪个数据出口**" |
| 06 Tech Stack | 用依赖 / 版本 / CVE 回答"**这套代码靠哪些技术栈生存,健康度如何**" |
| 07 Heatmap | 用复杂度热图回答"**业务最贵 / 最危险的代码在哪儿**" |
| 08 Risks | 每条风险回答"**这个风险点会损害哪条业务规则 / 哪个业务流程**" |
| 09 Decisions | 每条决策回答"**当年为什么这么选,以及这个选择对未来的业务演化有什么影响**" |
| 10 Open Q | 每条问题回答"**这块代码读完后,我仍然不知道它在业务上是为了什么**" |
| 11 Coverage | "全部 inventory 文件去向追溯,业务上没有承诺,纯结构性披露" |

**业务-Job 自检铁律**（写完每行后回看）：如果某节的业务-Job 写不出来 ——
**显式标"业务背景未知,本节只做技术解释"**，不要硬编。这是 Plan 自检铁律 2，也是
Section Reviewer 的 5 条 claim audit 中的一条。

## 6 · Self-check（5 条 · 写完 plan.md 立刻自查）

主 Agent 在 Phase 2 写完 plan.md 后**就地**对照下列 5 条 ——
**禁止开 SubAgent、禁止写 plan-review.md**。任一 fail → 回 plan.md 改 → 再自查 →
通过后进 Checkpoint 1。

1. **必选 Section 齐全**：Cover / 01 Verdict / 02b Business Domain / 03 Architecture /
   04 Module Walk / 08 Risks / 11 Coverage Annex / 12 Colophon 这 8 个**一个不能少**。
   architecture-review profile **不允许**因为"项目小"就跳过 02b 或 08 ——
   小项目可以让这两节短到 20-30 行，但不能没有。
2. **Verdict 不是空的**：01 Verdict 的"接管 / 重构 / PoC"三选一必须有一个被选中并写出
   一句理由；不允许"待定 / 视情况而定 / 取决于团队"等模糊兜底。Plan 阶段写出**候选
   verdict + 主要论据**即可，Phase 4 写作时再细化。
3. **Coverage Annex 覆盖 100% inventory**：`buckets/_summary.json.analyzedFiles` +
   excluded 文件数 = `inventory.json` 总文件数。任何漏的文件 = fail。`>10k` 项目允许
   走 ~70% 抽样,但**必须**在 Annex 显式列出"未抽样部分"的范围。
4. **02b / 03 / 05 至少有一张图**：02b Business Domain Map 必须画一张 `graph LR`
   （即使只有 3 个实体）；03 Architecture Map 必须画一张模块依赖图；05 Entry Points
   被开启时必须至少 1 张 `flowchart TD`。视觉块缺失 = fail。
5. **`>10k` 诚实规则被遵守**：如果 size tier 是 `>10k`,Plan Brief 是否写了那段"~70%
   覆盖,不声称 100%" 提示词？Verdict 是否避免了"完整 / 全面"等承诺词？Coverage Annex
   是否被升级为醒目位置？任一未达成 = fail。

## 7 · Theme recommendation hint（给 Checkpoint 1 推荐用）

architecture-review profile 的**默认主题推荐 = `terminal`**（PRD Q8）。理由：

- terminal 主题的 5 类语义状态色（risk-red / warn-amber / status-green / status-blue /
  status-violet）是为 Section 08 风险徽章 / Section 02b 业务实体 / Section 05 入口角色
  量身设计的；用其它主题需要手写一组替代色,成本高。
- 暗底等宽视觉让大量 `file:line` 引用读起来不喧宾夺主（呼应 Q9b 的 inline 鼓励）。

**例外建议**（写在 Checkpoint 1 推荐理由里供用户参考）：

- **项目偏证据 / 研究 / 算法库（典型例子：论文配套代码、ML pipeline、benchmark）**：
  推荐 `tufte`。理由：tufte 的 data-ink 哲学让 Section 06 / 07 的数据密集表格读起来
  更克制；terminal 的徽章感在学术项目里会显得过装饰。
- **项目本身就是内容业务（CMS / blog engine / 文档站后端）**：推荐 `press`。理由：
  让"代码分析报告"读起来像一本 editorial guide,呼应项目本身的内容气质。
- **默认情形（业务系统 / 微服务 / 中台 / 工具）**：直接 `terminal`,无需说明。

## 8 · Cover composition starter（封面起手提示）

architecture-review 的封面在 Phase 3 First Spread 替换 `article/Cover.tsx` 的
`<CoverPlaceholder />`。本 profile 推荐三种构图起手（任选其一,具体技术见
`references/cover.md` 的"视觉技术·模型自己选"段）：

1. **Tech-stack mosaic（技术栈拼贴）**：用主项目语言 + 核心框架 + 关键依赖的图标
   （**SVG 内联,禁止远程图**）构成 3×3 / 2×4 拼贴 + 项目名大字。适合多语言或技术栈
   丰富的项目（典型例子：Java + Vue + Python ETL 的中台系统）。
2. **Risk traffic-light grid（风险红黄绿格）**：3×3 或 2×3 的符号化网格,每格用 terminal
   主题的 risk-red / warn-amber / status-green 三色填色,呼应 Section 08 的风险密度。
   适合"判断为重构 / 弃用"的报告 —— 一眼传达紧张感。
3. **Module dependency silhouette（模块拓扑骨架）**：把 Section 03 Architecture Map
   的简化版用 `--ra-status-blue` 发丝线画在封面上 + 大字项目名。适合"判断为接管"的
   清晰系统 —— 一眼传达"这个项目结构清晰"。

封面文字层固定三段：项目名（`--ra-mono-display` 大字号）、副标题
`Codebase Analysis · architecture-review`、底部 colophon
`Made with [beautiful-codebase] · terminal theme`。

## 9 · 给 Plan SubAgent 的微调提示（写 plan.md 时的口诀）

- **写 Verdict 不要等所有 Section 写完才写**：plan.md 阶段就要落下"候选 verdict +
  主要论据"，否则 Phase 4 写出来会变成"先有 Section 再硬凑结论"。读者看的是判断,
  Section 是支撑材料。
- **08 Risks 与 09 Decisions 互引**：Risks 段每条风险尽量带一句"这条风险与 Section 09
  的 D-XX 决策相关"；让读者能从"风险"反查到"为什么会这样"。
- **03 Architecture Map 与 04 Module Walk 互引**：03 的每个节点尽量是 04 子节的锚点
  （`#04.NN-<bucket>`）,读者点击图上节点直接跳到那一子节。Plan Outline 里就要标好
  互引锚点。
- **业务上没找到的事不要硬编**：如果 02b Business Domain Map 在 schema / 枚举里只能
  找到 2 个实体,**就只画 2 个实体**,并加一句"本项目业务实体稀疏,可能为内部工具 /
  纯技术组件"。Q6 业务升级铁律：confident-tone 无证据 = fail。

## 10 · Per-section 写作起手提示(Writing SubAgent 用)

下面给出每个必选 Section 在 Step B Writing SubAgent 落笔时的"开头三句话"心智模型 ——
**不是模板字符串**(避免雷同),而是"这段该走什么节奏"的提示。

- **01 Verdict**: 第一句直接给判断("本项目当前结构 [接管 / 重构 / PoC],主要原因
  是…"),第二句给出 1-2 条关键支撑证据(指向 08 Risks 或 09 Decisions),第三句
  指明"主要不确定性"(诚实标注还需要哪些信息才能更确信)。**不要**用"通过深入分析,
  我们认为…"等套话开头。
- **02b Business Domain Map**: 第一段说"本项目的业务实体共 N 个,核心是 X 与 Y,
  通过 Z 关系联系";第二段说"实体识别来源:DB schema 中的 X 张表 / 枚举类 N 个 /
  模块命名暗示 …";第三段说"业务背景未在代码中显式声明的部分:…"(诚实标注盲点)。
- **03 Architecture Map**: 先画图(由 evidence 决定节点 / 边),后用 prose 拆解
  "层次 / 边界 / 依赖方向"三件事;最后一段点出"架构图里的可疑边"(循环依赖 /
  跨层穿透 / 上下游不对称)指向 08 Risks。
- **04 Module Walk-through**: 每个子节按"职责 → 关键文件 → 入口 → 业务规则 → 与其他
  模块的关系 → 本模块的风险点(如有)"的顺序写。**禁止**子节之间风格漂移 —— 第一个
  子节定调,后面所有子节按相同骨架写。
- **08 Risks & Hot Spots**: 每条风险按"标题(短) → 证据(file:line + 一段引用) →
  影响面(业务 / 性能 / 可维护性) → 修复成本(粗估) → 与 Decisions 的关联(如有)"
  写。风险数量 ≤ 7 条 —— 多了读者抓不住重点;有 12 条就合并成 5-7 个"风险族"。
- **11 Coverage Annex**: 由 `scripts/audit/coverage.sh` 自动生成,主 Agent 在 Phase 5
  写入。不要让 SubAgent 写这一节。

## 11 · 反面案例(本 profile 专属 · 禁止)

- **Verdict 不给判断**: 写"项目情况复杂,需要进一步评估" —— 这违反 profile 的核心
  承诺。即使所有信号矛盾,也要选一个三选一并写出"我选 X 是因为有 A 和 B 两项决定性
  证据;C 项相反证据但权重较低"。
- **Risks 全是经验填空**: 写"测试覆盖率可能不足 / 缺乏文档" 等不带具体 `file:line`
  的泛泛风险。每条 Risk 必须有可溯源的证据(`comments.jsonl` / `commit-themes.md` /
  `coverage.sh` 的输出)。
- **Decisions 编造作者意图**: 写"作者选 X 是为了灵活性" —— 除非有 commit / 注释 /
  ADR 明确说了"为了灵活性",否则只能写"作者选 X(commit `<sha>`),具体原因未在代码
  / 文档中说明"。
- **Architecture Map 画"理想架构"**: Section 03 必须画**真实**架构(从 inventory +
  codegraph 推),即使它丑、即使有循环依赖。**禁止**为了美观把图画成"应该长这样"
  的理想态;那是 architecture-proposal,不是 architecture-review。
- **把 Section 05 当成"项目大全"**: 入口流程图按 PRD Q6 升级硬上限 max 12 chart / role,
  全项目 max 50-100 chart;超出走 "Other Entry Points" 表格。**禁止**为追求完整把全部
  500 个入口画 500 张图 —— 报告会变成不可读的图册。

## 12 · 已知 trade-off / 局限

- **30 分钟限制是软上限**: 真要做出"接管 / 重构 / PoC" 判断的读者会回来翻第二遍 ——
  30 分钟是首次过审,不是终审。所以 Section 09 Decisions / 11 Coverage 这些"细节
  支撑"段允许密集,因为它们是给"二审"用的。
- **业务背景识别有上限**: 即便扫了 schema / 枚举 / 注释 / commit,某些项目就是没有
  显式业务表述(例如纯算法库 / 内部脚本集合)。02b 段允许写"业务实体稀疏,可能为
  纯技术组件" —— 这不是 profile 失败,是项目本身的特征。
- **Section 09 Decisions 在小项目里通常空**: `<100` 文件 + < 50 commits 的项目通常
  没有"值得回顾的决策";Section 09 在小项目里默认关闭(见 §4)。强行开会变成 1-2 条
  "这个项目使用了 Python 3.9" 等噪声。
- **跨语言项目挑战**: 多语言项目(典型:Java backend + Vue frontend + Python ETL)的
  Section 03 / 04 / 07 都需要按语言分层处理;Plan Outline 里 03 的节点要按语言着色,
  04 的子节要按语言分组,07 的复杂度热图按语言子图分页。

## 13 · 与其他 reference 的协作图

architecture-review profile 在整个 Skill 里不是孤立的 ——下面列出它和其他 reference
的关键协作点,Plan SubAgent 在写 plan.md 时应该按顺序参考:

| 阶段 | 主要读 | 配套 | 落到 plan.md 的哪一段 |
|------|--------|------|------------------------|
| Brief · reader profile | 本文件 §1 / §4 / §6 | `information-density.md` §1 | Brief 的"Reader profile" / "信息保留比例" |
| Brief · 工具 tier / size tier | `discovery/tools.json` / `size-tier.json` | `bucket-strategy.md` | Brief 的"工具 tier" / "size tier" |
| Outline · Section 列表 | 本文件 §2 / §3 / §4 | `discovery/codebase-brief.md` | Outline 表格的"必/选" / "引用 bucket" 两列 |
| Outline · 业务-Job | 本文件 §5 | `business-evidence-collection.md` | Outline 表格的"业务-Job" 列 |
| Theme | 本文件 §7 | `theme-selection.md` §3(3x3 矩阵) | Theme 段 |
| 版式 + TOC | (无 profile 偏好) | `layout.md` | Brief 的"版式宽度" / "TOC" |
| Assets | (无 profile 偏好) | `asset-policy.md` | Assets 段 |
| 封面 | 本文件 §8 | `cover.md` §3.1 / §3.2 / §3.3 | Brief 的"封面" |
| Self-check | 本文件 §6 + 本文件 §11 | `plan-template.md` §D | (无 ——主 Agent 内联跑) |
| Checkpoint 1 推荐文案 | 本文件 §7 / §8 | `plan-template.md` §E | (Checkpoint 1 的开场说明段) |

**写 plan.md 时的顺序心智**: 先读本文件 §1-§5 + `discovery/codebase-brief.md`(知道
项目大致是什么);再写 Brief 段(profile / 比例 / 工具 tier / size tier / 语言);
再写 Outline(每节按 §2 / §5 取标题与业务-Job);再写 Theme(按 §7 + 3x3 矩阵选);
最后写 Assets / 封面;**最后**对照 §6 + §11 的自检铁律内联自查。

## 14 · 一段最小可行 Outline 示例(供模仿)

下面是一份典型 `100-1k` 文件的业务系统的 architecture-review Outline 的"骨架行",
省略了 Brief / Theme / Assets 段。**仅作示意**,不要照抄 ——Section 数量、bucket
引用、Business-Job 都要按本项目实际重写:

```
| #   | 标题 | 必/选 | 引用 bucket | 业务-Job | 期望长度 | 视觉块 |
|-----|------|-------|-------------|----------|----------|--------|
| 00  | Cover | 必 | (无) | 视觉钩子;risk traffic-light grid | (封面) | SVG + 文字 |
| 01  | Verdict | 必 | (无) | 接管 / 重构 / PoC 三选一 + 主要原因 | 40 | 1 个判断徽章 |
| 02  | Project at a Glance | 选 | (全) | 用语言占比 + LOC 标定体量 | 60 | 1 张速览表 |
| 02b | Business Domain Map | 必 | bucket-02-domain, bucket-03-order | 用 schema + 枚举勾出业务实体 | 50 | graph LR |
| 03  | Architecture Map | 必 | (全) | 用模块依赖图回答"几层 / 几模块" | 80 | flowchart TD |
| 04  | Module Walk-through | 必 | bucket-01..bucket-06 | 每个 bucket 业务职责 + 关键规则 | 320 | 6 张子图 |
| 05  | Exposed Entry Points | 选 | (依据 entry-point sniff) | 外部调用从哪里进、走完哪些规则 | 200 | 12 张 flowchart |
| 06  | Tech Stack Audit | 选 | (依赖文件) | 用 CVE + 版本回答健康度 | 80 | 1 张表 + CVE 徽章 |
| 07  | Code Health Heatmap | 选 | (全) | 业务最贵的代码在哪儿 | 60 | 1 张 SVG 热图 |
| 08  | Risks & Hot Spots | 必 | bucket-04-payment, bucket-06-refund | 每条风险损害哪条业务规则 | 120 | 风险徽章组 |
| 09  | Decisions That Matter | 选 | (commit-themes) | 当年为什么这么选 | 80 | 决策表 |
| 11  | Coverage Annex | 必 | (全) | 全部 inventory 去向追溯 | (脚本生成) | 1 张表 |
| 12  | Colophon | 必 | (无) | (无业务) | 5 | 文字 |
```

Inventory 覆盖核查行:`所有 inventory 文件已分配:[320 / 340];已标 excluded:[20];
320 + 20 = 340 ✓`(假设 inventory.json 共 340 文件,其中 20 被 excluded)。

---

> 本 profile 是 v0.1.0 的基线。`architecture-review` 是用户最常选的 profile,真正写过
> 一份后如果发现 13 节框架不合用,**回到本文件改 Section 列表 / 自动决策表**,不要
> 在单份 plan.md 里临时改 ——其它项目下次还会复用本 profile。
