import { Prisma, type MindmapConnection, type MindmapConnectionAnchor } from "@prisma/client";
import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";

import { prisma } from "../../../core/prisma";
import type { MindmapConnectionCreateBody, MindmapConnectionUpdateBody } from "./mindmap-connection.schema";

function toDbAnchor(value: string): MindmapConnectionAnchor {
  return value as MindmapConnectionAnchor;
}

export async function findMindmapConnectionsForUserMindmap(
  userId: string,
  mindmapId: string,
): Promise<MindmapConnection[]> {
  return prisma.mindmapConnection.findMany({
    where: { userId, mindmapId },
    orderBy: [{ createdAt: "asc" }, { id: "asc" }],
  });
}

export async function createMindmapConnectionForUser(
  userId: string,
  body: MindmapConnectionCreateBody,
): Promise<MindmapConnection> {
  return prisma.mindmapConnection.create({
    data: {
      userId,
      mindmapId: body.mindmapId,
      sourceNodeId: body.sourceNodeId,
      sourceAnchor: toDbAnchor(body.sourceAnchor),
      targetNodeId: body.targetNodeId ?? null,
      targetAnchor: body.targetAnchor !== undefined ? toDbAnchor(body.targetAnchor) : null,
    },
  });
}

export async function findMindmapConnectionByIdForUser(
  userId: string,
  mindmapConnectionId: string,
): Promise<MindmapConnection | null> {
  return prisma.mindmapConnection.findFirst({
    where: { id: mindmapConnectionId, userId },
  });
}

export async function updateMindmapConnectionForUser(
  userId: string,
  mindmapConnectionId: string,
  body: MindmapConnectionUpdateBody,
): Promise<MindmapConnection | null> {
  const data: Prisma.MindmapConnectionUpdateInput = {};

  if (body.mindmapId !== undefined) {
    data.mindmapId = body.mindmapId;
  }
  if (body.sourceNodeId !== undefined) {
    data.sourceNodeId = body.sourceNodeId;
  }
  if (body.targetNodeId !== undefined) {
    data.targetNodeId = body.targetNodeId;
  }
  if (body.sourceAnchor !== undefined) {
    data.sourceAnchor = toDbAnchor(body.sourceAnchor);
  }
  if (body.targetAnchor !== undefined) {
    data.targetAnchor = body.targetAnchor === null ? null : toDbAnchor(body.targetAnchor);
  }

  if (Object.keys(data).length === 0) {
    return prisma.mindmapConnection.findFirst({
      where: { id: mindmapConnectionId, userId },
    });
  }

  try {
    return await prisma.mindmapConnection.update({
      where: { id: mindmapConnectionId, userId },
      data,
    });
  } catch (error) {
    if (error instanceof PrismaClientKnownRequestError && error.code === "P2025") {
      return null;
    }
    throw error;
  }
}

export async function deleteMindmapConnectionForUser(
  userId: string,
  mindmapConnectionId: string,
): Promise<boolean> {
  const result = await prisma.mindmapConnection.deleteMany({
    where: { id: mindmapConnectionId, userId },
  });
  return result.count > 0;
}
