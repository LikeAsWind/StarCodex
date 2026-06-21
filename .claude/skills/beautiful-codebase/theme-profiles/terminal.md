# Theme Profile · terminal（代码原生暗色）

> 这是给 **AI 写作时读** 的 authoring profile，不是 CSS。CSS token 的运行时实现交给
> 组件库的 `<ThemeProvider theme="terminal">`，本文件描述"如何选择和使用这个主题"。
> `beautiful-codebase` 的默认主题，专为**代码分析报告**设计。

- **runtime theme id**：`terminal`（`<ThemeProvider theme="terminal">`）
- **气质**：暗底终端 + 等宽显示 + 语义色承载代码分析原语。它不是"装成 IDE
  截图"——是把读者放进一份**被精心排版过的源码审阅**：暗纸感的深背景、克制的
  发丝级网格、用颜色精确标记**关键字 / 字符串 / 注释 / 风险 / 警告 / 状态 / 业务实体**。
  目的是让 30 分钟做架构判断、第二天上手第一个 issue、或做长期归档的人，都能在
  同一份报告里读到适合自己的密度与重点。

## 1 · 主题意图（Theme Intent）

代码分析报告天生有几个独特的视觉负担：(a) 大量的 `file:line` 引用，需要 inline 等宽且不
喧宾夺主；(b) 风险 / 警告 / 状态徽章在 Section 08 / 06 / 09 反复出现，必须用一致的语义色
而不是任意装饰色；(c) 业务实体图（Section 02b）和入口流程图（Section 05）的节点颜色需要
和 Section 04 的模块走查 / Section 07 的复杂度热图保持互译；(d) 全文要尊重 Q9b 的"代码尽量
少、Prose 优先"——所以代码块要看得舒服但**不要诱人多写**。

terminal 主题用一组**冷暗中性底 + 7 个语义色 + 2 个等宽字体角色**完成全部任务：暗底是底
盘、等宽承载身份、语义色承载含义。任何"装饰用色"——包括 IDE 主题里常见的紫色 / 橙色 /
青色光斑——都被禁掉。

## 2 · Token 表（暗色基线）

> 所有 token 走 `--ra-*` 命名空间。`--ra-terminal-*` 为本主题独有，其余继承组件库通用 token。
> 颜色值是**暗色基线**；浅色变体（如打印 / 高对比模式）由组件库运行时切换，作者不需要写。

### 2.1 表面与边界 · Surface & Border

| Token | Hex（暗） | 用途 | 主要使用位置 |
|---|---|---|---|
| `--ra-terminal-bg` | `#0E1116` | 全文最底盘色（页面背景、Article 容器底） | `<body>` / `<Article>` 根 |
| `--ra-terminal-surface` | `#161A21` | 区块抬升一层（Hero、Section、表格、CodeBlock 容器） | `<Section>` / `<Card>` / `<CodeBlock>` |
| `--ra-terminal-surface-2` | `#1D232C` | 比 surface 再抬一层（hover 行、边注、二级面板、Source Pointers 折叠面板） | `<aside>` / 折叠面板 |
| `--ra-terminal-border` | `#262B34` | 发丝级分割线、表格边框、CodeBlock 外框 | 一切内部分隔线 |
| `--ra-terminal-border-strong` | `#3A4150` | 节级分隔、Section 之间、终结性边框 | Section 之间的 hr |
| `--ra-terminal-fg` | `#E6E6EC` | 正文主色（中文 prose + 英文混排） | `<p>` / 默认文字 |
| `--ra-terminal-fg-mute` | `#A7A9B4` | 次要文字（caption / footnote / source pointer 引用） | `<small>` / `<caption>` |
| `--ra-terminal-fg-dim` | `#6F7280` | 极次要（colophon / 时间戳 / inventory 元数据） | colophon / footer 元信息 |

### 2.2 代码语法语义色 · Code Semantic Tokens

| Token | Hex | 用途 | 主要使用位置 |
|---|---|---|---|
| `--ra-keyword` | `#C792EA` | 关键字（`if/for/return/class/def/func`），保留字 | inline `<Code inline>` 的 keyword token、`<CodeBlock>` Prism 主题 |
| `--ra-string` | `#A8E27E` | 字符串字面量（含路径字面量、URL 字面量） | 同上 |
| `--ra-comment` | `#6F7280` | 注释、JSDoc、文档字符串 | 同上；与 `fg-dim` 同色，刻意让注释退后 |
| `--ra-identifier` | `#E6E6EC` | 标识符（变量名 / 函数名）默认色 = 正文色 | 同 fg |
| `--ra-type` | `#82B7FF` | 类型名 / 接口名 / 模块名 | TypeScript / Java / Rust 类型注释、Mermaid 节点上的类名 |
| `--ra-number` | `#F5C76A` | 数字 / 常量 / 布尔 | Prism token、表格中的度量值 |

