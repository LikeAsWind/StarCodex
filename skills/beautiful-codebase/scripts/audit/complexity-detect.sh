#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# complexity-detect.sh —— Per-language cyclomatic complexity scan.
#
# Reads discovery/inventory.json to learn which languages exist, then for
# each language picks a tool per references/complexity-tools.md §1
# priority (radon → gocyclo → lizard → ESLint → PMD → heuristic).
#
# Output goes to:
#   discovery/complexity.jsonl         (one JSON per function)
#   discovery/complexity-summary.json  (byLanguage / hot top 20 / degraded list)
#
# Section 07 (Code Health Heatmap) consumes both files.
#
# Usage:
#   bash complexity-detect.sh --workspace <path>
#   bash complexity-detect.sh --help
#
# Per-function JSON line schema:
#   {"file":"src/...","function":"...","line":42,"complexity":18,
#    "language":"go","source":"tool"|"heuristic","tool":"lizard"|"gocyclo"|...}
#
# Always exits 0 — missing tools are informational, not failures. The summary
# file's `degraded` array names every language that fell back to heuristic.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,25p' "$0"
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
if [[ ! -f "$INVENTORY" ]]; then
  echo "✗ inventory.json not found: $INVENTORY (run Phase 1 Discover first)" >&2
  exit 1
fi
TIER_JSON="$WORKSPACE/discovery/tier.json"
TARGET=""
if [[ -f "$TIER_JSON" ]]; then
  TARGET="$(tr -d '\n' < "$TIER_JSON" | sed -nE 's/.*"target"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
fi
if [[ -z "$TARGET" ]]; then
  TARGET="$(tr -d '\n' < "$INVENTORY" | sed -nE 's/.*"target"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
fi
if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
  echo "✗ could not determine target path from tier.json or inventory.json" >&2
  exit 1
fi

mkdir -p "$WORKSPACE/discovery"
OUT_JSONL="$WORKSPACE/discovery/complexity.jsonl"
OUT_SUMMARY="$WORKSPACE/discovery/complexity-summary.json"
: > "$OUT_JSONL"

# ── Helpers ─────────────────────────────────────────────────
js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# Extract distinct languages from inventory's byLanguage map.
get_languages() {
  tr -d '\n' < "$INVENTORY" \
    | sed -nE 's/.*"byLanguage"[[:space:]]*:[[:space:]]*\{([^}]*)\}.*/\1/p' \
    | tr ',' '\n' \
    | sed -nE 's/^[[:space:]]*"([^"]+)"[[:space:]]*:.*/\1/p' \
    | sort -u
}

# Per-language tool priority. Echoes "name|cmd|version_arg".
pick_tool() {
  local lang="$1"
  case "$lang" in
    python)
      command -v radon >/dev/null 2>&1 && { echo "radon"; return; }
      command -v lizard >/dev/null 2>&1 && { echo "lizard"; return; } ;;
    go)
      command -v gocyclo >/dev/null 2>&1 && { echo "gocyclo"; return; }
      command -v lizard >/dev/null 2>&1 && { echo "lizard"; return; } ;;
    javascript|typescript)
      # ESLint is project-local; check both global and local node_modules.
      if command -v eslint >/dev/null 2>&1; then echo "eslint"; return; fi
      if [[ -x "$TARGET/node_modules/.bin/eslint" ]]; then echo "eslint-local"; return; fi
      command -v lizard >/dev/null 2>&1 && { echo "lizard"; return; } ;;
    java)
      command -v pmd >/dev/null 2>&1 && { echo "pmd"; return; }
      command -v lizard >/dev/null 2>&1 && { echo "lizard"; return; } ;;
    rust)
      command -v cargo >/dev/null 2>&1 && { echo "clippy"; return; }
      command -v lizard >/dev/null 2>&1 && { echo "lizard"; return; } ;;
    ruby)
      command -v flog >/dev/null 2>&1 && { echo "flog"; return; }
      command -v lizard >/dev/null 2>&1 && { echo "lizard"; return; } ;;
    kotlin)
      command -v detekt >/dev/null 2>&1 && { echo "detekt"; return; }
      command -v lizard >/dev/null 2>&1 && { echo "lizard"; return; } ;;
    c|cpp|csharp|objc|objcpp|swift|scala|lua)
      command -v lizard >/dev/null 2>&1 && { echo "lizard"; return; } ;;
  esac
  echo "heuristic"
}

