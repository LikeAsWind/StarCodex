# Review Checklist · 各阶段审查清单

> **何时读**：Phase 2 Plan 写完后内联自查；Phase 3 First Spread 完成时；Phase 4 每个
> Section 完工时；Phase 5 三视角终审时；以及编写任意 Reviewer SubAgent prompt 时。
>
> **配套**：`scripts/audit/{coverage,freshness,density,claim-trace,source-pointers-gen,complexity-detect}.sh`
> （Phase F 实现）· `references/repair-policy.md`（修复政策）·
> `prompts/section-reviewer.md`（Section Reviewer SubAgent prompt 模板）。

本文件是 4 类 Reviewer + 4 类机械审计的**事实清单**。Reviewer prompt 提的"按 checklist
逐项核查"，指的就是这份文件。

---

## 0 · 全局质检方式总表（铁律）

| 阶段 / 节点 | 谁做 | 形态 | 产物 | 备注 |
|---|---|---|---|---|
| Plan 自查（Phase 2 → Checkpoint 1） | **主 Agent 内联** | inline 5 条 checklist | **无文件** | 禁止开 SubAgent；上下文是热的，冷启更慢 |
| First Spread（Phase 3 → Checkpoint 2） | First Spread Reviewer SubAgent | 独立 SubAgent | `review/first-spread-review.md` | 封面 + 第一节定调，多一道眼睛 |
| Section 完工（Phase 4 每节） | Section Reviewer SubAgent | 独立 SubAgent | **消息返回 pass/fail + 修复点（不写文件）** | 一份报告 7–15 节，N 份 review.md 没人看 |
| Final 三视角（Phase 5 → Checkpoint 3） | Editorial / Visual / Technical 三 SubAgent（可并行） | 独立 SubAgent ×3 | `review/final-review.md`（三段追加） | 交付物组件，留档有价值 |
| Coverage Audit（Phase 5） | **脚本** `scripts/audit/coverage.sh` | bash 脚本 | `review/coverage.json` + footer 注入 | 机械检查，跑脚本而非问 Agent |
| Freshness Audit（Phase 5） | **脚本** `scripts/audit/freshness.sh` | bash 脚本 | `review/freshness.json` + `review/freshness-summary.md` + footer 注入 | 同上 |
| Density Audit（Phase 4 每节 + Phase 5 抽样） | **脚本** `scripts/audit/density.sh` | bash 脚本 | `review/density.json` | Q9b 上限机械核查 |
| Claim Trace Audit（Phase 4 每节抽 5 条 + Phase 5 抽样） | **脚本** `scripts/audit/claim-trace.sh` | bash 脚本 | `review/claim-trace-NN.json` | 验证 prose 引用都在 evidence 里 |

**铁律：拿到任何质检结论 —— 先按 fail 项把产出改完，再向用户汇报"做完了 + 自检结论 +
改了什么"**。直接报结论但不修复 = 违规。

**为什么 Section Reviewer 不写文件**：一份报告可能有 7–15 节；留 7–15 个
`review/section-NN-review.md` 文件**没人会读**（连主 Agent 自己都不会回看）。Section
Reviewer 的契约是"消息往返 + 一次性修复"。留档的只有 `review/first-spread-review.md`
（Phase 3）和 `review/final-review.md`（Phase 5）——它们的内容真的会被回看。

---

## 1 · Plan 自查（Phase 2 → Checkpoint 1 · 主 Agent 内联 · 5 条）

**何时**：写完 `plan/plan.md` 后立刻；**谁做**：主 Agent 内联；**产物**：无文件，按结论
直接改 `plan/plan.md`；**禁止**：开 SubAgent、写 `review/plan-review.md`。

**输入**：

- `plan/plan.md`（自己刚写的）
- `discovery/inventory.json`（验证模块名都在 inventory 里）
- `discovery/codebase-brief.md`（背景）

**检查项**：

1. **Brief / Outline 自洽**：每节"必须保留"加总能落到选定 reader profile 的标配信息保留
   比例附近；Outline 没有偷偷塞 Brief 没承诺的内容，也没有遗漏 Brief 必须保留的项。
