import type { MindmapConnection } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import {
  mindmapConnectionCreateBodySchema,
  mindmapConnectionIdParamsSchema,
  mindmapConnectionResponseBodySchema,
  mindmapConnectionUpdateBodySchema,
  listMindmapConnectionsQuerySchema,
  type MindmapConnectionResponseBody,
} from "./mindmap-connection.schema";
import * as mindmapConnectionService from "./mindmap-connection.service";

function toMindmapConnectionResponseBody(row: MindmapConnection): MindmapConnectionResponseBody {
  return mindmapConnectionResponseBodySchema.parse({
    id: row.id,
    mindmap_id: row.mindmapId,
    source_node_id: row.sourceNodeId,
    target_node_id: row.targetNodeId,
    source_anchor: row.sourceAnchor,
    target_anchor: row.targetAnchor,
  });
}

export async function listMindmapConnections(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const parsed = listMindmapConnectionsQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const rows = await mindmapConnectionService.listMindmapConnectionsForUser(userId, parsed.data);
    const body: MindmapConnectionResponseBody[] = rows.map(toMindmapConnectionResponseBody);
    res.status(200).json(body);
  } catch (error) {
    next(error);
  }
}

export async function createMindmapConnection(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const parsed = mindmapConnectionCreateBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await mindmapConnectionService.createMindmapConnectionForUser(userId, parsed.data);
    if (!result.ok) {
      res.status(404).json({ error: "Mindmap not found" });
      return;
    }
    res.status(201).json(toMindmapConnectionResponseBody(result.mindmapConnection));
  } catch (error) {
    next(error);
  }
}

export async function updateMindmapConnection(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const paramsParsed = mindmapConnectionIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const bodyParsed = mindmapConnectionUpdateBodySchema.safeParse(req.body);
  if (!bodyParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: bodyParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await mindmapConnectionService.updateMindmapConnectionForUser(
      userId,
      paramsParsed.data.id,
      bodyParsed.data,
    );
    if (!result.ok) {
      if (result.reason === "mindmap_not_found") {
        res.status(404).json({ error: "Mindmap not found" });
        return;
      }
      res.status(404).json({ error: "Mindmap connection not found" });
      return;
    }
    res.status(200).json(toMindmapConnectionResponseBody(result.mindmapConnection));
  } catch (error) {
    next(error);
  }
}

export async function deleteMindmapConnection(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const paramsParsed = mindmapConnectionIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const deleted = await mindmapConnectionService.deleteMindmapConnectionForUser(
      userId,
      paramsParsed.data.id,
    );
    if (!deleted) {
      res.status(404).json({ error: "Mindmap connection not found" });
      return;
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}
