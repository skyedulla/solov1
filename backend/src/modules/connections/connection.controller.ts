import type { MindmapConnection } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import {
  connectionCreateBodySchema,
  connectionIdParamsSchema,
  connectionResponseBodySchema,
  connectionUpdateBodySchema,
  listConnectionsQuerySchema,
  type ConnectionResponseBody,
} from "./connection.schema";
import * as connectionService from "./connection.service";

function toConnectionResponseBody(row: MindmapConnection): ConnectionResponseBody {
  return connectionResponseBodySchema.parse({
    id: row.id,
    mindmap_id: row.mindmapId,
    source_node_id: row.sourceNodeId,
    target_node_id: row.targetNodeId,
    source_anchor: row.sourceAnchor,
    target_anchor: row.targetAnchor,
  });
}

export async function listConnections(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = listConnectionsQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const rows = await connectionService.listConnectionsForUser(userId, parsed.data);
    const body: ConnectionResponseBody[] = rows.map(toConnectionResponseBody);
    res.status(200).json(body);
  } catch (error) {
    next(error);
  }
}

export async function createConnection(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = connectionCreateBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await connectionService.createConnectionForUser(userId, parsed.data);
    if (!result.ok) {
      res.status(404).json({ error: "Mindmap not found" });
      return;
    }
    res.status(201).json(toConnectionResponseBody(result.connection));
  } catch (error) {
    next(error);
  }
}

export async function updateConnection(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = connectionIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const bodyParsed = connectionUpdateBodySchema.safeParse(req.body);
  if (!bodyParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: bodyParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await connectionService.updateConnectionForUser(
      userId,
      paramsParsed.data.id,
      bodyParsed.data,
    );
    if (!result.ok) {
      if (result.reason === "mindmap_not_found") {
        res.status(404).json({ error: "Mindmap not found" });
        return;
      }
      res.status(404).json({ error: "Connection not found" });
      return;
    }
    res.status(200).json(toConnectionResponseBody(result.connection));
  } catch (error) {
    next(error);
  }
}

export async function deleteConnection(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = connectionIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const deleted = await connectionService.deleteConnectionForUser(userId, paramsParsed.data.id);
    if (!deleted) {
      res.status(404).json({ error: "Connection not found" });
      return;
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}