2. **100% inventory 覆盖（铁律 1）**：每个 inventory 中的模块目录都被某个 Section 认领，
   或显式写入 `Coverage Annex`；**没有被遗忘的目录**。允许 Annex 大占比，但不允许"空白"。
3. **业务-Job 引用合规（铁律 2）**：每节的"业务-Job"行要么引用至少 1 条 evidence
   （`discovery/business-evidence/` 中的具体文件 / 测试名 / commit / DDL），要么显式标
   "业务背景未知, 本节只做技术解释"。**Confident-tone 无引用 = fail**。
4. **模块名都在 inventory（铁律 3）**：Outline 提到的每个模块名 / 文件路径都能在
   `inventory.json` 找到。**编造的模块名 = fail**。
5. **章节序号合理**：Section 编号连续单调（01 / 02 / 02b / 03 …），子节序号前缀对齐
   父章节（第 08 章下只能是 8.1 / 8.2，不能出现 5.1）。

**Pass 条件**：5 条全过。任一 fail → 改 `plan/plan.md`，再核查一次，直到 5 条全过。

**修复处理**：直接改 `plan/plan.md`，**不要**写新文件、**不要**派 SubAgent。

---

## 2 · First Spread Reviewer（Phase 3 → Checkpoint 2 · SubAgent · 写文件）

**何时**：封面 + 首屏（Hero / Lead / TOC） + 第一节完成后；**谁做**：First Spread
Reviewer SubAgent；**产物**：`review/first-spread-review.md`。

**输入**：

- `article/Cover.tsx`（若封面开）
- `article/Article.tsx`（assembler 当前状态）
- `article/sections/01-*.tsx`（第一节 .tsx）
- `article/sections/01-evidence.md`
- `article/sections/01-business.md`
- `plan/plan.md`
- 选定主题 `theme-profiles/<id>.md`
- `references/cover.md`（封面 5 条自检）

**检查项 · 封面段（若开 · 5 条 · 与 `references/cover.md` §自检一致）**：

1. **图文并茂**：截掉文字层后还剩视觉主体？截掉视觉层后还剩文字？两者都要有。
2. **主题忠实**：切到 `theme-profiles/index.json` 里另一个主题（改 `main.tsx` 一行），
   封面**自动跟随**变色 / 变字、不破相？写死值 = fail。
3. **内容忠实**：盯着封面看 5 秒钟能不能猜出"这是关于什么项目 / 什么 reader profile
   的报告"？只是"一个漂亮图形"但跟正文关系不大 = fail。
4. **比例自适应**：把容器从 3:4（屏幕）拉成 ~3:4.2（A4）/ ~3:3.9（Letter），内部元素
   没溢出 / 没错位？写死 absolute px 位置 = fail。
5. **不与 Hero 重复**：封面文字 ≠ Hero 文字（封面是钩子，Hero 是锚点）。

**检查项 · 首屏段（5 条）**：

1. **像报告，不像 landing page**：读者能立刻知道"这份报告要给谁解决什么问题"？
2. **TOC 完整**：左侧 TOC 列出全部计划 Section（与 plan.md 一致）；编号自洽。
3. **Hero meta 齐全**：项目名 / reader profile / 主题 / 时间戳 / 工具 tier 至少 3 项
   出现在 meta 里。
4. **第一节有阅读节奏**：prose 不是流水账；Mermaid / Table / 徽章按需出现而非堆砌。
5. **第一节走完整三阶段**：`01-evidence.md` 与 `01-business.md` 都存在并非空；Section
   Reviewer 在第一节上跑过且 pass。

**检查项 · 技术段（3 条）**：

1. `npm run dev` 启动无报错，浏览器控制台无红字。
2. Mermaid 块（若有）能渲染（不是源码裸露在页面）。
3. `<SourcePointers>` 节脚渲染了 ≥ 1 条 pointer（或 plan 标 `pure-intro: true` 豁免）。

**输出格式**（写进 `review/first-spread-review.md`）：

