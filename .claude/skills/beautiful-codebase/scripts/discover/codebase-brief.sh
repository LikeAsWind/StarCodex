#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# codebase-brief.sh —— Synthesize discovery/codebase-brief.md (~200 lines).
#
# Reads:
#   <workspace>/discovery/tier.json
#   <workspace>/discovery/inventory.json
#   <workspace>/discovery/size-tier.json
#   <workspace>/discovery/buckets/_summary.json
#   <workspace>/discovery/business-evidence/*
#
# Writes:
#   <workspace>/discovery/codebase-brief.md
#
# This is Phase 2 Plan's #1 reading. Goal: a single Markdown doc that lets the
# main agent author plan/plan.md without ever opening source code.
#
# Usage:
#   bash codebase-brief.sh --workspace <path>
#   bash codebase-brief.sh --help
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,21p' "$0"
}

WORKSPACE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)     usage; exit 0 ;;
    --workspace)   shift; WORKSPACE="${1:-}" ;;
    --workspace=*) WORKSPACE="${1#--workspace=}" ;;
    *) echo "✗ unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$WORKSPACE" ]]; then
  echo "✗ --workspace <path> is required" >&2
  exit 1
fi

D="$WORKSPACE/discovery"
INV="$D/inventory.json"
TIER_JSON="$D/tier.json"
SIZE_JSON="$D/size-tier.json"
SUM_JSON="$D/buckets/_summary.json"
BE="$D/business-evidence"

for f in "$INV" "$TIER_JSON" "$SIZE_JSON" "$SUM_JSON"; do
  [[ -f "$f" ]] || { echo "✗ missing $f — run inventory.sh + buckets.sh + tier-select.sh first" >&2; exit 1; }
done

# ── Tiny JSON readers ──────────────────────────────────────
read_str()  { tr -d '\n' < "$2" | sed -nE 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1; }
read_num()  { tr -d '\n' < "$2" | sed -nE 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' | head -n1; }

TARGET="$(read_str target "$TIER_JSON")"
TIER="$(read_str tier "$TIER_JSON")"
SNAPSHOT="$(read_str snapshot "$TIER_JSON")"

SIZE_TIER="$(read_str sizeTier "$SIZE_JSON")"
ANALYZED="$(read_num analyzedFiles "$SIZE_JSON")"
BUCKET_COUNT="$(read_num bucketCount "$SIZE_JSON")"
BUCKET_STRATEGY="$(read_str bucketStrategy "$SIZE_JSON")"
EVIDENCE_STRATEGY="$(read_str evidenceStrategy "$SIZE_JSON")"

TOTAL_LOC="$(read_num totalLoc "$INV")"
TOTAL_FILES="$(read_num totalFiles "$INV")"
EXCLUDED_FILES="$(read_num excludedFiles "$INV")"

# Tool versions for the header
CG_VERSION="$(tr -d '\n' < "$TIER_JSON" | sed -nE 's/.*"codegraph"[^}]*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
RG_VERSION="$(tr -d '\n' < "$TIER_JSON" | sed -nE 's/.*"rg"[^}]*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
GREP_VERSION="$(tr -d '\n' < "$TIER_JSON" | sed -nE 's/.*"grep"[^}]*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"

PROJECT_NAME="$(basename "$TARGET")"

# ── Language mix table from inventory.byLanguage ───────────
# Extract the {"go":320, "python":180, ...} block
LANG_BLOCK="$(tr -d '\n' < "$INV" | sed -nE 's/.*"byLanguage"[[:space:]]*:[[:space:]]*\{([^}]*)\}.*/\1/p' | head -n1)"

# Parse into "lang count" pairs, sort by count desc
LANG_TABLE="$(printf '%s' "$LANG_BLOCK" \
  | tr ',' '\n' \
  | sed -nE 's/^[[:space:]]*"([^"]+)"[[:space:]]*:[[:space:]]*([0-9]+).*/\2 \1/p' \
  | sort -rn -k1,1)"

# ── Reader profile auto-recommendation ─────────────────────
REASON=""
case "$SIZE_TIER" in
  ">10k")
    PROFILE_REC="archaeology"
    PROFILE_RETENTION="~70%"
    PROFILE_NOTE="(>10k files forces 70% cap; Coverage Annex mandatory; no '100% coverage' claim allowed)"
    REASON="forced by size tier >10k"
    ;;
  "1k-10k")
    PROFILE_REC="architecture-review"
    PROFILE_RETENTION="~80%"
    PROFILE_NOTE=""
    REASON="medium-large project; senior reviewers want a 30-min judgment"
    ;;
  "100-1k")
    PROFILE_REC="architecture-review"
    PROFILE_RETENTION="~80%"
    PROFILE_NOTE=""
    REASON="medium project; architecture review fits well"
    ;;
  "<100")
    PROFILE_REC="onboarding"
    PROFILE_RETENTION="~65%"
    PROFILE_NOTE=""
    REASON="small project; onboarding profile reads end-to-end comfortably"
    ;;
  *)
    PROFILE_REC="architecture-review"
    PROFILE_RETENTION="~80%"
    PROFILE_NOTE=""
    REASON="default"
    ;;
