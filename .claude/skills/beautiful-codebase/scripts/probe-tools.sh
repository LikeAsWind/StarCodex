#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# probe-tools.sh —— Detect available code-search tooling and emit a tier label.
#
# Used by Phase 0 / Intake of the beautiful-codebase Skill. The tier label
# decides which family of queries lib/query.sh dispatches:
#
#   codegraph-indexed   codegraph installed AND target has .codegraph/
#   codegraph-installed codegraph installed but target NOT yet indexed
#   rg                  codegraph absent, ripgrep present
#   grep                only system grep available
#   none                none of the three (exit 2)
#
# Usage:
#   bash probe-tools.sh [--target <path>] [--json]
#   bash probe-tools.sh --help
#
# Examples:
#   bash probe-tools.sh                              # text mode against $PWD
#   bash probe-tools.sh --target ./StarCodex --json  # JSON output for scripting
#
# Exit code: 0 on any tier ≥ grep; 2 on tier=none.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,22p' "$0"
}

# ── Parse args ──────────────────────────────────────────────
TARGET=""
JSON=0
for arg in "$@"; do
  case "$arg" in
    --help|-h)        usage; exit 0 ;;
    --json)           JSON=1 ;;
    --target)         shift; TARGET="${1:-}" ;;
    --target=*)       TARGET="${arg#--target=}" ;;
    *)
      # Tolerate the legacy positional form: probe-tools.sh <path>
      if [[ -z "$TARGET" && "$arg" != --* ]]; then
        TARGET="$arg"
      fi
      ;;
  esac
done

TARGET="${TARGET:-$PWD}"
if [[ ! -d "$TARGET" ]]; then
  echo "✗ --target path not a directory: $TARGET" >&2
  exit 1
fi
TARGET_ABS="$(cd "$TARGET" && pwd)"

# ── Detect each tool ────────────────────────────────────────
# Each detector runs version pipelines that may fail under set -euo pipefail
# (e.g. `head` SIGPIPEing the upstream); guard with `|| true` everywhere.
detect_codegraph() {
  if command -v codegraph >/dev/null 2>&1; then
    CG_AVAILABLE=1
    local raw
    raw="$(codegraph --version 2>/dev/null || true)"
    CG_VERSION="$(printf '%s' "$raw" | head -n1 | sed -E 's/^[^0-9]*([0-9][0-9.]*).*/\1/' || true)"
    if [[ -z "$CG_VERSION" ]]; then CG_VERSION="unknown"; fi
  else
    CG_AVAILABLE=0
    CG_VERSION=""
  fi

  if [[ -d "$TARGET_ABS/.codegraph" ]]; then
    CG_INDEXED=1
    CG_INDEX_PATH="$TARGET_ABS/.codegraph"
  else
    CG_INDEXED=0
    CG_INDEX_PATH=""
  fi
}

detect_rg() {
  if command -v rg >/dev/null 2>&1; then
    RG_AVAILABLE=1
    local raw
    raw="$(rg --version 2>/dev/null || true)"
    RG_VERSION="$(printf '%s' "$raw" | head -n1 | sed -E 's/^ripgrep[[:space:]]+([0-9][0-9.]*).*/\1/' || true)"
    if [[ -z "$RG_VERSION" ]]; then RG_VERSION="unknown"; fi
  else
    RG_AVAILABLE=0
    RG_VERSION=""
  fi
}

detect_grep() {
  if command -v grep >/dev/null 2>&1; then
    GREP_AVAILABLE=1
    local raw
    raw="$(grep --version 2>/dev/null || true)"
    GREP_VERSION="$(printf '%s' "$raw" | head -n1 | sed -E 's/.*[[:space:]]([0-9][0-9.]*)[^0-9]*$/\1/' || true)"
    if [[ -z "$GREP_VERSION" ]]; then GREP_VERSION="unknown"; fi
  else
    GREP_AVAILABLE=0
    GREP_VERSION=""
  fi
  return 0
}

detect_codegraph
detect_rg
detect_grep

# ── Compute tier label ──────────────────────────────────────
if [[ "$CG_AVAILABLE" == "1" && "$CG_INDEXED" == "1" ]]; then
  TIER="codegraph-indexed"
elif [[ "$CG_AVAILABLE" == "1" ]]; then
  TIER="codegraph-installed"
elif [[ "$RG_AVAILABLE" == "1" ]]; then
  TIER="rg"
elif [[ "$GREP_AVAILABLE" == "1" ]]; then
  TIER="grep"
else
  TIER="none"
fi

# ── Emit ────────────────────────────────────────────────────
emit_json() {
  # Hand-roll JSON to avoid jq/python deps.
  local cg_indexed_json=$([[ "$CG_INDEXED" == "1" ]] && echo true || echo false)
  local cg_path_json=$([[ -n "$CG_INDEX_PATH" ]] && printf '"%s"' "${CG_INDEX_PATH//\\/\\\\}" || echo null)
  cat <<EOF
{
  "tier": "$TIER",
  "codegraph": {"available": $([[ "$CG_AVAILABLE" == "1" ]] && echo true || echo false), "version": "$CG_VERSION", "indexed": $cg_indexed_json, "indexPath": $cg_path_json},
  "rg": {"available": $([[ "$RG_AVAILABLE" == "1" ]] && echo true || echo false), "version": "$RG_VERSION"},
  "grep": {"available": $([[ "$GREP_AVAILABLE" == "1" ]] && echo true || echo false), "version": "$GREP_VERSION"},
  "target": "${TARGET_ABS//\\/\\\\}"
}
EOF
}

emit_text() {
  echo "tier:      $TIER"
  echo "target:    $TARGET_ABS"
  echo "codegraph: $([[ "$CG_AVAILABLE" == "1" ]] && echo "yes ($CG_VERSION)" || echo "no") · indexed=$([[ "$CG_INDEXED" == "1" ]] && echo "yes" || echo "no")"
  echo "rg:        $([[ "$RG_AVAILABLE" == "1" ]] && echo "yes ($RG_VERSION)" || echo "no")"
  echo "grep:      $([[ "$GREP_AVAILABLE" == "1" ]] && echo "yes ($GREP_VERSION)" || echo "no")"
  case "$TIER" in
    codegraph-indexed)
      echo
      echo "▸ Tier codegraph-indexed: target has .codegraph/, semantic queries fully available."
      ;;
    codegraph-installed)
      echo
      echo "▸ Tier codegraph-installed: codegraph CLI present, but target NOT indexed."
      echo "  Phase 0 must ask the user (3 explicit choices, never silently run codegraph init):"
      echo "    A · run codegraph init now"
      echo "    B · downgrade to rg tier"
      echo "    C · stop, user will init manually"
      ;;
    rg)
      echo
      echo "▸ Tier rg: text-pattern search only. Symbol/caller queries degrade to text grep."
      ;;
    grep)
      echo
      echo "▸ Tier grep: only system grep present. Accuracy reduced; recommend installing rg."
      ;;
    none)
      echo
      echo "✗ Tier none: no codegraph / rg / grep on PATH. Cannot proceed." >&2
      ;;
  esac
}

if [[ "$JSON" == "1" ]]; then
  emit_json
else
  emit_text
fi

[[ "$TIER" == "none" ]] && exit 2
exit 0
