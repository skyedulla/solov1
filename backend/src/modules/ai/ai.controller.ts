import type { NextFunction, Request, Response } from "express";

import { aiPromptBodySchema } from "./ai.schema";

/**
 * **`POST /ai/prompt`**: validate body with Zod (same pattern as other module controllers); auth is enforced on **`aiRoutes`** via **`requireAuth`**.
 */
export async function postAiPrompt(req: Request, res: Response, next: NextFunction): Promise<void> {
  const parsed = aiPromptBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Validation failed",
      details: parsed.error.flatten(),
    });
    return;
  }

  try {
    res.status(501).json({ error: "Not implemented" });
  } catch (error) {
    next(error);
  }
}
