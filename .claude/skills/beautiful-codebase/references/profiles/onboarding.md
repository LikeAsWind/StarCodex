# Reader Profile · `onboarding`（今天读完,明天上手）

> **何时读**：Checkpoint 1 用户选 `onboarding` 后；写 `plan/plan.md` 时；
> Phase 4 每节回看自己的 Business-Job 与"starter trail"承诺时。
>
> **配套文件**：`references/plan-template.md`、`references/theme-selection.md`、
> `references/information-density.md`、`theme-profiles/terminal.md`。

## 1 · Profile intent · 这份报告给谁读、读完做什么

`onboarding` 服务的是**新加入团队的工程师 / 实习生 / 转岗同学**。他们手上有一个
**昨天才被 onboard 进来的项目**,**今天读完报告,明天要 ship 出 first pull request**。
读这份报告的目的不是"评判项目值不值得"(那是 architecture-review),而是**让自己能动
起来**：

- 能在 30 分钟内把 dev 环境跑起来（看到第一次成功输出）。
- 能在 2 小时内对项目目录结构建立一个"我现在在哪 / 想改 X 该从哪儿开始"的 mental map。
- 能在一天内识别出 5-8 个 "starter trail" —— 典型任务（加 API / 加数据库字段 /
  修一个 bug）的实现起点。

任何让新人读完仍然"不知道从哪儿改第一行代码"的报告,对这个 profile 都是失败的。
所以 onboarding 报告的核心**不是分析判断,而是导航 + 上手指引**。

`onboarding` profile 的隐含承诺是：**读者明天就要写代码,所以报告里所有抽象判断都
要折成具体动作**。"这套代码很复杂"对新人没用,"修一个 OrderService 的 bug 从
`order/Service.java:84` 看起"才有用。

## 2 · 默认 Section 列表（13 节 · 8 必 + 4 选）

onboarding profile 的 Section 编号体系**有意与 architecture-review 不同**：
01 Verdict 重命名为 "Welcome / What this codebase does"；新增 02 Quick Start /
06 Common Tasks / 07 Conventions / 08 Gotchas / 09 Where to Ask 等"导航类"小节。
没有 Verdict / Risks / Decisions That Matter ——那些是给评审人看的,不是新人。

| #   | Section                          | 必/选 | 行数估算 | 必选视觉块                       | 一句话职责 |
|-----|----------------------------------|-------|----------|----------------------------------|------------|
| 00  | Cover                            | 必    | (封面)   | 主视觉 + 项目身份                | 视觉欢迎；让新人"觉得被这个项目欢迎" |
| 01  | Welcome · 项目做什么             | 必    | 30-60    | 1 个项目身份徽章                 | 一句话说**这个项目做什么** + 给新人 1-2 句"为什么你在这里" |
| 02  | Quick Start · 跑起来             | 必    | 60-120   | 命令清单 + 期望输出截图 / 文本   | **30 分钟内看到第一次成功运行** ——含命令、期望输出、常见坑 |
| 03  | Project Map · 目录速览           | 必    | 50-100   | 1 张文件树缩略图 / 表格          | 用一句话说明每个主要目录是什么 / 装什么 |
| 04  | Business Domain Map              | 必    | 40-80    | 1 张 `graph LR` 业务实体图       | 用通俗语言说"这套代码在做什么业务,几个核心实体" |
| 05  | Module Walk-through              | 必    | 200-400  | 每子节 1 张子图 + 1 条 starter trail | 一桶一子节,**重点说"如果你要改 X 从这里看起"** |
| 06  | Common Tasks · 起点              | 选    | 80-160   | 5-8 条任务清单                   | 5-8 个典型任务（加 API / 加 DB 字段 / 修 bug）的实现起点 |
| 07  | Conventions & Style              | 选    | 30-80    | 1 张代码风格速查表               | 代码风格 / 命名 / 测试模板 / Lint 规则 |
| 08  | Gotchas · 常见陷阱               | 必    | 60-150   | 陷阱列表（每条带"为什么"）       | 调试技巧 / 环境踩坑 / "我也遇到过" |
| 09  | Where to Ask · 求助指向          | 选    | 20-50    | 联系人 / 链接表                  | 文档 / Slack / owner 在哪儿 ——给新人下一个动作 |
| 10  | Coverage Annex                   | 必    | 30-80    | 短覆盖表                         | onboarding 不强求 100%,但要列出"已覆盖 / 暂缓"两段 |
| 11  | Colophon                         | 必    | 5-10     | (无 · 文字)                      | 不可移除的署名 + 主题 |

