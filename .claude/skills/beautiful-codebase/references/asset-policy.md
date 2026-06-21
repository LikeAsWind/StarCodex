# Asset Policy · 配图策略

> **何时读**：Phase 2 写 plan.md 的 Assets 段时;Checkpoint 1 第 4 项决策时;
> Phase 3 / 4 写封面或某 Section 需要外部 Image 时回看。
>
> **配套文件**：`references/cover.md`(封面构图,封面本身不属于 Assets,但 placeholder
> 模式常用于封面);`references/raw-policy.md`(Raw / Mermaid 与 Assets 正交);
> `theme-profiles/<id>.md`(主题不直接管 Assets,但部分主题对图片风格有偏好)。

## 1 · 与 Raw / Mermaid 完全正交(铁律)

**Assets 策略只管外部 `Image`,与 `Raw` / `Mermaid` 完全正交,不是二选一**:

- **`Raw` 始终存在**(任意 HTML / CSS / JS / SVG / Canvas 自由层),不受 Assets 影响,
  也永远不需要用户"开启"。
- **`Mermaid` 始终存在**(本 Skill 的主要架构 / 调用链 / 业务实体图都靠它),不属于
  Assets 范畴。
- **`Image` 是独立的可选叠加层**,由 Assets 策略决定是否使用、用哪种来源。
- 选 `none` **不等于**"用 Raw / Mermaid 替代 Image" —— 它只表示"不使用外部图片",
  Raw 与 Mermaid 照常使用。

> 别把它框成"Image vs Mermaid"。正确心智:**Mermaid + Raw 一定有;Image 要不要、
> 用哪种来源,由用户在 Checkpoint 1 明确选定**。

## 2 · 四种来源模式(只针对 Image)

| 模式 | 说明 | 适合代码分析报告的情况 |
|------|------|------------------------|
| `none`(本 Skill 默认) | 不使用外部图片,Raw / Mermaid / 表格表达全部视觉 | 大多数 architecture-review / archaeology;Mermaid 已经覆盖架构 / 调用链 / 业务实体 |
| `user-assets` | 用户提供截图(架构图 / 业务流程图 / dashboard 截图 等) | 用户已经有内部架构图想嵌入;onboarding 报告想嵌入"运行截图" |
| `placeholders` | 先放占位图,Plan Assets 段标注每张应替换成什么 | **仅推荐用于封面**(Phase 3 First Spread 替换 `<CoverPlaceholder />` 之前的中间态);Section 07 复杂度热图等待真实数据时也可用 |
| `ai-generated` | AI 按文章和主题生成图片提示词 → 用户决定是否生成 | **不推荐** —— 不要 AI 画假架构图;若用户坚持,仅用于封面装饰 |

**默认推荐 = `none`**: 本 Skill 的视觉主轴是 Mermaid + 终端主题的徽章 / 表格,外部 Image
很少需要。Checkpoint 1 第 4 题必选,但 AI 推荐默认 `none` + 一句话理由。

## 3 · 为什么 `ai-generated` 强烈不推荐

代码分析报告的核心是**反幻觉** —— 每条技术陈述能溯源,每条业务陈述带引用。AI 生成
的"架构示意图 / 业务流程图"违反这条核心约束:

- **不要让 AI 画假架构图**: 真实架构图必须从 codegraph / `inventory.json` 推导,用
  Mermaid 生成,带 `file:line` 锚点。AI"想象"出来的图是幻觉。
- **不要让 AI 画假业务流程图**: 真实业务流程必须从 `business-evidence/` 推导。
  AI 画的"用户下单流程"是行业模板,不是这个项目的真实流程。

**唯一允许的 `ai-generated` 情形**: 封面的装饰性主视觉(完全不承担信息表达),且
用户在 Checkpoint 1 明确选择,且封面的"图文并茂"硬约束(见 `references/cover.md` §3
第 2 条)仍然要满足。

## 4 · `placeholders` 模式

最常见用途:**封面的中间态**。Phase 3 First Spread 之前,scaffold 在 `article/Cover.tsx`
里放一个 `<CoverPlaceholder />`(纯 SVG 占位 + 项目名 + 主题色),Phase 3 First Spread
主 Agent 把它替换为按 reader profile 与主题定制的真实封面。

