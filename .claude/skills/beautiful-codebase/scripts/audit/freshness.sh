#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# freshness.sh —— Re-run inventory and diff against the snapshot.
#
# Reads the original discovery/inventory.json, re-runs
# scripts/discover/inventory.sh to a temporary location, then computes
# {added, removed, modified} files by path↔sha map comparison.
#
# Always exits 0 — drift is information, not failure.
#
# Usage:
#   bash freshness.sh --workspace <path>
#   bash freshness.sh --help
#
# Outputs:
#   review/freshness.json
#   review/freshness-summary.md   (one-paragraph human summary, footer-ready)
#
# Schema (review/freshness.json):
#   {
#     "originalSnapshot": "<ISO>",
#     "currentSnapshot":  "<ISO>",
#     "addedFiles":    ["..."],
#     "removedFiles":  ["..."],
#     "modifiedFiles": ["..."],
#     "verdict": "fresh" | "drifted"
#   }
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,29p' "$0"
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

ORIGINAL="$WORKSPACE/discovery/inventory.json"
TIER_JSON="$WORKSPACE/discovery/tier.json"
REVIEW_DIR="$WORKSPACE/review"

if [[ ! -f "$ORIGINAL" ]]; then
  echo "✗ original inventory.json not found: $ORIGINAL" >&2; exit 1
fi
if [[ ! -f "$TIER_JSON" ]]; then
  echo "✗ tier.json not found: $TIER_JSON (needed to re-run inventory)" >&2; exit 1
fi
mkdir -p "$REVIEW_DIR"

# ── Helpers ─────────────────────────────────────────────────
js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

# Extract snapshot timestamp from an inventory.json.
get_snapshot() {
  local file="$1"
  tr -d '\n' < "$file" \
    | sed -nE 's/.*"snapshot"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1
}

