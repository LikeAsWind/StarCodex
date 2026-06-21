#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# business-evidence.sh —— Collect six business-evidence files for Phase 1.
#
# Produces `<workspace>/discovery/business-evidence/`:
#   • comments.jsonl     — doc-comments with file:line + symbol (best-effort)
#   • tests.jsonl        — test function names + assertion keywords
#   • schema.md          — DB DDL / migrations summary
#   • configs.md         — top-level config files and enum constants
#   • docs.md            — README / docs/ / root *.md
#   • commit-themes.md   — last ~200 commit messages clustered by prefix
#
# Usage:
#   bash business-evidence.sh --workspace <path>
#   bash business-evidence.sh --help
#
# Tier-aware: uses lib/query.sh `bc_query_text` for portable scanning.
# All extraction is best-effort; downstream NN-business.md SubAgent treats each
# evidence line as a possible citation source, not as ground truth.
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
TIER_JSON="$WORKSPACE/discovery/tier.json"
INV="$WORKSPACE/discovery/inventory.json"
[[ -f "$TIER_JSON" ]] || { echo "✗ missing $TIER_JSON (run tier-select.sh first)" >&2; exit 1; }
[[ -f "$INV" ]]       || { echo "✗ missing $INV (run inventory.sh first)" >&2;       exit 1; }

TARGET="$(tr -d '\n' < "$TIER_JSON" | sed -nE 's/.*"target"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)"
TIER="$(  tr -d '\n' < "$TIER_JSON" | sed -nE 's/.*"tier"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p'   | head -n1)"
[[ -d "$TARGET" ]] || { echo "✗ tier.json target invalid: $TARGET" >&2; exit 1; }

OUT_DIR="$WORKSPACE/discovery/business-evidence"
mkdir -p "$OUT_DIR"

# ── lib/query.sh for tier-aware scans ──────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$(cd "$SCRIPT_DIR/../lib" && pwd)/query.sh"
export BC_TIER="$TIER"
export BC_TARGET="$TARGET"

js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

# ── Helper: select analyzed paths from inventory by suffix filter ──
# Uses python if available, else awk grep on inventory.json (well-formed enough).
analyzed_paths() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$INV" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], 'r', encoding='utf-8'))
for f in data.get('files', []):
    if f.get('excluded_reason'):
        continue
    print(f.get('path', ''))
PY
  elif command -v python >/dev/null 2>&1; then
    python - "$INV" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], 'r'))
for f in data.get('files', []):
    if f.get('excluded_reason'):
        continue
    print(f.get('path', ''))
PY
  else
    awk '
      /"path"[[:space:]]*:/ {
        match($0, /"path"[[:space:]]*:[[:space:]]*"([^"]*)"/, a); p=a[1]
      }
      /"excluded_reason"[[:space:]]*:[[:space:]]*null/ {
        if (p != "") print p
        p=""
      }
    ' "$INV"
  fi
}

# Quick lang-filtered file lists
ALL_PATHS="$(analyzed_paths)"

filter_paths() {
  # Args: extension patterns (e.g. "py" "go" ...)
  local patterns="$*"
  printf '%s\n' "$ALL_PATHS" | awk -v pats="$patterns" '
    BEGIN {
      n = split(pats, arr, " ")
      for (i=1;i<=n;i++) exts[arr[i]]=1
    }
    {
      ext = $0
      sub(/.*\./, "", ext)
      if (ext in exts) print
    }
  '
}

# ── 1) comments.jsonl ──────────────────────────────────────
COMMENTS_OUT="$OUT_DIR/comments.jsonl"
: > "$COMMENTS_OUT"

# Python docstrings: triple-double-quote or triple-single-quote opener after a
# `def ...:` or `class ...:` line. We grep for the opener pattern and emit a
# row per match. The body text is the line containing the opener (good enough
# for citation; full body extraction would require a real parser).
emit_comment_jsonl() {
  local file="$1" line="$2" symbol="$3" text="$4"
  printf '{"file":"%s","line":%s,"symbol":"%s","text":"%s"}\n' \
    "$(js_escape "$file")" "$line" "$(js_escape "$symbol")" "$(js_escape "$text")"
}

# Python docstrings (one-liner triple-quote starts; the next line if multi-line).
while IFS=: read -r file lineno text; do
  [[ -z "$file" ]] && continue
  emit_comment_jsonl "$file" "$lineno" "" "$text"
done < <(bc_query_text '^\s*("""|'\'\'\'')' --type py 2>/dev/null \
           | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2:\3/p') \
  >> "$COMMENTS_OUT" || true

