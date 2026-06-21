# Bucket Strategy · 按尺寸 tier 切分 inventory

> **何时读**：Phase 1 `buckets.sh` 跑的时候；Phase 2 Plan 决定 Section 数量、
> Section ↔ bucket 映射时；Phase 4 每节 Step A SubAgent 开工前看一眼自己的桶。

把 inventory.json 切成 ~5k LOC / bucket 的稳定单位，让每个 SubAgent 工作量可控、产出
可独立持久化、失败可单点重跑。**Bucket 与 Section 是 1:1 映射的入口**——Phase 2 Plan
的 Outline 阶段可以重排 / 合并 / 拆分桶，但每一节最终必须能引用到至少一个桶（或者
明确入 Coverage Annex）。

## 1 · 尺寸 tier 速查（PRD Q5b 表格）

| Files       | Bucket strategy                          | Evidence granularity                                | Sections |
|-------------|-----------------------------------------|-----------------------------------------------------|----------|
| `<100`      | one bucket                              | per-file verbatim                                   | 3–5      |
| `100–1k`    | by top-level directory (~5k LOC/bucket) | per-file verbatim within bucket                     | 5–10     |
| `1k–10k`    | by codegraph module                     | entry-files verbatim + callers/callees for the rest | 10–20    |
| `>10k`      | two-tier: top module → submodule        | submodules: symbol summaries only                   | ~20 + optional appendix exports |

`buckets.sh` 的 `size-tier.json` 把 size tier、bucket strategy、evidence strategy 写
成一份单文件——后续 Phase 2 Plan / Phase 4 Step A SubAgent prompt 都从这里读取，
**不要在多个地方各自重新决定**。

## 2 · `<100` 文件项目（single bucket）

策略：**所有 analyzed 文件入一个桶**（`bucket-01-root.json`，scope = `(root)`）。

- Evidence strategy: **per-file-verbatim**——Step A SubAgent 把每个文件都用 verbatim
  代码片段引用（最多以函数 / 类为单位切）。
- Sections: **3–5**——典型组合：Verdict / Architecture Map（可能空）/ Module Walk /
  Risks / Coverage Annex。Plan 可决定省略哪些。
- 适用：小工具、单服务、PoC、内部脚本。

## 3 · `100–1k` 文件项目（directory roll-up）

策略：**按顶层目录切桶**，每桶目标 ~5k LOC。

- 桶 scope 例如 `cmd/`, `pkg/auth/`, `internal/store/`。如果某目录单独超过 7.5k LOC
  （1.5×），脚本会按文件顺序切成 `<scope>#part1` / `#part2`。
- Evidence strategy: **per-file-verbatim**——桶里每个文件都 verbatim 引用。
- Sections: **5–10**——典型组合：Verdict / Project at a Glance / Architecture Map /
  Module Walk（多节）/ Entry Points / Risks / Coverage Annex / Colophon。
- 适用：中小项目、微服务、Library。

## 4 · `1k–10k` 文件项目（codegraph module）

策略：**按 codegraph 语义模块切**。

- 如果 tier = `codegraph-indexed`，调用 `codegraph explore` 获取模块边界；每模块一桶。
- 如果 tier ≠ `codegraph-indexed`（用户在 Phase 0 选了 downgrade / stop 等），脚本
  **自动降级**为 `directory-rollup`，并在 bucket 的 `rationale` 注明
  `"codegraph module info unavailable"`。
- Evidence strategy: **entry-files-verbatim**——只对入口文件（controllers / handlers /
  main / consumers）做 verbatim；其它文件只取 callers/callees 摘要 + 关键 API 签名。
- Sections: **10–20**——Architecture / Module Walk / Entry Points 各占多节，Risks /
  Decisions / Code Health 都可能出现。
- 适用：典型企业级中台、SaaS 子系统。

## 5 · `>10k` 文件项目（双层 bucket）

策略：**两层切分**——顶层模块 → 子模块。

- 第一层：顶层目录 / 顶层模块；第二层：子目录 / 子模块。脚本默认 depth = 2（即
  最多 2 段路径作为 scope）。
