---
name: beautiful-codebase
description: "把任意代码项目（语言无关：Java / Python / Go / TS / Rust / …）做成一份**单文件 HTML 代码分析报告**——自包含、可离线打开、可分享。基于 codegraph 调用图（唯一真源），从代码结构本身分析业务功能链路、项目架构、调用拓扑，输出固定章节的分析报告。不回退到注释/commit 等不可信输入。"
---

# Beautiful Codebase

## 背景原则

代码分析报告的价值在于**可信 + 可控**。

**可信**：唯一真源是 codegraph 调用图——编译器/解释器验证过的调用关系，不会撒谎。没有 codegraph 时回退到 rg/grep 文本匹配（标注精度降级）。注释、commit message、文档等人工输入**不作为证据源**。

**可控**：每篇报告的章节结构是**固定的，不可由 AI 随意增减**。每章内容模板固定，不因 AI 的"风格"或"理解"而改变。核心流程只有发现→规划→生成→交付四个阶段，不包含需要 AI "创造"或"审美"的环节。

## 边界

- 最终产物是 **single-file HTML 代码分析报告**，不是网页应用/dashboard/可视化工具/文档站。
- **不主动**对目标项目做任何写入，唯一例外是 Phase 0 用户显式同意时跑 `codegraph init` 写 `.codegraph/`。
- 分析深度由 codegraph 入口点检测 + 调用图遍历自动决定。
- 如果用户要的是"改造这个项目" / "写个新功能" / "做个 dashboard 看代码指标"——停下来澄清，不要进入本 Skill。

---

## 工作流总览（4 Phase）

```
Phase 0  Intake            判断是否进入 Skill + 捕获目标项目路径 + 工具探测
    ↓
Phase 1  Discover          工具探测 → 入口点发现 → 调用图采集 → inventory
    ↓
Phase 2  Plan              写 plan/plan.md（章节列表固定，只填模块链路表）
    ↓
Phase 3  Delivery           构建 article.html + 交付
```

### Phase 0 · Intake

判断是否进入本 Skill，探测工具链。

| 用户给的东西 | 该做的 |
|---|---|
| 一个代码项目路径 | 进入 Phase 1 |
| 说"分析这个项目"但没给路径 | **反问**：项目路径是什么？ |

**工具探测**：
运行 `scripts/probe-tools.sh --target <path> --json`：
- `codegraph` 是否在 PATH，目标项目是否已 `codegraph init`（`.codegraph/` 存在）
- `rg` 是否在 PATH
- `grep`（POSIX）

输出 tier：`codegraph-indexed` / `codegraph-installed` / `rg` / `grep` / `none`

**codegraph init 确认**（仅当 tier = `codegraph-installed`）：
```
目标项目没有 codegraph 索引（.codegraph/ 不存在）。
要运行一次 `codegraph init` 吗？（约 30 秒到几分钟，会向项目根写 .codegraph/ 目录）
  A · 现在运行（推荐·精度最高）
  B · 不用，降级到 rg/grep（更快·精度下降）
  C · 我自己稍后跑，先停
```

**Phase 0 产出**：`discovery/tools.json`（tier 标签）

---

### Phase 1 · Discover

自动发现，无需用户参与。

#### 1.1 生成 inventory

运行 `inventory.sh`（与原来一致），输出 `discovery/inventory.json`：
- 所有分析文件路径、语言、行数、SHA
- excluded 文件列表（vendor/generated/fixtures）
- 统计信息（总文件数、分析文件数、总 LOC、按语言分布）

#### 1.2 发现入口点

基于 codegraph（或 rg/grep 回退）检测所有对外暴露的入口：

| 方式 | 检测模式 |
|---|---|
| codegraph | 查找所有被外部引用为入口的函数（controller/handler/router/main） |
| rg | `def.*handle` / `def.*route` / `def.*main` / `app\.(get|post|put|delete)` |
| grep | 同上 |

输出 `discovery/entrypoints.json`：
```json
{
  "tier": "codegraph-indexed",
  "entries": [
    {
      "id": "order-create",
      "name": "下单流程",
      "entry": "src/routers/order.py:25:create_order_handler",
      "source": "codegraph",
      "files_involved": 12,
      "depth": 5,
      "description": "基于代码结构推断：处理用户提交订单请求"
    }
  ]
}
```

每条入口自动生成业务描述（基于函数名/路由路径/参数名推断，标注"基于代码结构推断"）。

#### 1.3 采集调用图

对每个入口点，递归采集完整调用链路：

使用 `codegraph explore <entry_symbol>` 或 `codegraph node <symbol>` 逐层展开。

输出 `discovery/callgraphs/` 目录，每入口点一个 JSON：
```json
{
  "entry_id": "order-create",
  "entry_file": "src/routers/order.py",
  "entry_line": 25,
  "call_tree": [
    {
      "symbol": "validate_order",
      "file": "src/services/order.py",
      "line": 12,
      "callers": [],
      "callees": [
        {"symbol": "Product.get_by_id", "file": "src/models/product.py", "line": 88}
      ]
    }
  ]
}
```

