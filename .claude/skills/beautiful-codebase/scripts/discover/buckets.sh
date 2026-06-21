#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# buckets.sh —— Split inventory.json into ~5k-LOC buckets.
#
# Reads `<workspace>/discovery/inventory.json` + `tier.json`, applies the
# four-tier size strategy from PRD Q5b / references/bucket-strategy.md, writes
# one JSON file per bucket plus a `_summary.json`.
#
# Usage:
#   bash buckets.sh --workspace <path>
#   bash buckets.sh --help
#
# Size-tier auto-select (analyzedFiles from inventory.stats):
#   < 100         single bucket;                 per-file-verbatim          (3-5 sections)
#   100 - 1000    bucket per top-level dir;       per-file-verbatim          (5-10 sections)
#   1000 - 10000  bucket per codegraph module    entry-files-verbatim       (10-20 sections)
#   > 10000       two-tier (top → submodule);    symbol-summary             (~20 sections)
#
# Each bucket: ~5k LOC target. When codegraph tier unavailable for the
# 1k-10k / >10k tiers, this script degrades gracefully to directory roll-ups
# (and notes that in the bucket JSON as `rationale`).
#
# Output:
#   <workspace>/discovery/buckets/NN-<slug>.json
#   <workspace>/discovery/buckets/_summary.json
#
# Bucket schema:
#   {
#     "id": "bucket-04-auth",
#     "scope": "pkg/auth",
#     "rationale": "directory roll-up | codegraph module | top-level package | two-tier submodule",
#     "files": ["pkg/auth/middleware.go", ...],
#     "loc": 4900,
#     "language": ["go", "python"],
#     "isEntryHeavy": true,
#     "evidenceStrategy": "per-file-verbatim | entry-files-verbatim | symbol-summary"
#   }
#
# _summary.json schema:
#   {
#     "sizeTier":          "<100|100-1k|1k-10k|>10k",
#     "tier":              "<from tier.json>",
#     "analyzedFiles":     980,
#     "totalLoc":          152000,
#     "bucketCount":       12,
#     "bucketStrategy":    "directory-rollup | codegraph-module | two-tier",
#     "evidenceStrategy":  "per-file-verbatim | entry-files-verbatim | symbol-summary",
#     "buckets": ["bucket-01-...", ...]
#   }
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,42p' "$0"
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
INV="$WORKSPACE/discovery/inventory.json"
TIER_JSON="$WORKSPACE/discovery/tier.json"
[[ -f "$INV" ]]      || { echo "✗ missing $INV (run inventory.sh)" >&2;  exit 1; }
[[ -f "$TIER_JSON" ]] || { echo "✗ missing $TIER_JSON (run tier-select.sh)" >&2; exit 1; }

mkdir -p "$WORKSPACE/discovery/buckets"
rm -f "$WORKSPACE/discovery/buckets"/bucket-*.json "$WORKSPACE/discovery/buckets"/_summary.json 2>/dev/null || true

# ── Tier from tier.json (for codegraph awareness) ───────────
TIER="$(tr -d '\n' < "$TIER_JSON" | sed -nE 's/.*"tier"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"

# ── Parse inventory: emit lines `<path>\t<loc>\t<lang>` for analyzed files ──
# Strategy: read entire JSON, extract analyzed file records line-by-line.
parse_analyzed() {
  python_extract="$(cat <<'PY'
import json, sys
data = json.load(open(sys.argv[1], 'r', encoding='utf-8'))
for f in data.get('files', []):
    if f.get('excluded_reason'):
        continue
    print('{}\t{}\t{}'.format(
        f.get('path', ''),
        int(f.get('loc', 0) or 0),
        f.get('language', 'other') or 'other'))
PY
)"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "$python_extract" "$INV"
  elif command -v python >/dev/null 2>&1; then
    python -c "$python_extract" "$INV"
  else
    # Pure-shell fallback: brittle but works for our well-formed output.
    awk '
      /"path"[[:space:]]*:/ {
        match($0, /"path"[[:space:]]*:[[:space:]]*"([^"]*)"/, arr); path = arr[1]
      }
      /"language"[[:space:]]*:/ {
        match($0, /"language"[[:space:]]*:[[:space:]]*"([^"]*)"/, arr); lang = arr[1]
      }
      /"loc"[[:space:]]*:/ {
        match($0, /"loc"[[:space:]]*:[[:space:]]*([0-9]+)/, arr); loc = arr[1]
      }
      /"excluded_reason"[[:space:]]*:/ {
        if ($0 ~ /"excluded_reason"[[:space:]]*:[[:space:]]*null/) {
          if (path != "") print path "\t" loc "\t" lang
        }
        path=""; loc=0; lang=""
      }
    ' "$INV"
  fi
}

