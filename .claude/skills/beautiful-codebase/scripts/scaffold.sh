#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# scaffold.sh —— Create a beautiful-codebase analysis workspace.
#
# Usage:
#   bash scripts/scaffold.sh <target-dir> [--theme=<id>] [--no-cover]
#   bash scripts/scaffold.sh --list-themes
#   bash scripts/scaffold.sh --help
#
# Examples:
#   bash <skill>/scripts/scaffold.sh ./StarCodex-analysis --theme=terminal
#   bash <skill>/scripts/scaffold.sh ./brief-analysis --theme=press --no-cover
#   bash <skill>/scripts/scaffold.sh --list-themes
#
# Defaults:
#   • --theme=terminal (code-native dark surface; per Q8)
#   • cover ON (3:4 screen + own-page in PDF; --no-cover to disable)
#
# The workspace is created at the given target dir (typically a sibling of the
# analyzed project — never written into the analyzed project itself, see
# references/scaffold.md). Vite + React + TS + reacticle + mermaid; reacticle
# pulled from npm latest at scaffold time.
#
# After scaffold:
#   cd <target>
#   npm run dev      # preview
#   # Phase 3: replace article/Cover.tsx <CoverPlaceholder /> + sections/01-verdict.tsx
#   # Phase 4: write each Section through three-stage pipeline
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,28p' "$0"
}

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$SKILL_DIR/assets/scaffold-template"
PROFILES="$SKILL_DIR/theme-profiles/index.json"
DEFAULT_THEME="terminal"

list_themes() {
  echo "可用主题（来自 ${PROFILES}）:"
  echo
  grep -E '"id"|"label"|"mood"' "$PROFILES" | sed -E \
    -e 's/.*"id":[[:space:]]*"([^"]+)".*/  • \1/' \
    -e 's/.*"label":[[:space:]]*"([^"]+)".*/      \1/' \
    -e 's/.*"mood":[[:space:]]*"([^"]+)".*/      \1/'
  echo
  echo "用 --theme=<id> 选定一个。默认：${DEFAULT_THEME}（code-native）。"
}

theme_exists() {
  grep -Eq "\"id\"[[:space:]]*:[[:space:]]*\"$1\"" "$PROFILES"
}

# ── Parse args ──
TARGET=""
THEME="$DEFAULT_THEME"
COVER=1
SKIP_INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --help|-h)        usage; exit 0 ;;
    --list-themes)    list_themes; exit 0 ;;
    --theme=*)        THEME="${arg#--theme=}" ;;
    --no-cover)       COVER=0 ;;
    --cover)          COVER=1 ;;
    --skip-install)   SKIP_INSTALL=1 ;;
    --*)              echo "✗ 未知参数: $arg" >&2; exit 1 ;;
    *)                [[ -z "$TARGET" ]] && TARGET="$arg" ;;
  esac
done

TARGET="${TARGET:-my-codebase-analysis}"

# ── Validate theme ──
if ! theme_exists "$THEME"; then
  echo "✗ 未知主题 '$THEME'。可用主题：" >&2
  echo >&2
  list_themes >&2
  exit 1
fi

# ── Target directory check ──
if [[ -d "$TARGET" && -n "$(ls -A "$TARGET" 2>/dev/null || true)" ]]; then
  echo "✗ 目标目录 '$TARGET' 已存在且非空，已中止。" >&2
  exit 1
fi
if [[ "$SKIP_INSTALL" == "0" ]] && ! command -v npm >/dev/null; then
  echo "✗ 需要 npm，但在 PATH 里没找到。（用 --skip-install 跳过依赖安装做 dry-run）" >&2
  exit 1
fi

echo "▸ 在 $TARGET 创建 beautiful-codebase 工作区"
echo "▸ 主题：$THEME"
echo "▸ 封面：$([[ "$COVER" == "1" ]] && echo "开（屏幕 3:4 / PDF 独占首页，详见 references/cover.md）" || echo "关")"
echo "▸ reacticle：从 npm 安装最新发布版"

# ── Create workspace tree ──
mkdir -p "$TARGET"
# Engineering harness
cp "$TEMPLATE/package.json"        "$TARGET/package.json"
cp "$TEMPLATE/vite.config.ts"      "$TARGET/vite.config.ts"
cp "$TEMPLATE/tsconfig.json"       "$TARGET/tsconfig.json"
cp "$TEMPLATE/tsconfig.node.json"  "$TARGET/tsconfig.node.json"
cp "$TEMPLATE/index.html"          "$TARGET/index.html"

# Article source
mkdir -p "$TARGET/article/sections" "$TARGET/article/raw-blocks" "$TARGET/article/assets"
cp "$TEMPLATE/article/main.tsx"               "$TARGET/article/main.tsx"
cp "$TEMPLATE/article/Article.tsx"            "$TARGET/article/Article.tsx"
cp "$TEMPLATE/article/sections/01-verdict.tsx" "$TARGET/article/sections/01-verdict.tsx"
if [[ "$COVER" == "1" ]]; then
  cp "$TEMPLATE/article/Cover.tsx" "$TARGET/article/Cover.tsx"
