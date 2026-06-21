#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# delivery.sh —— Phase 6 Delivery orchestrator for beautiful-codebase.
#
# Runs the final delivery sequence against a beautiful-codebase workspace:
#   1. probe the workspace shape
#   2. (default) re-run the four Phase 5 audits as a final gate
#      (--skip-audits disables this; freshness is informational only)
#   3. `npm run build` inside the workspace; ensure article/article.html is a
#      true single-file (no external <script src=> or <link rel=stylesheet>)
#   4. write analysis-snapshot.json at the workspace root
#   5. (optional --pdf) call scripts/html-to-pdf.sh against the workspace
#   6. emit a delivery report (success or first failure)
#
# Usage:
#   bash <skill>/scripts/delivery.sh [--workspace <path>] [--pdf] [--skip-audits]
#   bash <skill>/scripts/delivery.sh --help
#
# Defaults:
#   --workspace defaults to $PWD
#   --pdf       off (PDF is opt-in per Checkpoint 3)
#   --skip-audits off (re-run coverage + density as a final gate by default)
#
# Exit codes:
#   0  delivery succeeded (HTML built, snapshot written, audits passed)
#   1  workspace probe failed (not a beautiful-codebase workspace)
#   2  a blocking audit failed (coverage missing entries, density violation)
#   3  Vite build failed
#   4  build succeeded but article/article.html is not a single-file
#   5  PDF export failed (HTML still on disk)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,33p' "$0"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_DIR="$SCRIPT_DIR/audit"
PDF_SCRIPT="$SCRIPT_DIR/html-to-pdf.sh"

WORKSPACE=""
PDF=0
SKIP_AUDITS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)        usage; exit 0 ;;
    --workspace)      shift; WORKSPACE="${1:-}" ;;
    --workspace=*)    WORKSPACE="${1#--workspace=}" ;;
    --pdf)            PDF=1 ;;
    --skip-audits)    SKIP_AUDITS=1 ;;
    *) echo "✗ 未知参数: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

WORKSPACE="${WORKSPACE:-$PWD}"
if [[ ! -d "$WORKSPACE" ]]; then
  echo "✗ workspace 不存在: $WORKSPACE" >&2
  exit 1
fi
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

START_EPOCH="$(date +%s)"

# ── Helpers ─────────────────────────────────────────────────
js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Extract the first matching string value of a top-level key from a JSON file.
# Best-effort sed; falls back to empty when not found.
json_get_string() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || { printf ''; return 0; }
  tr -d '\n' < "$file" 2>/dev/null \
    | sed -nE "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\\1/p" \
    | head -n1
}

# Extract the first matching numeric value of a top-level key from a JSON file.
json_get_number() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || { printf ''; return 0; }
  tr -d '\n' < "$file" 2>/dev/null \
    | sed -nE "s/.*\"${key}\"[[:space:]]*:[[:space:]]*([0-9]+(\\.[0-9]+)?).*/\\1/p" \
    | head -n1
}

# Pluck a simple `field: value` line from plan/plan.md (Brief段). Best-effort,
# returns empty when not present.
plan_get_field() {
  local plan="$1" field="$2"
  [[ -f "$plan" ]] || { printf ''; return 0; }
  # Match lines like "- 主题: terminal" or "Theme: terminal" or "- theme: terminal".
  grep -iE "^[[:space:]-]*${field}[[:space:]]*[:：]" "$plan" 2>/dev/null \
    | head -n1 \
    | sed -E "s/^[[:space:]-]*${field}[[:space:]]*[:：][[:space:]]*//I" \
    | sed -E 's/[[:space:]]+$//' \
    || true
}

# ── Step 1 · Probe workspace ────────────────────────────────
echo "▸ Step 1 · probe workspace at $WORKSPACE"

INVENTORY="$WORKSPACE/discovery/inventory.json"
TIER_JSON="$WORKSPACE/discovery/tier.json"
PLAN="$WORKSPACE/plan/plan.md"
ARTICLE_TSX="$WORKSPACE/article/Article.tsx"
PACKAGE_JSON="$WORKSPACE/package.json"