```markdown
# First Spread Review · <YYYY-MM-DD HH:MM>

## 封面
- [1] 图文并茂 · **pass** / **fail** —— <一句话证据，指 file:line>
- [2] 主题忠实 · pass / fail —— …
- [3] 内容忠实 · pass / fail —— …
- [4] 比例自适应 · pass / fail —— …
- [5] 不与 Hero 重复 · pass / fail —— …

## 首屏
- [1] 像报告 · pass / fail —— …
- [2] TOC 完整 · pass / fail —— …
- [3] Hero meta 齐全 · pass / fail —— …
- [4] 第一节阅读节奏 · pass / fail —— …
- [5] 三阶段完整 · pass / fail —— …

## 技术
- [1] npm run dev · pass / fail —— …
- [2] Mermaid 渲染 · pass / fail —— …
- [3] SourcePointers · pass / fail —— …

## 必须修复
- <修复点 1：具体改哪里改成什么>
- <修复点 2：…>

## 改写建议（可选）
- …
```

**修复处理**：主 Agent 收到结论后**先按"必须修复"项改完**，再进 Checkpoint 2。

---

## 3 · Section Reviewer（Phase 4 每节 · SubAgent · 消息返回 · 不写文件）

**何时**：每个 Section 的 Step B 写完后；**谁做**：Section Reviewer SubAgent；**产物**：
**消息回主 Agent，不写文件**。

> 完整 prompt 模板见 `prompts/section-reviewer.md`。本节是 prompt 背后的清单——任何修改
> prompt 的人必须先读这里确保覆盖。

**输入**：

- `article/sections/<NN>-<slug>.tsx`（Step B 交付）
- `article/sections/<NN>-evidence.md`（Step A 证据）
- `article/sections/<NN>-business.md`（Step A.5 业务）
- `plan/plan.md` 中本节那行 Outline
- 主 Agent 派活时给的 `<NN>`

**检查项（7 条 · 按顺序跑）**：

1. **Claim Audit · 抽 5 条技术陈述**：从 .tsx prose（`<P>` / `<Quote>` / `<Callout>`）
   里随机抽 5 条技术断言（"X 调用 Y" / "X 的实现是 Z" / "X 的入口在 Y" 等），每条找
   它在 `<NN>-evidence.md` 的对应引用。**找不到 = fail**，列出哪条 claim 没引用。
2. **Verbatim re-grep · 抽 evidence 3 个代码块**：每个用 `bc_query_text` 在 repo 里再
   grep 一次第一行，确认 verbatim 一致。**不一致 = fail**（说明 Step A 后文件被改了，
   或 Step A 抄错了），列出哪段对不上。
3. **业务引用核查 · 抽 3 条业务陈述**：从 .tsx prose 里抽 3 条业务陈述，每条找它在
   `<NN>-business.md` 的 `[证据: ...]` 引用。**找不到引用或 business.md 该条本身在
   §4 未知段 = fail**。
4. **代码密度审计（Q9b）**：
   - 数 `<CodeBlock>` 数量。Section 04 / 05 上限 2，其它上限 1。超 = fail。
   - 数每个 `<CodeBlock>` 的行数。> 8 = fail。
   - 估算 prose 段落数和 code-char 占比；显著超 Q9b 阈值（block/paragraph > 0.15，
     code-char share > 15%）= fail。
   - 这一条也可借 `scripts/audit/density.sh --section <NN>` 在 Reviewer 内跑一次。
5. **Source Pointers 完整性**：`<SourcePointers>` 节脚存在？`pointers` 数组长度 > 0？
   抽 3 条 pointer，每条 `file:line` 都能在本节 evidence.md / business.md 找到？
   role 与真实来源一致？**否 = fail**（除非 plan.md 标 `pure-intro: true`）。
6. **序号自洽**：`<Section index="<NN>">` 与主 Agent 派活的 `<NN>` 一致？所有
   `<Subsection index>` 前缀都是 `<NN>.X`（而非别的章节）？**否 = fail**。
7. **与前后节衔接（best-effort · 软标准）**：本节有没有重复隔壁节已说过的论点？有无明
   显悬空（说"见上文 X"但 X 不存在）？只在显著时 fail；一般记为"建议优化"而非"必须
   修复"。

**输出格式（消息回主 Agent）**：

如果全部 pass：

```
SECTION_REVIEW <NN>: PASS.
```

如果有 fail：

