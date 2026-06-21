#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# density.sh —— Q9b code-density audit per Section.
#
# Counts <CodeBlock> JSX tags, lines per block, <P> paragraphs, and the
# character share devoted to CodeBlock content. Enforces:
#
#   blockCount               ≤ 1 (Sections 04 / 05 may use ≤ 2)
#   linesPerBlock            ≤ 8
#   blockToParagraphRatio    ≤ 0.15
#   codeCharShare            ≤ 0.15
#
# Mermaid blocks (<Mermaid> or <Raw>) are NOT counted as <CodeBlock>.
#
# Usage:
#   bash density.sh --workspace <path> --section <NN>
#   bash density.sh --workspace <path> --all
#   bash density.sh --help
#
# Outputs:
#   review/density.json          (single section)        when --section used
#   review/density.json          (array of all sections) when --all used
#
# Exit 0 if pass; 1 if any section fails (--all) or the single section fails.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,24p' "$0"
}

WORKSPACE=""
SECTION=""
ALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)     usage; exit 0 ;;
    --workspace)   shift; WORKSPACE="${1:-}" ;;
    --workspace=*) WORKSPACE="${1#--workspace=}" ;;
    --section)     shift; SECTION="${1:-}" ;;
    --section=*)   SECTION="${1#--section=}" ;;
    --all)         ALL=1 ;;
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
REVIEW_DIR="$WORKSPACE/review"
mkdir -p "$REVIEW_DIR"

# ── Helpers ─────────────────────────────────────────────────
js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

find_section_tsx() {
  local nn="$1"
  local f
  for f in "$SECTIONS_DIR/${nn}-"*.tsx; do
    [[ -f "$f" ]] && { printf '%s' "$f"; return 0; }
  done
  return 1
}

# Determine per-section caps. Sections 04 / 05 allow 2 blocks; others 1.
block_cap_for() {
  local nn="$1"
  case "$nn" in
    04|05) echo 2 ;;
    *)     echo 1 ;;
  esac
}

