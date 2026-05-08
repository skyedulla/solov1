import type { MindmapConnection, MindmapNode } from "@prisma/client";

import type { LlmChatMessage } from "../../../core/llm_service/chatCompletion";

/** One node as supplied to summarization — full canvas snapshot fields. */
export type MindmapSummarizationNode = {
  id: string;
  text: string;
  parentNodeId: string | null;
  position: { x: number; y: number };
  dimensions: { height: number; width: number };
};

/** One connection as supplied to summarization — includes anchor sides for reasoning about layout links. */
export type MindmapSummarizationConnection = {
  id: string;
  sourceNodeId: string;
  targetNodeId: string | null;
  sourceAnchor: string;
  targetAnchor: string | null;
};

/** Full mind map graph + metadata for summarization (`title`, **`nodes`**, **`connections`**). */
export type MindmapSummarizationPromptInput = {
  title: string;
  currentSummary: string | null;
  nodes: MindmapSummarizationNode[];
  connections: MindmapSummarizationConnection[];
};

/** Maps persisted rows into **`MindmapSummarizationPromptInput`** for **`buildMindmapSummarizationMessages`**. */
export function mindmapSummarizationInputFromPersisted(graph: {
  title: string;
  currentSummary: string | null;
  nodes: MindmapNode[];
  connections: MindmapConnection[];
}): MindmapSummarizationPromptInput {
  return {
    title: graph.title,
    currentSummary: graph.currentSummary,
    nodes: graph.nodes.map((n) => ({
      id: n.id,
      text: n.text,
      parentNodeId: n.parentNodeId,
      position: { x: n.positionX, y: n.positionY },
      dimensions: { height: n.height, width: n.width },
    })),
    connections: graph.connections.map((c) => ({
      id: c.id,
      sourceNodeId: c.sourceNodeId,
      targetNodeId: c.targetNodeId,
      sourceAnchor: c.sourceAnchor,
      targetAnchor: c.targetAnchor,
    })),
  };
}

function truncateForPrompt(text: string, maxChars: number): string {
  const t = text.trim();
  if (t.length <= maxChars) {
    return t;
  }
  return `${t.slice(0, maxChars)}…`;
}

function formatNodesSection(nodes: MindmapSummarizationNode[]): string {
  if (nodes.length === 0) {
    return "(no nodes)";
  }
  const lines = nodes.map((n) => {
    const parent =
      n.parentNodeId === null ? "parent: none (root-level)" : `parent_node_id: ${n.parentNodeId}`;
    const body = truncateForPrompt(n.text, 12_000);
    const textLine = body.length > 0 ? body : "(empty text)";
    return [
      `— Node id ${n.id}`,
      `  ${parent}`,
      `  position: x=${n.position.x}, y=${n.position.y}`,
      `  dimensions: width=${n.dimensions.width}, height=${n.dimensions.height}`,
      `  text:`,
      `  ${textLine.replace(/\n/g, "\n  ")}`,
    ].join("\n");
  });
  return lines.join("\n\n");
}

function formatConnectionsSection(
  connections: MindmapSummarizationConnection[],
  nodeById: Map<string, MindmapSummarizationNode>,
): string {
  if (connections.length === 0) {
    return "(no connections)";
  }

  const snippet = (nodeId: string): string => {
    const node = nodeById.get(nodeId);
    const raw = node?.text.trim() ?? "";
    return raw.length > 0 ? truncateForPrompt(raw, 200) : "(no text)";
  };

  return connections
    .map((c) => {
      const srcSnippet = snippet(c.sourceNodeId);
      const targetId = c.targetNodeId;
      if (targetId === null) {
        return [
          `— Connection id ${c.id}`,
          `  source_node ${c.sourceNodeId} [${c.sourceAnchor}] (“${srcSnippet}”)`,
          `  → open-ended (target not set yet)`,
        ].join("\n");
      }
      const tgtSnippet = snippet(targetId);
      const anchorOut = c.targetAnchor ?? "?";
      return [
        `— Connection id ${c.id}`,
        `  source_node ${c.sourceNodeId} [${c.sourceAnchor}] (“${srcSnippet}”)`,
        `  → target_node ${targetId} [${anchorOut}] (“${tgtSnippet}”)`,
      ].join("\n");
    })
    .join("\n\n");
}

/**
 * Builds chat messages for refreshing a mind map **`summary`** from **`title`**, full **`nodes`**, and **`connections`**.
 */
export function buildMindmapSummarizationMessages(
  input: MindmapSummarizationPromptInput,
): LlmChatMessage[] {
  const nodeById = new Map(input.nodes.map((n) => [n.id, n]));

  const summarySection = input.currentSummary?.trim()
    ? `Current summary (may be stale):\n${input.currentSummary.trim()}`
    : "Current summary: none";

  const nodesSection = formatNodesSection(input.nodes);
  const connectionsSection = formatConnectionsSection(input.connections, nodeById);

  const userContent = [
    `Mind map title: ${input.title}`,
    "",
    summarySection,
    "",
    "Nodes (preserve factual detail from each node's text; hierarchy is indicated by parent_node_id):",
    nodesSection,
    "",
    "Connections (use these edges explicitly when explaining how ideas relate — tie source and target content together):",
    connectionsSection,
    "",
    [
      "Write an updated summary of this mind map.",
      "Use as much length as needed to capture every substantive detail from the node texts.",
      "Whenever nodes are linked by a connection, explain how those ideas relate using both endpoints (and anchors where helpful).",
      "Reflect parent/child hierarchy where it clarifies structure.",
      "Stay factual to the title, nodes, and connections given; do not invent goals, users, or missing links.",
      "Reply with plain text only (paragraphs allowed); do not use markdown headings or bullet lists.",
    ].join(" "),
  ].join("\n");

  return [
    {
      role: "system",
      content:
        "You summarize idea maps in SOLO using only the graph snapshot in the user message—title, nodes, and connections. Mind maps express expanded structure around ideas; stay factual to this snapshot and summarize thoroughly, emphasizing relationships among linked nodes.",
    },
    {
      role: "user",
      content: userContent,
    },
  ];
}