### 2.3 状态语义色 · Status / Risk Tokens（核心，跨 Section 复用）

| Token | Hex | 用途 | 主要使用位置 |
|---|---|---|---|
| `--ra-risk-red` | `#FF6B6B` | 高风险、阻塞性问题、CVE 高分、必修项 | Section 08 风险徽章 / Section 06 CVE 高危 / Section 07 复杂度红区 |
| `--ra-warn-amber` | `#F5C76A` | 警告、需关注、中等风险、TODO 密度高的模块 | Section 08 警告 / Section 07 复杂度黄区 / Section 09 决策风险点 |
| `--ra-status-green` | `#7FD18C` | 正常、已完成、测试覆盖良好、低风险 | Section 07 复杂度绿区 / Section 06 依赖健康 / 验收 OK 徽章 |
| `--ra-status-blue` | `#82B7FF` | 信息、模块名、入口角色、业务实体高亮 | Section 03 / 04 模块色 / Section 05 节点 / Section 02b 实体 |
| `--ra-status-violet` | `#C792EA` | 业务规则 / 决策点 / 异步链路标注 | Section 05 业务子图标签 / Section 09 决策标注 |

### 2.4 字体角色 · Type Roles

| Token | 实际值 | 用途 |
|---|---|---|
| `--ra-mono-display` | `"JetBrains Mono", "Fira Code", "IBM Plex Mono", ui-monospace, monospace` | 标题、徽章、入口角色标签、表头、CodeBlock 内文。需要等宽 + 一定的设计感（连字 / 等宽数字）。 |
| `--ra-mono-text` | `ui-monospace, "SF Mono", "Cascadia Code", Consolas, monospace` | inline `<Code inline>` 内文。优先系统字、确保 file:line 不发生奇怪连字。 |
| `--ra-sans` | `"Inter", "PingFang SC", "Source Han Sans SC", system-ui, sans-serif` | 正文 prose（中文 + 英文混排）。terminal 主题的正文**不是**等宽——只有标题、代码、徽章是。 |
| `--ra-serif` | 不使用 | terminal 主题禁用衬线。 |

### 2.5 度量 · Sizes & Spacing

| Token | 值 | 用途 |
|---|---|---|
| `--ra-size-body` | `15.5px` | 正文 prose 字号；比 tufte 的 16px 略小 0.5px，因为暗底视觉重量更重 |
| `--ra-size-code-inline` | `0.92em` | inline `<Code inline>` 相对于正文的字号 |
| `--ra-size-code-block` | `13.5px` | `<CodeBlock>` 内字号；比 inline 略小，避免代码块视觉抢戏（呼应 Q9b） |
| `--ra-line-height-body` | `1.7` | 暗底正文行距，比 tufte 的 1.6 略宽，疏松眼睛 |
| `--ra-radius` | `4px` | 唯一允许的圆角（badge、CodeBlock 容器）；不要更大，避免"卡片感" |
| `--ra-grid` | `0.5px solid var(--ra-terminal-border)` | 发丝级网格线；表格、Section 分割都用它 |

## 3 · 排版规则（Typography）

- **正文**：`--ra-sans`，`--ra-size-body`，`--ra-line-height-body`，颜色 `--ra-terminal-fg`。
  中英混排时英文沿用 `Inter`（与中文同行），不另切等宽——等宽留给身份标记。
- **标题**：`--ra-mono-display`，字重 500（不要 700，会糊），字号梯度 `H1 28px / H2 22px /
  H3 18px / H4 16px`。**所有标题大写不强制**——保持自然中英混排即可。
- **inline `<Code inline>`**：`--ra-mono-text`，`0.92em`，颜色 `--ra-terminal-fg`，背景
  `--ra-terminal-surface-2`，左右内 padding `0.25em`，**无边框**。这是 Q9b 鼓励大量使用的
  identifier 引用形式，所以视觉成本必须低——不要给它加发光边框、不要加粗。
- **`<CodeBlock>`**：见下文 Component-level guidance。
- **徽章 / Tag**：`--ra-mono-display`，11.5px，全大写允许（仅徽章），`--ra-radius` 圆角，
  仅用 §2.3 的状态色，**不要任意上色**。
- **行内强调**：粗体用 `--ra-status-blue` 描色（不用更深的字重，暗底加粗会糊），引用文字
  用 `--ra-terminal-fg-mute`。
- **链接**：`--ra-status-blue`，下划线发丝，hover 时下划线变实。
- **禁用斜体**——和 tufte 一致，斜体在等宽上下文里几乎不可读。

## 4 · 组件级写作指南（Component-level guidance）

> 下面这一段描述的是"作者在写作时应该让组件长成什么样"。具体 CSS 由组件库实现，作者
> 只需要按这个心智模型选择正确的组件。

