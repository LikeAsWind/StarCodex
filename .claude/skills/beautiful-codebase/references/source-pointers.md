# Source Pointers · 每节脚部 file:line 折叠面板

> **何时读**：Phase 0 抓 git remote 时（决定是否能渲染可点链接）；Phase 4 每节 Step B
> Writing SubAgent 写节脚时；Phase 5 Final Visual Reviewer 抽检链接时。
>
> **配套文件**：`references/component-policy.md` §6（`<SourcePointers>` 组件清单条目）·
> `references/section-build.md` §5 第 5 / 第 6 条（Step B prompt 强制每节有节脚）·
> `theme-profiles/terminal.md` §4.6（terminal 主题下的折叠面板样式）。

每节结尾必须挂一个 `<SourcePointers>` 节脚——它是一张折叠 / 展开的
**file:line 清单**，把本节"读到 / 引用到的所有源码位置"一次性列出。它**不是代码块**
（不计入 Q9b 上限），**是导航锚点**——读者随时可以跳进 repo 查证，也让 Section Reviewer
（与未来的 Coverage Audit）有一份机器可读的"本节引用了哪些 file:line"清单。

## 1 · 数据来源

Source Pointers 不是 Step B 手写的——它是**从证据文件自动汇集的**：

- `sections/<NN>-evidence.md` 里所有 `file:line` 标签 → `role: "evidence"`
- `sections/<NN>-business.md` `[证据: file:line]` 引用里所有 `file:line` → `role: "business"`
- 同一个 `file:line` 同时出现在两处 → `role: "evidence"`（技术证据优先；它是更底层的
  原始事实）

Phase F 会 ship `scripts/audit/source-pointers-gen.sh` 把这套抽取自动化：扫两份 md，
按"`file:line[-line]`" 正则提取，去重，按 file 排序、同 file 按 line 升序，输出一份
JSON（`<project>-analysis/article/sections/<NN>-pointers.json`），Section 组件 import
后传给 `<SourcePointers>`。**Phase E 不实现这个脚本**；当前阶段 Step B SubAgent
手动列 `pointers` 数组即可（详见 `references/section-build.md` §5 写法示例）。

## 2 · `<SourcePointers>` 组件 API

```ts
type PointerRole = "evidence" | "business";

interface Pointer {
  file: string;        // 仓库相对路径，如 "src/svc/order.go"
  line: number;        // 1-based 起始行
  endLine?: number;    // 可选：区间引用如 88-95
  label?: string;      // 可选：人类可读标签（如符号名 / 测试名 / 业务规则名）
  role?: PointerRole;  // 默认 "evidence"
}

interface SourcePointersProps {
  pointers: Pointer[];
  defaultOpen?: boolean;  // 默认由 reader profile 决定（见 §4）
}
```

最小用法（Step B SubAgent 手写时）：

```tsx
import { SourcePointers } from "reacticle";

<SourcePointers
  pointers={[
    { file: "src/svc/order.go", line: 42, endLine: 78, label: "OrderService.Checkout", role: "evidence" },
    { file: "src/svc/order.go", line: 88, endLine: 95, role: "evidence" },
    { file: "migrations/001_orders.sql", line: 1, role: "business" },
    { file: "tests/test_order.py", line: 31, label: "test_checkout_refunds_when_inventory_unavailable", role: "business" },
  ]}
/>
```

未来从 JSON import 用法（Phase F 后）：

```tsx
import pointers from "./07-pointers.json";
<SourcePointers pointers={pointers} />
```

## 3 · 渲染与样式

- **HTML 渲染**：折叠默认（`<details>` 包裹）；展开后是一组等宽的 file:line 链接，按
  `file` 分组、`line` 升序。
- **样式承袭主题**：terminal 主题的 `--ra-terminal-surface-2` 折叠面板底、`--ra-mono-text`
  字体、`--ra-status-blue` 链接色（详见 `theme-profiles/terminal.md` §4.6）。**作者不
  写样式**——组件内部走主题 token。
- **可访问性**：`<details>` 的 `<summary>` 给出"Source Pointers · N 条"摘要文本，
  支持键盘 toggle、aria-expanded 等。
- **role 视觉区分**：`role: "evidence"` 与 `role: "business"` 在折叠面板里分两组渲染
  （Evidence 在上、Business 在下），或同行末尾以 `[E]` / `[B]` 小标签区分——具体由
  组件库实现，作者不管。

## 4 · 默认折叠状态（按 reader profile）

| Reader profile | `defaultOpen` |
|---|---|
| `architecture-review` | `false`（默认折叠 —— 评审人按需展开） |
| `onboarding` | `false`（新人不需要被锚点海洋淹没；但能展开就有学习价值） |
| `archaeology` | `true`（归档 = 把每个 file:line 显式留下）|