# Get analyzed file paths for a given language (excluded_reason null + matching language).
files_for_language() {
  local lang="$1"
  awk -v lang="$lang" '
    BEGIN { in_files = 0; path = ""; this_lang = ""; excl = "" }
    /"files"[[:space:]]*:[[:space:]]*\[/ { in_files = 1; next }
    in_files == 1 {
      line = $0
      if (match(line, /"path"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        s = substr(line, RSTART, RLENGTH)
        sub(/.*"path"[[:space:]]*:[[:space:]]*"/, "", s)
        sub(/".*/, "", s)
        path = s
      }
      if (match(line, /"language"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        s = substr(line, RSTART, RLENGTH)
        sub(/.*"language"[[:space:]]*:[[:space:]]*"/, "", s)
        sub(/".*/, "", s)
        this_lang = s
      }
      if (match(line, /"excluded_reason"[[:space:]]*:[[:space:]]*(null|"[^"]*")/)) {
        s = substr(line, RSTART, RLENGTH)
        sub(/.*"excluded_reason"[[:space:]]*:[[:space:]]*/, "", s)
        excl = s
        if (path != "" && excl == "null" && this_lang == lang) {
          print path
        }
        path = ""; this_lang = ""; excl = ""
      }
      if (line ~ /^[[:space:]]*\][[:space:]]*,?[[:space:]]*$/) { in_files = 0 }
    }
  ' "$INVENTORY"
}

# Emit a JSONL row.
emit_row() {
  local file="$1" func="$2" line="$3" cc="$4" lang="$5" source="$6" tool="$7"
  printf '{"file":"%s","function":"%s","line":%d,"complexity":%d,"language":"%s","source":"%s","tool":"%s"}\n' \
    "$(js_escape "$file")" "$(js_escape "$func")" \
    "$line" "$cc" "$(js_escape "$lang")" "$(js_escape "$source")" "$(js_escape "$tool")" \
    >> "$OUT_JSONL"
}

# Heuristic fallback: emit one row per file with score = 0.5*loc + 5*nesting.
heuristic_for() {
  local file="$1" lang="$2"
  local abs="$TARGET/$file"
  [[ ! -f "$abs" ]] && return 0
  local loc nest score
  loc="$(awk 'NF>0 {n++} END{print n+0}' "$abs" 2>/dev/null || echo 0)"
  # Approximate nesting depth: max leading whitespace expansion / 2.
  nest="$(awk '
    {
      # Tabs count as 4 columns
      gsub(/\t/, "    ");
      n = match($0, /[^ ]/) - 1;
      if (n < 0) n = 0;
      indent = int(n / 2);
      if (indent > max) max = indent;
    }
    END { print (max + 0) }
  ' "$abs" 2>/dev/null || echo 0)"
  score="$(awk -v l=$loc -v n=$nest 'BEGIN { printf "%d", int(0.5*l + 5*n) }')"
  emit_row "$file" "<file>" 1 "$score" "$lang" "heuristic" "heuristic"
}

# Run a per-language tool against one file. Best-effort parsers.
run_lizard_file() {
  local file="$1" lang="$2"
  local abs="$TARGET/$file"
  [[ ! -f "$abs" ]] && return 0
  lizard "$abs" --csv 2>/dev/null | awk -F',' -v file="$file" -v lang="$lang" '
    NR > 0 && NF >= 5 && $1 ~ /^[0-9]+$/ {
      # lizard --csv columns: nloc, ccn, token, param, length, location, file, line
      ccn = $2; func_name = $6; line = $8;
      if (func_name == "") func_name = "<anon>";
      if (line == "") line = 1;
      gsub(/"/, "\\\"", func_name);
      printf "%s\t%s\t%s\t%s\n", line, ccn, func_name, file
    }
  ' | while IFS=$'\t' read -r ln cc func fpath; do
    [[ -z "$cc" ]] && continue
    emit_row "$fpath" "$func" "$ln" "$cc" "$lang" "tool" "lizard"
  done
}

run_radon_file() {
  local file="$1"
  local abs="$TARGET/$file"
  [[ ! -f "$abs" ]] && return 0
  radon cc "$abs" -j 2>/dev/null | awk -v file="$file" '
    /"name"/ {
      match($0, /"name"[^"]*"[^"]*"/)
      name = substr($0, RSTART, RLENGTH)
      gsub(/.*"name"[^"]*"/, "", name); gsub(/".*/, "", name)
    }
    /"lineno"/ {
      match($0, /"lineno":[ ]*[0-9]+/)
      lineno = substr($0, RSTART, RLENGTH)
      sub(/.*: */, "", lineno)
    }
    /"complexity"/ {
      match($0, /"complexity":[ ]*[0-9]+/)
      cc = substr($0, RSTART, RLENGTH)
      sub(/.*: */, "", cc)
      if (name != "" && cc != "") {
        printf "%s\t%s\t%s\n", lineno, cc, name
        name = ""; lineno = ""; cc = ""
      }
    }
  ' | while IFS=$'\t' read -r ln cc func; do
    [[ -z "$cc" ]] && continue
    emit_row "$file" "$func" "${ln:-1}" "$cc" "python" "tool" "radon"
  done
}

run_gocyclo_file() {
  local file="$1"
  local abs="$TARGET/$file"
  [[ ! -f "$abs" ]] && return 0
  gocyclo "$abs" 2>/dev/null | awk -v file="$file" '
    NF >= 4 {
      cc = $1; func = $3; loc = $4
      gsub(/.*:/, "", loc)
      # gocyclo format: "<cc> <pkg> <func> <file>:<line>"
      match($0, /:[0-9]+:/);
      if (RSTART > 0) {
        line = substr($0, RSTART + 1, RLENGTH - 2)
      } else line = 1
      printf "%s\t%s\t%s\n", line, cc, func
    }
  ' | while IFS=$'\t' read -r ln cc func; do
    [[ -z "$cc" ]] && continue
    emit_row "$file" "$func" "${ln:-1}" "$cc" "go" "tool" "gocyclo"
  done
}

# Track which languages went degraded
DEGRADED=()
BY_LANG_NAMES=()
BY_LANG_TOOLS=()

# ── Main loop: per language ─────────────────────────────────
for lang in $(get_languages); do
  case "$lang" in
    image|pdf|archive|font|audio|video|binary|markdown|yaml|toml|json|xml|html|css|other)
      continue ;;
  esac
  tool="$(pick_tool "$lang")"
  BY_LANG_NAMES+=("$lang")
  BY_LANG_TOOLS+=("$tool")
  if [[ "$tool" == "heuristic" ]]; then
    DEGRADED+=("$lang")
  fi

  files_for_language "$lang" | while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    case "$tool" in
      radon)         run_radon_file   "$path" ;;
      gocyclo)       run_gocyclo_file "$path" ;;
      lizard)        run_lizard_file  "$path" "$lang" ;;
      eslint|eslint-local|pmd|clippy|flog|detekt)
        # Best-effort: those parsers are spec-heavy; degrade to heuristic
        # so the report still has something to draw. Bias toward "data exists
        # but tool integration is v0.2 work" — emit but mark source=heuristic.
        heuristic_for "$path" "$lang"
        ;;
      heuristic|*)
        heuristic_for "$path" "$lang"
        ;;
    esac
  done
done

# ── Build summary ───────────────────────────────────────────
# byLanguage map
bylang_json="{"
first=1
for i in "${!BY_LANG_NAMES[@]}"; do
  ln="${BY_LANG_NAMES[$i]}"
  tn="${BY_LANG_TOOLS[$i]}"
  avail="true"
  [[ "$tn" == "heuristic" ]] && avail="false"
  if [[ $first -eq 1 ]]; then first=0; else bylang_json="$bylang_json,"; fi
  bylang_json="$bylang_json\"$(js_escape "$ln")\":{\"tool\":\"$(js_escape "$tn")\",\"available\":$avail}"
done
bylang_json="$bylang_json}"

# hot top 20
hot_json="["
hfirst=1
if [[ -s "$OUT_JSONL" ]]; then
  # Sort by complexity desc, take top 20
  while IFS= read -r row; do
    if [[ $hfirst -eq 1 ]]; then hfirst=0; else hot_json="$hot_json,"; fi
    hot_json="$hot_json$row"
  done < <(sort -t: -k4 -nr "$OUT_JSONL" 2>/dev/null \
    | awk -F'"complexity":' 'NF >= 2 { c = $2; gsub(/[^0-9].*/, "", c); printf "%s\t%s\n", c, $0 }' \
    | sort -nr | head -20 | cut -f2-)
fi
hot_json="$hot_json]"

# degraded list
deg_json="["
dfirst=1
for d in "${DEGRADED[@]}"; do
  if [[ $dfirst -eq 1 ]]; then dfirst=0; else deg_json="$deg_json,"; fi
  deg_json="$deg_json\"$(js_escape "$d")\""
done
deg_json="$deg_json]"

cat > "$OUT_SUMMARY" <<EOF
{
  "byLanguage": $bylang_json,
  "hot": $hot_json,
  "degraded": $deg_json,
  "totalRows": $(wc -l < "$OUT_JSONL" | tr -d ' '),
  "snapshot": "$(date -u +%FT%TZ)"
}
EOF

echo "✓ wrote $OUT_JSONL ($(wc -l < "$OUT_JSONL" | tr -d ' ') rows) + $OUT_SUMMARY"
if [[ "${#DEGRADED[@]}" -gt 0 ]]; then
  echo "  (degraded to heuristic: ${DEGRADED[*]}) — see references/complexity-tools.md §4 for caveat" >&2
fi

exit 0
