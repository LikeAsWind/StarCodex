#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# html-to-pdf.sh —— Render the beautiful-codebase single-file HTML to PDF.
#
# Usage:
#   bash <skill>/scripts/html-to-pdf.sh [input.html] [output.pdf]
#   bash <skill>/scripts/html-to-pdf.sh --input article/article.html
#   bash <skill>/scripts/html-to-pdf.sh --help
#
# Defaults: input  = ./article/article.html
#           output = ./article/article.pdf
#
# Prerequisites: a chromium-family browser on PATH (chromium / chrome /
# chromium-browser / brave-browser / microsoft-edge). Auto-detected; macOS app
# bundles also probed. No npm, no Node, no puppeteer.
#
# How it works (see references/pdf-output.md):
#   1. reacticle's TOC is a 2-col desktop grid; PDF wants TOC above body.
#      We inject scripts/pdf-print-overrides.css into <head> so @media print
#      collapses TOC to one column and breaks the page after it.
#   2. The CSS also tames mermaid (no edge orphans), expands Source Pointers
#      <details> in print, and preserves the terminal theme dark surface.
#   3. We then drive a headless Chromium with --print-to-pdf.
#   4. Failure fallback: print the temp HTML path so the user can manually
#      Cmd+P / Ctrl+P → "Save as PDF".
# ─────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  sed -n '2,28p' "$0"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSS_FILE="$SCRIPT_DIR/pdf-print-overrides.css"

INPUT=""
OUTPUT=""
for arg in "$@"; do
  case "$arg" in
    --help|-h)    usage; exit 0 ;;
    --input=*)    INPUT="${arg#--input=}" ;;
    --input)      shift; INPUT="${1:-}" ;;
    --output=*)   OUTPUT="${arg#--output=}" ;;
    --output)     shift; OUTPUT="${1:-}" ;;
    --*)          echo "✗ 未知参数: $arg" >&2; exit 1 ;;
    *)
      if   [[ -z "$INPUT"  ]]; then INPUT="$arg"
      elif [[ -z "$OUTPUT" ]]; then OUTPUT="$arg"
      fi
      ;;
  esac
done

INPUT="${INPUT:-article/article.html}"
OUTPUT="${OUTPUT:-article/article.pdf}"

if [[ ! -f "$INPUT" ]]; then
  echo "✗ 输入文件不存在：$INPUT" >&2
  echo "  先在工作区跑 \`npm run html\` 产出 article/article.html。" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

# ── Detect chromium-family browser ─────────────────────────
find_browser() {
  local candidates=(
    chromium
    chromium-browser
    google-chrome
    google-chrome-stable
    chrome
    brave-browser
    microsoft-edge
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
    "/Applications/Arc.app/Contents/MacOS/Arc"
    "/usr/bin/chromium"
    "/usr/bin/google-chrome"
    "/snap/bin/chromium"
    "/c/Program Files/Google/Chrome/Application/chrome.exe"
    "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
    "/c/Program Files/Microsoft/Edge/Application/msedge.exe"
    "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
  )
  for c in "${candidates[@]}"; do
    if command -v "$c" >/dev/null 2>&1; then
      echo "$c"; return 0
    fi
    if [[ -x "$c" ]]; then
      echo "$c"; return 0
    fi
  done
  return 1
}

# ── Inject @media print overrides into a temp HTML ─────────
TMP_DIR="$(mktemp -d -t beautiful-codebase-pdf.XXXXXX)"
TMP_HTML="$TMP_DIR/article-print.html"

if [[ ! -f "$CSS_FILE" ]]; then
  echo "✗ 找不到打印覆盖 CSS：$CSS_FILE" >&2
  echo "  这个文件应跟脚本同目录（scripts/pdf-print-overrides.css）。" >&2
  exit 2
fi

awk -v css_file="$CSS_FILE" '
  /<\/head>/ && !done {
    print "<style id=\"bc-pdf-overrides\">"
    while ((getline line < css_file) > 0) print line
    close(css_file)
    print "</style>"
    done = 1
  }
  { print }
' "$INPUT" > "$TMP_HTML"

if ! grep -q 'bc-pdf-overrides' "$TMP_HTML"; then
  echo "✗ 注入失败：未在输入 HTML 找到 </head>。" >&2
  echo "  你的 article.html 可能不是 Vite + reacticle 单页产物。" >&2
  exit 3
fi

# ── Locate browser ──────────────────────────────────────────
BROWSER="$(find_browser || true)"
if [[ -z "$BROWSER" ]]; then
  echo "⚠ 未找到任何 chromium-family 浏览器（chromium / chrome / brave / edge）。"
  echo
  echo "  回退方案：注入了打印 CSS 的 HTML 已经放在："
  echo "  $TMP_HTML"
  echo
  echo "  请用浏览器打开它 → Cmd+P / Ctrl+P → 目标改为'另存为 PDF' → 保存。"
  exit 3
fi

echo "▸ 用浏览器：$BROWSER"
echo "▸ 输入：$INPUT"
echo "▸ 输出：$OUTPUT"

# ── Render ─────────────────────────────────────────────────
# --no-pdf-header-footer / --print-to-pdf-no-header: drop browser-supplied chrome.
# --virtual-time-budget=8000: give mermaid + Raw extra time to finish render
#   (terminal theme + Section 05 flowcharts are heavier than a typical article).
# --hide-scrollbars: avoid scrollbar shadow.
"$BROWSER" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --hide-scrollbars \
  --no-pdf-header-footer \
  --virtual-time-budget=8000 \
  --print-to-pdf-no-header \
  --print-to-pdf="$OUTPUT" \
  "file://$TMP_HTML" 2>/dev/null || {
    # Old Chrome lacks --headless=new; retry with legacy --headless.
    "$BROWSER" \
      --headless \
      --disable-gpu \
      --no-sandbox \
      --hide-scrollbars \
      --print-to-pdf-no-header \
      --print-to-pdf="$OUTPUT" \
      "file://$TMP_HTML" 2>/dev/null
  }

rm -rf "$TMP_DIR"

if [[ -f "$OUTPUT" ]]; then
  SIZE="$(du -h "$OUTPUT" 2>/dev/null | cut -f1)"
  echo "✓ PDF 输出：${OUTPUT} (${SIZE:-?})"
  echo
  echo "  如果 TOC / 分页 / mermaid 不理想，看 references/pdf-output.md 故障排除段。"
else
  echo "✗ 浏览器返回成功但输出文件不存在：$OUTPUT" >&2
  exit 4
fi
