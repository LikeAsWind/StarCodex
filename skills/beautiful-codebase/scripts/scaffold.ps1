#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Create a beautiful-codebase analysis workspace (Vite + React + TS).
.DESCRIPTION
  Copies scaffold template from assets/scaffold-template/, replaces placeholders,
  installs npm dependencies, and runs typecheck. PowerShell equivalent of scaffold.sh.
.PARAMETER TargetDir
  Path to the target workspace directory.
.PARAMETER Theme
  Theme ID from theme-profiles/index.json (terminal, tufte, press). Default: terminal.
.PARAMETER NoCover
  Disable cover page (deprecated — cover is always on by default).
.PARAMETER SkipInstall
  Skip npm install (dry-run / offline).
.PARAMETER ListThemes
  List available themes and exit.
.PARAMETER Help
  Show this help message.
.EXAMPLE
  .\scaffold.ps1 ./StarCodex-analysis --Theme terminal
.EXAMPLE
  .\scaffold.ps1 --ListThemes
.EXAMPLE
  .\scaffold.ps1 ./test --SkipInstall
#>

param(
  [Parameter(Position = 0)]
  [string]$TargetDir = "",

  [string]$Theme = "terminal",

  [switch]$NoCover,

  [switch]$SkipInstall,

  [switch]$ListThemes,

  [switch]$Help
)

# Helper: resolve skill directory (location of this script's grandparent)
$ScriptPath = if ($MyInvocation.MyCommand.Path) {
  Split-Path $MyInvocation.MyCommand.Path -Parent
} else {
  # fallback for dot-sourcing
  Split-Path $PSScriptRoot -Parent
}
$SkillDir = Split-Path $ScriptPath -Parent
$TemplateDir = Join-Path $SkillDir "assets\scaffold-template"
$ProfilesFile = Join-Path $SkillDir "theme-profiles\index.json"
$DefaultTheme = "terminal"

# ---- Functions ----
function List-Themes {
  $profiles = Get-Content $ProfilesFile -Raw | ConvertFrom-Json
  Write-Host "可用主题（来自 $ProfilesFile）：" -ForegroundColor Cyan
  Write-Host ""
  foreach ($p in $profiles) {
    Write-Host "  • $($p.id)" -ForegroundColor Green
    Write-Host "     $($p.label)" -ForegroundColor Gray
    Write-Host "     $($p.mood)"
  }
  Write-Host ""
  Write-Host "用 --Theme <id> 选定一个。默认：$DefaultTheme（code-native）。" -ForegroundColor Cyan
}

function Test-ThemeExists {
  param([string]$id)
  $profiles = Get-Content $ProfilesFile -Raw | ConvertFrom-Json
  return ($profiles.id -contains $id)
}

# ---- Argument handling ----
if ($Help) {
  Get-Help $MyInvocation.MyCommand.Path
  exit 0
}

if ($ListThemes) {
  List-Themes
  exit 0
}

if ($NoCover) {
  Write-Warning "--NoCover 已废弃，封面始终启用"
}

if ([string]::IsNullOrEmpty($TargetDir)) {
  $TargetDir = "my-codebase-analysis"
}

# ---- Validate theme ----
if (-not (Test-ThemeExists $Theme)) {
  Write-Host "❌ 未知主题 '$Theme'。可用主题：" -ForegroundColor Red
  Write-Host ""
  List-Themes
  exit 1
}

# ---- Target directory check ----
if (Test-Path $TargetDir -PathType Container) {
  $items = Get-ChildItem $TargetDir
  if ($items.Count -gt 0) {
    Write-Host "❌ 目标目录 '$TargetDir' 已存在且非空，已中止。" -ForegroundColor Red
    exit 1
  }
}

if (-not $SkipInstall) {
  $npmPath = (Get-Command npm -ErrorAction SilentlyContinue).Path
  if (-not $npmPath) {
    Write-Host "❌ 需要 npm，但在 PATH 里没找到（用 --SkipInstall 跳过依赖安装做 dry-run）。" -ForegroundColor Red
    exit 1
  }
}

Write-Host "▸ 在 $TargetDir 创建 beautiful-codebase 工作区" -ForegroundColor Cyan
Write-Host "▸ 主题：$Theme" -ForegroundColor Cyan
Write-Host "▸ 封面：开（3:4 屏幕 / PDF 独占首页）" -ForegroundColor Cyan
Write-Host "▸ reacticle：从 npm 安装最新发布版" -ForegroundColor Cyan

# ---- Create workspace tree ----
$null = New-Item -ItemType Directory -Path $TargetDir -Force

# Engineering files
Copy-Item (Join-Path $TemplateDir "package.json")        (Join-Path $TargetDir "package.json")
Copy-Item (Join-Path $TemplateDir "vite.config.ts")      (Join-Path $TargetDir "vite.config.ts")
Copy-Item (Join-Path $TemplateDir "tsconfig.json")       (Join-Path $TargetDir "tsconfig.json")
Copy-Item (Join-Path $TemplateDir "tsconfig.node.json")  (Join-Path $TargetDir "tsconfig.node.json")
Copy-Item (Join-Path $TemplateDir "index.html")          (Join-Path $TargetDir "index.html")

# Article source
$null = New-Item -ItemType Directory -Path (Join-Path $TargetDir "article\sections") -Force
$null = New-Item -ItemType Directory -Path (Join-Path $TargetDir "article\raw-blocks") -Force
$null = New-Item -ItemType Directory -Path (Join-Path $TargetDir "article\assets") -Force