**总行数估算**：典型 onboarding 报告走 8 必 + 2-3 选 = 10-11 节,渲染后正文约
600-1000 行(不含 Mermaid / 表格)。**比 architecture-review 略短**,因为 onboarding
更短促 / 更动作导向。

**没有的 Section**（与 architecture-review 的差异）：

- 没有 `01 Verdict` ——新人不需要判断"项目值不值得";被分配进来就是要干活了。
- 没有 `06 Tech Stack Audit (CVE)` / `07 Code Health Heatmap` / `08 Risks` /
  `09 Decisions That Matter` ——这些都是评审人语境,不是新人语境。如果某条具体风险
  会绊倒新人,放到 onboarding 的 `08 Gotchas` 里讲。

## 3 · Section 分配规则（bucket → Section）

- **Section 05 Module Walk-through**：**一桶一子节**(同 architecture-review)。但子节
  的"骨架"不一样 ——onboarding 的子节按这个顺序写：
  1. **职责**（一句话：这个模块在做什么业务）
  2. **入口 / Owner**（这个模块的入口文件 + 关键类）
  3. **Starter trail**（"如果你要改 X 从这里看起" —— 至少 1 条具体的从入口到出口的
     路径,带 `file:line` 锚点）
  4. **相关的常见任务**（指向 Section 06 的 task id,如有）
  5. **本模块的坑**（指向 Section 08 的 gotcha id,如有）
- **Section 02 Quick Start**：必须从 `discovery/codebase-brief.md` 的 "Build / Run
  detection" 段抽取真实命令(不是猜的)。如果脚手架探测器找不到任何运行命令(纯 library /
  内部包),Section 02 应写"本项目无独立运行命令,通过 import 使用 ——参考 Section 03
  / 05" 并保留小节(不要静默删除)。
- **Section 03 Project Map**：覆盖**顶层 + 二层目录**就够；不要深到三层(新人会迷路)。
  每行一句话,**禁止抄 README** —— 必须基于 inventory 真实文件分布写。
- **Section 04 Business Domain Map**：onboarding 的业务图要**比 architecture-review
  更通俗** ——少用"聚合根 / Anti-corruption layer"等 DDD 术语,多用"用户做什么 / 系统
  存什么"语言。
- **Section 06 Common Tasks**：从 `business-evidence/commit-themes.md` 抓"最常出现的
  动词"(add / fix / update / refactor 等),归纳出 5-8 个"过去三个月最常做的事",每条
  写"从哪个文件 / 哪个测试看起"。
- **Section 08 Gotchas**：从 `business-evidence/commit-themes.md` 中找"fix:" / "hotfix:"
  / "revert:" 的聚类,以及 `comments.jsonl` 里的 TODO / FIXME / HACK 注释,归纳出最常
  被踩的坑。**不要从经验里编**。

## 4 · 可选 Section 自动决策规则（按 size-tier）

| size tier | 06 Tasks | 07 Conventions | 09 Where to Ask | 备注 |
|-----------|----------|----------------|------------------|------|
| `<100`    | **关**   | **关**         | **关**           | 小项目跳过 Tasks / Conventions / Ask;新人通读 03 / 05 / 08 就够 |
| `100-1k`  | 开       | 开             | 开（若 Phase 0 抓到 maintainer 信息） | 默认完整组合 |
| `1k-10k`  | 开       | 开             | 开               | onboarding 的甜区,所有可选都打开 |
| `>10k`    | 开       | 开             | 开（强烈推荐）   | 大项目新人最需要"问谁",务必开 09 |

**`>10k` 时的特别提示**：onboarding profile 在 `>10k` 项目下不像 archaeology 那样
被强制降级,但 Plan Brief 要写一行 "项目较大,Module Walk 只覆盖 ~30% 入口模块,新人
按需深读"。Coverage Annex 要写"onboarding 短版,只列未覆盖的顶层目录"。

## 5 · 每节 Business-Job 提示词（Plan SubAgent 用）

