#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# claim-trace.sh —— Audit a Section's prose claims against its evidence.
#
# Samples N (default 5) factual claims from a rendered section .tsx, then:
#   1. Extracts identifier-class tokens (file paths, ClassName, methodName,
#      camelCase / snake_case / PascalCase identifiers) from each claim.
#   2. Verifies ≥ 60% of those tokens are mentioned somewhere in the
#      section's <NN>-evidence.md or <NN>-business.md.
#   3. For every `file:line[-line]` excerpt block in the evidence file,
#      re-greps the repo at that path to confirm the verbatim first line of
#      the excerpt still matches (catches "Step A ran, then someone edited
#      the file" evidence drift).
#
# Exit 0 if all sampled sections pass; 1 if any section has a claim with
# hitRate < 0.6 OR any evidence excerpt drifted.
#
# Usage:
#   bash claim-trace.sh --workspace <path> --section <NN> [--samples <N>] [--seed <hex>]
#   bash claim-trace.sh --workspace <path> --all          [--samples <N>] [--seed <hex>]
#   bash claim-trace.sh --help
#
# Outputs:
#   review/claim-trace-<NN>.json   per-section report
#
# Schema:
#   {
#     "section": "04",
#     "samples": [
#       {"line": "<verbatim prose line>", "tokens": ["..."],
#        "hits":  ["..."], "hitRate": 1.0, "verdict": "pass"|"fail"},
#       ...
#     ],
#     "evidence_drift": [
#       {"file": "src/...", "lines": "42-78", "issue": "first line differs"}
#     ],
#     "verdict": "pass" | "fail",
#     "fix_hints": ["..."]
#   }
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,33p' "$0"
}

WORKSPACE=""
SECTION=""
ALL=0
SAMPLES=5
SEED=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)        usage; exit 0 ;;
    --workspace)      shift; WORKSPACE="${1:-}" ;;
    --workspace=*)    WORKSPACE="${1#--workspace=}" ;;
    --section)        shift; SECTION="${1:-}" ;;
    --section=*)      SECTION="${1#--section=}" ;;
    --all)            ALL=1 ;;
    --samples)        shift; SAMPLES="${1:-5}" ;;
    --samples=*)      SAMPLES="${1#--samples=}" ;;
    --seed)           shift; SEED="${1:-}" ;;
    --seed=*)         SEED="${1#--seed=}" ;;
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
REVIEW_DIR="$WORKSPACE/review"
mkdir -p "$REVIEW_DIR"

# ── Tier-agnostic search ────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/query.sh" 2>/dev/null || true

# Try to fish target out of tier.json so verbatim re-grep can resolve files.
TIER_JSON="$WORKSPACE/discovery/tier.json"
TARGET=""
if [[ -f "$TIER_JSON" ]]; then
  TARGET="$(tr -d '\n' < "$TIER_JSON" | sed -nE 's/.*"target"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
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

# Find section file (NN-<slug>.tsx) given NN.
find_section_tsx() {
  local nn="$1"
  local f
  for f in "$SECTIONS_DIR/${nn}-"*.tsx; do
    [[ -f "$f" ]] && { printf '%s' "$f"; return 0; }
  done
  return 1
}

# Extract prose lines from a .tsx: lines wrapped by <P>, <Quote>, <Callout>,
# Best-effort: also catch top-level string children of <Section>.
extract_prose() {
  local tsx="$1"
  # Match between <P>...</P>, <Quote>...</Quote>, <Callout>...</Callout>
  # Use a simple grep for opening tag, then strip JSX wrappers.
  grep -nE '<(P|Quote|Callout)[^>]*>' "$tsx" 2>/dev/null \
    | sed -E 's/[[:space:]]*<\/?(P|Quote|Callout)[^>]*>//g' \
    | sed -E 's/^[[:space:]]+//' \
    | sed -E 's/\{[^}]*\}//g' \
    | awk -F: '{ if (length($0) > 0) { line=$1; $1=""; sub(/^:/, "", $0); print line ":" $0 } }' \
    | awk -F: 'length($0) > 20 { print }'
}

