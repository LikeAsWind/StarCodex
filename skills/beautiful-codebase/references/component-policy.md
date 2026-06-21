# Component Policy · Reacticle 组件协议（代码分析视角）

> **何时读**：Phase 3 写首屏第一节时；Phase 4 每节写作时；Section Reviewer 审代码密度
> 时。
>
> **配套文件**：`references/section-build.md`（Step B prompt 模板里直接引用本文件）·
> `references/raw-policy.md`（Raw 自由层）· `references/source-pointers.md`（节脚组件）·
> `references/information-density.md`（reader profile 标配带宽）·
> `theme-profiles/<id>.md`（主题级写作指南，每个组件的样式承袭主题 token）。

`beautiful-codebase` 用 `reacticle` 组件协议写报告 —— **不手写裸 `div` / `className` /
行内 `style` / CSS**。结构走语义组件，正文走段落，自定义视觉走 `Raw`。本文件是
**代码分析报告专属裁剪**：组件清单收紧、Q9b 代码密度上限硬约束、并强调"prose 为主体、
inline 鼓励、CodeBlock 极少、Mermaid 是主视觉"。

## 1 · Prose-first · Q9b 替换优先级（铁律）

代码分析报告的失败态是**变成贴满代码的 cookbook**——读者翻完只记得"这套代码有很多
函数"，记不住业务、记不住决策、记不住风险。Q9b（PRD）锁死了一条**替换优先级**：

```
prose → mermaid → table → <Code inline> → <CodeBlock>
   ↑                                            ↑
最优先                                        末选
```

写每节时，每要落一段"想表达的事实"，先问"prose 能不能讲清？" 不能，再问"画一张
mermaid 能不能讲清？" 不能，再问"列一张 table 能不能讲清？" 不能，再 inline；最后才考虑
`<CodeBlock>`。Section Reviewer 抽查时会反向倒推："这个 CodeBlock 替换到 inline 行不行？"
能 = fail。

**Step B Writing SubAgent 的 prompt 把这条优先级原样写进硬指令**——见
`references/section-build.md` §5 第 3 条。

## 2 · 允许组件清单（按需取用）

下表是 Step B Writing SubAgent **唯一可用**的 reacticle 组件。任何不在表里的组件 =
"不允许使用"；任何作者发明的组件 = 立即 fail。

### 2.1 结构

| 组件 | 一句话用途 | 典型出现位置 |
|---|---|---|
| `<Section>` | 节的根容器，必填 `index` + `title` | 每节根 |
| `<Subsection>` | 子节，必填 `index`（如 `4.1`） | 04 Module Walk 多模块时 |
| `<H1>` / `<H2>` / `<H3>` | 标题。一般不直接写，`<Section>` / `<Subsection>` 已带 | 极少数需要"标题但不是节"的场景 |
| `<P>` | 段落。多数时候直接写 `<p>` 也可，组件库会把裸 `<p>` 包装成 `<P>` | 正文主体 |

### 2.2 数据 / 二维信息

| 组件 | 用途 | 典型 Section |
|---|---|---|
| `<Table>` | 二维信息（依赖清单 / 风险表 / 覆盖清单 / 配置表 / 入口表） | 02 / 06 / 07 / 08 / 09 / 10 / 11 |
| `<List>` | 一维清单（不带 row x col 结构的） | 各处 |

### 2.3 代码

| 组件 | 用途 | 上限 |
|---|---|---|
| `<Code inline>` | 行内 identifier / `file:line` / 配置 key / API 名 / 命令 | **不计入 Q9b 上限**——鼓励大量使用 |
| `<CodeBlock>` | 多行代码块（必填 `language`） | **每节 ≤ 1 块；Section 04 / 05 例外 ≤ 2 块；每块 ≤ 8 行** |

> **不要直接使用 `HighlightedCode`**——它是 `<CodeBlock>` 的内部底层，作者一律用
> `<CodeBlock>`。

### 2.4 观点 / 标注

