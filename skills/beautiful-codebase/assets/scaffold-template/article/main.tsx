import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { ThemeProvider } from "reacticle";
import "reacticle/styles.css";
import { Cover } from "./Cover";
import { ArticleDoc } from "./Article";

// 渲染顺序：Cover → ArticleDoc（含 TOC + 正文 + colophon）
createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <ThemeProvider theme="__THEME__">
      <Cover />
      <ArticleDoc />
    </ThemeProvider>
  </StrictMode>
);