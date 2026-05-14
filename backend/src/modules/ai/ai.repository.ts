import type { AIConversation, AIMessage } from "@prisma/client";

import { prisma } from "../../core/prisma";

export async function createConversationForUser(params: {
  userId: string;
  ideaId: string;
  title: string;
}): Promise<AIConversation | null> {
  const idea = await prisma.idea.findFirst({
    where: { id: params.ideaId, userId: params.userId },
    select: { id: true },
  });
  if (!idea) {
    return null;
  }

  return prisma.aIConversation.create({
    data: {
      ideaId: params.ideaId,
      title: params.title,
    },
  });
}

/**
 * Loads prior turns ordered by **`createdAt`**. **`null`** = no **`AIConversation`** row for **`(conversationId,
 * ideaId, userId)`** (unknown id or unauthorized). **`[]`** = valid thread with no messages yet.
 */
export async function findMessagesForUserConversation(params: {
  userId: string;
  ideaId: string;
  conversationId: string;
}): Promise<Pick<AIMessage, "prompt" | "output">[] | null> {
  const conv = await prisma.aIConversation.findFirst({
    where: {
      id: params.conversationId,
      ideaId: params.ideaId,
      idea: { userId: params.userId },
    },
    select: {
      messages: {
        orderBy: { createdAt: "asc" },
        select: {
          prompt: true,
          output: true,
        },
      },
    },
  });
  return conv ? conv.messages : null;
}

export async function createMessageForConversation(params: {
  conversationId: string;
  prompt: string;
  output: string;
  tokenCount?: number | null;
}): Promise<AIMessage> {
  return prisma.aIMessage.create({
    data: {
      conversationId: params.conversationId,
      prompt: params.prompt,
      output: params.output,
      tokenCount: params.tokenCount ?? null,
    },
  });
}