**tier 回退**：
- `codegraph-indexed` / `codegraph-installed`：精确调用图
- `rg`：正则匹配调用关系（低精度，标注 "call graph: rg-based (low precision)"）
- `grep`：同上，更低精度

#### 1.4 生成代码摘要

对每个涉及的文件，收集：
- 文件路径
- 导出函数/类列表（codegraph query 或 text 扫描）
- 函数签名

输出 `discovery/summary.json`

#### Phase 1 产出

```
discovery/
  tools.json              # tier 标签
  inventory.json          # 文件清单
  entrypoints.json        # 入口点列表（含 AI 推断的业务描述）
  callgraphs/             # 每个入口点一个调用树 JSON
    order-create.json
    refund-create.json
    ...
  summary.json            # 文件级代码摘要
```

**Phase 1 自检**（主 Agent 内联，不开 SubAgent）：
1. [ ] `entrypoints.json` 非空（至少一个入口点；空则标记"项目无外部入口，生成空报告"）
2. [ ] 每个入口点至少有一条调用链路
3. [ ] `inventory.json` 与 `entrypoints.json` 引用的文件一致
4. [ ] 每个文件的摘要中导出的函数已覆盖

---

### Phase 2 · Plan

章节结构**固定**，Plan 只是填写数据，不是创作。

章节模板：

| # | 标题 | 固定 | 数据来源 |
|---|------|------|---------|
| 00 | Cover | 固定 | inventory.json 统计 + 项目路径 |
| 01 | 项目概览 | 固定 | codebase-brief + entrypoints |
| 02 | 业务功能总览 | 固定 | entrypoints.json |
| 03 | 项目架构图 | 固定 | codegraph 模块依赖 / rg fallback |
| 04..N | 功能链路章节 | 按入口点数量扩展 | callgraphs/ 每个入口点一章 |
| N+1 | 总结 | 固定 | 全局分析汇总 |
| N+2 | Colophon | 固定 | beautiful-codebase 署名 |

**每章第 N 章（功能链路）的内部结构同样固定**：

```
## <链路名>

### SVG 调用链路图
（AI 基于 callgraph JSON 绘制 SVG）

### 完整调用列表
（逐层展开的 file:line，可折叠）

### 业务分析
（基于代码结构和命名推断的业务描述，标注"基于代码结构推断"）

### 调用链分析
- 亮点：（基于客观指标：错误处理覆盖、解耦程度、接口清晰度等）
- 不足：（基于客观指标：调用链深度、循环依赖、缺少错误处理等）
- 优化空间：（基于不足给出具体建议 + 优先级）

[高/中/低] 优化提案标题
```

Plan 输出单个文件：`plan/plan.md`，只包含：
```markdown
# Plan

## Brief
- 目标项目：<path>
- 工具 tier：<codegraph-indexed|rg|grep>
- 入口点数量：<N>
- 章节数量：<3 + N + 2>
- 章节列表：
  - 00 Cover
  - 01 项目概览
  - 02 业务功能总览
  - 03 项目架构图
  - 04 <链路1名>
  - 05 <链路2名>
  - ...
  - <N+1> 总结
  - <N+2> Colophon

## Entrypoints 确认
| ID | 名称 | 入口 file:line | 涉及文件数 | 调用深度 |
|----|------|---------------|-----------|---------|
```

**没有 Checkpoint，没有用户决策点**。Phase 2 写完 plan.md 即完成，直接进入 Phase 3。

---

### Phase 3 · Delivery

#### 3.1 创建工程

scaffold 创建 Vite + React + TS 工作区：
```bash
bash <skill>/scripts/scaffold.sh ./<project>-analysis --theme=terminal
```

scaffold 后的工作区结构：
```
<project>-analysis/
  article/
    Cover.tsx            # Phase 3 主 Agent 写
    Article.tsx          # Phase 3 主 Agent 写（assembler）
    sections/
      01-overview.tsx    # Phase 3 写
      02-modules.tsx     # Phase 3 写
      03-architecture.tsx
      04-<slug>.tsx      # 每条链路一章，主 Agent 逐个生成
      05-<slug>.tsx
      ...
      NN-summary.tsx
      NN-colophon.tsx
  discovery/             # Phase 1 产出
  plan/plan.md           # Phase 2 产出
  index.html package.json vite.config.ts ...
```

#### 3.2 生成章节

**章节生成规则**：

每个章节走四阶段 sub-agent 管线（完整规范见 `references/section-build.md`）。
Step A Evidence SubAgent -> Step A.5 Business Distill -> Step B Writing SubAgent -> Section Reviewer。


证据链：
```
① codegraph callgraph JSON（唯一真源）
② rg/grep 回退（标注精度降级）
③ 代码文件本身（函数签名、类型定义、参数名补充）
```

**SVG 流程图生成规则**（见 `references/component-policy.md`）：
- 基于 `callgraph JSON` 翻译为中文业务描述
- 每个节点：中文名 + `file:line` 标注
- 调用方向用箭头连接
- 错误路径用虚线/不同颜色
- 样式用 `--ra-*` token，跟随主题