probe_missing=()
[[ -f "$INVENTORY"   ]] || probe_missing+=("discovery/inventory.json")
[[ -f "$PLAN"        ]] || probe_missing+=("plan/plan.md")
[[ -f "$ARTICLE_TSX" ]] || probe_missing+=("article/Article.tsx")
[[ -f "$PACKAGE_JSON" ]] || probe_missing+=("package.json")

if [[ ${#probe_missing[@]} -gt 0 ]]; then
  echo "✗ workspace 不是 beautiful-codebase 形态，缺少：" >&2
  for m in "${probe_missing[@]}"; do echo "    - $m" >&2; done
  echo "  请先跑 scripts/scaffold.sh 与 Phase 1 Discover。" >&2
  exit 1
fi
echo "  ✓ inventory.json / plan.md / Article.tsx / package.json 齐备"

# ── Step 2 · Re-run final-gate audits ───────────────────────
if [[ "$SKIP_AUDITS" == "1" ]]; then
  echo "▸ Step 2 · 跳过审计（--skip-audits）"
  AUDIT_NOTE="skipped (--skip-audits)"
else
  echo "▸ Step 2 · 再跑一遍 Phase 5 审计作为最后一道闸"
  AUDIT_NOTE="re-ran coverage + density + freshness"

  # Coverage — blocking.
  if [[ -f "$AUDIT_DIR/coverage.sh" ]]; then
    if bash "$AUDIT_DIR/coverage.sh" --workspace "$WORKSPACE"; then
      echo "  ✓ coverage 通过"
    else
      cov_rc=$?
      echo "✗ coverage 失败 (exit=$cov_rc)，参见 $WORKSPACE/review/coverage.json" >&2
      exit 2
    fi
  else
    echo "  ⚠ audit/coverage.sh 不存在，跳过 coverage 闸" >&2
  fi

  # Density — blocking (--all → fails if any section fails).
  if [[ -f "$AUDIT_DIR/density.sh" ]]; then
    if bash "$AUDIT_DIR/density.sh" --workspace "$WORKSPACE" --all; then
      echo "  ✓ density 通过"
    else
      den_rc=$?
      echo "✗ density 失败 (exit=$den_rc)，参见 $WORKSPACE/review/density.json" >&2
      exit 2
    fi
  else
    echo "  ⚠ audit/density.sh 不存在，跳过 density 闸" >&2
  fi

  # Freshness — informational, never aborts.
  if [[ -f "$AUDIT_DIR/freshness.sh" ]]; then
    if bash "$AUDIT_DIR/freshness.sh" --workspace "$WORKSPACE"; then
      echo "  ✓ freshness 已记录（informational only）"
    else
      echo "  ⚠ freshness 退出非零，但 informational，不阻断交付" >&2
    fi
  else
    echo "  ⚠ audit/freshness.sh 不存在，跳过 freshness" >&2
  fi
fi

# ── Step 3 · Vite build + single-file check ─────────────────
echo "▸ Step 3 · npm run build （Vite 单文件构建）"

if ! command -v npm >/dev/null 2>&1; then
  echo "✗ 找不到 npm，无法运行 build。请装 Node.js / npm 后重试。" >&2
  exit 3
fi

HTML_OUT="$WORKSPACE/article/article.html"
if ! ( cd "$WORKSPACE" && npm run build ); then
  echo "✗ npm run build 失败" >&2
  exit 3
fi

# scaffold-template 的 build script 只产出 dist/index.html；这里复用 html script
# 的语义，把它复制到 article/article.html。若工作区有自定义 html script 优先它。
if grep -q '"html"[[:space:]]*:' "$PACKAGE_JSON" 2>/dev/null; then
  if ! ( cd "$WORKSPACE" && npm run html ); then
    echo "✗ npm run html 失败" >&2
    exit 3
  fi
else
  DIST_HTML="$WORKSPACE/dist/index.html"
  if [[ ! -f "$DIST_HTML" ]]; then
    echo "✗ build 后找不到 dist/index.html，无法生成 article.html" >&2
    exit 3
  fi
  mkdir -p "$WORKSPACE/article"
  cp "$DIST_HTML" "$HTML_OUT"
fi

if [[ ! -f "$HTML_OUT" ]]; then
  echo "✗ build 完成但 article/article.html 不存在" >&2
  exit 3
fi

# Single-file invariant: no external <script src="..."> nor <link rel="stylesheet" href="...">.
# vite-plugin-singlefile inlines everything; if any remain we abort delivery.
EXT_SCRIPTS="$(grep -cE '<script[^>]*\bsrc=' "$HTML_OUT" 2>/dev/null || true)"
EXT_SCRIPTS="${EXT_SCRIPTS:-0}"
EXT_STYLES="$(grep -cE '<link[^>]*rel="?stylesheet"?[^>]*\bhref=' "$HTML_OUT" 2>/dev/null || true)"
EXT_STYLES="${EXT_STYLES:-0}"
if [[ "$EXT_SCRIPTS" -gt 0 || "$EXT_STYLES" -gt 0 ]]; then
  echo "✗ article/article.html 不是单文件：" >&2
  echo "    外部 <script src=> 数: $EXT_SCRIPTS" >&2
  echo "    外部 <link rel=stylesheet href=> 数: $EXT_STYLES" >&2
  echo "  检查 vite.config.ts 是否启用了 vite-plugin-singlefile。" >&2
  exit 4
fi

HTML_SIZE_BYTES=0
if [[ -f "$HTML_OUT" ]]; then
  HTML_SIZE_BYTES="$(wc -c < "$HTML_OUT" 2>/dev/null | tr -d ' ' || echo 0)"
fi
HTML_SIZE_HUMAN="$(du -h "$HTML_OUT" 2>/dev/null | cut -f1 || echo '?')"
echo "  ✓ article/article.html ${HTML_SIZE_HUMAN} · 单文件 invariant 通过 (scripts=$EXT_SCRIPTS, styles=$EXT_STYLES)"

# ── Step 4 · analysis-snapshot.json ─────────────────────────
echo "▸ Step 4 · 写 analysis-snapshot.json"

# Tools tier
TIER_LABEL="$(json_get_string "$TIER_JSON" tier)"
[[ -z "$TIER_LABEL" ]] && TIER_LABEL="unknown"
CG_VERSION="$(json_get_string "$TIER_JSON" version)"
RG_VERSION=""
GREP_VERSION=""
# probe-tools.sh writes per-tool sub-objects; pluck them best-effort.
if [[ -f "$TIER_JSON" ]]; then
  CG_VERSION="$(tr -d '\n' < "$TIER_JSON" \
    | sed -nE 's/.*"codegraph"[[:space:]]*:[[:space:]]*\{[^}]*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
  RG_VERSION="$(tr -d '\n' < "$TIER_JSON" \
    | sed -nE 's/.*"rg"[[:space:]]*:[[:space:]]*\{[^}]*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
  GREP_VERSION="$(tr -d '\n' < "$TIER_JSON" \
    | sed -nE 's/.*"grep"[[:space:]]*:[[:space:]]*\{[^}]*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
fi
TARGET_PATH="$(json_get_string "$TIER_JSON" target)"

# codegraph SHA, if applicable
CODEGRAPH_SHA=""
if [[ "$TIER_LABEL" == "codegraph-indexed" && -n "$TARGET_PATH" && -d "$TARGET_PATH/.codegraph" ]]; then
  if command -v git >/dev/null 2>&1; then
    CODEGRAPH_SHA="$(git -C "$TARGET_PATH/.codegraph" rev-parse HEAD 2>/dev/null || true)"
  fi
fi

# Snapshot timestamps
DISCOVER_SNAPSHOT="$(json_get_string "$INVENTORY" snapshot)"
[[ -z "$DISCOVER_SNAPSHOT" ]] && DISCOVER_SNAPSHOT="$(json_get_string "$INVENTORY" generatedAt)"
DELIVERY_TIME="$(date -u +%FT%TZ)"

# Coverage & freshness summaries (if audits ran)
COVERAGE_JSON="$WORKSPACE/review/coverage.json"
COVERAGE_PCT="$(json_get_number "$COVERAGE_JSON" coveragePct)"
[[ -z "$COVERAGE_PCT" ]] && COVERAGE_PCT="null"
COVERAGE_VERDICT="$(json_get_string "$COVERAGE_JSON" verdict)"
[[ -z "$COVERAGE_VERDICT" ]] && COVERAGE_VERDICT="not-run"

FRESHNESS_JSON="$WORKSPACE/review/freshness.json"
FRESHNESS_VERDICT="$(json_get_string "$FRESHNESS_JSON" verdict)"
[[ -z "$FRESHNESS_VERDICT" ]] && FRESHNESS_VERDICT="not-run"
ADDED_COUNT="$(json_get_number "$FRESHNESS_JSON" addedCount)"
REMOVED_COUNT="$(json_get_number "$FRESHNESS_JSON" removedCount)"
MODIFIED_COUNT="$(json_get_number "$FRESHNESS_JSON" modifiedCount)"
[[ -z "$ADDED_COUNT" ]] && ADDED_COUNT="0"
[[ -z "$REMOVED_COUNT" ]] && REMOVED_COUNT="0"
[[ -z "$MODIFIED_COUNT" ]] && MODIFIED_COUNT="0"
FRESHNESS_SUMMARY_PATH=""
if [[ -f "$WORKSPACE/review/freshness-summary.md" ]]; then
  FRESHNESS_SUMMARY_PATH="review/freshness-summary.md"
fi

# Size tier + inventory size
SIZE_TIER="$(json_get_string "$WORKSPACE/discovery/size-tier.json" tier)"
[[ -z "$SIZE_TIER" ]] && SIZE_TIER="$(json_get_string "$INVENTORY" sizeTier)"
ANALYZED_FILES="$(json_get_number "$INVENTORY" analyzedFiles)"
[[ -z "$ANALYZED_FILES" ]] && ANALYZED_FILES="null"

# Plan-derived metadata (best-effort: scan plan/plan.md for canonical fields).
PROFILE="$(plan_get_field "$PLAN" 'reader profile')"
[[ -z "$PROFILE" ]] && PROFILE="$(plan_get_field "$PLAN" 'profile')"
[[ -z "$PROFILE" ]] && PROFILE="$(plan_get_field "$PLAN" '读者画像')"
THEME="$(plan_get_field "$PLAN" 'theme')"
[[ -z "$THEME" ]] && THEME="$(plan_get_field "$PLAN" '主题')"
WIDTH="$(plan_get_field "$PLAN" 'width')"
[[ -z "$WIDTH" ]] && WIDTH="$(plan_get_field "$PLAN" '版式宽度')"
[[ -z "$WIDTH" ]] && WIDTH="$(plan_get_field "$PLAN" '宽度')"
ASSET_MODE="$(plan_get_field "$PLAN" 'asset mode')"
[[ -z "$ASSET_MODE" ]] && ASSET_MODE="$(plan_get_field "$PLAN" 'assets')"
[[ -z "$ASSET_MODE" ]] && ASSET_MODE="$(plan_get_field "$PLAN" '配图模式')"

# Fallback marker: when we couldn't parse, point readers at the plan.
plan_fallback() {
  local v="$1"
  if [[ -z "$v" ]]; then printf 'see plan/plan.md'
  else printf '%s' "$v"
  fi
}
PROFILE="$(plan_fallback "$PROFILE")"
THEME="$(plan_fallback "$THEME")"
WIDTH="$(plan_fallback "$WIDTH")"
ASSET_MODE="$(plan_fallback "$ASSET_MODE")"

# Sections rendered (file names without extension + leading number prefix)
SECTIONS_JSON="["
first=1
for tsx in "$WORKSPACE/article/sections/"*.tsx; do
  [[ -f "$tsx" ]] || continue
  base="$(basename "$tsx" .tsx)"
  if [[ $first -eq 1 ]]; then first=0; else SECTIONS_JSON="$SECTIONS_JSON,"; fi
  SECTIONS_JSON="$SECTIONS_JSON\"$(js_escape "$base")\""
done
SECTIONS_JSON="$SECTIONS_JSON]"

SNAPSHOT_OUT="$WORKSPACE/analysis-snapshot.json"
cat > "$SNAPSHOT_OUT" <<EOF
{
  "skill": "beautiful-codebase",
  "skillVersion": "0.1.0",
  "deliveredAt": "$DELIVERY_TIME",
  "discoverSnapshot": "$(js_escape "$DISCOVER_SNAPSHOT")",
  "workspace": "$(js_escape "$WORKSPACE")",
  "target": "$(js_escape "$TARGET_PATH")",
  "tools": {
    "tier": "$(js_escape "$TIER_LABEL")",
    "codegraph": "$(js_escape "$CG_VERSION")",
    "codegraphSha": "$(js_escape "$CODEGRAPH_SHA")",
    "rg": "$(js_escape "$RG_VERSION")",
    "grep": "$(js_escape "$GREP_VERSION")"
  },
  "sizeTier": "$(js_escape "$SIZE_TIER")",
  "analyzedFiles": $ANALYZED_FILES,
  "readerProfile": "$(js_escape "$PROFILE")",
  "theme": "$(js_escape "$THEME")",
  "width": "$(js_escape "$WIDTH")",
  "assetMode": "$(js_escape "$ASSET_MODE")",
  "sectionsRendered": $SECTIONS_JSON,
  "coverage": {
    "verdict": "$(js_escape "$COVERAGE_VERDICT")",
    "coveragePct": $COVERAGE_PCT
  },
  "freshness": {
    "verdict": "$(js_escape "$FRESHNESS_VERDICT")",
    "addedCount":    $ADDED_COUNT,
    "removedCount":  $REMOVED_COUNT,
    "modifiedCount": $MODIFIED_COUNT,
    "summaryFile":   "$(js_escape "$FRESHNESS_SUMMARY_PATH")"
  },
  "audits": "$(js_escape "$AUDIT_NOTE")",
  "html": {
    "path": "article/article.html",
    "sizeBytes": $HTML_SIZE_BYTES,
    "externalScripts": $EXT_SCRIPTS,
    "externalStylesheets": $EXT_STYLES
  }
}
EOF

echo "  ✓ $SNAPSHOT_OUT"

# ── Step 5 · Optional PDF export ────────────────────────────
PDF_OUT_REL=""
if [[ "$PDF" == "1" ]]; then
  echo "▸ Step 5 · PDF 导出 (html-to-pdf.sh)"
  if [[ ! -x "$PDF_SCRIPT" && ! -f "$PDF_SCRIPT" ]]; then
    echo "✗ html-to-pdf.sh 不存在: $PDF_SCRIPT" >&2
    exit 5
  fi
  if ( cd "$WORKSPACE" && bash "$PDF_SCRIPT" "article/article.html" "article/article.pdf" ); then
    PDF_OUT_REL="article/article.pdf"
    echo "  ✓ article/article.pdf"
  else
    echo "✗ PDF 导出失败；HTML 仍然在 $HTML_OUT" >&2
    exit 5
  fi
else
  echo "▸ Step 5 · 跳过 PDF（未传 --pdf）"
fi

# ── Step 6 · Final report ───────────────────────────────────
END_EPOCH="$(date +%s)"
ELAPSED=$((END_EPOCH - START_EPOCH))

echo
echo "──────────────────────────────────────────────"
echo "✓ Delivery 成功"
echo "──────────────────────────────────────────────"
echo "  workspace          : $WORKSPACE"
echo "  article.html       : article/article.html ($HTML_SIZE_HUMAN)"
[[ -n "$PDF_OUT_REL" ]] \
  && echo "  article.pdf        : $PDF_OUT_REL" \
  || echo "  article.pdf        : (not exported · pass --pdf to enable)"
echo "  snapshot           : analysis-snapshot.json"
echo "  audits             : $AUDIT_NOTE"
echo "  coverage           : $COVERAGE_VERDICT (${COVERAGE_PCT}%)"
echo "  freshness          : $FRESHNESS_VERDICT (+$ADDED_COUNT ~$MODIFIED_COUNT -$REMOVED_COUNT)"
echo "  elapsed            : ${ELAPSED}s"
echo

exit 0
