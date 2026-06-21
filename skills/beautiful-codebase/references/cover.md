# Cover · 书封式封面(屏幕 3:4 / PDF 独占首页)

> **何时读**：Phase 2 写 plan.md 的 Brief 段"封面"行时;Checkpoint 1 第 5 题
> 决定封面开 / 关时;Phase 3 First Spread 替换 `article/Cover.tsx` 里的
> `<CoverPlaceholder />` 时。
>
> **配套文件**：`references/profiles/<id>.md`(每个 profile 推荐的封面起手在那里);
> `theme-profiles/<id>.md`(主题 token 才是允许的颜色 / 字体来源);
> `references/cover.md` 来源于 `beautiful-article/references/cover.md`,本 Skill
> 重述并加入代码分析报告专属的 5 个构图模板。

## 1 · 这是什么

`beautiful-codebase` 每份报告在 TOC + 正文之上有一块**像书的封面**的题图,独占顶部。
它是 HTML 报告"出版物感"的开篇 ——一眼传达"**这份代码分析报告讲什么 + 长什么气质**",
决定读者会不会往下看。

封面**不**是 Hero(沿用 beautiful-article 的区分):

| 角色 | Hero | Cover |
|------|------|-------|
| 位置 | `<Article>` 内、TOC 旁 | `<Article>` 之外、TOC 之上 |
| 形态 | 标题 + 副题 + meta(文字栏) | 3:4 图文构图(图 + 字) |
| 职责 | 框定主题 + 读者收获 | 视觉钩子 + 风格定调 |
| 信息 | 文字为主 | **图主字辅** |

两者**互补**:封面引人,Hero 锚定。**不要把它们做成同一件事**。

## 2 · 硬约束(5 条 · 不可妥协)

1. **3:4 屏幕 + PDF 独占首页(外壳不要动)**:`Cover.tsx` 的 `aspectRatio: "3 / 4"` 和
   max-width / margin / border 不要改 —— `pdf-print-overrides.css` C 段只负责让封面
   之后分页。**内部元素一律用百分比 / 相对单位**,不要写绝对 px 高度。
2. **图文并茂(禁止纯文字封面)**。必须同时具备:
   - **视觉主体**(SVG / CSS 几何 / 复杂 React 组件 / 字体艺术 任选);
   - **文字层**:至少一个标题、副标题 `Codebase Analysis · <profile>`、底部 colophon。
3. **主题忠实 · 只能用 `--ra-*` token**:颜色 / 字号 / 字重 / 边框 / 圆角 / 间距全部
   通过 `var(--ra-terminal-fg)` / `var(--ra-status-blue)` / `var(--ra-text-3xl)` 等取值。
   **禁止**写死 hex / 字体名 / 像素字号 —— 切主题封面就废。
4. **内容忠实(代码分析报告专属)**:封面的视觉主体要呼应**本报告的主旨** ——
   读完封面读者要能猜出 "这是哪种 reader profile 的报告 + 这个项目大概是什么气质"。
   architecture-review 报告的封面气质应该是"判断锚点"(模块拓扑骨架 / 风险灯阵);
   onboarding 报告的封面气质应该是"欢迎引导"(welcome map / starter trail);
   archaeology 报告的封面气质应该是"时间胶囊"(time capsule / knowledge vault)。
5. **offline-first 严格禁远程图**:`<img src="https://...">` / Google Fonts 动态加载 /
   跨域 CSS background-url 一律禁;base64 raster 仅当 Checkpoint 1 选了 `user-assets` /
   `ai-generated` 才允许,且必须内联。

## 3 · 5 个构图模板(代码分析报告专属)

下面 5 个模板覆盖 `beautiful-codebase` 三个 reader profile 的常见封面气质。**不要混搭**
——一份报告一个模板。

### 3.1 Tech-stack mosaic(技术栈拼贴)

**适合**:architecture-review profile;多语言 / 多框架 / 多依赖的中台系统。

**构图**:把项目主要语言图标 / 核心框架 logo / 关键依赖徽章用 SVG **内联**(禁止远程
图,所有图标用 simple-icons 的 SVG path 内联)排成 3×3 / 4×2 / 2×4 拼贴。中央或下方
大字项目名。颜色用 terminal 主题的 `--ra-status-blue` + `--ra-terminal-fg-mute`
+ `--ra-terminal-surface-2`。

**典型布局**(口述): 上 1/3 是 3×3 / 4×2 / 2×4 图标拼贴(代表项目主要技术栈),
下 2/3 是项目名 + 副标题 + colophon 占位行。

**反面**: 别堆 9 个以上图标;别用 emoji 替代 SVG icon;别让图标颜色挑战 terminal token。

### 3.2 Module dependency silhouette(模块拓扑骨架)

