import type { ReactNode } from "react";

/**
 * SvgWrapper - 渲染 SVG 字符串的辅助组件。
 *
 * 将原始的 SVG HTML 字符串通过 dangerouslySetInnerHTML 安全注入 DOM。
 * 宽度默认 100%，超出部分允许横向滚动。
 */
export function SvgWrapper({ html, caption }: { html: string; caption?: ReactNode }) {
  return (
    <figure style={{ margin: "var(--ra-space-4, 1.5rem) 0" }}>
      <div
        style={{ width: "100%", overflowX: "auto", WebkitOverflowScrolling: "touch" }}
        dangerouslySetInnerHTML={{ __html: html }}
      />
      {caption && (
        <figcaption
          style={{
            marginTop: "var(--ra-space-2, 0.5rem)",
            fontSize: "var(--ra-text-xs, 0.78rem)",
            color: "var(--ra-color-muted, inherit)",
            textAlign: "center",
          }}
        >
          {caption}
        </figcaption>
      )}
    </figure>
  );
}
