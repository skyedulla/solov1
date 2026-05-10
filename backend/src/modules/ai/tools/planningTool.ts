import { AI_TOOL_TYPES } from "../constants";
import { PLANNING_TOOL_SYSTEM_PROMPT } from "../system_prompts";
import type { AiToolConfig } from "./toolRegistry";

export const planningTool: AiToolConfig = {
  toolType: AI_TOOL_TYPES.planning,
  systemPrompt: PLANNING_TOOL_SYSTEM_PROMPT,
  requiredVariables: ["title", "targetUser", "purpose", "description"],
};