fi

# Discovery / plan / review long-term-memory dirs (Q7 workspace structure)
mkdir -p \
  "$TARGET/discovery/buckets" \
  "$TARGET/discovery/business-evidence" \
  "$TARGET/plan" \
  "$TARGET/review"

# Discovery placeholders
echo '{}'  > "$TARGET/discovery/inventory.json"
echo '{}'  > "$TARGET/discovery/tier.json"
echo '{}'  > "$TARGET/discovery/tools.json"
touch      "$TARGET/discovery/buckets/.gitkeep"
cat > "$TARGET/discovery/codebase-brief.md" <<'EOF'
# Codebase Brief

(Phase 1 Discover writes this file. ~200 lines covering language stats / LOC /
top modules / commit cadence / contributors / key entry points.)
EOF

# Business evidence stubs (Phase 1 fills them; see
# references/business-evidence-collection.md)
: > "$TARGET/discovery/business-evidence/comments.jsonl"
: > "$TARGET/discovery/business-evidence/tests.jsonl"
cat > "$TARGET/discovery/business-evidence/schema.md"        <<'EOF'
# Schema Evidence

(Phase 1 Discover collects DB DDL / migrations into this file.)
EOF
cat > "$TARGET/discovery/business-evidence/configs.md"       <<'EOF'
# Configs Evidence

(Phase 1 Discover collects config files + enum constants here.)
EOF
cat > "$TARGET/discovery/business-evidence/docs.md"          <<'EOF'
# Docs Evidence

(Phase 1 Discover collects README / docs/ / wiki links here.)
EOF
cat > "$TARGET/discovery/business-evidence/commit-themes.md" <<'EOF'
# Commit Themes

(Phase 1 Discover clusters ~200 recent commit messages here.)
EOF

# Plan placeholder (Phase 2 fills it; references/plan-template.md is the
# authoritative template)
cat > "$TARGET/plan/plan.md" <<'EOF'
# Plan

> Phase 2 fills this from references/plan-template.md (Brief / Outline / Theme /
> Assets). Plan self-check (see references/review-checklist.md "Plan 自查段")
> happens inline in main agent before Checkpoint 1.

## Brief

(reader profile · retention · target language · width · TOC · asset mode ·
tool tier · size tier · git remote · …)

## Outline

(每节五行：编号 + 名称 + bucket 引用 + 业务-Job + 必须保留信息 +
Mermaid/Table/CodeBlock 取舍)

## Theme

(terminal / tufte / press · 一句理由)

## Assets

(默认 none — Mermaid 是主视觉)
EOF

touch "$TARGET/review/.gitkeep"
echo '{}' > "$TARGET/analysis-snapshot.json"

# Workspace README — quick orientation
cat > "$TARGET/README.md" <<EOF
# $(basename "$TARGET") · beautiful-codebase 工作区

