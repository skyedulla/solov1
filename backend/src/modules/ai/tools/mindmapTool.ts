import { AI_TOOL_TYPES } from "../constants";
import { MINDMAP_TOOL_SYSTEM_PROMPT } from "../system_prompts";
import type { AiToolConfig } from "./toolRegistry";

export const mindmapTool: AiToolConfig = {
  toolType: AI_TOOL_TYPES.mindmap,
  systemPrompt: MINDMAP_TOOL_SYSTEM_PROMPT,
  requiredVariables: ["title", "targetUser", "purpose", "description"],
};