```
SECTION_REVIEW <NN>: FAIL.
Failed checks:
- <编号>. <审计项名>: <失败具体描述 + 影响位置 file:line 或行号>
- <编号>. ...
Recommended fixes:
- <修复点 1：具体改哪里改成什么>
- <修复点 2：...>
```

**修复处理**：

| Fail 项 | 修复手段 | 是否重派 SubAgent |
|---|---|---|
| 1 Claim Audit | 主 Agent 直接修 .tsx prose（加引用或重写） | 否 |
| 2 Verbatim re-grep | 主 Agent 重跑 Step A（evidence 已失真） | **是**：重派 Evidence SubAgent |
| 3 业务引用 | 主 Agent 直接修 .tsx prose 或重跑 Step A.5 | 视情况：业务陈述本来就有 → 改 prose；evidence 缺失 → 重跑 A.5 |
| 4 密度审计 | 主 Agent 直接改 .tsx：删 CodeBlock / 缩短 / 改 inline | 否 |
| 5 SourcePointers | 主 Agent 直接修 `pointers` 数组 | 否 |
| 6 序号 | 主 Agent 直接改 `index` 字符串 | 否 |
| 7 衔接 | 主 Agent 调整 prose | 否 |

修完后**再走一次 Reviewer**，直到 PASS。绝不"已知有 fail 但放过"。

---

## 4 · Final · Editorial Reviewer（Phase 5 · SubAgent · 追加 `final-review.md`）

**何时**：所有 Section 都已 Section-Reviewer-pass 后；**谁做**：Editorial Reviewer
SubAgent；**产物**：`review/final-review.md` 的"## Editorial"段追加。

**输入**：

- `plan/plan.md`
- `article/Article.tsx`
- 所有 `article/sections/*.tsx`
- 所有 `article/sections/*-evidence.md` + `*-business.md`
- 选定 reader profile `references/profiles/<id>.md`
- `discovery/codebase-brief.md`

**检查项（7 条）**：

1. **它仍然是一份报告**，不是网页应用、不是 dashboard、不是 pitch deck。读起来像一份
   被编辑过的工程文档。
2. **reader profile 标配被尊重**：信息保留比例 ±10% 内合规；必选 Section 全到齐；可选
   Section 与 plan 决定一致。
3. **必须保留的信息没丢**：plan.md Brief 的"必须保留"清单逐条对照——都还在？
4. **业务-Job 覆盖**：每节都有一条明确的"业务-Job"叙述，或显式标"业务背景未知"。没有
   一节"光讲技术不讲它做什么业务"——除非该节本来就是 Verdict / Architecture Map 这种
   元层级节。
5. **结构连贯**：章节顺序符合 reader profile 推荐节奏（如 architecture-review 先
   Verdict 后 Risks）；前后呼应有节奏，没有跳脱。
6. **语言符合 Brief**：默认中文 prose + 英文标识符；术语 / 引用 / 图注全部一致；没有
   残留的英文段落（除非 Brief 选了 "全英" / "双语"）。
7. **没有空泛标题、堆卡片、过度总结**：避免营销腔（"我们使命是..."）、避免一节里堆
   3 个 Aside / Quote 当装饰。

**输出格式**（写进 `review/final-review.md`）：

```markdown
## Editorial · <YYYY-MM-DD HH:MM>

- [1] 报告性 · pass / fail —— …
- [2] reader profile 标配 · pass / fail —— …
- [3] 必须保留 · pass / fail —— …
- [4] 业务-Job 覆盖 · pass / fail —— …
- [5] 结构连贯 · pass / fail —— …
- [6] 语言一致 · pass / fail —— …
- [7] 无空泛 · pass / fail —— …

### 必须修复
- ...

### 改写建议（可选）
- ...
```

---

## 5 · Final · Visual Reviewer（Phase 5 · SubAgent · 追加 `final-review.md`）

**输入**：所有 .tsx + raw-blocks/ + 选定主题 `theme-profiles/<id>.md` + `references/cover.md`。

**检查项（7 条）**：

1. **主题气质统一**：颜色 / 字体 / 间距全走主题 token；徽章只用 terminal 主题的 5 种状
   态色（`--ra-risk-red` / `--ra-warn-amber` / `--ra-status-green` / `--ra-status-blue`
   / 中性）；切主题不破。
