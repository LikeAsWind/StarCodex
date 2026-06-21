# Reader Profile · `archaeology`（交接归档 / 100% 留存）

> **何时读**：Checkpoint 1 用户选 `archaeology` 后；写 `plan/plan.md` 时；
> Phase 4 每节回看；以及 size tier `>10k` 自动给出降级建议时。
>
> **配套文件**：`references/plan-template.md`、`references/theme-selection.md`、
> `references/information-density.md`、`theme-profiles/terminal.md` /
> `theme-profiles/tufte.md`。

## 1 · Profile intent · 这份报告给谁读、读完做什么

`archaeology` 服务的是**交接 / 知识沉淀 / 半年后的接手者 / 离职归档 / 合规审计 /
未来的自己**。这是三个 profile 里**最长 / 最系统 / 最克制**的一种 ——核心使命是
**把活在某人脑子里的项目变成可检索资产**：

- 当原作者离开,**半年后接手的人**仍能从报告里找回"为什么这块代码长这样 / 当时是怎么
  决定的"。
- 当合规 / 审计来翻账,能从报告里查到**业务规则的逐条来源**(commit / 注释 / PR /
  schema)。
- 当**自己**两年后再回到这个项目,能从报告里像翻"项目日记"一样找回上下文。

任何让读者读完仍然"找不到这块代码当年为什么这么写"的报告,对这个 profile 都是失败的。
所以 archaeology 报告的核心**不是判断、也不是上手指引,而是 100% 信息留存 + 决策追溯**。

`archaeology` profile 的隐含承诺是：**信息完整度优先于阅读速度** ——这份报告不是为
"一坐下来读完"的人写的,而是为"半年后用 Ctrl+F 找东西"的人写的。所以长表格全开、
Source Pointers 默认展开、每个 bucket 独占一章、cross-cutting concerns 单列。

## 2 · 默认 Section 列表(13+ 章 · 11 必 + 2 选 · 章数随项目规模线性扩张)

archaeology profile **打破固定 13 节框架** ——Module Chapters 段按 bucket 数线性
扩张(每个 bucket 一章),所以一个 50 bucket 的项目会产生 50+ 章。下面给出的是
"骨架表"(N = bucket 数,可能是 5,可能是 30):

| #     | Section                          | 必/选 | 行数估算 | 必选视觉块                       | 一句话职责 |
|-------|----------------------------------|-------|----------|----------------------------------|------------|
| 00    | Cover                            | 必    | (封面)   | 主视觉 + 时间戳 + 主要贡献者     | "时间胶囊" 气质 |
| 01    | Lead · 一段 caption              | 必    | 40-80    | 元信息条                         | 一段 caption + 创作时间窗 + 主要贡献者 + git remote |
| 02    | File-tree Atlas                  | 必    | 100-500  | 完整文件树(代码块或表格)         | 完整文件树 + 每行一句注释;大项目可分页 |
| 03    | Business Domain Map              | 必    | 60-120   | 1 张 `graph LR` 业务实体图       | 比 architecture-review 更完整,保留所有发现的实体 |
| 04    | Architecture Map                 | 必    | 80-160   | 1 张完整模块依赖图               | 不简化,所有模块都画;过大时按子系统分页 |
| 05..N | Module Chapters (一桶一章)        | 必    | 每章 80-200 | 每章 1 张子图 + 子节结构        | 每个 bucket 独占一章;节内顺序:职责→文件清单→入口→关系图→解释→TODO |
| N+1   | Cross-cutting Concerns           | 必    | 100-200  | 横切关注点矩阵                   | 配置 / 日志 / 错误处理 / i18n / 安全 / 鉴权 / 缓存 |
| N+2   | Critical Path Trails             | 必    | 80-200   | 至少 3 张端到端 `flowchart TD`   | 至少 3 条最重要的链路,从入口到出口完整追踪 |
| N+3   | Decisions & Rationale            | 必    | 60-150   | 决策表 / 时间线                  | 从注释 / commit / style 归纳出来的设计决策(每条带证据) |
| N+4   | Open Questions                   | 必    | 30-80    | 列表                             | **显式列出未读懂的地方** —— archaeology 不允许把"不懂"藏起来 |
| N+5   | Glossary                         | 选    | 30-100   | 项目术语表                       | 项目独有名词 / 缩写 / 黑话 |
| N+6   | Coverage Annex                   | 必    | 80-300   | 完整覆盖表                       | **100% 覆盖,不允许 annex 简化**;`>10k` 例外见 §5 |
| N+7   | Colophon                         | 必    | 5-10     | (无 · 文字)                      | 不可移除的署名 + 主题 + 创作时间戳 |

