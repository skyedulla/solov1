import { z } from "zod";

// --- Path params ----------------------------------------------------------------

export const objectiveIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export type ObjectiveIdParams = z.infer<typeof objectiveIdParamsSchema>;

// --- Request bodies ------------------------------------------------------------

export const objectiveCreateBodySchema = z.object({
  ideaId: z.string().uuid(),
  text: z.string().min(1).max(100_000),
});

export type ObjectiveCreateBody = z.infer<typeof objectiveCreateBodySchema>;

export const objectiveUpdateBodySchema = z.object({
  text: z.string().min(1).max(100_000),
});

export type ObjectiveUpdateBody = z.infer<typeof objectiveUpdateBodySchema>;

// --- API wire (Swift `ObjectiveModel` + snake_case JSON) ----------------------

export const objectiveResponseBodySchema = z.object({
  id: z.string().uuid(),
  idea_id: z.string().uuid(),
  text: z.string(),
  is_completed: z.boolean(),
});

export type ObjectiveResponseBody = z.infer<typeof objectiveResponseBodySchema>;
