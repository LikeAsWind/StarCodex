---
name: beautiful-codebase
description: "把任意代码项目（语言无关：Java / Python / Go / TS / Rust / …）做成一份**单文件 HTML 代码分析报告**——自包含、可离线打开、可分享。基于 reacticle 组件协议 + 三档工具回退（codegraph / rg / grep），运行 Phase 0 Intake → Discover → Plan → First Spread → Build → Review → Delivery 的小型 harness 流程。三阶段写作（Evidence → Business → Writing）从机制上断绝对未读源码的幻觉；Mermaid 主导可视化（Architecture / Call Chain / Business Domain）；ships 三类 reader profile 与 code-native 的 terminal 主题。触发场景：分析这个代码库 / 给这个项目做一份分析报告 / 给我一个项目架构总览 / 帮我写一份代码归档 / 我要交接这个项目，'analyze this codebase / build a beautiful codebase report / generate an architecture review of this repo / make a single-file HTML report for this project / reacticle codebase report'。只生成代码分析报告，不生成应用、dashboard、数据可视化产品。"
---

# Beautiful Codebase

## 背景原则

代码越复杂，输出媒介越重要。一份代码分析报告的价值，不在"我读过这套代码"，而在"我能让别人在 30 分钟里读懂它的架构、在第二天上手第一个 issue、或在交接半年后还能找回当时的决策"。HTML 在这件事上是无可替代的载体：可以同时承载 prose 解释、Mermaid 流程图、SVG 复杂度热图、可折叠的 Source Pointers、徽章化的风险矩阵、以及 Coverage / Freshness 这种结构性元数据。Markdown / PDF / Wiki 都做不到一次性把它们排在一份**自包含、断网可读、可分享**的页面里。

`beautiful-codebase` 是 `beautiful-article` 的姐妹 Skill：同样的 reacticle 脚手架、同样的主题系统、同样的 Cover / Colophon / PDF 导出，但**源**不再是 URL / PDF / DOCX 等编辑物料，而是一个真实的代码仓库；**产物**也不再是一篇通用文章，而是面向特定 reader（架构评审 / 新人入职 / 交接归档）的项目分析报告。

整套 Skill 的核心约束是：**这是一份关于真实代码的报告，不能编造**。所有反幻觉机制都围绕这一点构建：inventory of record、三阶段写、claim audit、coverage audit、freshness audit。

## 边界（先判断要不要进这个 Skill）

- 最终主产物是 **single-file HTML 代码分析报告**，不是网页应用 / dashboard / 代码可视化工具 / 文档站。
- 报告可以有 Raw 自由层（SVG 热图、复杂封面、复杂时序图），但**必须服务阅读、解释、论证、节奏或审美**——不是装饰。
- **不**生成：在线 Q&A bot、IDE 插件、live 文档站、CI 集成 / pre-commit hook、内部知识库平台、AI illustration。
- **不主动**对目标项目做任何写入，唯一例外是 Phase 0 用户显式同意时跑 `codegraph init` 写 `.codegraph/`。
- 分析深度由用户在 Checkpoint 1 选 reader profile 决定；默认是"first-look 架构总览"，不是逐行代码审计。

如果用户要的是"把这个项目改造一下" / "写个新功能" / "做个 dashboard 看代码指标"——停下来澄清，不要进入本 Skill。

---

## 工作流总览（v0.1.0 · 6 Phase + 3 Checkpoint）

```
Phase 0  Intake             判断是否进入 Skill + 捕获目标项目路径 + 工作区位置 + 目标语言
   ▼
Phase 1  Discover           工具 tier 探测 → (可选) codegraph init →
                            扫描 inventory + buckets + business-evidence + brief
                            自动选 size tier；> 10k 时建议 reader profile 降级
   ▼
Phase 2  Plan               一份 plan/plan.md (Brief / Outline / Theme / Assets)
                            Outline 自检：100% inventory 覆盖（assigned 或 annexed）
   ▼              ★ Checkpoint 1  逐项确认 5 件事：
                                 reader profile / theme / 版式宽度 / 配图模式 / 封面
                                 （信息保留比例打包进 reader profile 标配）
   ▼
Phase 3  First Spread       封面（若开） + 首屏 + 第一节（脚手架在此创建）
                            First Spread Reviewer SubAgent → review/first-spread-review.md
   ▼              ★ Checkpoint 2  逐项确认 2 件事：验收结论 / 开发模式 A 或 B
   ▼
Phase 4  Full Build         所有剩余 Section，按选定模式（A 单 Agent · B 多 Agent）执行
                            每节走三阶段：Evidence → Business Distillation → Writing
                            每节后跑 Section Reviewer SubAgent（消息返回 pass/fail）
   ▼
Phase 5  Review & Repair    三视角终审 + Coverage 审计 + Freshness 审计 + Code-Density 审计
                            → review/final-review.md；最小切片修复
   ▼              ★ Checkpoint 3  交付决策：HTML 单导 / HTML+PDF 双导 / 局部再修 / 暂停
   ▼
Phase 6  Delivery           构建 article.html（自包含单文件）+ analysis-snapshot.json
                            可选：html-to-pdf.sh → article.pdf
```

工作区结构（脚手架创建；这些文件是 Skill 的长期记忆，**不要只依赖聊天上下文记决策**）：

