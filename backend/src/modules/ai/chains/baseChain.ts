import { AIMessage, HumanMessage } from "@langchain/core/messages";
import type { BaseMessage } from "@langchain/core/messages";
import { ChatPromptTemplate, MessagesPlaceholder } from "@langchain/core/prompts";

import { streamCompleteChat, type LlmChatMessage, type LlmCompletionUsage } from "../../../core/llm_service";
import type { LlmCallSource } from "../../../core/llm_service";
import { BASE_SOLO_SYSTEM_PROMPT } from "../system_prompts";
import * as aiRepository from "../ai.repository";
import { resolvePromptVariables } from "../resolvers/promptVariableResolvers";
import type { AiToolConfig } from "../tools/toolRegistry";

export type BaseChainInput = {
  toolConfig: AiToolConfig;
  userId: string;
  ideaId: string;
  conversationId: string;
  query: string;
  context: Record<string, string>;
  model: string;
  temperature: number;
  maxTokens?: number;
};

export type BaseChainUsage = {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  cachedPromptTokens: number | null;
};

export type BaseChainResult = {
  content: string;
  model: string;
  usage: BaseChainUsage;
};

export type BaseChainStreamChunk =
  | { kind: "content"; text: string }
  | { kind: "done"; model: string; usage: BaseChainUsage }
  | {
      kind: "error";
      error: string;
      status?: number;
      source?: LlmCallSource;
    };

function fillSystemPrompt(template: string, variables: Record<string, string>): string {
  return Object.entries(variables).reduce(
    (prompt, [key, value]) => prompt.replaceAll(`{${key}}`, value),
    template,
  );
}

function buildCurrentUserMessage(query: string, context: Record<string, string>): string {
  return [
    query,
    "",
    "Current context JSON:",
    JSON.stringify(context, null, 2),
  ].join("\n");
}

function contentFromMessage(message: BaseMessage): string {
  if (typeof message.content === "string") {
    return message.content;
  }
  return message.content.map((part) => (typeof part === "string" ? part : "text" in part ? part.text : "")).join("");
}

async function loadConversationMessages(input: BaseChainInput): Promise<BaseMessage[] | null> {
  const turns = await aiRepository.findMessagesForUserConversation({
    userId: input.userId,
    ideaId: input.ideaId,
    conversationId: input.conversationId,
  });
  if (turns === null) {
    return null;
  }
  return turns.flatMap((turn) => [new HumanMessage(turn.prompt), new AIMessage(turn.output)]);
}

function toLlmChatMessages(messages: BaseMessage[]): LlmChatMessage[] {
  return messages.map((message) => {
    const type = message._getType();
    if (type === "human") {
      return { role: "user", content: contentFromMessage(message) };
    }
    if (type === "ai") {
      return { role: "assistant", content: contentFromMessage(message) };
    }
    return { role: "system", content: contentFromMessage(message) };
  });
}

async function streamCompletionToResult(input: BaseChainInput, messages: LlmChatMessage[]): Promise<BaseChainResult> {
  let content = "";
  let model = input.model;
  let usage: LlmCompletionUsage = {
    promptTokens: 0,
    completionTokens: 0,
    totalTokens: 0,
    cachedPromptTokens: null,
  };

  for await (const chunk of streamCompleteChat({
    messages,
    model: input.model,
    temperature: input.temperature,
    maxCompletionTokens: input.maxTokens,
    source: {
      module: "ai",
      operation: "baseChain.streamCompletion",
      toolType: input.toolConfig.toolType,
      sessionId: input.conversationId,
    },
  })) {
    if (chunk.kind === "content") {
      content += chunk.text;
      continue;
    }
    if (chunk.kind === "done") {
      model = chunk.model ?? model;
      usage = chunk.usage ?? usage;
      continue;
    }
    throw new Error(`LLM call failed from ${chunk.source?.module ?? "unknown"}: ${chunk.error}`);
  }

  const trimmed = content.trim();
  if (!trimmed) {
    throw new Error("LLM returned no assistant message content");
  }

  return {
    content: trimmed,
    model,
    usage,
  };
}

export async function prepareBaseChainLlmMessages(input: BaseChainInput): Promise<LlmChatMessage[] | null> {
  const variables = await resolvePromptVariables({
    userId: input.userId,
    ideaId: input.ideaId,
    requiredVariables: input.toolConfig.requiredVariables,
  });
  if (!variables) {
    return null;
  }

  // Inline templates from `system_prompts.ts`, wired per tool in `tools/*.ts` → `toolRegistry`.
  const systemPromptTemplate = input.toolConfig.systemPrompt;

  const toolSystemPrompt = fillSystemPrompt(systemPromptTemplate, variables);

  const prompt = ChatPromptTemplate.fromMessages([
    ["system", BASE_SOLO_SYSTEM_PROMPT],
    ["system", toolSystemPrompt],
    new MessagesPlaceholder("history"),
    ["human", "{question}"],
  ]);

  const history = await loadConversationMessages(input);
  if (history === null) {
    return null;
  }

  const formattedMessages = await prompt.formatMessages({
    history,
    question: buildCurrentUserMessage(input.query, input.context),
  });

  return toLlmChatMessages(formattedMessages);
}

/** Streams completion for messages already built by **`prepareBaseChainLlmMessages`**. */
export async function* streamBaseChainCompletion(
  input: BaseChainInput,
  messages: LlmChatMessage[],
): AsyncGenerator<BaseChainStreamChunk> {
  let model = input.model;
  let usage: BaseChainUsage = {
    promptTokens: 0,
    completionTokens: 0,
    totalTokens: 0,
    cachedPromptTokens: null,
  };

  for await (const chunk of streamCompleteChat({
    messages,
    model: input.model,
    temperature: input.temperature,
    maxCompletionTokens: input.maxTokens,
    source: {
      module: "ai",
      operation: "baseChain.streamCompletion",
      toolType: input.toolConfig.toolType,
      sessionId: input.conversationId,
    },
  })) {
    if (chunk.kind === "content") {
      yield { kind: "content", text: chunk.text };
      continue;
    }
    if (chunk.kind === "done") {
      model = chunk.model ?? model;
      usage = chunk.usage ?? usage;
      yield { kind: "done", model, usage };
      continue;
    }
    yield {
      kind: "error",
      error: chunk.error,
      status: chunk.status,
      source: chunk.source,
    };
  }
}

export async function streamBaseChain(input: BaseChainInput): Promise<AsyncGenerator<BaseChainStreamChunk> | null> {
  const messages = await prepareBaseChainLlmMessages(input);
  if (!messages) {
    return null;
  }
  return streamBaseChainCompletion(input, messages);
}

export async function invokeBaseChain(input: BaseChainInput): Promise<BaseChainResult | null> {
  const messages = await prepareBaseChainLlmMessages(input);
  if (!messages) {
    return null;
  }
  return streamCompletionToResult(input, messages);
}
