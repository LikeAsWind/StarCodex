#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# coverage.sh —— Audit inventory coverage across sections + annex.
#
# Reads every file path from discovery/inventory.json (where
# excluded_reason == null), and for each:
#   1. searches all article/sections/*-evidence.md for that path → assigned
#   2. otherwise searches article/sections/coverage-annex.json     → annexed
#   3. otherwise → missing
#
# Pass when missing is empty (coveragePct == 100).
#
# Honors the ">10k honesty rule": if discovery/tier.json reports
# size tier ">10k" (or stats indicate >10k analyzed files), ANY missing entry
# yields exit code 2 — Phase 8 Delivery must read this and refuse to claim
# "100% coverage".
#
# Usage:
#   bash coverage.sh --workspace <path>
#   bash coverage.sh --help
#
# Outputs:
#   review/coverage.json
#
# Coverage Annex contract (article/sections/coverage-annex.json):
#   {
#     "annexed": [
#       {"path": "src/gen/bindings.go",
#        "reason": "auto-generated bindings; no business semantics"},
#       ...
#     ]
#   }
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,34p' "$0"
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
  echo "✗ --workspace <path> is required" >&2; exit 1
fi

INVENTORY="$WORKSPACE/discovery/inventory.json"
TIER_JSON="$WORKSPACE/discovery/tier.json"
SECTIONS_DIR="$WORKSPACE/article/sections"
ANNEX="$SECTIONS_DIR/coverage-annex.json"
REVIEW_DIR="$WORKSPACE/review"

if [[ ! -f "$INVENTORY" ]]; then
  echo "✗ inventory.json not found: $INVENTORY (run Phase 1 Discover first)" >&2
  exit 1
fi
if [[ ! -d "$SECTIONS_DIR" ]]; then
  echo "✗ sections directory not found: $SECTIONS_DIR" >&2; exit 1
fi
mkdir -p "$REVIEW_DIR"

# ── Helpers ─────────────────────────────────────────────────
js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Detect size tier. Prefer discovery/tier.json, fall back to inventory stats.
detect_size_tier() {
  # Phase 1 size-tier classification is stored either in tier.json (the tool
  # tier from probe + user choice) or in a sibling size-tier.json. The PRD
  # uses both names; we accept either, plus an inventory-based fallback.
  local size_tier=""
  if [[ -f "$WORKSPACE/discovery/size-tier.json" ]]; then
    size_tier="$(tr -d '\n' < "$WORKSPACE/discovery/size-tier.json" \
      | sed -nE 's/.*"tier"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
  fi
  if [[ -z "$size_tier" && -f "$INVENTORY" ]]; then
    local n
    n="$(tr -d '\n' < "$INVENTORY" \
      | sed -nE 's/.*"analyzedFiles"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' | head -n1)"
    if [[ -n "$n" ]]; then
      if   [[ "$n" -lt 100 ]];   then size_tier="<100"
      elif [[ "$n" -lt 1000 ]];  then size_tier="100-1k"
      elif [[ "$n" -lt 10000 ]]; then size_tier="1k-10k"
      else                            size_tier=">10k"
      fi
    fi
  fi
  printf '%s' "${size_tier:-unknown}"
}

SIZE_TIER="$(detect_size_tier)"

