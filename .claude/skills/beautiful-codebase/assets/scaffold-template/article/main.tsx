import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { ThemeProvider } from "reacticle";
import "reacticle/styles.css";
// __COVER_IMPORT_BEGIN__  (scaffold.sh strips this block on --no-cover)
import { Cover } from "./Cover";
// __COVER_IMPORT_END__
import { ArticleDoc } from "./Article";

// Entry for the self-contained single-file HTML build.
// Theme is fixed here — change `theme` (must be a registered reacticle theme id:
// "terminal" | "tufte" | "press") to switch the whole look. Default for
// beautiful-codebase is "terminal" (code-native dark surface).
//
// Render order: Cover (optional) → ArticleDoc (TOC + body + colophon).
// Cover sits as a sibling of ArticleDoc under ThemeProvider so the DOM order
// is naturally: Cover → TOC → body → colophon.
createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <ThemeProvider theme="__THEME__">
      {/* __COVER_RENDER_BEGIN__  (scaffold.sh strips this block on --no-cover) */}
      <Cover />
      {/* __COVER_RENDER_END__ */}
      <ArticleDoc />
    </ThemeProvider>
  </StrictMode>
);