```text
<project-name>-analysis/                        # 默认在调用目录下，**不写进目标项目**
  discovery/
    tools.json                                  # tier 探测结果
    tier.json                                   # < 100 / 100-1k / 1k-10k / > 10k
    inventory.json                              # 真值集：path / lang / bytes / sha / excluded_reason
    buckets/NN-<slug>.json                      # ~5k LOC / bucket
    business-evidence/
      comments.jsonl  tests.jsonl  schema.md
      configs.md      docs.md      commit-themes.md
    codebase-brief.md                           # ~200 行的项目速览
    complexity.jsonl                            # Section 07 数据
  plan/
    plan.md                                     # Brief / Outline / Theme / Assets + business-job
  article/
    Cover.tsx  Article.tsx                      # Article.tsx 是 assembler，主 Agent 拥有
    sections/
      NN-<slug>.tsx                             # 渲染 prose（Step B 输出）
      NN-evidence.md                            # Step A 输出
      NN-business.md                            # Step A.5 输出
    raw-blocks/                                 # SVG 热图 / 复杂封面隔离到这里
    assets/
    article.html                                # 主交付物
    article.pdf                                 # 仅 Checkpoint 3 选 PDF 时才有
  review/
    first-spread-review.md                      # Phase 3 产物
    final-review.md                             # Phase 5 产物
    repair-log.md                               # 仅有修复时
  analysis-snapshot.json                        # 工具版本 / SHA / 时间戳 / inventory diff
  index.html  package.json  vite.config.ts  tsconfig*.json   # 构建工装
```

---

## 硬性质检协议（贯穿整个 Skill）

**质检方式按节点区分 —— 不是所有质检都开 SubAgent，也不是所有质检都写文件。** 误开
SubAgent / 误写文件是首要性能问题；下表严格执行：

| 节点 | 质检方式 | 产物 | 为什么 |
|---|---|---|---|
| **Phase 1 Discover** | 主 Agent 内联 5 条 checklist | 无文件 | tools / inventory / tier 都是机器写的，主 Agent 通读自查即可 |
| **Phase 2 Plan / Checkpoint 1 前** | **主 Agent 内联自查 + Outline 自检三铁律**（禁止开 SubAgent） | 无文件 | plan 是文字决策且 200-400 行；上下文是热的，SubAgent 冷启反而更慢 |
| **Phase 3 First Spread / Checkpoint 2 前** | First Spread Reviewer SubAgent（封面 5 条 + 第一节 5 条） | `review/first-spread-review.md` | 首屏定调；多一道独立眼睛更稳 |
| **Phase 4 每个 Section** | Section Reviewer SubAgent（claim audit + verbatim re-grep + 业务引用核查 + 代码密度审计） | **以消息返回 pass/fail + 修复点（不写文件）** | 一份报告可能 7-15 节，N 份 review 文件无人再读 |
| **Phase 5 终审 / Checkpoint 3 前** | Editorial + Visual + Technical Reviewer SubAgent | `review/final-review.md` | 交付物的一部分，留档有价值 |
| **Phase 5 全局审计** | Coverage / Freshness / Code-Density 三脚本（`scripts/audit/*.sh`） | 审计输出嵌入 article footer + final-review.md | 这些是机制化检查，跑脚本而非问 Agent |

**铁律：**

1. **Plan Checkpoint（Phase 2 → Checkpoint 1）严禁开 SubAgent 做质检**。主 Agent 写完
   `plan/plan.md` 后**就地**对照清单（见 `references/review-checklist.md` 的 Plan 自查段）
   核查、按结论改完 `plan/plan.md`，**不要写任何 review 文件**，然后进入 Checkpoint 1。
2. First Spread / Final 必须用 SubAgent；只有探测不到 SubAgent 环境才由主 Agent 兜底，
   并在文件首注明"无 SubAgent 环境，主 Agent 兜底"。
3. Section Reviewer 用 SubAgent，但**返回值是消息**（pass / fail + 修复点）；fail 项主
   Agent 收到后直接修，**不要让 SubAgent 写 `review/section-NN-review.md` 文件**。
4. **Step B Writing SubAgent 物理隔离 repo 访问**——这是反幻觉的最后防线。Writing
   SubAgent 的 prompt 模板里只允许读 `NN-evidence.md` + `NN-business.md` 两个文件，
   主 Agent 创建该 SubAgent 时**禁止**透传任何文件搜索 / 读取 repo 的工具。
5. 拿到任何质检结论 —— **先按 fail 项把产出改完，再汇报"做完了 + 自检结论 + 改了什么"**。
   直接拿原始结论汇报但不修复 = 违规。
6. **决策收集铁律 · 禁止静默替用户选择**：在每个 Checkpoint（1 / 2 / 3），所有需要用户
   确认的决策项**必须每项独立列出 + 等用户答复**。Agent **可以推荐**（"我推荐 X，因为 …"），
   但**不能"已经替你定了 X，如果不对再说"** —— 这等于剥夺选择机会。
   - **优先**：如果环境有 `AskQuestion` 工具，每个决策项作为一个独立 question（一次调用
     可传多个 question），用户能用选择卡逐项确认。
   - **否则**：停下来在消息里把所有问题**编号列出**（每个问题独占一段、写清推荐项 + 理由
     + 备选项），明确说"我等你逐项答复后再继续"，**不要继续做任何后续工作**。
   - **绝不**：把多项决策打包成一个"全选我推荐的 / 全部 OK 吗？"yes/no 问题；也不要在
     "推荐一句话"后默认直接进下一步。
7. **`codegraph init` 决不静默执行**——它会向目标项目写 `.codegraph/`。属于"medium-risk
   写"，必须在 Phase 0 给出 3 选项让用户决定。详见下文 Phase 0。

各节点的 checklist 与 SubAgent prompt 模板见 `references/review-checklist.md`。

---

## 各阶段文件读取指南（渐进加载，别一次全读）

