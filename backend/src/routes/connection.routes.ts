import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import {
  createConnection,
  deleteConnection,
  listConnections,
  updateConnection,
} from "../modules/connections/connection.controller";

export const connectionRoutes = Router();

connectionRoutes.use(requireAuth);
connectionRoutes.get("/", (req, res, next) => {
  void listConnections(req, res, next);
});
connectionRoutes.post("/", (req, res, next) => {
  void createConnection(req, res, next);
});
connectionRoutes.patch("/:id", (req, res, next) => {
  void updateConnection(req, res, next);
});
/** Same handler as **`PATCH`** — fallback for environments that block **`PATCH`**. */
connectionRoutes.put("/:id", (req, res, next) => {
  void updateConnection(req, res, next);
});
connectionRoutes.delete("/:id", (req, res, next) => {
  void deleteConnection(req, res, next);
});