**总行数估算**(N=10 bucket 的中型项目)：渲染后正文约 1500-3000 行 ——大约是
architecture-review 报告的 2-3 倍。这是 profile 的设计目标,**不是过度** —— archaeology
就是要全。

## 3 · Section 分配规则(bucket → Section)

- **Module Chapters 段(Section 05..N)**: **一桶一章,不合并**。这是 archaeology 与
  其他 profile 最大的区别 —— architecture-review 可以把多个小 bucket 合到 04 Module
  Walk 的子节里,onboarding 可以挑重点 bucket 写,但 archaeology 必须**每个 bucket 都
  有自己的一章**,即使这一章只有 50 行。
- **章内骨架固定六段**(每章按这个顺序写)：
  1. **章首元数据**:章号 + bucket scope + LOC + 主要贡献者(从 git blame 聚合)
  2. **职责**(一段话:这个模块在系统里承担什么 + 业务上对应什么)
  3. **文件清单**(完整列表,不省略 —— 这是 archaeology 的关键)
  4. **入口**(本模块的入口符号 + `file:line`)
  5. **关系图**(本模块对外依赖的 mermaid 子图,即使只有 2-3 个节点)
  6. **解释 + TODO**(代码里发现的 TODO / FIXME / HACK 引述 + 业务背景解释)
- **Section N+1 Cross-cutting Concerns**: archaeology 的特色章节,**必选**。即使项目
  没有显式 i18n / 安全模块,也要写"未检测到 X(扫描了 `<paths>`)"。这一节确保**横切
  关注点不会因为没有专门 bucket 而被遗漏**。
- **Section N+2 Critical Path Trails**: 至少 **3 条**端到端调用追踪(从入口到出口)。
  从 `discovery/business-evidence/tests.jsonl` + `entry-point-taxonomy.md` 的入口扫描
  里挑选"业务核心路径"(下单 / 登录 / 数据导出 等)。每条 trail 一张完整 `flowchart TD`。
- **Section N+3 Decisions & Rationale**: 来源限定为 **3 类证据**:
  1. `business-evidence/commit-themes.md` 中的"refactor:" / "decision:" / "switch from
     X to Y" 等聚类;
  2. `comments.jsonl` 中带"because" / "we chose" / "see RFC" 等标记的注释;
  3. `business-evidence/docs.md` 中的 README / ADR / docs/ 引用。
  **禁止**从代码 style 凭空归纳"作者偏好" ——archaeology 不允许"我感觉是"。

## 4 · 可选 Section 自动决策规则(按 size-tier)

| size tier | N+5 Glossary | 备注 |
|-----------|--------------|------|
| `<100`    | **关**       | 小项目术语稀,直接 inline 解释 |
| `100-1k`  | 选开         | 项目独有名词 ≥ 5 个时开 |
| `1k-10k`  | 开           | 默认开 |
| `>10k`    | 开           | 必开 ——大项目术语爆炸,不开会失控 |

**注意**:archaeology profile 的可选项**只有 Glossary 一个**;其他 12+ 个 Section 全部
必选 ——这正是 archaeology 的"100% 留存" 承诺的体现。

## 5 · `>10k` 诚实规则的特殊处理