| Section | Business-Job 模板（一句话） |
|---------|------------------------------|
| 01 Welcome | 用一句话告诉新人**这个项目在为哪类用户做什么事**(避免抽象描述) |
| 02 Quick Start | **让新人 30 分钟内看到第一次成功运行** —— 命令、期望输出、最常见的 3 个"跑不起来"原因 |
| 03 Project Map | 让新人**在脑子里建立"目录 = 业务模块"的对应表** |
| 04 Business Domain | 用 schema / 枚举 + **通俗语言**说"这个系统在为什么业务建模" |
| 05 Module Walk | 每子节回答"**如果你要改 X 业务规则,从哪个文件 / 哪个测试看起**" |
| 06 Common Tasks | 每条任务回答"**最近三个月团队最常做的事是 Y,这个项目里 Y 通常从这里开始**" |
| 07 Conventions | 让新人**知道写代码要遵守哪些团队约定**(命名 / 测试 / 提交) |
| 08 Gotchas | 每条陷阱回答"**别人(包括团队成员)曾经在这里踩过,以下是绕过的方法**" |
| 09 Where to Ask | 让新人**知道下一个动作是什么**(找 owner / 看文档 / 进 Slack) |
| 10 Coverage | 短版 ——"已覆盖 / 暂缓覆盖" 两段即可 |

**业务-Job 自检铁律同 architecture-review**：业务写不出来就显式标"业务背景未知"。
但 onboarding 多一条特殊要求：**每一段必须能落成一个"新人能做的动作"** —— 如果某节
读完后新人**没有任何具体动作**可做,这段就是失败的。

## 6 · Self-check（5 条 · 写完 plan.md 立刻自查）

1. **Quick Start 命令具体且可验证**：Section 02 的命令必须能复制粘贴到 shell 里跑;
   每条命令带"期望输出"(一行也行)。**禁止**"启动开发服务器即可"这种空泛指令。
2. **Module Walk 至少有 3 条 starter trail**：Section 05 总共必须出现至少 3 条
   "如果你要改 X 从这里看起"的具体路径(带 `file:line` 锚点)。少于 3 条 = fail。
3. **Gotchas 非空且有证据**：如果 `business-evidence/commit-themes.md` 显示有 ≥ 3 个
   "fix:" / "hotfix:" 聚类、或 `comments.jsonl` 里有 ≥ 3 条 TODO / FIXME / HACK,
   Section 08 必须至少列出对应数量的 gotcha。证据多但 Gotchas 空 = fail。
4. **必选 Section 齐全**：Cover / 01 Welcome / 02 Quick Start / 03 Project Map /
   04 Business Domain / 05 Module Walk / 08 Gotchas / 10 Coverage / 11 Colophon —— 一个不少。
5. **业务 Domain 通俗**：Section 04 的描述里**不**出现"领域驱动设计 /
   Anti-corruption layer / aggregate root"等术语,除非项目代码里**本身**这么用 ——
   onboarding 报告的读者还没准备好读 DDD 黑话。

## 7 · Theme recommendation hint

onboarding profile 的**默认主题推荐 = `terminal`**。理由同 architecture-review:
terminal 的语义色让 Section 08 Gotchas 的警告徽章一致, mermaid 节点色也够清晰。

**例外建议**：

- **项目是 CMS / blog engine / content domain 自身**：推荐 `press`。理由：press 主题
  的"叙事感"对新人更友好 ——读起来像一本团队手册,而不是审计报告。
- **不推荐 tufte**：tufte 太克制 / 数据墨水比太高,对"上手指引"语境是负担 —— 新人想要
  的是温暖引导,不是学术克制。

## 8 · Cover composition starter（封面起手提示）

onboarding 封面的语气和 architecture-review 截然不同 —— 不是"判断锚点",而是
**"欢迎气质"**。推荐两种起手：

1. **Welcome map（欢迎地图）**：用 SVG 画一个"项目地形图" —— 把主要目录画成几个岛屿
   或区域,中心一个 "you are here" 星标 + 项目名。颜色用 terminal 主题的 status-blue +
   status-green(温和、不警示)。
2. **First-pull-request trail（第一次 PR 路径）**：把一条典型的 starter trail(从入口
   到第一次提交)画成一条带箭头的小径,起点是"You" 终点是"git push"。线条用 status-green。

封面文字层固定三段：项目名(`--ra-mono-display` 大字号)、副标题
`Onboarding Guide · Day 1 to Day 7`、底部 colophon
`Made with [beautiful-codebase] · terminal theme`(用了 press 则相应改名)。

