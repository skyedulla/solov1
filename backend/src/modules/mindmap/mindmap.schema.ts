import { z } from "zod";

import { connectionResponseBodySchema } from "../connection/connection.schema";
import { nodeResponseBodySchema } from "../nodes/node.schema";

/** Express `req.query` values may be `string | string[] | undefined`. */
function firstQueryString(value: unknown): string | undefined {
  if (typeof value === "string") {
    return value;
  }
  if (Array.isArray(value) && typeof value[0] === "string") {
    return value[0];
  }
  return undefined;
}

/** **`POST /mindmaps`** — camelCase JSON. */
export const mindmapCreateBodySchema = z.object({
  ideaId: z.string().uuid(),
  title: z.string().optional(),
  summary: z.string().optional(),
});

export type MindmapCreateBody = z.infer<typeof mindmapCreateBodySchema>;

/** Wire JSON for **`POST /mindmaps`** (Swift uses **`id`** as **`mindmapId`** on nodes / connections). */
export const mindmapResponseBodySchema = z.object({
  id: z.string().uuid(),
  idea_id: z.string().uuid(),
  title: z.string(),
  summary: z.string(),
  created_at: z.string().datetime(),
  last_updated_at: z.string().datetime(),
});

export type MindmapResponseBody = z.infer<typeof mindmapResponseBodySchema>;

export const mindmapIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export type MindmapIdParams = z.infer<typeof mindmapIdParamsSchema>;

/** Query for **`GET`** / **`DELETE /mindmaps/:id`** — **`idea_id`** must match the stored mind map for the authenticated user. */
export const loadMindmapQuerySchema = z.object({
  idea_id: z.preprocess(
    (v) => firstQueryString(v),
    z.string().uuid(),
  ),
});

export type LoadMindmapQuery = z.infer<typeof loadMindmapQuerySchema>;

/** Query for **`GET /mindmaps`** (list maps for an idea) — same shape as **`loadMindmapQuerySchema`**. */
export const listMindmapsQuerySchema = loadMindmapQuerySchema;

export type ListMindmapsQuery = z.infer<typeof listMindmapsQuerySchema>;

const mindmapLastTransformSchema = z.object({
  scale: z.number(),
  translate_x: z.number(),
  translate_y: z.number(),
});

/** Full document for **`GET /mindmaps/:id`** — aligned with Swift **`MindmapModel`** wire JSON. */
export const mindmapLoadDocumentResponseSchema = z.object({
  id: z.string().uuid(),
  idea_id: z.string().uuid(),
  nodes: z.array(nodeResponseBodySchema),
  connections: z.array(connectionResponseBodySchema),
  last_transform: mindmapLastTransformSchema,
});

export type MindmapLoadDocumentResponse = z.infer<typeof mindmapLoadDocumentResponseSchema>;