# Collect analyzed file entries
ALL_LINES="$(parse_analyzed)"
ANALYZED_FILE_COUNT="$(printf '%s\n' "$ALL_LINES" | awk 'NF>0' | wc -l | tr -d ' ')"
TOTAL_LOC="$(printf '%s\n' "$ALL_LINES" | awk -F'\t' 'NF>=2 {sum+=$2} END {print sum+0}')"

if [[ "$ANALYZED_FILE_COUNT" -eq 0 ]]; then
  echo "✗ inventory has no analyzed files; aborting" >&2
  exit 1
fi

# ── Decide size tier ────────────────────────────────────────
if   [[ $ANALYZED_FILE_COUNT -lt 100 ]];   then SIZE_TIER="<100";    BUCKET_STRATEGY="single";          EVIDENCE_STRATEGY="per-file-verbatim"
elif [[ $ANALYZED_FILE_COUNT -lt 1000 ]];  then SIZE_TIER="100-1k";  BUCKET_STRATEGY="directory-rollup"; EVIDENCE_STRATEGY="per-file-verbatim"
elif [[ $ANALYZED_FILE_COUNT -lt 10000 ]]; then SIZE_TIER="1k-10k";  BUCKET_STRATEGY="codegraph-module"; EVIDENCE_STRATEGY="entry-files-verbatim"
else                                            SIZE_TIER=">10k";    BUCKET_STRATEGY="two-tier";         EVIDENCE_STRATEGY="symbol-summary"
fi

# Lower-tier degrade for codegraph-module strategy
if [[ "$BUCKET_STRATEGY" == "codegraph-module" && "$TIER" != "codegraph-indexed" ]]; then
  BUCKET_STRATEGY="directory-rollup"
fi
if [[ "$BUCKET_STRATEGY" == "two-tier" && "$TIER" != "codegraph-indexed" ]]; then
  BUCKET_STRATEGY="two-tier-directory"  # still two-tier, but by directory levels
fi

# ── Helpers ─────────────────────────────────────────────────
js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

slugify() {
  # Replace / and special chars with -, lowercase, strip leading/trailing -
  local s="$1"
  s="${s//\//-}"
  s="${s//_/-}"
  s="$(printf '%s' "$s" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9.-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
  [[ -z "$s" ]] && s="root"
  printf '%s' "$s"
}

# Decide a file's "scope" by strategy.
scope_of() {
  local strategy="$1" path="$2" depth="$3"  # depth used only for two-tier
  case "$strategy" in
    single) echo "(root)" ;;
    directory-rollup)
      # First directory segment, or `(root)` if no slash
      case "$path" in
        */*) echo "${path%%/*}" ;;
        *)   echo "(root)" ;;
      esac
      ;;
    two-tier-directory)
      # Up to <depth> path components
      local IFS=/ ; read -r -a parts <<< "$path"
      local n="${#parts[@]}"
      if [[ "$n" -le 1 ]]; then
        echo "(root)"
        return
      fi
      local take="$depth"
      [[ "$take" -gt $(( n - 1 )) ]] && take=$(( n - 1 ))
      local out="${parts[0]}"
      for (( i=1; i<take; i++ )); do
        out="$out/${parts[$i]}"
      done
      echo "$out"
      ;;
    codegraph-module)
      # Lower tier should never reach here; fall through to first-segment
      case "$path" in
        */*) echo "${path%%/*}" ;;
        *)   echo "(root)" ;;
      esac
      ;;
  esac
}

