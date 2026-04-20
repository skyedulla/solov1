import { z } from "zod";

// --- Query (list / search) -------------------------------------------------

/** API `sort` query values — matches Swift `SortByConstants` `value` entries. */
export const ideaSortBySchema = z.enum(["title_asc", "created_desc", "created_asc", "updated_desc"]);

export type IdeaSortBy = z.infer<typeof ideaSortBySchema>;

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

export const listIdeasQuerySchema = z.object({
  sort: z.preprocess(
    (v) => firstQueryString(v),
    ideaSortBySchema.optional().default("created_desc"),
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

export type ListIdeasQuery = z.infer<typeof listIdeasQuerySchema>;

// --- Request bodies (future POST/PATCH) -------------------------------------

/**
 * User-editable fields — maps to Prisma `Idea` columns
 * `title`, `description`, `is_published`, `target_user`, `purpose`.
 * Use camelCase for JSON request bodies to this API.
 */
export const ideaCoreSchema = z.object({
  title: z.string().min(1).max(10_000),
  description: z.string().max(100_000).default(""),
  isPublished: z.boolean().default(false),
  targetUser: z.string().min(1).max(2000),
  purpose: z.string().min(1).max(20_000),
});

export type IdeaCore = z.infer<typeof ideaCoreSchema>;

/** Request body for creating an idea (same fields as `ideaCoreSchema`). */
export const ideaCreateBodySchema = ideaCoreSchema;
export type IdeaCreateBody = z.infer<typeof ideaCreateBodySchema>;

// --- API wire format (Swift `IdeaModel` + snake_case JSON) ------------------

/**
 * JSON object returned to the client — keys match Swift `CodingKeys` via `convertFromSnakeCase`
 * (`isPublished` → `is_published`, `lastUpdatedAt` → `last_updated_at`, etc.).
 * Use **`parse`** / **`safeParse`** on outbound payloads so responses stay aligned with this contract.
 */
export const ideaResponseBodySchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  description: z.string(),
  is_published: z.boolean(),
  created_at: z.string().datetime(),
  last_updated_at: z.string().datetime(),
  target_user: z.string(),
  purpose: z.string(),
});

export type IdeaResponseBody = z.infer<typeof ideaResponseBodySchema>;