| 组件 | 用途 | 主要场景 |
|---|---|---|
| `<Callout tone="info">` | 中性提示 / 说明 | 节里需要"插一段说明"时 |
| `<Callout tone="warn">` | 警告（依赖陈旧 / 配置缺失等） | Section 06 / 08 |
| `<Callout tone="danger">` | 红线（已知 bug / CVE / 风险点） | Section 08 |
| `<Callout tone="success">` | 正面（最佳实践 / 已修复） | Section 09 |
| `<Quote>` | 引用一段 README / 注释 / commit message 原文 | Section 02 / 09 时偶用 |

### 2.5 可视化

| 组件 | 用途 | 何时用 |
|---|---|---|
| `<Mermaid>` | 业务实体图 / 架构图 / 调用链流程图 | Section 02b / 03 / 05 默认走 Mermaid；02 / 04 按需 |
| 自定义 Raw block | 复杂 SVG 热图 / 封面 / 极少数 mermaid 表达不了的图 | Section 07 复杂度热图、Cover 题图 |

### 2.6 节脚

| 组件 | 用途 |
|---|---|
| `<SourcePointers>` | 每节脚部的 file:line 折叠面板（详见 `references/source-pointers.md`） |

## 3 · `<Code inline>` —— 鼓励大量使用

`<Code inline>` 是代码分析报告的呼吸器。它**不计入** Q9b 代码上限，因为它视觉成本极低
（terminal 主题下与 prose 几乎齐高），但承担了"精确指向"的全部责任：

```tsx
<p>
  订单结算的入口在 <Code inline>OrderService.Checkout</Code>
  （<Code inline>src/svc/order.go:42</Code>）；它先检查 <Code inline>InventoryService.Reserve</Code>
  返回值，再写库 <Code inline>orders</Code> 表的状态从 <Code inline>pending</Code>
  转到 <Code inline>paid</Code>。
</p>
```

**鼓励的使用场景**：

- 文件路径：`<Code inline>src/auth/middleware.go</Code>`
- 位置锚点：`<Code inline>config/app.yaml:12</Code>`
- 类 / 函数 / 方法名：`<Code inline>UserRepository.findById</Code>`
- 配置 key / enum 值：`<Code inline>FEATURE_FLAG_NEW_FLOW</Code>`
- 命令 / API 名：`<Code inline>git rebase --onto</Code>` / `<Code inline>POST /v1/orders</Code>`
- 错误 / 日志关键字：`<Code inline>connection refused</Code>`

**不要用 inline 装短句**（"这是 <Code inline>关键</Code> 决策" ← 别这样）。inline 只
装真实的代码 / 路径 / 标识符。

## 4 · `<CodeBlock>` —— 严格上限（Q9b 核心）

### 4.1 默认禁，例外严格

`<CodeBlock>` 是**默认禁用**的——Section Reviewer 在密度审计时把 CodeBlock 当作"必须
辩护"的存在。允许使用的 3 类场景：

1. **核心业务规则**：用 prose 表达会失去字面精度（如复杂的折扣计算 / 状态机判断）。
2. **已知 anti-pattern / bug 风险**：要展示"长这样的代码就是问题"，截图式价值高于
   prose。
3. **DDL / config YAML / 短的声明式 spec**：高密度 + 难复述 + 读者要复制时。

不在以上 3 类的代码段：**不要用 `<CodeBlock>`** —— 改成 prose 描述 + `<Code inline>`
标识符即可。

### 4.2 上限速查

| 维度 | 上限 |
|---|---|
| 每节 `<CodeBlock>` 数量 | **≤ 1** |
| Section 04 / 05 例外 | **≤ 2** |
| 每块 `<CodeBlock>` 行数 | **≤ 8** |
| 全文 code-char 占比 | **≤ 15%** |
| block-count / paragraphs 比 | **≤ 0.15** |

任何一项超 = Section Reviewer fail = 重写或降级。Phase 5 `scripts/audit/density.sh`
全文跑一遍兜底。

### 4.3 正确的 `<CodeBlock>` 用法