- 当 tier = `codegraph-indexed` 时，理想模式是顶层用 codegraph 模块边界、子层用子模块
  边界。当前实现暂以 `two-tier-directory` 兜底，并在 `_summary.json.bucketStrategy`
  注明。
- Evidence strategy: **symbol-summary**——子模块只用符号 outline + 关键签名 + 关键
  注释；**不**全文 verbatim。verbatim 只保留给"入口 + 真正关键节"。
- Sections: **~20 + optional appendix exports**——典型架构评审 / 归档场景。
- **强制规则**：reader profile 降级推荐到 `archaeology · 70%`；Coverage Annex 强制开；
  禁止声称 "100% coverage"。`codebase-brief.md` 会在头部显式打这条规则。

## 6 · 排除规则（`excluded_reason`）

`inventory.sh` 在生成 inventory 时已经为每个文件标了 `excluded_reason`：

| Reason | 含义 | 触发示例 |
|---|---|---|
| `vendored` | 第三方依赖代码（按规约不分析） | `vendor/`, `node_modules/`, `third_party/` |
| `generated` | 自动生成的工件 | `dist/`, `*.min.js`, lockfiles, `_pb.go`, `@generated` 头 |
| `fixtures` | 测试夹具 / 快照 | `fixtures/`, `testdata/`, `__snapshots__/` |

`buckets.sh` **不把排除文件放进桶**——它们只在 inventory 里有记录，Phase 5 Coverage
Audit 会扫一次确保每个 inventory 文件要么在某桶、要么有 `excluded_reason`。这两条
互斥地覆盖了 100% inventory。

**手动加排除**：v0.1.0 暂不提供自定义排除文件机制；如果有需要（例如 monorepo 想排除
某子包），可以在 Phase 0 用户自由文本提出，主 Agent 在 inventory 后手动给某些文件加
`excluded_reason` 字段。这是一个已知 v0.2 backlog 项。

## 7 · Bucket → Section 映射输出

Bucket 文件 schema（每个 `bucket-NN-<slug>.json`）：

```json
{
  "id": "bucket-04-auth",
  "scope": "pkg/auth",
  "rationale": "directory roll-up (top-level dir)",
  "files": ["pkg/auth/middleware.go", "pkg/auth/jwt.go", ...],
  "loc": 4900,
  "language": ["go"],
  "isEntryHeavy": true,
  "evidenceStrategy": "per-file-verbatim"
}
```

`_summary.json`：

```json
{
  "sizeTier": "100-1k",
  "tier": "rg",
  "analyzedFiles": 320,
  "totalLoc": 24800,
  "bucketCount": 6,
  "bucketStrategy": "directory-rollup",
  "evidenceStrategy": "per-file-verbatim",
  "buckets": ["bucket-01-cmd", "bucket-02-pkg-auth", ...]
}
```

**Phase 2 Plan 的用法**：

1. 主 Agent 读 `_summary.json` 与每个 bucket 的 `scope`/`loc`/`isEntryHeavy` 字段，
   不必读 `files` 全表。
2. 在 plan.md Outline 里，每个 Section 注明它"引用 bucket = bucket-NN-<slug>"。一节
   可以引多桶（合并），多节也可以引一桶（拆分）——但每个 analyzed 文件最终都得归到
   某节或 Annex。
3. **`isEntryHeavy: true`** 的桶强提示主 Agent："这个桶应至少出现在 Section 04 Module
   Walk 或 Section 05 Entry Points 之一"。
4. Plan 自检铁律 1（100% inventory 覆盖）由 Phase 5 Coverage Audit 机器验证；Plan 阶段
   主 Agent 内联自查即可。

**Phase 4 每节 Step A SubAgent 的用法**：每个 SubAgent 拿到自己负责的 bucket id +
`buckets/bucket-NN-<slug>.json`（可能多个），按 evidenceStrategy 决定证据粒度，
verbatim 引用代码进 `sections/NN-evidence.md`。
