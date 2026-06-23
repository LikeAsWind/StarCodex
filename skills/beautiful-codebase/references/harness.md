# Harness · 构建 Harness 说明

> **何时读**: Phase 3.1 创建工程后；Phase 6 构建交付物时

## 1 · 构建流程

```
scaffold.sh -> npm install -> Phase 3-5 写作 -> npm run build -> npm run html -> article/article.html
```

## 2 · Harness 脚本

`scripts/harness.sh` 封装了从 scaffold 到交付的完整流程：

```bash
# 完整管线
bash harness.sh ./<project>-analysis --target /path/to/project --theme=terminal

# 等价于手动执行:
mkdir -p discovery/
# ... Phase 1
# ... Phase 2
# ... Phase 3-5
npm run build
npm run html
```

## 3 · 输出

- `dist/index.html` — Vite 构建输出（CSS+JS 内联）
- `article/article.html` — 最终交付物（自包含单文件 HTML）
- `analysis-snapshot.json` — 元数据快照

## 4 · 常用命令速查

| 命令 | 用途 |
|------|------|
| `npm run dev` | 起 Vite 预览（Phase 3-4 边写边看） |
| `npm run typecheck` | tsc --noEmit |
| `npm run build` | tsc + vite build -> dist/index.html |
| `npm run html` | 复用 build，再复制为 article/article.html |
| `npm run preview` | 预览 dist/ |

> HTML 构建结果在 `npm run build` + `npm run html` 之后交付。
