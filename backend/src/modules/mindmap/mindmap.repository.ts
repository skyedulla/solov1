import type { Mindmap } from "@prisma/client";

import { prisma } from "../../core/prisma";
import type { MindmapCreateBody } from "./mindmap.schema";

export async function createMindmapForUser(userId: string, body: MindmapCreateBody): Promise<Mindmap> {
  return prisma.mindmap.create({
    data: {
      userId,
      ideaId: body.ideaId,
      title: body.title ?? "",
      summary: body.summary ?? "",
    },
  });
}

export async function findMindmapByIdForUserAndIdea(
  userId: string,
  mindmapId: string,
  ideaId: string,
): Promise<Mindmap | null> {
  return prisma.mindmap.findFirst({
    where: { id: mindmapId, userId, ideaId },
  });
}

export async function findMindmapsForUserByIdea(userId: string, ideaId: string): Promise<Mindmap[]> {
  return prisma.mindmap.findMany({
    where: { userId, ideaId },
    orderBy: [{ updatedAt: "desc" }, { id: "asc" }],
  });
}

/**
 * Deletes **`mindmap_connections`**, **`mindmap_nodes`**, then **`mindmaps`** when a row exists for **`userId`** + **`mindmapId`** + **`ideaId`**.
 * Returns **`false`** when no such mind map row exists.
 */
export async function deleteMindmapCascadeForUser(
  userId: string,
  mindmapId: string,
  ideaId: string,
): Promise<boolean> {
  return prisma.$transaction(async (tx) => {
    const existing = await tx.mindmap.findFirst({
      where: { id: mindmapId, userId, ideaId },
    });
    if (!existing) {
      return false;
    }
    await tx.mindmapConnection.deleteMany({
      where: { userId, mindmapId, ideaId },
    });
    await tx.mindmapNode.deleteMany({
      where: { userId, mindmapId, ideaId },
    });
    await tx.mindmap.delete({
      where: { id: mindmapId },
    });
    return true;
  });
}
