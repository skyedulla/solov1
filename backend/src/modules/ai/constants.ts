export const AI_TOOL_TYPES = {
  highlightedSnippet: "ai.highlighted_snippet",
  planning: "ai.planning",
  mindmap: "ai.mindmap",
  research: "ai.research",
} as const;

export const AI_TOOL_TYPE_VALUES = [
  AI_TOOL_TYPES.highlightedSnippet,
  AI_TOOL_TYPES.planning,
  AI_TOOL_TYPES.mindmap,
  AI_TOOL_TYPES.research,
] as const;

export type AiToolType = (typeof AI_TOOL_TYPE_VALUES)[number];

