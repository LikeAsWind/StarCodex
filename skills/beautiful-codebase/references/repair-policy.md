# Repair Policy · 修复策略

> **何时读**: Phase 4 Section Reviewer 返回 fail 需要修复时；Phase 6 终审需要修复时

## 1 · 修复层级

| 级别 | 触发条件 | 修复方式 |
|------|---------|---------|
| Hotfix | Section Reviewer Claim Audit fail | 重写该 claim 所在的 prose 段 |
| Re-gen | 整节 evidence/business 不满足反幻觉 | 重派该节 Step A -> A.5 -> Step B |
| Density | Q9b 密度审计 fail | 优先用 `<Code inline>` / mermaid 替代 `<CodeBlock>` |
| Index | Section index 不服 | 主 Agent 直接改 Article.tsx 的序号 |

## 2 · 优先级

Critical > High > Medium > Low

- **Critical**: 反幻觉 fail, 虚假 claim → 立即修复，不可交付
- **High**: 质量不达标（density fail, source pointers 缺失） → 修复后进入下一节
- **Medium**: 风格不一致，衔接不平滑 → 进入下一节，终审时统一修
- **Low**: 排版微调 → 记录 issue，不阻塞交付

## 3 · 修复循环

```
fail -> 主 Agent 判断修复级别 -> hotfix 直接修 / re-gen 重派 sub-agent
-> 验证通过 -> 进入下一节
-> 二次 fail -> 主 Agent 人工介入
```
