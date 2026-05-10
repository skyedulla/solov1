import type { ChatCompletionMessageParam } from "openai/resources/chat/completions";

import { logLlmUsage } from "../llmLogger";
import { handleLlmError, llmSourceToString, type LlmCallSource } from "./llmErrorHandler";
import { tryGetOpenAiClient } from "./openaiClient";

export type LlmChatRole = "system" | "user" | "assistant";

export type LlmChatMessage = {
  role: LlmChatRole;
  content: string;
};

export type LlmCompletionUsage = {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  /** Prompt-cache hits appear here when supported; **`null`** if omitted by the API. */
  cachedPromptTokens: number | null;
};

export type LlmCompletionResult =
  | { ok: true; content: string; model: string; usage: LlmCompletionUsage }
  | { ok: false; error: string; status?: number; source?: LlmCallSource };

function toMessages(messages: LlmChatMessage[]): ChatCompletionMessageParam[] {
  return messages.map((m) => ({
    role: m.role,
    content: m.content,
  }));
}

function usageFromCompletion(usage: {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
  prompt_tokens_details?: { cached_tokens?: number } | null;
}): LlmCompletionUsage {
  const cached = usage.prompt_tokens_details?.cached_tokens;
  return {
    promptTokens: usage.prompt_tokens,
    completionTokens: usage.completion_tokens,
    totalTokens: usage.total_tokens,
    cachedPromptTokens: typeof cached === "number" ? cached : null,
  };
}

/** One piece of streamed assistant text (`delta`). */
export type LlmStreamChunk =
  | { kind: "content"; text: string }
  | {
      kind: "done";
      model: string | null;
      /** Present when **`stream_options.include_usage`** is **`true`** and the stream finishes normally. */
      usage: LlmCompletionUsage | null;
    }
  | { kind: "error"; error: string; status?: number; source?: LlmCallSource };

/**
 * Streaming wrapper around **`chat.completions.create`** (`stream: true`).
 * Iterate with **`for await`**; **`done`** fires after all **`content`** chunks (or immediately on error).
 */
export async function* streamCompleteChat(params: {
  messages: LlmChatMessage[];
  model?: string;
  temperature?: number;
  maxCompletionTokens?: number;
  source?: LlmCallSource;
}): AsyncGenerator<LlmStreamChunk> {
  const client = tryGetOpenAiClient();
  if (!client) {
    const handled = handleLlmError(new Error("OPENAI_API_KEY is not set"), params.source);
    yield { kind: "error", error: handled.error, status: handled.status, source: handled.source };
    return;
  }

  try {
    const stream = await client.chat.completions.create({
      model: params.model ?? "gpt-4o-mini",
      messages: toMessages(params.messages),
      temperature: params.temperature,
      max_completion_tokens: params.maxCompletionTokens,
      stream: true,
      stream_options: { include_usage: true },
    });

    let lastModel: string | null = null;
    let lastUsage: LlmCompletionUsage | null = null;

    for await (const chunk of stream) {
      if (chunk.model) {
        lastModel = chunk.model;
      }

      const delta = chunk.choices[0]?.delta?.content;
      if (typeof delta === "string" && delta.length > 0) {
        yield { kind: "content", text: delta };
      }

      const usageRaw = chunk.usage;
      if (usageRaw) {
        lastUsage = usageFromCompletion(usageRaw);
      }
    }

    if (lastModel && lastUsage) {
      logLlmUsage({
        source: llmSourceToString(params.source),
        sessionId: params.source?.sessionId,
        model: lastModel,
        usage: lastUsage,
      });
    }

    yield { kind: "done", model: lastModel, usage: lastUsage };
  } catch (error: unknown) {
    const handled = handleLlmError(error, params.source);
    yield { kind: "error", error: handled.error, status: handled.status, source: handled.source };
  }
}

/**
 * Thin wrapper around **`chat.completions.create`** (non-streaming).
 * Log **`usage.cachedPromptTokens`** in dev/production to verify prompt caching.
 */
export async function completeChat(params: {
  messages: LlmChatMessage[];
  model?: string;
  temperature?: number;
  maxCompletionTokens?: number;
  source?: LlmCallSource;
}): Promise<LlmCompletionResult> {
  const client = tryGetOpenAiClient();
  if (!client) {
    const handled = handleLlmError(new Error("OPENAI_API_KEY is not set"), params.source);
    return { ok: false, error: handled.error, status: handled.status, source: handled.source };
  }

  try {
    const completion = await client.chat.completions.create({
      model: params.model ?? "gpt-4o-mini",
      messages: toMessages(params.messages),
      temperature: params.temperature,
      max_completion_tokens: params.maxCompletionTokens,
    });

    const choice = completion.choices[0]?.message?.content;
    const content = typeof choice === "string" ? choice.trim() : "";
    if (!content) {
      const handled = handleLlmError(new Error("OpenAI returned no assistant message content"), params.source);
      return { ok: false, error: handled.error, status: handled.status, source: handled.source };
    }

    const usageRaw = completion.usage;
    if (!usageRaw) {
      const result = {
        ok: true,
        content,
        model: completion.model,
        usage: {
          promptTokens: 0,
          completionTokens: 0,
          totalTokens: 0,
          cachedPromptTokens: null,
        },
      } as const;
      logLlmUsage({
        source: llmSourceToString(params.source),
        sessionId: params.source?.sessionId,
        model: result.model,
        usage: result.usage,
      });
      return result;
    }

    const result = {
      ok: true,
      content,
      model: completion.model,
      usage: usageFromCompletion(usageRaw),
    } as const;
    logLlmUsage({
      source: llmSourceToString(params.source),
      sessionId: params.source?.sessionId,
      model: result.model,
      usage: result.usage,
    });
    return result;
  } catch (error: unknown) {
    const handled = handleLlmError(error, params.source);
    return { ok: false, error: handled.error, status: handled.status, source: handled.source };
  }
}
