# Component Policy · 组件规范

> **何时读**：Phase 3 每写一个章节时

## 1 · 可用的 reacticle 组件

| 组件 | 用途 | 限制 |
|------|------|------|
| `<Section>` | 每章根组件，必须 | 必须带 `index` 和 `title` props |
| `<p>` | 正文段落 | 自由使用 |
| `<Aside>` | 重点提示/标注 | 用于"业务分析"中的关键推断 |
| `<Raw>` | SVG 流程图、自定义排版 | 见 raw-policy.md |
| `<details>`+`<summary>` | 折叠的完整调用列表 | HTML 原生，直接写在 prose 中 |

## 2 · 组件使用优先级

```
prose 段落（<p>） → 主要的表达方式
SVG 流程图（<Raw>） → 调用链可视化
<Aside> → 标注"基于代码结构推断"的关键结论
<details> → 折叠长调用列表
```

## 3 · 禁止的组件和模式

- ? mermaid（用 SVG 替代）
- ? `<Quote>` 组件（没有引用来源）
- ? `<CodeBlock>`（代码太长，用 `file:line` 引用替代）
- ? 外部图片（必须是内联 SVG 或 CSS）