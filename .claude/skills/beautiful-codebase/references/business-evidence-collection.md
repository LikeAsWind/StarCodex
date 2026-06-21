# Business Evidence Collection · 业务证据采集（Phase 1 扩展扫描）

> **何时读**：Phase 1 Discover 进入"业务证据"子阶段（即跑 `business-evidence.sh`）时；
> Phase 4 每节 Step A.5 Business Distillation SubAgent 开工时（写 `NN-business.md`）。

`beautiful-codebase` 的核心创新之一：报告必须解释**业务背景与业务规则**，但 Skill 不能
凭空发明业务——只能从 repo 已有证据里重建。本文件定义 6 类证据的采集规则、引用约束、
以及 `NN-business.md` 模板骨架。

## 1 · 6 类证据文件总览

`discovery/business-evidence/` 下：

| 文件 | 它在反映什么 | 它适合支持什么业务陈述 |
|---|---|---|
| `comments.jsonl` | 开发者自己对意图 / 边界条件 / 业务规则的描述 | "代码本意是 X"——直接引用注释最有说服力 |
| `tests.jsonl` | 测试名 + 断言关键词描述"期望行为" | "系统在 X 场景下应该 Y" |
| `schema.md` | DB DDL / 迁移 / ORM tag 揭示数据模型 | 业务实体之间的关系；字段语义 |
| `configs.md` | 配置文件 + enum 常量 | 业务词汇 / 业务状态机 / 阈值 |
| `docs.md` | README / `docs/` 揭示项目自述的业务定位 | "这个项目本意是 X" |
| `commit-themes.md` | 近 200 commit 的演化主题 | 近期重心 / 业务节奏 / 高维风险 |

**心法**：每一类都是**线索**，不是 ground truth。Step A.5 SubAgent 把多类线索交叉印证
（例如：注释说 "post-payment fulfillment"、commit theme 说 "feat: payment"、schema 有
`payments` 表）——三者一致才能写成 confident 的业务陈述；任一条单独存在就要降级表述。

## 2 · comments.jsonl · 文档注释

每行 JSONL：

```json
{"file": "src/svc/order.go", "line": 42, "symbol": "OrderService.Checkout", "text": "// 完成订单结算并触发付款"}
```

字段：

- `file` — 相对路径。
- `line` — 行号（1-based）。
- `symbol` — 如能解析到符号则填；否则空串。
- `text` — 注释正文（含注释起始标记，便于人眼区分）。

**抽取规则**（按语言）：

| 语言 | 模式 |
|---|---|
| Python | `"""..."""` / `'''...'''` 三引号 docstring 起始行（best-effort，只抓起始） |
| JS / TS / Java / C / C++ / Rust | `/** ... */` JSDoc / Javadoc 起始行 |
| Go | 每个 `// ` 起始的连续行（`// ` 之上接 `func`/`type` 的尤其重要） |
| Rust | `///` doc comment |

**注意**：`business-evidence.sh` 当前只抓**起始行**，不抓多行 body。SubAgent 在引用
时如需读完整 body，按 `file:line` 回到 inventory 找到那个文件，由 Step A SubAgent
（不是 Step A.5）在 `NN-evidence.md` 里把完整 verbatim 块引出来。Step A.5 引用注释
是引用 file:line 这一个锚点。

## 3 · tests.jsonl · 测试名 + 断言关键字

每行 JSONL：

```json
{"file": "tests/test_order.py", "line": 31, "name": "test_checkout_refunds_when_inventory_unavailable", "assertions": []}
```

字段：

- `file` / `line` — 测试函数定义所在位置。
- `name` — 函数 / `it` / `describe` 名。
- `assertions` — 当前 v0.1.0 默认空数组；SubAgent 可以在写 `NN-business.md` 时按
  `file:line` 回到 inventory 找到测试内的 `assert*` / `expect*` 关键字。

**框架识别**（按语言 / 框架）：

| 语言 / 框架 | 模式 |
|---|---|
| Python pytest / unittest | `def test_*` |
| Go testing | `func Test*` |
| Java JUnit | `@Test` 注解 |
| JavaScript / TypeScript (Jest / Mocha / Vitest) | `it(...)` / `describe(...)` / `test(...)` |

**为什么测试名是业务线索**：好的测试名直接表达"系统在 X 条件下应该 Y"，比代码本身更
靠近业务规范。

## 4 · schema.md · DDL / 迁移

格式：单 Markdown 文件，含若干段：

- **SQL files**：找到的 `.sql` 文件列表 + 每个文件里 `CREATE TABLE` 的表名汇总。
- **Migration files**：`migrations/`, `migrate/`, `schema/`, `db/migrate/`,
  `alembic/versions/` 目录下的文件列表。
- **GORM struct tags (Go)**：扫描 `gorm:"..."` 标签出现位置（每行 file:line）。
- **Prisma schema**：`.prisma` 文件列表。

**未来扩展（v0.2 backlog）**：TypeORM `@Entity()`、SQLAlchemy `class X(Base)`、
Hibernate `@Table` 等的 ORM-aware 抽取；目前由 GORM tag + Prisma + SQL DDL 覆盖最常
见情形。

**没找到任何 DB 工件时**：文件写入 `(no DB schema found)`。Phase 4 Section 02b
Business Domain Map 的 SubAgent 看到这个字符串 → 该 Section 显式标 "本项目无业务实体,
跳过"（PRD AC9 要求的确切字符串）。

## 5 · configs.md · 配置 + enum

