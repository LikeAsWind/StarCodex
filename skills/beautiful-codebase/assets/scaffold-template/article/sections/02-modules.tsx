import { Section } from "reacticle";
import { SourcePointers } from "../components/SourcePointers";

// 02 业务功能总览：Phase 3 基于 entrypoints.json 生成入口点表格
export function SectionModules() {
  // Phase 3 从 entrypoints.json entries 数组填充
  const entries: Array<{
    id: string;
    name: string;
    route: string;
    entry_file: string;
    entry_line: number;
    files_involved: number;
    depth: number;
    description: string;
  }> = [];

  return (
    <Section index="02" title="业务功能总览">
      <p>
        基于 codegraph 调用图分析，本项目共发现 <strong>{entries.length}</strong>{" "}
        个外部入口点。以下表格列出每个入口点的功能描述、路由、调用深度和涉及文件数。
      </p>

      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>功能</th>
            <th>路由</th>
            <th>入口位置</th>
            <th>涉及文件</th>
            <th>调用深度</th>
          </tr>
        </thead>
        <tbody>
          {entries.map((e, i) => (
            <tr key={e.id}>
              <td>{i + 1}</td>
              <td>{e.name}</td>
              <td>{e.route || "-"}</td>
              <td>
                <code>
                  {e.entry_file}:{e.entry_line}
                </code>
              </td>
              <td>{e.files_involved}</td>
              <td>{e.depth}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <p>
        每个入口点的详细调用链路分析见后续章节。标注"基于代码结构推断"的描述
        基于函数名、参数名、模块路径推断，未引用注释或文档。
      </p>

      <SourcePointers
        files={[
          { path: "discovery/entrypoints.json", lines: [], summary: "入口点列表" },
        ]}
      />
    </Section>
  );
}
