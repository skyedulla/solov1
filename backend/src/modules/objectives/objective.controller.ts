import type { Objective } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import {
  objectiveCreateBodySchema,
  objectiveIdParamsSchema,
  objectiveResponseBodySchema,
  objectiveUpdateBodySchema,
  type ObjectiveResponseBody,
} from "./objective.schema";
import * as objectiveService from "./objective.service";

function toObjectiveResponseBody(row: Objective): ObjectiveResponseBody {
  return objectiveResponseBodySchema.parse({
    id: row.id,
    text: row.text,
    is_completed: row.isCompleted,
  });
}

export async function addObjective(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = objectiveCreateBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const row = await objectiveService.createObjectiveForUser(userId, parsed.data);
    res.status(201).json(toObjectiveResponseBody(row));
  } catch (error) {
    next(error);
  }
}

export async function modifyObjective(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const paramsParsed = objectiveIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const bodyParsed = objectiveUpdateBodySchema.safeParse(req.body);
  if (!bodyParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: bodyParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const row = await objectiveService.updateObjectiveForUser(
      userId,
      paramsParsed.data.id,
      bodyParsed.data,
    );
    if (!row) {
      res.status(404).json({ error: "Objective not found" });
      return;
    }
    res.status(200).json(toObjectiveResponseBody(row));
  } catch (error) {
    next(error);
  }
}

export async function completeObjective(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const paramsParsed = objectiveIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const row = await objectiveService.toggleCompleteForUser(userId, paramsParsed.data.id);
    if (!row) {
      res.status(404).json({ error: "Objective not found" });
      return;
    }
    res.status(200).json(toObjectiveResponseBody(row));
  } catch (error) {
    next(error);
  }
}

export async function removeObjective(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const paramsParsed = objectiveIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const deleted = await objectiveService.deleteObjectiveForUser(userId, paramsParsed.data.id);
    if (!deleted) {
      res.status(404).json({ error: "Objective not found" });
      return;
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}
