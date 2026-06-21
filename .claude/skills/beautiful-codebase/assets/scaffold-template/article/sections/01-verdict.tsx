import { Section, Aside } from "reacticle";

// One Section per file. In parallel builds a single subagent owns this file and
// must not touch Article.tsx or other section files. See references/section-build.md.
//
// This is the example "Section 01 · Verdict" produced by scaffold.sh — replace
// in Phase 3 First Spread with the real verdict written by the three-stage
// pipeline (Evidence → Business → Writing). All technical and business claims
// must trace back to sections/01-evidence.md and sections/01-business.md.
//
// Code-density (Q9b) reminders:
//   - Prose is the body. Inline <Code> for identifiers is encouraged.
//   - <CodeBlock> default-banned; ≤ 1 per section, ≤ 8 lines (Section 04 / 05
//     allowed up to 2). Mermaid blocks do not count.
//   - Substitution priority: prose → mermaid → table → inline → code block.
export function SectionVerdict() {
  return (
    <Section index="01" title="Verdict">
      <p>
        正文段落写在 <code>&lt;Section&gt;</code> 的 children 里 —— 这应是本节主体。
        Verdict 是 architecture-review / archaeology profile 的开篇判断：
        用 2-3 段说出"这套代码是什么 / 健康吗 / 值不值得继续投入"，然后用 Aside 给一句核心判断。
      </p>
      <p>
        本占位是 scaffold 创建的样板 —— Phase 3 First Spread 时主 Agent 走完整的三阶段（
        Evidence → Business Distillation → Writing），把本节替换成基于真实 evidence 的版本。
      </p>

      <Aside tone="principle" label="核心判断">
        用一句话给出本节的判断；这句话应能在 <code>01-evidence.md</code> 与{" "}
        <code>01-business.md</code> 找到证据支撑。
      </Aside>
    </Section>
  );
}