# Emit "path\tsha" for each analyzed file in an inventory.json.
get_path_sha_pairs() {
  local file="$1"
  # The schema places sha after path; pair them within the same row using awk.
  awk '
    BEGIN { in_files = 0; current_path = ""; current_sha = "" }
    /"files"[[:space:]]*:[[:space:]]*\[/ { in_files = 1; next }
    in_files == 1 {
      line = $0
      if (match(line, /"path"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        s = substr(line, RSTART, RLENGTH)
        sub(/.*"path"[[:space:]]*:[[:space:]]*"/, "", s)
        sub(/".*/, "", s)
        current_path = s
      }
      if (match(line, /"sha"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        s = substr(line, RSTART, RLENGTH)
        sub(/.*"sha"[[:space:]]*:[[:space:]]*"/, "", s)
        sub(/".*/, "", s)
        current_sha = s
        if (current_path != "" && current_sha != "") {
          print current_path "\t" current_sha
          current_path = ""; current_sha = ""
        }
      }
      if (line ~ /^[[:space:]]*\][[:space:]]*,?[[:space:]]*$/) { in_files = 0 }
    }
  ' "$file"
}

# ── Re-run inventory into a temp workspace ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISCOVER_SCRIPT="$SCRIPT_DIR/../discover/inventory.sh"
if [[ ! -f "$DISCOVER_SCRIPT" ]]; then
  echo "✗ inventory.sh not found at $DISCOVER_SCRIPT" >&2
  exit 1
fi

TMP_WS="$(mktemp -d -t bc-freshness-XXXXXX)"
trap 'rm -rf "$TMP_WS"' EXIT
mkdir -p "$TMP_WS/discovery"
# Re-use the existing tier.json (it carries the target path).
cp "$TIER_JSON" "$TMP_WS/discovery/tier.json"

if ! bash "$DISCOVER_SCRIPT" --workspace "$TMP_WS" >/dev/null 2>&1; then
  echo "⚠ re-running inventory failed; leaving freshness=unknown" >&2
  # Emit a degenerate report rather than failing
  cat > "$REVIEW_DIR/freshness.json" <<EOF
{
  "originalSnapshot": "$(js_escape "$(get_snapshot "$ORIGINAL")")",
  "currentSnapshot":  "$(date -u +%FT%TZ)",
  "addedFiles":    [],
  "removedFiles":  [],
  "modifiedFiles": [],
  "verdict": "unknown",
  "note": "re-run of scripts/discover/inventory.sh failed; treat as informational only"
}
EOF
  cat > "$REVIEW_DIR/freshness-summary.md" <<EOF
**Freshness**: re-scan failed; verdict unknown. Snapshot:
$(get_snapshot "$ORIGINAL").
EOF
  echo "✓ wrote $REVIEW_DIR/freshness.json (verdict=unknown)"
  exit 0
fi

CURRENT_INV="$TMP_WS/discovery/inventory.json"
if [[ ! -f "$CURRENT_INV" ]]; then
  echo "✗ re-run did not produce inventory.json" >&2
  exit 0
fi

# ── Diff path↔sha ───────────────────────────────────────────
OLD_PAIRS="$(mktemp -t bc-freshness-old-XXXXXX)"
NEW_PAIRS="$(mktemp -t bc-freshness-new-XXXXXX)"
trap 'rm -rf "$TMP_WS" "$OLD_PAIRS" "$NEW_PAIRS"' EXIT
get_path_sha_pairs "$ORIGINAL"    | sort > "$OLD_PAIRS"
get_path_sha_pairs "$CURRENT_INV" | sort > "$NEW_PAIRS"

OLD_PATHS="$(mktemp -t bc-freshness-oldp-XXXXXX)"
NEW_PATHS="$(mktemp -t bc-freshness-newp-XXXXXX)"
trap 'rm -rf "$TMP_WS" "$OLD_PAIRS" "$NEW_PAIRS" "$OLD_PATHS" "$NEW_PATHS"' EXIT
awk -F'\t' '{ print $1 }' "$OLD_PAIRS" > "$OLD_PATHS"
awk -F'\t' '{ print $1 }' "$NEW_PAIRS" > "$NEW_PATHS"

ADDED="$(comm -13 "$OLD_PATHS" "$NEW_PATHS")"
REMOVED="$(comm -23 "$OLD_PATHS" "$NEW_PATHS")"

# Modified: same path, different sha. Build old map then walk new.
MOD_TMP="$(mktemp -t bc-freshness-mod-XXXXXX)"
trap 'rm -rf "$TMP_WS" "$OLD_PAIRS" "$NEW_PAIRS" "$OLD_PATHS" "$NEW_PATHS" "$MOD_TMP"' EXIT
awk -F'\t' '
  NR == FNR { old[$1] = $2; next }
  { if ($1 in old && old[$1] != $2) print $1 }
' "$OLD_PAIRS" "$NEW_PAIRS" > "$MOD_TMP"
MODIFIED="$(cat "$MOD_TMP")"

ORIG_SNAPSHOT="$(get_snapshot "$ORIGINAL")"
NEW_SNAPSHOT="$(get_snapshot "$CURRENT_INV")"
[[ -z "$NEW_SNAPSHOT" ]] && NEW_SNAPSHOT="$(date -u +%FT%TZ)"

added_count=$(printf '%s\n' "$ADDED"    | grep -c . || true)
removed_count=$(printf '%s\n' "$REMOVED" | grep -c . || true)
modified_count=$(printf '%s\n' "$MODIFIED" | grep -c . || true)

verdict="fresh"
if [[ $added_count -gt 0 || $removed_count -gt 0 || $modified_count -gt 0 ]]; then
  verdict="drifted"
fi

# ── Build JSON arrays ───────────────────────────────────────
to_json_array() {
  local first=1 arr="[" line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ $first -eq 1 ]]; then first=0; else arr="$arr,"; fi
    arr="$arr\"$(js_escape "$line")\""
  done <<< "$1"
  arr="$arr]"
  printf '%s' "$arr"
}

ADDED_JSON="$(to_json_array "$ADDED")"
REMOVED_JSON="$(to_json_array "$REMOVED")"
MODIFIED_JSON="$(to_json_array "$MODIFIED")"

cat > "$REVIEW_DIR/freshness.json" <<EOF
{
  "originalSnapshot": "$(js_escape "$ORIG_SNAPSHOT")",
  "currentSnapshot":  "$(js_escape "$NEW_SNAPSHOT")",
  "addedFiles":    $ADDED_JSON,
  "removedFiles":  $REMOVED_JSON,
  "modifiedFiles": $MODIFIED_JSON,
  "addedCount":    $added_count,
  "removedCount":  $removed_count,
  "modifiedCount": $modified_count,
  "verdict": "$verdict"
}
EOF

# Markdown summary (footer-ready)
{
  printf '**Snapshot**: %s · **Re-checked**: %s · ' \
    "$ORIG_SNAPSHOT" "$NEW_SNAPSHOT"
  if [[ "$verdict" == "fresh" ]]; then
    printf '**No drift** since snapshot.\n'
  else
    printf '**Drift**: %d modified, %d added, %d removed since snapshot. (See `review/freshness.json` for full list.)\n' \
      "$modified_count" "$added_count" "$removed_count"
  fi
} > "$REVIEW_DIR/freshness-summary.md"

echo "✓ $REVIEW_DIR/freshness.json (verdict=$verdict +$added_count ~$modified_count -$removed_count)"
exit 0