# JSDoc / Javadoc / C-style /** ... */ start markers
while IFS=: read -r file lineno text; do
  [[ -z "$file" ]] && continue
  emit_comment_jsonl "$file" "$lineno" "" "$text"
done < <(bc_query_text '^\s*/\*\*' 2>/dev/null \
           | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2:\3/p') \
  >> "$COMMENTS_OUT" || true

# Go-style: /// or // immediately above func/type — best-effort: grep for `// `
# on lines preceding a `func ` declaration. To stay cheap, we just collect
# `^// ` lines from .go files.
while IFS=: read -r file lineno text; do
  [[ -z "$file" ]] && continue
  emit_comment_jsonl "$file" "$lineno" "" "$text"
done < <(bc_query_text '^// ' --type go 2>/dev/null \
           | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2:\3/p') \
  >> "$COMMENTS_OUT" || true

# Rust /// doc comments
while IFS=: read -r file lineno text; do
  [[ -z "$file" ]] && continue
  emit_comment_jsonl "$file" "$lineno" "" "$text"
done < <(bc_query_text '^\s*///' --type rust 2>/dev/null \
           | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2:\3/p') \
  >> "$COMMENTS_OUT" || true

COMMENTS_LINES="$(wc -l < "$COMMENTS_OUT" | tr -d ' ')"

# ── 2) tests.jsonl ─────────────────────────────────────────
TESTS_OUT="$OUT_DIR/tests.jsonl"
: > "$TESTS_OUT"

emit_test_jsonl() {
  local file="$1" line="$2" name="$3"
  printf '{"file":"%s","line":%s,"name":"%s","assertions":[]}\n' \
    "$(js_escape "$file")" "$line" "$(js_escape "$name")"
}

# Python pytest / unittest: `def test_*(...)`
while IFS=: read -r file lineno text; do
  [[ -z "$file" ]] && continue
  name="$(printf '%s' "$text" | sed -nE 's/.*def[[:space:]]+(test_[A-Za-z0-9_]+)\(.*/\1/p' | head -n1)"
  emit_test_jsonl "$file" "$lineno" "${name:-anonymous}"
done < <(bc_query_text 'def[[:space:]]+test_' --type py 2>/dev/null \
           | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2:\3/p') \
  >> "$TESTS_OUT" || true

# Go: `func Test...`
while IFS=: read -r file lineno text; do
  [[ -z "$file" ]] && continue
  name="$(printf '%s' "$text" | sed -nE 's/.*func[[:space:]]+(Test[A-Za-z0-9_]+)\(.*/\1/p' | head -n1)"
  emit_test_jsonl "$file" "$lineno" "${name:-anonymous}"
done < <(bc_query_text 'func[[:space:]]+Test' --type go 2>/dev/null \
           | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2:\3/p') \
  >> "$TESTS_OUT" || true

# JS/TS: it('name') / describe('name') / test('name')
for pattern in "it\\(['\"]" "describe\\(['\"]" "test\\(['\"]"; do
  for typ in js ts; do
    while IFS=: read -r file lineno text; do
      [[ -z "$file" ]] && continue
      name="$(printf '%s' "$text" | sed -nE "s/.*(it|describe|test)\\((['\"])([^'\"]+)\\2.*/\\3/p" | head -n1)"
      emit_test_jsonl "$file" "$lineno" "${name:-anonymous}"
    done < <(bc_query_text "$pattern" --type "$typ" 2>/dev/null \
               | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2:\3/p') \
      >> "$TESTS_OUT" || true
  done
done

# Java JUnit: `@Test` on a method
while IFS=: read -r file lineno text; do
  [[ -z "$file" ]] && continue
  emit_test_jsonl "$file" "$lineno" "@Test"
done < <(bc_query_text '@Test' --type java 2>/dev/null \
           | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2:\3/p') \
  >> "$TESTS_OUT" || true

TESTS_LINES="$(wc -l < "$TESTS_OUT" | tr -d ' ')"

# ── 3) schema.md ───────────────────────────────────────────
SCHEMA_OUT="$OUT_DIR/schema.md"
{
  echo "# DB Schema · Discover scan"
  echo
  echo "_Auto-collected from SQL DDL, migrations, ORM definitions. Best-effort; treat as citation source, not ground truth._"
  echo
} > "$SCHEMA_OUT"

found_schema=0

# SQL files
SQL_FILES="$(filter_paths sql)"
if [[ -n "$SQL_FILES" ]]; then
  echo "## SQL files" >> "$SCHEMA_OUT"
  echo "" >> "$SCHEMA_OUT"
  echo "| file | tables (best-effort) |" >> "$SCHEMA_OUT"
  echo "|------|---------------------|" >> "$SCHEMA_OUT"
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    abs="$TARGET/$rel"
    [[ -f "$abs" ]] || continue
    tables="$(grep -iE '^[[:space:]]*CREATE[[:space:]]+TABLE' "$abs" 2>/dev/null \
              | sed -nE 's/.*CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?["`]?([A-Za-z0-9_.]+)["`]?.*/\2/Ip' \
              | sort -u | tr '\n' ' ')"
    [[ -z "$tables" ]] && tables="(no CREATE TABLE found)"
    echo "| \`$rel\` | $tables |" >> "$SCHEMA_OUT"
    found_schema=1
  done <<< "$SQL_FILES"
  echo "" >> "$SCHEMA_OUT"
fi

# Migration-like directories
MIG_FILES="$(printf '%s\n' "$ALL_PATHS" | awk '/(^|\/)(migrations|migrate|schema|db\/migrate|alembic\/versions)\//')"
if [[ -n "$MIG_FILES" ]]; then
  echo "## Migration files" >> "$SCHEMA_OUT"
  echo "" >> "$SCHEMA_OUT"
  printf '%s\n' "$MIG_FILES" | awk 'NF>0 {print "- `" $0 "`"}' >> "$SCHEMA_OUT"
  echo "" >> "$SCHEMA_OUT"
  found_schema=1
fi

# GORM struct tags (Go): `gorm:"..."` lines
GORM_HITS="$(bc_query_text 'gorm:"' --type go 2>/dev/null \
              | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+).*$/\1:\2/p' | sort -u)"
if [[ -n "$GORM_HITS" ]]; then
  echo "## GORM struct tags (Go)" >> "$SCHEMA_OUT"
  echo "" >> "$SCHEMA_OUT"
  printf '%s\n' "$GORM_HITS" | awk -F: 'NF>0 {print "- `" $1 ":" $2 "`"}' | head -n 50 >> "$SCHEMA_OUT"
  echo "" >> "$SCHEMA_OUT"
  found_schema=1
fi

# Prisma schema
PRISMA="$(printf '%s\n' "$ALL_PATHS" | awk '/\.prisma$/')"
if [[ -n "$PRISMA" ]]; then
  echo "## Prisma schema" >> "$SCHEMA_OUT"
  printf '%s\n' "$PRISMA" | awk 'NF>0 {print "- `" $0 "`"}' >> "$SCHEMA_OUT"
  echo "" >> "$SCHEMA_OUT"
  found_schema=1
fi

if [[ "$found_schema" -eq 0 ]]; then
  echo "(no DB schema found)" >> "$SCHEMA_OUT"
fi

# ── 4) configs.md ──────────────────────────────────────────
CONFIGS_OUT="$OUT_DIR/configs.md"
{
  echo "# Configs + enum constants"
  echo
  echo "_Top-level config files and source-level enum / const tables. Each line is a potential citation source for business vocabulary._"
  echo
} > "$CONFIGS_OUT"

CONFIG_FILES="$(printf '%s\n' "$ALL_PATHS" | awk '
  /^[^\/]*$/ && /(^|\/)(config|conf|settings)([.-]|$)/ {print; next}
  /(^|\/)\.env([.-]|$)/ {print; next}
  /^(config|conf|settings|application|appsettings)\.(yml|yaml|toml|json|properties|ini|env)$/ {print; next}
  /(^|\/)application(-[a-zA-Z]+)?\.(yml|yaml|properties)$/ {print; next}
  /(^|\/)application\.properties$/ {print; next}
')"

if [[ -n "$CONFIG_FILES" ]]; then
  echo "## Detected config files" >> "$CONFIGS_OUT"
  echo "" >> "$CONFIGS_OUT"
  printf '%s\n' "$CONFIG_FILES" | awk 'NF>0 {print "- `" $0 "`"}' | head -n 50 >> "$CONFIGS_OUT"
  echo "" >> "$CONFIGS_OUT"
fi

# Enum constant detection — best-effort across common languages
echo "## Enum / const candidates" >> "$CONFIGS_OUT"
echo "" >> "$CONFIGS_OUT"
echo "_Lines that look like enum / const definitions in source. Cap 50 per scan to stay readable._" >> "$CONFIGS_OUT"
echo "" >> "$CONFIGS_OUT"
{
  bc_query_text '^[[:space:]]*(public[[:space:]]+)?enum[[:space:]]+[A-Za-z_]'           2>/dev/null
  bc_query_text '^[[:space:]]*const[[:space:]]+[A-Za-z_]'                               2>/dev/null
  bc_query_text '^[[:space:]]*type[[:space:]]+[A-Za-z_].*=[[:space:]]*("|'\'')' --type ts 2>/dev/null
} | sed -nE 's/^\{[^}]*"file":"([^"]+)"[^}]*"line":([0-9]+)[^}]*"text":"([^"]+)".*$/\1:\2: \3/p' \
  | head -n 50 \
  | awk 'NF>0 {print "- `" $0 "`"}' >> "$CONFIGS_OUT"
echo "" >> "$CONFIGS_OUT"

# ── 5) docs.md ─────────────────────────────────────────────
DOCS_OUT="$OUT_DIR/docs.md"
{
  echo "# Docs · README / docs/ / root markdown"
  echo
  echo "_First non-blank line of each candidate doc. Citation source for business background._"
  echo
} > "$DOCS_OUT"

DOC_FILES="$(printf '%s\n' "$ALL_PATHS" | awk '
  /^README(\.md|\.rst|\.txt)?$/i {print; next}
  /^[^\/]*\.md$/i              {print; next}
  /^docs\//i                    {print; next}
  /(^|\/)CHANGELOG(\.md)?$/i   {print; next}
  /(^|\/)CONTRIBUTING(\.md)?$/i {print; next}
')"

if [[ -n "$DOC_FILES" ]]; then
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    abs="$TARGET/$rel"
    [[ -f "$abs" ]] || continue
    first="$(awk 'NF>0 {print; exit}' "$abs" 2>/dev/null || echo '(empty)')"
    # Trim
    first="${first# }"
    [[ ${#first} -gt 120 ]] && first="${first:0:117}..."
    printf -- '- `%s` — %s\n' "$rel" "$first" >> "$DOCS_OUT"
  done <<< "$DOC_FILES"
else
  echo "(no docs found)" >> "$DOCS_OUT"
fi

# ── 6) commit-themes.md ────────────────────────────────────
COMMITS_OUT="$OUT_DIR/commit-themes.md"
{
  echo "# Commit themes · last ~200 commits"
  echo
} > "$COMMITS_OUT"

if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TOTAL_COMMITS="$(git -C "$TARGET" log --oneline -n 200 2>/dev/null | wc -l | tr -d ' ')"
  echo "_Total commits scanned: ${TOTAL_COMMITS}_" >> "$COMMITS_OUT"
  echo "" >> "$COMMITS_OUT"

  # Cluster by leading prefix (feat:/fix:/chore:/refactor:/docs:/test:/perf:/etc.)
  echo "## Themes (by conventional-commit prefix)" >> "$COMMITS_OUT"
  echo "" >> "$COMMITS_OUT"
  git -C "$TARGET" log --pretty=%s -n 200 2>/dev/null \
    | awk '
        {
          msg = $0
          prefix = ""
          if (match(msg, /^[a-zA-Z]+(\([^)]+\))?:/)) {
            prefix = substr(msg, RSTART, RLENGTH)
            sub(/:$/, "", prefix)
            sub(/\(.+\)$/, "", prefix)
          } else if (match(msg, /^[A-Z][A-Z0-9]*-[0-9]+/)) {
            prefix = "ticket"
          } else {
            prefix = "other"
          }
          counts[prefix]++
        }
        END {
          for (p in counts) print counts[p] "\t" p
        }
      ' \
    | sort -rn -k1,1 \
    | head -n 20 \
    | awk '{printf "- %s × %s\n", $1, $2}' \
    >> "$COMMITS_OUT"
  echo "" >> "$COMMITS_OUT"

  echo "## Last 20 commit subjects" >> "$COMMITS_OUT"
  echo "" >> "$COMMITS_OUT"
  git -C "$TARGET" log --pretty='%h %s' -n 20 2>/dev/null \
    | awk 'NF>0 {print "- `" $0 "`"}' \
    >> "$COMMITS_OUT"
else
  echo "(target is not a git repository; commit themes unavailable)" >> "$COMMITS_OUT"
fi

# ── Summary ────────────────────────────────────────────────
echo "✓ wrote business-evidence/ (comments=$COMMENTS_LINES tests=$TESTS_LINES schema=$([ "$found_schema" = "1" ] && echo yes || echo no))"
echo "  $COMMENTS_OUT"
echo "  $TESTS_OUT"
echo "  $SCHEMA_OUT"
echo "  $CONFIGS_OUT"
echo "  $DOCS_OUT"
echo "  $COMMITS_OUT"
