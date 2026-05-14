import type { AiPromptBody, AiPromptStreamChunk } from "./ai.schema";
import * as aiRepository from "./ai.repository";
import { prepareBaseChainLlmMessages, streamBaseChainCompletion } from "./chains/baseChain";
import { getToolConfig } from "./tools/toolRegistry";

function titleFromPrompt(query: string): string {
  const trimmed = query.trim();
  if (trimmed.length <= 64) {
    return trimmed;
  }
  return `${trimmed.slice(0, 61)}...`;
}

async function fetchConversationForPrompt(
  userId: string,
  body: AiPromptBody,
): Promise<{ conversationId: string } | null> {
  if (body.conversation_id) {
    return { conversationId: body.conversation_id };
  }

  const conversation = await aiRepository.createConversationForUser({
    userId,
    ideaId: body.idea_id,
    title: titleFromPrompt(body.query),
  });
  return conversation ? { conversationId: conversation.id } : null;
}

export async function sendPromptStreamForUser(
  userId: string,
  body: AiPromptBody,
): Promise<AsyncGenerator<AiPromptStreamChunk> | null> {
  const resolved = await fetchConversationForPrompt(userId, body);
  if (!resolved) {
    return null;
  }
  const { conversationId } = resolved;

  const toolConfig = await getToolConfig(body.tool_type);
  const chainInput = {
    toolConfig,
    userId,
    ideaId: body.idea_id,
    conversationId,
    query: body.query,
    context: body.context,
    model: body.llm_model,
    temperature: body.temperature,
    maxTokens: body.max_tokens,
  };

  const preparedMessages = await prepareBaseChainLlmMessages(chainInput);
  if (!preparedMessages) {
    return null;
  }
  const llmMessages = preparedMessages;

  async function* toApiChunks(): AsyncGenerator<AiPromptStreamChunk> {
    yield { type: "conversation", conversation_id: conversationId };

    let content = "";
    let model = body.llm_model;
    let promptTokens = 0;
    let completionTokens = 0;
    let totalTokens = 0;
    let cachedPromptTokens: number | null = null;
    let hasError = false;

    if (body.include_formatted_prompt) {
      yield { type: "formatted_prompt", messages: llmMessages };
    }

    for await (const chunk of streamBaseChainCompletion(chainInput, llmMessages)) {
      if (chunk.kind === "content") {
        content += chunk.text;
        yield { type: "content", content: chunk.text };
        continue;
      }
      if (chunk.kind === "done") {
        model = chunk.model;
        promptTokens = chunk.usage.promptTokens;
        completionTokens = chunk.usage.completionTokens;
        totalTokens = chunk.usage.totalTokens;
        cachedPromptTokens = chunk.usage.cachedPromptTokens;
        yield {
          type: "done",
          model,
          usage: {
            prompt_tokens: promptTokens,
            completion_tokens: completionTokens,
            total_tokens: totalTokens,
            cached_prompt_tokens: cachedPromptTokens,
          },
        };
        continue;
      }

      hasError = true;
      yield {
        type: "error",
        error: chunk.error,
        status: chunk.status,
      };
    }

    if (hasError) {
      return;
    }

    const trimmed = content.trim();
    if (!trimmed) {
      yield {
        type: "error",
        error: "LLM returned no assistant message content",
      };
      return;
    }

    await aiRepository.createMessageForConversation({
      conversationId,
      prompt: body.query,
      output: trimmed,
      tokenCount: totalTokens,
    });
  }

  return toApiChunks();
}
