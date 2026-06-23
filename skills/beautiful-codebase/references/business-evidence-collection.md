# Business Evidence Collection · 业务证据采集

> **何时读**: Phase 1 Discover 采集业务证据时；Phase 4 Step A.5 Business Distillation 时

## 1 · 为什么需要业务证据

代码分析报告需要把代码结构"翻译"成业务含义。翻译的燃料必须来自**可验证的代码结构**，不能来自注释/文档/commit message 等人工输入。

## 2 · 三类可验证的业务证据

Phase 1 Discover 结束时，以下 3 类证据写入 `discovery/business-evidence/`：

| # | 证据类型 | 文件名 | 采集方式 | 用途 | 可信依据 |
|---|---------|--------|---------|------|---------|
| 1 | 测试用例 | tests.jsonl | 分析 test_ 文件中的断言和场景命名 | 验证业务规则的测试覆盖 | 编译器验证过的断言代码 |
| 2 | 数据模型 | schema.md | 收集 database DDL / Pydantic models / SQLAlchemy / Prisma 定义 | 了解业务实体和字段 | 编译时存在的类型定义 |
| 3 | 配置/枚举 | configs.md | 收集配置文件、常量定义、枚举值 | 理解业务策略和开关 | 编译时存在的常量值 |

### 排除的证据类型（不可信输入）

| 类型 | 排除原因 |
|------|---------|
| 注释/docstring | 人工输入，可能过时或与代码不匹配 |
| 文档/README | 人工输入，可能过时或与代码不匹配 |
| Commit 主题 | 人工输入，无编译器验证 |

## 3 · 来源标注规则

- 测试用例：`[TEST: file:line]`
- Schema：`[SCHEMA: file:line]`
- 配置/枚举：`[CONFIG: file:line]`

## 4 · 与反幻觉的关系

业务证据是**验证约束**：Step A.5 只允许写带 `[证据:]` 检测的业务陈述。

没有任何业务证据可循时，Step A.5 输出 `BUSINESS_EVIDENCE_EMPTY`，整节降级为纯技术描述。
