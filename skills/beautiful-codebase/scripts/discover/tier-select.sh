#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# tier-select.sh —— Finalize the tool tier for Phase 1 Discover.
#
# Reads the JSON output of probe-tools.sh (file path or stdin), optionally
# combines it with the user's Phase 0 choice for the `codegraph-installed`
# case (init / downgrade / stop), and writes
# `<workspace>/discovery/tier.json` — the single source of truth that the
# remaining Phase 1 scripts (inventory / buckets / business-evidence /
# codebase-brief) read.
#
# Usage:
#   bash tier-select.sh --workspace <path> --probe-json <path|-> \
#                       [--choice init|downgrade|stop] [--target <path>]
#   bash tier-select.sh --help
#
# Choices (used only when probe tier is `codegraph-installed`):
#   init        Run `codegraph init <target>` now, then tier becomes
#               `codegraph-indexed`. This is the ONE allowed write into the
#               analyzed project (per SKILL.md Phase 0 rule). Script echoes a
#               notice before running and only proceeds if `codegraph` is on
#               PATH. Failure of `codegraph init` exits non-zero.
#   downgrade   Tier becomes `rg` if rg available, else `grep`.
#   stop        Exit 2; caller should halt the skill, the user will init
#               manually and restart.
#
# Output schema (discovery/tier.json):
#   {
#     "tier":          "codegraph-indexed|codegraph-installed|rg|grep",
#     "target":        "<absolute path>",
#     "snapshot":      "<ISO timestamp>",
#     "decided_by":    "auto|user-init|user-downgrade",
#     "tools":         { codegraph:{available,version,indexed,indexPath},
#                        rg:{available,version},
#                        grep:{available,version} },
#     "notes":         [ "...", "..." ]
#   }
#
# Exit codes:
#   0  Tier successfully decided and tier.json written.
#   2  User chose `stop` (skill should halt cleanly).
#   1  Other errors (bad args, codegraph init failure, missing inputs).
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,38p' "$0"
}

# ── Args ────────────────────────────────────────────────────
WORKSPACE=""
PROBE_JSON=""
CHOICE=""
TARGET_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)         usage; exit 0 ;;
    --workspace)       shift; WORKSPACE="${1:-}" ;;
    --workspace=*)     WORKSPACE="${1#--workspace=}" ;;
    --probe-json)      shift; PROBE_JSON="${1:-}" ;;
    --probe-json=*)    PROBE_JSON="${1#--probe-json=}" ;;
    --choice)          shift; CHOICE="${1:-}" ;;
    --choice=*)        CHOICE="${1#--choice=}" ;;
    --target)          shift; TARGET_OVERRIDE="${1:-}" ;;
    --target=*)        TARGET_OVERRIDE="${1#--target=}" ;;
    *) echo "✗ unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$WORKSPACE" ]]; then
  echo "✗ --workspace <path> is required" >&2
  exit 1
fi
if [[ -z "$PROBE_JSON" ]]; then
  echo "✗ --probe-json <path|-> is required" >&2
  exit 1
fi

mkdir -p "$WORKSPACE/discovery"

# ── Slurp probe JSON ────────────────────────────────────────
if [[ "$PROBE_JSON" == "-" ]]; then
  PROBE_RAW="$(cat)"
else
  if [[ ! -f "$PROBE_JSON" ]]; then
    echo "✗ probe JSON file not found: $PROBE_JSON" >&2
    exit 1
  fi
  PROBE_RAW="$(cat "$PROBE_JSON")"
fi

if [[ -z "$PROBE_RAW" ]]; then
  echo "✗ probe JSON is empty" >&2
  exit 1
fi

# ── Tiny JSON value extractors (no jq dependency) ───────────
# Grab a string value: json_str "tier"
json_str() {
  local key="$1"
  printf '%s' "$PROBE_RAW" | sed -nE 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1
}
# Grab a boolean: json_bool "codegraph" "available"
json_bool_nested() {
  local outer="$1" inner="$2"
  printf '%s' "$PROBE_RAW" \
    | tr -d '\n' \
    | sed -nE 's/.*"'"$outer"'"[[:space:]]*:[[:space:]]*\{([^}]*)\}.*/\1/p' \
    | sed -nE 's/.*"'"$inner"'"[[:space:]]*:[[:space:]]*(true|false).*/\1/p' \
    | head -n1
}
json_str_nested() {
  local outer="$1" inner="$2"
  printf '%s' "$PROBE_RAW" \
    | tr -d '\n' \
    | sed -nE 's/.*"'"$outer"'"[[:space:]]*:[[:space:]]*\{([^}]*)\}.*/\1/p' \
    | sed -nE 's/.*"'"$inner"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' \
    | head -n1
}

PROBE_TIER="$(json_str tier)"
PROBE_TARGET="$(json_str target)"
CG_AVAILABLE="$(json_bool_nested codegraph available)"
CG_VERSION="$(json_str_nested codegraph version)"
CG_INDEXED="$(json_bool_nested codegraph indexed)"
CG_INDEX_PATH="$(json_str_nested codegraph indexPath)"
RG_AVAILABLE="$(json_bool_nested rg available)"
RG_VERSION="$(json_str_nested rg version)"
GREP_AVAILABLE="$(json_bool_nested grep available)"
GREP_VERSION="$(json_str_nested grep version)"

if [[ -z "$PROBE_TIER" ]]; then
  echo "✗ probe JSON does not contain a tier field" >&2
  exit 1
