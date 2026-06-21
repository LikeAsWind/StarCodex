<p align="center">
<picture>
<source srcset="./assets/banner.png" media="(prefers-color-scheme: dark)">
<source srcset="./assets/banner.png" media="(prefers-color-scheme: light)">
<img src="./assets/banner.png" alt="StarCodex" width="100%" style="image-rendering: -webkit-optimize-contrast; image-rendering: crisp-edges;">
</picture>
</p>

<p align="center">
<strong>StarCodex — Gather stellar code, weave links into graphs, forge projects into engineering tomes.</strong><br/>
<sub>An AI coding skill that reads your project, links its code into a navigable knowledge graph, and distills the result into a queryable engineering codex — so every contributor and every coding agent opens the same map.</sub>
</p>

<p align="center">
<a href="./README.md">中文</a>
</p>

<p align="center">
<a href="https://github.com/LikeAsWind/StarCodex/stargazers"><img src="https://img.shields.io/github/stars/LikeAsWind/StarCodex?style=flat-square&color=eab308" alt="stars" /></a>
<a href="https://github.com/LikeAsWind/StarCodex/issues"><img src="https://img.shields.io/github/issues/LikeAsWind/StarCodex?style=flat-square&color=e67e22" alt="open issues" /></a>
<a href="https://github.com/LikeAsWind/StarCodex/pulls"><img src="https://img.shields.io/github/issues-pr/LikeAsWind/StarCodex?style=flat-square&color=9b59b6" alt="open PRs" /></a>
<a href="./LICENSE"><img src="https://img.shields.io/github/license/LikeAsWind/StarCodex?style=flat-square&color=10b981" alt="license" /></a>
</p>

---

## What is this

StarCodex is a **collection of AI coding skills**. Each skill is a declarative workflow that lets an AI coding assistant (Claude Code / Cursor / Codex / Gemini / opencode, etc.) get one specific kind of task right end to end — not a prompt template, but the full "understand, plan, execute, self-check, deliver" pipeline captured as a reusable process.

Important framing: **StarCodex is not an app and not a tool you run directly**. You point an AI client at a skill, and the AI drives the workflow described inside; the skill itself is just markdown plus scripts plus templates.

v0.1.0 ships one skill in this repo. Future releases will add more.

## Available skills

### `beautiful-codebase` · Single-file HTML codebase report

Turn any code project (language-agnostic: Java / Python / Go / TypeScript / Rust …) into a **self-contained, offline-openable, shareable** single-file HTML codebase report.

Key features:

- **Three-tier tool fallback**: codegraph (preferred) → rg → grep, auto-selected at probe time so the skill runs across environments.
- **Three-stage write (Evidence → Business → Writing)**: the writing sub-agent has no source-code access by construction; it only reads the upstream `evidence.md` / `business.md` artifacts. Hallucination is cut at the wiring level, not by self-discipline.
- **Three reader profiles**: `architecture-review` (senior eng / 30-minute structural call) / `onboarding` (read today, ship the first issue tomorrow) / `archaeology` (handover / archival / find a decision six months later). Profile drives mandatory sections, information-retention ratio, and theme pairing.
- **Mermaid-led visualization**: architecture, call chains, business-domain diagrams render in mermaid; SVG is reserved for covers and Section 07 complexity heatmaps.
- **Business-evidence harvesting**: comments, tests, DB schema, configs, and commit history are scanned to reconstruct business context. Confident-tone claims without an evidence pointer are rejected.
- **Three hard checkpoints**: Plan / First Spread / Final. Each must stop and ask the user — the agent is not allowed to silently pick on your behalf.
- **Optional PDF export**: headless-browser print, zero npm dependencies.

→ Full usage walk-through: [docs/usage-guide.md](./docs/usage-guide.md) (Chinese)
→ Skill source: [skills/beautiful-codebase/](./skills/beautiful-codebase/)
→ Skill entry: [skills/beautiful-codebase/SKILL.md](./skills/beautiful-codebase/SKILL.md)