**禁止**:在 onboarding 封面上画 risk grid / 红色块 / "BLOCKER" 徽章 —— 那是
architecture-review 的视觉语言;onboarding 的视觉语言是"欢迎"。

## 9 · 给 Plan SubAgent 的微调提示（写 plan.md 时的口诀）

- **Quick Start 写"命令 + 期望输出 + 常见坑"三件套,不要只写命令**:
  新人最大的痛点不是"不知道命令",而是"跑不起来不知道为什么";期望输出与常见坑是给
  他们的安全网。
- **Module Walk 子节顺序固定**(职责 → 入口 → starter trail → 相关任务 → 本模块的坑),
  让新人形成肌肉记忆,翻到任何一节都知道往下找什么。
- **Gotchas 是 onboarding 的灵魂**:这一节如果空了,整份报告对新人就是"虚假的友善";
  写不出来就去 `commit-themes.md` 里找 fix 类聚类,写不出来就去 `comments.jsonl` 里找
  TODO/FIXME/HACK,实在没有就老实标"本项目历史短,暂无典型坑"。
- **Common Tasks 从真实 commit 模式归纳,不要从经验编**:"最近三个月最常做的事是 add
  API endpoint" 这种话必须能在 `commit-themes.md` 里找到对应聚类才能写。
- **整篇语气保持"团队前辈在指引新人"**:不要"This codebase implements ..."(评审语气),
  要"在这里,我们把 ..."(团队语气)。

## 10 · Per-section 写作起手提示(Writing SubAgent 用)

- **01 Welcome**: 第一句直接说"这个项目是一个 [XXX 类型] 系统,负责 [一句业务作用]";
  第二句给新人定位"作为新加入的工程师,你可能会接到的第一类任务是…";第三句指向
  "想立刻跑起来,看 02 Quick Start";**不要**写"欢迎加入团队!"这种空话。
- **02 Quick Start**: 按"前置依赖 → 一键启动命令 → 期望输出 → 第一次踩坑救援"四段
  组织。前置依赖具体到版本(`node >= 18 / pnpm >= 8 / docker compose >= 2`);一键
  启动命令必须能逐行复制粘贴;期望输出至少给出最终一行(如"Server listening on
  http://localhost:3000");第一次踩坑救援列 3 条最常见的"为什么跑不起来"。
- **03 Project Map**: 用表格 ——左列目录名,中列 LOC / 文件数,右列"一句话职责"。
  顶层目录 + 二层目录,**不要深到三层**。
- **04 Business Domain Map**: 第一段说"这个系统在为 [用户类型] 做 [核心动作],
  涉及 [N 个核心实体]";然后画 mermaid;最后用 1-2 段说明"对你日常工作最相关的实体
  是 X(因为大多数 issue 围绕它)"。**禁用 DDD 术语**。
- **05 Module Walk-through**: 每子节按固定六段写(职责 / 入口 / starter trail /
  相关任务 / 本模块的坑 / 想深入再看哪里)。**最重要的是 starter trail** —— 这是
  onboarding 报告与 architecture-review 最大的差别,每子节至少 1 条具体路径。
- **08 Gotchas**: 按"症状 → 原因 → 怎么避开"三段写每条 gotcha。**禁用**"注意 X" 这种
  空话;必须给出"看到这种 error 通常是因为 Y;暂时绕过用 Z;长期修复见 [issue
  link / 文件路径]"。

## 11 · 反面案例(本 profile 专属 · 禁止)

- **Quick Start 只给命令不给输出**: "运行 `npm run dev` 即可" —— 新人跑了不知道
  成功 / 失败的标志。必须给出"看到 `Server listening on http://localhost:3000` 就成功了"。
- **Module Walk 没有 starter trail**: 每子节只写"这个模块包含 X / Y / Z 文件" ——
  新人读完仍然不知道改哪里。每子节必须有至少 1 条"如果你要做 X,从 Y 文件看起"的具体
  路径。
- **Gotchas 用经验填空**: 写"小心配置文件别误删 / 注意环境变量" —— 这种 gotcha 在任何
  项目都适用,等于没说。必须从本项目的真实 commit / TODO / FIXME 归纳。
- **Common Tasks 给"理论任务清单"**: 写"如何添加新功能 / 如何处理错误" —— 这是教科书
  目录,不是这个项目的常见任务。Common Tasks 必须从 `commit-themes.md` 的真实活动
  归纳。
