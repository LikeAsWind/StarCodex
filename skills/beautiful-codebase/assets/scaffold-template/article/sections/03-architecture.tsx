import { Section, Raw } from "reacticle";
import { SourcePointers } from "../components/SourcePointers";

// 03 项目架构图：Phase 3 基于 codegraph 模块依赖关系生成 SVG 架构拓扑图
export function SectionArchitecture() {
  // Phase 3 从 discovery/callgraphs/ 综合生成模块依赖矩阵
  // 然后渲染为 SVG 拓扑图
  return (
    <Section index="03" title="项目架构图">
      <p>
        基于 codegraph 调用图综合分析，以下 SVG 描述了项目各模块间的依赖关系。
        节点大小反映模块代码量，连线粗细反映调用频次。
      </p>

      <Raw title="模块依赖拓扑图">
        <svg viewBox="0 0 600 300" width="100%" role="img" aria-label="模块依赖拓扑图">
          {/* Phase 3 动态生成模块节点和连线 */}
          <rect x="50" y="40" width="120" height="60" rx="4"
                fill="var(--ra-color-surface, #222)" stroke="var(--ra-status-blue, #4fc3f7)" strokeWidth="1.5" />
          <text x="110" y="75" textAnchor="middle"
                fill="var(--ra-color-fg, #eee)" fontSize="12">模块 A</text>

          <rect x="240" y="120" width="120" height="60" rx="4"
                fill="var(--ra-color-surface, #222)" stroke="var(--ra-status-green, #66bb6a)" strokeWidth="1.5" />
          <text x="300" y="155" textAnchor="middle"
                fill="var(--ra-color-fg, #eee)" fontSize="12">模块 B</text>

          <rect x="430" y="200" width="120" height="60" rx="4"
                fill="var(--ra-color-surface, #222)" stroke="var(--ra-status-amber, #ffa726)" strokeWidth="1.5" />
          <text x="490" y="235" textAnchor="middle"
                fill="var(--ra-color-fg, #eee)" fontSize="12">模块 C</text>

          {/* 调用连线 */}
          <line x1="170" y1="70" x2="240" y2="150" stroke="var(--ra-color-border, #555)" strokeWidth="1" />
          <line x1="360" y1="150" x2="430" y2="230" stroke="var(--ra-color-border, #555)" strokeWidth="1" />
        </svg>
      </Raw>

      <h3>模块依赖说明</h3>
      <p>
        （Phase 3 基于 codegraph 自动分析：module_a -> module_b -> module_c）
      </p>

      <SourcePointers
        files={[
          { path: "discovery/entrypoints.json", lines: [], summary: "入口点列表" },
          { path: "discovery/callgraphs/", lines: [], summary: "调用链路数据" },
        ]}
      />
    </Section>
  );
}
