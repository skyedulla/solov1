import type { NextFunction, Request, Response } from "express";

import { aiPromptBodySchema } from "./ai.schema";
import * as aiService from "./ai.service";

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
    const stream = await aiService.sendPromptStreamForUser(req.authUser!.id, parsed.data);
    if (!stream) {
      res.status(404).json({ error: "Idea or conversation not found" });
      return;
    }

    res.status(200);
    res.setHeader("Content-Type", "application/x-ndjson; charset=utf-8");
    res.setHeader("Cache-Control", "no-cache, no-transform");
    res.setHeader("Connection", "keep-alive");
    res.flushHeaders();

    for await (const chunk of stream) {
      if (req.aborted || res.writableEnded || res.destroyed) {
        break;
      }

      const payload = `${JSON.stringify(chunk)}\n`;
      res.write(payload);
    }

    if (!res.writableEnded && !res.destroyed) {
      res.end();
    }
  } catch (error) {
    next(error);
  }
}
