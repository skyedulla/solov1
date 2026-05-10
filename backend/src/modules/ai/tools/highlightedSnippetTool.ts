import { AI_TOOL_TYPES } from "../constants";
import { HIGHLIGHTED_SNIPPET_SYSTEM_PROMPT } from "../system_prompts";
import type { AiToolConfig } from "./toolRegistry";

export const highlightedSnippetTool: AiToolConfig = {
  toolType: AI_TOOL_TYPES.highlightedSnippet,
  systemPrompt: HIGHLIGHTED_SNIPPET_SYSTEM_PROMPT,
  requiredVariables: [],
};
