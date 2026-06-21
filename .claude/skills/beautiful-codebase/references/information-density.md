# Information Density · 信息保留比例 + 组件比例

> **何时读**：Phase 2 写 plan.md 的 Brief 段"信息保留比例"行时;Phase 4 每节
> 写作时回看以判断"这段是不是该再压一点"。
>
> **配套文件**：`references/profiles/<id>.md`(profile 决定标配带宽);
> `references/component-policy.md`(Q9b 代码密度上限);`references/section-build.md`
> (Step B Writing SubAgent 的替换优先级)。

信息保留比例**与代码密度(Q9b)正交**: 前者是"原始信息留多少",后者是"代码 vs prose
比例上限"。两条铁律,Section Reviewer 各自核查。

## 1 · Reader profile 标配带宽

每个 reader profile 都有一个**默认信息保留比例**,这是 Plan Brief 段"信息保留比例"
行的默认起点。用户可以在 Checkpoint 1 回答 reader profile 时**用自由文本覆盖**(例:
"architecture-review 但只要 50%"),Plan 阶段把实际比例写到 plan.md。

| Profile | 默认保留比例 | 一句话标定 | `>10k` 时的硬上限 |
|---------|--------------|--------------|-------------------|
| `architecture-review` | ~80% | 评审人需要"足以做判断"的事实 + 浓缩的 Verdict;不需要文件级完整 | 不变 ~80% |
| `onboarding` | ~65% | 新人需要"上手所需"的事实;砍掉太学术 / 太归档 / 太抽象的内容 | 不变 ~65% |
| `archaeology` | ~100% | 归档场景必须完整;不允许"我觉得不重要就删" | **强制降到 ~70%**(诚实规则) |

**带宽是"自信范围",不是"硬上限"**: 80% 不是"必须 80%",而是"通常落在 70-90% 之间
是健康的"。低于下限(arch-review < 70%)说明"评审证据不足以支撑 Verdict",高于上限
(onboarding > 75%)说明"太多对新人没用的细节"。

## 2 · 每档带宽下的组件比例(描述性,不给硬百分比)

下表描述"在这个比例下,prose / 表格 / 图表 / inline code / CodeBlock 各自该如何分
布",**不给硬百分比** —— 实际比例由 Section 内容决定。

### `architecture-review · ~80%`

- **Prose 主导**: 评审人靠文字判断,不靠代码片段。
- **表格频繁**: Section 02 速览表 / 06 依赖表 / 08 风险表 / 11 覆盖表都靠表格组织
  事实。
- **流程图密集**: Section 03 / 05 是视觉重心;每张图配 1-2 段 prose 解释。
- **Inline code 大量**: `file:line` 引用、类名、配置 key 全靠 inline —— Q9b 鼓励。
- **CodeBlock 极少**: 受 Q9b 严格上限(每节 ≤ 1 块);Verdict / Risks 段几乎不用。

### `onboarding · ~65%`

- **Prose + Action 双线**: 每段 prose 后跟"具体动作"(命令 / 文件 / 测试名);避免
  抽象描述。
- **表格中等**: Section 02 Quick Start 的命令清单 / Section 07 Conventions 的速查表;
  Risks / Decisions 段(本 profile 没有)对应的复杂表格也没有。
- **流程图保留**: Section 05 入口图、Section 04 子节图都画,但单图节点数比
  architecture-review 少(新人不需要看完整调用链,只需要"我从哪里改起")。
- **Inline code 高频**: `file:line` 是 starter trail 的核心。
- **CodeBlock 可达 Q9b 上限**: Section 05 Module Walk 允许 ≤ 2 块/节 —— starter
  trail 偶尔需要一段简短的入口函数节选。

### `archaeology · ~100%(或 >10k 时 ~70%)`

- **Prose + 完整表格双重**: Module Chapter 的"文件清单"段是表格,**不省略**;
  Source Pointers 默认展开。
- **流程图按 bucket 全开**: 每个 Module Chapter 一张子图,即使只有 2-3 个节点也画。
- **Inline code 极频繁**: archaeology 把"每一个 `file:line`"都视为档案;Source
  Pointers 段动辄百行。
- **CodeBlock 仍受 Q9b 约束**: 即使 100% 信息保留,代码块仍然 ≤ 1 块/节 ——
  archaeology 保留的是"信息",不是"代码本身";代码靠 inline 与表格表达。

