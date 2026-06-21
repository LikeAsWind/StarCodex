#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# inventory.sh —— Build `discovery/inventory.json` for Phase 1 Discover.
#
# Reads `<workspace>/discovery/tier.json` (written by tier-select.sh) to learn
# the target path + chosen tier, enumerates files via lib/query.sh
# (`bc_query_files`), classifies each as analyzed vs. excluded (vendored /
# generated / fixtures), detects language, counts bytes + LOC, computes a
# SHA-1 of contents, and emits a single JSON document.
#
# Usage:
#   bash inventory.sh --workspace <path>
#   bash inventory.sh --help
#
# Output: <workspace>/discovery/inventory.json
#
# Schema:
#   {
#     "target":   "<absolute target path>",
#     "snapshot": "<ISO timestamp>",
#     "tier":     "<from tier.json>",
#     "files": [
#       {"path": "<rel>", "language": "go", "bytes": 1234, "loc": 56,
#        "sha":  "<sha1>", "excluded_reason": null},
#       {"path": "vendor/x.go", "excluded_reason": "vendored"}
#     ],
#     "stats": {
#       "totalFiles":     1234,
#       "analyzedFiles":   980,
#       "excludedFiles":   254,
#       "byLanguage":     {"go": 320, "python": 180, ...},
#       "totalLoc":      152000
#     }
#   }
#
# Design notes:
#   • Streams JSON line-by-line into the file (open `[` → append rows → close `]`)
#     so memory stays flat even on 10k+ file projects.
#   • Excluded files only carry {path, excluded_reason} — no language/bytes/sha
#     so they don't bloat the doc.
#   • LOC is "non-blank lines" best-effort (a true non-comment count per language
#     is overkill for our purposes; downstream readers treat this as approximate).
#   • Language detection: extension table + shebang sniff for shells/python/ruby.
#   • Tier-agnostic enumeration via `lib/query.sh` so codegraph/rg/grep all work.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,38p' "$0"
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
if [[ ! -f "$TIER_JSON" ]]; then
  echo "✗ missing $TIER_JSON; run tier-select.sh first" >&2
  exit 1
fi

# ── Tiny JSON readers (no jq) ───────────────────────────────
read_json_str() {
  local key="$1" file="$2"
  tr -d '\n' < "$file" | sed -nE 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1
}

TARGET="$(read_json_str target "$TIER_JSON")"
TIER="$(read_json_str tier "$TIER_JSON")"
if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
  echo "✗ tier.json target invalid: $TARGET" >&2
  exit 1
fi

# ── Source lib/query.sh ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/query.sh"
export BC_TIER="$TIER"
export BC_TARGET="$TARGET"

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

# Detect language from extension and (for scripts) shebang.
detect_language() {
  local rel="$1" abs="$2"
  local ext="${rel##*.}"
  if [[ "$rel" == "$ext" ]]; then ext=""; fi  # no extension
  ext="${ext,,}"
  # Known binary / asset extensions — short-circuit, no shebang sniff
  case "$ext" in
    png|jpg|jpeg|gif|webp|bmp|ico|svg) echo image; return ;;
    pdf) echo pdf; return ;;
    zip|tar|gz|tgz|bz2|xz|7z|rar) echo archive; return ;;
    woff|woff2|ttf|otf|eot) echo font; return ;;
    mp3|wav|ogg|flac|m4a) echo audio; return ;;
    mp4|mov|avi|mkv|webm) echo video; return ;;
    bin|exe|dll|so|dylib|class|jar|war|o|obj|wasm) echo binary; return ;;
  esac
  case "$ext" in
    go) echo go; return ;;
    py) echo python; return ;;
    rb) echo ruby; return ;;
    java) echo java; return ;;
    kt|kts) echo kotlin; return ;;
    scala) echo scala; return ;;
    ts) echo typescript; return ;;
    tsx) echo typescript; return ;;
    js|mjs|cjs) echo javascript; return ;;
    jsx) echo javascript; return ;;
    vue) echo vue; return ;;
    svelte) echo svelte; return ;;
    rs) echo rust; return ;;
    c) echo c; return ;;
    h) echo c; return ;;
    cc|cpp|cxx) echo cpp; return ;;
    hpp|hxx) echo cpp; return ;;
    m) echo objc; return ;;
    mm) echo objcpp; return ;;
    cs) echo csharp; return ;;
    swift) echo swift; return ;;
    php) echo php; return ;;
    sh|bash) echo shell; return ;;
    zsh) echo shell; return ;;
    sql) echo sql; return ;;
    proto) echo proto; return ;;
    graphql|gql) echo graphql; return ;;
    md|mdx) echo markdown; return ;;
    yaml|yml) echo yaml; return ;;
    toml) echo toml; return ;;
    json|jsonc) echo json; return ;;
    xml) echo xml; return ;;
    html|htm) echo html; return ;;
    css|scss|sass|less) echo css; return ;;
    dockerfile) echo docker; return ;;
    tf) echo terraform; return ;;
    lua) echo lua; return ;;
  esac

  # Filename-only specials
  local base
  base="$(basename "$rel")"
  case "$base" in
    Dockerfile|Dockerfile.*) echo docker; return ;;
    Makefile|makefile|GNUmakefile) echo makefile; return ;;
    Gemfile|Rakefile) echo ruby; return ;;
    Cargo.toml) echo toml; return ;;
    go.mod|go.sum) echo go-module; return ;;
    package.json|tsconfig.json|tsconfig.*.json) echo json; return ;;
  esac

  # Shebang sniff for extensionless / `.script` files
  if [[ -f "$abs" ]]; then
    local first
    first="$(head -c 200 "$abs" 2>/dev/null || true)"
    case "$first" in
      \#\!*bash*|\#\!*sh\ *|\#\!*sh) echo shell; return ;;
      \#\!*python*) echo python; return ;;
      \#\!*ruby*) echo ruby; return ;;
      \#\!*node*) echo javascript; return ;;
      \#\!*perl*) echo perl; return ;;
    esac
  fi

  echo other
}

