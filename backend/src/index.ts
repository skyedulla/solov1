import path from "node:path";

import { config as loadEnv } from "dotenv";
import express, { type NextFunction, type Request, type Response } from "express";

import { logApiError } from "./core/apiLogger";
import { isPrismaError, logDatabaseError } from "./core/databaseLogger";
import { ideaRoutes } from "./routes/idea.routes";

loadEnv({ path: path.resolve(__dirname, "../../.env") });

// Before using persisted routes (e.g. `GET /ideas`), apply migrations: `cd backend && npx prisma migrate deploy` (or `npm run db:migrate` in development).

const app = express();
app.use(express.json());

/** Confirms this process is the SOLO API (use before debugging 404s from another server on the same port). */
app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true, service: "solo-api" });
});

/** Logged-in API surface — each router applies **`requireAuth`** (or equivalent) for protected resources. */
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

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`API listening on ${port}`);
});