# Extract analyzed paths from inventory (excluded_reason: null) using awk.
# inventory.json schema: files array of {path, ..., excluded_reason: <null|str>}.
get_analyzed_paths() {
  # Use a small awk state machine to walk the JSON file array. Each `path`
  # appears before `excluded_reason` in the row.
  awk '
    BEGIN { in_files = 0; depth = 0; current_path = ""; current_excl = "" }
    /"files"[[:space:]]*:[[:space:]]*\[/ { in_files = 1; next }
    in_files == 1 {
      line = $0
      # path field
      if (match(line, /"path"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        s = substr(line, RSTART, RLENGTH)
        sub(/.*"path"[[:space:]]*:[[:space:]]*"/, "", s)
        sub(/".*/, "", s)
        current_path = s
      }
      # excluded_reason
      if (match(line, /"excluded_reason"[[:space:]]*:[[:space:]]*(null|"[^"]*")/)) {
        s = substr(line, RSTART, RLENGTH)
        sub(/.*"excluded_reason"[[:space:]]*:[[:space:]]*/, "", s)
        current_excl = s
        # Emit at end-of-row markers (} or ,})
        if (current_path != "") {
          if (current_excl == "null") {
            print current_path
          }
          current_path = ""; current_excl = ""
        }
      }
      # End of files array
      if (line ~ /^[[:space:]]*\][[:space:]]*,?[[:space:]]*$/) {
        in_files = 0
      }
    }
  ' "$INVENTORY"
}

# Extract annexed paths from coverage-annex.json (paths only).
get_annexed_paths() {
  [[ ! -f "$ANNEX" ]] && return 0
  tr -d '\n' < "$ANNEX" 2>/dev/null \
    | { grep -oE '"path"[[:space:]]*:[[:space:]]*"[^"]*"' || true; } \
    | sed -E 's/.*"path"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' \
    || true
}

# Concatenate all evidence.md content for cheap path lookups.
ALL_EVIDENCE_FILE="$(mktemp -t bc-coverage-XXXXXX.md)"
trap 'rm -f "$ALL_EVIDENCE_FILE"' EXIT
for ev in "$SECTIONS_DIR"/*-evidence.md; do
  [[ -f "$ev" ]] && cat "$ev" >> "$ALL_EVIDENCE_FILE"
done

# Build annex set
ANNEX_SET_FILE="$(mktemp -t bc-coverage-annex-XXXXXX.txt)"
trap 'rm -f "$ALL_EVIDENCE_FILE" "$ANNEX_SET_FILE"' EXIT
get_annexed_paths > "$ANNEX_SET_FILE"

# ── Walk inventory ──────────────────────────────────────────
total=0
assigned=0
annexed=0
missing=()

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  total=$((total + 1))
  if grep -qF -- "$path" "$ALL_EVIDENCE_FILE" 2>/dev/null; then
    assigned=$((assigned + 1))
    continue
  fi
  if grep -qxF -- "$path" "$ANNEX_SET_FILE" 2>/dev/null; then
    annexed=$((annexed + 1))
    continue
  fi
  missing+=("$path")
done < <(get_analyzed_paths)

# Compute pct
PCT="0.00"
if [[ $total -gt 0 ]]; then
  PCT="$(awk -v a=$assigned -v n=$annexed -v t=$total \
    'BEGIN { printf "%.2f", (a + n) * 100 / t }')"
fi

# Verdict
verdict="pass"
missing_count=${#missing[@]}
if [[ $missing_count -gt 0 ]]; then
  verdict="fail"
fi

# Build missing JSON
missing_json="[" mfirst=1
for m in "${missing[@]}"; do
  if [[ $mfirst -eq 1 ]]; then mfirst=0; else missing_json="$missing_json,"; fi
  missing_json="$missing_json\"$(js_escape "$m")\""
done
missing_json="$missing_json]"

OUT="$REVIEW_DIR/coverage.json"
cat > "$OUT" <<EOF
{
  "totalAnalyzed": $total,
  "assigned": $assigned,
  "annexed": $annexed,
  "missing": $missing_json,
  "missingCount": $missing_count,
  "coveragePct": $PCT,
  "verdict": "$verdict",
  "sizeTier": "$(js_escape "$SIZE_TIER")",
  "snapshot": "$(date -u +%FT%TZ)"
}
EOF

echo "✓ $OUT (analyzed=$total assigned=$assigned annexed=$annexed missing=$missing_count pct=$PCT% tier=$SIZE_TIER verdict=$verdict)"

# Exit codes:
#   0 — 100% coverage
#   1 — small project, missing entries
#   2 — >10k honesty: cannot claim 100%; any missing → distinct failure code
if [[ "$verdict" == "pass" ]]; then
  exit 0
fi
if [[ "$SIZE_TIER" == ">10k" ]]; then
  exit 2
fi
exit 1
