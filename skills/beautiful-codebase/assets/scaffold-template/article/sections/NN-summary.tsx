import { Section } from "reacticle";
import { SourcePointers } from "../components/SourcePointers";

// 总结：Phase 3 基于所有功能链路的分析结果汇总生成
export function SectionSummary() {
  return (
    <Section index="__INDEX__" title="总结">
      <p>
        基于 codegraph 调用图分析，本报告对项目的 <strong>N</strong> 个核心功能链路
        进行了详细的代码级分析。以下为关键发现汇总。
      </p>

      <h3>核心发现</h3>
      <ul>
        <li>
          <strong>架构特点</strong>：（Phase 3 基于模块依赖分析自动生成）
        </li>
        <li>
          <strong>风险点</strong>：（Phase 3 基于复杂度检测和错误处理分析生成）
        </li>
        <li>
          <strong>优化建议</strong>：（Phase 3 汇总各章节的优化提案，按优先级排列）
        </li>
      </ul>

      <h3>统计总览</h3>
      <table>
        <thead>
          <tr>
            <th>指标</th>
            <th>值</th>
          </tr>
        </thead>
        <tbody>
          <tr><td>总分析文件数</td><td>（Inventory）</td></tr>
          <tr><td>总代码行数</td><td>（Inventory）</td></tr>
          <tr><td>入口点数量</td><td>（Entrypoints）</td></tr>
          <tr><td>功能链路章节数</td><td>（Callgraphs）</td></tr>
        </tbody>
      </table>

      <SourcePointers
        files={[
          { path: "discovery/inventory.json", lines: [], summary: "文件统计" },
          { path: "discovery/entrypoints.json", lines: [], summary: "入口点数据" },
        ]}
      />
    </Section>
  );
}
