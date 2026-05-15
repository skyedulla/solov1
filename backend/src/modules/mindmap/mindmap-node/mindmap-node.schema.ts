import { z } from "zod";

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

export const searchMindmapNodesQuerySchema = z.object({
  mindmap_id: z.preprocess(
    (v) => firstQueryString(v),
    z.string().uuid(),
  ),
  q: z.preprocess(
    (v) => firstQueryString(v),
    z
      .string()
      .max(500)
      .optional()
      .transform((value) => (value === undefined ? "" : value.trim())),
  ),
});

export type SearchMindmapNodesQuery = z.infer<typeof searchMindmapNodesQuerySchema>;

const mindmapPositionSchema = z.object({
  x: z.number().int(),
  y: z.number().int(),
});

const mindmapDimensionsSchema = z.object({
  height: z.number().int().min(0),
  width: z.number().int().min(0),
});

/**
 * **`POST /mindmap-node`** (**mindmap-node** create) — camelCase JSON; nested **`position`** / **`dimensions`** match Swift **`NodeModel`**.
 */
export const mindmapNodeCreateBodySchema = z.object({
  mindmapId: z.string().uuid(),
  parentNodeId: z.string().uuid().optional(),
  position: mindmapPositionSchema,
  text: z.string().max(100_000).optional().default(""),
  dimensions: mindmapDimensionsSchema,
});

export type MindmapNodeCreateBody = z.infer<typeof mindmapNodeCreateBodySchema>;

export const mindmapNodeIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export type MindmapNodeIdParams = z.infer<typeof mindmapNodeIdParamsSchema>;

/**
 * **`PATCH /mindmap-node/:id`** (**mindmap-node** update) — omit a field to leave it unchanged (**`parentNodeId`**: pass **`null`** to clear).
 */
export const mindmapNodeUpdateBodySchema = z.object({
  mindmapId: z.string().uuid().optional(),
  parentNodeId: z.union([z.string().uuid(), z.null()]).optional(),
  position: mindmapPositionSchema.optional(),
  text: z.string().max(100_000).optional(),
  dimensions: mindmapDimensionsSchema.optional(),
});

export type MindmapNodeUpdateBody = z.infer<typeof mindmapNodeUpdateBodySchema>;

/** Wire JSON for one **mindmap-node** (`NodeModel`) + snake_case keys. */
export const mindmapNodeResponseBodySchema = z.object({
  id: z.string().uuid(),
  mindmap_id: z.string().uuid(),
  parent_node_id: z.string().uuid().nullable(),
  position: mindmapPositionSchema,
  text: z.string(),
  dimensions: mindmapDimensionsSchema,
});

export type MindmapNodeResponseBody = z.infer<typeof mindmapNodeResponseBodySchema>;
