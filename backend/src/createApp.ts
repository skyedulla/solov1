import express, { type NextFunction, type Request, type Response } from "express";

import { apiAccessLoggingMiddleware, logApiError } from "./core/apiLogger";
import { isPrismaError } from "./core/databaseLogger";
import { aiRoutes } from "./routes/ai.routes";
import { mindmapConnectionRoutes } from "./routes/mindmap-connection.routes";
import { decisionMapRoutes } from "./routes/decision_map.routes";
import { ideaRoutes } from "./routes/idea.routes";
import { mindmapRoutes } from "./routes/mindmap.routes";
import { mindmapNodeRoutes } from "./routes/mindmap-node.routes";
import { objectiveRoutes } from "./routes/objective.routes";
import { storageRoutes } from "./routes/storage.routes";

/**
 * Builds the Express app (routes + JSON parser + error handler) without listening.
 * Used by **`index.ts`**.
 */
export function createApp(): express.Application {
  const app = express();
  app.use(express.json());
  app.use(apiAccessLoggingMiddleware());

  app.get("/health", (_req, res) => {
    res.status(200).json({ ok: true, service: "solo-api" });
  });

  app.use("/ai", aiRoutes);
  app.use("/ideas", ideaRoutes);
  app.use("/decision-maps", decisionMapRoutes);
  app.use("/mindmaps", mindmapRoutes);
  app.use("/mindmap-node", mindmapNodeRoutes);
  app.use("/mindmap-connection", mindmapConnectionRoutes);
  app.use("/objectives", objectiveRoutes);
  app.use("/storage", storageRoutes);

  app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
    const context = `${req.method} ${req.originalUrl}`;
    if (!isPrismaError(err)) {
      logApiError(err, context);
    }
    if (res.headersSent) {
      return;
    }
    res.status(500).json({ error: "Internal server error" });
  });

  return app;
}
