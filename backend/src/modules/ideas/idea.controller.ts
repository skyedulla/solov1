import type { Idea } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import {
  ideaCreateBodySchema,
  ideaIdParamsSchema,
  ideaResponseBodySchema,
  ideaUpdateBodySchema,
  type IdeaResponseBody,
  listIdeasQuerySchema,
} from "./idea.schema";
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

export async function createNewIdea(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = ideaCreateBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const idea = await ideaService.createIdeaForUser(userId, parsed.data);
    res.status(201).json(toIdeaResponseBody(idea));
  } catch (error) {
    next(error);
  }
}

export async function updateIdea(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = ideaIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const bodyParsed = ideaUpdateBodySchema.safeParse(req.body);
  if (!bodyParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: bodyParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const idea = await ideaService.updateIdeaForUser(userId, paramsParsed.data.id, bodyParsed.data);
    if (!idea) {
      res.status(404).json({ error: "Idea not found" });
      return;
    }
    res.status(200).json(toIdeaResponseBody(idea));
  } catch (error) {
    next(error);
  }
}

export async function deleteIdea(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = ideaIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const deleted = await ideaService.deleteIdeaForUser(userId, paramsParsed.data.id);
    if (!deleted) {
      res.status(404).json({ error: "Idea not found" });
      return;
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}