# Classify exclusion. Returns reason string or empty for analyzed.
classify_exclusion() {
  local rel="$1"
  case "$rel" in
    .git/*|.git) echo silent; return ;;
    .constella/*|.constella) echo silent; return ;;
    .claude/*|.claude) echo silent; return ;;
    node_modules/.cache/*) echo silent; return ;;
  esac
  case "$rel" in
    vendor/*|*/vendor/*) echo vendored; return ;;
    node_modules/*|*/node_modules/*) echo vendored; return ;;
    vendored/*|*/vendored/*) echo vendored; return ;;
    third_party/*|*/third_party/*) echo vendored; return ;;
    third-party/*|*/third-party/*) echo vendored; return ;;
  esac
  case "$rel" in
    dist/*|*/dist/*) echo generated; return ;;
    build/*|*/build/*) echo generated; return ;;
    out/*|*/out/*) echo generated; return ;;
    target/*|*/target/*) echo generated; return ;;
    .next/*|*/.next/*) echo generated; return ;;
    .nuxt/*|*/.nuxt/*) echo generated; return ;;
    coverage/*|*/coverage/*) echo generated; return ;;
    *.min.js|*.min.css|*.min.map) echo generated; return ;;
    *.generated.*) echo generated; return ;;
    *_pb.go|*_pb2.py) echo generated; return ;;
  esac
  case "$rel" in
    package-lock.json|*/package-lock.json) echo generated; return ;;
    yarn.lock|*/yarn.lock) echo generated; return ;;
    pnpm-lock.yaml|*/pnpm-lock.yaml) echo generated; return ;;
    Cargo.lock|*/Cargo.lock) echo generated; return ;;
    poetry.lock|*/poetry.lock) echo generated; return ;;
    Gemfile.lock|*/Gemfile.lock) echo generated; return ;;
    composer.lock|*/composer.lock) echo generated; return ;;
  esac
  case "$rel" in
    fixtures/*|*/fixtures/*) echo fixtures; return ;;
    testdata/*|*/testdata/*) echo fixtures; return ;;
    __fixtures__/*|*/__fixtures__/*) echo fixtures; return ;;
    __snapshots__/*|*/__snapshots__/*) echo fixtures; return ;;
  esac
  echo ""
}

# First-line `// @generated` / similar sniff. Only inspect text-looking files.
is_generated_by_header() {
  local abs="$1"
  if [[ ! -f "$abs" ]]; then return 1; fi
  # Skip known binary extensions
  case "${abs,,}" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.bmp|*.ico|*.pdf|*.zip|*.tar|*.gz|*.tgz|*.bz2|*.xz|*.7z|*.rar|*.woff|*.woff2|*.ttf|*.otf|*.eot|*.mp3|*.wav|*.ogg|*.flac|*.m4a|*.mp4|*.mov|*.avi|*.mkv|*.webm|*.bin|*.exe|*.dll|*.so|*.dylib|*.class|*.jar|*.war|*.o|*.obj|*.wasm)
      return 1 ;;
  esac
  local first
  first="$(head -n 3 "$abs" 2>/dev/null || true)"
  case "$first" in
    *"@generated"*|*"GENERATED CODE"*|*"Code generated by"*|*"DO NOT EDIT"*) return 0 ;;
  esac
  return 1
}

# SHA-1 of file contents. Prefer git hash-object (works inside repos).
sha1_of() {
  local abs="$1"
  if command -v git >/dev/null 2>&1 \
     && git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git hash-object "$abs" 2>/dev/null && return 0
  fi
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum "$abs" 2>/dev/null | awk '{print $1}' && return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 1 "$abs" 2>/dev/null | awk '{print $1}' && return 0
  fi
  echo ""
}

# Non-blank lines as LOC approximation.
loc_of() {
  local abs="$1"
  if [[ ! -f "$abs" ]]; then echo 0; return; fi
  awk 'NF>0 {n++} END {print n+0}' "$abs" 2>/dev/null || echo 0
}

bytes_of() {
  local abs="$1"
  if [[ ! -f "$abs" ]]; then echo 0; return; fi
  if command -v stat >/dev/null 2>&1; then
    # GNU stat
    local out
    out="$(stat -c %s "$abs" 2>/dev/null || true)"
    if [[ -n "$out" ]]; then echo "$out"; return; fi
    # BSD stat
    out="$(stat -f %z "$abs" 2>/dev/null || true)"
    if [[ -n "$out" ]]; then echo "$out"; return; fi
  fi
  wc -c < "$abs" 2>/dev/null | tr -d ' ' || echo 0
}

# ── Enumerate files via lib/query.sh ────────────────────────
mkdir -p "$WORKSPACE/discovery"
OUT="$WORKSPACE/discovery/inventory.json"
TMP="${OUT}.tmp"

SNAPSHOT="$(date -u +%FT%TZ)"
TARGET_ESC="$(js_escape "$TARGET")"

# Open document
{
  printf '{\n'
  printf '  "target": "%s",\n' "$TARGET_ESC"
  printf '  "snapshot": "%s",\n' "$SNAPSHOT"
  printf '  "tier": "%s",\n' "$(js_escape "$TIER")"
  printf '  "files": [\n'
} > "$TMP"

# Counters / stats buffers
total=0
analyzed=0
excluded=0
total_loc=0
# byLanguage stats: store as parallel arrays (works on bash 3+ for portability)
LANG_KEYS=()
LANG_VALS=()

bump_lang() {
  local lang="$1"
  local i
  for i in "${!LANG_KEYS[@]}"; do
    if [[ "${LANG_KEYS[$i]}" == "$lang" ]]; then
      LANG_VALS[$i]=$(( LANG_VALS[$i] + 1 ))
      return
    fi
  done
  LANG_KEYS+=("$lang")
  LANG_VALS+=(1)
}

first_row=1
emit_row() {
  if [[ $first_row -eq 1 ]]; then
    first_row=0
    printf '    %s' "$1" >> "$TMP"
  else
    printf ',\n    %s' "$1" >> "$TMP"
  fi
}

# Stream lib/query.sh JSONL of {kind:"file",path,root}; parse path field.
while IFS= read -r jline; do
  [[ -z "$jline" ]] && continue
  rel="$(printf '%s' "$jline" | sed -nE 's/.*"path"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p')"
  [[ -z "$rel" ]] && continue
  abs="$TARGET/$rel"

  # Silent skip never counted
  reason="$(classify_exclusion "$rel")"
  if [[ "$reason" == "silent" ]]; then
    continue
  fi
  total=$(( total + 1 ))

  if [[ -z "$reason" ]] && is_generated_by_header "$abs"; then
    reason="generated"
  fi

  if [[ -n "$reason" ]]; then
    excluded=$(( excluded + 1 ))
    emit_row "{\"path\": \"$(js_escape "$rel")\", \"excluded_reason\": \"$reason\"}"
    continue
  fi

  if [[ ! -f "$abs" ]]; then
    # Skip non-regular entries (symlinks to dirs, sockets, etc.)
    continue
  fi

  lang="$(detect_language "$rel" "$abs")"
  bytes="$(bytes_of "$abs")"
  case "$lang" in
    image|pdf|archive|font|audio|video|binary) loc=0 ;;
    *) loc="$(loc_of "$abs")" ;;
  esac
  sha="$(sha1_of "$abs")"

  analyzed=$(( analyzed + 1 ))
  total_loc=$(( total_loc + loc ))
  bump_lang "$lang"

  emit_row "{\"path\": \"$(js_escape "$rel")\", \"language\": \"$lang\", \"bytes\": $bytes, \"loc\": $loc, \"sha\": \"$(js_escape "$sha")\", \"excluded_reason\": null}"
done < <(bc_query_files "$TARGET")

# Close files array, write stats
{
  printf '\n  ],\n'
  printf '  "stats": {\n'
  printf '    "totalFiles": %d,\n' "$total"
  printf '    "analyzedFiles": %d,\n' "$analyzed"
  printf '    "excludedFiles": %d,\n' "$excluded"
  printf '    "totalLoc": %d,\n' "$total_loc"
  printf '    "byLanguage": {'
  for i in "${!LANG_KEYS[@]}"; do
    if [[ $i -gt 0 ]]; then printf ', '; fi
    printf '"%s": %d' "$(js_escape "${LANG_KEYS[$i]}")" "${LANG_VALS[$i]}"
  done
  printf '}\n'
  printf '  }\n'
  printf '}\n'
} >> "$TMP"

mv "$TMP" "$OUT"

echo "✓ wrote $OUT (total=$total analyzed=$analyzed excluded=$excluded loc=$total_loc)"