2. **Mermaid 主题忠实**：Mermaid 节点颜色 / 边色取自主题 token；不出现野生 hex 颜色；
   暗底主题下 Mermaid 默认 init 走 `theme: 'dark'`。
3. **Mermaid 渲染清晰**：Section 02b / 03 / 05 的图节点数适中（一图 ≤ ~20 节点，超出
   就拆图）；中文标签不被裁切；箭头方向自洽。
4. **Raw 块无野生样式**：每个 `<Raw>` / raw-blocks 文件只用 `--ra-*` token；不写死颜
   色、不引远程图、不引远程字体。
5. **Cover 维持自检 5 条**：与 §2 封面段一致；终审时复核一次。
6. **没有明显 AI 味**：装饰性紫粉渐变、圆角彩卡、假插画、emoji 装饰、无意义图标墙——
   都禁止。
7. **桌面 + 移动端都可读**：检查 `width=narrow/regular/wide/full` 在 360px / 1024px /
   1440px 三个断点下无文字溢出 / 无遮挡 / 无大块空白。

**输出格式**：

```markdown
## Visual · <YYYY-MM-DD HH:MM>
- [1] 主题统一 · pass / fail —— …
- [2] Mermaid 主题忠实 · pass / fail —— …
- [3] Mermaid 渲染清晰 · pass / fail —— …
- [4] Raw 无野生样式 · pass / fail —— …
- [5] Cover · pass / fail —— …
- [6] 无 AI 味 · pass / fail —— …
- [7] 移动端 · pass / fail —— …

### 必须修复
- ...
```

---

## 6 · Final · Technical Reviewer（Phase 5 · SubAgent · 追加 `final-review.md`）

**输入**：所有 .tsx + `package.json` + `vite.config.ts` + `article/article.html`（若已
build）+ `discovery/` 全部 + `review/` 已有审计 json。

**检查项（8 条）**：

1. **构建成功**：`npm run build` / `npm run html` 退出 0；无 TypeScript 错误；无 Vite
   警告。
2. **控制台干净**：浏览器打开 `article.html` 后 DevTools Console 无红字、无关键 warn。
3. **代码密度合规**：跑 `scripts/audit/density.sh --workspace <ws> --all`，**全节 pass**；
   贴 `review/density.json` 摘要。
4. **章节序号全篇自洽**：逐个 `<Section>` / `<Subsection>` 抄序号比对（**不要只看代码
   顺序**——多 Agent 并行下 subagent 看不到全篇位置，最容易在这里写错）；序号与 TOC、
   plan.md Outline 三者一致；第 NN 章下只能是 NN.1 / NN.2，**不能**出现别的章节前缀。
5. **Source Pointers 链接可用**：若 Phase 0 抓到 git remote，抽 5 个 pointer 点开链
   接，确认 GitHub / GitLab / Bitbucket URL 拼接正确，且 `line` 落在对应文件存在的行
   范围内。
6. **可访问性基础**：`<img>` 有 alt；`<Raw>` 内 `<svg>` 有 `role="img"` 或 `aria-label`；
   `<details>` 的 `<summary>` 有可读文本；标题层级合理（不跳级）。
7. **Article.tsx 无死引用**：assembler 里 `import` 的每个 section 文件都真的存在；
   `<Section>` 排列与 import 顺序一致；没有 import 但没渲染的死代码。
8. **Coverage / Freshness 审计已跑且嵌入 footer**：
   - `scripts/audit/coverage.sh` 输出 `coveragePct`，已被 `Article.tsx` footer 读取；
   - `scripts/audit/freshness.sh` 输出 `freshness-summary.md` 已嵌入 footer；
   - 若 size tier = `>10k`，footer 显式说"本报告为 ~70% 覆盖归档版本"。

**输出格式**：

```markdown
## Technical · <YYYY-MM-DD HH:MM>
- [1] 构建 · pass / fail —— …
- [2] 控制台 · pass / fail —— …
- [3] 密度 · pass / fail —— `review/density.json` 摘要：N 节，X fail
- [4] 序号 · pass / fail —— …
- [5] SourcePointers 链接 · pass / fail —— …
- [6] 可访问性 · pass / fail —— …
- [7] Article.tsx 无死引用 · pass / fail —— …
- [8] Coverage/Freshness footer · pass / fail —— Coverage X%, Freshness <fresh|drifted>

### 必须修复
- ...
```

