# HTML Output · 构建与交付

> **何时读**: Phase 6 构建/交付时

## 1 · 构建管线

```bash
# 完整构建
npm run build       # tsc --noEmit + vite build -> dist/index.html
npm run html        # 复制 dist/index.html -> article/article.html

# 仅类型检查
npm run typecheck   # tsc --noEmit

# 预览
npm run dev         # 开发预览
npm run preview     # 构建后预览 dist/
```

## 2 · 交付物

| 产物 | 路径 | 说明 |
|------|------|------|
| 主交付物 | `article/article.html` | 自包含单文件 HTML |
| 元数据 | `analysis-snapshot.json` | 工具 tier / 时间戳 / 项目信息 |

## 3 · 质量验证

交付前验证清单：
- [ ] `file://` 协议离线打开
- [ ] 所有 SVG 流程图正常渲染
- [ ] TOC 链接可点击跳转
- [ ] 字体正确（不是 fallback 到系统 sans-serif）
- [ ] 控制台无 404
- [ ] article.html < 5MB