| 阶段 | 必读 | 按需查 |
|---|---|---|
| **Phase 0 Intake** | `references/harness.md` | —— |
| **Phase 1 Discover** | `references/discover.md` · `references/bucket-strategy.md` · `references/business-evidence-collection.md` · `references/entry-point-taxonomy.md` · `references/complexity-tools.md` | `scripts/probe-tools.sh` · `scripts/discover/*.sh` |
| **Phase 2 Plan** | `references/plan-template.md` · `references/theme-selection.md` · `references/layout.md` · `references/information-density.md` · `references/asset-policy.md` · `references/cover.md` · 选定 reader profile `references/profiles/<id>.md` | `theme-profiles/index.json` · `theme-profiles/<id>.md` |
| **Phase 3 First Spread / Phase 4 Build（每节回看）** | `references/section-build.md` · `references/component-policy.md` · `references/raw-policy.md` · `references/source-pointers.md` · 选定主题 `theme-profiles/<id>.md` · **封面：`references/cover.md`** | `references/scaffold.md`（建项目时一次） · `references/html-output.md` |
| **Phase 5 Review & Repair** | `references/review-checklist.md` · `references/repair-policy.md` | `scripts/audit/*.sh` |
| **Phase 6 Delivery** | `references/html-output.md` | `references/pdf-output.md`（仅当用户选 PDF 导出） |

## Reader Profiles · 三种读者模型（v0.1.0 全部 fully fleshed）

`beautiful-codebase` 的 reader profile 是 Checkpoint 1 的核心决策项之一。三种 profile 对应
三种真实使用场景，**v0.1.0 全部 ship**——不是"先做一个其它 v0.2"。每个 profile 决定：

- 必选 / 可选 Section 的清单
- 标配信息保留比例
- 视觉密度（流程图 / 徽章 / 表格的比例）
- 默认主题搭配
- Source Pointers 是 collapsed 还是 expanded
- Plan 自检的"业务-Job"严格度

| Profile | 一句话使命 | 必选 Section | 标配保留 | 默认主题 | 详见 |
|---|---|---|---|---|---|
| `architecture-review` | senior eng / 架构师 30 分钟做出"值不值得继续投入 / 哪里有结构性风险"判断 | Cover · 01 Verdict · 02b Business Domain · 03 Architecture Map · 04 Module Walk · 08 Risks · 11 Coverage Annex · 12 Colophon | ~80% | terminal | `references/profiles/architecture-review.md` |
| `onboarding` | 今天读完，明天上手 ship 第一个 issue | Cover · 01 What this codebase does · 02 Project at a Glance · 04 Module Walk · 05 Entry Points · 12 Colophon | ~65% | terminal · 也合 press | `references/profiles/onboarding.md` |
| `archaeology` | 交接 / 归档 / 半年后还能找回决策 | Cover · 01 Verdict · 02 Project at a Glance · 02b Business Domain · 03 Architecture Map · 04 Module Walk · 08 Risks · 09 Decisions That Matter · 11 Coverage Annex · 12 Colophon | ~100% / >10k 强制 ~70% | terminal · 也合 tufte | `references/profiles/archaeology.md` |

**Section 编号体系**（13 节，v0.1.0 锁定，可选项由 Plan 自动决定 / 用户在 Checkpoint 1
覆盖）：

```
00  Cover                      所有 profile 默认开
01  Verdict                    所有 profile 必选；onboarding 重命名为 "What this codebase does"
02  Project at a Glance        必选 onboarding / archaeology；可选 architecture-review
02b Business Domain Map        必选 architecture-review / archaeology
03  Architecture Map           必选 architecture-review / archaeology
04  Module Walk-through        所有 profile 必选
05  Exposed Entry Points       必选 onboarding；可选其他
06  Tech Stack Audit (CVE)     可选 (architecture-review / archaeology)
07  Code Health Heatmap        可选 (architecture-review / archaeology)
08  Risks & Hot Spots          必选 architecture-review / archaeology
09  Decisions That Matter      必选 archaeology；可选 architecture-review
10  Open Questions             可选所有
11  Coverage Annex             必选 architecture-review / archaeology；onboarding 短版
12  Colophon                   不可移除（继承 beautiful-article）
```

## Phase 0 —— Intake

判断是否进入本 Skill；捕获目标项目路径、工作区位置、目标语言、（可选）git remote。

| 用户给的东西 | 该做的 |
|---|---|
| 一个代码项目路径（绝对 / 相对 / "当前目录"） | 进入 Phase 1 |
| "帮我分析一个项目"但没给路径 | **反问**：要 path。Skill 不能凭空挑项目。 |
| 明显要的是改代码 / 加功能 / 跑工具 | 停下来澄清，不进入本 Skill |
| 多个项目（monorepo 跨包；或多个独立 repo） | v0.1.0 一次只处理一个 repo；让用户挑一个或先聚焦一个 |

**捕获目标语言**：开场就记录用户**期望的最终报告语言**。

- 用户**未指定** → 默认 **Chinese prose + English code identifiers**（见 Q9）。Prose / 解释 /
  业务背景用中文；代码标识符 / 文件路径 / 命令 / API 名 / 库名 / 错误信息 / 日志 verbatim
  英文不翻译。
- 用户**指定**了"全部英文 / 全部中文 / 双语" → 记进 `plan/plan.md` Brief 段；Phase 4 写
  作时遵守。

**捕获 git remote**：尝试 `git remote get-url origin`；如成功且是 GitHub（最常见），记下
`<owner>/<repo>` + 当前 SHA，用于 Phase 4 Source Pointers 自动渲染可点链接（详见
`references/source-pointers.md`）。其它平台（GitLab / Bitbucket）按各自 URL 规则；抓不到也
没事，Source Pointers 退化成纯文本 file:line。

**工具 tier 探测 + codegraph init 决策**：在 Intake 末尾跑 `scripts/probe-tools.sh`，把
结果（codegraph 是否安装 / `.codegraph/` 是否存在 / rg / grep 版本）暂记。

