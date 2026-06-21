# Scaffold · `<project>-analysis/` 工作区脚手架

> **何时读**：Phase 3 First Spread 跑 `scripts/scaffold.sh` 时（每个项目跑一次）。

## 1 · 用法

```bash
# 最常用：在当前目录的 <name>-analysis/ 里建工作区
bash <skill>/scripts/scaffold.sh ./StarCodex-analysis --theme=terminal

# 关封面（适合 briefing / 给忙人看的极简版报告）
bash <skill>/scripts/scaffold.sh ./brief-analysis --theme=press --no-cover

# 只看可选主题列表
bash <skill>/scripts/scaffold.sh --list-themes

# Dry-run：建好目录树和文件，但不跑 npm install（CI / 无网络环境）
bash <skill>/scripts/scaffold.sh ./test --skip-install
```

| 参数 | 默认 | 说明 |
|---|---|---|
| `<target-dir>` | `my-codebase-analysis` | 工作区目录路径。必须不存在或为空。 |
| `--theme=<id>` | `terminal` | 必须是 `theme-profiles/index.json` 注册的 id：`terminal` / `tufte` / `press`。 |
| `--no-cover` / `--cover` | `--cover` | 关闭封面则不复制 `Cover.tsx` 并从 `main.tsx` 剥掉 `__COVER_*__` 标记段。 |
| `--skip-install` | off | 跳过 `npm install`；用于 dry-run / 离线环境。 |
| `--list-themes` | — | 打印可用主题后退出。 |
| `--help` / `-h` | — | 打印使用说明后退出。 |

## 2 · 工作区位置铁律

- **默认 `./<target>-analysis/`** —— 工作区在当前目录创建，**永远不写进被分析项目**。
- 唯一例外：用户在 Phase 0 显式选 "A · run codegraph init now" 时，`.codegraph/` 会
  写到目标项目根（这是 `codegraph init` 自己的行为，不是脚手架决定）。
- 用户可在 Phase 0 自由文本里覆盖路径（例如 "工作区放进项目根的 `.beautiful-codebase/`"），
  这时把目标路径作为 `<target-dir>` 传给脚本即可。

## 3 · 创建的工作区结构

脚手架跑完产出（对应 PRD Q7 的权威基线）：

```
<target>-analysis/
  package.json  vite.config.ts  tsconfig.json  tsconfig.node.json  index.html
  README.md                  # 工作区自带速查表（脚手架生成）
  .theme                     # 起步主题 id（切主题时用作 sanity check）

  discovery/                 # Phase 1 Discover 产出
    tools.json               # 占位 {} —— probe-tools.sh 写
    tier.json                # 占位 {} —— tier-select.sh 写
    inventory.json           # 占位 {} —— inventory.sh 写
    buckets/                 # buckets.sh 按 size tier 切分
    codebase-brief.md        # 占位 —— codebase-brief.sh 写
    business-evidence/       # business-evidence.sh 写 6 个文件
      comments.jsonl  tests.jsonl
      schema.md  configs.md  docs.md  commit-themes.md

  plan/plan.md               # Phase 2 占位（Brief/Outline/Theme/Assets 四段骨架）

  article/
    main.tsx                 # 入口：<ThemeProvider> + <Cover/> + <ArticleDoc/>
    Cover.tsx                # 报告封面外壳（--no-cover 时不生成）
    Article.tsx              # Assembler（主 Agent 拥有）
    sections/
      01-verdict.tsx         # 示例 Section 组件（首屏写它）
    raw-blocks/.gitkeep      # 大型 Raw 隔离目录
    assets/.gitkeep          # 配图素材

  review/                    # 评审产物（Phase 3 / 5 写）
  analysis-snapshot.json     # 占位 {} —— Phase 6 写工具版本 / SHA / 时间戳
```

> **一节一文件铁律**：每个 Section 都是独立 `sections/NN-*.tsx`；`Article.tsx` 只
> import 并排序，**不写 Section 正文**。这是 Phase 4 Mode B（多 Agent 并行）的前提。

## 4 · npm 依赖策略

- 脚手架把 `reacticle: "latest"` 写进 `package.json`，跑完 `npm install` 后**再次** 
  `npm install reacticle@latest` 强制刷新到当下最新发布版，并打印实际安装版本。
- `mermaid` 由模板的 `package.json` 显式声明（Section 02b / 03 / 05 全依赖它）。
- `katex` / `prismjs` 作为 `reacticle` 的传递依赖会被自动带下来。
- `vite-plugin-singlefile` 用于把 CSS + JS 全部 inline 到单页 HTML（见
  `html-output.md`）。
- `npm install` 失败（断网 / 代理）时脚手架会留下完整工作区文件、打印警告、退出 0；
  用户可手动 `cd <target> && npm install` 重试。

## 5 · 切主题

scaffold 后任何时刻切主题需要**改两处保持一致**：

1. `article/main.tsx` 的 `<ThemeProvider theme="...">`（运行时主题）。
2. `article/Article.tsx` 末尾 colophon `· <主题> theme`（印记主题名）。

可用 id：`terminal`（默认 · code-native）/ `tufte` / `press`。脚手架默认会把起步
主题 id 注入到这两个位置（通过 `__THEME__` 标记 + perl 替换）。

## 6 · 升级 reacticle / mermaid

```bash
cd <target>-analysis
npm install reacticle@latest
npm install mermaid@latest   # 偶尔需要，主题升级才要
npm run typecheck            # 看有没有 breaking
```

## 7 · 三阶段写（写给跑 scaffold 之后的人）

每个 Section 必走 Evidence → Business → Writing 三阶段（见
`references/section-build.md`）：

- `sections/NN-evidence.md` —— Step A Evidence SubAgent 写：verbatim 源码 +
  codegraph 查询结果。
- `sections/NN-business.md` —— Step A.5 Business Distillation SubAgent 写：
  业务陈述带 `[证据: file:line]` 引用，无证据走 "业务背景未知" 子段。
- `sections/NN-*.tsx` —— Step B Writing SubAgent 写：**只能** 读上面两个 md
  文件，**禁止** 访问 repo。这是反幻觉的最后防线。

## 8 · 不在脚手架里的事

- ❌ 脚手架**不**自动跑 `codegraph init`（中等风险写操作，必须用户在 Phase 0 显式
  同意 —— 见 PRD Q4）。
- ❌ 脚手架**不**填 `discovery/`、`plan/`、`article/sections/` —— 那是 Phase 1 / 2 /
  3 / 4 的工作。
- ❌ 脚手架**不**侵入被分析项目目录。
- ❌ 脚手架**不**复制 reacticle 源码到工作区，只从 npm 拉。
