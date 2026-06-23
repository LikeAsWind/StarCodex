# Bucket Strategy · 切桶策略

> **何时读**: Phase 1 Discover 完成入口点发现后，将文件分配到 bucket 时

## 1 · 什么是 Bucket

Bucket 是 Phase 1 将目标项目文件按"功能链路"分组的基本单位。每个 bucket 对应一封 report 中的一个 Section（04 下单流程 / 05 退款流程...）。

## 2 · 切桶原则

### 优先按入口点分配

每个入口点（entrypoint）自动成为一个 bucket：

```
POST /orders  → bucket: order-create  → Section 04
POST /refunds → bucket: refund-create  → Section 05
```

### 共享文件剥离

被 2+ 入口点引用的文件（如 `models/user.py`、`lib/validator.py`）放入 `__shared__` bucket，不归入任何功能链路 Section。

### 桶边界规则

| 条件 | 切桶方式 |
|------|---------|
| 入口点文件列表不重叠 | 每个入口点独立成桶 |
| 2 个入口点共享 > 60% 文件 | 合并为一个桶 |
| 入口点涉及 > 20 个文件 | 按目录/模块边界拆成子桶 |
| 文件不在任何入口点调用链中 | 放入 orphan bucket（Section 06） |

## 3 · Bucket JSON 格式

```json
{
  "bucket_id": "order-create",
  "entrypoint_id": "order-create",
  "name_cn": "下单流程",
  "files": ["src/routers/order.py", "src/services/order.py", ...],
  "depth": 5,
  "shared_files": ["src/models/user.py"],
  "orphan": false
}
```