- `.codegraph/` 存在 → tier = `codegraph-indexed`，悄悄进 Phase 1，不打扰用户。
- codegraph 已装但 `.codegraph/` 不存在 → tier = `codegraph-installed`，**必须**给用户 3 选项：
  ```
  目标项目没有 codegraph 索引（.codegraph/ 不存在）。要让分析最准确，建议现在跑一次 codegraph init（约 30 秒到几分钟，会向项目写一个 .codegraph/ 目录）。请选：
    A · 现在跑 codegraph init（推荐 · 精度最高）
    B · 不用，降级到 rg（更快，精度略降）
    C · 我自己稍后跑，到时再回来；现在停下
  ```
  **绝不静默执行 `codegraph init`**——属于 medium-risk 写。用户选完才动。
- codegraph 未装 / 仅 rg → tier = `rg`，进 Phase 1。
- 仅 grep → tier = `grep`，进 Phase 1，提示精度会下降。

**工作区位置**：默认 `./<project-name>-analysis/`（在调用 shell 当前目录，不写进目标项目）。
用户可在 Intake 自由文本覆盖（"放进 .beautiful-codebase/" 等）。

自检：用户要的是**报告**还是**代码改造**？目标项目路径有没有捕获到？工作区路径会不会
误写进目标项目？git remote / 目标语言 / 工具 tier 都记下了吗？

---

## Phase 1 —— Discover

把目标项目从"一坨源码"变成"一份可信清单 + 一组按需读的证据底座"。详见 `references/discover.md`。

四件主要工作：

1. **Inventory of record** → `discovery/inventory.json`：枚举每个分析中的文件
   `{path, language, bytes, sha}`；排除文件带 `excluded_reason`（vendored / generated /
   fixtures）。优先用 `codegraph files`，否则用 `git ls-files` + `file --mime` 推断语言。
2. **Buckets** → `discovery/buckets/NN-<slug>.json`：按 `references/bucket-strategy.md`
   切到 ~5k LOC / bucket。size tier 自动选择（`<100 / 100-1k / 1k-10k / >10k`）写入
   `discovery/tier.json`。
3. **Business evidence** → `discovery/business-evidence/`：6 个文件 (`comments.jsonl` /
   `tests.jsonl` / `schema.md` / `configs.md` / `docs.md` / `commit-themes.md`)，规则
   见 `references/business-evidence-collection.md`。这是 Step A.5 的燃料——没有这一步，
   business 段只能瞎编。
4. **Codebase brief** → `discovery/codebase-brief.md`：~200 行的项目速览（语言占比 / LOC /
   top 模块 / 提交节奏 / 贡献者 / 关键入口文件）。这是 Phase 2 Plan 的入口阅读。

可选：

5. **Complexity** → `discovery/complexity.jsonl`：按 `references/complexity-tools.md` 探测
   各语言可用工具，跑 CC 数据。Section 07 用。
6. **Entry points** → 按 `references/entry-point-taxonomy.md` 跑跨语言入口扫描，结果留
   在 inventory 元数据里，Phase 4 Section 05 的 Evidence SubAgent 会重新精扫。

**>10k 文件强制规则**：Phase 1 末尾若 `tier == ">10k"`，主 Agent 必须在进 Phase 2 前
显式提示用户："本项目规模 > 10k 文件，强制推荐 reader profile 降级到 archaeology · 70%；
Coverage Annex 强制开启；本报告不会声称 100% coverage。" 用户可在 Checkpoint 1 选回
其它 profile，但 70% 上限不可突破。

Phase 1 末尾主 Agent 内联自查：tools.json / inventory.json / business-evidence/ / brief /
tier.json 五件齐全 → 进 Phase 2。

---

## Phase 2 —— Plan

形成编辑方案，**不直接写 HTML**。**只产出一份 `plan/plan.md`**（四段 + 业务-job 行），
模板见 `references/plan-template.md`：

- **Brief**：reader profile / 标配信息保留比例 / 必须保留 / 可删减 / 语气 / 主要观点 /
  阅读目标 / 目标语言 / 版式宽度 / TOC / 配图策略 / **工具 tier · 尺寸 tier · git
  remote**。
- **Outline**：每节五行——编号 + 名称 + 引用 bucket + **业务-Job** + 必须保留信息 +
  是否需要 Mermaid / Table / CodeBlock。Outline 严守"100% 覆盖三铁律"：
  1. 每个 inventory 模块目录都被某 Section 认领或写进 `Coverage Annex`。
  2. 每节业务陈述必须能引用 evidence 或显式标"业务背景未知,本节只做技术解释"。
  3. Outline 出现的模块名必须存在于 inventory（防止编造模块）。
- **Theme**：从 `terminal / tufte / press` 三选一 + 理由 + 与 reader profile 的契合度。
- **Assets**：本 Skill 默认 `none`——Mermaid 才是主视觉。其余三种（user-assets /
  placeholders / ai-generated）按 `references/asset-policy.md`。

**自检方式 · 强约束**：写完 `plan/plan.md` 后由**主 Agent 内联**对照 5 条 Plan 自查清单
核查（见 `references/review-checklist.md` 的 Plan 自查段），按结论改完 `plan/plan.md`，
**直接进入 Checkpoint 1，禁止开 SubAgent，禁止写 `review/plan-review.md`**。

---

## Checkpoint 1 · Plan（★硬节点 · 必须停）

**铁律：禁止静默替用户选择。每个决策项独立列出、独立等用户答复。**

**5 项独立确认**（缺一不可）：