```tsx
<p>
  订单结算前，<Code inline>OrderService.Checkout</Code> 会用一段乐观锁判断库存
  （见 <Code inline>src/svc/order.go:88-95</Code>）。这段代码体现了"先扣后写"的
  关键业务规则：
</p>
<CodeBlock language="go" caption="src/svc/order.go:88-95">{`
if !inv.TryReserve(ctx, item) {
    return ErrOutOfStock
}
order.Status = StatusPaid
return repo.Save(order)
`}</CodeBlock>
```

**关键**：CodeBlock 前必须有一段 prose 解释"为什么读这段"，CodeBlock 不孤立出现。
`caption` 字段写 `file:line-line`（自动可点链接见 `references/source-pointers.md`）。

## 5 · `<Mermaid>` —— 主视觉（不计 CodeBlock 上限）

代码分析报告的视觉重心是 Mermaid，不是 CodeBlock。Mermaid 块**不计入** Q9b 上限——画
多少张图都不算"代码块"。

### 5.1 三类必出 Mermaid 的 Section

| Section | 图类型 | 何时用 |
|---|---|---|
| 02b Business Domain Map | `graph LR` 业务实体 + 关系 | architecture-review / archaeology profile 必出 |
| 03 Architecture Map | 模块依赖 `graph` | 几乎所有 profile 必出 |
| 05 Exposed Entry Points | 每个入口一张 `flowchart TD` | onboarding profile 必出；其它按需 |

### 5.2 主题 token 自动注入

`<Mermaid>` 不需要作者写颜色——主题 mermaid-init 脚本（详见
`theme-profiles/terminal.md`）会把 `--ra-*` token 注入 mermaid 渲染。作者只写 mermaid
源码：

```tsx
<Mermaid caption="OrderService 结算调用链">{`
flowchart TD
  subgraph 业务: 订单结算
    A[控制器方法 (Controller) · OrderController.create · src/api/order.go:18] --> B[OrderService.Checkout · src/svc/order.go:42]
    B --> C{库存可用?}
    C -- 是 --> D[InventoryService.Reserve · src/svc/inventory.go:55]
    C -- 否 --> E[退款分支]
    D --> F[订单状态 → paid]
  end
`}</Mermaid>
```

### 5.3 Section 05 必须 `subgraph 业务: <name>` 包裹

按 PRD Q6-business-upgrade，Section 05 的每张入口流程图**必须**用
`subgraph 业务: <业务名>` 包裹一层。业务名来自该入口 `NN-business.md` §2 关键业务规则
里的"规则名"，不能凭空起名。

如果该入口的 business.md 把它归在 §4 "业务未知" → 不要写 `subgraph 业务: ...`，改为
裸 `flowchart TD`，并在图上方 prose 显式说"本入口业务背景未知，仅展示技术调用链"。

## 6 · `<SourcePointers>` —— 每节脚部强制

每节最后必须有 `<SourcePointers>`，自动从本节 evidence.md / business.md 收集所有
`file:line` 引用，渲染为折叠 / 展开的 file:line 清单。完整组件 API 与 URL 解析规则
见 `references/source-pointers.md`。

写法：

```tsx
<SourcePointers
  pointers={[
    { file: "src/svc/order.go", line: 42, role: "evidence" },
    { file: "src/svc/order.go", line: 88, role: "evidence" },
    { file: "tests/test_order.py", line: 31, role: "business", label: "checkout refunds when inventory unavailable" },
    { file: "migrations/001_orders.sql", line: 1, role: "business" },
  ]}
/>
```

Section Reviewer 会核查：`pointers` 数组非空、每条 file:line 都能在本节
evidence.md / business.md 找到、`role` 与来源一致。

## 7 · 自定义 Raw block —— 受 Raw Policy 约束

Reacticle 有 `<Raw>` 自由层，允许作者写任意 HTML / SVG / React。在
`beautiful-codebase` 里这是**保留逃生口**，**不是常规组件**：

- **允许**：Section 07 SVG 复杂度热图、Cover 题图、极少数 mermaid 表达不了的图（如
  真实数据折线对比）。
