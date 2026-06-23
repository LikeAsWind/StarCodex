import { useState } from "react";

export interface TreeNode {
  label: string;
  children?: TreeNode[];
}

function TreeItem({ node, depth }: { node: TreeNode; depth: number }) {
  const [open, setOpen] = useState(depth < 2);
  const hasChildren = node.children && node.children.length > 0;

  return (
    <div style={{ marginLeft: depth === 0 ? 0 : "1.2rem" }}>
      <div
        onClick={() => hasChildren && setOpen(!open)}
        style={{
          display: "flex",
          alignItems: "center",
          gap: "0.3rem",
          padding: "0.15rem 0",
          cursor: hasChildren ? "pointer" : "default",
          fontSize: "var(--ra-text-sm, 0.88rem)",
          lineHeight: 1.5,
          fontFamily: "var(--ra-font-mono, monospace)",
          color: "var(--ra-color-fg, inherit)",
        }}
      >
        {hasChildren ? (
          <span style={{ width: "0.9rem", textAlign: "center", flexShrink: 0, opacity: 0.45, fontSize: "0.7rem" }}>
            {open ? "\u25BC" : "\u25B6"}
          </span>
        ) : (
          <span style={{ width: "0.9rem", flexShrink: 0 }} />
        )}
        <span style={{ opacity: hasChildren ? 0.7 : 0.5 }}>{hasChildren ? "\u2502 " : "\u2514 "}</span>
        <span>{node.label}</span>
      </div>
      {hasChildren && open && (
        <div>
          {node.children!.map((child, i) => (
            <TreeItem key={i} node={child} depth={depth + 1} />
          ))}
        </div>
      )}
    </div>
  );
}

export function CallTree({ data, title }: { data: TreeNode; title?: string }) {
  return (
    <details style={{ marginTop: "var(--ra-space-3, 0.75rem)" }}>
      <summary
        style={{
          cursor: "pointer",
          fontSize: "var(--ra-text-base, 1rem)",
          fontWeight: 600,
          padding: "0.3rem 0",
        }}
      >
        {title || "\u5B8C\u6574\u8C03\u7528\u5217\u8868\uFF08\u70B9\u51FB\u5C55\u5F00\uFF09"}
      </summary>
      <div
        style={{
          marginTop: "0.4rem",
          padding: "0.6rem 1rem",
          background: "var(--ra-color-surface, #f8f8f8)",
          borderRadius: "var(--ra-radius-sm, 4px)",
          border: "1px solid var(--ra-color-border, #ddd)",
        }}
      >
        <TreeItem node={data} depth={0} />
      </div>
    </details>
  );
}