- **整篇用 architecture-review 的"判断"语气**: "本项目存在以下风险…" —— 这是给评审人
  说的,不是给新人说的。新人需要的是"在这里我们这样做",不是"这套代码这样有问题"。
- **04 Business Domain 用 DDD 黑话**: "本系统采用 Anti-corruption layer 隔离外部上下文" ——
  新人无法解析。改成"本系统在 `<path>` 里有一层 adapter,把外部 API 的数据格式翻译
  成内部使用的格式"。

## 12 · 已知 trade-off / 局限

- **"今天读完明天上手"的 7 天承诺是软上限**: 复杂项目(尤其 `1k-10k` 文件 + 多语言
  混合)的新人可能需要 2-3 周才真正上手 ——onboarding 报告只能加速这个过程,不能完全
  替代真实代码阅读。
- **Common Tasks 在新项目里通常空**: < 50 commits 的项目可能还没形成"重复任务模式",
  Section 06 在新项目里默认关闭或非常短。这不是 profile 失败,是项目本身的特征。
- **Gotchas 的"真实性"取决于 commit message 质量**: 团队如果只用 "wip" / "update"
  做 commit message,Section 08 的 gotcha 归纳会很弱。这种情形 plan.md 写一行
  "commit message 质量低,gotcha 段以 TODO / FIXME 注释为主"。
- **跨语言项目的 starter trail 数量爆炸**: 多语言项目的"加一个 API"可能涉及 backend +
  frontend + DB migration 三个 trail。每条 starter trail 应该按"我要改这个语言侧"分别
  写,不要混淆。
- **Section 03 Project Map 的"顶层目录"假设**: 有些项目目录结构平坦(所有源码在 src/
  下),Section 03 这种项目里几乎没用 —— 可以降级为"主要文件列表" + 简短说明。

## 13 · 与其他 reference 的协作图

| 阶段 | 主要读 | 配套 | 落到 plan.md 的哪一段 |
|------|--------|------|------------------------|
| Brief · reader profile | 本文件 §1 / §4 / §6 | `information-density.md` §1 | Brief 的"Reader profile" / "信息保留比例" |
| Brief · Quick Start 命令 | 本文件 §3(02 子节) | `discovery/codebase-brief.md` 的 "Build / Run detection" | (写到 Section 02 时用,不直接进 plan.md) |
| Outline · Section 列表 | 本文件 §2 / §3 / §4 | `discovery/codebase-brief.md` | Outline 表格的"必/选" / "引用 bucket" |
| Outline · Common Tasks | 本文件 §3(06 子节) | `business-evidence/commit-themes.md` | Outline 表格(06 行的"业务-Job" 列) |
| Outline · Gotchas | 本文件 §3(08 子节) | `business-evidence/commit-themes.md` + `comments.jsonl` | Outline 表格(08 行) |
| Theme | 本文件 §7 | `theme-selection.md` §3 | Theme 段 |
| 封面 | 本文件 §8 | `cover.md` §3.4 | Brief 的"封面" |
| Self-check | 本文件 §6 + 本文件 §11 | `plan-template.md` §D | (主 Agent 内联跑) |
| Checkpoint 1 推荐文案 | 本文件 §7 / §8 | `plan-template.md` §E | (Checkpoint 1 的开场说明段) |

**写 plan.md 时的顺序心智**: onboarding 比 architecture-review 多一个隐含步骤 ——
先扫一遍 `business-evidence/commit-themes.md` 看团队过去三个月在做什么(决定 Section
06 是否能开),再扫 TODO / FIXME 看团队踩过哪些坑(决定 Section 08 的密度)。这两类
信息直接决定整份 onboarding 报告的"动作性"。

## 14 · 一段最小可行 Outline 示例(供模仿)

下面是一份典型 `100-1k` 文件中型业务系统的 onboarding Outline 骨架,**仅作示意**:

