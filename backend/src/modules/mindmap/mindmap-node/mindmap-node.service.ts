import type { MindmapNode } from "@prisma/client";

import * as mindmapRepository from "../mindmap.repository";
import type { MindmapNodeCreateBody, MindmapNodeUpdateBody, SearchMindmapNodesQuery } from "./mindmap-node.schema";
import * as mindmapNodeRepository from "./mindmap-node.repository";

export async function searchMindmapNodesForUser(
  authUserId: string,
  query: SearchMindmapNodesQuery,
): Promise<MindmapNode[]> {
  return mindmapNodeRepository.findMindmapNodesForUserMindmap(
    authUserId,
    query.mindmap_id,
    query.q,
  );
}

export type MindmapNodeCreateResult =
  | { ok: true; mindmapNode: MindmapNode }
  | { ok: false; reason: "mindmap_not_found" };

export async function createMindmapNodeForUser(
  authUserId: string,
  body: MindmapNodeCreateBody,
): Promise<MindmapNodeCreateResult> {
  const mindmap = await mindmapRepository.findMindmapByIdForUser(authUserId, body.mindmapId);
  if (!mindmap) {
    return { ok: false, reason: "mindmap_not_found" };
  }
  const mindmapNode = await mindmapNodeRepository.createMindmapNodeForUser(authUserId, body);
  return { ok: true, mindmapNode };
}

export type MindmapNodeUpdateResult =
  | { ok: true; mindmapNode: MindmapNode }
  | { ok: false; reason: "mindmap_node_not_found" | "mindmap_not_found" };

export async function updateMindmapNodeForUser(
  authUserId: string,
  mindmapNodeId: string,
  body: MindmapNodeUpdateBody,
): Promise<MindmapNodeUpdateResult> {
  if (body.mindmapId !== undefined) {
    const mindmap = await mindmapRepository.findMindmapByIdForUser(authUserId, body.mindmapId);
    if (!mindmap) {
      return { ok: false, reason: "mindmap_not_found" };
    }
  }

  const row = await mindmapNodeRepository.updateMindmapNodeForUser(authUserId, mindmapNodeId, body);
  if (!row) {
    return { ok: false, reason: "mindmap_node_not_found" };
  }
  return { ok: true, mindmapNode: row };
}

export async function deleteMindmapNodeForUser(
  authUserId: string,
  mindmapNodeId: string,
): Promise<boolean> {
  return mindmapNodeRepository.deleteMindmapNodeForUser(authUserId, mindmapNodeId);
}
