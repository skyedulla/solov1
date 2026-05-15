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

export const mindmapConnectionAnchorSchema = z.enum(["top", "right", "left", "bottom"]);

export type MindmapConnectionAnchorWire = z.infer<typeof mindmapConnectionAnchorSchema>;

export const listMindmapConnectionsQuerySchema = z.object({
  mindmap_id: z.preprocess(
    (v) => firstQueryString(v),
    z.string().uuid(),
  ),
});

export type ListMindmapConnectionsQuery = z.infer<typeof listMindmapConnectionsQuerySchema>;

/**
 * **`POST /mindmap-connection`** (**mindmap-connection** create) — camelCase JSON. **`targetNodeId`** / **`targetAnchor`** optional together (open-ended link).
 */
export const mindmapConnectionCreateBodySchema = z
  .object({
    mindmapId: z.string().uuid(),
    sourceNodeId: z.string().uuid(),
    sourceAnchor: mindmapConnectionAnchorSchema,
    targetNodeId: z.string().uuid().optional(),
    targetAnchor: mindmapConnectionAnchorSchema.optional(),
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

export type MindmapConnectionCreateBody = z.infer<typeof mindmapConnectionCreateBodySchema>;

export const mindmapConnectionIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export type MindmapConnectionIdParams = z.infer<typeof mindmapConnectionIdParamsSchema>;

/**
 * **`PATCH /mindmap-connection/:id`** (**mindmap-connection** update) — omit to leave unchanged; **`targetNodeId`** / **`targetAnchor`**: pass **`null`** to clear.
 */
export const mindmapConnectionUpdateBodySchema = z.object({
  mindmapId: z.string().uuid().optional(),
  sourceNodeId: z.string().uuid().optional(),
  targetNodeId: z.union([z.string().uuid(), z.null()]).optional(),
  sourceAnchor: mindmapConnectionAnchorSchema.optional(),
  targetAnchor: z.union([mindmapConnectionAnchorSchema, z.null()]).optional(),
});

export type MindmapConnectionUpdateBody = z.infer<typeof mindmapConnectionUpdateBodySchema>;

/** Wire JSON for one **mindmap-connection** (`ConnectionModel`) (snake_case). */
export const mindmapConnectionResponseBodySchema = z.object({
  id: z.string().uuid(),
  mindmap_id: z.string().uuid(),
  source_node_id: z.string().uuid(),
  target_node_id: z.string().uuid().nullable(),
  source_anchor: mindmapConnectionAnchorSchema,
  target_anchor: mindmapConnectionAnchorSchema.nullable(),
});

export type MindmapConnectionResponseBody = z.infer<typeof mindmapConnectionResponseBodySchema>;
