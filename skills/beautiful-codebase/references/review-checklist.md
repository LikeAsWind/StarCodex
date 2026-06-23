# Review Checklist · 终审检查清单

> **何时读**: Phase 5 Final Review 逐项检查时

## 1 · 全文审计项

### 覆盖度 (coverage.sh)
- [ ] 每个 inventory 文件都被至少一个 Section 的 evidence.md 收纳
- [ ] 没有被漏掉的高价值文件（大型核心文件、高频变更文件）

### 新鲜度 (freshness.sh)
- [ ] 自 Phase 1 以来 repo 是否发生了变化？如有，标注差异

### 密度 (density.sh)
- [ ] 全篇 CodeBlock 数量 <= 功能链路数 * 2
- [ ] prose : code 比例 >= 60:40

### 声明可追溯 (claim-trace.sh)
- [ ] 随机抽 5 个技术断言的 file:line 引用，均能在 evidence.md 中找到
- [ ] 随机抽 5 个业务陈述的 [证据:] 引用，均能在 business.md 中找到

### 序号自洽
- [ ] TOC 显示序号连续，无跳号/重复
- [ ] Section index 与文件前缀 NN 一致

## 2 · 视觉审计

- [ ] 所有 SVG 流程图正常渲染
- [ ] 封面图文并茂，无占位符
- [ ] Terminal 暗底颜色对比度可读
- [ ] mobile viewport 下无溢出
- [ ] 打印预览无错位

## 3 · 构建验证

- [ ] `npm run typecheck` 通过
- [ ] `npm run build` 通过
- [ ] `article/article.html` 可离线打开