三个视角可**并行**起 SubAgent，主 Agent 收齐后按 fail 项最小切片修复（见
`references/repair-policy.md`）。

---

## 7 · Coverage Audit（Phase 5 · 脚本 · 嵌 footer）

**何时**：Phase 5 三视角终审前；**谁做**：`scripts/audit/coverage.sh`；**产物**：
`review/coverage.json` + footer 嵌入 + `final-review.md` Technical 段引用。

**输入**：

- `discovery/inventory.json`（真值集）
- 所有 `article/sections/*-evidence.md`
- `article/sections/coverage-annex.json`（Section 11 Coverage Annex 显式列出的 annexed
  文件清单；contract 见 `coverage.sh --help`）

**检查项**：

- 读 inventory 中 `excluded_reason == null` 的每个文件路径。
- 对每条路径：
  - 在所有 `*-evidence.md` 中搜该路径出现 → 计为 `assigned`。
  - 若未在 evidence 出现，在 `coverage-annex.json` 中查找 → 计为 `annexed`。
  - 都没有 → 计为 `missing`。
- `coveragePct = (assigned + annexed) / totalAnalyzed * 100`。

**Pass 条件**：`missing` 为空（即 `coveragePct == 100`）。

**>10k honesty rule**：若 `discovery/size-tier.json`（实际 schema 由 tier-select 决定，
可能字段名是 `tier`，参 `discovery/tier.json`）显示该项目 size tier 为 `>10k`，**任何
`missing` 都按 fail 处理**，并以专用 exit code 2 提示——Phase 8 Delivery 必须读这个
exit code，**不允许**报告里出现 "100% coverage" 字样；footer 改为 "~70% 覆盖归档版本"
（与 reader profile downgrade 一致）。

**输出**：

```json
{
  "totalAnalyzed": 1234,
  "assigned": 1100,
  "annexed": 100,
  "missing": ["src/foo/bar.go", "..."],
  "coveragePct": 97.24,
  "verdict": "pass" | "fail",
  "sizeTier": "100-1k" | ">10k" | ...,
  "snapshot": "2026-06-21T07:30:00Z"
}
```

**Footer 注入**：`Article.tsx` 在 colophon 上方读 `review/coverage.json` 渲染一行
"Coverage: <pct>% · <assigned> assigned / <annexed> annexed / <missing.length> missing"。

---

## 8 · Freshness Audit（Phase 5 · 脚本 · 嵌 footer）

**何时**：Phase 5 终审时；**谁做**：`scripts/audit/freshness.sh`；**产物**：
`review/freshness.json` + `review/freshness-summary.md` + footer 嵌入。

**输入**：原始 `discovery/inventory.json`。

**做的事**：重跑 `scripts/discover/inventory.sh` 到临时位置；按 `{path → sha}` map 做
diff。

**输出**：

```json
{
  "originalSnapshot": "2026-06-20T14:00:00Z",
  "currentSnapshot": "2026-06-21T07:30:00Z",
  "addedFiles":    ["src/new.go"],
  "removedFiles":  ["src/old.go"],
  "modifiedFiles": ["src/foo.go", "..."],
  "verdict": "fresh" | "drifted"
}
```

`fresh` 当 `added + removed + modified == 0`；否则 `drifted`。

**Markdown 摘要**（`review/freshness-summary.md` · 适合直接嵌 footer）：

```markdown
**Snapshot**: 2026-06-20 14:00 UTC · **Re-checked**: 2026-06-21 07:30 UTC ·
**Drift**: 3 modified, 1 added, 0 removed since snapshot. (See coverage annex for full list.)
```

**Pass 条件**：永远 pass（exit 0）—— drift 不是 fail 而是**信息**。但若 verdict ==
`drifted`，footer 必须显示这条 drift summary；Technical Reviewer 检查它有没有被嵌入。

---

## 9 · Density Audit（Phase 4 每节 + Phase 5 抽样 · 脚本）

