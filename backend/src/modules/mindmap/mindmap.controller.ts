import type { Mindmap, MindmapConnection, MindmapNode } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import {
  connectionResponseBodySchema,
  type ConnectionResponseBody,
} from "../connections/connection.schema";
import {
  nodeResponseBodySchema,
  type NodeResponseBody,
} from "../nodes/node.schema";
import {
  listMindmapsQuerySchema,
  loadMindmapQuerySchema,
  mindmapCreateBodySchema,
  mindmapGenerateSummaryResponseSchema,
  mindmapIdParamsSchema,
  mindmapLoadDocumentResponseSchema,
  mindmapResponseBodySchema,
  type MindmapResponseBody,
} from "./mindmap.schema";
import * as mindmapService from "./mindmap.service";

function toMindmapResponseBody(row: Mindmap): MindmapResponseBody {
  return mindmapResponseBodySchema.parse({
    id: row.id,
    idea_id: row.ideaId,
    title: row.title,
    summary: row.summary,
    created_at: row.createdAt.toISOString(),
    last_updated_at: row.updatedAt.toISOString(),
  });
}

function toNodeResponseBody(row: MindmapNode): NodeResponseBody {
  return nodeResponseBodySchema.parse({
    id: row.id,
    mindmap_id: row.mindmapId,
    parent_node_id: row.parentNodeId,
    position: { x: row.positionX, y: row.positionY },
    text: row.text,
    dimensions: { height: row.height, width: row.width },
  });
}

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

export async function createMindmap(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = mindmapCreateBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const row = await mindmapService.createMindmapForUser(userId, parsed.data);
    res.status(201).json(toMindmapResponseBody(row));
  } catch (error) {
    next(error);
  }
}

export async function listMindmaps(req: Request, res: Response, next: NextFunction): Promise<void> {
  const queryParsed = listMindmapsQuerySchema.safeParse(req.query);
  if (!queryParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: queryParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const rows = await mindmapService.listMindmapsForUser(userId, queryParsed.data);
    const body: MindmapResponseBody[] = rows.map(toMindmapResponseBody);
    res.status(200).json(body);
  } catch (error) {
    next(error);
  }
}

export async function generateMindmapSummary(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = mindmapIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const queryParsed = loadMindmapQuerySchema.safeParse(req.query);
  if (!queryParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: queryParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const result = await mindmapService.generateMindmapSummaryForUser(
      userId,
      paramsParsed.data.id,
      queryParsed.data.idea_id,
    );
    if (!result.ok) {
      if (result.kind === "not_found") {
        res.status(404).json({ error: "Mindmap not found" });
        return;
      }
      res.status(503).json({ error: result.message });
      return;
    }

    const body = mindmapGenerateSummaryResponseSchema.parse({ summary: result.summary });
    res.status(200).json(body);
  } catch (error) {
    next(error);
  }
}

export async function loadMindmap(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = mindmapIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const queryParsed = loadMindmapQuerySchema.safeParse(req.query);
  if (!queryParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: queryParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const doc = await mindmapService.loadMindmapDocumentForUser(
      userId,
      paramsParsed.data.id,
      queryParsed.data.idea_id,
    );
    if (!doc) {
      res.status(404).json({ error: "Mindmap not found" });
      return;
    }

    const body = mindmapLoadDocumentResponseSchema.parse({
      id: doc.id,
      idea_id: doc.ideaId,
      title: doc.title,
      nodes: doc.nodes.map(toNodeResponseBody),
      connections: doc.connections.map(toConnectionResponseBody),
      last_transform: { scale: 1, translate_x: 0, translate_y: 0 },
    });

    res.status(200).json(body);
  } catch (error) {
    next(error);
  }
}

export async function deleteMindmap(req: Request, res: Response, next: NextFunction): Promise<void> {
  const paramsParsed = mindmapIdParamsSchema.safeParse(req.params);
  if (!paramsParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: paramsParsed.error.flatten(),
    });
    return;
  }

  const queryParsed = loadMindmapQuerySchema.safeParse(req.query);
  if (!queryParsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: queryParsed.error.flatten(),
    });
    return;
  }

  const userId = req.authUser!.id;

  try {
    const deleted = await mindmapService.deleteMindmapForUser(
      userId,
      paramsParsed.data.id,
      queryParsed.data.idea_id,
    );
    if (!deleted) {
      res.status(404).json({ error: "Mindmap not found" });
      return;
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}