### 4.1 徽章 / Risk Pills（Section 08 / 06 / 09 反复用）

每个徽章 = 等宽小写文字 + `--ra-radius` 圆角矩形 + 单色块底（用 §2.3 的状态色加 12-18%
透明度作为背景，文字用对应纯色）。形如：

```
[BLOCKER]   ← 背景 #FF6B6B22, 文字 #FF6B6B
[WARN]      ← 背景 #F5C76A22, 文字 #F5C76A
[OK]        ← 背景 #7FD18C22, 文字 #7FD18C
[INFO]      ← 背景 #82B7FF22, 文字 #82B7FF
[BUSINESS]  ← 背景 #C792EA22, 文字 #C792EA
```

**严禁**两件事：(a) 多色渐变徽章；(b) 在徽章里塞 emoji 或图标。terminal 主题的徽章
就是"打印体小标签"——读到的人能立刻在脑子里把它对应到一个语义类别。

### 4.2 表格

- 边框：仅顶 / 底两条 `--ra-terminal-border-strong`，行间用 `--ra-grid` 发丝线。**没有竖
  线**，参照 tufte。
- 表头：`--ra-mono-display`，`--ra-terminal-fg-mute`。
- 数值列右对齐；文字列左对齐；status 列居中且只填徽章。
- 行 hover 浅淡（`--ra-terminal-surface-2`）；不要 zebra。

### 4.3 Mermaid 流程图（Section 02b / 03 / 05）

terminal 主题为 mermaid 注入一组主题变量（实现层面通过 `mermaid.initialize({ theme:
'base', themeVariables: { ... } })`），让作者在 plan / writing 阶段不需要逐图写颜色：

| Mermaid 变量 | 取值（terminal 暗色） | 含义映射 |
|---|---|---|
| `background` | `--ra-terminal-bg` | 图底 = 页面底，无缝 |
| `primaryColor` | `--ra-terminal-surface-2` | 默认节点背景 |
| `primaryBorderColor` | `--ra-status-blue` | 默认节点边框（信息蓝） |
| `primaryTextColor` | `--ra-terminal-fg` | 节点文字 |
| `lineColor` | `--ra-terminal-border-strong` | 普通边 |
| `tertiaryColor` | `--ra-status-violet` | `subgraph 业务: ...` 子图边框（业务紫） |

Section 05 的角色色映射（写在 mermaid 节点 class 上，作者只需写 `class FooNode controller`
之类）：

| 角色 class | 颜色 | 含义 |
|---|---|---|
| `controller` | `--ra-status-blue` | 控制器方法 / Webhook / WebSocket |
| `scheduled` | `--ra-warn-amber` | 定时任务 / Init loader |
| `consumer` | `--ra-status-green` | 消息消费者 / Event listener |
| `cli` | `--ra-keyword` | CLI 命令 |
| `middleware` | `--ra-terminal-fg-mute` | 中间件 |
| `risk` | `--ra-risk-red` | 标记为 Section 08 风险点的节点 |

异步边用 mermaid 的 `-.->` 虚线 + edge label 标注触发条件（"by cron / on event /
async dispatch"）。

### 4.4 Inline code

inline 是 terminal 主题的"身份元素"——`file:line`、类名、方法名、配置 key、错误码
都是 inline。视觉成本必须低（见 §3）。**鼓励大量使用**——这是把代码分析的精确度安全
地塞进 prose 的最佳手段（呼应 Q9b 的 substitution priority）。

### 4.5 CodeBlock（Q9b 严格上限）

`<CodeBlock>` 在 terminal 主题下的设计目标是"看起来像一段被精心引用的源码节选"，**不
是 IDE 截图**。

- 容器：`--ra-terminal-surface` 底，`--ra-terminal-border` 发丝边，`--ra-radius` 圆角。
- 标题栏（如有）：仅一行小字 `--ra-terminal-fg-mute`，写 `path/to/file.ts:120-128`。
  没有 macOS 红绿灯，没有 tab。
- 行号：`--ra-terminal-fg-dim`，与正文大小相同。
- Prism token 着色按 §2.2 的语义色——**和 inline `<Code inline>` 一致**，让读者在 inline
  和 block 之间迁移视觉时是"放大／缩小"而不是"换主题"。
- **每节最多 1 块、每块最多 8 行**（Q9b 硬上限；Section 04 / 05 例外允许 ≤ 2 块）。

### 4.6 Source Pointers 折叠面板（每节脚部）

底部一个 `--ra-terminal-surface-2` 的折叠区，等宽小字 `--ra-mono-text` 列出本节引用过
的所有 `file:line`。如果 Phase 0 抓到 git remote，每条渲染成可点链接（颜色
`--ra-status-blue`，下划线发丝）。**这是导航锚点，不是代码块**——不要塞代码内容。

