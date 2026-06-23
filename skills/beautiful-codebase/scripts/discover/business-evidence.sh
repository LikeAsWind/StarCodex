#!/usr/bin/env bash
# scripts/discover/business-evidence.sh
# Phase 1 Discover: 采集 3 类可验证的业务证据到 discovery/business-evidence/
set -euo pipefail

TARGET="${1:-.}"
OUT_DIR="${2:-$TARGET/discovery/business-evidence}"
mkdir -p "$OUT_DIR"

echo "=== 1/3: Tests ==="
find "$TARGET" -path "*/test*" -name "*.py" -o -path "*/test*" -name "*.ts" -o -path "*/test*" -name "*.js" 2>/dev/null \
  | head -100 > "$OUT_DIR/tests.jsonl" || touch "$OUT_DIR/tests.jsonl"
echo "  $(wc -l < "$OUT_DIR/tests.jsonl") files"

echo "=== 2/3: Schema (DDL/Models) ==="
rg --no-heading -n "CREATE TABLE|class\s+\w+\(|@Entity|\.objects\.create|type\s+\w+\s*=\s*{" "$TARGET" --include="*.py" --include="*.java" --include="*.sql" --include="*.ts" 2>/dev/null \
  > "$OUT_DIR/schema.md" || touch "$OUT_DIR/schema.md"
echo "  $(wc -l < "$OUT_DIR/schema.md") lines"

echo "=== 3/3: Configs ==="
rg --no-heading -n "^\s*(CONFIG|ENV|SECRET|API_KEY|APP_|DB_|REDIS_|PORT|HOST)" "$TARGET" --include="*.py" --include="*.env" --include="*.yaml" --include="*.yml" 2>/dev/null \
  > "$OUT_DIR/configs.md" || touch "$OUT_DIR/configs.md"
echo "  $(wc -l < "$OUT_DIR/configs.md") lines"

echo "=== Business evidence collection complete (3 types: tests / schema / configs) ==="
