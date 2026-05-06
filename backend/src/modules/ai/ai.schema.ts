import { z } from "zod";

/**
 * Known **`tool_type`** values — keep aligned with Swift **`AIToolType`** and **`tool_config/index.ts`**.
 */
export const AI_TOOL_TYPE_VALUES = [
  "ai.highlighted_snippet",
  "ai.planning",
  "ai.mindmap",
  "ai.research",
] as const;

export type AiToolType = (typeof AI_TOOL_TYPE_VALUES)[number];

/** Request body from Swift **`AIPromptModel`** (**`JSONEncoder.convertToSnakeCase`**). */
export const aiPromptBodySchema = z.object({
  tool_type: z.enum(AI_TOOL_TYPE_VALUES),
  query: z.string().min(1, "query is required"),
  context: z.record(z.string()).default({}),
  llm_model: z.string().min(1, "llm_model is required"),
  temperature: z.number(),
  max_tokens: z.number().int().positive().optional(),
  idea_id: z.string().uuid(),
  conversation_id: z.string().uuid(),
});

export type AiPromptBody = z.infer<typeof aiPromptBodySchema>;

/** **`POST /ai/prompt`** success body (Swift decodes snake_case usage fields). */
export const aiPromptCompletionResponseSchema = z.object({
  content: z.string(),
  model: z.string(),
  usage: z.object({
    prompt_tokens: z.number(),
    completion_tokens: z.number(),
    total_tokens: z.number(),
    cached_prompt_tokens: z.number().nullable(),
  }),
});

export type AiPromptCompletionResponseBody = z.infer<typeof aiPromptCompletionResponseSchema>;
