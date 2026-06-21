# Plan Template · `plan/plan.md` 单一规划文件模板

> **何时读**：Phase 2 写 `plan/plan.md` 时;Phase 2 末尾内联自检时;Checkpoint 1
> 收集决策前(本文件后半段就是 Checkpoint 1 协议)。
>
> **配套文件**：`references/profiles/<id>.md`(profile 决定的 Section 列表与 Business-Job
> 模板)、`references/theme-selection.md`、`references/layout.md`、
> `references/information-density.md`、`references/asset-policy.md`、`references/cover.md`、
> `references/review-checklist.md`(Plan 自查段)。

继承 `beautiful-article` 的 Brief / Outline / Theme / Assets 四段,扩展每节的
**Business-Job** 行 + **100% inventory coverage** 自检。Phase 2 **只产出一份 `plan/plan.md`**,
**不直接写 HTML**,写完后由**主 Agent 内联**跑 5 条自查(见末尾"Plan 自检"段),
按结论改 `plan.md` 本身,**不开 SubAgent、不写任何 review 文件**,然后进入
Checkpoint 1。

---

## A · `plan/plan.md` 完整模板

```markdown
# Plan

## Brief

- 目标读者：<谁会读,带着什么决策问题>
- Reader profile：<architecture-review / onboarding / archaeology>
- 信息保留比例：<X%>(走 profile 标配 · architecture-review=80% / onboarding=65% /
  archaeology=100%(>10k 时强制 70%));用户偏离标配写实际值并加一行"非标配组合·
  注意事项"
- 主要观点：<这份报告要让读者记住的 1-3 个判断 / 上手指引 / 归档结论>
- 阅读目标：<读完能做什么决定 / 知道什么 / ship 什么 issue>
- 必须保留的信息：<章节 / 表格 / 业务规则 / 关键文件,逐条列;指向 inventory / business-evidence>
- 可删减的信息：<对当前 profile 不重要的部分;每条带理由>
- 语气：<克制分析(arch-review) / 团队前辈指引(onboarding) / 考古学家描述(archaeology)>
- 目标语言：<中文 prose + 英文标识符(默认) / 全中 / 全英 / 双语>
- 版式宽度：<narrow / regular(默认) / wide / full>(见 `references/layout.md`)
- TOC：<开(默认) / 关>
- 配图策略：<none(默认) / user-assets / placeholders / ai-generated>(见 `references/asset-policy.md`)
- 封面：<开(默认) / 关>。若开,写一句构图想法 + 推荐起手模板(见
  `references/profiles/<id>.md` 的 Cover 段 + `references/cover.md`)。
- **业务-Job 总结**(一段话,3-5 句):整份报告在业务层面承担什么任务 —— 不是"分析代码",
  而是"让读者明白这套代码在做什么业务 / 当年为什么这么做 / 现在的业务表现如何"。
- **工具 tier**：<codegraph-indexed / codegraph-installed / rg / grep>(来自
  `discovery/tools.json`)
- **size tier**：<<100 / 100-1k / 1k-10k / >10k>(来自 `discovery/size-tier.json`)
- **git remote**：<<owner>/<repo> · <sha> · 上次扫描时间>(若 Phase 0 抓到 origin)
- **Inventory 总数**：analyzed = <N1> / excluded = <N2> / total = <N1+N2>(对齐
  `inventory.json`)

## Outline

### Sections

| #   | 标题 | 必/选 | 引用 bucket | 业务-Job(一句话) | 技术-Job(一句话) | 期望长度 | 视觉块 |
|-----|------|-------|-------------|------------------|------------------|----------|--------|
| 00  | Cover | 必 | (无) | <一句话,见 profile §5> | 视觉钩子 | (封面) | 主视觉 + 文字 |
| 01  | Verdict / Welcome / Lead | 必 | (无,基于 brief) | <一句话> | <一句话> | 30-60 行 | 1 个徽章 |
| 02  | ... | ... | bucket-NN-<slug> | <一句话或 "业务背景未知,本节只做技术解释"> | <一句话> | <N 行> | <Mermaid/表格/无> |
| ... | ... | ... | ... | ... | ... | ... | ... |
| 11  | Coverage Annex | 必 | (全表) | "全部 inventory 文件去向追溯,业务上无承诺,纯结构性披露" | 列出未在前面 Section 出现的所有文件 | 50-200 行 | 1 张表 |
| 12  | Colophon | 必 | (无) | (无业务) | 不可移除署名 | 5-10 行 | (文字) |

**Inventory 覆盖核查**(下面这行必须填实际数字):

- 所有 inventory 文件已分配：[X / Y](X = 分配到 Section 04 / 05 等的文件数;Y = `inventory.json` analyzed 总数)
- 已标 excluded(annex 内承诺列出)：[Z](Z = `inventory.json` 中带 `excluded_reason` 的文件数)
- X + Z 应等于 Y · 不等 = Plan 自检 fail

### Hero / Lead / Summary

- Hero：<标题气质 / 副标题 / meta:扫描日期 · git remote · 工具 tier>
- Lead：<导语,1-2 句框定报告主题>
- Summary：<是否需要 TL;DR ——arch-review 通常需要(就是 01 Verdict 的浓缩),
  onboarding / archaeology 通常不需要>

## Theme

- 选定主题：<terminal(默认) / tufte / press>
- 理由：<为什么是它,结合 reader profile + 项目语义类型(业务系统 / 学术 / CMS)>
- 与 reader profile 的契合度：<引用 `references/theme-selection.md` 的 3x3 矩阵>
- 已知冲突：<如有(例:archaeology + terminal 在长报告里徽章频率会偏高),如何处理;
  若无,写"无">
- 当前信息密度下的表现建议：<引用 `theme-profiles/<id>.md` 的相应段>

## Assets

> 这一段配合 Brief 的"配图策略"使用。本 Skill 默认 `none` —— Mermaid 才是主视觉。
> `none` 模式下一句话即可。

- 策略：<none(默认) / user-assets / placeholders / ai-generated>
- 一句话说明：<为什么是这个策略 —— "本 Skill 用 Mermaid 做架构 / 调用链 / 业务实体图;
  外部 Image 通常不需要">

### 逐图计划(仅 user-assets / placeholders / ai-generated 模式需要)

每张图列：位置 / 服务的段落 / 目的 / 主题 / 风格 / 禁止项 / 来源 / 备选提示词。
格式同 `beautiful-article` 的 plan-template.md。
```