**禁止**：
- ? 引用注释内容作为证据
- ? 引用 commit message
- ? 引用文档/README
- 保持流程图节点中文优先（详见 references/component-policy.md）
- ? 添加非固定结构的任何额外章节

**每个章节都遵循"先写确定性内容（调用图/列表），再写分析"**的顺序。

#### 3.3 质量验证

每写完一个章节，主 Agent 内联自检（不开 SubAgent）：

调用链验证：
1. [ ] SVG 流程图中的每个节点都能在 `callgraph JSON` 中找到对应
2. [ ] 展开的调用列表与 SVG 流程图的节点数一致
3. [ ] 每个 file:line 在 inventory 中存在
4. [ ] "业务分析"段落标注了"基于代码结构推断"
5. [ ] 亮点/不足/优化都基于调用链客观指标，没有空话
6. [ ] SVG 不依赖外部资源（字体用 `--ra-*` token，颜色用 `--ra-*` token）

#### 3.4 构建

```bash
npm run build    # tsc --noEmit + vite build
npm run html     # 复制到 article/article.html
```

验证交付物：
- `file://` 协议离线打开
- 所有 SVG 流程图正常渲染
- TOC 链接可点击跳转
- 字体正确（不是 fallback 到系统 sans-serif）
- 控制台无 404

#### 3.5 交付

输出：
```
article/article.html          # 主交付物
analysis-snapshot.json        # 元数据快照
```

**无 PDF 输出**——PDF 是静态快照，SVG 流程图在 PDF 中不需要额外处理（已经是图片），但如果用户要求可以后续加。

---

## 硬性质检协议

| 节点 | 质检方式 | 产物 | 为什么 |
|---|---|---|---|
| Phase 1 末尾 | 主 Agent 内联 4 条 checklist | 无文件 | 数据都是机器产出，主 Agent 通读自查即可 |
| Phase 3 每章 | Section Reviewer SubAgent 消息返回 pass/fail | 无文件 | SubAgent 独立审计，比主 Agent 自检更客观 |
| 全部写完 | 主 Agent 通读验证 | 无文件 | 章节数量固定，通读一遍即可 |

---

## 成功标准

- 报告结构**严格遵循固定模板**，每章内容次序一致
- 每个 file:line 都可以溯源到代码
- SVG 流程图**漂亮、易读、统一风格**
- 40% 信息时读起来像被认真编辑过的文章而非大纲，100% 时像精修过的长文

---

## 引用文件索引

| 文件 | 何时读 | 内容 |
|---|---|---|
| `references/discover.md` | Phase 1 | 入口点发现、调用图采集、inventory 生成 |
| `references/plan-template.md` | Phase 2 | 固定模板填写指南 |
| `references/section-build.md` | Phase 3-4 | 基于调用图的四阶段章节构建流程 |
| `references/component-policy.md` | Phase 3 | SVG 流程图规范、组件使用边界 |
| `references/raw-policy.md` | Phase 3 | SVG 绘制规则、Raw 自由层边界 |
| `references/cover.md` | Phase 3 写封面时 | 3:4 封面设计指南 |
| `references/html-output.md` | 构建/交付时 | dev / build / 交付命令 |
| `references/layout.md` | 布局决策 | 版式宽度、TOC 位置、页面结构 |
| `references/business-evidence-collection.md` | Phase 1 | 6 类业务证据采集 |
| `references/source-pointers.md` | Phase 4 | 节脚 file:line 引用面板 |
| `references/information-density.md` | Phase 1 | Reader profile 标配带宽 |
| `references/scaffold.md` | Phase 3 | 脚手架结构说明 |
| `references/harness.md` | Phase 3.1 | 构建 harness 说明 |
| `references/asset-policy.md` | Phase 3 | 内联资源策略 |
| `references/bucket-strategy.md` | Phase 1 | 切桶策略 |
| `references/complexity-tools.md` | Phase 5 | 代码复杂度检测 |
| `references/entry-point-taxonomy.md` | Phase 1 | 入口点分类 |
| `references/repair-policy.md` | 修复时 | 修复策略 |
| `references/theme-selection.md` | Phase 1 | 主题选择指南 |
| `references/pdf-output.md` | 交付 | PDF 输出规范 |
| `references/review-checklist.md` | 终审 | 终审检查清单 |
| `profiles/` | Phase 1 | 预设读者画像（archaeology/architecture-review/onboarding） |
| `theme-profiles/terminal.md` | 默认主题 | 暗底等宽、语义色、组件级写作指南 |
| `prompts/step-a-evidence.md` | Phase 4 | Step A Evidence SubAgent prompt |
| `prompts/step-a5-business.md` | Phase 4 | Step A.5 Business Distill SubAgent prompt |
| `prompts/step-b-writing.md` | Phase 4 | Step B Writing SubAgent prompt |
| `prompts/section-reviewer.md` | Phase 4 | Section Reviewer SubAgent prompt |