**适合**:architecture-review 或 archaeology;**清晰系统** —— 模块边界整齐、依赖关系
明确的项目。

**构图**:把 Section 03 Architecture Map 的**简化版**用 `--ra-status-blue` 发丝线在
封面上呈现 ——节点用 `--ra-terminal-surface-2` 的小方块(只画轮廓不写文字),依赖关系
用发丝线连接。整体像一张"项目脉络图"。中央或上方大字项目名。

**典型布局**(口述): 上 1/3 是项目名 + 副标题 + colophon;下 2/3 是 5-8 个抽象方块
节点 + 发丝线连接,呈金字塔或三角形拓扑。

**反面**: 不要画完整的 Section 03 ——封面是钩子,不是 dashboard;节点 ≤ 8 个为佳。

### 3.3 Risk traffic-light grid(风险红黄绿格)

**适合**:architecture-review;**判断为重构 / 弃用**的项目 ——传达紧张感。

**构图**: 3×3 或 2×3 符号化网格,每格用 terminal 的 `--ra-risk-red` / `--ra-warn-amber`
/ `--ra-status-green` 三色填色(取 12-18% 透明度作为背景 + 纯色作为边框),格内用
`--ra-mono-display` 小字写风险类别("Tests / Deps / CVE / LOC / Complexity / Owners"
等)。下方大字项目名。

**典型布局**(口述): 上 1/2 是 2×3 或 3×3 色块网格(每格 1 个风险类别 + 1 个红 / 黄 /
绿状态色);下 1/2 是项目名 + 副标题 + colophon。

**反面**: 不要让红格 > 50%(全红的封面读者会本能拒绝);风险类别名不要超过 6 个字符
(等宽字撑不开)。**禁止**给 GREEN 加 emoji ✅;只用 `<Badge>` 风格的色块。

### 3.4 Welcome map(欢迎地图)

**适合**:onboarding profile;气质"温和欢迎"。

**构图**: 用 SVG 画一个抽象的"项目地形图" ——把主要目录画成几个相邻区域(用
`--ra-terminal-surface-2` 填色,`--ra-status-green` 描边),中心一个 "you are here"
星标(用 `--ra-status-blue`,8 角星 SVG path)+ 项目名。可选:加几条虚线代表"starter
trail" 路径,从 "you are here" 向各区域延伸。

**典型布局**(口述): 上 2/3 是抽象地形 ——3-5 个相邻区域(代表主要目录)+ 中心
"you are here" 星标 + 几条虚线 trail;下 1/3 是项目名 + 副标题 `Onboarding Guide ·
Day 1` + colophon。

**反面**: 不要把地图画太精确(看起来像真实地图);保持抽象 / 象征。**禁止** risk
红色块出现 ——onboarding 的视觉语言是欢迎,不是警示。

### 3.5 Time capsule(时间胶囊)

**适合**:archaeology profile;气质"为未来归档"。

**构图**:主视觉是一条横向时间轴(SVG 线 + 等距圆点,代表 commit 时间分布),
首尾两端用 `--ra-mono-display` 小字标 `<earliest commit date>` / `<latest commit date>`。
中央叠加项目名(大字)+ 主要贡献者(`@xxx @yyy @zzz`,等宽小字)。颜色用
`--ra-status-blue` 圆点 + `--ra-terminal-fg-mute` 线 + `--ra-terminal-fg` 文字。

**典型布局**(口述): 上 1/3 是项目名 + 副标题 `Codebase Archaeology · <date> snapshot`
+ 贡献者列表 `@yzt @abc @xyz`;中 1/3 是横向时间轴(5-10 个稀疏圆点);下 1/3 是
colophon `Made with [beautiful-codebase] · tufte theme`。

**反面**: 不要把时间轴画太复杂(分日 / 分月密集圆点会喧宾夺主);保持 5-10 个稀疏
节点;贡献者列表 ≤ 5 个,多了换"+ N more"。

## 4 · 三主题的封面起手(token 用法速查)

| 主题 | 推荐模板 | 主要 token | 视觉手法举例 |
|------|----------|------------|--------------|
| `terminal` | 3.2 / 3.3 / 3.5 | `--ra-terminal-bg`(底)+ `--ra-status-blue` / `--ra-status-green` / `--ra-risk-red`(主视觉) + `--ra-mono-display`(大字标题) | 发丝线骨架 / 状态色格 / 终端字标题 |
| `tufte` | 3.5 / 3.2 | `--ra-color-bg`(浅底)+ `--ra-color-fg-mute`(发丝)+ `--ra-color-accent`(单点强调) | data-ink 风的克制曲线 / 极细线图 |
| `press` | 3.4 / 3.1 | `--ra-color-bg`(暖底)+ `--ra-color-accent`(印刷色) + `--ra-serif`(衬线大字) | 大字标题 + 横分割线 / 印刷感拼贴 |

