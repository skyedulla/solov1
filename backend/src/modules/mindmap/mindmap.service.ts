import type { MindmapConnection, MindmapNode } from "@prisma/client";

import * as connectionRepository from "../connection/connection.repository";
import * as nodeRepository from "../nodes/node.repository";
import type { MindmapCreateBody, ListMindmapsQuery } from "./mindmap.schema";
import * as mindmapRepository from "./mindmap.repository";

export type MindmapLoadDocument = {
  id: string;
  ideaId: string;
  nodes: MindmapNode[];
  connections: MindmapConnection[];
};

export async function createMindmapForUser(authUserId: string, body: MindmapCreateBody): Promise<
  Awaited<ReturnType<typeof mindmapRepository.createMindmapForUser>>
> {
  return mindmapRepository.createMindmapForUser(authUserId, body);
}

export async function listMindmapsForUser(
  authUserId: string,
  query: ListMindmapsQuery,
): Promise<Awaited<ReturnType<typeof mindmapRepository.findMindmapsForUserByIdea>>> {
  return mindmapRepository.findMindmapsForUserByIdea(authUserId, query.idea_id);
}

/**
 * Loads graph data when **`mindmaps`** row exists for **`authUserId`** + **`mindmapId`** + **`ideaId`**.
 * Returns **`null`** if that row is missing (caller maps to **`404`**).
 */
export async function loadMindmapDocumentForUser(
  authUserId: string,
  mindmapId: string,
  ideaId: string,
): Promise<MindmapLoadDocument | null> {
  const mindmap = await mindmapRepository.findMindmapByIdForUserAndIdea(authUserId, mindmapId, ideaId);
  if (!mindmap) {
    return null;
  }

  const [nodes, connections] = await Promise.all([
    nodeRepository.findAllNodesForUserMindmapIdea(authUserId, mindmapId, ideaId),
    connectionRepository.findConnectionsForUserMindmap(authUserId, mindmapId, ideaId),
  ]);

  return { id: mindmap.id, ideaId: mindmap.ideaId, nodes, connections };
}

export async function deleteMindmapForUser(
  authUserId: string,
  mindmapId: string,
  ideaId: string,
): Promise<boolean> {
  return mindmapRepository.deleteMindmapCascadeForUser(authUserId, mindmapId, ideaId);
}
