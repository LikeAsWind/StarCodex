import { Article, Hero, Raw } from "reacticle";
import { SectionVerdict } from "./sections/01-verdict";
import { SectionOverview } from "./sections/01-overview";
import { SectionModules } from "./sections/02-modules";
import { SectionArchitecture } from "./sections/03-architecture";
// 后续功能链路章节在 Phase 3 动态添加
// 格式：import { SectionEntry_<slug> } from "./sections/04-<slug>";
import { SectionSummary } from "./sections/NN-summary";

export function ArticleDoc() {
  return (
    <Article toc width="regular">
      <Hero title="代码分析报告" subtitle="基于 codegraph 调用图的深度分析" />

      <SectionVerdict />
      <SectionOverview />
      <SectionModules />
      <SectionArchitecture />
      {/* Phase 3 在此添加功能链路章节 */}
      <SectionSummary />

      <Raw title="">
        <footer className="ra-colophon"
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
            href="__BEAUTIFUL_CODEBASE_REPO__"
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
          路 __THEME__ theme
        </footer>
      </Raw>
    </Article>
  );
}
