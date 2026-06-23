#!/usr/bin/env bash
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# scaffold.sh 鈥斺€?Create a beautiful-codebase analysis workspace.
#
# Usage:
#   (cover is always on; --no-cover deprecated)]
#   bash scripts/scaffold.sh --list-themes
#   bash scripts/scaffold.sh --help
#
# Examples:
#   bash <skill>/scripts/scaffold.sh ./StarCodex-analysis --theme=terminal
#   (cover is always on; --no-cover deprecated)
#   bash <skill>/scripts/scaffold.sh --list-themes
#
# Defaults:
#   鈥?--theme=terminal (code-native dark surface; per Q8)
#   鈥?cover ON (3:4 screen + own-page in PDF; --no-cover to disable)
#
# The workspace is created at the given target dir (typically a sibling of the
# analyzed project 鈥?never written into the analyzed project itself, see
# Vite + React + TS + reacticle + mermaid; reacticle
# pulled from npm latest at scaffold time.
#
# After scaffold:
#   cd <target>
#   npm run dev      # preview
#   # Phase 3: replace article/Cover.tsx <CoverPlaceholder /> + sections/01-verdict.tsx
#   # Phase 4: write each Section through three-stage pipeline
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
set -euo pipefail

usage() {
  sed -n '2,28p' "$0"
}

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$SKILL_DIR/assets/scaffold-template"
PROFILES="$SKILL_DIR/theme-profiles/index.json"
DEFAULT_THEME="terminal"

list_themes() {
  echo "鍙敤涓婚锛堟潵鑷?${PROFILES}锛?"
  echo
  grep -E '"id"|"label"|"mood"' "$PROFILES" | sed -E \
    -e 's/.*"id":[[:space:]]*"([^"]+)".*/  鈥?\1/' \
    -e 's/.*"label":[[:space:]]*"([^"]+)".*/      \1/' \
    -e 's/.*"mood":[[:space:]]*"([^"]+)".*/      \1/'
  echo
  echo "鐢?--theme=<id> 閫夊畾涓€涓€傞粯璁わ細${DEFAULT_THEME}锛坈ode-native锛夈€?
}

theme_exists() {
  grep -Eq "\"id\"[[:space:]]*:[[:space:]]*\"$1\"" "$PROFILES"
}

# 鈹€鈹€ Parse args 鈹€鈹€
TARGET=""
THEME="$DEFAULT_THEME"
COVER=1
SKIP_INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --help|-h)        usage; exit 0 ;;
    --list-themes)    list_themes; exit 0 ;;
    --theme=*)        THEME="${arg#--theme=}" ;;
    --no-cover)       COVER=0 ;;  (deprecated — cover is always on now)
    --cover)          COVER=1 ;;
    --skip-install)   SKIP_INSTALL=1 ;;
    --*)              echo "鉁?鏈煡鍙傛暟: $arg" >&2; exit 1 ;;
    *)                [[ -z "$TARGET" ]] && TARGET="$arg" ;;
  esac
done

TARGET="${TARGET:-my-codebase-analysis}"

# 鈹€鈹€ Validate theme 鈹€鈹€
if ! theme_exists "$THEME"; then
  echo "鉁?鏈煡涓婚 '$THEME'銆傚彲鐢ㄤ富棰橈細" >&2
  echo >&2
  list_themes >&2
  exit 1
fi

# 鈹€鈹€ Target directory check 鈹€鈹€
if [[ -d "$TARGET" && -n "$(ls -A "$TARGET" 2>/dev/null || true)" ]]; then
  echo "鉁?鐩爣鐩綍 '$TARGET' 宸插瓨鍦ㄤ笖闈炵┖锛屽凡涓銆? >&2
  exit 1
fi
if [[ "$SKIP_INSTALL" == "0" ]] && ! command -v npm >/dev/null; then
  echo "鉁?闇€瑕?npm锛屼絾鍦?PATH 閲屾病鎵惧埌銆傦紙鐢?--skip-install 璺宠繃渚濊禆瀹夎鍋?dry-run锛? >&2
  exit 1
fi

echo "鈻?鍦?$TARGET 鍒涘缓 beautiful-codebase 宸ヤ綔鍖?
echo "鈻?涓婚锛?THEME"
echo "鈻?灏侀潰锛?([[ "$COVER" == "1" ]] && echo "寮€锛堝睆骞?3:4 / PDF 鐙崰棣栭〉锛岃瑙?references/cover.md锛? || echo "鍏?)"
echo "鈻?reacticle锛氫粠 npm 瀹夎鏈€鏂板彂甯冪増"

