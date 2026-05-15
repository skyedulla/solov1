import type { MindmapConnection } from "@prisma/client";

import * as mindmapRepository from "../mindmap.repository";
import type {
  MindmapConnectionCreateBody,
  MindmapConnectionUpdateBody,
  ListMindmapConnectionsQuery,
} from "./mindmap-connection.schema";
import * as mindmapConnectionRepository from "./mindmap-connection.repository";

export async function listMindmapConnectionsForUser(
  authUserId: string,
  query: ListMindmapConnectionsQuery,
): Promise<MindmapConnection[]> {
  return mindmapConnectionRepository.findMindmapConnectionsForUserMindmap(
    authUserId,
    query.mindmap_id,
  );
}

export type MindmapConnectionCreateResult =
  | { ok: true; mindmapConnection: MindmapConnection }
  | { ok: false; reason: "mindmap_not_found" };

export async function createMindmapConnectionForUser(
  authUserId: string,
  body: MindmapConnectionCreateBody,
): Promise<MindmapConnectionCreateResult> {
  const mindmap = await mindmapRepository.findMindmapByIdForUser(authUserId, body.mindmapId);
  if (!mindmap) {
    return { ok: false, reason: "mindmap_not_found" };
  }
  const mindmapConnection = await mindmapConnectionRepository.createMindmapConnectionForUser(
    authUserId,
    body,
  );
  return { ok: true, mindmapConnection };
}

export type MindmapConnectionUpdateResult =
  | { ok: true; mindmapConnection: MindmapConnection }
  | { ok: false; reason: "mindmap_connection_not_found" | "mindmap_not_found" };

export async function updateMindmapConnectionForUser(
  authUserId: string,
  mindmapConnectionId: string,
  body: MindmapConnectionUpdateBody,
): Promise<MindmapConnectionUpdateResult> {
  if (body.mindmapId !== undefined) {
    const mindmap = await mindmapRepository.findMindmapByIdForUser(authUserId, body.mindmapId);
    if (!mindmap) {
      return { ok: false, reason: "mindmap_not_found" };
    }
  }

  const row = await mindmapConnectionRepository.updateMindmapConnectionForUser(
    authUserId,
    mindmapConnectionId,
    body,
  );
  if (!row) {
    return { ok: false, reason: "mindmap_connection_not_found" };
  }
  return { ok: true, mindmapConnection: row };
}

export async function deleteMindmapConnectionForUser(
  authUserId: string,
  mindmapConnectionId: string,
): Promise<boolean> {
  return mindmapConnectionRepository.deleteMindmapConnectionForUser(
    authUserId,
    mindmapConnectionId,
  );
}