---

## B · Outline 自检三铁律(写 Outline 时手动遵守)

1. **100% inventory 覆盖**: 每个 inventory 模块目录都被某 Section 认领(出现在
   "引用 bucket" 列)**或**写进 Coverage Annex。任何模块文件**两边都没出现** = fail。
2. **每节业务陈述有引用或显式标"未知"**: Business-Job 列里的每条声明要么能在
   `discovery/business-evidence/` 找到证据,要么写成"业务背景未知,本节只做技术解释"。
   confident-tone 无证据 = fail。
3. **Outline 模块名必须存在于 inventory**: 任何在表格里出现的模块 / 文件名,必须能在
   `inventory.json` / `buckets/*.json` 里找到。**禁止编造模块** —— 例:不要在
   "引用 bucket" 列写一个根本不存在的 `bucket-99-imaginary`。

---

## C · 业务-Job 行写法示例(3 个示例 · 见样式而不是套用)

### 示例 1 · 电商订单服务(architecture-review)

```
| 04 Module Walk | 必 | bucket-03-order, bucket-04-payment, bucket-05-inventory |
  "每个 bucket 回答:这个模块在业务上承担订单生命周期的哪一环(下单/支付/出库),
   关键业务规则在哪个文件" |
  "每个 bucket 走完代码结构 + 入口 + 关键调用链" |
  ~280 行 | 3 张子图(每 bucket 1 张) |
```

### 示例 2 · 内部脚本集合(architecture-review · 无明显业务)

