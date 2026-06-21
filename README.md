<p align="center">
<picture>
<source srcset="./assets/banner.png" media="(prefers-color-scheme: dark)">
<source srcset="./assets/banner.png" media="(prefers-color-scheme: light)">
<img src="./assets/banner.png" alt="StarCodex" width="100%" style="image-rendering: -webkit-optimize-contrast; image-rendering: crisp-edges;">
</picture>
</p>

<p align="center">
<strong>StarCodex — 星典聚码，连链成图，淬项目为工程之书。</strong><br/>
<sub>一款 AI 编码技能：通读你的项目，将代码织为可导航的知识图谱，再淬炼为可查可承的工程之书——让每位贡献者与每个编码 Agent，都能打开同一张地图。</sub>
</p>

<p align="center">
<a href="./README_EN.md">English</a>
</p>

<p align="center">
<a href="https://github.com/LikeAsWind/StarCodex/stargazers"><img src="https://img.shields.io/github/stars/LikeAsWind/StarCodex?style=flat-square&color=eab308" alt="stars" /></a>
<a href="https://github.com/LikeAsWind/StarCodex/issues"><img src="https://img.shields.io/github/issues/LikeAsWind/StarCodex?style=flat-square&color=e67e22" alt="open issues" /></a>
<a href="https://github.com/LikeAsWind/StarCodex/pulls"><img src="https://img.shields.io/github/issues-pr/LikeAsWind/StarCodex?style=flat-square&color=9b59b6" alt="open PRs" /></a>
<a href="./LICENSE"><img src="https://img.shields.io/github/license/LikeAsWind/StarCodex?style=flat-square&color=10b981" alt="license" /></a>
</p>

---

## 这是什么

StarCodex 是一个 **AI 编码技能 (Skill) 集合**。每个 skill 都是一份声明式工作流，让 AI 编码助手 (Claude Code / Cursor / Codex / Gemini / opencode 等) 把一类具体任务做透——不是给一段提示词模板，而是把"理解、规划、执行、自检、交付"完整流程沉淀成可复用的工序。

定位上**它不是一个独立应用，也不是一个你直接跑的工具**——你把 skill 喂给 AI 编码客户端，AI 按 skill 描述的流程一步一步做事；skill 本身只是 markdown + 脚本 + 模板。

v0.1.0 仓库内现有 1 个 skill；后续版本会陆续加新 skill。

## 现有技能

### `beautiful-codebase` · 单文件 HTML 代码分析报告

把任意代码项目（语言无关：Java / Python / Go / TypeScript / Rust …）做成一份**自包含、可离线打开、可分享**的单文件 HTML 代码分析报告。

核心特性：

- **三档工具回退**：codegraph (推荐) → rg → grep 自动选档，在不同的开发环境下都能跑。
- **三阶段写作 (Evidence → Business → Writing)**：写作子代理在机制层面无法读源码，只能读上游沉淀好的 evidence.md / business.md，反幻觉。
- **三种读者画像**：`architecture-review` (架构评审 · 30 分钟看清结构性风险) / `onboarding` (新人入职 · 第二天 ship 第一个 issue) / `archaeology` (交接归档 · 半年后还能找回决策)，每种画像决定必选 Section、信息保留比例、主题搭配。
- **mermaid 主导可视化**：架构图、调用链、业务领域图全用 mermaid；SVG 仅留给封面和复杂度热图。
- **业务证据自动采集**：从注释、测试、DB schema、配置文件、commit 历史里重建业务背景，**禁止凭空编造**。
- **三 Checkpoint 硬节点**：Plan / First Spread / Final 三处必须停下问用户，不允许 Agent 替你静默选择。
- **可选 PDF 导出**：headless 浏览器打印，零 npm 依赖。

→ 详细使用流程见 [docs/usage-guide.md](docs/usage-guide.md)
→ Skill 入口与源码：[skills/beautiful-codebase/SKILL.md](skills/beautiful-codebase/SKILL.md)

## 快速开始

