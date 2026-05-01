import type { MindmapConnection } from "@prisma/client";

import * as mindmapRepository from "../mindmap/mindmap.repository";
import type { ConnectionCreateBody, ConnectionUpdateBody, ListConnectionsQuery } from "./connection.schema";
import * as connectionRepository from "./connection.repository";

export async function listConnectionsForUser(
  authUserId: string,
  query: ListConnectionsQuery,
): Promise<MindmapConnection[]> {
  return connectionRepository.findConnectionsForUserMindmap(authUserId, query.mindmap_id);
}

export type ConnectionCreateResult =
  | { ok: true; connection: MindmapConnection }
  | { ok: false; reason: "mindmap_not_found" };

export async function createConnectionForUser(
  authUserId: string,
  body: ConnectionCreateBody,
): Promise<ConnectionCreateResult> {
  const mindmap = await mindmapRepository.findMindmapByIdForUserAndIdea(
    authUserId,
    body.mindmapId,
    body.ideaId,
  );
  if (!mindmap) {
    return { ok: false, reason: "mindmap_not_found" };
  }
  const connection = await connectionRepository.createConnectionForUser(authUserId, body);
  return { ok: true, connection };
}

export type ConnectionUpdateResult =
  | { ok: true; connection: MindmapConnection }
  | { ok: false; reason: "connection_not_found" | "mindmap_not_found" };

export async function updateConnectionForUser(
  authUserId: string,
  connectionId: string,
  body: ConnectionUpdateBody,
): Promise<ConnectionUpdateResult> {
  if (body.ideaId !== undefined || body.mindmapId !== undefined) {
    const current = await connectionRepository.findConnectionByIdForUser(authUserId, connectionId);
    if (!current) {
      return { ok: false, reason: "connection_not_found" };
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

  const row = await connectionRepository.updateConnectionForUser(authUserId, connectionId, body);
  if (!row) {
    return { ok: false, reason: "connection_not_found" };
  }
  return { ok: true, connection: row };
}

export async function deleteConnectionForUser(authUserId: string, connectionId: string): Promise<boolean> {
  return connectionRepository.deleteConnectionForUser(authUserId, connectionId);
}