PDF 打印时**一律展开**（无论 profile），由 `scripts/pdf-print-overrides.css` 强制
`<details> { display: block !important; } details > summary { display: block; } details > *:not(summary) { display: block !important; }`
（Phase G 实现）。打印是档案，不能藏。

## 5 · URL 解析（git remote 自动可点链接）

Phase 0 在 Intake 末尾尝试 `git remote get-url origin`，如果成功且能识别 provider，把
结果记进 `analysis-snapshot.json`：

```json
{
  "remote": {
    "provider": "github",          // 或 "gitlab" / "bitbucket"
    "baseUrl": "https://github.com/owner/repo",
    "branch": "main"               // 或抓到的 default branch / 当前 SHA
  }
}
```

`<SourcePointers>` 在渲染时**读这份 snapshot**（构建时被注入；详见
`references/html-output.md` 的"snapshot 注入"段），对每个 `Pointer`：

| provider | 链接模板 |
|---|---|
| `github` | `<baseUrl>/blob/<branch>/<file>#L<line>`（区间用 `#L<start>-L<end>`） |
| `gitlab` | `<baseUrl>/-/blob/<branch>/<file>#L<line>` |
| `bitbucket` | `<baseUrl>/src/<branch>/<file>#lines-<line>` |
| **不识别 / 无 remote** | 渲染为纯文本（不可点） |

**绝不**为了让链接"看起来能用"硬拼一个 baseUrl——抓不到就是纯文本，让读者复制 file:line
自己定位。

如果 Phase 0 抓到的是当前 SHA（而非 branch 名），baseUrl 模板里的 `<branch>` 直接替换
为 SHA——这样链接是"不变快照"，几年后仍准确指向当时的代码。这是 archaeology profile
的核心价值之一。

## 6 · Section Reviewer 的检查项

每节 Step B 完成后，Section Reviewer 对 `<SourcePointers>` 节脚做 4 项检查
（详见 `references/section-build.md` §8）：

1. **存在**：节里有 `<SourcePointers>` 组件？无 = fail。
2. **非空**：`pointers` 数组长度 > 0？空 = fail（除非这是一个"纯导言"节，主 Agent
   要在 plan.md 标注 `pure-intro: true` 才允许；详见 §7）。
3. **可追溯**：随机抽 3 条 `pointers`，每条 `file:line` 都能在本节
   `<NN>-evidence.md` 或 `<NN>-business.md` 里找到？找不到 = fail。
4. **role 一致**：每条 `role` 与它真实来源一致？（出现在 evidence.md 的 `role`
   是 `"evidence"`、出现在 business.md 的 `role` 是 `"business"`）

发现 fail → 主 Agent 直接修 `pointers` 数组，不重派 SubAgent。

## 7 · 与 Coverage Annex 的关系

| 角色 | 节脚 SourcePointers | Section 11 Coverage Annex |
|---|---|---|
| 作用域 | **本节** | **全报告** |
| 数据来源 | 本节 evidence.md / business.md | 全部 `inventory.json` 文件路径 |
| 视觉 | 折叠面板（短） | 大表格（可分页） |
| 触发 | 每节必有 | 仅 architecture-review / archaeology profile |
| 责任 | Step B 写 / Phase F 脚本生成 | Phase 5 Coverage Audit 检查 |

两者**互补不重复**：SourcePointers 是"我这节读了哪些 file:line"的局部导航；Coverage Annex
是"全 repo 有哪些文件、各自被哪节认领或为什么未覆盖"的全局清单。Reader 翻到任意节都
能从节脚跳进 repo；翻到末尾的 Coverage Annex 能看完整账。

**例外**：一个"纯导言 / 纯过场"的节（如 01 Verdict 的极简首屏、12 Colophon 的署名）
没有引用 file:line 是合理的。这类节在 plan.md Outline 段标 `pure-intro: true`，Section
Reviewer 跳过空 SourcePointers 检查。**不要**为了凑 pointers 而把无关 file:line 塞进
去——那是注水。

## 8 · 一键速查

| 我要做 | 做法 |
|---|---|
| 写节脚 | Step B SubAgent 手写 `pointers` 数组（Phase E 阶段）；Phase F 后改 import JSON |
| 找渲染规则 | 本文件 §3 + `theme-profiles/terminal.md` §4.6 |
| 改默认折叠 | 通过 `defaultOpen` 显式覆盖，否则按 §4 profile 默认 |
| 想配 GitHub 可点链接 | Phase 0 抓 `git remote`，结果落 `analysis-snapshot.json`，组件自动渲染 |
| 通不过 Reviewer | 对照 §6 四项一项一项修；空 → 加引用或在 plan.md 标 `pure-intro: true` |
| 想知道脚本 | Phase F `scripts/audit/source-pointers-gen.sh`（**不**在 Phase E 范围内） |