```
| #   | 标题 | 必/选 | 引用 bucket | 业务-Job | 期望长度 | 视觉块 |
|-----|------|-------|-------------|----------|----------|--------|
| 00  | Cover | 必 | (无) | welcome map · 温和欢迎 | (封面) | SVG + 文字 |
| 01  | Welcome | 必 | (无) | 这个项目为 [B2B 客户] 做 [订单管理] | 30 | 1 个项目身份徽章 |
| 02  | Quick Start | 必 | (无,基于 codebase-brief) | 30 分钟内看到第一次成功运行 | 80 | 命令清单 + 期望输出 |
| 03  | Project Map | 必 | (顶层目录) | 让新人在脑子里建立"目录 = 业务模块" | 60 | 1 张目录速览表 |
| 04  | Business Domain | 必 | bucket-02-domain | 系统在为客户做订单管理,涉及 5 个核心实体 | 50 | graph LR |
| 05  | Module Walk-through | 必 | bucket-01..bucket-06 | 每子节回答"想改 X 业务规则从哪里看起" | 280 | 6 张子图 + 6 条 starter trail |
| 06  | Common Tasks | 选 | (commit-themes) | 团队最近三个月最常做的 6 件事的实现起点 | 120 | 6-8 条任务清单 |
| 07  | Conventions | 选 | (style configs) | 团队代码风格 / 命名 / 测试约定 | 50 | 1 张速查表 |
| 08  | Gotchas | 必 | (commit-themes + TODOs) | 别人踩过的 5 个坑 + 怎么绕过 | 100 | 陷阱列表 |
| 09  | Where to Ask | 选 | (无) | 找 owner / 看 docs / 进 Slack | 30 | 1 张联系人表 |
| 10  | Coverage Annex | 必 | (全) | "已覆盖 / 暂缓"两段 | (脚本生成) | 1 张表 |
| 11  | Colophon | 必 | (无) | (无业务) | 5 | 文字 |
```

注意:onboarding 的 Module Walk(05)预期长度 280 行已经包含**至少 3 条 starter
trail**(§6 自检铁律 2);如果项目特征导致 starter trail 多于 6 条,可以增加到 350-400
行,但不要减少 trail 数量。

## 15 · "Starter trail" 模板(给 Writing SubAgent 在 Module Walk 写 trail 时用)

每条 starter trail 必须包含至少 5 个具体动作 / 路径锚点。下面是 3 个不同情境的
模板(**仅作示意**,实际由 evidence 决定):

### 15.1 添加新 API endpoint

```
如果你要加一个新的 `/api/orders` GET endpoint,从这里开始:
1. 在 `src/api/routes.ts:42` 添加路由声明(参考 line 30-40 的同模式)
2. 实现 handler 在 `src/handlers/order.ts`(参考 `getUser` line 18-35)
3. 在 `src/services/OrderService.ts:120` 加业务方法
4. 在 `tests/api/order.test.ts` 加测试(参考 `tests/api/user.test.ts` line 22 起)
5. 跑 `pnpm test:api`,期望 7 passed
```

### 15.2 修一个已知 bug(基于 commit 或 issue link)

```
如果你要修订单状态不同步的 bug(issue #142),从这里开始:
1. 复现:跑 `pnpm test:e2e:order`,看到 `expected confirmed, got pending`
2. 入口:`src/services/OrderService.ts:184` 的 `updateStatus` 方法
3. 状态机定义:`src/domain/order/states.ts:12`
4. 已有的 fix 尝试:见 commit `<sha>`(已被 revert,原因在 PR description)
5. 跑 `pnpm test:e2e:order`,期望 12 passed
```

### 15.3 在 DB 里加一个新字段

```
如果你要在 `orders` 表加 `customer_note` 字段,从这里开始:
1. 写 migration:`migrations/$(date +%Y%m%d)_add_customer_note.sql`
   (参考 `migrations/20240315_add_priority.sql`)
2. 跑 `pnpm db:migrate`,期望 ✓ 1 migration applied
3. 在 `src/domain/order/Order.ts:18` 加 entity 字段
4. 在 `src/repositories/OrderRepository.ts:55` 的 mapping 加新字段
5. 跑 `pnpm test:repo`,期望 8 passed
```

**模板填充原则**: 5 步动作中至少 3 步带 `file:line`(锚点);至少 1 步带可运行命令
(命令必须能复制粘贴);最后一步是验证(测试 / 命令的期望输出)。少于 5 步的 trail
对新人价值有限,Section Reviewer 会标 fail。

---

> 本 profile 是 v0.1.0 的基线。onboarding 是和 architecture-review 并列的两个最常用
> profile 之一,真正写过一份后如果发现"新人读不到所需信息",**回到本文件改 Section
> 列表 / 自动决策表 / Business-Job 模板**,不要在单份 plan.md 里临时打补丁。