# Extract identifier-class tokens from a prose line.
# Heuristic: words with CamelCase, snake_case, kebab-case, dotted paths, or
# strings containing a slash (file paths) and a dot extension.
extract_tokens() {
  local line="$1"
  printf '%s' "$line" \
    | tr -c 'A-Za-z0-9._/-' '\n' \
    | sed -E 's/[._-]+$//; s/^[._-]+//' \
    | awk '
      length($0) >= 3 {
        # PascalCase or camelCase (mixed case)
        if ($0 ~ /[a-z][A-Z]/ || $0 ~ /^[A-Z][a-z]+[A-Z]/) print
        # snake_case
        else if ($0 ~ /_/) print
        # Path with dot extension
        else if ($0 ~ /\./ && $0 ~ /\//) print
        # Dotted method (Class.method)
        else if ($0 ~ /\./ && $0 ~ /^[A-Za-z]+\.[a-zA-Z_]/) print
        # ALL_CAPS const
        else if ($0 ~ /^[A-Z][A-Z0-9_]+$/ && length($0) >= 4) print
      }' \
    | sort -u
}

# Check token presence in evidence + business files.
token_in_evidence() {
  local token="$1" evidence="$2" business="$3"
  if [[ -f "$evidence" ]] && grep -qF -- "$token" "$evidence"; then return 0; fi
  if [[ -f "$business" ]] && grep -qF -- "$token" "$business"; then return 0; fi
  return 1
}

# Deterministic pseudo-random pick of N lines from stdin given a SHA seed.
# We seed awk's srand via tail+head order with a deterministic shuffle.
pick_n() {
  local n="$1" seed="$2"
  awk -v n="$n" -v seed="$seed" '
    BEGIN {
      # Compute a numeric seed from string (sum chars)
      s = 0; for (i = 1; i <= length(seed); i++) s += (i * 31 + (substr(seed, i, 1) ~ /./ ? 1 : 0));
      srand(s == 0 ? 1 : s);
    }
    { lines[NR] = $0 }
    END {
      total = NR;
      if (total == 0) exit 0;
      # Knuth shuffle indices
      for (i = 1; i <= total; i++) idx[i] = i;
      for (i = total; i > 1; i--) {
        j = int(rand() * i) + 1;
        tmp = idx[i]; idx[i] = idx[j]; idx[j] = tmp;
      }
      take = (n < total ? n : total);
      for (i = 1; i <= take; i++) print lines[idx[i]];
    }
  '
}

# Re-grep an evidence file:line excerpt to detect drift.
# Evidence excerpts use markdown headings like "src/foo.go:42-78" followed by
# a code fence with the verbatim block. We sample the FIRST non-blank line
# inside the fence as the canary.
check_evidence_drift() {
  local evidence_md="$1"
  local target="$2"
  local drifts=""
  [[ ! -f "$evidence_md" ]] && return 0
  [[ -z "$target" || ! -d "$target" ]] && return 0

  # Parse: lines like "filename:line[-line]" optionally followed by a code fence.
  # We use awk to walk: track current pointer when we see a header line,
  # then capture the first line inside the next ``` block.
  awk '
    /^[[:space:]]*[A-Za-z0-9_./-]+:[0-9]+(-[0-9]+)?[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0);
      pointer = $0;
      next;
    }
    /^[[:space:]]*```/ {
      if (pointer != "" && infence == 0) {
        infence = 1; captured = 0;
      } else if (infence == 1) {
        infence = 0; pointer = "";
      }
      next;
    }
    infence == 1 && captured == 0 {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0);
      if (length($0) > 0) {
        print pointer "\t" $0;
        captured = 1;
      }
    }
  ' "$evidence_md" | while IFS=$'\t' read -r ptr first; do
    [[ -z "$ptr" || -z "$first" ]] && continue
    local file="${ptr%%:*}"
    local rest="${ptr#*:}"
    local start="${rest%%-*}"
    local abs="$target/$file"
    [[ ! -f "$abs" ]] && { echo "${ptr}|missing"; continue; }
    local actual
    actual="$(sed -n "${start}p" "$abs" 2>/dev/null || true)"
    actual="$(printf '%s' "$actual" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    local expected
    expected="$(printf '%s' "$first" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    if [[ "$actual" != "$expected" ]]; then
      echo "${ptr}|drift"
    fi
  done
}

# ── Audit one section ───────────────────────────────────────
audit_one() {
  local nn="$1"
  local tsx
  if ! tsx="$(find_section_tsx "$nn")"; then
    echo "✗ no section .tsx for NN=$nn" >&2
    return 1
  fi
  local evidence="$SECTIONS_DIR/${nn}-evidence.md"
  local business="$SECTIONS_DIR/${nn}-business.md"

  local seed="${SEED:-$(sha1sum "$tsx" 2>/dev/null | awk '{print $1}')}"
  [[ -z "$seed" ]] && seed="default"

  # Pick N prose lines
  local prose_lines
  prose_lines="$(extract_prose "$tsx" | pick_n "$SAMPLES" "$seed")"

  local out="$REVIEW_DIR/claim-trace-${nn}.json"
  local samples_json="[" first=1
  local section_verdict="pass"
  local fix_hints=()

  if [[ -z "$prose_lines" ]]; then
    samples_json="$samples_json"  # empty
  else
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      # entry format: "<linenum>:<text>"
      local linenum="${entry%%:*}"
      local text="${entry#*:}"
      local tokens
      tokens="$(extract_tokens "$text")"
      local total=0 hit=0
      local tokens_json="[" hits_json="["
      local tfirst=1 hfirst=1
      while IFS= read -r tok; do
        [[ -z "$tok" ]] && continue
        total=$((total + 1))
        if [[ $tfirst -eq 1 ]]; then tfirst=0; else tokens_json="$tokens_json,"; fi
        tokens_json="$tokens_json\"$(js_escape "$tok")\""
        if token_in_evidence "$tok" "$evidence" "$business"; then
          hit=$((hit + 1))
          if [[ $hfirst -eq 1 ]]; then hfirst=0; else hits_json="$hits_json,"; fi
          hits_json="$hits_json\"$(js_escape "$tok")\""
        fi
      done <<< "$tokens"
      tokens_json="$tokens_json]"
      hits_json="$hits_json]"
      local rate="0.0" verdict="pass"
      if [[ $total -gt 0 ]]; then
        rate="$(awk -v h=$hit -v t=$total 'BEGIN { printf "%.2f", h/t }')"
      fi
      if [[ $total -eq 0 ]]; then
        # No identifier tokens — claim is generic prose, can't audit. Pass.
        verdict="skip"
      elif awk -v r="$rate" 'BEGIN { exit (r >= 0.6) ? 0 : 1 }'; then
        verdict="pass"
      else
        verdict="fail"
        section_verdict="fail"
        fix_hints+=("line ${linenum}: hitRate ${rate} (${hit}/${total}); add citation to evidence.md or rewrite to use identifiers that exist there")
      fi
      if [[ $first -eq 1 ]]; then first=0; else samples_json="$samples_json,"; fi
      samples_json="$samples_json{\"line\": \"$(js_escape "$text")\", \"sourceLine\": $linenum, \"tokens\": $tokens_json, \"hits\": $hits_json, \"hitRate\": $rate, \"verdict\": \"$verdict\"}"
    done <<< "$prose_lines"
  fi
  samples_json="$samples_json]"

  # Evidence drift
  local drift_json="[" dfirst=1
  while IFS='|' read -r ptr issue; do
    [[ -z "$ptr" ]] && continue
    local file="${ptr%%:*}"
    local rest="${ptr#*:}"
    if [[ $dfirst -eq 1 ]]; then dfirst=0; else drift_json="$drift_json,"; fi
    drift_json="$drift_json{\"file\": \"$(js_escape "$file")\", \"lines\": \"$(js_escape "$rest")\", \"issue\": \"$(js_escape "$issue")\"}"
    section_verdict="fail"
    fix_hints+=("evidence drift at ${ptr}: re-run Step A Evidence SubAgent to refresh ${nn}-evidence.md")
  done < <(check_evidence_drift "$evidence" "$TARGET")
  drift_json="$drift_json]"

  # Fix hints JSON
  local hints_json="[" hfirst=1
  for h in "${fix_hints[@]}"; do
    if [[ $hfirst -eq 1 ]]; then hfirst=0; else hints_json="$hints_json,"; fi
    hints_json="$hints_json\"$(js_escape "$h")\""
  done
  hints_json="$hints_json]"

  cat > "$out" <<EOF
{
  "section": "$(js_escape "$nn")",
  "tsx": "$(js_escape "$tsx")",
  "samples": $samples_json,
  "evidence_drift": $drift_json,
  "verdict": "$section_verdict",
  "fix_hints": $hints_json,
  "snapshot": "$(date -u +%FT%TZ)"
}
EOF
  echo "✓ $out (verdict=$section_verdict)"

  [[ "$section_verdict" == "pass" ]] && return 0 || return 1
}

# ── Main ────────────────────────────────────────────────────
overall=0
if [[ "$ALL" == 1 ]]; then
  for tsx in "$SECTIONS_DIR"/*.tsx; do
    [[ -f "$tsx" ]] || continue
    base="$(basename "$tsx")"
    nn="${base%%-*}"
    [[ -z "$nn" ]] && continue
    audit_one "$nn" || overall=1
  done
else
  audit_one "$SECTION" || overall=1
fi

exit $overall
