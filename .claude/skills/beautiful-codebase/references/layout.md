# Layout · 版式宽度 + TOC

> **何时读**：Phase 2 写 plan.md 的 Brief 段(版式宽度 / TOC 两行)时;Checkpoint 1
> 推荐版式时;Phase 3 First Spread 写 `<Article width="…" toc>` 时回看。
>
> **配套文件**：`theme-profiles/<id>.md`(主题与版式正交,但部分主题对宽度有偏好提示);
> `references/profiles/<id>.md`(profile 通常隐含 TOC 偏好)。

版式是**与主题解耦的独立决策** —— 主题只管审美气质,宽度 / TOC 管阅读版式。在
Checkpoint 1 由用户确认,落到 `plan/plan.md` Brief 段的"版式宽度"行 + "TOC" 行。

## 1 · 4 种宽度

由 `<Article width="...">` 控制(reacticle ≥ 0.2.0)。**主题与宽度正交**,任意主题
都能搭任意宽度。

| 模式 | 阅读列宽 | 适合代码分析报告的场景 |
|------|----------|------------------------|
| `narrow` | ~34rem (~640px) | 极短报告、briefing 风格、reader profile = onboarding 且项目极小(`<100` 文件) |
| `regular` | ~46rem (~760px)(默认) | 大多数 architecture-review 与 onboarding 报告;表格少 / 流程图中等密度 |
| `wide` | ~58rem (~1040px) | **流程图密集**(Section 05 ≥ 10 张 `flowchart TD`);**长文件路径**频繁出现(`> 60` 字符的 `file:line`);archaeology 的 Module Chapters 段 |
| `full` | ~78rem (edge-to-edge) | 仅用于 atlas 页(完整 File-tree Atlas) / Section 07 SVG 复杂度热图独占的报告页 |

**关键经验**:代码分析报告比通用文章**更容易**触发 `wide` 的推荐 —— Mermaid 流程图
横向溢出 `regular` 列宽时阅读体验明显下降;长 Java / Go 包路径(如
`com.company.platform.order.service.OrderProcessingServiceImpl`)在 `regular` 下也容易
折行。**所以本 Skill 的 `wide` 推荐频率高于 beautiful-article**。

## 2 · TOC

由 `<Article toc>` 控制 —— 渲染左侧目录(从 `Section` / `Subsection` 自动派生,
最多三级,带滚动高亮)。

- **本 Skill 默认开启 TOC**:代码分析报告的 Section 数通常 7-15(architecture-review)或
  13+ 子章(archaeology),没有 TOC 几乎不可读。**Checkpoint 1 不单独成题,默认开**。
- **极短报告可以关**:`<100` 文件的 onboarding 报告(可能只有 4-5 节),TOC 比正文还长 ——
  这种情形 plan.md Brief 写 "TOC: 关" 即可。Phase 4 写作时不渲染 `<Article toc>`。
- **archaeology profile 的 TOC 必须分层**:由于章数多(可能 30+ 章),TOC 必须是
  `Section / Subsection` 两级(reacticle 默认就是),让读者能折叠展开。Plan 阶段
  默认不需要额外配置 ——但在 plan.md Brief 段写一行 "TOC:开 · 分层(archaeology
  章数多)" 提示后续 Section Writing SubAgent 写 Subsection 时要规整。

## 3 · 何时推荐 `wide`

Plan SubAgent 在写 plan.md Brief 段时,按下列条件**任一满足**即推荐 `wide`:

1. **Section 05 流程图密集**:`discovery/codebase-brief.md` 的 "Entry-point sniff" 段
   预计 Section 05 渲染 ≥ 10 张 `flowchart TD`。
2. **长文件路径密集**:`discovery/inventory.json` 中 ≥ 30% 的文件路径长度 > 60 字符
   (Java / Go / Rust 多包项目常见)。
3. **archaeology profile + ≥ 10 个 bucket**:Module Chapters 段每章一张子图,长报告下
   `wide` 让子图更舒展。
4. **Section 07 SVG 热图**:复杂度热图横向密集,`wide` 让格子更清晰。

否则推荐 `regular`(默认)。

**`narrow` 几乎不推荐** —— 只有 onboarding profile + `<100` 文件项目这种"极短" 情形
才用。

**`full` 只在 archaeology 的 File-tree Atlas 独占 Section 时考虑** —— 不是整篇 Article
都用 `full`,而是在该 Section 内部用一个 `<Raw width="full">` 局部覆盖。Plan 阶段
通常不需要写 `full`。

## 4 · 用法示例(Phase 3 / 4 写作时)

```tsx
// 默认:常规宽度 + 开 TOC(本 Skill 最常见)
<Article toc width="regular">
  <Cover />
  <Hero ...>
  <Section id="01-verdict">...</Section>
</Article>

// 流程图密集的 architecture-review:wide + TOC
<Article toc width="wide"> ... </Article>

// 极短 onboarding(< 100 文件):narrow + 关 TOC
<Article width="narrow"> ... </Article>
```

## 5 · 与主题的关系(再次强调:正交)

- terminal 在 `narrow` / `regular` / `wide` 下都正常 —— 暗底等宽不挑宽度。
- tufte 在 `regular` / `wide` 下都正常;`narrow` 时边注被压缩,需要在 Plan Theme 段
  注明 "tufte + narrow:边注降级为 inline footnote"。
- press 在 `regular` / `wide` 下都正常;`narrow` 时大字标题会显得拥挤,通常不推荐。

**没有"这个主题只能用这个宽度"的硬规则** —— 都是建议;切宽度后目检即可。

## 6 · Checkpoint 1 的体现

版式宽度是 Checkpoint 1 的第 3 题(见 `references/plan-template.md` §E.2)。AI 推荐
按本文件 §3 的规则;用户可以推翻。

TOC 默认开 / 关**不单独成 Checkpoint 题** —— 走默认(开),除非用户在 Phase 0 自由
文本里说"我不要 TOC"。如果走默认与项目特征冲突(典型:`<100` 文件项目默认开 TOC
但只有 4 节),Plan SubAgent 应该在 Checkpoint 1 的"开场说明"段提一句:"本项目较小,
TOC 可关;走默认开,你可以告诉我关掉。"

## 7 · 移动端

- terminal 在移动端:标题字号下沉(由 reacticle 自动处理,不需要 plan / writing 改),
  徽章不换行(`white-space: nowrap`,由组件库实现),表格横向滚动(由组件库实现)。
  **作者不需要写 media query**。
- TOC 在窄视口(< 1000px)自动塌成"顶部抽屉" 单栏(reacticle 默认行为)。
- `wide` 在移动端自动落回 `regular`(reacticle 默认行为)。
- `full` 在移动端依然 full(因为 full 通常用于 Section 07 热图 / atlas,移动端就是要
  edge-to-edge)。

## 8 · 自检

- 宽度是否匹配内容?(流程图 / 长路径多 → 至少 `wide`;短叙事 → `regular` / `narrow`)
- 宽度是按内容选的,而不是按主题选的?(本 Skill 任何主题都能用任何宽度)
- TOC 开 / 关是否符合 profile 默认?(architecture-review / archaeology 默认开;
  极短 onboarding 可以关)
- archaeology 的 TOC 是否分层(Section / Subsection)?
- 移动端预览(`npm run dev` 后浏览器开发者工具切到 mobile)有没有破相?
