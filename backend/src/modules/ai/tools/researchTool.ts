import { AI_TOOL_TYPES } from "../constants";
import { RESEARCH_TOOL_SYSTEM_PROMPT } from "../system_prompts";
import type { AiToolConfig } from "./toolRegistry";

export const researchTool: AiToolConfig = {
  toolType: AI_TOOL_TYPES.research,
  systemPrompt: RESEARCH_TOOL_SYSTEM_PROMPT,
  requiredVariables: ["title", "targetUser", "purpose", "description"],
};