| # | 决策项 | 选项 | 备注 |
|---|---|---|---|
| 1 | **reader profile**（信息保留比例打包在内） | `architecture-review · ~80%` / `onboarding · ~65%` / `archaeology · ~100%`（>10k 时 ~70%） | AI 推荐一个并写一句理由。比例不再单独成题；想偏离用自由文本覆盖（"architecture-review 但只要 50%"） |
| 2 | **主题** | `terminal`（默认 · code-native）/ `tufte`（学术 / 研究）/ `press`（CMS / 内容） | AI 默认推 `terminal`；项目偏学术或编辑系统时换 |
| 3 | **版式宽度** | `narrow / regular / wide / full` | 默认 `regular` |
| 4 | **配图模式**（必选 · 不允许"默认通过"） | `none / user-assets / placeholders / ai-generated` | 默认 `none`，因为 Mermaid 是主视觉 |
| 5 | **封面** | `开`（默认）/ `关` | AI 推 "开" 并给一句构图想法（推荐"模块拓扑骨架 SVG"作为 terminal 主题封面起手） |

TOC 默认开（一句话带过即可，不必单独成题）。语言 / 编辑删减允许 / 是否先看首屏样张 走默认。

**Checkpoint 1 开场消息模板**（在收集决策前先发一条说明）：

```
plan/plan.md 已经写好（自检通过）。我会逐项跟你确认 5 件事：reader profile / 主题 / 版式宽度 / 配图模式 / 封面。

我的推荐先放在这里供参考（不会替你选）：
- reader profile：<X>（含标配保留 <Y%>。理由：…）
- 主题：<theme>（理由：…）
- 版式宽度：<width>（理由：…）
- 配图模式：<策略>（理由：…）
- 封面：开 / 关（理由：…；若开，构图想法：…）

默认走但你可以推翻：语言（中文 prose + 英文标识符）；TOC 开；接下来会先做首屏样张。
信息保留比例如要偏离 profile 标配，下面回答完直接告诉我具体百分比。

下面逐项请你确认。
```

发完上面这条说明后，**立刻**用 AskQuestion 传 5 个 question（或在无工具环境下编号列出
5 个问题、停下等答复）。**5 项全部收齐答复才能进 Phase 3**。

---

## Phase 3 —— First Spread

先做"封面（若开） + 首屏（Hero / Lead / TOC） + 第一节 + 一个代表性 Mermaid 块"。
**脚手架在这里创建工作区**（详见 `references/scaffold.md`）：

```bash
# 默认开封面
bash <skill>/scripts/scaffold.sh ./<project>-analysis --theme=terminal
# Checkpoint 1 用户选了"封面 · 关"
bash <skill>/scripts/scaffold.sh ./<project>-analysis --theme=terminal --no-cover
bash <skill>/scripts/scaffold.sh --list-themes
```

它创建 Vite + React + TS 工作区（从 npm 安装 `reacticle` 最新发布版）+ `discovery/ plan/
review/` 记忆目录 + assembler `article/Article.tsx` + 一个示例 section 组件
（+ 默认 `article/Cover.tsx`，除非 `--no-cover`）。

**第一节用什么**：按 reader profile 选——`architecture-review` / `archaeology` 用 01 Verdict，
`onboarding` 用 01 What this codebase does。第一节走完整三阶段（Evidence → Business →
Writing），它是后续所有 Section 的模板锚点。

**第一个 Section 完成后，按硬性质检协议创建 First Spread Reviewer SubAgent**，写
`review/first-spread-review.md`（含**封面 5 条自检** + **第一节 5 条自检**），按 fail
项改完，再进 Checkpoint 2。

---

## Checkpoint 2 · First Spread（★硬节点，必须停）

让用户验收首屏 + 第一个 Section，**并选定后续开发模式**。同样适用 Checkpoint 1 的决策
收集铁律：**两项独立确认，禁止打包；优先 AskQuestion，无工具则编号列出、停下等答复**。

先发一条简短消息：

```
首屏 + 第一个 Section 做好了，npm run dev 在 localhost 预览。
质检结论见 review/first-spread-review.md（已按 fail 项改完，列出修了哪些）。
下面两件事请你独立确认：1) 验收结论 2) 后续开发模式。
```

然后用 AskQuestion 传**两个独立 question**：

1. **验收结论** —— `通过 · 进入完整生成` / `局部修改 · 我会另起一条说改哪里` /
   `主题或版式不合适 · 回到 Checkpoint 1`。
2. **后续开发模式** —— `A · 单 Agent 顺序（默认 · 最稳 · 风格最统一）` /
   `B · 多 Agent 并行（最快 · 风格轻微差异）`。

**不要把这两件事打包成"通过 + A，OK 吗？"**——用户可能"通过验收但想用 B"或反之。
两题都收齐答复后进入 Phase 4。

---

## Phase 4 —— Full Build（三阶段写）

按 Checkpoint 2 选定的开发模式生成完整报告。详见 `references/section-build.md` +
`references/component-policy.md` + `references/raw-policy.md`。

**三阶段写 · 每节强制流程**（每个 Section 都走一遍）：

```
Step A · Evidence SubAgent
   输入：bucket + tier + reader profile
   输出：sections/NN-evidence.md（verbatim 源码 + codegraph/rg/grep 查询结果）
   每段引用 file:line-line；不写 prose
   
Step A.5 · Business Distillation SubAgent  ←  beautiful-codebase 独有
   输入：NN-evidence.md + discovery/business-evidence/
   输出：sections/NN-business.md（每条业务陈述带 [证据: file:line] 引用 + 显式"未知"段）
   confident-tone 无引用 = 失败
   
Step B · Writing SubAgent  ←  反幻觉物理隔离
   输入：NN-evidence.md + NN-business.md（仅此两份，禁止 repo 访问）
   输出：sections/NN-<slug>.tsx
   遵守 Q9b 替换优先级：prose → mermaid → table → inline → block
```

