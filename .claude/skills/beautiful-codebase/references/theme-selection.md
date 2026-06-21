# Theme Selection · 主题选择

> **何时读**：Phase 2 写 plan.md 的 Theme 段时;Checkpoint 1 推荐主题时;Phase 3 / 4
> 写 First Spread 与每节、需要"贴着主题写"时回看。
>
> **配套文件**：`theme-profiles/index.json`(主题元数据)、`theme-profiles/<id>.md`
> (具体主题的 authoring profile)、`references/profiles/<id>.md`(reader profile);
> `references/raw-policy.md`(Raw 怎么响应主题)。

主题负责**审美气质、排版语言、Raw / Mermaid 风格、代码 / 徽章风格**。它不是 CSS 皮肤,
也不是 reader profile 的同义词。

> CSS 给浏览器读,theme profile 给 AI 读。
> reader profile 决定**Section 取舍 + 业务-Job 风格**,theme 决定**视觉气质 + 颜色语义**。
> 两者正交。

## 1 · 三主题速查

`beautiful-codebase` v0.1.0 锁定 3 个主题(沿用 PRD Q8 的决定):

| Theme | runtime id | 何时选 | 何时不选 |
|-------|-----------|--------|----------|
| **terminal** | `terminal` | code-native;暗底等宽 + 5 类语义状态色;Section 02b / 05 / 08 的徽章 / 流程图 / 业务实体都依赖本主题的色 token | 需要打印的正式纸质交付物(暗底费墨);温暖叙事 / 出版气质的报告 |
| **tufte** | `tufte` | 证据 / 数据密集;archaeology profile + 长归档;学术 / 研究 / 算法库;data-ink 风格的低装饰长报告 | 需要鲜明色调度的业务报告;Section 08 风险徽章频率高的项目 |
| **press** | `press` | 项目本身是 CMS / blog engine / 内容业务;希望读起来像一本团队 editorial guide 的 onboarding | 数据 / 证据密集的 archaeology 长报告(用 tufte);技术中台 / 工具的 architecture-review(用 terminal) |

## 2 · 默认推荐规则

`beautiful-codebase` 的**默认主题推荐 = `terminal`**(`theme-profiles/index.json` 的
`default: true`)。理由:

- `terminal` 的 5 类语义状态色(risk-red / warn-amber / status-green / status-blue /
  status-violet)是为代码分析报告的徽章 / 流程图 / 业务实体配色专门设计的;其他主题
  没有现成的"风险红"和"业务紫" token,需要在 plan / writing 阶段手写一组替代色。
- 暗底等宽承载大量 `file:line` 引用(Q9b 鼓励 inline)时视觉成本最低。
- mermaid 的 6 种 class 颜色(controller / scheduled / consumer / cli / middleware /
  risk)直接对应 terminal 的 token,**不需要额外配置**(见 `theme-profiles/terminal.md`
  §4.3)。

**仅当**项目偏离"业务系统 / 中台 / 工具"这个默认语义类型时,才换主题:

- 项目偏**学术 / 研究 / 评测**(典型:论文配套代码、ML pipeline、benchmark suite) →
  推荐 `tufte`。
- 项目偏**内容业务 / CMS / blog**(典型:Ghost、WordPress、内部博客后端) →
  推荐 `press`。

## 3 · 与 reader profile 的搭配(3×3 矩阵)

下表是 Plan Checkpoint 1 推荐主题时的查表:**每个 (profile, project-type) 组合**
给一个推荐主题 + 一句理由。"project-type" 由 `discovery/codebase-brief.md` 的
"项目语义分类" 字段提供(在 Phase 1 末尾推断)。

|                    | project-type = **business / tooling / 中台** | project-type = **research / academic / library** | project-type = **cms / content** |
|--------------------|----------------------------------------------|--------------------------------------------------|----------------------------------|
| **architecture-review** | `terminal` · 默认推荐;徽章 / 流程图密集,terminal 的语义色直接对应 | `tufte` · 评审一个研究项目时,克制 + data-ink 比 terminal 的徽章感更合适 | `press` · 评审内容业务项目时,主题与项目气质契合 |
| **onboarding** | `terminal` · 默认推荐;新人需要清晰的颜色编码 | `terminal` · 学术项目的新人通常也是工程师,terminal 更直接 | `press` · 内容团队的新人手册更适合 press 的叙事感 |
| **archaeology** | `terminal` 或 `tufte` · 业务系统归档用 terminal;若希望"经得起时间"用 tufte | `tufte` · **强烈推荐**;长归档 + data-ink + 学术克制 = 完美组合 | `press` · 内容业务归档可以走 press,但更长的报告下 tufte 仍然可接受 |

