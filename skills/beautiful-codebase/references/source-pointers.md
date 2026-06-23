# SourcePointers · 节脚 file:line 引用面板

> **何时读**: Phase 4 每节写 SourcePointers 时; Phase 5 终审 SourcePointers 完整性时

## 1 · 什么是 SourcePointers

每个 `<Section>` 的结尾必须有一个 `<SourcePointers>` 组件,列出本节引用的所有文件。这是
**可溯源性**的最后一道视觉保证:读者在节脚看到一份完整的引用清单,确认每个 claim 都有来源。

## 2 · 组件用法

```tsx
import { SourcePointers } from "../components/SourcePointers";

<Section index="04" title="下单流程">
  {/* ... prose / SVG / details ... */}
  <SourcePointers
    files={[
      { path: "src/routers/order.py", lines: [25, 30-48], summary: "订单入口路由" },
      { path: "src/services/order.py", lines: [12-55], summary: "订单验证与保存逻辑" },
      { path: "src/models/product.py", lines: [88-95], summary: "商品数据查询" },
    ]}
  />
</Section>
```

## 3 · 数据来源

- `evidence.md` 中的 verbatim 代码块 file:line-header
- `business.md` 中的 `[证据: file:line]` 引用
- plan.md Outline 行中的 bucket 文件列表

## 4 · 组件约定

- `path`: 相对项目根的文件路径
- `lines`: 行号范围数组
- `summary`: 该文件在本节中的角色(一句话)

## 5 · 每节必须

- [ ] `<SourcePointers>` 非空(至少 1 个文件)
- [ ] 每个 file:line 都能在 evidence.md 或 business.md 中找到
- [ ] summary 字段写的是"在本节中的角色",不是文件本身的通用描述