**archaeology 是唯一可以产出"100% 留存" 报告的 profile** —— 这是它的卖点。但 PRD 的
`>10k` 诚实规则仍然强制约束所有 profile,所以 archaeology 在 `>10k` 项目下必须**分卷
输出**:

- **第一卷**(主报告): 覆盖项目最关键的 ~30 个 bucket(从 `_summary.json.isEntryHeavy`
  + 业务核心模块挑选)。这一卷仍叫"archaeology 报告",但**信息保留比例降到 ~70%**,
  Coverage Annex 段必须显式说"本卷为代表性子集,完整文件清单见附录卷"。
- **附录卷**(可选): `article-volume-2-annex.html` ——只含完整 File-tree Atlas +
  Coverage Annex + 未在主卷出现的 bucket 章节(每章用 archaeology 标准骨架,但允许
  短到 30-50 行)。
- **禁止**:`>10k` 项目下声称"100% coverage";只能说"分卷覆盖,主卷 ~70% + 附录卷
  追加 ~30%"。

**Plan 阶段的硬约束**(自检铁律之一): 如果 size tier == `>10k`,plan.md Brief 必须
包含一行 "本项目为分卷归档,主卷覆盖 ~70%,附录卷覆盖剩余 ~30%,本报告不会声称
100% coverage"。如果用户在 Checkpoint 1 强行覆盖为"单卷 100%",主 Agent 必须**再次
礼貌拒绝**并解释:"`>10k` 项目的 100% 单卷会导致 article.html ≥ 20MB,失去可分享性。"

## 6 · 每节 Business-Job 提示词(Plan SubAgent 用)

| Section | Business-Job 模板(一句话) |
|---------|------------------------------|
| 01 Lead | 一段 caption 回答"**这套代码是谁、什么时候、为什么、做的什么** —— 像项目的墓碑铭文" |
| 02 File-tree | 文件树本身没有业务-Job,但每行一句话注释必须**用业务语言** |
| 03 Business Domain | **比 architecture-review 更完整** —— 所有发现的实体都画,即使关系不清也画 |
| 04 Architecture | 完整模块依赖图;回答"**这个系统的业务能力被组织成几层**" |
| 05..N Module Chapter | 每章回答"**这个模块在业务上做什么 + 当年为什么这么实现**" |
| N+1 Cross-cutting | 每个横切关注点回答"**这套代码如何统一处理 X**"(配置 / 日志 / 安全等) |
| N+2 Critical Path | 每条 trail 回答"**一次完整的 X 业务流程,从外部请求到数据落地的全过程**" |
| N+3 Decisions | 每条决策回答"**当年这个团队为什么选 A 而不选 B**" |
| N+4 Open Q | 每条问题回答"**这块代码读完后,我仍然不知道它在业务上是为了什么**" |
| N+5 Glossary | 每个术语回答"**这个词在本项目里特指什么**"(可能与行业通用含义不同) |
| N+6 Coverage | "全部 inventory 文件去向追溯;`>10k` 时分卷追溯" |

**Business-Job 自检铁律**(archaeology 加强版): 业务找不到证据时**不仅要标"未知",还要
显式写出"已扫描了 X / Y / Z 证据源"** —— 让未来的接手者知道"作者当时确实查过,但没
找到",避免他们再来一次。

## 7 · Self-check(5 条 · 写完 plan.md 立刻自查)

1. **每个 bucket 都有一章**: Module Chapters 段的章数 == `buckets/_summary.json.bucketCount`。
   缺章 / 合并章 = fail(`>10k` 分卷例外:主卷覆盖 ~30 章,附录卷覆盖其余)。
2. **至少 3 条 Critical Path Trails**: Section N+2 必须有至少 3 张完整端到端
   `flowchart TD`。少于 3 张 = fail。
3. **每个 commit theme cluster 都有决策入口**: `commit-themes.md` 里如果有 ≥ 3 个
   "refactor:" / "decision:" 聚类,Section N+3 Decisions 必须至少列出对应数量的决策
   条目(或显式标"此聚类无明确决策证据,仅作样本归档")。