esac

COVERAGE_ALLOWED="yes"
if [[ "$SIZE_TIER" == ">10k" ]]; then COVERAGE_ALLOWED="no (>10k honesty rule)"; fi

# ── Optional sections suggestion per profile ───────────────
case "$PROFILE_REC" in
  architecture-review) OPT_SECTIONS="06 Tech Stack Audit · 07 Code Health Heatmap · 09 Decisions That Matter · 10 Open Questions" ;;
  onboarding)          OPT_SECTIONS="03 Architecture Map · 06 Tech Stack Audit · 10 Open Questions" ;;
  archaeology)         OPT_SECTIONS="05 Exposed Entry Points · 06 Tech Stack Audit · 07 Code Health Heatmap · 10 Open Questions" ;;
esac

# ── Entry-point preview via cheap regex scan ───────────────
# We don't load lib/query.sh — Phase 1 already wrote evidence files. For the
# brief, a one-shot per-role count is enough to give Plan a feel.
declare -i CNT_CTRL=0 CNT_SCHED=0 CNT_MSG=0 CNT_INIT=0 CNT_CLI=0
declare -i CNT_EVT=0 CNT_MID=0 CNT_HOOK=0 CNT_WS=0

count_pattern() {
  # Args: pattern; uses rg if available, else grep -r. Always returns 0.
  local n
  if command -v rg >/dev/null 2>&1; then
    n="$(rg -c --no-heading --color=never -e "$1" "$TARGET" 2>/dev/null \
        | awk -F: '{s+=$2} END {print s+0}' || true)"
  else
    n="$(grep -rcE "$1" "$TARGET" 2>/dev/null \
        | awk -F: '{s+=$2} END {print s+0}' || true)"
  fi
  printf '%s' "${n:-0}"
  return 0
}

CNT_CTRL=$(count_pattern '@(RestController|Controller|GetMapping|PostMapping|RequestMapping)\b|@(app\.(get|post|put|delete))|app\.(get|post|put|delete)\(' )
CNT_SCHED=$(count_pattern '@Scheduled\b|@scheduled\b|@cron\b|^[[:space:]]*cron:|celery\.task\(' )
CNT_MSG=$(count_pattern  '@KafkaListener|@RabbitListener|@SqsListener|@MessageMapping|consumer\.subscribe' )
CNT_INIT=$(count_pattern '@PostConstruct|InitializingBean|on_startup|app\.ready|once_ready|register_startup' )
CNT_CLI=$(count_pattern  'cobra\.Command\{|argparse\.ArgumentParser|commander\.Command|@click\.command|click\.command\(' )
CNT_EVT=$(count_pattern  '@EventListener|addEventListener\(|on\(["\x27][a-z]' )
CNT_MID=$(count_pattern  'app\.use\(|middleware\.func|class[[:space:]]+.*Middleware\b' )
CNT_HOOK=$(count_pattern 'webhook|/hooks?/' )
CNT_WS=$(count_pattern   'WebSocket\b|socket\.on\(|new[[:space:]]+WebSocket|sse|ServerSentEvent' )

