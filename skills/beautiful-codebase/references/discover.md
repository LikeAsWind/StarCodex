# Discover · Phase 1 入口发现与调用图采集

> **何时读**：Phase 1 开始时

整个 Phase 1 的目标：从目标项目中提取 **入口点 → 调用链路 → 文件清单**，全部基于 codegraph 调用图数据，不依赖注释/commit/文档等不可信输入。

## 1 · 工具探测

由 `scripts/probe-tools.sh --target <path> --json` 提供。检测：

- `codegraph` 是否在 PATH（及版本），目标项目是否已 `codegraph init`（`.codegraph/` 存在）
- `rg` 是否在 PATH
- `grep`（POSIX）

输出 tier 标签：`codegraph-indexed` / `codegraph-installed` / `rg` / `grep` / `none`

写入 `discovery/tools.json`。

## 2 · inventory 生成

由 `inventory.sh` 产出（保持原来不变）。

字段：
```json
{
  "target": "<absolute path>",
  "snapshot": "<ISO timestamp>",
  "tier": "<from tools.json>",
  "files": [
    {"path":"src/foo.py", "language":"python", "bytes":1234, "loc":56, "sha":"<sha1>", "excluded_reason": null},
    {"path":"vendor/lib.js", "excluded_reason":"vendored"}
  ],
  "stats": {"totalFiles":..., "analyzedFiles":..., "excludedFiles":..., "totalLoc":..., "byLanguage":{...}}
}
```

排除规则（与原来一致）：`vendored` / `generated` / `fixtures`。

## 3 · 入口点发现

基于 tier 选择发现方式：

### codegraph-indexed

使用 `codegraph explore` 或 `codegraph query` 查找所有被外部引用的入口函数：

```bash
# 查找所有 controller/handler/router 类符号
codegraph query "controller" --path <target>
codegraph query "handler" --path <target>
codegraph query "route" --path <target>
codegraph query "main" --path <target>

# 查找所有 HTTP 路由定义
rg "app\.(get|post|put|delete|patch|route)\(" <target>
rg "@(router|app|api)\.(get|post|put|delete)" <target>
```

### rg 回退

```bash
rg -n "def (handle|route|main|create|list|get|update|delete)" <target>
rg -n "app\.(get|post|put|delete|route)\(" <target>
```

### grep 回退

```
grep -rn "def handle\|def route\|def main" <target>
```

### 去重与排序

- 移除内部函数（只被本文件引用的）
- 按涉及时钟/调用深度排序，最重要的排前面
- 自动生成业务描述：基于函数名 + 路由路径 + 参数名推断

输出 `discovery/entrypoints.json`：
```json
{
  "tier": "codegraph-indexed",
  "entries": [
    {
      "id": "order-create",
      "name": "下单流程",
      "entry_symbol": "create_order_handler",
      "entry_file": "src/routers/order.py",
      "entry_line": 25,
      "source": "codegraph",
      "route": "POST /orders",
      "files_involved": 0,
      "depth": 0,
      "description": "基于代码结构推断：处理用户提交订单请求，涉及订单验证、库存检查、支付处理等步骤"
    }
  ]
}
```

**`description` 字段规范**：
- 只能基于：函数名、参数名、模块路径、路由路径
- 必须标注 `基于代码结构推断`
- 禁止引用注释/commit/docs

## 4 · 调用图采集

对每个入口点，递归采集完整调用链路：

### codegraph 模式

```bash
# 对每个入口符号，递归展开
codegraph explore <entry_symbol> --path <target>
# codegraph node 逐层深入
codegraph node <symbol> --path <target>
```

递归策略：
1. 从入口点开始，`codegraph node` 获取调用者/被调用者列表
2. 对每个被调用者，如果不在"已访问"集合中，继续展开
3. 最大深度 20 层，防止无限递归
4. 标记标准库/第三方库调用（不继续展开）

### rg 回退

```bash
# 查找函数定义
rg -n "def <symbol>|func <symbol>|<symbol> = fn" <target>
# 查找函数内部调用了哪些其他函数
rg -n "\b(validate|check|compute|save|notify|send)\(" <target>/<file>
```

精度标注：每个节点标注 `source: "rg"`（低精度）。

### 输出格式

每个入口点一个文件，`discovery/callgraphs/<entry_id>.json`：

```json
{
  "entry_id": "order-create",
  "entry_name": "下单流程",
  "entry_file": "src/routers/order.py",
  "entry_line": 25,
  "tier": "codegraph-indexed",
  "call_tree": [
    {
      "symbol": "validate_order",
      "name_cn": "验证订单参数",
      "file": "src/services/order.py",
      "line": 12,
      "depth": 1,
      "source": "codegraph",
      "callees": [
        {
          "symbol": "Product.get_by_id",
          "name_cn": "查询商品信息",
          "file": "src/models/product.py",
          "line": 88,
          "depth": 2,
          "source": "codegraph",
          "callees": []
        }
      ]
    }
  ]
}
```

**`name_cn` 字段**：AI 在写入时基于 symbol 名翻译为中文业务描述。

## 5 · 文件摘要

对 call_graph 中涉及的所有文件，采集其导出函数/类列表：

### codegraph 模式
```bash
codegraph status <target>  # 获取索引状态
codegraph node <file> --path <target> --symbols-only  # 获取文件中所有符号
```

### rg 回退
```bash
# Python
rg -n "^(async )?def |^class " <file>
# JS/TS
rg -n "^(export )?(async )?function |^(export )?(default )?(async )?const |^class " <file>
# Go
rg -n "^func " <file>
# Java
rg -n "public|private|protected" <file>
```

输出 `discovery/summary.json`：
```json
{
  "files": {
    "src/services/order.py": {
      "language": "python",
      "exports": [
        {"name": "validate_order", "type": "function", "line": 12, "signature": "(order_data: dict) -> bool"},
        {"name": "save_order", "type": "function", "line": 60, "signature": "(order_data: dict) -> Order"}
      ]
    }
  }
}
```

## 6 · Phase 1 自检

主 Agent 内联自查（不开 SubAgent）：

1. [ ] `entrypoints.json` 非空（至少一个入口点；空则标记"项目无外部入口，生成基础架构报告"）
2. [ ] 每个入口点至少有一条调用链路
3. [ ] `inventory.json` 与 `entrypoints.json` 引用的文件一致
4. [ ] 每个 entrypoint 的 description 标注了"基于代码结构推断"