| 路径 | 内容 |
|---|---|
| \`discovery/\` | Phase 1 产出：tools.json / tier.json / inventory.json / buckets/ / business-evidence/ / codebase-brief.md |
| \`plan/plan.md\` | Phase 2 产出：Brief / Outline / Theme / Assets |
| \`article/Article.tsx\` | Assembler（主 Agent 拥有），import + 排序各 Section |
| \`article/Cover.tsx\` | 报告封面（3:4 屏幕 / PDF 独占首页）$([[ "$COVER" == "1" ]] && echo "" || echo "（已关闭）") |
| \`article/sections/NN-*.tsx\` | 渲染 prose（Step B 输出）—— 一节一文件铁律 |
| \`article/sections/NN-evidence.md\` | Step A 输出：verbatim 源码 + codegraph 查询结果 |
| \`article/sections/NN-business.md\` | Step A.5 输出：业务陈述带 [证据: file:line] 引用 |
| \`article/raw-blocks/\` | 大型 Raw（SVG 复杂度热图、复杂封面）隔离到这里 |
| \`article/article.html\` | Phase 6 主交付物：自包含单页 HTML |
| \`review/first-spread-review.md\` | Phase 3 产物 |
| \`review/final-review.md\` | Phase 5 产物 |
| \`analysis-snapshot.json\` | 工具版本 / SHA / 时间戳 / inventory diff |

## 常用命令

\`\`\`bash
npm run dev        # 起 Vite 预览（Phase 3 / 4 边写边看）
npm run typecheck  # tsc --noEmit
npm run build      # tsc + 单页 HTML → dist/index.html（CSS+JS 内联）
npm run html       # 复用 build，再复制为交付物 article/article.html
\`\`\`

## 切主题

改两处保持一致：

1. \`article/main.tsx\` 的 \`<ThemeProvider theme="...">\`（运行时主题）。
2. \`article/Article.tsx\` 末尾 colophon \`· <主题> theme\`（印记主题名）。

可用主题：\`terminal\`（默认 · code-native）/ \`tufte\` / \`press\`（与
\`<skill>/theme-profiles/index.json\` 一致）。

## 三阶段写

每个 Section 走 Evidence → Business → Writing，详见 \`<skill>/references/section-build.md\`。
Step B Writing SubAgent 物理隔离 repo 访问，只读 \`NN-evidence.md\` + \`NN-business.md\`
两个文件 —— 这是反幻觉的最后防线。

起步主题：$THEME（见 \`.theme\`）
EOF

# Track empty dirs for git
touch "$TARGET/article/raw-blocks/.gitkeep" "$TARGET/article/assets/.gitkeep"

# ── Inject theme id (use perl to dodge sed escaping) ──
export RA_THEME="$THEME"
perl -pi -e 's/__THEME__/$ENV{RA_THEME}/g' "$TARGET/article/main.tsx"
perl -pi -e 's/__THEME__/$ENV{RA_THEME}/g' "$TARGET/article/Article.tsx"

# ── Cover toggle (mirror beautiful-article logic) ──
if [[ "$COVER" == "1" ]]; then
  perl -i -ne 'print unless /__COVER_(IMPORT|RENDER)_(BEGIN|END)__/' "$TARGET/article/main.tsx"
else
  perl -i -0pe 's{[^\n]*__COVER_IMPORT_BEGIN__.*?__COVER_IMPORT_END__[^\n]*\n}{}gs' "$TARGET/article/main.tsx"
  perl -i -0pe 's{[^\n]*__COVER_RENDER_BEGIN__.*?__COVER_RENDER_END__[^\n]*\n}{}gs' "$TARGET/article/main.tsx"
fi

# Marker file for theme + dry-run flag
echo "$THEME" > "$TARGET/.theme"

# ── Install deps (skippable for dry-run / CI) ──
if [[ "$SKIP_INSTALL" == "1" ]]; then
  echo "▸ --skip-install 已传入：跳过 npm install。请在 $TARGET 手动跑 npm install / typecheck。"
  echo
  echo "✓ 完成（dry-run）。工作区：$TARGET（主题 $THEME）"
  exit 0
fi

cd "$TARGET"
echo "▸ 安装依赖（含 reacticle 最新版，可能要等一会）..."
npm install >/dev/null 2>&1 || {
  echo "⚠ npm install 失败 —— 检查网络或代理。已经创建好工作区文件，可以手动重试。" >&2
  exit 0
}
npm install reacticle@latest >/dev/null 2>&1 || true

INSTALLED_REACTICLE="$(node -e "console.log(JSON.parse(require('fs').readFileSync('node_modules/reacticle/package.json','utf8')).version)" 2>/dev/null || echo '?')"
echo "▸ reacticle 版本：$INSTALLED_REACTICLE"

echo "▸ 跑一次 typecheck 确认接线 OK ..."
if npx tsc --noEmit; then
  echo "✓ typecheck 通过"
else
  echo "⚠ typecheck 有问题（见上），dev / build 仍可能正常 —— 请人工确认。" >&2
fi

cat <<EOF

✓ 完成。工作区：$TARGET（主题 $THEME，见 .theme；reacticle $INSTALLED_REACTICLE）

下一步：
  1. cd $TARGET
  2. 继续 Phase 1 Discover：跑 \`<skill>/scripts/discover/*.sh\` 系列填 discovery/。
  3. Phase 2 Plan：写 plan/plan.md（按 references/plan-template.md）。
  4. Phase 3 First Spread：替换 article/Cover.tsx <CoverPlaceholder /> 与
     article/sections/01-verdict.tsx —— 走完整三阶段（Evidence → Business → Writing）。
  5. Phase 4: subsequent sections, mode A 单 Agent / B 多 Agent 并行（Checkpoint 2 选定）。

构建交付（Phase 6）：
  • npm run build     # 类型检查 + 单页 HTML → dist/index.html（CSS+JS 内联）
  • npm run html      # 复用 build，再复制为交付物 article/article.html
  • bash <skill>/scripts/html-to-pdf.sh   # 可选 PDF（Checkpoint 3 选定后）

切主题：改 article/main.tsx 的 <ThemeProvider theme="..."> 一字（terminal / tufte / press）。
升级组件库：npm install reacticle@latest

写作必读（路径在 Skill 仓库内）：
  • $SKILL_DIR/references/section-build.md
  • $SKILL_DIR/references/component-policy.md
  • $SKILL_DIR/references/raw-policy.md
  • $SKILL_DIR/theme-profiles/$THEME.md
EOF
