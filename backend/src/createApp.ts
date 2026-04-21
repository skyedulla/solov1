import express, { type NextFunction, type Request, type Response } from "express";

import { logApiError } from "./core/apiLogger";
import { isPrismaError, logDatabaseError } from "./core/databaseLogger";
import { ideaRoutes } from "./routes/idea.routes";

/**
 * Builds the Express app (routes + JSON parser + error handler) without listening.
 * Used by **`index.ts`**.
 */
export function createApp(): express.Application {
  const app = express();
  app.use(express.json());

  app.get("/health", (_req, res) => {
    res.status(200).json({ ok: true, service: "solo-api" });
  });

  app.use("/ideas", ideaRoutes);

  app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
    const context = `${req.method} ${req.originalUrl}`;
    if (isPrismaError(err)) {
      logDatabaseError(err, context);
    } else {
      logApiError(err, context);
    }
    if (res.headersSent) {
      return;
    }
    res.status(500).json({ error: "Internal server error" });
  });

  return app;
}
