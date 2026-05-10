import type { AiToolType } from "../constants";
import { highlightedSnippetTool } from "./highlightedSnippetTool";
import { mindmapTool } from "./mindmapTool";
import { planningTool } from "./planningTool";
import { researchTool } from "./researchTool";

export type AiToolConfig = {
  toolType: AiToolType;
  systemPrompt: string;
  requiredVariables: string[];
};

const registry = new Map<AiToolType, AiToolConfig>(
  [highlightedSnippetTool, planningTool, mindmapTool, researchTool].map((tool) => [tool.toolType, tool]),
);

export function getToolConfig(toolType: AiToolType): AiToolConfig {
  const config = registry.get(toolType);
  if (!config) {
    throw new Error(`Unknown AI tool type: ${toolType}`);
  }
  return config;
}

