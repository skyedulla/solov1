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

export const searchNodesQuerySchema = z.object({
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

export type SearchNodesQuery = z.infer<typeof searchNodesQuerySchema>;

const positionSchema = z.object({
  x: z.number().int(),
  y: z.number().int(),
});

const dimensionsSchema = z.object({
  height: z.number().int().min(0),
  width: z.number().int().min(0),
});

/**
 * **`POST /nodes`** JSON body — camelCase; nested **`position`** / **`dimensions`** match Swift **`NodeModel`**.
 */
export const nodeCreateBodySchema = z.object({
  ideaId: z.string().uuid(),
  mindmapId: z.string().uuid(),
  parentNodeId: z.string().uuid().optional(),
  position: positionSchema,
  text: z.string().max(100_000).optional().default(""),
  dimensions: dimensionsSchema,
});

export type NodeCreateBody = z.infer<typeof nodeCreateBodySchema>;

export const nodeIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export type NodeIdParams = z.infer<typeof nodeIdParamsSchema>;

/**
 * **`PATCH /nodes/:id`** — omit a field to leave it unchanged (**`parentNodeId`**: pass **`null`** to clear).
 */
export const nodeUpdateBodySchema = z.object({
  ideaId: z.string().uuid().optional(),
  mindmapId: z.string().uuid().optional(),
  parentNodeId: z.union([z.string().uuid(), z.null()]).optional(),
  position: positionSchema.optional(),
  text: z.string().max(100_000).optional(),
  dimensions: dimensionsSchema.optional(),
});

export type NodeUpdateBody = z.infer<typeof nodeUpdateBodySchema>;

/** Wire JSON aligned with Swift **`NodeModel`** + snake_case keys. */
export const nodeResponseBodySchema = z.object({
  id: z.string().uuid(),
  idea_id: z.string().uuid(),
  mindmap_id: z.string().uuid(),
  parent_node_id: z.string().uuid().nullable(),
  position: positionSchema,
  text: z.string(),
  dimensions: dimensionsSchema,
});

export type NodeResponseBody = z.infer<typeof nodeResponseBodySchema>;
