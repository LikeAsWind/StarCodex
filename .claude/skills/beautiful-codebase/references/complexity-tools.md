# Complexity Tools · 各语言圈复杂度工具检测

> **何时读**：Phase 1 准备 Section 07 数据时（若 Plan 决定包含 Section 07）；Phase 4
> Section 07 Evidence SubAgent 选工具时；Phase 5 Technical Reviewer 验证 caveat 是否
> 已声明时。

Section 07 Code Health Heatmap 用真实圈复杂度（CC）数据画 SVG 热图。本文档枚举各
语言的工具选择 / 检测顺序 / 退化规则；目标是**有工具就用真值、没工具就用启发式 +
caveat**——绝不假装有数据。

## 1 · 各语言工具优先级

| 语言 | 首选 | 次选 | 检测命令 | 备注 |
|---|---|---|---|---|
| Python | `radon` | `lizard` | `radon --version` / `pip show radon` | radon 输出 CC 最细粒度 |
| Go | `gocyclo` | `lizard` | `gocyclo -version` / `which gocyclo` | gocyclo 来自 fzipp/gocyclo |
| JavaScript / TypeScript | `eslint --rule complexity` | `lizard` | `eslint --version` + 项目里有 `.eslintrc*` | 需要项目本地安装 ESLint |
| Java | `pmd` (`pmd check -R category/java/design.xml/CyclomaticComplexity`) | `checkstyle` / `lizard` | `pmd --version` | 需要 JDK |
| C / C++ | `lizard` | — | `lizard --version` | lizard 支持 C/C++/CUDA |
| C# | `lizard` | `Roslyn analyzers` | `lizard --version` | 真原生工具是 ndepend（商用），lizard 够用 |
| Rust | `clippy` (`cognitive_complexity`) | `lizard`(部分支持) | `cargo clippy -- -W clippy::cognitive_complexity` | clippy 是 cognitive 而非 cyclomatic，注明 |
| Kotlin | `detekt` | `lizard` | `detekt --version` | 需要 JDK |
| Scala | `scalastyle` | `lizard` | — | 弱支持 |
| Ruby | `flog` | `lizard` | `flog --version` | flog 输出 ABC，注明换算逻辑 |
| 其它 | `lizard` (通用 fallback) | — | `lizard --version` | 最后兜底 |

**检测顺序**：每种语言**优先 1 → 优先 2 → lizard**。Section 07 Evidence SubAgent 跑
`scripts/audit/complexity-detect.sh`（Phase F 实现）按上表顺序探测可用工具，写到
`discovery/complexity-tools.json`，本 Section 写作时按此文件选工具。

## 2 · Lizard 通用 fallback