- **禁止**：终端打字效果、代码雨、粒子背景、霓虹发光、装饰性动画。
- **token 驱动**：所有颜色 / 字体 / 间距走 `--ra-*` token，不要硬编码。
- **隔离**：> 30 行的 Raw 抽到 `article/raw-blocks/NN-*.tsx`，由对应 section import。

详细规则见 `references/raw-policy.md`。

## 8 · Reader profile / 信息密度的影响

不同 reader profile 对**组件比例**有不同期待（详见
`references/information-density.md`）。Step B Writing SubAgent 派活时主 Agent 会把
profile 直接告知，作者照着调整：

| profile | 表格频次 | Mermaid 数量 | inline 频次 | CodeBlock |
|---|---|---|---|---|
| `architecture-review · ~80%` | 高（Section 02 / 06 / 08 / 11） | 高（Section 02b / 03 / 05） | 极高 | 极少（Verdict / Risks 几乎不用） |
| `onboarding · ~65%` | 中（Quick Start / 速查表为主） | 中（Section 04 / 05） | 高（starter trail 核心） | 可达上限（Section 04 / 05 偶尔 2 块） |
| `archaeology · ~100%` | 极高（每章带文件清单表） | 高（每 Module Chapter 一张） | 极高（每个 file:line 都是档案） | 仍受 Q9b 约束，靠 inline + 表表达 |

## 9 · 禁止项（违反即 fail）

| 禁止 | 原因 | 替代 |
|---|---|---|
| 自创组件（如 `<MyCard>` / `<FeatureGrid>`） | 不在 reacticle 协议内；视觉碎片 | 用 §2 表里允许的组件 |
| 裸 `<div className="...">` / 行内 `style={...}` 含 hex / rgb | 破坏主题切换 + 风格不可控 | 走主题 token；语义重要的话用 `<Callout>` / `<Aside>` |
| 把多个 Section 写进一个 .tsx 文件 | 破坏一节一文件铁律 → 多 Agent 并行失效 | 拆成 `sections/NN-*.tsx`，由 `Article.tsx` 组装 |
| `<Article>` 之外不写 `<ThemeProvider theme="...">` | reacticle 强约束 | scaffold 已经在 `main.tsx` 包好 |
| 外部 `<img>` / 远程 URL `src` | 单文件 HTML 不可断网；asset-policy 默认 `none` | 走 `<Mermaid>` 或自带 SVG |
| `<script src="https://cdn...">` | 单文件 HTML 不能依赖 CDN | 不要做这种事 |
| 重复实现 `<SourcePointers>` 为自家 Raw | 已经是组件，不要发明轮子 | 用 `<SourcePointers>` 组件 |
| 漏 `<SourcePointers>` 节脚 | 反幻觉链断裂 | 必须有；Section Reviewer 必查 |
| `<CodeBlock>` 装"我读过的全函数"（30+ 行） | 直接违反 Q9b | 提取符号 + 业务规则做 prose 描述；只在 §4.1 三类场景用 |
| 行内"hex 颜色 + style" 写徽章 | 不走主题 | 用 `<Callout tone="...">` 或 `<Badge>`（如果主题暴露） |

## 10 · 一键速查表

| 我要表达 | 用什么 |
|---|---|
| 一段事实 / 解释 / 决策 | `<p>` prose + `<Code inline>` 锚点 |
| 一张依赖 / 入口 / 风险二维信息 | `<Table>` |
| 一张架构 / 业务实体 / 调用链图 | `<Mermaid>` |
| 一段必须看字面的核心代码（≤ 8 行） | `<CodeBlock>` |
| 一个 file:line 引用 | `<Code inline>file:line</Code>`（节脚再列一遍） |
| 警告 / 风险 / 成功 / 信息 | `<Callout tone="...">` |
| 一段引文 / 注释原文 | `<Quote>` |
| 节脚 file:line 折叠面板 | `<SourcePointers>` |
| 复杂可视化（SVG 热图 / 复杂封面） | 自定义 Raw block（在 `raw-blocks/` 隔离） |