# 鈹€鈹€ Create workspace tree 鈹€鈹€
mkdir -p "$TARGET"

cp "$TEMPLATE/package.json"        "$TARGET/package.json"
cp "$TEMPLATE/vite.config.ts"      "$TARGET/vite.config.ts"
cp "$TEMPLATE/tsconfig.json"       "$TARGET/tsconfig.json"
cp "$TEMPLATE/tsconfig.node.json"  "$TARGET/tsconfig.node.json"
cp "$TEMPLATE/index.html"          "$TARGET/index.html"

# Article source
mkdir -p "$TARGET/article/sections" "$TARGET/article/raw-blocks" "$TARGET/article/assets"
cp "$TEMPLATE/article/main.tsx"               "$TARGET/article/main.tsx"
cp "$TEMPLATE/article/Article.tsx"            "$TARGET/article/Article.tsx"
cp "$TEMPLATE/article/sections/01-verdict.tsx" "$TARGET/article/sections/01-verdict.tsx"
if [[ "$COVER" == "1" ]]; then
  cp "$TEMPLATE/article/Cover.tsx" "$TARGET/article/Cover.tsx"
fi

# Discovery / plan / review long-term-memory dirs (Q7 workspace structure)
mkdir -p \
  "$TARGET/discovery/buckets" \
  "$TARGET/discovery/business-evidence" \
  "$TARGET/plan" \
  "$TARGET/review"

# Discovery placeholders
echo '{}'  > "$TARGET/discovery/inventory.json"
echo '{}'  > "$TARGET/discovery/tier.json"
echo '{}'  > "$TARGET/discovery/tools.json"
touch      "$TARGET/discovery/buckets/.gitkeep"
cat > "$TARGET/discovery/codebase-brief.md" <<'EOF'
# Codebase Brief

(Phase 1 Discover writes this file. ~200 lines covering language stats / LOC /
top modules / commit cadence / contributors / key entry points.)
EOF

# Business evidence stubs (Phase 1 fills them; see
# references/business-evidence-collection.md)
: > "$TARGET/discovery/business-evidence/comments.jsonl"
: > "$TARGET/discovery/business-evidence/tests.jsonl"
cat > "$TARGET/discovery/business-evidence/schema.md"        <<'EOF'
# Schema Evidence

(Phase 1 Discover collects DB DDL / migrations into this file.)
EOF
cat > "$TARGET/discovery/business-evidence/configs.md"       <<'EOF'
# Configs Evidence

(Phase 1 Discover collects config files + enum constants here.)
EOF
cat > "$TARGET/discovery/business-evidence/docs.md"          <<'EOF'
# Docs Evidence

(Phase 1 Discover collects README / docs/ / wiki links here.)
EOF
cat > "$TARGET/discovery/business-evidence/commit-themes.md" <<'EOF'
# Commit Themes

(Phase 1 Discover clusters ~200 recent commit messages here.)
EOF

# Plan placeholder (Phase 2 fills it; references/plan-template.md is the
# authoritative template)
cat > "$TARGET/plan/plan.md" <<'EOF'
# Plan

> Phase 2 fills this from references/plan-template.md (Brief / Outline / Theme /
> Assets). 
> happens inline in main agent before Checkpoint 1.

## Brief

