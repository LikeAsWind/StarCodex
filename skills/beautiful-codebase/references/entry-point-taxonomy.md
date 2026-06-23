# Entry Point Taxonomy · 入口点分类体系

> **何时读**: Phase 1 Discover 完成入口点发现后，需要对入口点进行分类时

## 1 · 入口点类型

| 类型 | 代码示例 | 在报告中的呈现 |
|------|---------|-------------|
| HTTP Handler | `@router.post("/orders")` | 完整调用链路一章 |
| CLI Command | `def main():` / `cli.add_command()` | 完整调用链路一章 |
| Event Handler | `async def handle_order_created(event)` | 取决于事件链路深度 |
| Worker/Job | `@celery.task` / `def process_payment()` | 独立功能链路 |
| Library API | `def calculate_price(order) -> int` | 归入父级入口点 |
| Internal helper | `def _validate(x)` | 不独立成节 |

## 2 · 报告优先级

1. HTTP Handler > CLI Command > Event Handler > Worker
2. 按"调用链文件数"降序排列
3. 相同文件数的，按功能重要程度排列（HTTP > Event > Worker）

## 3 · Entrypoints JSON 字段

```json
{
  "id": "order-create",
  "type": "http-handler",
  "name": "下单流程",
  "priority": 1,
  "entry_symbol": "create_order_handler",
  "entry_file": "src/routers/order.py",
  "entry_line": 25,
  "source": "codegraph",
  "route": "POST /orders",
  "files_involved": 12,
  "depth": 5,
  "description": "基于代码结构推断：处理用户提交订单请求"
}
```