4. **Open Questions 非空**: archaeology 报告不允许把"不懂"藏起来。Section N+4 必须至少
   列出 3 条 open question,即使是"作者完成报告时已经清楚但未来读者可能不清楚"的事
   也写。空 Open Questions = fail。
5. **`>10k` 分卷规则被遵守**: 如果 size tier == `>10k`,plan.md 是否写了分卷计划?
   Coverage Annex 是否被升级为"分卷追溯"段?是否避免了声称"100% coverage"?

## 8 · Theme recommendation hint

archaeology profile 的**默认主题推荐 = `tufte`**(注意:与其他 profile 不同)。理由：

- archaeology 报告**信息密度极高**(完整文件树 / 完整 bucket 章 / 完整覆盖表),tufte
  的 data-ink 哲学 + 克制留白让长报告读起来不疲劳。
- archaeology 报告是**给未来翻账的**,tufte 的低装饰 / 高克制更经得起时间(不会过两年
  看起来"过时");terminal 的暗底徽章感更适合"当下决策",对归档语境略喧宾夺主。

**例外建议**：

- **terminal 也很合适**: 如果项目本身就是技术中台 / 工具 / 基础设施,terminal 的代码
  原生感和项目气质契合,选 terminal 也很自然。
- **press 不推荐**: press 的叙事 / 出版气质适合"读一本书",但归档报告更像"翻一本词典",
  press 在长篇查阅场景下会显得冗余。

## 9 · Cover composition starter(封面起手提示)

archaeology 封面的气质是 **"time capsule"** 或 **"knowledge vault"**,与 architecture
-review 的"判断锚点"、onboarding 的"欢迎气质"截然不同。推荐两种起手：

1. **Time capsule(时间胶囊)**: 主视觉用 SVG 画一个抽象的"时间轴" ——一条横线上等距
   分布若干圆点(代表 commit 时间分布),首尾两端标"<earliest commit date>" /
   "<latest commit date>";中央叠加项目名 + 主要贡献者头像位(用 `--ra-mono-display`
   小字代替头像,例如 `@yzt @abc @xyz`)。颜色用 `--ra-status-blue` + `--ra-terminal-fg-mute`。
2. **Knowledge vault(知识库金库)**: 主视觉是一组类似图书馆书脊的纵向矩形(每个矩形
   代表一个 bucket / 一章),用 `--ra-terminal-surface-2` 填色,书脊上用 `--ra-mono-display`
   小字写 bucket 名;最上方一行 `<project-name> · Archaeology Edition`。

封面文字层固定三段：项目名(`--ra-mono-display` 大字号)、副标题
`Codebase Archaeology · <date> snapshot · <reader>`、底部 colophon
`Made with [beautiful-codebase] · tufte theme`(选了 terminal 则改名)。

**特别要求**: 由于 archaeology 报告是"为未来"的,**封面必须显示创作日期**(精确到年月)
+ 主要贡献者列表 —— 半年后翻报告的人会用这两条信息判断"这份报告是什么时候写的、
谁写的"。

## 10 · 给 Plan SubAgent 的微调提示(写 plan.md 时的口诀)

- **完整性优先于可读性**: 在 architecture-review 里"简洁是美",在 archaeology 里"完整
  是美"。长表格不要折叠,Source Pointers 默认展开,Coverage Annex 全列。
- **每章按固定六段骨架写,不要"自由发挥"**: 章太多了(可能 30+ 章),固定骨架让读者
  形成肌肉记忆,翻到任何一章都知道往下找什么。
- **Decisions 段是核心**: archaeology 的真正价值在 Decisions —— 这是"业务规则"和"代码
  结构"之间最珍贵的连接组织。写 Decisions 不要懒,把每一个 commit theme cluster 都
  老实归纳。
- **Open Questions 不可耻**: archaeology 报告的诚实标志就是 Open Questions 非空。空了
  反而可疑(代表作者要么真的全懂、要么把"不懂"藏起来了 —— 前者罕见,后者常见)。
