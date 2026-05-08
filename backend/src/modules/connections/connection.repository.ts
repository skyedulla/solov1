import { Prisma, type MindmapConnection, type MindmapConnectionAnchor } from "@prisma/client";
import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";

import { prisma } from "../../core/prisma";
import type { ConnectionCreateBody, ConnectionUpdateBody } from "./connection.schema";

function toDbAnchor(value: string): MindmapConnectionAnchor {
  return value as MindmapConnectionAnchor;
}

export async function findConnectionsForUserMindmap(
  userId: string,
  mindmapId: string,
): Promise<MindmapConnection[]> {
  return prisma.mindmapConnection.findMany({
    where: { userId, mindmapId },
    orderBy: [{ createdAt: "asc" }, { id: "asc" }],
  });
}

export async function createConnectionForUser(
  userId: string,
  body: ConnectionCreateBody,
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

export async function findConnectionByIdForUser(
  userId: string,
  connectionId: string,
): Promise<MindmapConnection | null> {
  return prisma.mindmapConnection.findFirst({
    where: { id: connectionId, userId },
  });
}

export async function updateConnectionForUser(
  userId: string,
  connectionId: string,
  body: ConnectionUpdateBody,
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
      where: { id: connectionId, userId },
    });
  }

  try {
    return await prisma.mindmapConnection.update({
      where: { id: connectionId, userId },
      data,
    });
  } catch (error) {
    if (error instanceof PrismaClientKnownRequestError && error.code === "P2025") {
      return null;
    }
    throw error;
  }
}

export async function deleteConnectionForUser(userId: string, connectionId: string): Promise<boolean> {
  const result = await prisma.mindmapConnection.deleteMany({
    where: { id: connectionId, userId },
  });
  return result.count > 0;
}
