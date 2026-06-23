# Complexity Tools · 代码复杂度检测

> **何时读**: Phase 5 需要检测代码复杂度生成热图时

## 1 · 工具

`scripts/audit/complexity-detect.sh` 封装了复杂度检测。

支持的指标：

| 指标 | 命令 | 说明 |
|------|------|------|
| 圈复杂度 (CC) | `codegraph query --metric cyclomatic` | 函数复杂度，> 10 标记高 |
| 函数长度 | `rg -n "^def |^fn |^function"` | 行数统计 |
| 模块依赖数 | `codegraph node <file> --symbols-only` | import 依赖计数 |
| 嵌套深度 | codegraph AST 分析 | 控制流最大嵌套层级 |

## 2 · 热图生成

Output JSONL (每文件一行):
```jsonl
{"path":"src/services/order.py","loc":180,"cc":12,"deps":8,"nesting":4,"tier":"high"}
{"path":"src/services/user.py","loc":45,"cc":3,"deps":2,"nesting":1,"tier":"low"}
```

Tier 标签:
- `low`: CC <= 5
- `medium`: CC 6-10
- `high`: CC 11-20
- `critical`: CC > 20

## 3 · SVG 热图

Phase 5 基于 JSONL 生成 SVG 热图（独立文件），规则见 `references/raw-policy.md`。
