import type { MindmapConnection, MindmapNode } from "@prisma/client";

import { completeChat } from "../../core/llm_service/chatCompletion";
import * as connectionRepository from "../connections/connection.repository";
import * as nodeRepository from "../nodes/node.repository";
import type { MindmapCreateBody, ListMindmapsQuery } from "./mindmap.schema";
import {
  buildMindmapSummarizationMessages,
  mindmapSummarizationInputFromPersisted,
} from "./prompt_constructor/mindmapSummarizationPrompt";
import * as mindmapRepository from "./mindmap.repository";

export type MindmapLoadDocument = {
  id: string;
  ideaId: string;
  title: string;
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
    nodeRepository.findAllNodesForUserMindmap(authUserId, mindmapId),
    connectionRepository.findConnectionsForUserMindmap(authUserId, mindmapId),
  ]);

  return { id: mindmap.id, ideaId: mindmap.ideaId, title: mindmap.title, nodes, connections };
}

export async function deleteMindmapForUser(
  authUserId: string,
  mindmapId: string,
  ideaId: string,
): Promise<boolean> {
  return mindmapRepository.deleteMindmapCascadeForUser(authUserId, mindmapId, ideaId);
}

export type GenerateMindmapSummaryResult =
  | { ok: true; summary: string }
  | { ok: false; kind: "not_found" }
  | { ok: false; kind: "llm_error"; message: string };

/**
 * Loads the mind map graph, builds summarization messages, runs **`completeChat`**, persists **`summary`**, returns new text.
 */
export async function generateMindmapSummaryForUser(
  authUserId: string,
  mindmapId: string,
  ideaId: string,
): Promise<GenerateMindmapSummaryResult> {
  const mindmap = await mindmapRepository.findMindmapByIdForUserAndIdea(authUserId, mindmapId, ideaId);
  if (!mindmap) {
    return { ok: false, kind: "not_found" };
  }

  const [nodes, connections] = await Promise.all([
    nodeRepository.findAllNodesForUserMindmap(authUserId, mindmapId),
    connectionRepository.findConnectionsForUserMindmap(authUserId, mindmapId),
  ]);

  const promptInput = mindmapSummarizationInputFromPersisted({
    title: mindmap.title,
    currentSummary: mindmap.summary.trim().length > 0 ? mindmap.summary : null,
    nodes,
    connections,
  });

  const messages = buildMindmapSummarizationMessages(promptInput);
  const completion = await completeChat({
    messages,
    temperature: 0.35,
    maxCompletionTokens: 8192,
  });

  if (!completion.ok) {
    return { ok: false, kind: "llm_error", message: completion.error };
  }

  const persisted = await mindmapRepository.updateMindmapSummaryForUser(
    authUserId,
    mindmapId,
    ideaId,
    completion.content,
  );
  if (!persisted) {
    return { ok: false, kind: "not_found" };
  }

  return { ok: true, summary: completion.content };
}
