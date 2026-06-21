import { Article, Hero, Lead, Raw } from "reacticle";
import { SectionVerdict } from "./sections/01-verdict";

// Article.tsx is the ASSEMBLER, owned by the main agent. It imports and orders
// Section components — it must NOT contain Section bodies inline.
//
// Iron rule: each Section is its own file (article/sections/NN-*.tsx), never
// inlined here. This is the precondition for parallel multi-agent builds (mode B
// in Checkpoint 2). See references/section-build.md.
//
// width (narrow/regular/wide/full) + toc are set at Plan Checkpoint 1 and are
// decoupled from the theme. See references/layout.md.
export function ArticleDoc() {
  return (
    <Article toc width="regular">
      <Hero
        title="<项目名> · 代码分析报告"
        subtitle="一句话框定本报告解决的问题（reader profile、覆盖范围、新鲜度）"
        meta={[
          { label: "Reader profile", value: "architecture-review" },
          { label: "Tool tier", value: "codegraph-indexed" },
          { label: "Snapshot", value: "YYYY-MM-DD · sha=__short__" },
        ]}
      />
      <Lead>
        导语：用一两句话告诉读者这份报告是给谁看的、覆盖了多少代码、读完应能带走什么判断。
      </Lead>

      <SectionVerdict />
      {/* In order, append more sections here as Phase 4 produces them:
          <SectionProjectAtAGlance />
          <SectionBusinessDomainMap />
          <SectionArchitectureMap />
          <SectionModuleWalkThrough />
          <SectionEntryPoints />
          <SectionTechStackAudit />
          <SectionCodeHealthHeatmap />
          <SectionRisksHotSpots />
          <SectionDecisionsThatMatter />
          <SectionOpenQuestions />
          <SectionCoverageAnnex /> */}

      {/*
        ─── Colophon ───
        Each beautiful-codebase report MUST keep this footer, immediately before
        </Article> and after all Sections / Conclusion.

        Constraints:
          • Do not delete. Do not float to a corner. Do not move next to Hero.
          • Text format is fixed: Made with beautiful-codebase (link to repo) · <theme> theme
          • The theme name placeholder (__THEME__) is filled by scaffold.sh.
            When switching theme, update both this colophon AND the
            <ThemeProvider theme="..."> in main.tsx.
          • Style only via --ra-* tokens; low-contrast small caps, centered.
      */}
      <Raw title="">
        <footer
          style={{
            marginTop: "var(--ra-space-7, 3rem)",
            paddingTop: "var(--ra-space-4, 1rem)",
            borderTop: "1px solid var(--ra-color-border, currentColor)",
            color: "var(--ra-color-muted, inherit)",
            fontSize: "var(--ra-text-xs, 0.78rem)",
            textAlign: "center",
            letterSpacing: "0.02em",
            opacity: 0.85,
          }}
        >
          Made with{" "}
          <a
            href="https://github.com/ConardLi/garden-skills"
            target="_blank"
            rel="noopener noreferrer"
            style={{
              color: "inherit",
              textDecoration: "underline",
              textUnderlineOffset: "0.2em",
            }}
          >
            beautiful-codebase
          </a>{" "}
          · __THEME__ theme
        </footer>
      </Raw>
    </Article>
  );
}