### 4.7 复杂度热图（Section 07，SVG）

terminal 是少数几个明确允许 SVG 的 Section。配色直接走 §2.3 的红 / 黄 / 绿三色，每格一个色块
+ 等宽 file 名标签。背景 = `--ra-terminal-bg`；网格线 = `--ra-terminal-border`。

## 5 · 封面构图起手（Cover）

terminal 主题的封面**不能**是终端窗口截图（太字面、太装饰）。推荐起手：

> **冷暗底盘 + 一组发丝级"代码地形" + 一行项目身份标识**。
> 主视觉用 SVG / Canvas 画出项目的**模块拓扑骨架**——把 Section 03 Architecture Map
> 的简化版用 `--ra-status-blue` 发丝线在封面上呈现出来，节点用 `--ra-terminal-surface-2`
> 小方块。文字层只有三段：项目名（`--ra-mono-display` 大字号 28px）、副标题
> "Codebase Analysis · <reader-profile>"、底部一行 colophon 占位
> "Made with [beautiful-codebase] · terminal theme"。比例严格 3:4，PDF 独占首页。
> 视觉技术（SVG / Canvas / 复杂 React 组件）按封面 reference 的"全开放"原则自由选择，
> 但配色不出 terminal token 集合。

## 6 · 不同 Reader Profile 下的微调（建议，非限制）

- `architecture-review`：徽章频率高、流程图密集、CodeBlock 极少。整篇视觉重量分布
  在 Section 03 / 05 / 08。
- `onboarding`：流程图保留、徽章频率中、Section 02 Project at a Glance 的扫读密度可以
  更高。
- `archaeology`：开放 Section 06 / 07 / 09 / 11 等 optional 全开；Source Pointers 折叠
  面板**默认展开**而不是收起。

## 7 · 禁止项

- 紫 / 青 / 橙 / 粉的"装饰渐变"——任何 §2 之外的颜色。
- 大圆角（>4px）、玻璃拟态、霓虹发光、粒子背景、CRT 扫描线滤镜——这是"代码分析报
  告"，不是赛博风海报。
- 在 Raw 里堆"代码雨 / matrix 字符流 / 仿终端命令打字效果"。
- emoji / 装饰图标当 status 标记（必须用 §4.1 的徽章）。
- 把 mermaid 节点用十几种自定义色——**只用 §4.3 的 6 个 class 色**。
- 强行把正文也变成等宽——会让 5000 字的报告无法读完。

## 8 · 示例用法（说明性，非可运行代码）

下面三段示意 terminal 主题下作者的"心智 API"，实现细节由组件库 + scaffold 提供。

### 8.1 一段典型 Section 04 模块走查的混排

```
<Section id="04-module-walkthrough">
  <h2>04 · 模块走查</h2>
  <p>
    入口模块 <Code inline>src/services/order/OrderService.java</Code> 集中了
    下单 / 取消 / 退款三个用例，依赖 <Code inline>OrderRepository</Code> 与
    外部支付网关 <Code inline>PaymentGateway</Code>。下面是这三个用例的调用骨架。
  </p>
  <Mermaid src={callChain04A} />
  <p>
    其中 <Badge tone="warn">WARN</Badge> 出现在退款分支：见
    <Code inline>OrderService.java:284-302</Code>，与 Section 08 风险 R-03 关联。
  </p>
  <SourcePointers items={[...]} />
</Section>
```

### 8.2 Section 08 风险徽章组

```
<RiskRow>
  <Badge tone="risk">BLOCKER</Badge>  R-01 · 支付幂等键缺失
  <Badge tone="warn">WARN</Badge>     R-03 · 退款分支吞异常
  <Badge tone="info">INFO</Badge>     R-07 · 缓存 TTL 未集中配置
</RiskRow>
```

### 8.3 Section 05 入口流程图（伪 mermaid）

```
flowchart TD
  subgraph 业务: 订单提交
    A["控制器方法 (Controller)<br/>OrderController.submit<br/>order/Controller.java:84"]:::controller
    B["OrderService.place<br/>order/Service.java:120"]:::middleware
    C["PaymentGateway.charge<br/>payment/Gateway.java:55"]:::middleware
    D["OrderRepository.save<br/>order/Repo.java:33"]:::middleware
    A --> B --> C
    B --> D
    C -.->|"async · webhook callback"| E["WebhookController.onPaymentResult<br/>payment/WebhookController.java:21"]:::controller
  end
```

`classDef` 的具体 6 个 class 见 §4.3。

---

> 本 profile 是 v0.1.0 的基线设计。如果实际 dogfood 跑出来发现某个 token 在
> StarCodex 项目里读起来吃力，**回到本文件改 token 表**，不要在单个 Section 里
> 写 inline style 覆盖。
