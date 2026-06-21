#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# source-pointers-gen.sh —— Build NN-pointers.json from evidence + business.
#
# Walks article/sections/<NN>-evidence.md and article/sections/<NN>-business.md,
# extracts every `file:line[-line]` reference, dedupes, sorts by (file, line),
# and writes article/sections/<NN>-pointers.json that the Section component
# imports and passes to <SourcePointers pointers={...} />.
#
# Pointer extraction rules:
#   - evidence.md: standalone heading-style "filename:line[-line]" lines
#     (matching the convention in references/source-pointers.md §1).
#   - business.md: in-prose markers "[证据: file:line[-line]]" (Chinese)
#     and "[evidence: file:line[-line]]" (English fallback).
#
# Same file:line in both → role: "evidence" wins (technical source = ground truth).
#
# Usage:
#   bash source-pointers-gen.sh --workspace <path> --section <NN> [--allow-empty]
#   bash source-pointers-gen.sh --workspace <path> --all          [--allow-empty]
#   bash source-pointers-gen.sh --help
#
# Outputs:
#   article/sections/<NN>-pointers.json   per section
#
# Schema:
#   {
#     "section": "04",
#     "pointers": [
#       {"file": "src/svc/order.go", "line": 42, "endLine": 78, "role": "evidence"},
#       {"file": "tests/...",        "line": 31, "label": "...", "role": "business"},
#       ...
#     ]
#   }
#
# Exit 0 if non-empty (or --allow-empty was passed); 1 if empty without that
# flag (signals that the section likely missed pointer collection unless it
# is a pure-intro / colophon section).
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,33p' "$0"
}

WORKSPACE=""
SECTION=""
ALL=0
ALLOW_EMPTY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)       usage; exit 0 ;;
    --workspace)     shift; WORKSPACE="${1:-}" ;;
    --workspace=*)   WORKSPACE="${1#--workspace=}" ;;
    --section)       shift; SECTION="${1:-}" ;;
    --section=*)     SECTION="${1#--section=}" ;;
    --all)           ALL=1 ;;
    --allow-empty)   ALLOW_EMPTY=1 ;;
    *) echo "✗ unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$WORKSPACE" ]]; then
  echo "✗ --workspace <path> is required" >&2; exit 1
fi
if [[ "$ALL" == 0 && -z "$SECTION" ]]; then
  echo "✗ pass --section <NN> or --all" >&2; exit 1
fi

SECTIONS_DIR="$WORKSPACE/article/sections"
if [[ ! -d "$SECTIONS_DIR" ]]; then
  echo "✗ sections directory not found: $SECTIONS_DIR" >&2; exit 1
fi

# ── Helpers ─────────────────────────────────────────────────
js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# Extract evidence pointers from <NN>-evidence.md.
# Heuristic: lines matching the pattern <path>:<start>[-<end>] standalone,
# OR appearing right before a ``` code fence.
extract_evidence_pointers() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  # Standalone heading-style references
  grep -oE '[A-Za-z0-9_./-]+\.[A-Za-z0-9_./-]+:[0-9]+(-[0-9]+)?' "$file" 2>/dev/null \
    | awk '{ print "evidence\t" $0 }'
}

# Extract business pointers from <NN>-business.md.
# Pattern: [证据: file:line] or [evidence: file:line]
extract_business_pointers() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  # Use a single regex that matches both Chinese and English markers.
  # grep -oE prints only the matched part. The character before "证据" varies
  # in length (multibyte) so we use a permissive prefix match.
  grep -oE '\[(证据|evidence)[^]]*\]' "$file" 2>/dev/null \
    | grep -oE '[A-Za-z0-9_./-]+\.[A-Za-z0-9_./-]+:[0-9]+(-[0-9]+)?' 2>/dev/null \
    | awk '{ print "business\t" $0 }'
}

# Audit/build pointers for one section. Returns 0 if non-empty (or allow-empty),
# 1 if empty without allow-empty.
build_one() {
  local nn="$1"
  local evidence="$SECTIONS_DIR/${nn}-evidence.md"
  local business="$SECTIONS_DIR/${nn}-business.md"
  local out="$SECTIONS_DIR/${nn}-pointers.json"

  # Collect "role\tfile:lines" rows
  local raw_rows
  raw_rows="$( { extract_evidence_pointers "$evidence"; extract_business_pointers "$business"; } )"

  # Dedupe with evidence priority: if the same file:lines appears as both
  # roles, evidence wins (sort puts "business" alphabetically before "evidence",
  # so we sort -u by file:lines, then prefer the evidence row).
  local dedup
  dedup="$(printf '%s\n' "$raw_rows" | awk -F'\t' '
    NF == 2 && $2 != "" {
      key = $2
      if (!(key in role) || role[key] == "business") {
        role[key] = $1
      }
    }
    END {
      for (k in role) print role[k] "\t" k
    }
  ' | sort -t$'\t' -k2,2)"

  local count=0
  local items_json="" first=1
  while IFS=$'\t' read -r role spec; do
    [[ -z "$role" || -z "$spec" ]] && continue
    local file_part line_part start end
    file_part="${spec%%:*}"
    line_part="${spec#*:}"
    if [[ "$line_part" == *-* ]]; then
      start="${line_part%%-*}"
      end="${line_part##*-}"
    else
      start="$line_part"
      end=""
    fi
    # Validate numeric
    if ! [[ "$start" =~ ^[0-9]+$ ]]; then continue; fi
    if [[ $first -eq 1 ]]; then first=0; else items_json="$items_json,"; fi
    if [[ -n "$end" ]]; then
      items_json="$items_json{\"file\": \"$(js_escape "$file_part")\", \"line\": $start, \"endLine\": $end, \"role\": \"$role\"}"
    else
      items_json="$items_json{\"file\": \"$(js_escape "$file_part")\", \"line\": $start, \"role\": \"$role\"}"
    fi
    count=$((count + 1))
  done <<< "$dedup"

  # Sort items by (file, line) — already done above by sort.
  cat > "$out" <<EOF
{
  "section": "$(js_escape "$nn")",
  "pointers": [$items_json],
  "count": $count,
  "snapshot": "$(date -u +%FT%TZ)"
}
EOF

  echo "✓ $out (count=$count)"

  if [[ "$count" -eq 0 && "$ALLOW_EMPTY" == 0 ]]; then
    echo "  ⚠ pointers empty; pass --allow-empty for pure-intro/colophon sections" >&2
    return 1
  fi
  return 0
}

# ── Main ────────────────────────────────────────────────────
overall=0
declare -A SEEN=()
if [[ "$ALL" == 1 ]]; then
  for ev in "$SECTIONS_DIR"/*-evidence.md "$SECTIONS_DIR"/*-business.md; do
    [[ -f "$ev" ]] || continue
    base="$(basename "$ev")"
    nn="${base%%-*}"
    [[ -z "$nn" ]] && continue
    if [[ -z "${SEEN[$nn]:-}" ]]; then
      SEEN[$nn]=1
      build_one "$nn" || overall=1
    fi
  done
  # Fallback: if no evidence/business found, walk .tsx files.
  if [[ "${#SEEN[@]}" -eq 0 ]]; then
    for tsx in "$SECTIONS_DIR"/*.tsx; do
      [[ -f "$tsx" ]] || continue
      base="$(basename "$tsx")"
      nn="${base%%-*}"
      [[ -z "$nn" ]] && continue
      [[ -n "${SEEN[$nn]:-}" ]] && continue
      SEEN[$nn]=1
      build_one "$nn" || overall=1
    done
  fi
else
  build_one "$SECTION" || overall=1
fi

exit $overall
