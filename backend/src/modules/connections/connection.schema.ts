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

export const connectionAnchorSchema = z.enum(["top", "right", "left", "bottom"]);

export type ConnectionAnchor = z.infer<typeof connectionAnchorSchema>;

export const listConnectionsQuerySchema = z.object({
  mindmap_id: z.preprocess(
    (v) => firstQueryString(v),
    z.string().uuid(),
  ),
});

export type ListConnectionsQuery = z.infer<typeof listConnectionsQuerySchema>;

/**
 * **`POST /connections`** — camelCase JSON. **`targetNodeId`** / **`targetAnchor`** optional together (open-ended link).
 */
export const connectionCreateBodySchema = z
  .object({
    mindmapId: z.string().uuid(),
    sourceNodeId: z.string().uuid(),
    sourceAnchor: connectionAnchorSchema,
    targetNodeId: z.string().uuid().optional(),
    targetAnchor: connectionAnchorSchema.optional(),
  })
  .superRefine((data, ctx) => {
    const hasTargetId = data.targetNodeId !== undefined;
    const hasTargetAnchor = data.targetAnchor !== undefined;
    if (hasTargetId !== hasTargetAnchor) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "targetNodeId and targetAnchor must both be set or both omitted",
        path: hasTargetId ? ["targetAnchor"] : ["targetNodeId"],
      });
    }
  });

export type ConnectionCreateBody = z.infer<typeof connectionCreateBodySchema>;

export const connectionIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export type ConnectionIdParams = z.infer<typeof connectionIdParamsSchema>;

/**
 * **`PATCH /connections/:id`** — omit to leave unchanged; **`targetNodeId`** / **`targetAnchor`**: pass **`null`** to clear.
 */
export const connectionUpdateBodySchema = z.object({
  mindmapId: z.string().uuid().optional(),
  sourceNodeId: z.string().uuid().optional(),
  targetNodeId: z.union([z.string().uuid(), z.null()]).optional(),
  sourceAnchor: connectionAnchorSchema.optional(),
  targetAnchor: z.union([connectionAnchorSchema, z.null()]).optional(),
});

export type ConnectionUpdateBody = z.infer<typeof connectionUpdateBodySchema>;

/** Wire JSON aligned with Swift **`ConnectionModel`** (snake_case). */
export const connectionResponseBodySchema = z.object({
  id: z.string().uuid(),
  mindmap_id: z.string().uuid(),
  source_node_id: z.string().uuid(),
  target_node_id: z.string().uuid().nullable(),
  source_anchor: connectionAnchorSchema,
  target_anchor: connectionAnchorSchema.nullable(),
});

export type ConnectionResponseBody = z.infer<typeof connectionResponseBodySchema>;