[Lizard](https://github.com/terryyin/lizard) 是 Python 写的多语言 CC 工具，支持 ~12
种语言（Python / Go / Java / JS / TS / C / C++ / C# / Scala / Lua / Swift / TTCN-3）。
**优势**：单工具覆盖大半 BAU 场景；**劣势**：精度略低于原生工具（例如 Go 的 gocyclo
对 Goroutine 的处理）。

安装：

```bash
pip install lizard
# 或 pipx：
pipx install lizard
```

使用：

```bash
lizard <project-path>                  # 默认 CCN > 15 警告
lizard -C 10 -L 80 <project-path>      # CC > 10 警告，函数 > 80 行警告
lizard <project> --csv > cc.csv        # CSV 输出
lizard <project> --xml > cc.xml        # XML 输出（适合脚本）
```

**何时优先选 lizard**：

- 多语言混合项目（Python + Go + TS 一起）—— 单工具更省事。
- 不愿在用户机器装多个工具的语言（C# / Scala / Lua）。
- 用户机器上没有任何原生工具但有 Python。

**何时绕开 lizard**：

- 用户已经在用 ESLint / clippy / pmd 等原生工具且配了项目规则 —— 复用现有配置更
  贴近团队习惯。
- Rust 项目想用 cognitive_complexity（lizard 当前对 Rust 支持有限）。

## 3 · 探测脚本协议（v0.2 backlog）

v0.1.0 的 Phase 1 **暂不主动跑复杂度扫描**——这是 v0.2 backlog（Phase F 的
`scripts/audit/complexity-detect.sh` 会负责）。Phase 4 Section 07 Evidence SubAgent
在 v0.1.0 期间会临时承担这部分：

1. SubAgent 启动时探测：对项目中每种语言（从 `inventory.json.stats.byLanguage` 读）
   按 §1 顺序探测可用工具。
2. 把探测结果写到 `discovery/complexity-tools.json`：

```json
{
  "byLanguage": {
    "python": {"tool": "radon", "version": "6.0.1", "available": true},
    "go":     {"tool": "lizard", "version": "1.17.10", "available": true,
               "note": "gocyclo not on PATH, fell back to lizard"},
    "rust":   {"tool": null, "available": false, "note": "no tool found"}
  },
  "fallbackHeuristic": false
}
```

3. 对每种 `available: true` 的语言跑工具，归一化为 `complexity.jsonl` 行：

```json
{"file": "src/svc/order.go", "function": "Checkout", "cc": 18, "loc": 84, "language": "go", "tool": "lizard"}
```

4. Section 07 SVG 热图读 `complexity.jsonl` 渲染。

## 4 · 没有可用工具时的退化

仅当**所有语言都无可用工具**时，退化为 LOC + 嵌套深度启发式：

| 启发式分数 | 计算 | 与 CC 的近似关系 |
|---|---|---|
| `loc` | 函数体非空行数 | 大致正相关 |
| `nesting` | 最大缩进层数（按语言 tab/space 折算） | 大致正相关 |
| `score` | `0.5 * loc + 5 * nesting` | 启发式，不严谨 |

**显著性下降**——不能当成真 CC 数据用。**必须**在 Section 07 顶部加 caveat：

```
⚠ 本节复杂度数据基于启发式（LOC + 嵌套深度），未使用 radon / gocyclo / lizard 等
真圈复杂度工具。原因：用户机器上未检测到任何可用工具。建议读者把绝对分数视为
"相对热点指示"，不要直接对照 CC ≥ 10 这类经典阈值。
```

Visual Reviewer 在 Phase 5 终审时会专门检查这条 caveat 是否存在。

## 5 · 输出归一化

无论用哪个工具，最终都归一化为 `discovery/complexity.jsonl`，每行：

```json
{"file": "src/svc/order.go",
 "function": "OrderService.Checkout",
 "cc": 18,
 "loc": 84,
 "language": "go",
 "tool": "lizard"}
```

字段：

- `file` — inventory 中的相对路径。**必须**与 inventory.path 一致，否则 Coverage
  Audit 会漏算这一行。
- `function` — 函数 / 方法的限定名（best-effort：包含类名 / 模块名前缀）。
- `cc` — 圈复杂度（无工具时是启发式 `score`）。
- `loc` — 函数体行数（best-effort）。
- `language` — 与 inventory.language 一致。
- `tool` — 实际使用的工具名（`radon` / `gocyclo` / `lizard` / `eslint` / `pmd` /
  `heuristic`）。`heuristic` 是退化路径。

Section 07 SVG 热图渲染时按 `cc` 从高到低排，取 top 30 / 50（Plan 阶段决定）；当一
项目混合了多种 tool 时，色阶按 tool 分组而非全局拉伸（避免 lizard CC 与 radon CC 直接
比较——它们的数值不完全可比）。

Coverage Audit 在 Phase 5 验证：**没有任何 complexity.jsonl 行**指向 inventory 之外
的文件；inventory 中 `analyzed` 但没有 cc 数据的文件视为"工具没覆盖"（正常，不算 fail），
但 Section 07 Evidence SubAgent 应该在 evidence.md 里列出"未覆盖文件占总数百分比"，
保证 reader 知道热图的样本完整度。