**例外说明**:

- 矩阵给的是"默认推荐",**不是强制**。用户在 Checkpoint 1 可以推翻,Plan 阶段不要
  替用户选。
- 如果 Plan SubAgent 无法从 codebase-brief.md 推断 project-type,**默认按 business**
  处理(走第一列) ——这是最常见的情形。

## 4 · 主题如何约束 Raw 块

(详见 `references/raw-policy.md`,本节只点要害)

每个主题的 Raw 块都必须**只用 `--ra-*` token**;不允许写死 hex 颜色 / 字体名 / 像素值。
所以"切主题需要改 Raw 吗?"的答案是 **不需要**(如果 Raw 写得规矩) —— Raw 自动跟随
主题变色。

terminal 主题对 Raw 的特殊约束:

- Mermaid 节点 class 只用 §4.3 表的 6 个 class(controller / scheduled / consumer /
  cli / middleware / risk),**不允许自定义 classDef**。
- SVG(Section 07 复杂度热图 / 封面)只用 status-red / warn-amber / status-green 三色
  填色;**不允许自定义 hex**。
- 徽章(Section 08 风险)只用 §4.1 的 5 种(BLOCKER / WARN / OK / INFO / BUSINESS),
  **不允许自创徽章名**。

tufte / press 主题对 Raw 的约束沿用 `beautiful-article` 的同名主题文档;两者都禁止
霓虹 / 渐变 / 装饰色。

## 5 · 切主题的成本

scaffold 后切换主题需要改 **3 处**:

1. `article/main.tsx` 里的 `<ThemeProvider theme="...">` 一行。
2. `article/Article.tsx` 末尾的 colophon Raw 块里的主题名(`Made with [beautiful-codebase] · <theme> theme`)。
3. 如果用了 mermaid,**重新初始化** `mermaid.initialize({ theme: 'base', themeVariables: { ... } })`
   ——每个主题有自己的一组 mermaid 变量(terminal 在 `theme-profiles/terminal.md` §4.3
   给出;tufte / press 在 beautiful-article 的对应文档给出)。

切完后跑一次 `npm run dev`,目检每节的徽章 / 流程图 / 表格 / 封面是否自动变色;
**如果有破相,大概率是某段写死了 hex / 字体名 / 像素值,改写它**,不要在主题切换
脚本里打补丁。

## 6 · 不再扩展主题(v0.1.0)

v0.1.0 锁定 3 主题(terminal / tufte / press);**v0.2 才考虑新增**。新增主题的约束:

1. **组件库 runtime**:reacticle 必须有对应 runtime theme CSS 与 `<ThemeProvider>`
   注册;只在 Skill 这一侧加 `theme-profiles/<id>.md` 是不够的(只能作候选,不能用于
   正式生成)。
2. **Skill authoring profile**:必须有 `theme-profiles/<id>.md` + 在
   `theme-profiles/index.json` 注册 + 完整定义代码语义色 / 状态色 / 字体角色 / mermaid
   变量。
3. **canonical 来源**:tufte / press 的 canonical 来源是 **`beautiful-article` 的同名
   theme-profile**;`beautiful-codebase` 的 `theme-profiles/{tufte,press}.md` 是 re-export
   stub,**禁止在本 Skill 内修改它们**(会和 `beautiful-article` 行为漂移)。新增主题
   建议先在 `beautiful-article` 落定,再 re-export 到本 Skill。

## 7 · 主题选择自检(写完 plan.md Theme 段后内联自查)

- 选定主题是否在 `theme-profiles/index.json` 里存在?
- 与 reader profile 的搭配是否查过 §3 的 3x3 矩阵?
- 与项目语义类型(business / research / cms)的契合度有没有写在 Plan Theme 段?
- 如果不是默认 `terminal`,有没有写"为什么不是 terminal"的一句理由?
- mermaid 在该主题下的 6 个 class 颜色是否清楚(terminal 见 §4.3;其它主题可能需要
  在 Plan Theme 段额外定义)?

---

> 本文件是给 AI 读的主题选择决策树。如果实际跑出来发现某个 (profile, project-type)
> 组合的推荐不对,**回到本文件改 §3 的矩阵**,不要在单份 plan.md 里临时换主题。