# ── Business evidence summary ──────────────────────────────
COMMENTS_LINES="$(wc -l < "$BE/comments.jsonl" 2>/dev/null | tr -d ' \n' || true)"
TESTS_LINES="$(wc -l < "$BE/tests.jsonl" 2>/dev/null | tr -d ' \n' || true)"
COMMENT_FILES="$(awk -F'"file":"' '{print $2}' "$BE/comments.jsonl" 2>/dev/null | awk -F'"' 'NF>0 {print $1}' | sort -u | wc -l | tr -d ' \n' || true)"
SCHEMA_HAS="$( { grep -c '^- ' "$BE/schema.md" 2>/dev/null || true; } | head -n1 | tr -d ' \n')"
CONFIG_COUNT="$( { grep -c '^- ' "$BE/configs.md" 2>/dev/null || true; } | head -n1 | tr -d ' \n')"
DOCS_COUNT="$( { grep -c '^- ' "$BE/docs.md" 2>/dev/null || true; } | head -n1 | tr -d ' \n')"
: "${COMMENTS_LINES:=0}"
: "${TESTS_LINES:=0}"
: "${COMMENT_FILES:=0}"
: "${SCHEMA_HAS:=0}"
: "${CONFIG_COUNT:=0}"
: "${DOCS_COUNT:=0}"

# Top 3 commit-theme clusters
TOP_THEMES=""
if [[ -f "$BE/commit-themes.md" ]]; then
  TOP_THEMES="$(awk '/^- [0-9]/ {print; n++} n>=3 {exit}' "$BE/commit-themes.md" | paste -sd '; ' -)"
fi
[[ -z "$TOP_THEMES" ]] && TOP_THEMES="(no commits / no themes)"

# ── Top buckets (read each bucket-*.json's `scope` + `loc`) ──
BUCKETS_LIST="$(ls "$D/buckets"/bucket-*.json 2>/dev/null | sort)"
TOP_BUCKETS=""
if [[ -n "$BUCKETS_LIST" ]]; then
  while IFS= read -r bf; do
    [[ -z "$bf" ]] && continue
    sc="$(read_str scope "$bf")"
    lc="$(read_num loc "$bf")"
    eh="$(tr -d '\n' < "$bf" | sed -nE 's/.*"isEntryHeavy"[[:space:]]*:[[:space:]]*(true|false).*/\1/p' | head -n1)"
    tag=""
    [[ "$eh" == "true" ]] && tag=" 【entry-heavy】"
    TOP_BUCKETS="$TOP_BUCKETS- \`$sc\` — ${lc:-0} LOC${tag}"$'\n'
  done <<< "$BUCKETS_LIST"
fi

# ── Bucket strategy one-liner ──────────────────────────────
case "$BUCKET_STRATEGY" in
  single)              BUCKET_LINE="single bucket; per-file verbatim evidence" ;;
  directory-rollup)    BUCKET_LINE="one bucket per top-level directory, ~5k LOC target; per-file verbatim" ;;
  codegraph-module)    BUCKET_LINE="one bucket per codegraph module; entry-files verbatim, rest summary" ;;
  two-tier-directory)  BUCKET_LINE="two-tier directory (codegraph index absent); submodule = symbol summary" ;;
  two-tier)            BUCKET_LINE="two-tier (top module → submodule); symbol-summary only" ;;
  *)                   BUCKET_LINE="$BUCKET_STRATEGY" ;;
esac

