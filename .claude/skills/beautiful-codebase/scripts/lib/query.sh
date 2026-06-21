#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/query.sh —— Tier-aware query dispatcher (sourced, not executed)
#
# Usage:
#   source "$(dirname "$0")/lib/query.sh"
#   eval "$(bc-detect-tier --target ./my-project)"   # exports BC_TIER + BC_TARGET
#   bc_query_files ./my-project | head
#   bc_query_symbols MyClass --callers
#   bc_query_text "TODO" --type py
#   bc_query_explore "where is auth handled"
#
# Design:
#   • Reference docs name only the **intent** of a query (list files / find
#     callers / search text / explore symbol). This lib decides the tool.
#   • Every function emits JSON Lines on stdout. Callers parse uniformly,
#     never branching on tier themselves.
#   • Degraded-tier warnings go to stderr so JSONL stdout stays clean.
#   • BC_TIER env var picks the implementation. If unset, the lib auto-detects
#     against PWD on first call (safe default; pass --target to override).
#
# Functions:
#   bc-detect-tier [--target <path>]       echo tier + target as `export FOO=bar` lines
#   bc_query_files <root>                  list source files in <root>
#   bc_query_symbols <symbol> [--callers|--callees|--all]
#   bc_query_text <pattern> [--type <lang>] [<root>]
#   bc_query_explore <symbol-or-question>  codegraph-only; warns on lower tiers
# ─────────────────────────────────────────────────────────────

# ── Small helpers ────────────────────────────────────────────
_bc_warn() { printf '%s\n' "$@" >&2; }
_bc_err()  { printf 'lib/query.sh: %s\n' "$@" >&2; }

# JSON-escape a string (handles backslash, double-quote, newline, tab).
_bc_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

# Emit a single JSONL line {kind,...}. Keys/values are pre-escaped by caller.
_bc_jsonl() {
  printf '{%s}\n' "$*"
}

# ── Tier detection (callable as a normal command) ────────────
bc-detect-tier() {
  local target=""
  for arg in "$@"; do
    case "$arg" in
      --target=*) target="${arg#--target=}" ;;
      --target)   shift; target="${1:-}" ;;
    esac
  done
  target="${target:-$PWD}"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local probe="$script_dir/probe-tools.sh"
  if [[ ! -x "$probe" && ! -f "$probe" ]]; then
    _bc_err "probe-tools.sh not found next to lib/ (looked in $script_dir)"
    return 1
  fi

  # Use probe-tools.sh to compute the tier; avoid re-implementing detection.
  local tier
  tier="$(bash "$probe" --target "$target" 2>/dev/null | awk -F': *' '$1=="tier"{print $2; exit}')" || true
  if [[ -z "$tier" ]]; then
    _bc_err "probe-tools.sh returned no tier; defaulting to grep"
    tier="grep"
  fi

  printf 'export BC_TIER=%q\n' "$tier"
  printf 'export BC_TARGET=%q\n' "$(cd "$target" && pwd)"
}

# Lazy auto-detect if BC_TIER unset.
_bc_ensure_tier() {
  if [[ -z "${BC_TIER:-}" ]]; then
    eval "$(bc-detect-tier --target "${BC_TARGET:-$PWD}")"
  fi
}

# Default file extensions when falling back to find/grep.
_BC_DEFAULT_EXTS=(
  java py go ts tsx js jsx rb php rs c cc cpp h hpp m mm
  swift kt scala cs sh sql proto graphql vue svelte md mdx
)

# ── bc_query_files ──────────────────────────────────────────
bc_query_files() {
  _bc_ensure_tier
  local root="${1:-${BC_TARGET:-$PWD}}"
  if [[ ! -d "$root" ]]; then
    _bc_err "bc_query_files: not a directory: $root"
    return 1
  fi

  case "$BC_TIER" in
    codegraph-indexed)
      # Prefer codegraph's own file enumeration; passes through to JSONL.
      if codegraph files --json --root "$root" 2>/dev/null | head -n1 | grep -q '^{'; then
        codegraph files --json --root "$root" 2>/dev/null
        return 0
      fi
      # Fall through to git/rg if --json shape unsupported by current codegraph.
      _bc_warn "codegraph files --json unsupported on this version, falling back to git ls-files"
      ;;
  esac

  # Cross-tier fallback: prefer git ls-files (respects .gitignore), then rg --files,
  # then find with a default extension list.
  local files_out
  if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    files_out="$(git -C "$root" ls-files 2>/dev/null)"
  elif command -v rg >/dev/null 2>&1; then
    files_out="$(cd "$root" && rg --files 2>/dev/null)"
  else
    local ext_pattern
    ext_pattern="$(printf -- '-name *.%s -o ' "${_BC_DEFAULT_EXTS[@]}" | sed 's/ -o $//')"
    # shellcheck disable=SC2086
    files_out="$(cd "$root" && find . -type f \( $ext_pattern \) 2>/dev/null | sed 's|^\./||')"
  fi

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    local esc_path esc_root
    esc_path="$(_bc_json_escape "$path")"
    esc_root="$(_bc_json_escape "$root")"
    _bc_jsonl "\"kind\":\"file\",\"path\":\"$esc_path\",\"root\":\"$esc_root\""
  done <<< "$files_out"
}