**何时**：Phase 4 每节 Reviewer 跑时（可由 Reviewer SubAgent 调用 `density.sh
--section <NN>`）+ Phase 5 Technical Reviewer 跑一次 `--all`；**谁做**：
`scripts/audit/density.sh`；**产物**：`review/density.json`。

**输入**：`article/sections/<NN>-<slug>.tsx`。

**检查项（Q9b 上限）**：

| 指标 | 默认上限 | Section 04 / 05 例外 |
|---|---|---|
| `blockCount`（每节 `<CodeBlock>` 数） | ≤ 1 | ≤ 2 |
| `linesPerBlock`（每个 `<CodeBlock>` 行数） | ≤ 8 | ≤ 8 |
| `blockToParagraphRatio`（`blockCount / paragraphCount`） | ≤ 0.15 | ≤ 0.15 |
| `codeCharShare`（CodeBlock 字符数 / 全节字符数） | ≤ 0.15 | ≤ 0.15 |

Mermaid 块**不计入** `<CodeBlock>`（它们走 `<Mermaid>` 或 `<Raw>` 组件，不是
`<CodeBlock>`）。

**输出**：见脚本 `--help`，每节一个 JSON `{section, blockCount, blockLines, paragraphCount,
codeShare, verdict, violations}`。

**Pass 条件**：所有指标都在上限内。

**修复处理**：Reviewer 报 fail → 主 Agent 改 .tsx：删 CodeBlock / 缩短到 ≤ 8 行 / 改
inline 引用 / 改 prose 描述。**不要**重跑 Step B SubAgent（除非主 Agent 判断这是 Step B
跑偏了；正常的密度超限直接在 .tsx 改更快）。

---

## 10 · Claim Trace Audit（Phase 4 每节抽 + Phase 5 抽样 · 脚本）

**何时**：Phase 4 每节 Reviewer 跑时（Reviewer SubAgent 可直接调用，或主 Agent 在
Reviewer 后跑一次确认）；Phase 5 Technical Reviewer 跑 `--all` 抽样；**谁做**：
`scripts/audit/claim-trace.sh`；**产物**：`review/claim-trace-<NN>.json`。

**输入**：

- `article/sections/<NN>-<slug>.tsx`
- `article/sections/<NN>-evidence.md`
- `article/sections/<NN>-business.md`

**做的事**：

1. 从 .tsx 抽 N（默认 5）条 prose 行（`<P>` / `<Quote>` / `<Callout>` 内）。
2. 提取每条的 identifier-class tokens（文件路径、类名、方法名、业务术语）。
3. 检查每个 identifier 在 evidence.md 或 business.md 中出现过 —— 至少 60% 命中算
   pass，否则 flag。
4. 同时对 evidence.md 中的每个 `file:line[-line]` 引用块 verbatim re-grep 一次，确认
   excerpt 与 repo 当前内容一致；不一致 = evidence drift（典型：Step A 跑完后文件被
   修改）。

**输出**：

```json
{
  "section": "04",
  "samples": [
    {"line": "...", "tokens": ["OrderService", "Checkout"], "hitRate": 1.0, "verdict": "pass"},
    ...
  ],
  "evidence_drift": [
    {"file": "src/svc/order.go", "lines": "42-78", "drift": "actual text differs"}
  ],
  "verdict": "pass" | "fail",
  "fix_hints": ["重跑 04-evidence.md（Step A）：源文件已变"]
}
```

**Pass 条件**：所有样本 hitRate ≥ 0.6 且 `evidence_drift` 为空。

**修复处理**：

- 样本 hitRate < 0.6（claim 没引用）→ 主 Agent 改 .tsx prose：加引用或重写。
- `evidence_drift` 非空 → **重跑 Step A Evidence SubAgent**（这是反幻觉的最后防线，不
  能用手 patch）。

---

## 11 · Reviewer SubAgent prompt 模板速查

各 Reviewer prompt 完整文件：

| Reviewer | Prompt 模板路径 |
|---|---|
| First Spread Reviewer | （Phase E 写在本节模板里；下方 §11.1） |
| Section Reviewer | `prompts/section-reviewer.md` |
| Editorial Reviewer | （Phase E 写在本节模板里；下方 §11.3） |
| Visual Reviewer | （Phase E 写在本节模板里；下方 §11.4） |
| Technical Reviewer | （Phase E 写在本节模板里；下方 §11.5） |