具体 token 见各主题的 `theme-profiles/<id>.md` 文件;tufte / press 因为 inherited from
`beautiful-article`,token 走那个 Skill 的 canonical 版本。

## 5 · `Cover.tsx` 脚手架契约

scaffold(`scripts/scaffold.sh`)在 `article/Cover.tsx` 创建一个**封面外壳 + 占位**:

```tsx
// 外壳(不要动)
export function Cover() {
  return (
    <div className="ra-cover" style={{
      aspectRatio: "3 / 4",
      maxWidth: "min(100%, 48rem, calc((100vh - 8rem) * 3 / 4))",
      margin: "0 auto",
      // ... 其他外壳样式
    }}>
      <CoverPlaceholder />
    </div>
  );
}

// 占位(Phase 3 First Spread 替换)
function CoverPlaceholder() {
  return <div>...占位内容...</div>;
}
```

**Phase 3 First Spread 主 Agent 的职责**: 把 `<CoverPlaceholder />` 替换成按 reader
profile + 主题选定的真实构图;**外壳一行不动**。

**PDF 分页**: `scripts/pdf-print-overrides.css` C 段自带 `.ra-cover { break-after:
always }`,封面之后自动分页;Phase 3 不需要额外处理。

## 6 · Self-check(5 条 · 写完封面立刻自查)

1. **图文并茂**:截掉文字层后还剩视觉主体?截掉视觉层后还剩文字?两者都要有。
2. **主题忠实**:切到 `theme-profiles/index.json` 里另一个主题(改 `main.tsx` 一行),
   封面**自动跟随**变色 / 变字、不破相?有写死值就不算过。
3. **内容忠实(profile 维度)**: 盯着封面看 5 秒,能不能猜出这是 architecture-review /
   onboarding / archaeology 哪种报告?如果三者气质混淆不算过。
4. **比例自适应**:把容器从 3:4(屏幕)拉到 ~3:4.2(A4) / ~3:3.9(Letter),内部元素
   没溢出 / 没错位 / 没出现大块空白?(用 `position:absolute; inset:0` + `grid` /
   `flex` 撑起元素,而不是写死像素位置,就自动通过)
5. **不与 Hero 重复**:封面文字 ≠ Hero 文字(一个钩子,一个锚点)?

## 7 · 反面案例(禁止)

- **纯文字封面**(只有标题居中,没有视觉主体)。
- **远程图片**(`<img src="https://...">` / `background-image: url(https://…)`) ——
  离线打不开。
- **写死颜色 / 字体 / 像素值**(`color: #ff0066` / `font: 24px Helvetica`) —— 切主题废。
- **位置写死成绝对像素**(`top: 384px`) —— 换视口或打印缩放就错位。
- **复制 Hero 内容到封面**(标题 + 副题 + 日期 + 作者全堆封面) —— 与 Hero 重复。
- **AI 画假架构图**(用 ai-generated 模式画"项目架构示意") —— 违反反幻觉铁律。
- **封面塞过多元素**(标题 + 副题 + 三个小标签 + meta + Lead + TOC 预览 + 大插画) ——
  不像封面像 dashboard。
- **Canvas 动画依赖时间才出现内容**(PDF 只截第一帧,黑屏) —— 保证第一帧自身就好看。
- **代码风险数据强行打到封面**(把 Section 08 的所有风险条目放封面) —— 封面是钩子,
  详情在 Section。

## 8 · 何时关闭封面(`--no-cover`)

代码分析报告 99% 的场景都该开。少数关闭的情况:

- **极短 onboarding 报告**(`<100` 文件 + 用户希望"打开就上手"):可关。
- **CI / dashboard 嵌入式报告**(用户在 Phase 0 说"这份报告会嵌到 internal portal 里
  做 iframe"):封面在嵌入场景里浪费空间,可关。
- **用户明确要关**:尊重用户。

关闭方法:`bash <skill>/scripts/scaffold.sh ./<project>-analysis --theme=terminal --no-cover`。
已脚手架:删 `article/main.tsx` 里 `<Cover />` 引入和渲染,可顺手删 `Cover.tsx`。

## 9 · PDF 表现

`scripts/pdf-print-overrides.css` 的 C 段会把封面:

- 保持封面的 3:4 外壳不变 —— 避免 Chromium print 在强拉伸时裁切内部布局。
- `break-after: always` —— TOC 从第二页开始。

效果:PDF 第一页 = 3:4 封面独占首页;第二页起 = TOC + 正文。

---

> 本文件描述代码分析报告专属的 5 个封面模板。如果在 dogfood 时发现某种 profile +
> 项目类型需要新模板,**回到本文件加 §3.6**,不要在单份报告里临时设计 ——下次同类
> 项目还会用到。
