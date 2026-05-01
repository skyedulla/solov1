import type { MindmapNode } from "@prisma/client";

import * as mindmapRepository from "../mindmap/mindmap.repository";
import type { SearchNodesQuery, NodeCreateBody, NodeUpdateBody } from "./node.schema";
import * as nodeRepository from "./node.repository";

export async function searchNodesForUser(authUserId: string, query: SearchNodesQuery): Promise<MindmapNode[]> {
  return nodeRepository.findNodesForUserMindmap(authUserId, query.mindmap_id, query.q);
}

export type NodeCreateResult =
  | { ok: true; node: MindmapNode }
  | { ok: false; reason: "mindmap_not_found" };

export async function createNodeForUser(authUserId: string, body: NodeCreateBody): Promise<NodeCreateResult> {
  const mindmap = await mindmapRepository.findMindmapByIdForUserAndIdea(
    authUserId,
    body.mindmapId,
    body.ideaId,
  );
  if (!mindmap) {
    return { ok: false, reason: "mindmap_not_found" };
  }
  const node = await nodeRepository.createNodeForUser(authUserId, body);
  return { ok: true, node };
}

export type NodeUpdateResult =
  | { ok: true; node: MindmapNode }
  | { ok: false; reason: "node_not_found" | "mindmap_not_found" };

export async function updateNodeForUser(
  authUserId: string,
  nodeId: string,
  body: NodeUpdateBody,
): Promise<NodeUpdateResult> {
  if (body.ideaId !== undefined || body.mindmapId !== undefined) {
    const current = await nodeRepository.findNodeByIdForUser(authUserId, nodeId);
    if (!current) {
      return { ok: false, reason: "node_not_found" };
    }
    const nextIdeaId = body.ideaId ?? current.ideaId;
    const nextMindmapId = body.mindmapId ?? current.mindmapId;
    const mindmap = await mindmapRepository.findMindmapByIdForUserAndIdea(
      authUserId,
      nextMindmapId,
      nextIdeaId,
    );
    if (!mindmap) {
      return { ok: false, reason: "mindmap_not_found" };
    }
  }

  const row = await nodeRepository.updateNodeForUser(authUserId, nodeId, body);
  if (!row) {
    return { ok: false, reason: "node_not_found" };
  }
  return { ok: true, node: row };
}

export async function deleteNodeForUser(authUserId: string, nodeId: string): Promise<boolean> {
  return nodeRepository.deleteNodeForUser(authUserId, nodeId);
}
