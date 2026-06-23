# Theme Selection · 主题选择指南

> **何时读**: Phase 1 规划报告时；Phase 3 创建工程前

## 1 · 可用主题

| 主题 | 气质 | 适用场景 | 默认 |
|------|------|---------|------|
| terminal | 暗底终端、等宽、语义色 | 代码分析首选 | ✅ |
| tufte | 亮底、克制的 data-ink、边注 | 学术/研究型项目 | |
| press | 暖底、书卷感、衬线 | 叙事型/编辑型项目 | |

## 2 · 选择依据

- **代码分析报告首选 terminal**: 暗底让 SVG 图中的 accent 色更突出
- **学术/算法库用 tufte**: 需要大段边注和引用
- **编辑系统/CMS 项目用 press**: 输出风格接近出版文档

## 3 · 切换主题

改两处保证一致：
1. `article/main.tsx` 的 `<ThemeProvider theme="...">`
2. `article/Article.tsx` 末尾 colophon "路 <主题> theme"

## 4 · Reader profile 与主题对照

| Profile | 推荐主题 | 理由 |
|---------|---------|------|
| archaeology | terminal | 暗底高对比，调用链 SVG 清晰 |
| architecture-review | terminal | 多模块拓扑图需要语义色区分 |
| onboarding | press 或 terminal | 暖底亲和 or 终端专业 |