**铁律 · 每个 Section 必须是独立组件文件**（`article/sections/NN-*.tsx`），**坚决不允许把
多个 Section 直接写进一个组件**。`article/Article.tsx` 只是 **assembler**：import 并排序各
Section，由**主 Agent 拥有**。大型 Raw 同样隔离到 `article/raw-blocks/NN-*.tsx`。文件级
隔离是多 Agent 并行的前提，也是单节失败可单点重跑的前提。

开发模式（Checkpoint 2 选定）：

- **A · 单 Agent 顺序（默认）**：主 Agent 顺序对每节跑三阶段，最稳、风格最统一。
- **B · 多 Agent 并行**：subagent 各拥**一个** Section 文件并行开发；**主 Agent 负责合并
  与稳定性**——维护 `Article.tsx` 的 import 与顺序、跑 `npm run typecheck` / `build`、
  兜底主题与风格一致、解决冲突。每节内部仍走三阶段。

**Section Reviewer SubAgent**（每节完成后跑）：5 项 claim 回溯 + verbatim re-grep + 业务
引用核查 + 代码密度审计 + 与前后衔接。**消息返回 pass/fail + 修复点**（pass 则一行 OK；
fail 则列出修复点），**不写 `review/section-NN-review.md` 文件**。主 Agent 收到 fail 项
后**直接修对应 section 文件**，然后再汇报本节交付。

**Mermaid 重点 Section**：
- **Section 02b Business Domain Map**：单张 `graph LR`，业务实体 + 关系，颜色取自
  terminal 主题的 §4.3 class（`controller / consumer / middleware / risk / business`）。
- **Section 03 Architecture Map**：模块依赖图，节点对应 Outline 的 Section 编号。
- **Section 05 Exposed Entry Points**：每个入口一张 `flowchart TD`，`subgraph 业务: <name>`
  包裹，节点 class 走 `references/entry-point-taxonomy.md` 的 9 类角色。

---

## Phase 5 —— Review & Repair

三视角终审 + 三脚本审计 + 最小切片修复。完整清单见 `references/review-checklist.md` +
`references/repair-policy.md`。

**三视角终审**（必须用三个独立 SubAgent；无 SubAgent 环境时主 Agent 兜底并在文件首注明）：

1. **Editorial Reviewer**：报告性、信息取舍、reader profile 是否被尊重、Business-Job
   是否有引用。
2. **Visual Reviewer**：主题统一、徽章只用 terminal 主题的 5 种状态色、Mermaid 不出主题
   token、移动端可读。
3. **Technical Reviewer**：构建无错、控制台无警告、Code-Density 在 Q9b 上限内、可访问性、
   Source Pointers 链接正确。

**三脚本审计**（脚本，非 SubAgent）：

- **Coverage Audit** (`scripts/audit/coverage.sh`)：每个 inventory 文件路径必须出现在某
  `evidence.md` 或 Coverage Annex；缺一即 fail。
- **Freshness Audit** (`scripts/audit/freshness.sh`)：重新跑 `codegraph status` /
  `git ls-files`，diff 原始 inventory，把快照时间戳 + diff 摘要嵌入 article footer。
- **Code-Density Audit** (`scripts/audit/density.sh`)：每节 block-count/paragraphs ≤ 0.15、
  lines/block ≤ 8、code-char share ≤ 15%；超限 fail。

**红线**：它仍是一份**报告**（不是应用 / dashboard）· reader profile 标配被尊重 · 必须保留
的信息没丢 · 主题气质统一 · Raw / Mermaid 无野生样式 · 业务陈述都有引用或显式"未知" ·
桌面 + 移动端可读 · HTML 可构建可打开可分享。

**修复**：按最小单位修复（Section / Raw block / Mermaid chart 为最小单位）。**禁止**：只
反馈一处就重写整篇 / 为修视觉改动已确认的 outline / 为压缩信息删掉用户必须保留的内容。
**有修复才写** `review/repair-log.md`（无修复 / 一次过则不写）。

---

## Checkpoint 3 · Final（★交付确认 · 必须停）

终审改完后，**停下来**让用户独立确认交付决策。优先 AskQuestion，无工具则在消息里编号
列出问题、停下等答复。

- **交付决策** —— `通过 · 导出 HTML 交付` / `通过 · 同时导出 HTML + PDF` /
  `还有局部修复 · 我会列出具体修哪里` / `先停一停 · 我要再看看`。

只有这一项决策，但**仍要主动停下来问**，不要静默走默认导出 HTML。

---

## Phase 6 —— Delivery

构建并交付（命令见 `references/html-output.md`）：

- `article/article.html`（自包含单页，CSS + JS 内联，断网可打开）—— **主交付物**。
- `analysis-snapshot.json`（必出）：工具版本 / codegraph SHA / 时间戳 / inventory diff
  摘要 / reader profile / theme / coverage 百分比 / freshness diff。
- **可选** `article/article.pdf`：仅当 Checkpoint 3 用户选了"通过 · 同时导出 HTML + PDF"
  时才生成。命令：
  ```bash
  bash <skill>/scripts/html-to-pdf.sh
  ```
  脚本探测系统已装的 chromium-family 浏览器，注入 `@media print` 覆盖（TOC 从左右栅格塌成
  上下排布、TOC 独占首页、Section 05 长流程图分页），headless 打印。零 npm 依赖。详细原理 /
  故障排除见 `references/pdf-output.md`。
- 简短编辑说明：reader profile / 信息保留比例 / 主题 / 工具 tier / 主要编辑取舍 /
  Coverage 数字 / Freshness 数字。

---

## 默认策略

- **输出**：single-file HTML 报告；reader profile 默认建议 `architecture-review · 80%`，
  按 inventory 的 size tier 与项目语义自动调整推荐。
