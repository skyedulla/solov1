import type { Idea } from "@prisma/client";

import type { IdeaCreateBody, IdeaSortBy, ListIdeasQuery } from "./idea.schema";
import * as ideaRepository from "./idea.repository";

/** Maps a validated list query into repository parameters (extend when adding filters, paging, policy). */
function toRepositoryListParams(query: ListIdeasQuery): { sort: IdeaSortBy; searchQuery: string } {
  return {
    sort: query.sort,
    searchQuery: query.q,
  };
}

/**
 * Lists ideas for the authenticated identity (Supabase user id).
 * Orchestration and cross-domain rules belong here; persistence stays in the repository.
 */
export async function listIdeasForUser(authUserId: string, query: ListIdeasQuery): Promise<Idea[]> {
  return ideaRepository.findIdeasForUser(authUserId, toRepositoryListParams(query));
}

export async function createIdeaForUser(authUserId: string, body: IdeaCreateBody): Promise<Idea> {
  return ideaRepository.createIdeaForUser(authUserId, body);
}