# ── Render Markdown ────────────────────────────────────────
OUT="$D/codebase-brief.md"
{
  echo "# Codebase Brief · $PROJECT_NAME"
  echo
  echo "_Snapshot: ${SNAPSHOT:-unknown} · Tier: ${TIER} · codegraph ${CG_VERSION:-N/A} · rg ${RG_VERSION:-N/A} · grep ${GREP_VERSION:-N/A}_"
  echo
  echo "> **何时读**：Phase 2 Plan 的入口阅读。本文是主 Agent 写 \`plan/plan.md\` 前唯一必读的项目级速览。"
  echo "> 主 Agent **不需要再打开任何源码**，所有细节都已落盘在 inventory / buckets / business-evidence 中。"
  echo
  echo "## At a glance"
  echo
  echo "- \`$PROJECT_NAME\`: **${TOTAL_FILES:-0} files total** ($ANALYZED analyzed, $EXCLUDED_FILES excluded), **${TOTAL_LOC:-0} LOC**."
  echo "- **Size tier:** \`$SIZE_TIER\` · Bucket count: $BUCKET_COUNT · Strategy: $BUCKET_LINE"
  echo "- **Evidence strategy:** \`$EVIDENCE_STRATEGY\` (governs Step A SubAgent for every Section)."
  echo "- **Tool tier:** \`$TIER\`."
  if [[ "$SIZE_TIER" == ">10k" ]]; then
    echo "- **>10k files honesty rule active:** reader profile **forced to \`archaeology · ~70%\`**, Coverage Annex mandatory, no '100% coverage' claim."
  fi
  echo
  echo "## Language mix"
  echo
  echo "| language | file count |"
  echo "|----------|-----------:|"
  if [[ -n "$LANG_TABLE" ]]; then
    printf '%s\n' "$LANG_TABLE" | awk '{printf "| %s | %s |\n", $2, $1}'
  else
    echo "| (none) | 0 |"
  fi
  echo
  echo "## Top buckets · candidate Section seeds"
  echo
  if [[ -n "$TOP_BUCKETS" ]]; then
    printf '%s' "$TOP_BUCKETS"
  else
    echo "(no buckets — inventory was empty or buckets.sh did not run)"
  fi
  echo
  echo "## Entry-point sniff (preview · regex-only, full taxonomy in Section 05)"
  echo
  echo "| role | rough hits |"
  echo "|------|----------:|"
  echo "| 控制器方法 (Controller)        | $CNT_CTRL |"
  echo "| 定时任务 (Scheduled job)        | $CNT_SCHED |"
  echo "| 消息消费者 (Message consumer)   | $CNT_MSG |"
  echo "| 初始化加载 (Init loader)        | $CNT_INIT |"
  echo "| CLI 命令 (CLI entry)            | $CNT_CLI |"
  echo "| 事件监听器 (Event listener)     | $CNT_EVT |"
  echo "| 中间件 (Middleware)             | $CNT_MID |"
  echo "| Webhook                         | $CNT_HOOK |"
  echo "| WebSocket / SSE                 | $CNT_WS |"
  echo
  echo "> These are pattern-match counts, not semantic counts. Section 05 (when active) runs"
  echo "> the full \`references/entry-point-taxonomy.md\` detector with per-language rules."
  echo
  echo "## Business evidence summary"
  echo
  echo "- **Doc comments:** $COMMENTS_LINES lines across $COMMENT_FILES files (\`business-evidence/comments.jsonl\`)."
  echo "- **Test functions:** $TESTS_LINES detected (\`business-evidence/tests.jsonl\`)."
  if [[ "$SCHEMA_HAS" -gt 0 ]]; then
    echo "- **DB schema:** yes — see \`business-evidence/schema.md\` ($SCHEMA_HAS items)."
  else
    echo "- **DB schema:** none detected (\`business-evidence/schema.md\` records '(no DB schema found)')."
  fi
  echo "- **Configs / enums:** $CONFIG_COUNT items (\`business-evidence/configs.md\`)."
  echo "- **Docs (README / docs/):** $DOCS_COUNT files (\`business-evidence/docs.md\`)."
  echo "- **Commit themes (last ~200):** $TOP_THEMES"
  echo
  echo "## Auto-decisions for Phase 2 Plan"
  echo
  echo "- **Recommend reader profile:** \`$PROFILE_REC · $PROFILE_RETENTION\` $PROFILE_NOTE"
  echo "  - Reason: $REASON."
  echo "- **Optional sections to include by default:** $OPT_SECTIONS"
  echo "- **\"100% coverage\" claim allowed?** $COVERAGE_ALLOWED"
  echo
  echo "## How to use this brief"
  echo
  echo "1. The main agent reads this brief and skims \`buckets/_summary.json\`, then opens \`references/plan-template.md\` and writes \`plan/plan.md\`."
  echo "2. **Do not open source code from here on** — the inventory tells you what exists, the buckets tell you how Sections will be cut, the business-evidence files tell you what business claims are supportable."
  echo "3. If the auto-recommended profile in this brief looks wrong (e.g. archaeology forced on a project the user wants 30-min reviewed), bring it up at Checkpoint 1 as the AI recommendation — the user has the final say."
} > "$OUT"

LINES="$(wc -l < "$OUT" | tr -d ' ')"
echo "✓ wrote $OUT ($LINES lines)"