# Audit one section. Emits one JSON object to stdout (no trailing newline tweaks).
audit_one() {
  local nn="$1"
  local tsx
  if ! tsx="$(find_section_tsx "$nn")"; then
    printf '{"section":"%s","error":"no tsx file","verdict":"fail","violations":["section file not found"]}' "$(js_escape "$nn")"
    return 1
  fi

  local cap; cap="$(block_cap_for "$nn")"

  # Use awk to compute everything in one pass.
  # We track:
  #   - block_count: number of <CodeBlock ...> opening tags
  #   - block_lines[]: per-block line counts (lines inside CodeBlock children)
  #   - paragraph_count: number of <P> opening tags
  #   - total_chars: total non-tag characters in the file
  #   - code_chars: characters inside CodeBlock blocks (children only)
  local stats
  stats="$(awk '
    BEGIN {
      block_count = 0; block_lines = 0; in_block = 0; this_block_lines = 0;
      paragraph_count = 0; total_chars = 0; code_chars = 0;
      blocks_csv = "";
    }
    {
      raw_line = $0
      total_chars += length(raw_line)
      # Count <P> opens (excluding closing </P>)
      n = 0; tmp = raw_line
      while (match(tmp, /<P[ >]/)) {
        n += 1; tmp = substr(tmp, RSTART + RLENGTH)
      }
      paragraph_count += n
      # Count <CodeBlock> opens. Use a generous match so multi-line attribute
      # lists still register.
      o = 0; tmp = raw_line
      while (match(tmp, /<CodeBlock[ >]/)) {
        o += 1; tmp = substr(tmp, RSTART + RLENGTH)
      }
      # Close tags
      c = 0; tmp = raw_line
      while (match(tmp, /<\/CodeBlock>/)) {
        c += 1; tmp = substr(tmp, RSTART + RLENGTH)
      }
      # Self-closing <CodeBlock ... /> count once as block but no body lines.
      sc = 0; tmp = raw_line
      while (match(tmp, /<CodeBlock[^>]*\/>/)) {
        sc += 1; tmp = substr(tmp, RSTART + RLENGTH)
      }
      block_count += o
      block_count += sc
      # Track body lines for non-self-closing blocks
      for (i = 0; i < o - sc; i++) {
        in_block += 1
      }
      if (in_block > 0) {
        # We are inside (or starting/ending) a block. Count this line content
        # as code_chars and (if mid-block) as block body line.
        code_chars += length(raw_line)
        if (in_block > 0 && o == 0 && c == 0) {
          this_block_lines += 1
        }
      }
      for (i = 0; i < c; i++) {
        if (this_block_lines > 0) {
          if (blocks_csv == "") blocks_csv = this_block_lines
          else blocks_csv = blocks_csv "," this_block_lines
        } else {
          if (blocks_csv == "") blocks_csv = 0
          else blocks_csv = blocks_csv "," 0
        }
        this_block_lines = 0
        in_block -= 1
        if (in_block < 0) in_block = 0
      }
    }
    END {
      print block_count "|" paragraph_count "|" total_chars "|" code_chars "|" blocks_csv
    }
  ' "$tsx")"

  local block_count paragraph_count total_chars code_chars blocks_csv
  IFS='|' read -r block_count paragraph_count total_chars code_chars blocks_csv <<< "$stats"
  [[ -z "$block_count" ]] && block_count=0
  [[ -z "$paragraph_count" ]] && paragraph_count=0
  [[ -z "$total_chars" ]] && total_chars=0
  [[ -z "$code_chars" ]] && code_chars=0

  # Build block_lines JSON
  local block_lines_json="["
  if [[ -n "$blocks_csv" ]]; then
    block_lines_json="[$blocks_csv]"
  else
    block_lines_json="[]"
  fi

  # Ratios
  local ratio="0.00"
  if [[ "$paragraph_count" -gt 0 ]]; then
    ratio="$(awk -v b="$block_count" -v p="$paragraph_count" 'BEGIN { printf "%.3f", b/p }')"
  fi
  local share="0.00"
  if [[ "$total_chars" -gt 0 ]]; then
    share="$(awk -v c="$code_chars" -v t="$total_chars" 'BEGIN { printf "%.3f", c/t }')"
  fi

  # Violations
  local violations=()
  if [[ "$block_count" -gt "$cap" ]]; then
    violations+=("blockCount=$block_count > cap=$cap")
  fi
  # Per-block line counts
  if [[ -n "$blocks_csv" ]]; then
    local idx=1
    IFS=',' read -r -a parts <<< "$blocks_csv"
    for n in "${parts[@]}"; do
      if [[ "$n" -gt 8 ]]; then
        violations+=("block[$idx] lines=$n > 8")
      fi
      idx=$((idx + 1))
    done
  fi
  if awk -v r="$ratio" 'BEGIN { exit (r > 0.15) ? 0 : 1 }'; then
    violations+=("blockToParagraphRatio=$ratio > 0.15")
  fi
  if awk -v s="$share" 'BEGIN { exit (s > 0.15) ? 0 : 1 }'; then
    violations+=("codeCharShare=$share > 0.15")
  fi

  local verdict="pass"
  [[ "${#violations[@]}" -gt 0 ]] && verdict="fail"

  # violations JSON
  local v_json="[" vfirst=1
  for v in "${violations[@]}"; do
    if [[ $vfirst -eq 1 ]]; then vfirst=0; else v_json="$v_json,"; fi
    v_json="$v_json\"$(js_escape "$v")\""
  done
  v_json="$v_json]"

  printf '{"section":"%s","tsx":"%s","blockCount":%d,"blockCap":%d,"blockLines":%s,"paragraphCount":%d,"blockToParagraphRatio":%s,"codeCharShare":%s,"totalChars":%d,"codeChars":%d,"verdict":"%s","violations":%s}' \
    "$(js_escape "$nn")" "$(js_escape "$tsx")" \
    "$block_count" "$cap" "$block_lines_json" "$paragraph_count" \
    "$ratio" "$share" "$total_chars" "$code_chars" \
    "$verdict" "$v_json"

  [[ "$verdict" == "pass" ]] && return 0 || return 1
}

# ── Main ────────────────────────────────────────────────────
OUT="$REVIEW_DIR/density.json"
overall=0

if [[ "$ALL" == 1 ]]; then
  printf '{\n  "sections": [\n' > "$OUT"
  first=1
  for tsx in "$SECTIONS_DIR"/*.tsx; do
    [[ -f "$tsx" ]] || continue
    base="$(basename "$tsx")"
    nn="${base%%-*}"
    [[ -z "$nn" ]] && continue
    obj="$(audit_one "$nn")" || overall=1
    if [[ $first -eq 1 ]]; then first=0; else printf ',\n' >> "$OUT"; fi
    printf '    %s' "$obj" >> "$OUT"
  done
  overall_verdict="pass"
  [[ "$overall" != 0 ]] && overall_verdict="fail"
  printf '\n  ],\n  "verdict": "%s",\n  "snapshot": "%s"\n}\n' \
    "$overall_verdict" "$(date -u +%FT%TZ)" >> "$OUT"
  echo "✓ $OUT (--all, verdict=$overall_verdict)"
else
  obj="$(audit_one "$SECTION")" || overall=1
  {
    printf '{\n  "sections": [\n    %s\n  ],\n  "verdict": "%s",\n  "snapshot": "%s"\n}\n' \
      "$obj" \
      "$([[ "$overall" == 0 ]] && echo pass || echo fail)" \
      "$(date -u +%FT%TZ)"
  } > "$OUT"
  echo "✓ $OUT (section=$SECTION, verdict=$([[ "$overall" == 0 ]] && echo pass || echo fail))"
fi

exit $overall