```
| 04 Module Walk | 必 | bucket-01-scripts |
  "业务背景未知,本节只做技术解释 —— 这是一组内部运维脚本,无对外业务规则" |
  "走完每个脚本的入口 / 输入 / 输出 / 副作用" |
  ~120 行 | 1 张子图 |
```

### 示例 3 · 算法库(archaeology)

```
| 06.03 graph-algorithms | 必 | bucket-03-graph |
  "图算法库:实现 Dijkstra / BFS / DFS / Tarjan SCC;业务背景为图遍历计算,
   不直接对应外部业务实体;调用方在 bucket-05-business 里" |
  "走完每个算法的实现 / 复杂度 / 测试覆盖" |
  ~180 行 | 1 张算法关系图 + 1 张复杂度表 |
```

---

## D · Plan 自检(5 条 · 写完 plan.md 立刻自查)

**铁律重申**:这一节由**主 Agent 内联**执行 ——**禁止开 SubAgent**,**禁止写
`review/plan-review.md` 文件**,**禁止跳过任一条**。任一 fail → 回 plan.md 改 →
再自查 → 全通过后进入下面的 Checkpoint 1。

1. **100% inventory 覆盖(铁律 1)**: Outline 段末尾的 "Inventory 覆盖核查" 三行,
   X + Z == Y。任何不等 = fail。
2. **业务引用 / 显式未知(铁律 2)**: 翻一遍 Outline 表格,每行的"业务-Job"列要么有
   具体业务表述,要么显式标"业务背景未知,本节只做技术解释"。confident-tone 无证据 = fail。
3. **Outline 不编造模块(铁律 3)**: 翻一遍 Outline 的"引用 bucket"列,每个 bucket id
   能在 `buckets/_summary.json.buckets` 里找到。任何编造 = fail。
4. **必选 Section 与 profile 一致**: 翻一遍 Outline 的"必/选"列,所有必选 Section 已
   出现且符合 reader profile(见 `references/profiles/<id>.md` 的 §2 表)。漏一节 = fail。
5. **`>10k` 诚实规则被遵守(若适用)**: 如果 `discovery/size-tier.json` 是 `>10k`,
   Brief 是否写了"~70% 覆盖" / "不声称 100%" / "Coverage Annex 醒目"等?Verdict /
   Welcome / Lead 是否避免了"全面 / 完整"等承诺词?任一未达成 = fail。

---

## E · Checkpoint 1 协议(Plan 后必须停下来 · 5 项独立确认)

**铁律**: **禁止静默替用户选择**。下面 5 项**每项独立列出 + 等用户答复**;**禁止
打包成"全选我推荐的吗?"yes/no**。AI 可以推荐(写理由),**不能跳过让用户选**。

### E.1 开场说明(收集决策前先发一条)

```
plan/plan.md 已经写好(自检 5 条全通过)。我会逐项跟你确认 5 件事:
1) reader profile · 2) 主题 · 3) 版式宽度 · 4) 配图模式 · 5) 封面。

我的推荐先放在这里供参考(不会替你选):
- reader profile:<X · ~Y%>(理由:基于 discovery/codebase-brief.md 的项目体量与
  业务密度,推荐 …)
- 主题:<theme>(理由:见 references/theme-selection.md 的 3x3 矩阵,在 <profile> +
  <项目类型> 下推 <theme>)
- 版式宽度:<width>(理由:本项目 Section 05 预计有 <N> 个流程图,推荐 <wide / regular>)
- 配图模式:<策略>(理由:本 Skill 默认 none,因为 Mermaid 是主视觉)
- 封面:开 / 关(理由:…;若开,构图想法见 references/profiles/<id>.md 的 Cover 段)

默认走但你可以推翻:语言(中文 prose + 英文标识符);TOC 开;接下来会先做首屏样张。
信息保留比例如要偏离 profile 标配,下面回答完直接告诉我具体百分比。

下面逐项请你确认。
```

### E.2 5 项独立问题(优先 AskQuestion · 无工具则编号列出 + 停下等答复)

