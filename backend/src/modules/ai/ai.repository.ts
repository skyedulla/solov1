import type { AIConversation, AIMessage } from "@prisma/client";

import { prisma } from "../../core/prisma";

export async function findConversationForUser(
  userId: string,
  ideaId: string,
  conversationId: string,
): Promise<AIConversation | null> {
  return prisma.aIConversation.findFirst({
    where: {
      id: conversationId,
      ideaId,
      idea: {
        userId,
      },
    },
  });
}

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

export async function findMessagesForConversation(
  conversationId: string,
): Promise<Pick<AIMessage, "prompt" | "output">[]> {
  return prisma.aIMessage.findMany({
    where: { conversationId },
    orderBy: { createdAt: "asc" },
    select: {
      prompt: true,
      output: true,
    },
  });
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