(reader profile 路 retention 路 target language 路 width 路 TOC 路 asset mode 路
tool tier 路 size tier 路 git remote 路 鈥?

## Outline

(姣忚妭浜旇锛氱紪鍙?+ 鍚嶇О + bucket 寮曠敤 + 涓氬姟-Job + 蹇呴』淇濈暀淇℃伅 +
Mermaid/Table/CodeBlock 鍙栬垗)

## Theme

(terminal / tufte / press 路 涓€鍙ョ悊鐢?

## Assets

(榛樿 none 鈥?Mermaid 鏄富瑙嗚)
EOF

touch "$TARGET/review/.gitkeep"
echo '{}' > "$TARGET/analysis-snapshot.json"

# Workspace README 鈥?quick orientation
cat > "$TARGET/README.md" <<EOF
# $(basename "$TARGET") 路 beautiful-codebase 宸ヤ綔鍖?
| 璺緞 | 鍐呭 |
|---|---|
| \`discovery/\` | Phase 1 浜у嚭锛歵ools.json / tier.json / inventory.json / buckets/ / business-evidence/ / codebase-brief.md |
| \`plan/plan.md\` | Phase 2 浜у嚭锛欱rief / Outline / Theme / Assets |
| \`article/Article.tsx\` | Assembler锛堜富 Agent 鎷ユ湁锛夛紝import + 鎺掑簭鍚?Section |
| \`article/Cover.tsx\` | 鎶ュ憡灏侀潰锛?:4 灞忓箷 / PDF 鐙崰棣栭〉锛?([[ "$COVER" == "1" ]] && echo "" || echo "锛堝凡鍏抽棴锛?) |
| \`article/sections/NN-*.tsx\` | 娓叉煋 prose锛圫tep B 杈撳嚭锛夆€斺€?涓€鑺備竴鏂囦欢閾佸緥 |
| \`article/sections/NN-evidence.md\` | Step A 杈撳嚭锛歷erbatim 婧愮爜 + codegraph 鏌ヨ缁撴灉 |
| \`article/sections/NN-business.md\` | Step A.5 杈撳嚭锛氫笟鍔￠檲杩板甫 [璇佹嵁: file:line] 寮曠敤 |
| \`article/raw-blocks/\` | 澶у瀷 Raw锛圫VG 澶嶆潅搴︾儹鍥俱€佸鏉傚皝闈級闅旂鍒拌繖閲?|
| \`article/article.html\` | Phase 6 涓讳氦浠樼墿锛氳嚜鍖呭惈鍗曢〉 HTML |
| \`review/first-spread-review.md\` | Phase 3 浜х墿 |
| \`review/final-review.md\` | Phase 5 浜х墿 |
| \`analysis-snapshot.json\` | 宸ュ叿鐗堟湰 / SHA / 鏃堕棿鎴?/ inventory diff |

## 甯哥敤鍛戒护

\`\`\`bash
npm run dev        # 璧?Vite 棰勮锛圥hase 3 / 4 杈瑰啓杈圭湅锛?npm run typecheck  # tsc --noEmit
npm run build      # tsc + 鍗曢〉 HTML 鈫?dist/index.html锛圕SS+JS 鍐呰仈锛?npm run html       # 澶嶇敤 build锛屽啀澶嶅埗涓轰氦浠樼墿 article/article.html
\`\`\`

## 鍒囦富棰?
鏀逛袱澶勪繚鎸佷竴鑷达細

1. \`article/main.tsx\` 鐨?\`<ThemeProvider theme="...">\`锛堣繍琛屾椂涓婚锛夈€?2. \`article/Article.tsx\` 鏈熬 colophon \`路 <涓婚> theme\`锛堝嵃璁颁富棰樺悕锛夈€?
鍙敤涓婚锛歕`terminal\`锛堥粯璁?路 code-native锛? \`tufte\` / \`press\`锛堜笌
\`<skill>/theme-profiles/index.json\` 涓€鑷达級銆?
## 涓夐樁娈靛啓

姣忎釜 Section 璧?Evidence 鈫?Business 鈫?Writing锛岃瑙?\`<skill>/references/section-build.md\`銆?Step B Writing SubAgent 鐗╃悊闅旂 repo 璁块棶锛屽彧璇?\`NN-evidence.md\` + \`NN-business.md\`
涓や釜鏂囦欢 鈥斺€?杩欐槸鍙嶅够瑙夌殑鏈€鍚庨槻绾裤€?
璧锋涓婚锛?THEME锛堣 \`.theme\`锛?EOF

# Track empty dirs for git
touch "$TARGET/article/raw-blocks/.gitkeep" "$TARGET/article/assets/.gitkeep"

# 鈹€鈹€ Inject theme id (use perl to dodge sed escaping) 鈹€鈹€
export RA_THEME="$THEME"
perl -pi -e 's/__THEME__/$ENV{RA_THEME}/g' "$TARGET/article/main.tsx"
perl -pi -e 's/__THEME__/$ENV{RA_THEME}/g' "$TARGET/article/Article.tsx"

# 鈹€鈹€ Inject beautiful-codebase repo URL into Article.tsx colophon 鈹€鈹€
# The colophon credits the **skill itself** (Made with beautiful-codebase 鈫?,
# NOT the project being analyzed. So this URL is fixed at scaffold time and
# always resolves to wherever the skill source lives.
#
# When the skill moves to its own repo, update this single constant; the
# template carries the placeholder __BEAUTIFUL_CODEBASE_REPO__.
export RA_REPO_URL="https://github.com/LikeAsWind/StarCodex/tree/master/skills/beautiful-codebase"
perl -pi -e 's{__BEAUTIFUL_CODEBASE_REPO__}{$ENV{RA_REPO_URL}}g' "$TARGET/article/Article.tsx"

# 鈹€鈹€ Cover toggle (mirror beautiful-article logic) 鈹€鈹€
if [[ "$COVER" == "1" ]]; then
  perl -i -ne 'print unless /__COVER_(IMPORT|RENDER)_(BEGIN|END)__/' "$TARGET/article/main.tsx"
else
  perl -i -0pe 's{[^\n]*__COVER_IMPORT_BEGIN__.*?__COVER_IMPORT_END__[^\n]*\n}{}gs' "$TARGET/article/main.tsx"
  perl -i -0pe 's{[^\n]*__COVER_RENDER_BEGIN__.*?__COVER_RENDER_END__[^\n]*\n}{}gs' "$TARGET/article/main.tsx"
fi

# Marker file for theme + dry-run flag
echo "$THEME" > "$TARGET/.theme"

# 鈹€鈹€ Install deps (skippable for dry-run / CI) 鈹€鈹€
if [[ "$SKIP_INSTALL" == "1" ]]; then
  echo "鈻?--skip-install 宸蹭紶鍏ワ細璺宠繃 npm install銆傝鍦?$TARGET 鎵嬪姩璺?npm install / typecheck銆?
  echo
  echo "鉁?瀹屾垚锛坉ry-run锛夈€傚伐浣滃尯锛?TARGET锛堜富棰?$THEME锛?
  exit 0
fi

cd "$TARGET"
echo "鈻?瀹夎渚濊禆锛堝惈 reacticle 鏈€鏂扮増锛屽彲鑳借绛変竴浼氾級..."
npm install >/dev/null 2>&1 || {
  echo "鈿?npm install 澶辫触 鈥斺€?妫€鏌ョ綉缁滄垨浠ｇ悊銆傚凡缁忓垱寤哄ソ宸ヤ綔鍖烘枃浠讹紝鍙互鎵嬪姩閲嶈瘯銆? >&2
  exit 0
}
npm install reacticle@latest >/dev/null 2>&1 || true

INSTALLED_REACTICLE="$(node -e "console.log(JSON.parse(require('fs').readFileSync('node_modules/reacticle/package.json','utf8')).version)" 2>/dev/null || echo '?')"
echo "鈻?reacticle 鐗堟湰锛?INSTALLED_REACTICLE"

echo "鈻?璺戜竴娆?typecheck 纭鎺ョ嚎 OK ..."
if npx tsc --noEmit; then
  echo "鉁?typecheck 閫氳繃"
else
  echo "鈿?typecheck 鏈夐棶棰橈紙瑙佷笂锛夛紝dev / build 浠嶅彲鑳芥甯?鈥斺€?璇蜂汉宸ョ‘璁ゃ€? >&2
fi

cat <<EOF

鉁?瀹屾垚銆傚伐浣滃尯锛?TARGET锛堜富棰?$THEME锛岃 .theme锛況eacticle $INSTALLED_REACTICLE锛?
涓嬩竴姝ワ細
  1. cd $TARGET
  2. 缁х画 Phase 1 Discover锛氳窇 \`<skill>/scripts/discover/*.sh\` 绯诲垪濉?discovery/銆?  3. Phase 2 Plan锛氬啓 plan/plan.md锛堟寜 references/plan-template.md锛夈€?  4. Phase 3 First Spread锛氭浛鎹?article/Cover.tsx <CoverPlaceholder /> 涓?     article/sections/01-verdict.tsx 鈥斺€?璧板畬鏁翠笁闃舵锛圗vidence 鈫?Business 鈫?Writing锛夈€?  5. Phase 4: subsequent sections, mode A 鍗?Agent / B 澶?Agent 骞惰锛圕heckpoint 2 閫夊畾锛夈€?
鏋勫缓浜や粯锛圥hase 6锛夛細
  鈥?npm run build     # 绫诲瀷妫€鏌?+ 鍗曢〉 HTML 鈫?dist/index.html锛圕SS+JS 鍐呰仈锛?  鈥?npm run html      # 澶嶇敤 build锛屽啀澶嶅埗涓轰氦浠樼墿 article/article.html
  鈥?bash <skill>/scripts/html-to-pdf.sh   # 鍙€?PDF锛圕heckpoint 3 閫夊畾鍚庯級

鍒囦富棰橈細鏀?article/main.tsx 鐨?<ThemeProvider theme="..."> 涓€瀛楋紙terminal / tufte / press锛夈€?鍗囩骇缁勪欢搴擄細npm install reacticle@latest

鍐欎綔蹇呰锛堣矾寰勫湪 Skill 浠撳簱鍐咃級锛?  鈥?$SKILL_DIR/references/section-build.md
  鈥?$SKILL_DIR/references/component-policy.md
  鈥?$SKILL_DIR/references/raw-policy.md
  鈥?$SKILL_DIR/theme-profiles/$THEME.md
EOF
