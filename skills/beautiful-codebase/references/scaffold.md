# Scaffold · 脚手架结构说明

> **何时读**: Phase 3 创建工程后；Phase 4 写章节时；初次接触 workspace 结构时

## 1 · Workspace 结构

```
<project>-analysis/
  article/
    Cover.tsx               # 3:4 封面（主 Agent 修正）
    Article.tsx             # Assembler（主 Agent 拥有）：import + 排序
    main.tsx                # React 入口，ThemeProvider 包 Cover + ArticleDoc
    sections/
      01-verdict.tsx        # 第一节：判断性摘要
      02-glance.tsx         # 第二节：项目速览
      02b-business-domain.tsx  # 第二节附加：业务领域
      03-architecture-map.tsx  # 第三节：架构图
      04-<slug>.tsx ~ NN    # 按入口点扩展的功能链路章节
      NN-summary.tsx        # 总结
      NN-colophon.tsx       # 署名
    raw-blocks/             # > 30 行的 Raw SVG / 复杂可视化
    assets/                 # 报告自带资源（极少数情况）
  discovery/                # Phase 1 产出
    inventory.json          # 文件清单
    tools.json              # 工具 tier
    entrypoints.json        # 入口点列表
    callgraphs/             # 每个入口点一个调用树 JSON
    summary.json            # 文件摘要
    codebase-brief.md       # 项目概况（~200 lines）
    buckets/                # 切桶结果
    business-evidence/      # 6 类业务证据
  plan/
    plan.md                 # Phase 2 产出
  review/
    first-spread-review.md  # Phase 3 产出
    final-review.md          # Phase 5 产出
  analysis-snapshot.json    # 元数据快照
```

## 2 · 关键约定

- `Article.tsx` 只做 import + 排序，不包含任何一节的具体内容
- 每个 section 独立文件，文件名格式：`<NN>-<slug>.tsx`
- 组件名格式：`Section<Name>`（如 `SectionOrderCreate`）
- Raw blocks > 30 行必须抽到 `raw-blocks/NN-<slug>.tsx`
