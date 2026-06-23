import { Section, Raw } from "reacticle";
import { SourcePointers } from "../components/SourcePointers";

// 01 项目概览：Phase 3 主 Agent 基于 inventory + entrypoints 综合生成
// 包含项目规模、语言分布、入口点总览、技术栈
export function SectionOverview() {
  const stats = {
    totalFiles: 0,       // Phase 3 从 inventory.json 填充
    analyzedFiles: 0,    // Phase 3 从 inventory.json 填充
    totalLoc: 0,         // Phase 3 从 inventory.json 填充
    primaryLanguage: "", // Phase 3 从 inventory.json 填充
    entryCount: 0,       // Phase 3 从 entrypoints.json 填充
  };

  return (
    <Section index="01" title="项目概览">
      <p>
        本项目是一个 <strong>{stats.primaryLanguage}</strong> 项目，共包含{" "}
        <strong>{stats.totalFiles}</strong> 个文件（其中分析范围{" "}
        <strong>{stats.analyzedFiles}</strong> 个），总代码行数{" "}
        <strong>{stats.totalLoc}</strong> 行。
      </p>

      <h3>语言分布</h3>
      {/* Phase 3 基于 inventory.json byLanguage 生成表格 */}

      <h3>入口点总览</h3>
      <p>
        共发现 <strong>{stats.entryCount}</strong> 个外部入口点。
        本项目的主要功能链路包括：下单流程、退款流程等（详见第 04/05 章）。
      </p>

      <h3>技术栈</h3>
      <p>（Phase 3 基于 entrypoints.json 和文件分布自动推断）</p>

      <SourcePointers
        files={[
          { path: "discovery/inventory.json", lines: [], summary: "项目文件统计" },
          { path: "discovery/entrypoints.json", lines: [], summary: "入口点列表" },
        ]}
      />
    </Section>
  );
}
