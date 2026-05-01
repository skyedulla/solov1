import { Prisma, type MindmapNode } from "@prisma/client";
import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";

import { prisma } from "../../core/prisma";
import type { NodeCreateBody, NodeUpdateBody } from "./node.schema";

/** Maximum rows returned by **`findNodesForUserMindmap`** (search / unsorted list). */
export const NODES_SEARCH_LIMIT = 5;

type MindmapNodeSqlRow = {
  id: string;
  user_id: string;
  idea_id: string;
  mindmap_id: string;
  parent_node_id: string | null;
  position_x: number;
  position_y: number;
  text: string;
  width: number;
  height: number;
  created_at: Date;
  updated_at: Date;
};

function mapSqlRowToMindmapNode(row: MindmapNodeSqlRow): MindmapNode {
  return {
    id: row.id,
    userId: row.user_id,
    ideaId: row.idea_id,
    mindmapId: row.mindmap_id,
    parentNodeId: row.parent_node_id,
    positionX: row.position_x,
    positionY: row.position_y,
    text: row.text,
    width: row.width,
    height: row.height,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

/**
 * Lists up to **`NODES_SEARCH_LIMIT`** nodes for the map.
 * - Empty **`searchQuery`**: all nodes, ordered by **`text`** ascending.
 * - Non-empty: case-insensitive substring match on **`text`** (`strpos`), ordered alphabetically by the suffix starting **after** the first match (the “next characters” after **`q`**).
 */
export async function findNodesForUserMindmap(
  userId: string,
  mindmapId: string,
  searchQuery: string,
): Promise<MindmapNode[]> {
  const q = searchQuery;

  if (q.length === 0) {
    return prisma.mindmapNode.findMany({
      where: { userId, mindmapId },
      orderBy: [{ text: "asc" }, { id: "asc" }],
      take: NODES_SEARCH_LIMIT,
    });
  }

  const rows = await prisma.$queryRaw<MindmapNodeSqlRow[]>(Prisma.sql`
      SELECT id, user_id, idea_id, mindmap_id, parent_node_id, position_x, position_y, text, width, height, created_at, updated_at
      FROM mindmap_nodes
      WHERE user_id = ${userId}
        AND mindmap_id = ${mindmapId}
        AND strpos(lower(text), lower(${q}::text)) > 0
      ORDER BY lower(substring(text FROM strpos(lower(text), lower(${q}::text)) + char_length(${q}::text))) ASC,
        id ASC
      LIMIT ${NODES_SEARCH_LIMIT}
    `);

  return rows.map(mapSqlRowToMindmapNode);
}

/** All nodes for a map and idea (no search limit — used when loading a full mind map). */
export async function findAllNodesForUserMindmapIdea(
  userId: string,
  mindmapId: string,
  ideaId: string,
): Promise<MindmapNode[]> {
  return prisma.mindmapNode.findMany({
    where: { userId, mindmapId, ideaId },
    orderBy: [{ text: "asc" }, { id: "asc" }],
  });
}

export async function createNodeForUser(userId: string, body: NodeCreateBody): Promise<MindmapNode> {
  return prisma.mindmapNode.create({
    data: {
      userId,
      ideaId: body.ideaId,
      mindmapId: body.mindmapId,
      parentNodeId: body.parentNodeId ?? null,
      positionX: body.position.x,
      positionY: body.position.y,
      text: body.text,
      width: body.dimensions.width,
      height: body.dimensions.height,
    },
  });
}

export async function findNodeByIdForUser(userId: string, nodeId: string): Promise<MindmapNode | null> {
  return prisma.mindmapNode.findFirst({
    where: { id: nodeId, userId },
  });
}

export async function updateNodeForUser(
  userId: string,
  nodeId: string,
  body: NodeUpdateBody,
): Promise<MindmapNode | null> {
  const data: Prisma.MindmapNodeUpdateInput = {};

  if (body.ideaId !== undefined) {
    data.ideaId = body.ideaId;
  }
  if (body.mindmapId !== undefined) {
    data.mindmapId = body.mindmapId;
  }
  if (body.parentNodeId !== undefined) {
    data.parentNodeId = body.parentNodeId;
  }
  if (body.position !== undefined) {
    data.positionX = body.position.x;
    data.positionY = body.position.y;
  }
  if (body.text !== undefined) {
    data.text = body.text;
  }
  if (body.dimensions !== undefined) {
    data.width = body.dimensions.width;
    data.height = body.dimensions.height;
  }

  if (Object.keys(data).length === 0) {
    return prisma.mindmapNode.findFirst({
      where: { id: nodeId, userId },
    });
  }

  try {
    return await prisma.mindmapNode.update({
      where: { id: nodeId, userId },
      data,
    });
  } catch (error) {
    if (error instanceof PrismaClientKnownRequestError && error.code === "P2025") {
      return null;
    }
    throw error;
  }
}

export async function deleteNodeForUser(userId: string, nodeId: string): Promise<boolean> {
  const result = await prisma.mindmapNode.deleteMany({
    where: { id: nodeId, userId },
  });
  return result.count > 0;
}