# Detect "entry-heavy" buckets via simple filename heuristics; full taxonomy
# lives in entry-point-taxonomy.md but a coarse signal here is enough to flag
# evidence-strategy upgrade for entry-files-verbatim.
is_entry_heavy_file() {
  local path="$1"
  case "$path" in
    *controller*|*Controller*) return 0 ;;
    *handler*|*Handler*)       return 0 ;;
    *route*|*Route*|*router*)  return 0 ;;
    *cmd/*|cmd/*)              return 0 ;;
    main.go|*/main.go|main.py|*/main.py|cli.py|*/cli.py|index.ts|*/index.ts) return 0 ;;
    *webhook*|*Webhook*)       return 0 ;;
    *consumer*|*Consumer*)     return 0 ;;
    *worker*|*Worker*)         return 0 ;;
    *jobs/*|jobs/*)            return 0 ;;
  esac
  return 1
}

# ── Group lines into scopes ─────────────────────────────────
# Build associative-array-free grouping via two parallel arrays:
declare -a SCOPE_KEYS=()
declare -a SCOPE_PATHS=()    # newline-joined file list per scope
declare -a SCOPE_LOC=()
declare -a SCOPE_LANGS=()    # space-joined unique langs
declare -a SCOPE_ENTRY=()    # 0/1

add_to_scope() {
  local key="$1" path="$2" loc="$3" lang="$4" entry="$5"
  local i
  for i in "${!SCOPE_KEYS[@]}"; do
    if [[ "${SCOPE_KEYS[$i]}" == "$key" ]]; then
      SCOPE_PATHS[$i]="${SCOPE_PATHS[$i]}"$'\n'"$path"
      SCOPE_LOC[$i]=$(( SCOPE_LOC[$i] + loc ))
      case " ${SCOPE_LANGS[$i]} " in
        *" $lang "*) ;;
        *) SCOPE_LANGS[$i]="${SCOPE_LANGS[$i]} $lang" ;;
      esac
      if [[ "$entry" == "1" ]]; then SCOPE_ENTRY[$i]=1; fi
      return
    fi
  done
  SCOPE_KEYS+=("$key")
  SCOPE_PATHS+=("$path")
  SCOPE_LOC+=("$loc")
  SCOPE_LANGS+=(" $lang ")
  SCOPE_ENTRY+=("$entry")
}

DEPTH=2  # two-tier-directory depth default
while IFS=$'\t' read -r path loc lang; do
  [[ -z "$path" ]] && continue
  scope="$(scope_of "$BUCKET_STRATEGY" "$path" "$DEPTH")"
  entry=0
  if is_entry_heavy_file "$path"; then entry=1; fi
  add_to_scope "$scope" "$path" "$loc" "$lang" "$entry"
done <<< "$ALL_LINES"

# ── Split oversize scopes into chunks of ~TARGET_LOC ─────────
TARGET_LOC=5000

# Each "bucket draft" gets pushed into the final list with sequential id.
declare -a BUCKETS_SCOPE=()
declare -a BUCKETS_FILES=()
declare -a BUCKETS_LOC=()
declare -a BUCKETS_LANGS=()
declare -a BUCKETS_ENTRY=()

split_scope() {
  local scope="$1" files_block="$2" total_loc="$3" langs="$4" entry="$5"
  if [[ "$total_loc" -le $(( TARGET_LOC * 3 / 2 )) ]]; then
    BUCKETS_SCOPE+=("$scope")
    BUCKETS_FILES+=("$files_block")
    BUCKETS_LOC+=("$total_loc")
    BUCKETS_LANGS+=("$langs")
    BUCKETS_ENTRY+=("$entry")
    return
  fi
  # Walk files line-by-line, greedily filling chunks.
  local chunk_files=""
  local chunk_loc=0
  local part=1
  # Need per-file LOC; re-derive from ALL_LINES by lookup (simpler: keep a
  # tab-delim mini-table per scope by rebuilding from ALL_LINES).
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    # Look up loc for $p from ALL_LINES (one-pass per file is fine at this scale)
    local p_loc
    p_loc="$(printf '%s\n' "$ALL_LINES" | awk -F'\t' -v p="$p" '$1==p {print $2; exit}')"
    [[ -z "$p_loc" ]] && p_loc=0
    if [[ "$chunk_loc" -gt 0 && $(( chunk_loc + p_loc )) -gt $TARGET_LOC ]]; then
      BUCKETS_SCOPE+=("$scope#part$part")
      BUCKETS_FILES+=("$chunk_files")
      BUCKETS_LOC+=("$chunk_loc")
      BUCKETS_LANGS+=("$langs")
      BUCKETS_ENTRY+=("$entry")
      chunk_files=""
      chunk_loc=0
      part=$(( part + 1 ))
    fi
    if [[ -z "$chunk_files" ]]; then chunk_files="$p"; else chunk_files="$chunk_files"$'\n'"$p"; fi
    chunk_loc=$(( chunk_loc + p_loc ))
  done <<< "$files_block"
  if [[ -n "$chunk_files" ]]; then
    BUCKETS_SCOPE+=("$scope#part$part")
    BUCKETS_FILES+=("$chunk_files")
    BUCKETS_LOC+=("$chunk_loc")
    BUCKETS_LANGS+=("$langs")
    BUCKETS_ENTRY+=("$entry")
  fi
}

for i in "${!SCOPE_KEYS[@]}"; do
  split_scope "${SCOPE_KEYS[$i]}" "${SCOPE_PATHS[$i]}" "${SCOPE_LOC[$i]}" "${SCOPE_LANGS[$i]}" "${SCOPE_ENTRY[$i]}"
done

# ── Emit bucket files ───────────────────────────────────────
BUCKET_DIR="$WORKSPACE/discovery/buckets"

# Rationale label per strategy
case "$BUCKET_STRATEGY" in
  single)              RATIONALE="single bucket (project < 100 files)" ;;
  directory-rollup)    RATIONALE="directory roll-up (top-level dir)" ;;
  codegraph-module)    RATIONALE="codegraph module boundary" ;;
  two-tier-directory)  RATIONALE="two-tier directory (depth ${DEPTH}); codegraph module info unavailable" ;;
esac

# Build per-bucket JSON
bucket_ids=()
for i in "${!BUCKETS_SCOPE[@]}"; do
  scope_label="${BUCKETS_SCOPE[$i]}"
  files_block="${BUCKETS_FILES[$i]}"
  loc="${BUCKETS_LOC[$i]}"
  langs_raw="${BUCKETS_LANGS[$i]}"
  entry_flag="${BUCKETS_ENTRY[$i]}"

  idx="$(printf '%02d' $(( i + 1 )))"
  slug="$(slugify "$scope_label")"
  bucket_id="bucket-${idx}-${slug}"
  bucket_ids+=("$bucket_id")
  out_file="$BUCKET_DIR/${bucket_id}.json"

  # Build files JSON array
  files_json="["
  first_f=1
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    if [[ $first_f -eq 1 ]]; then first_f=0; else files_json="$files_json, "; fi
    files_json="$files_json\"$(js_escape "$p")\""
  done <<< "$files_block"
  files_json="$files_json]"

  # Languages JSON array (dedup + sorted)
  langs_json="["
  first_l=1
  for l in $(printf '%s' "$langs_raw" | tr ' ' '\n' | awk 'NF>0' | sort -u); do
    if [[ $first_l -eq 1 ]]; then first_l=0; else langs_json="$langs_json, "; fi
    langs_json="$langs_json\"$(js_escape "$l")\""
  done
  langs_json="$langs_json]"

  entry_bool=$([[ "$entry_flag" == "1" ]] && echo true || echo false)

  cat > "$out_file" <<EOF
{
  "id": "$bucket_id",
  "scope": "$(js_escape "$scope_label")",
  "rationale": "$(js_escape "$RATIONALE")",
  "files": $files_json,
  "loc": $loc,
  "language": $langs_json,
  "isEntryHeavy": $entry_bool,
  "evidenceStrategy": "$EVIDENCE_STRATEGY"
}
EOF
done

# ── Emit _summary.json ─────────────────────────────────────
SUM="$BUCKET_DIR/_summary.json"
{
  printf '{\n'
  printf '  "sizeTier": "%s",\n' "$SIZE_TIER"
  printf '  "tier": "%s",\n' "$(js_escape "$TIER")"
  printf '  "analyzedFiles": %d,\n' "$ANALYZED_FILE_COUNT"
  printf '  "totalLoc": %d,\n' "$TOTAL_LOC"
  printf '  "bucketCount": %d,\n' "${#bucket_ids[@]}"
  printf '  "bucketStrategy": "%s",\n' "$BUCKET_STRATEGY"
  printf '  "evidenceStrategy": "%s",\n' "$EVIDENCE_STRATEGY"
  printf '  "buckets": ['
  for i in "${!bucket_ids[@]}"; do
    if [[ $i -gt 0 ]]; then printf ', '; fi
    printf '"%s"' "${bucket_ids[$i]}"
  done
  printf ']\n'
  printf '}\n'
} > "$SUM"

# Write size tier also into a top-level discovery/tier.json companion if not
# already in tier.json. We don't overwrite tier.json — instead add a sibling
# `size-tier.json` for downstream scripts that want a one-liner.
SIZE_TIER_FILE="$WORKSPACE/discovery/size-tier.json"
cat > "$SIZE_TIER_FILE" <<EOF
{
  "sizeTier": "$SIZE_TIER",
  "analyzedFiles": $ANALYZED_FILE_COUNT,
  "bucketCount": ${#bucket_ids[@]},
  "evidenceStrategy": "$EVIDENCE_STRATEGY",
  "bucketStrategy": "$BUCKET_STRATEGY"
}
EOF

echo "✓ wrote ${#bucket_ids[@]} buckets to $BUCKET_DIR/ (sizeTier=$SIZE_TIER strategy=$BUCKET_STRATEGY)"
echo "✓ wrote $SUM"
echo "✓ wrote $SIZE_TIER_FILE"