- **语言**：默认 **Chinese prose + English code identifiers**——prose / 解释 / 业务背景用
  中文；代码标识符 / 文件路径 / 命令 / API 名 / 库名 / 错误信息 / 日志 verbatim 英文不
  翻译；角色 tag 双语（如 `控制器方法 (Controller)`）。Phase 0 用户自由文本可覆盖
  （全英 / 全中 / 双语）。
- **工具 tier**：自动探测 → `codegraph-indexed` → `codegraph-installed` → `rg` → `grep`；
  `codegraph init` 决不静默执行。
- **主题**：默认 `terminal`（code-native，暗底等宽 + 语义状态色）。证据密集学术项目推荐
  `tufte`；编辑 / 内容业务推荐 `press`。所有都在 Checkpoint 1 确认。
- **版式**：宽度默认 `regular`、**TOC 默认开**（详见 `references/layout.md`）。
- **配图（Asset）**：默认 `none`——本 Skill 用 Mermaid 做主视觉，外部图很少需要。Checkpoint 1
  必选项。
- **代码密度（Q9b）**：prose 优先、`<Code inline>` 鼓励大量使用、`<CodeBlock>` 默认禁、
  每节最多 1 块（Section 04 / 05 例外允许 ≤ 2 块），每块 ≤ 8 行；替换优先级 prose → mermaid
  → table → inline → block。Section Reviewer 强制密度审计。
- **Mermaid**：所有架构 / 调用链 / 业务实体图默认 Mermaid；SVG 仅留给 Cover 与 Section 07
  复杂度热图。
- **业务证据**：每条业务陈述必须 `[证据: file:line]` 引用，否则归"业务背景未知/不充分"
  子节；禁止 confident-tone 无引用。
- **三阶段写**：Evidence SubAgent → Business SubAgent → Writing SubAgent；Writing 物理
  隔离 repo 访问。
- **质检**：Plan 内联自查（无 SubAgent / 无文件）· First Spread 与 Final 用 SubAgent +
  写文件 · Section 用 SubAgent + 消息返回 + 不写文件 · 三脚本审计（Coverage / Freshness /
  Density）。
- **决策收集**：Checkpoint 1 / 2 / 3 每项独立确认 · 禁止静默替用户选择。可推荐，不能跳过。
- **修复**：最小切片，有修复才写 `review/repair-log.md`。
- **Colophon · 不可移除**：scaffold 在 `article/Article.tsx` 末尾自带 colophon Raw 块
  （`Made with [beautiful-codebase] · <主题> theme`）。每份报告必须保留，禁止删除、禁止
  移到 Hero 旁边或浮动到角落。切换主题时同步更新 colophon 里的主题名 + `main.tsx` 的
  `<ThemeProvider theme="...">` 两处。
- **封面 · 默认开 · 必须图文并茂**：scaffold 默认在 `article/Cover.tsx` 创建屏幕 3:4 +
  PDF 独占首页的书封式题图外壳。Phase 3 主 Agent 把 `<CoverPlaceholder />` 替换为按
  reader profile + 主题定制的图 + 字构图。**硬约束**：外壳比例 / 打印分页不可动、必须有
  视觉元素 + 文字、只用 `--ra-*` token、不要远程图、不要重复 Hero。详见 `references/cover.md`。
- **PDF 导出 · 可选**：主交付物始终是 `article/article.html`。**仅当** Checkpoint 3 用户
  选了"HTML + PDF"才跑 `html-to-pdf.sh`；不选则不动。不要替用户默认导。
- **工作区位置**：默认 `./<project>-analysis/`；用户在 Phase 0 可覆盖；**不写进目标项目**。
- **>10k 文件强制规则**：reader profile 推荐降级到 `archaeology · 70%`；Coverage Annex
  强制开；禁止声称 "100% coverage"。

---

## 成功标准

- 它**首先是一份关于真实代码的报告**——不是应用、不是 dashboard、不是 pitch deck。
- **没有幻觉**：每条技术陈述都能在某 NN-evidence.md 找到 verbatim 引用；每条业务陈述都
  有 `[证据: file:line]` 引用或显式标"未知"；Section Reviewer / Coverage Audit /
  Freshness Audit 三道关全过。
- **reader profile 被尊重**：选 architecture-review 的人能在 30 分钟做架构判断；选
  onboarding 的人第二天能 ship 第一个 issue；选 archaeology 的人半年后还能找回决策。
- **业务背景有交代**：Section 02b Business Domain Map 与 Section 09 Decisions That Matter
  能让读者理解"这套代码在做什么业务、为什么这么做"，而不只是"这套代码的目录结构"；
  当目标项目确实没有业务实体时，显式标"本项目无业务实体, 跳过"——不是静默省略。
- **Q9b 被尊重**：报告读起来像被精心编辑过的工程随笔，不像贴满代码的 cookbook；CodeBlock
  极少出现，inline 标识符承载精确度。
- **HTML 自包含**：单文件 article.html ≥ 1 MB（典型项目），断网可打开，所有 Mermaid 在
  client-side 渲染成功，所有字体 / 资产 inline，没有外链 CDN。
- **覆盖与新鲜度**：Coverage 数字 + Freshness diff 嵌在 article footer；如果 >10k 文件项
  目，footer 显式说明"本报告为 ~70% 覆盖归档版本，未覆盖文件见 Coverage Annex"。

---

## 相关资源（按"何时读"标注）