下面的模板可以直接复制贴到 SubAgent 派活消息里：

### 11.1 First Spread Reviewer

```text
你是 First Spread Reviewer SubAgent。读取：
  - article/Cover.tsx（若存在）
  - article/Article.tsx
  - article/sections/01-*.tsx
  - article/sections/01-evidence.md
  - article/sections/01-business.md
  - plan/plan.md
  - theme-profiles/<id>.md
  - references/cover.md（封面 5 条自检参照）

对照 references/review-checklist.md §2 的 13 项清单（封面 5 + 首屏 5 + 技术 3）逐项核查，
把结论写到 review/first-spread-review.md（用 §2 的输出格式）。
不要替我改文件，也不要泛泛夸奖。每项必须给出 pass/fail + 一句证据（指 file:line 或行号）。
```

### 11.2 Section Reviewer

见 `prompts/section-reviewer.md`（完整模板）。本文件 §3 是 prompt 背后的清单。

### 11.3 Editorial Reviewer

```text
你是 Editorial Reviewer SubAgent。读取：
  - plan/plan.md
  - article/Article.tsx
  - 所有 article/sections/*.tsx
  - 所有 article/sections/*-evidence.md、*-business.md
  - references/profiles/<id>.md（选定 reader profile）
  - discovery/codebase-brief.md

对照 references/review-checklist.md §4 的 7 项清单逐项核查，把结论**追加**到
review/final-review.md 的 "## Editorial" 段（用 §4 的输出格式）。
不要替我改文件，不要泛泛夸奖。每项必须给出 pass/fail + 一句证据。
```

### 11.4 Visual Reviewer

```text
你是 Visual Reviewer SubAgent。读取：
  - 所有 article/sections/*.tsx
  - article/raw-blocks/*.tsx（若有）
  - article/Cover.tsx
  - theme-profiles/<id>.md
  - references/cover.md

对照 references/review-checklist.md §5 的 7 项清单逐项核查，把结论**追加**到
review/final-review.md 的 "## Visual" 段（用 §5 的输出格式）。
不要替我改文件，不要泛泛夸奖。每项必须给出 pass/fail + 一句证据（指文件 / 节点 / 颜色）。
```

### 11.5 Technical Reviewer

```text
你是 Technical Reviewer SubAgent。读取：
  - 所有 article/sections/*.tsx
  - article/Article.tsx
  - package.json · vite.config.ts
  - 若已 build：article/article.html
  - discovery/inventory.json · discovery/tier.json
  - review/coverage.json · review/freshness.json · review/density.json（若已生成）

对照 references/review-checklist.md §6 的 8 项清单逐项核查，把结论**追加**到
review/final-review.md 的 "## Technical" 段（用 §6 的输出格式）。
你可以也应该自己跑 `bash scripts/audit/{coverage,freshness,density}.sh --workspace <ws>`
来获得最新 json。不要替我改源代码，但 npm run build 你可以跑。
```

---

## 12 · 何时跑哪个脚本（速查）

| 我在做什么 | 跑哪个脚本 |
|---|---|
| Phase 4 写完一节，Section Reviewer 触发密度检查 | `density.sh --workspace <ws> --section <NN>` |
| Phase 4 写完一节，验证 prose 引用回 evidence | `claim-trace.sh --workspace <ws> --section <NN>` |
| Phase 4 写完一节，生成 SourcePointers 数据 | `source-pointers-gen.sh --workspace <ws> --section <NN>` |
| Phase 5 终审 Technical 视角 | `coverage.sh / freshness.sh / density.sh --all / claim-trace.sh --all` |
| Phase 1 Discover 跑复杂度（Section 07 需要） | `complexity-detect.sh --workspace <ws>` |
| 修复后回归（仅该节） | `density.sh --section <NN>` + `claim-trace.sh --section <NN>` |

修完任何 fail 后**只重跑触及到的节的审计**，不要重跑整个 Phase 5；这是
`references/repair-policy.md` §5 的最小回归原则。
