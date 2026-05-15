import type { MindmapNode } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import {
  mindmapNodeCreateBodySchema,
  mindmapNodeIdParamsSchema,
  mindmapNodeResponseBodySchema,
  mindmapNodeUpdateBodySchema,
  searchMindmapNodesQuerySchema,
  type MindmapNodeResponseBody,
} from "./mindmap-node.schema";
import * as mindmapNodeService from "./mindmap-node.service";

function toMindmapNodeResponseBody(row: MindmapNode): MindmapNodeResponseBody {
  return mindmapNodeResponseBodySchema.parse({
    id: row.id,
    mindmap_id: row.mindmapId,
    parent_node_id: row.parentNodeId,
    position: { x: row.positionX, y: row.positionY },
    text: row.text,
    dimensions: { height: row.height, width: row.width },
  });
}

export async function searchMindmapNodes(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const parsed = searchMindmapNodesQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const rows = await mindmapNodeService.searchMindmapNodesForUser(userId, parsed.data);
    const body: MindmapNodeResponseBody[] = rows.map(toMindmapNodeResponseBody);
    res.status(200).json(body);
  } catch (error) {
    next(error);
  }
}

export async function createMindmapNode(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const parsed = mindmapNodeCreateBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await mindmapNodeService.createMindmapNodeForUser(userId, parsed.data);
    if (!result.ok) {
      res.status(404).json({ error: "Mindmap not found" });
      return;
    }
    res.status(201).json(toMindmapNodeResponseBody(result.mindmapNode));
  } catch (error) {
    next(error);
  }
}

export async function updateMindmapNode(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const paramsParsed = mindmapNodeIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const bodyParsed = mindmapNodeUpdateBodySchema.safeParse(req.body);
  if (!bodyParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: bodyParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await mindmapNodeService.updateMindmapNodeForUser(
      userId,
      paramsParsed.data.id,
      bodyParsed.data,
    );
    if (!result.ok) {
      if (result.reason === "mindmap_not_found") {
        res.status(404).json({ error: "Mindmap not found" });
        return;
      }
      res.status(404).json({ error: "Mindmap node not found" });
      return;
    }
    res.status(200).json(toMindmapNodeResponseBody(result.mindmapNode));
  } catch (error) {
    next(error);
  }
}

export async function deleteMindmapNode(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const paramsParsed = mindmapNodeIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const deleted = await mindmapNodeService.deleteMindmapNodeForUser(userId, paramsParsed.data.id);
    if (!deleted) {
      res.status(404).json({ error: "Mindmap node not found" });
      return;
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}
