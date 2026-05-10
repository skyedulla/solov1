import { z } from "zod";

import { AI_TOOL_TYPE_VALUES, type AiToolType } from "./constants";

export { AI_TOOL_TYPE_VALUES, type AiToolType };

/** Request body from Swift **`AIPromptModel`** (**`JSONEncoder.convertToSnakeCase`**). */
export const aiPromptBodySchema = z.object({
  tool_type: z.enum(AI_TOOL_TYPE_VALUES),
  query: z.string().min(1, "query is required"),
  context: z.record(z.string(), z.string()).default({}),
  llm_model: z.string().min(1, "llm_model is required"),
  temperature: z.number(),
  max_tokens: z.number().int().positive().optional(),
  idea_id: z.string().uuid(),
  /** Omitted or empty: server creates a conversation row and uses its id for this prompt. */
  conversation_id: z.preprocess(
    (val) => (val === "" || val === null || val === undefined ? undefined : val),
    z.string().uuid().optional(),
  ),
  /** When true, stream begins with a **`formatted_prompt`** chunk (exact **`messages`** sent to the LLM). */
  include_formatted_prompt: z.boolean().optional().default(false),
});

export type AiPromptBody = z.infer<typeof aiPromptBodySchema>;

/** **`POST /ai/prompt`** success body (Swift decodes snake_case usage fields). */
export const aiPromptCompletionResponseSchema = z.object({
  content: z.string(),
  model: z.string(),
  /** Resolved conversation id (echoed when client sent one, or the server-generated id). */
  conversation_id: z.string().uuid().optional(),
  usage: z.object({
    prompt_tokens: z.number(),
    completion_tokens: z.number(),
    total_tokens: z.number(),
    cached_prompt_tokens: z.number().nullable(),
  }),
});

export type AiPromptCompletionResponseBody = z.infer<typeof aiPromptCompletionResponseSchema>;

export const aiPromptStreamChunkSchema = z.discriminatedUnion("type", [
  z.object({
    type: z.literal("conversation"),
    conversation_id: z.string().uuid(),
  }),
  z.object({
    type: z.literal("formatted_prompt"),
    messages: z.array(
      z.object({
        role: z.enum(["system", "user", "assistant"]),
        content: z.string(),
      }),
    ),
  }),
  z.object({
    type: z.literal("content"),
    content: z.string(),
  }),
  z.object({
    type: z.literal("done"),
    model: z.string(),
    usage: z.object({
      prompt_tokens: z.number(),
      completion_tokens: z.number(),
      total_tokens: z.number(),
      cached_prompt_tokens: z.number().nullable(),
    }),
  }),
  z.object({
    type: z.literal("error"),
    error: z.string(),
    status: z.number().optional(),
  }),
]);

export type AiPromptStreamChunk = z.infer<typeof aiPromptStreamChunkSchema>;
