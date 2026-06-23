# Plan Template · `plan/plan.md` 简化模板

> **何时读**：Phase 2 写 `plan/plan.md` 时

章节固定，Plan 只是确认数据完整性，不是创作。

## 完整模板

```markdown
# Plan

## Brief

- 目标项目：<path>
- 工具 tier：<codegraph-indexed | rg | grep>
- 入口点数量：<N>
- 章节数量：<3 core + N entries + 2 (summary + colophon)>
- 总分析文件数：<from inventory.json>
- 总代码行数：<from inventory.json>

## Entrypoints

| ID | 名称 | 入口 file:line | 路由 | 涉及文件数 | 调用深度 | 来源 |
|----|------|---------------|------|-----------|---------|------|
| order-create | 下单流程 | src/routers/order.py:25 | POST /orders | 12 | 5 | codegraph |
| refund-create | 退款流程 | src/routers/refund.py:15 | POST /refunds | 8 | 3 | codegraph |

## Sections

| # | 标题 | 数据源 |
|---|------|--------|
| 00 | Cover | inventory |
| 01 | 项目概览 | codebase + entrypoints 综合 |
| 02 | 业务功能总览 | entrypoints.json |
| 03 | 项目架构图 | codegraph 模块依赖 |
| 04 | 下单流程 | callgraphs/order-create.json |
| 05 | 退款流程 | callgraphs/refund-create.json |
| ... | ... | ... |
| N+1 | 总结 | 全局汇总 |
| N+2 | Colophon | 固定 |
```

写完即可，无需用户确认，直接进入 Phase 3。