| # | 决策项 | 选项 | AI 推荐规则 | 备注 |
|---|--------|------|-------------|------|
| 1 | **reader profile**(信息保留比例打包在内) | `architecture-review · ~80%` / `onboarding · ~65%` / `archaeology · ~100%`(>10k 时 ~70%) | 从 `discovery/codebase-brief.md` 的 "Auto-decisions · suggested profile" 行取默认值。`>10k` 时**强制**推荐 archaeology · 70%(用户可推翻,但 70% 上限不破) | 比例不再单独成题;偏离标配走用户自由文本("arch-review 但只要 50%") |
| 2 | **主题** | `terminal`(默认) / `tufte` / `press` | 走 `references/theme-selection.md` 的 3x3 矩阵 + `discovery/codebase-brief.md` 的"项目语义类型"(business / research / cms / tooling) | 推荐写两句:为什么这个项目类型 + profile 下推这个主题 |
| 3 | **版式宽度** | `narrow` / `regular`(默认) / `wide` / `full` | 默认 `regular`;若 `discovery/codebase-brief.md` 显示"预计 Section 05 有 ≥ 10 个流程图" → 推荐 `wide`;若文件路径 ≥ 60 字符密集 → `wide` | TOC 默认开,不另成题 |
| 4 | **配图模式** | `none`(默认) / `user-assets` / `placeholders` / `ai-generated` | 默认 `none` —— 本 Skill 用 Mermaid 做主视觉,外部图很少需要。**这一项不允许"默认通过"**(沿用 beautiful-article 的硬约束),必须用户明确选 | `placeholders` 通常只用于封面;`ai-generated` 不推荐 |
| 5 | **封面 · 开 / 关** | `开`(默认) / `关` | 默认推荐"开" + 给一句构图起手(从 `references/profiles/<id>.md` 的 Cover 段取一个模板) | onboarding 推荐 "welcome map";architecture-review 推荐 "module dependency silhouette" 或 "risk traffic-light grid";archaeology 推荐 "time capsule" |

### E.3 收集到答复后

**5 项全部收齐答复才能进 Phase 3**。把每项答复落回 `plan/plan.md` 的对应段(Brief 的
"Reader profile" / "信息保留比例" / "版式宽度" / "配图策略" / "封面";Theme 段的"选定
主题")。然后:

- 主 Agent 对照本文件的 D 段再跑一遍 Plan 自检(决策可能改变 Section 配置,需要重新核
  对必选 Section 是否齐全)。
- 全通过后进入 Phase 3 First Spread —— 跑 `scripts/scaffold.sh` 创建工作区。

### E.4 禁止的反面案例(不要犯)

- **禁止**:"我推荐 architecture-review + terminal + regular + none + 开封面,全 OK 吗?"
  ——把 5 项打包成 1 个 yes/no,剥夺用户选择。
- **禁止**:"我已经替你选好 terminal 主题了,如果不对再说" —— 静默替选。
- **禁止**:"我会写 plan.md 时顺便确认这些事" —— 必须独立、必须停下来。
- **允许**:在每项推荐里写明"为什么 + 备选项";让用户能"快速肯定"或"少量修正"。

---

## F · 与其它 reference 的关系

- **reader profile 详细 Section 列表 / Business-Job 模板**:见
  `references/profiles/<id>.md` 的 §2 / §5。Plan Outline 的"必/选"列与"业务-Job"列
  直接借用这两段。
- **主题选择 3x3 矩阵**:见 `references/theme-selection.md`,Plan Theme 段直接引用。
- **版式宽度详细规则**:见 `references/layout.md`,Plan Brief 的"版式宽度"行落到那里
  的决策树。
- **配图四种模式**:见 `references/asset-policy.md`,Plan Assets 段落到那里。
- **封面 5 条硬约束 + 模板**:见 `references/cover.md`,Plan Brief 的"封面"行落到那里。
- **Plan 自检 5 条铁律 + Checkpoint 1 协议**:本文件 D / E 段,以及
  `references/review-checklist.md` 的 "Plan 自查" 段(若两者有差异,以本文件为准 ——
  这里是单一规划文件的权威)。
- **信息保留比例与 profile 的关系**:见 `references/information-density.md`。