- **整篇语气保持"考古学家描述遗迹"**: 不评判("这个设计不好"),只描述("当年选择 X,
  原因见 commit `<sha>`,后来未再调整") —— archaeology 的读者要的是事实,不是观点。
- **写完每章就在 plan.md Outline 里 check off**: 章太多容易漏,plan.md Outline 段可以
  借鉴一个 checkbox 列表,每章一行,写完打勾。这不是强制要求,但实操中非常有用。

## 11 · Per-section / per-chapter 写作起手提示

- **01 Lead**: 第一段 caption 是整份报告最像"墓碑铭文"的部分 —— 一段不超过 80 字的
  自然语言描述,回答"这是谁的代码、什么时候、为什么、做的什么"。第二段列元数据
  (创作时间窗 / 主要贡献者 / git remote / 当前 sha / 工具 tier)。
- **02 File-tree Atlas**: 用 `<CodeBlock language="text">` 或一个长表格直接打印 inventory
  树。每行一句注释从 `business-evidence/docs.md` + `comments.jsonl` 文件首注释里抽取;
  抽不到就写"未注释"(诚实标注)。**禁止**为求好看简化树结构。
- **03 Business Domain Map**: 比 architecture-review 的同名节更完整 —— 即使关系不清
  也画,实体来源用 `business-evidence/schema.md` + `configs.md`(枚举常量)+ 模块命名
  三路融合。
- **04 Architecture Map**: 完整模块依赖图;过大时按子系统分页(可用 reacticle 的
  Pagination 组件)。每个节点带"章节链接"(`#05-NN-<bucket>`),让读者点击直接跳到
  对应 Module Chapter。
- **05..N Module Chapter** (每章固定六段):
  - **章首元数据**: 章号 + bucket scope + LOC + 主要贡献者(从 `git blame` 聚合到
    `business-evidence/`,或写"无 git 历史可推断")。
  - **职责**: 一段话(50-100 字)说"这个模块在系统里承担什么 + 业务上对应什么"。
  - **文件清单**: 表格 ——文件名 / LOC / 首行注释(若有) / 最近修改 commit。**禁止
    省略文件** —— 这是 archaeology 的关键。
  - **入口**: 本模块的入口符号 + `file:line`。如果是 library 模块没有入口,写"作为
    library 被 X / Y / Z 模块 import,无独立入口"。
  - **关系图**: 本模块对外依赖的 mermaid 子图,即使只有 2-3 个节点也画(画法见
    `references/component-policy.md`)。
  - **解释 + TODO**: 代码里发现的 TODO / FIXME / HACK 引述(逐条带 `file:line`),
    后跟"业务背景解释"段(如有)。无 TODO 就写"未发现 TODO 注释"。
- **N+1 Cross-cutting Concerns**: 按 7 项横切关注点(配置 / 日志 / 错误处理 / i18n /
  安全 / 鉴权 / 缓存)分子节,每子节回答"本项目如何统一处理 X" + "未统一处理的部分"。
  即使某项未实现也写"未检测到 X 的统一处理 —— 各模块各自实现 / 不存在"。
- **N+2 Critical Path Trails**: 每条 trail 写"路径名称 + 起点 + 终点 + 业务含义" +
  一张完整 `flowchart TD`(从入口控制器一直到数据库 / 外部 API 调用) + 几段说明关键
  环节。至少 3 条。
- **N+3 Decisions & Rationale**: 决策表 ——决策号 / 决策日期(从 commit / ADR 提取) /
  决策描述 / 引用证据 / 后续影响。每条决策 30-80 字。
- **N+4 Open Questions**: 列表 ——每条问题 1-2 句话,标注"我已尝试通过 X / Y / Z 解答,
  但仍未明朗"。
- **N+6 Coverage Annex**: 由 `scripts/audit/coverage.sh` 自动生成 + 主 Agent 在 Phase 5
  人工核对;`>10k` 分卷时此节注明分卷范围。

## 12 · 反面案例(本 profile 专属 · 禁止)

- **合并 bucket 章节**: 把 2 个 bucket 合并成 1 章("这两个 bucket 都和 auth 相关,
  合到一章") —— archaeology 必须**一桶一章**。
- **省略文件清单**: Module Chapter 的"文件清单"段省略"小文件 / 看起来不重要的文件" ——
  archaeology 要全。
- **Decisions 段空**: 写"本项目没有值得记录的决策" —— 除非 `commit-themes.md` 真的
  显示零聚类,否则必有 ≥ 3 条 decision-worthy commit。Decisions 空 = fail。
- **Open Questions 空**: 写"已完整理解项目" —— 这种话在 100 文件 +< 50 commits 的
  小项目里可能勉强成立,但 archaeology 报告通常涉及大项目;Open Questions 空几乎
  一定是"装作全懂"。
- **判断式语言**: 写"这个设计不好" / "应该重构" —— archaeology 不评判,只描述。
  评判性内容属于 architecture-review,跑错 profile 了。
- **`>10k` 单卷强行 100%**: 把 12k 文件的项目全部塞到一个 article.html(可能 20MB+)。
  必须分卷(见 §5)。
- **章节顺序漂移**: 第 5 章按"职责 → 入口 → 文件清单"写,第 8 章按"文件清单 → 入口 →
  职责"写 —— 30+ 章下读者会迷失。固定六段顺序贯穿全报告。
- **Cross-cutting 段静默跳过未实现项**: "本项目未涉及 i18n,本子节跳过" —— **禁止**。
  必须显式写"未检测到 i18n 的统一处理(扫描了 `<paths>`,未发现 i18n 相关 import /
  配置)" —— 让未来接手者知道作者查过。

## 13 · 已知 trade-off / 局限

- **报告极长 · 生成极慢**: archaeology 报告通常 1500-3000 行,生成时间是其他 profile
  的 2-3 倍(因为 Module Chapters 一桶一章,三阶段写 × N 章)。用户在 Checkpoint 1
  选 archaeology 前应被提示"生成时间会显著长于其他 profile"。
- **`>10k` 分卷的工程复杂度**: 主卷 + 附录卷的双 article 输出在 v0.1.0 是手动产物
  (主 Agent 跑两次 build);v0.2 可能加 `scripts/build-volume.sh` 一键化。
- **git blame 在 squash merge 后失真**: 大量 PR 走 squash merge 的项目,git blame 显示
  的"主要贡献者"都是 squash 提交者(通常是 maintainer),真实作者无法追溯。Lead 段
  的"主要贡献者"应该来源于 `git log --pretty=%an` 聚合,而不是单纯的 blame。
- **commit-themes.md 在 monorepo 子包里噪声大**: 如果项目是 monorepo 的子包,
  `commit-themes.md` 会聚到整个 monorepo 的主题,不全是本子包的。这种情形 Decisions
  段需要主 Agent 在 evidence 阶段额外筛选"涉及本子包路径"的 commit。
- **Cross-cutting 7 项目是欧美主流业务系统的清单**: 某些项目(嵌入式 / 游戏 / 算法库)
  的横切关注点完全不同(内存管理 / 帧率 / 数值稳定性)。允许 Plan 阶段按项目类型替换
  这 7 项,但替换后要在 plan.md Brief 段注明。

## 14 · 与其他 reference 的协作图

| 阶段 | 主要读 | 配套 | 落到 plan.md 的哪一段 |
|------|--------|------|------------------------|
| Brief · reader profile | 本文件 §1 / §4 / §6 | `information-density.md` §1(注意 `>10k` 时强制降到 70%) | Brief 的"Reader profile" / "信息保留比例" |
| Brief · `>10k` 分卷计划 | 本文件 §5 | (无) | Brief 的"分卷"行(`>10k` 时必填) |
| Outline · Module Chapters 段 | 本文件 §3 | `discovery/buckets/_summary.json` | Outline 表格(每 bucket 一章) |
| Outline · 业务-Job | 本文件 §6 | `business-evidence-collection.md`(尤其 commit-themes / schema / configs) | Outline 表格的"业务-Job" 列 |
| Theme | 本文件 §8 | `theme-selection.md` §3(archaeology 推 tufte) | Theme 段 |
| 封面 | 本文件 §9 | `cover.md` §3.5(time capsule)| Brief 的"封面" |
| Self-check | 本文件 §7 + 本文件 §12 | `plan-template.md` §D | (主 Agent 内联跑) |
| Checkpoint 1 推荐文案 | 本文件 §8 / §9 | `plan-template.md` §E | (Checkpoint 1 的开场说明段) |

## 15 · 一段最小可行 Outline 示例(供模仿)

下面是一份典型 `1k-10k` 文件中型项目的 archaeology Outline 骨架(N = 10 bucket),
**仅作示意**:

```
| #     | 标题 | 必/选 | 引用 bucket | 业务-Job | 期望长度 | 视觉块 |
|-------|------|-------|-------------|----------|----------|--------|
| 00    | Cover | 必 | (无) | time capsule · 创作时间 + 主要贡献者 | (封面) | SVG + 文字 |
| 01    | Lead | 必 | (无) | 一段 caption · 这是谁、什么时候、为什么、做的什么 | 50 | 元信息条 |
| 02    | File-tree Atlas | 必 | (全) | 完整文件树 + 每行一句注释 | 200 | 长 CodeBlock 或表格 |
| 03    | Business Domain Map | 必 | bucket-02-domain, bucket-03-order, bucket-04-payment | 完整业务实体 + 关系 | 80 | graph LR |
| 04    | Architecture Map | 必 | (全) | 完整模块依赖图 | 100 | flowchart TD |
| 05    | Module · bucket-01-cmd | 必 | bucket-01-cmd | CLI 入口承担运维任务,无对外业务 | 80 | 子图 |
| 06    | Module · bucket-02-domain | 必 | bucket-02-domain | 业务实体定义层,DDD aggregate | 120 | 子图 |
| 07-14 | Module · ... | 必 | bucket-03..bucket-10 | (每章一桶) | 80-200 each | 子图 |
| 15    | Cross-cutting Concerns | 必 | (横切) | 配置 / 日志 / 错误 / i18n / 安全 / 鉴权 / 缓存 | 150 | 横切关注点矩阵 |
| 16    | Critical Path Trails | 必 | (entry-point sniff + tests) | 至少 3 条端到端业务流程 | 150 | 3 张 flowchart TD |
| 17    | Decisions & Rationale | 必 | (commit-themes + ADR) | 当年为什么这么选 | 100 | 决策表 |
| 18    | Open Questions | 必 | (作者人工) | 显式列出未读懂的地方 | 50 | 列表 |
| 19    | Glossary | 选 | (项目术语) | 项目独有名词 / 缩写 / 黑话 | 60 | 术语表 |
| 20    | Coverage Annex | 必 | (全) | 100% inventory 覆盖追溯 | (脚本生成) | 1 张表 |
| 21    | Colophon | 必 | (无) | (无业务) | 5 | 文字 + 创作时间戳 |
```

总章数 = 21(基础)+ N(Module Chapters,本例 10) - 重复编号 = 21 章左右。
渲染后正文约 1500-2500 行。

如果是 `>10k` 项目,Outline 末尾追加一段"分卷计划":主卷覆盖 bucket-01..bucket-30
(按 `isEntryHeavy` + 业务核心模块筛选);附录卷覆盖其余 bucket 用压缩骨架(每章
30-50 行)。

---

> 本 profile 是 v0.1.0 的基线,也是三个 profile 里**最重的一个**。archaeology 报告
> 跑出来通常长 1500-3000 行,生成时间也最长(每个 bucket 一章,每章三阶段写)。
> 用户在 Checkpoint 1 选 archaeology 前,主 Agent 应该提醒一句"archaeology 是最完整
> 但也最长的 profile,生成时间约是其他 profile 的 2-3 倍,确认继续吗?"。