## Quick start

> Prerequisites: you are inside an AI coding client that supports skills (Claude Code / Cursor / Codex / Gemini / opencode); the host machine has `git` and any one of `codegraph` / `rg` / `grep` (three-tier fallback); Node.js 18+ for the report workspace's Vite build.

1. **Clone this repo somewhere your AI client can read** (same machine is fine):

   ```bash
   git clone https://github.com/LikeAsWind/StarCodex.git
   ```

2. **Make the skill discoverable to your AI client**:

   - **Claude Code**: copy (or symlink) `skills/beautiful-codebase/` into `~/.claude/skills/` and restart the session; or just tell the assistant "read `<repo>/skills/beautiful-codebase/SKILL.md` and follow that workflow".
   - **Cursor / Codex / Gemini / opencode**: point the assistant at `SKILL.md`. Its frontmatter declares the trigger phrases, and the body is the full phase + checkpoint protocol.

3. **Trigger**: any of these phrasings drops the assistant into the `beautiful-codebase` workflow:

   - "analyze this codebase"
   - "build a beautiful codebase report"
   - "generate an architecture review of this repo"
   - "make a single-file HTML report for this project"
   - "I'm handing off this project, write me an archive"
   - Chinese variants: "分析这个代码库" / "给这个项目做一份分析报告" / "给我一个项目架构总览" / "帮我写一份代码归档" / "我要交接这个项目"

4. The assistant then walks Phase 0 → 6. **Three hard checkpoints** stop and require your independent confirmation (reader profile / theme / layout width / asset mode / cover / first-spread acceptance / build mode / delivery decision). The agent will not silently pick for you.

→ Full usage manual: [docs/usage-guide.md](./docs/usage-guide.md) (Chinese)

## Repo layout

```
StarCodex/
├── skills/                  # collection of AI coding skills (v0.1.0: 1)
│   └── beautiful-codebase/
│       ├── SKILL.md         # skill entry (frontmatter declares trigger phrases)
│       ├── manifest.json    # metadata + compat list
│       ├── references/      # on-demand sub-docs, one per phase concern
│       ├── prompts/         # SubAgent prompt templates (sent verbatim)
│       ├── scripts/         # tool chain (probe / scaffold / discover / audit / delivery)
│       ├── theme-profiles/  # authoring descriptions for the three themes
│       └── assets/          # scaffold templates and static resources
├── docs/
│   └── usage-guide.md       # full usage manual (linked from README)
├── assets/
│   └── banner.png
├── README.md / README_EN.md
├── LICENSE                  # MIT
├── AGENTS.md / CLAUDE.md    # in-repo conventions for AI clients
└── v0.2-followups.md        # known follow-ups distilled from the v0.1.0 dogfood
```

## Development & contributing

The repo is currently solo-maintained. Issues and improvement notes are welcome.

Conventions for adding a new skill:

- Each skill ships its own `SKILL.md` (frontmatter with trigger description) + `manifest.json` (with a `compat` client list) + `references/` (per-phase sub-docs) + `scripts/` + `prompts/` (if it dispatches SubAgents).
- A skill must be self-contained at runtime — no skill depends on another skill's runtime, though a skill may cite another's reference docs for cross-comparison.
- Use `skills/beautiful-codebase/` as the skeleton reference.

The `v0.1.0 → v0.2` follow-up list (16 findings from the dogfood: reacticle API drift, audit-script regex defects, Windows PDF path handling, terminal-theme block, etc.) lives in [v0.2-followups.md](./v0.2-followups.md).

## Compatible clients

`beautiful-codebase`'s `manifest.json` declares compatibility with: **Claude Code** · **Claude.ai** · **Cursor** · **Codex CLI** · **Gemini CLI** · **opencode**.

Only Claude Code has been driven end-to-end so far (StarCodex's own v0.1.0 dogfood). The other clients are theoretically supported; field reports from the community are welcome.

## License

[MIT](./LICENSE)
