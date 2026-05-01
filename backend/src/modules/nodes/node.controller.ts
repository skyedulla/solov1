import type { MindmapNode } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import {
  nodeCreateBodySchema,
  nodeIdParamsSchema,
  nodeResponseBodySchema,
  nodeUpdateBodySchema,
  searchNodesQuerySchema,
  type NodeResponseBody,
} from "./node.schema";
import * as nodeService from "./node.service";

function toNodeResponseBody(row: MindmapNode): NodeResponseBody {
  return nodeResponseBodySchema.parse({
    id: row.id,
    idea_id: row.ideaId,
    mindmap_id: row.mindmapId,
    parent_node_id: row.parentNodeId,
    position: { x: row.positionX, y: row.positionY },
    text: row.text,
    dimensions: { height: row.height, width: row.width },
  });
}

export async function searchNodes(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = searchNodesQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const rows = await nodeService.searchNodesForUser(userId, parsed.data);
    const body: NodeResponseBody[] = rows.map(toNodeResponseBody);
    res.status(200).json(body);
  } catch (error) {
    next(error);
  }
}

export async function createNode(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = nodeCreateBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await nodeService.createNodeForUser(userId, parsed.data);
    if (!result.ok) {
      res.status(404).json({ error: "Mindmap not found" });
      return;
    }
    res.status(201).json(toNodeResponseBody(result.node));
  } catch (error) {
    next(error);
  }
}

export async function updateNode(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = nodeIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const bodyParsed = nodeUpdateBodySchema.safeParse(req.body);
  if (!bodyParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: bodyParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await nodeService.updateNodeForUser(userId, paramsParsed.data.id, bodyParsed.data);
    if (!result.ok) {
      if (result.reason === "mindmap_not_found") {
        res.status(404).json({ error: "Mindmap not found" });
        return;
      }
      res.status(404).json({ error: "Node not found" });
      return;
    }
    res.status(200).json(toNodeResponseBody(result.node));
  } catch (error) {
    next(error);
  }
}

export async function deleteNode(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = nodeIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const deleted = await nodeService.deleteNodeForUser(userId, paramsParsed.data.id);
    if (!deleted) {
      res.status(404).json({ error: "Node not found" });
      return;
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}