# ── bc_query_symbols ────────────────────────────────────────
bc_query_symbols() {
  _bc_ensure_tier
  local symbol="${1:-}"
  shift || true
  local mode="all"
  for arg in "$@"; do
    case "$arg" in
      --callers) mode="callers" ;;
      --callees) mode="callees" ;;
      --all)     mode="all" ;;
    esac
  done
  if [[ -z "$symbol" ]]; then
    _bc_err "bc_query_symbols: missing <symbol>"
    return 1
  fi

  case "$BC_TIER" in
    codegraph-indexed)
      if [[ "$mode" == "callers" || "$mode" == "all" ]]; then
        codegraph callers "$symbol" --json 2>/dev/null || true
      fi
      if [[ "$mode" == "callees" || "$mode" == "all" ]]; then
        codegraph callees "$symbol" --json 2>/dev/null || true
      fi
      return 0
      ;;
  esac

  # Lower tiers: degrade to text-grep on the symbol name. Semantic accuracy lost.
  _bc_warn "[tier=$BC_TIER] bc_query_symbols degrades to text grep on \"$symbol\"; semantic accuracy reduced."

  local root="${BC_TARGET:-$PWD}"
  local hits=""
  if [[ "$BC_TIER" == "rg" ]]; then
    hits="$(rg -n --no-heading --color=never --fixed-strings "$symbol" "$root" 2>/dev/null || true)"
  else
    hits="$(grep -rn --color=never -F "$symbol" "$root" 2>/dev/null || true)"
  fi

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local file_part rest_part lineno snippet
    file_part="${line%%:*}"
    rest_part="${line#*:}"
    lineno="${rest_part%%:*}"
    snippet="${rest_part#*:}"
    local esc_file esc_snip esc_sym
    esc_file="$(_bc_json_escape "$file_part")"
    esc_snip="$(_bc_json_escape "$snippet")"
    esc_sym="$(_bc_json_escape "$symbol")"
    _bc_jsonl "\"kind\":\"symbol-hit\",\"symbol\":\"$esc_sym\",\"file\":\"$esc_file\",\"line\":$lineno,\"text\":\"$esc_snip\",\"degraded\":true"
  done <<< "$hits"
}

# ── bc_query_text ───────────────────────────────────────────
bc_query_text() {
  _bc_ensure_tier
  local pattern=""
  local lang=""
  local root=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type=*) lang="${1#--type=}" ;;
      --type)   shift; lang="${1:-}" ;;
      --*)      ;;
      *)
        if [[ -z "$pattern" ]]; then pattern="$1"
        elif [[ -z "$root" ]]; then root="$1"
        fi
        ;;
    esac
    shift
  done
  if [[ -z "$pattern" ]]; then
    _bc_err "bc_query_text: missing <pattern>"
    return 1
  fi
  root="${root:-${BC_TARGET:-$PWD}}"

  local hits=""
  case "$BC_TIER" in
    codegraph-indexed)
      # codegraph 1.x exposes `query` for full-text patterns; prefer it.
      if [[ -n "$lang" ]]; then
        hits="$(codegraph query "$pattern" --type "$lang" --json 2>/dev/null || true)"
      else
        hits="$(codegraph query "$pattern" --json 2>/dev/null || true)"
      fi
      if [[ -n "$hits" ]]; then
        printf '%s\n' "$hits"
        return 0
      fi
      _bc_warn "codegraph query returned empty; falling back to rg/grep"
      ;;
  esac

  if [[ "$BC_TIER" == "rg" ]] || command -v rg >/dev/null 2>&1; then
    if [[ -n "$lang" ]]; then
      hits="$(rg -n --no-heading --color=never --type "$lang" "$pattern" "$root" 2>/dev/null || true)"
    else
      hits="$(rg -n --no-heading --color=never "$pattern" "$root" 2>/dev/null || true)"
    fi
  else
    hits="$(grep -rn --color=never -E "$pattern" "$root" 2>/dev/null || true)"
  fi

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local file_part rest_part lineno snippet
    file_part="${line%%:*}"
    rest_part="${line#*:}"
    lineno="${rest_part%%:*}"
    snippet="${rest_part#*:}"
    local esc_file esc_snip esc_pat
    esc_file="$(_bc_json_escape "$file_part")"
    esc_snip="$(_bc_json_escape "$snippet")"
    esc_pat="$(_bc_json_escape "$pattern")"
    _bc_jsonl "\"kind\":\"text-hit\",\"pattern\":\"$esc_pat\",\"file\":\"$esc_file\",\"line\":$lineno,\"text\":\"$esc_snip\""
  done <<< "$hits"
}

# ── bc_query_explore ───────────────────────────────────────
bc_query_explore() {
  _bc_ensure_tier
  local query="${1:-}"
  if [[ -z "$query" ]]; then
    _bc_err "bc_query_explore: missing <symbol-or-question>"
    return 1
  fi

  case "$BC_TIER" in
    codegraph-indexed)
      codegraph explore "$query" --json 2>/dev/null || true
      return 0
      ;;
    *)
      _bc_warn "[tier=$BC_TIER] bc_query_explore is codegraph-only; returning empty."
      return 0
      ;;
  esac
}

# Allow `bash lib/query.sh <function> args...` for ad-hoc CLI use, but
# the canonical mode is sourced.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  fn="${1:-}"
  if [[ -z "$fn" ]]; then
    sed -n '2,32p' "$0"
    exit 0
  fi
  shift
  case "$fn" in
    bc-detect-tier|bc_query_files|bc_query_symbols|bc_query_text|bc_query_explore)
      "$fn" "$@"
      ;;
    --help|-h)
      sed -n '2,32p' "$0"
      ;;
    *)
      _bc_err "unknown function: $fn"
      exit 1
      ;;
  esac
fi