格式：单 Markdown 文件，含两段：

- **Detected config files**：根目录及子目录里的 `config*.{yml,yaml,toml,json,properties,ini,env}`、
  `application*.{yml,properties}`、`.env*` 文件路径列表（前 50 行）。
- **Enum / const candidates**：跨语言扫描 `enum X`、`const X`、`type X = ...` 等
  定义的 file:line + 起始行文本（前 50 行）。

**为什么 enum 是业务高密度区**：例如 `OrderStatus { Pending, Paid, Shipped, Refunded }`
直接告诉你订单的核心状态机。Step A.5 SubAgent 把这些枚举值合并写成业务实体表。

## 6 · docs.md · README / docs/ / wiki

格式：单 Markdown 文件，每个候选 doc 一行：

```
- `README.md` — # MyAwesomeProject
- `docs/architecture.md` — # System Overview
```

**取值**：每个文件第一非空行（截断到 120 字符 + "..."）。SubAgent 看到这些标题 / 第一
段即可决定要不要去翻全文（Step A SubAgent 会按需 verbatim 引用）。

**包含规则**：根 `README*`、根目录 `*.md`、`docs/` 目录所有 `*.md`、`CHANGELOG*`、
`CONTRIBUTING*`。**不包含** `.github/` 模板。

## 7 · commit-themes.md · 近 ~200 commit message 聚类

格式：单 Markdown 文件：

```markdown
# Commit themes · last ~200 commits
_Total commits scanned: 187_

## Themes (by conventional-commit prefix)
- 62 × feat
- 41 × fix
- 25 × chore
- ...

## Last 20 commit subjects
- `abc1234 feat(auth): add token rotation`
- ...
```

**聚类规则**：

- 拉取最近 200 条 commit 主题（`git log --pretty=%s -n 200`）。
- 按 conventional-commit 前缀（`feat:` / `fix:` / `chore:` / `refactor:` / `docs:` /
  `test:` / `perf:`）聚类。
- 形如 `JIRA-123` 的 ticket 前缀归类为 `ticket`。
- 其它归 `other`。
- 输出 top 20 cluster + 最近 20 条 subject 原文。

**目标项目不是 git 仓库**：文件写入 `(target is not a git repository; commit themes
unavailable)`。

## 8 · 证据 → 业务陈述的引用规则

**铁律**：`NN-business.md` 里每一条业务陈述都必须**就近**带 `[证据: ...]` 引用，
或者**显式**标"业务背景未知 / 不充分"。

合法的引用格式：

- `[证据: src/svc/order.go:42]`（指向单一 file:line）
- `[证据: src/svc/order.go:42-58]`（指向行范围）
- `[证据: business-evidence/schema.md#payments]`（指向 schema.md 里某 section）
- `[证据: business-evidence/commit-themes.md]`（整文件作为弱证据）
- `[证据: README.md:1-5]`（指向 README 的引言段）

**不合法的"陈述"**：

- "看起来这套代码在处理订单。" ← 没有引用 = fail。
- "OrderService 应该是核心业务入口。" ← "应该是"+ 无引用 = fail。
- "通常这种系统会有 fulfillment 步骤。" ← "通常"是行业常识，不是本项目证据 = fail。

**降级表述**（合法）：

- "代码模块 `pkg/order/` 含有 OrderService 类型与 Checkout 方法 [证据:
  pkg/order/order.go:12-50]，结合 commit 主题 `feat(order): ...`
  [证据: business-evidence/commit-themes.md]，可以推测核心入口位于此模块；具体业务
  规则在本节其它段落引用注释 / 测试展开。"

## 9 · NN-business.md 模板骨架

每节业务文件采用统一五段结构，便于 Step B Writing SubAgent 解析与 Reviewer 审阅：

```markdown
# Section NN · Business notes

## 业务任务（What this section's code is responsible for in business terms）
<一两段，每条业务陈述必带 [证据: file:line]>

## 主要业务规则
- 规则 1：<...> [证据: ...]
- 规则 2：<...> [证据: ...]

## 触发条件
- 何时启动 / 何时退出 / 何时分支
- 引自 controller 注释、测试名、enum、commit theme 等

## 例外处理（Error / fallback 路径）
- 引自 test 名（"test_*_when_*_unavailable"）
- 引自代码的 catch / except / recover 块

## 业务背景未知 / 不充分
- 列出本节"无法用 evidence 支撑"的业务问题
- Step B 写作时不能 confident-tone 谈这些点；必须显式标"目前证据不足"
```

**为什么固定五段**：Step B Writing SubAgent 只读 `NN-evidence.md` + `NN-business.md`，
固定结构让它能机械化地把"业务背景"与"技术描述"交织进文章 prose；Section Reviewer
也用固定结构核对引用是否齐全。

**自检（Step A.5 SubAgent 写完 NN-business.md 后内联自查）**：

1. 每个非"未知"段落都至少有一条 `[证据: ...]` 引用。
2. "业务背景未知 / 不充分" 段不能为空——如果真的全部都有证据，就明示
   "本节业务背景充分覆盖，无未知项"。
3. 没有出现 "通常 / 一般来说 / 大家都知道" 这类无来源词。
4. 引用的 file:line 都能在 inventory 里找到（粗略 sanity）。
5. 如果 Section 02b Business Domain Map 是本节但 schema.md 是 `(no DB schema found)`，
   `NN-business.md` 必须显式写 "本项目无业务实体, 跳过"。