fi

# Allow caller to override the target path (e.g. analyzing a sibling project).
TARGET="${TARGET_OVERRIDE:-$PROBE_TARGET}"
if [[ -z "$TARGET" ]]; then
  echo "✗ no target path: pass --target or include target in probe JSON" >&2
  exit 1
fi
if [[ ! -d "$TARGET" ]]; then
  echo "✗ target not a directory: $TARGET" >&2
  exit 1
fi
TARGET_ABS="$(cd "$TARGET" && pwd)"

# ── Resolve final tier based on probe tier + user choice ────
FINAL_TIER="$PROBE_TIER"
DECIDED_BY="auto"
NOTES=()

case "$PROBE_TIER" in
  codegraph-indexed)
    NOTES+=("target has .codegraph/, semantic queries fully available")
    ;;
  codegraph-installed)
    if [[ -z "$CHOICE" ]]; then
      cat >&2 <<'EOF'
✗ probe tier is `codegraph-installed` (codegraph CLI present, target NOT indexed).
  This script needs a user choice — pass one of:
    --choice=init        run `codegraph init` now (writes .codegraph/ into target)
    --choice=downgrade   keep target untouched, downgrade to rg/grep
    --choice=stop        halt skill; user will init manually and restart
EOF
      exit 1
    fi
    case "$CHOICE" in
      init)
        if ! command -v codegraph >/dev/null 2>&1; then
          echo "✗ user chose init but codegraph CLI is not on PATH" >&2
          exit 1
        fi
        echo "▸ Notice: running \`codegraph init $TARGET_ABS\` now (writes .codegraph/ into the target project)." >&2
        echo "▸ This is the only allowed write into the analyzed project." >&2
        if ! codegraph init "$TARGET_ABS" >&2; then
          echo "✗ \`codegraph init\` failed; aborting" >&2
          exit 1
        fi
        FINAL_TIER="codegraph-indexed"
        DECIDED_BY="user-init"
        CG_INDEXED="true"
        CG_INDEX_PATH="$TARGET_ABS/.codegraph"
        NOTES+=("user opted in: ran \`codegraph init\` at $TARGET_ABS")
        ;;
      downgrade)
        if [[ "$RG_AVAILABLE" == "true" ]]; then
          FINAL_TIER="rg"
        elif [[ "$GREP_AVAILABLE" == "true" ]]; then
          FINAL_TIER="grep"
        else
          echo "✗ user chose downgrade but neither rg nor grep available; cannot proceed" >&2
          exit 1
        fi
        DECIDED_BY="user-downgrade"
        NOTES+=("user opted to skip codegraph init; using ${FINAL_TIER}")
        ;;
      stop)
        echo "▸ User chose stop. Skill should halt cleanly; user will run \`codegraph init\` manually and restart." >&2
        exit 2
        ;;
      *)
        echo "✗ unknown --choice: $CHOICE (expected init|downgrade|stop)" >&2
        exit 1
        ;;
    esac
    ;;
  rg)
    NOTES+=("codegraph absent; using rg text search; symbol queries degrade to text grep")
    ;;
  grep)
    NOTES+=("only system grep available; accuracy reduced; recommend installing ripgrep (rg)")
    ;;
  none)
    echo "✗ probe tier is \`none\` (no codegraph / rg / grep). Cannot proceed." >&2
    exit 1
    ;;
  *)
    echo "✗ unknown probe tier: $PROBE_TIER" >&2
    exit 1
    ;;
esac

# ── JSON escape helper ──────────────────────────────────────
js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

SNAPSHOT="$(date -u +%FT%TZ)"

# Build notes array
notes_json="["
first=1
for n in "${NOTES[@]}"; do
  if [[ $first -eq 1 ]]; then first=0; else notes_json="$notes_json,"; fi
  notes_json="$notes_json\"$(js_escape "$n")\""
done
notes_json="$notes_json]"

# Lowercase boolean strings -> raw json tokens
to_jbool() { [[ "$1" == "true" ]] && echo true || echo false; }
CG_AV_J="$(to_jbool "$CG_AVAILABLE")"
CG_IX_J="$(to_jbool "$CG_INDEXED")"
RG_AV_J="$(to_jbool "$RG_AVAILABLE")"
GREP_AV_J="$(to_jbool "$GREP_AVAILABLE")"

if [[ -n "$CG_INDEX_PATH" ]]; then
  CG_PATH_JSON="\"$(js_escape "$CG_INDEX_PATH")\""
else
  CG_PATH_JSON="null"
fi

OUT="$WORKSPACE/discovery/tier.json"
cat > "$OUT" <<EOF
{
  "tier": "$(js_escape "$FINAL_TIER")",
  "target": "$(js_escape "$TARGET_ABS")",
  "snapshot": "$SNAPSHOT",
  "decided_by": "$DECIDED_BY",
  "tools": {
    "codegraph": {"available": $CG_AV_J, "version": "$(js_escape "$CG_VERSION")", "indexed": $CG_IX_J, "indexPath": $CG_PATH_JSON},
    "rg":        {"available": $RG_AV_J, "version": "$(js_escape "$RG_VERSION")"},
    "grep":      {"available": $GREP_AV_J, "version": "$(js_escape "$GREP_VERSION")"}
  },
  "notes": $notes_json
}
EOF

echo "✓ wrote $OUT (tier=$FINAL_TIER, decided_by=$DECIDED_BY)"
