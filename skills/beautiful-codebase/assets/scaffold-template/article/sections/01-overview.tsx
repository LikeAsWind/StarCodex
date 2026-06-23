import { Section, Raw } from "reacticle";
import { SourcePointers } from "../components/SourcePointers";

// 01 项目概览：Phase 3 主 Agent 基于 inventory + entrypoints + codebase-brief 综合生成
// 包含项目规模、语言分布、业务领域推断、技术栈识别、入口点总览
export function SectionOverview() {
  const stats = {
    totalFiles: 0,
    analyzedFiles: 0,
    totalLoc: 0,
    primaryLanguage: "",
    entryCount: 0,
  };

  return (
    <Section index="01" title="项目概览">
      <h3>项目规模</h3>
      <p>
        本项目是一个 <strong>{stats.primaryLanguage}</strong> 项目，共{" "}
        <strong>{stats.totalFiles}</strong> 个文件（分析范围{" "}
        <strong>{stats.analyzedFiles}</strong> 个），总代码行数{" "}
        <strong>{stats.totalLoc}</strong>。
      </p>

      <h3>语言分布</h3>
      {/* Phase 3 基于 inventory.json byLanguage 生成表格 */}

      <h3>业务领域推断</h3>
      <p>
        基于模块命名模式和 API 路由分析（标注"基于代码结构推断"），本项目主要涉及以下业务领域：
      </p>
      <ul>
        {/* Phase 3 基于模块名/api 路由推断:
            - 订单管理：基于 order cart module 命名推断
            - 支付处理：基于 payment checkout 路由推断
            - 物流配送：基于 shipping delivery 模块推断
        */}
        <li><strong>领域一</strong>：基于 &lt;模块名&gt; 推断</li>
        <li><strong>领域二</strong>：基于 &lt;API 路由&gt; 推断</li>
        <li><strong>领域三</strong>：基于 &lt;数据模型&gt; 推断</li>
      </ul>
      <p><em>以上推断基于代码结构（模块名、路由路径、数据模型类名），未引用注释或文档。</em></p>

      <h3>技术栈识别</h3>
      <p>基于依赖配置文件（package.json / Cargo.toml / go.mod / requirements.txt）和 import 分析：</p>
      <table>
        <thead>
          <tr>
            <th>类别</th>
            <th>技术</th>
            <th>来源</th>
          </tr>
        </thead>
        <tbody>
          {/* Phase 3 基于项目依赖文件自动填充 */}
          <tr><td>Web 框架</td><td>—</td><td>依赖文件</td></tr>
          <tr><td>数据库</td><td>—</td><td>依赖文件</td></tr>
          <tr><td>消息队列</td><td>—</td><td>配置/依赖文件</td></tr>
          <tr><td>外部集成</td><td>—</td><td>配置/import 分析</td></tr>
        </tbody>
      </table>

      <h3>入口点总览</h3>
      <p>
        共发现 <strong>{stats.entryCount}</strong> 个外部入口点。
        主要功能链路包括：订单处理、支付流程等（详见第 04 章起）。
      </p>

      <SourcePointers
        files={[
          { path: "discovery/inventory.json", lines: [], summary: "项目文件统计" },
          { path: "discovery/entrypoints.json", lines: [], summary: "入口点列表" },
          { path: "discovery/codebase-brief.md", lines: [], summary: "项目概况（含依赖/技术栈）" },
        ]}
      />
    </Section>
  );
}