其次用途:**Section 07 复杂度热图待数据**。如果 Phase 1 的 complexity 工具检测失败
(无可用 lizard / radon 等),Section 07 可以用 placeholder 占位,并在 Plan Assets 段
注明"待用户补充真实复杂度数据后替换"。

`placeholders` 不需要在 plan.md 的 Assets 段写"逐图计划",只需要一句"使用 placeholder
作为 Cover / Section 07 的占位"。

## 5 · `user-assets` 模式

如果用户在 Phase 0 自由文本里提到"我有一张内部架构图想用",启用 `user-assets`:

- **截图必须是论证素材**(代码截图 / 真实架构图 / dashboard 截图 / 业务流程图),
  **不要是装饰**(团队合影 / 办公室照 / 营销 banner)。
- **截图必须裁掉浏览器 chrome**(地址栏 / 标签 / 任务栏)、敏感信息(token / 内网
  URL / 个人邮箱)。
- **必填 alt 文本**: 描述图里的关键信息(不是"一张架构图",而是"前端 → API Gateway →
  Order Service / Payment Service / Inventory Service 三层架构,数据库 PostgreSQL")。
- **与 Mermaid 互补,不重复**: 如果用户截图就是架构图,Section 03 Architecture Map
  的 Mermaid 是否还要画?**两者保留一个** —— 通常保留 Mermaid(可点击锚点 + 跟随
  主题色),用户截图放在 Lead 段作为"原始资料"补充。

plan.md Assets 段需要"逐图计划"(位置 / 服务的段落 / 目的 / 主题风格 / 禁止项 / 来源
路径),格式同 `beautiful-article` 的 plan-template。

## 6 · Asset Checkpoint 必问(Checkpoint 1 内 · 不允许默认通过)

虽然 AI 推荐 `none`,但 Checkpoint 1 第 4 项**仍然必须让用户选**(不能 "default 通过")。
开场说明里这样写:

```
配图模式(这一项只决定是否使用外部 Image;Mermaid + Raw 自由层不受影响,照常使用)。
请从以下四种里选一种:
- none(我的推荐):不使用外部图片,靠 Mermaid + Raw + 表格表达。本 Skill 的视觉主轴
  是 Mermaid,绝大多数情形都用这个。
- user-assets:你提供素材目录或截图,我据此排版(代码截图 / 内部架构图 / dashboard 截图)。
- placeholders:先放占位图(通常用于封面),我在 plan.md 的 Assets 段标注每张应替换成什么。
- ai-generated:**强烈不推荐**(代码分析报告不应该有 AI 画的假架构图);若你坚持仅用于
  封面装饰,我会生成提示词等你确认后再生成图片。
你确认 none,还是改成别的?
```

## 7 · 与 Mermaid 的关系

代码分析报告的视觉重心是 Mermaid:

- **Section 02b Business Domain Map**: 1 张 `graph LR` 业务实体图。
- **Section 03 Architecture Map**: 1 张模块依赖图。
- **Section 05 Exposed Entry Points**: 每个入口一张 `flowchart TD`,最多 50-100 张。
- **archaeology 的每个 Module Chapter**: 一张本模块对外依赖子图。

这些 Mermaid 块都走 Raw 层 + 主题 token(`theme-profiles/terminal.md` §4.3 的 6 个
class),**不属于 Assets 范畴,不在 plan.md 的 Assets 段讨论**。Assets 段只讨论
外部 Image 的来源。

## 8 · 配图自检(每张图,仅 user-assets / placeholders / ai-generated 模式有图时)

- 是否服务报告中的具体位置?是否符合选定主题 `theme-profiles/<id>.md` 的媒体风格?
- 是否不是纯装饰?是否不会抢正文?是否与 Mermaid 表达没有重复?
- 是否有 caption / source / alt 文本?
- 是否内联(base64 raster)以保证 offline-first?(远程 URL 严禁)
- 是否清理了敏感信息(token / 内网 URL / 个人邮箱)?

配图自查并入 Plan 自查 5 条之一("Raw / 图片有目的") —— 由主 Agent 内联完成,
**不再单独开 Asset Reviewer SubAgent**。详见 `references/review-checklist.md` 的
Plan 自查段。