> 前提：你在 Claude Code / Cursor / Codex / Gemini / opencode 等支持 skill 的 AI 编码客户端里；系统装了 `git`，以及 `codegraph` / `rg` / `grep` 任一即可（三档兜底）；Node.js 18+ 用于报告 workspace 的 Vite 构建。

1. **克隆本仓库到 AI 客户端能读到的位置**（同一台机器即可）：

   ```bash
   git clone https://github.com/LikeAsWind/StarCodex.git
   ```

2. **让你的 AI 客户端发现 skill**：

   - **Claude Code**：把 `skills/beautiful-codebase/` 复制（或建符号链接）到 `~/.claude/skills/`，重启会话；或直接在客户端里告诉 AI "读 `<repo>/skills/beautiful-codebase/SKILL.md` 然后按它的流程做事"。
   - **Cursor / Codex / Gemini / opencode**：直接让 AI 读 `SKILL.md`，它的 frontmatter 写明了触发词，正文是完整的 phase 说明 + checkpoint 协议。

3. **触发**：在 AI 客户端里发任一类似的请求，AI 会自动进入 `beautiful-codebase` 工作流：

   - "分析这个代码库"
   - "给这个项目做一份分析报告"
   - "给我一个项目架构总览"
   - "帮我写一份代码归档"
   - "我要交接这个项目"
   - "analyze this codebase" / "build a beautiful codebase report" / "generate an architecture review of this repo"

4. AI 会按 Phase 0 → 6 走一遍流程；其中 **3 个硬 Checkpoint** 必须停下来让你独立确认 (读者画像 / 主题 / 版式宽度 / 配图模式 / 封面 / 首屏验收 / 开发模式 / 交付决策)，**Agent 不会替你静默选择**。

→ 完整流程手册：[docs/usage-guide.md](docs/usage-guide.md)

## 仓库结构

```
StarCodex/
├── skills/                  # AI 编码技能集合 (v0.1.0 共 1 个)
│   └── beautiful-codebase/
│       ├── SKILL.md         # skill 入口（含 frontmatter 触发词）
│       ├── manifest.json    # 元数据 + 兼容客户端列表
│       ├── references/      # 按需加载的子文档（各 phase 详细规则）
│       ├── prompts/         # 子代理 prompt 模板（原样发给 SubAgent）
│       ├── scripts/         # 工具链 (probe / scaffold / discover / audit / delivery)
│       ├── theme-profiles/  # 三个主题的 authoring 描述
│       └── assets/          # scaffold 模板等静态资源
├── docs/
│   └── usage-guide.md       # 完整使用流程手册（链接自 README）
├── assets/
│   └── banner.png           # 仓库 banner
├── README.md / README_EN.md
├── LICENSE                  # MIT
├── AGENTS.md / CLAUDE.md    # 仓库内 AI 客户端约定
└── v0.2-followups.md        # v0.1.0 → v0.2 已知待办（dogfood 沉淀）
```

## 开发与贡献

本仓库目前是单人维护。欢迎反馈 issue 与改进建议。

新增 skill 的约定：

- 每个 skill 自带 `SKILL.md`（frontmatter 含触发词描述）+ `manifest.json`（含 `compat` 兼容客户端列表）+ `references/`（按 phase 拆分的子文档）+ `scripts/`（工具脚本）+ `prompts/`（如有 SubAgent 派活模板）。
- skill 可独立工作，不依赖其它 skill 的运行时（可以 cite 其它 skill 的 reference 文档作为对照）。
- 详见 `skills/beautiful-codebase/` 作为骨架范本。

`v0.1.0 → v0.2 待办`（含 16 条 dogfood findings：reacticle API drift / 脚本 regex 缺陷 / Windows PDF path / 主题阻塞等）见 [v0.2-followups.md](v0.2-followups.md)。

## 兼容客户端

`beautiful-codebase` 的 `manifest.json` 已声明兼容：**Claude Code** · **Claude.ai** · **Cursor** · **Codex CLI** · **Gemini CLI** · **opencode**。

实际只在 Claude Code 上跑过端到端 (StarCodex 自己 dogfood，v0.1.0)。其它客户端理论可用，实测留待社区反馈。

## 许可

[MIT](LICENSE)