Copy-Item (Join-Path $TemplateDir "article\main.tsx")              (Join-Path $TargetDir "article\main.tsx")
Copy-Item (Join-Path $TemplateDir "article\Article.tsx")           (Join-Path $TargetDir "article\Article.tsx")
Copy-Item (Join-Path $TemplateDir "article\Cover.tsx")             (Join-Path $TargetDir "article\Cover.tsx")
Copy-Item (Join-Path $TemplateDir "article\sections\01-overview.tsx") (Join-Path $TargetDir "article\sections\01-verdict.tsx")

# Components
$null = New-Item -ItemType Directory -Path (Join-Path $TargetDir "article\components") -Force
$compDir = Join-Path $TemplateDir "article\components"
if (Test-Path $compDir) {
  Get-ChildItem $compDir -Filter "*.tsx" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $TargetDir "article\components\$($_.Name)")
  }
}

# Track empty dirs for git
$null = New-Item -ItemType File -Path (Join-Path $TargetDir "article\raw-blocks\.gitkeep") -Force
$null = New-Item -ItemType File -Path (Join-Path $TargetDir "article\assets\.gitkeep") -Force

# ---- Inject theme id ----
$mainTsx = Join-Path $TargetDir "article\main.tsx"
$articleTsx = Join-Path $TargetDir "article\Article.tsx"

(Get-Content $mainTsx -Raw) -replace '__THEME__', $Theme | Set-Content $mainTsx -NoNewline
(Get-Content $articleTsx -Raw) -replace '__THEME__', $Theme | Set-Content $articleTsx -NoNewline

# ---- Inject repo URL into colophon ----
$repoUrl = "https://github.com/LikeAsWind/StarCodex/tree/master/skills/beautiful-codebase"
$content = Get-Content $articleTsx -Raw
$content = $content -replace '__BEAUTIFUL_CODEBASE_REPO__', $repoUrl
Set-Content $articleTsx $content -NoNewline

# ---- Cover toggle ----
if ($NoCover) {
  # Remove __COVER_IMPORT_BEGIN__ .. __COVER_IMPORT_END__ block
  $text = Get-Content $mainTsx -Raw
  $text = $text -replace '(?s)[^\n]*__COVER_IMPORT_BEGIN__.*?__COVER_IMPORT_END__[^\n]*\n', ''
  $text = $text -replace '(?s)[^\n]*__COVER_RENDER_BEGIN__.*?__COVER_RENDER_END__[^\n]*\n', ''
  Set-Content $mainTsx $text -NoNewline
} else {
  # Strips the marker lines only, preserving Cover import and render
  $text = Get-Content $mainTsx -Raw
  $text = $text -replace '__COVER_IMPORT_BEGIN__\s*', ''
  $text = $text -replace '__COVER_IMPORT_END__\s*', ''
  $text = $text -replace '__COVER_RENDER_BEGIN__\s*', ''
  $text = $text -replace '__COVER_RENDER_END__\s*', ''
  Set-Content $mainTsx $text -NoNewline
}

# ---- Marker file ----
Set-Content (Join-Path $TargetDir ".theme") $Theme -NoNewline

# ---- Install deps ----
if ($SkipInstall) {
  Write-Host "▸ --SkipInstall 已传入：跳过 npm install。请在 $TargetDir 手动运行 npm install / typecheck。" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "✅ 完成（dry-run）。工作区：$TargetDir（主题 $Theme）"
  exit 0
}

Push-Location $TargetDir
try {
  Write-Host "▸ 安装依赖（含 reacticle 最新版，可能要等一会）..." -ForegroundColor Cyan
  npm install 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ npm install 失败 — 检查网络或代理。已创建好工作区文件，可以手动重试。" -ForegroundColor Yellow
    exit 0
  }

  npm install reacticle@latest 2>$null | Out-Null

  # Print reacticle version
  $pkgPath = Join-Path $TargetDir "node_modules\reacticle\package.json"
  $version = if (Test-Path $pkgPath) {
    $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
    $pkg.version
  } else { "?" }
  Write-Host "▸ reacticle 版本：$version" -ForegroundColor Cyan

  Write-Host "▸ 跑一次 typecheck 确认接线 OK ..." -ForegroundColor Cyan
  $tcResult = & npx tsc --noEmit 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ typecheck 通过" -ForegroundColor Green
  } else {
    Write-Host "⚠️ typecheck 有问题（见上），dev / build 仍可能正常 — 请人工确认。" -ForegroundColor Yellow
  }

  Write-Host @"

✅ 完成。工作区：$TargetDir（主题 $Theme，见 .theme；reacticle $version）
下一步：
  1. cd $TargetDir
  2. 继续 Phase 1 Discover：运行 <skill>/scripts/discover/*.ps1 系列填 discovery/。
  3. Phase 2 Plan：写 plan/plan.md（按 references/plan-template.md）。
  4. Phase 3 First Spread：替换 article/Cover.tsx <CoverPlaceholder /> 与
     article/sections/01-verdict.tsx —— 走完整三阶段（Evidence → Business → Writing）。
  5. Phase 4: subsequent sections, mode A 单 Agent / B 多 Agent 并行（Checkpoint 2 选定）。

构建交付（Phase 6）：
  • npm run build     # 类型检查 + 单页 HTML → dist/index.html（CSS+JS 内联）
  • npm run html      # 复用 build，再复制为交付物 article/article.html
  • <skill>/scripts/html-to-pdf.sh   # 可选 PDF（Checkpoint 3 选定后）

切主题：改 article/main.tsx 的 <ThemeProvider theme="..."> 一字（terminal / tufte / press）。
升级组件库：npm install reacticle@latest

写作必读（路径在 Skill 仓库内）：
  • $SkillDir/references/section-build.md
  • $SkillDir/references/component-policy.md
  • $SkillDir/references/raw-policy.md
  • $SkillDir/theme-profiles/$Theme.md
"@ -ForegroundColor Cyan, Gray, White
}
finally {
  Pop-Location
}