## 3 · 不同 Section 的密度差异(同一份报告内部)

即使 Plan Brief 写了 "80%",报告各 Section 的"信息密度"不是均匀的。Plan SubAgent
在写 Outline 时按下表大致分布(实际值因项目而异):

| Section | 典型密度档位 |
|---------|--------------|
| 00 Cover · 01 Verdict / Welcome / Lead · 12 Colophon | 极低(钩子 / 浓缩判断 / 署名) |
| 02 Glance · 02b Domain · 06 Stack · 07 Heatmap · 09 Decisions · 10 Open Q | 中(单张表 / 图 + 简短解释) |
| 03 Architecture · 08 Risks | 中高(单图 + 多段展开) |
| **04 Module Walk · 05 Entry Points** | **极高**(信息最密;表格 + 流程图 + 大量 inline) |
| **11 Coverage Annex** | **极高(表格密集)**(大表,prose 极少) |

**关键经验**: 04 / 05 / 11 是"高密度承重墙",其它 Section 不需要(也不应该)同样
密集。Plan 阶段提醒 SubAgent "你写 01 Verdict 时不要写得像 04 Module Walk 一样长"。

## 4 · 与 Q9b 代码密度的桥接

**Q9b 是硬上限,信息密度档位**是软建议**。两者各自独立审计:

- Q9b 上限(由 `scripts/audit/density.sh` 自动核查):
  - 每节 `<CodeBlock>` ≤ 1 块(Section 04 / 05 例外 ≤ 2 块)。
  - 每块 ≤ 8 行。
  - 全文 code-char share ≤ 15%。
  - block-count / paragraphs ≤ 0.15。
- 信息密度档位(由 Section Reviewer + Final Editorial Reviewer 主观判断):
  - reader profile 标配带宽是否被尊重。
  - 必须保留的信息有没有丢。
  - 是否出现"为了凑长度堆 prose"或"为了省字数把关键事实压成单字徽章"等极端。

**两者关系**: 即使 archaeology profile 拿到 100% 保留比例,Q9b 仍然约束代码块上限
——因为"100% 信息留存"指的是**信息**不是**代码本身**;信息可以靠 inline + 表格 +
mermaid 表达,而不必塞进 CodeBlock。

## 5 · 偏离标配的写法

用户在 Checkpoint 1 回答 reader profile 时**用自由文本覆盖**。典型例子:

- "arch-review 但只要 50%" → Verdict / Risks 不变(本来就浓缩),Module Walk /
  Entry Points 各 bucket 只写"入口 + 一句业务-Job + 主要风险",不全文 walkthrough。
- "onboarding 但要 90%" → Quick Start / Gotchas / Module Walk 写到 arch-review 级别
  的详尽度;Common Tasks 段从 5-8 条扩到 10-15 条。
- "archaeology 但只要 60%" → Module Chapters 每章用"压缩骨架"(职责 + 入口 + 关键
  文件清单,跳过完整文件树);Cross-cutting / Decisions 保留;**Open Questions
  不可压缩** —— 那是诚实标志。

**铁律**: 偏离标配时 Plan Brief 必须**显式写出实际比例 + 一行非标配组合·注意事项**,
让 Phase 4 写作时 Section Writing SubAgent 能看到这条提示。

## 6 · `>10k` 项目的反膨胀(anti-bloat warning)

在 `>10k` 项目上,即使 reader profile 是 archaeology,**也不要让 prose 密度跟着信息
量线性增长** —— 否则 article.html 会变成 5MB+ 的不可读墙。

具体规则:

- **prose 密度下降**:每个 Module Chapter 的解释段从 archaeology 标配的 100-200 行降到
  60-100 行。
- **pointer / 表格密度上升**:用 Source Pointers 折叠面板 + 文件清单表替代展开的
  prose;让读者"按需点开"而不是"被动通读"。
- **TOC 必须分层**(Section / Subsection),让 30+ 章可折叠。
- **Coverage Annex 必须分页**(由 reacticle 的 `<Pagination>` 组件处理) —— 完整表
  不要一次性渲染 1 万行。

这些规则的目的:**让 archaeology 报告在 `>10k` 项目上仍然能"被翻"** —— 翻不是读,
但翻得到就有归档价值。
