import type { Idea } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import { ideaResponseBodySchema, type IdeaResponseBody, listIdeasQuerySchema } from "./idea.schema";
import * as ideaService from "./idea.service";

/**
 * Maps a Prisma row to the wire JSON shape and validates with **`ideaResponseBodySchema`**
 * so list responses match the Swift client contract.
 */
function toIdeaResponseBody(idea: Idea): IdeaResponseBody {
  return ideaResponseBodySchema.parse({
    id: idea.id,
    title: idea.title,
    description: idea.description,
    is_published: idea.isPublished,
    created_at: idea.createdAt.toISOString(),
    last_updated_at: idea.updatedAt.toISOString(),
    target_user: idea.targetUser,
    purpose: idea.purpose,
  });
}

export async function listIdeas(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = listIdeasQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  // `requireAuth` on this router guarantees `req.authUser`; avoid duplicate 401 handling.
  const userId = req.authUser!.id;

  try {
    const ideas = await ideaService.listIdeasForUser(userId, parsed.data);
    const body: IdeaResponseBody[] = ideas.map(toIdeaResponseBody);
    res.status(200).json(body);
  } catch (error) {
    next(error);
  }
}
