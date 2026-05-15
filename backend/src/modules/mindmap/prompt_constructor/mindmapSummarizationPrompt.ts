import type { MindmapConnection, MindmapNode } from "@prisma/client";

import type { LlmChatMessage } from "../../../core/llm_service/chatCompletion";

/** One **mindmap-node** snapshot for summarization — full canvas fields. */
export type MindmapSummarizationMindmapNode = {
  id: string;
  text: string;
  parentNodeId: string | null;
  position: { x: number; y: number };
  dimensions: { height: number; width: number };
};

/** One **mindmap-connection** as supplied to summarization — includes anchor sides for reasoning about layout links. */
export type MindmapSummarizationMindmapConnection = {
  id: string;
  sourceNodeId: string;
  targetNodeId: string | null;
  sourceAnchor: string;
  targetAnchor: string | null;
};

/** Full graph (**mindmap-nodes** + **mindmap-connections**) + metadata for summarization (`title`, **`mindmapNodes`**, **`mindmapConnections`**). */
export type MindmapSummarizationPromptInput = {
  title: string;
  currentSummary: string | null;
  mindmapNodes: MindmapSummarizationMindmapNode[];
  mindmapConnections: MindmapSummarizationMindmapConnection[];
};

/** Maps persisted rows into **`MindmapSummarizationPromptInput`** for **`buildMindmapSummarizationMessages`**. */
export function mindmapSummarizationInputFromPersisted(graph: {
  title: string;
  currentSummary: string | null;
  mindmapNodes: MindmapNode[];
  mindmapConnections: MindmapConnection[];
}): MindmapSummarizationPromptInput {
  return {
    title: graph.title,
    currentSummary: graph.currentSummary,
    mindmapNodes: graph.mindmapNodes.map((mindmapNode) => ({
      id: mindmapNode.id,
      text: mindmapNode.text,
      parentNodeId: mindmapNode.parentNodeId,
      position: { x: mindmapNode.positionX, y: mindmapNode.positionY },
      dimensions: { height: mindmapNode.height, width: mindmapNode.width },
    })),
    mindmapConnections: graph.mindmapConnections.map((mindmapConnection) => ({
      id: mindmapConnection.id,
      sourceNodeId: mindmapConnection.sourceNodeId,
      targetNodeId: mindmapConnection.targetNodeId,
      sourceAnchor: mindmapConnection.sourceAnchor,
      targetAnchor: mindmapConnection.targetAnchor,
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

function formatMindmapNodesSection(
  mindmapNodes: MindmapSummarizationMindmapNode[],
): string {
  if (mindmapNodes.length === 0) {
    return "(no mindmap-nodes)";
  }
  const lines = mindmapNodes.map((mindmapNode) => {
    const parent =
      mindmapNode.parentNodeId === null
        ? "parent: none (root-level)"
        : `parent_node_id: ${mindmapNode.parentNodeId}`;
    const body = truncateForPrompt(mindmapNode.text, 12_000);
    const textLine = body.length > 0 ? body : "(empty text)";
    return [
      `— Mindmap-node id ${mindmapNode.id}`,
      `  ${parent}`,
      `  position: x=${mindmapNode.position.x}, y=${mindmapNode.position.y}`,
      `  dimensions: width=${mindmapNode.dimensions.width}, height=${mindmapNode.dimensions.height}`,
      `  text:`,
      `  ${textLine.replace(/\n/g, "\n  ")}`,
    ].join("\n");
  });
  return lines.join("\n\n");
}

function formatMindmapConnectionsSection(
  mindmapConnections: MindmapSummarizationMindmapConnection[],
  mindmapNodeById: Map<string, MindmapSummarizationMindmapNode>,
): string {
  if (mindmapConnections.length === 0) {
    return "(no mindmap-connections)";
  }

  const snippet = (mindmapNodeId: string): string => {
    const mindmapNode = mindmapNodeById.get(mindmapNodeId);
    const raw = mindmapNode?.text.trim() ?? "";
    return raw.length > 0 ? truncateForPrompt(raw, 200) : "(no text)";
  };

  return mindmapConnections
    .map((mindmapConnection) => {
      const srcSnippet = snippet(mindmapConnection.sourceNodeId);
      const targetId = mindmapConnection.targetNodeId;
      if (targetId === null) {
        return [
          `— Mindmap-connection id ${mindmapConnection.id}`,
          `  source_node ${mindmapConnection.sourceNodeId} [${mindmapConnection.sourceAnchor}] (“${srcSnippet}”)`,
          `  → open-ended (target not set yet)`,
        ].join("\n");
      }
      const tgtSnippet = snippet(targetId);
      const anchorOut = mindmapConnection.targetAnchor ?? "?";
      return [
        `— Mindmap-connection id ${mindmapConnection.id}`,
        `  source_node ${mindmapConnection.sourceNodeId} [${mindmapConnection.sourceAnchor}] (“${srcSnippet}”)`,
        `  → target_node ${targetId} [${anchorOut}] (“${tgtSnippet}”)`,
      ].join("\n");
    })
    .join("\n\n");
}

/**
 * Builds chat messages for refreshing a mind map **`summary`** from **`title`**, full **`mindmapNodes`** (**mindmap-nodes**), and **`mindmapConnections`** (**mindmap-connections**).
 */
export function buildMindmapSummarizationMessages(
  input: MindmapSummarizationPromptInput,
): LlmChatMessage[] {
  const mindmapNodeById = new Map(input.mindmapNodes.map((mindmapNode) => [mindmapNode.id, mindmapNode]));

  const summarySection = input.currentSummary?.trim()
    ? `Current summary (may be stale):\n${input.currentSummary.trim()}`
    : "Current summary: none";

  const mindmapNodesSection = formatMindmapNodesSection(input.mindmapNodes);
  const mindmapConnectionsSection = formatMindmapConnectionsSection(
    input.mindmapConnections,
    mindmapNodeById,
  );

  const userContent = [
    `Mind map title: ${input.title}`,
    "",
    summarySection,
    "",
    "Mindmap-nodes (preserve factual detail from each mindmap-node's text; hierarchy is indicated by parent_node_id):",
    mindmapNodesSection,
    "",
    "Mindmap-connections (use these edges explicitly when explaining how ideas relate — tie source and target content together):",
    mindmapConnectionsSection,
    "",
    [
      "Write an updated summary of this mind map.",
      "Use as much length as needed to capture every substantive detail from the mindmap-node texts.",
      "Whenever mindmap-nodes are linked by a mindmap-connection, explain how those ideas relate using both endpoints (and anchors where helpful).",
      "Reflect parent/child hierarchy where it clarifies structure.",
      "Stay factual to the title, mindmap-nodes, and mindmap-connections given; do not invent goals, users, or missing links.",
      "Reply with plain text only (paragraphs allowed); do not use markdown headings or bullet lists.",
    ].join(" "),
  ].join("\n");

  return [
    {
      role: "system",
      content:
        "You summarize idea maps in SOLO using only the graph snapshot in the user message—title, mindmap-nodes, and mindmap-connections. Mind maps express expanded structure around ideas; stay factual to this snapshot and summarize thoroughly, emphasizing relationships among linked mindmap-nodes.",
    },
    {
      role: "user",
      content: userContent,
    },
  ];
}
