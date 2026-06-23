import { Section, Aside } from "reacticle";
import { SourcePointers } from "../components/SourcePointers";

// 01-verdict 判断性摘要
// Phase 3 主 Agent 基于 inventory + entrypoints + codebase-brief 综合生成
// 提供对项目的第一印象：规模、质量信号、主要定论
export function SectionVerdict() {
  return (
    <Section index="01" title="判断性摘要">
      <Aside tone="info">
        本摘要基于代码结构分析自动生成。标注"基于代码结构推断"的结论来自
        函数名/模块路径/调用关系，非来自注释或文档。
      </Aside>

      <h3>项目定论</h3>
      <p>
        （Phase 3 基于分析生成一句话定论。例如："这是一个典型的微服务架构项目，
        核心业务是订单处理和支付。"）
      </p>

      <h3>质量信号</h3>
      <ul>
        <li>
          <strong>调用链深度</strong>：最大深度 N 层（高/中/低）
        </li>
        <li>
          <strong>模块耦合度</strong>：核心模块依赖数 N（紧密/适中/松散）
        </li>
        <li>
          <strong>错误处理覆盖</strong>：N（高/中/低）
        </li>
      </ul>

      <p>详细分析见后续各章。</p>

      <SourcePointers
        files={[
          { path: "discovery/inventory.json", lines: [], summary: "项目统计" },
          { path: "discovery/entrypoints.json", lines: [], summary: "入口点" },
          { path: "discovery/codebase-brief.md", lines: [], summary: "项目概况" },
        ]}
      />
    </Section>
  );
}