| 文件 | 何时读 | 内容 |
|---|---|---|
| `references/harness.md` | Phase 0 | Skill 的 harness 视角、六问、状态文件约定、与 beautiful-article 的差异速查 |
| `references/discover.md` | Phase 1 开始 | 探测 / 索引 / inventory / buckets / business-evidence / brief 全流程 |
| `references/bucket-strategy.md` | Phase 1 切 bucket 时 | 4 档 size tier 的 bucket 策略；`>10k` 双层规则 |
| `references/business-evidence-collection.md` | Phase 1 业务证据 / Phase 4 写 NN-business.md 时 | 6 类证据的采集规则；引用约束；NN-business.md 模板骨架 |
| `references/entry-point-taxonomy.md` | Phase 1 / Phase 4 Section 05 | 9 类入口角色 + 跨语言检测规则 + mermaid class 映射 + 上限规则 |
| `references/complexity-tools.md` | Phase 1 跑复杂度 / Phase 4 Section 07 | 各语言 CC 工具优先级、lizard fallback、退化策略 |
| `references/plan-template.md` | Phase 2 写 plan.md | 单一 plan.md 模板（Brief / Outline / Theme / Assets + business-job） |
| `references/profiles/architecture-review.md` | Checkpoint 1 选这个后 / 写每节回看 | 必选 / 可选 Section / 标配密度 / 主题搭配 / 给作者提示 |
| `references/profiles/onboarding.md` | Checkpoint 1 选这个后 | 同上 |
| `references/profiles/archaeology.md` | Checkpoint 1 选这个后 / 写每节回看 / `>10k` 强制时 | 同上 |
| `references/theme-selection.md` | Phase 2 选主题 / Checkpoint 1 推荐时 | 三主题速查；与 reader profile 的搭配；切主题成本 |
| `references/layout.md` | Phase 2 / Checkpoint 1 | 4 种宽度模式 + TOC；与主题解耦 |
| `references/information-density.md` | Phase 2 / 写每节时 | reader profile 标配密度；与 Q9b 的关系；偏离标配的写法 |
| `references/asset-policy.md` | Phase 2 / Checkpoint 1 | 4 种来源；本 Skill 默认 none；mermaid 与 Assets 正交 |
| `references/cover.md` | Phase 2 / Phase 3 写封面时 | 书封式封面：硬约束、三主题封面起手、5 个构图模板、5 条自检 |
| `references/section-build.md` | Phase 3 / Phase 4 每节 | 一节一文件铁律、三阶段写流程、单 / 多 Agent 模式、Reviewer prompt 模板 |
| `references/component-policy.md` | Phase 3 / Phase 4 每节 | reacticle 组件协议；Q9b 替换优先级；inline 鼓励、CodeBlock 严格上限 |
| `references/raw-policy.md` | Phase 3 / Phase 4 每节 | Raw 允许 / 禁止；token 驱动；与 Mermaid 的关系 |
| `references/source-pointers.md` | Phase 4 写每节 / Phase 0 抓 git remote 时 | 每节脚部 file:line 折叠面板；GitHub URL 自动解析 |
| `references/review-checklist.md` | Plan 自查 / First Spread / Section / Final 各节点 | 各阶段 Reviewer 清单与 prompt 模板；Coverage / Freshness / Density 脚本说明 |
| `references/repair-policy.md` | Phase 5 修复时 | 最小切片修复对照表；不允许的修复 |
| `references/scaffold.md` | Phase 3 建项目时 | 脚手架做什么、用法、工作区结构、切主题成本 |
| `references/html-output.md` | 构建 / Phase 6 交付时 | dev / build / 单文件 HTML 命令与产物；analysis-snapshot.json |
| `references/pdf-output.md` | Phase 6 当 Checkpoint 3 选 PDF 时 | `html-to-pdf.sh` 用法、TOC 排版原理、terminal 暗底打印 caveat、故障排除 |
| `theme-profiles/index.json` + `*.md` | Phase 2 选主题 / Phase 4 写作 | 主题 authoring profile（给 AI 读，非 CSS） |
| `theme-profiles/terminal.md` | 默认主题 · 写作时贴着读 | 暗底等宽、语义状态色、组件级写作指南、Mermaid class 映射、封面起手 |
| `theme-profiles/tufte.md` | 选 tufte 时 | re-export 占位；指向 beautiful-article 的 canonical 版本 |
| `theme-profiles/press.md` | 选 press 时 | re-export 占位；指向 beautiful-article 的 canonical 版本 |
| `prompts/step-a-evidence.md` | Phase 4 派 Step A SubAgent 时 | Evidence Collection SubAgent 完整 prompt 模板（原样发出） |
| `prompts/step-a5-business.md` | Phase 4 派 Step A.5 SubAgent 时 | Business Distillation SubAgent 完整 prompt 模板（禁止 repo 访问；4 段输出契约） |
| `prompts/step-b-writing.md` | Phase 4 派 Step B SubAgent 时 | Writing SubAgent 完整 prompt 模板（物理隔离 repo；Q9b 密度上限） |
| `prompts/section-reviewer.md` | Phase 4 每节完工后 | Section Reviewer SubAgent prompt（消息返回 pass/fail，不写文件） |
| `scripts/probe-tools.sh` | Phase 0 末尾 | 探测 codegraph / rg / grep，输出 tier label（Phase B 实现） |
| `scripts/scaffold.sh` | Phase 3 跑一次 | 一键创建 `<project>-analysis/` 工作区（Phase B 实现） |
| `scripts/discover/*.sh` | Phase 1 | inventory / buckets / business-evidence / brief / tier 子流程（Phase C 实现） |
| `scripts/audit/{coverage,freshness,density,claim-trace}.sh` | Phase 5 | 三审计 + claim 回溯（Phase F 实现） |
| `scripts/html-to-pdf.sh` | Phase 6 仅当用户选 PDF | HTML → PDF（headless 浏览器 + 注入 print CSS，零 npm 依赖；Phase G 实现） |
| `scripts/pdf-print-overrides.css` | 改 PDF 样式时 | `html-to-pdf.sh` 注入到 `<head>` 的 `@media print` 覆盖 |

