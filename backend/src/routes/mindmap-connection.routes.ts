import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import {
  createMindmapConnection,
  deleteMindmapConnection,
  listMindmapConnections,
  updateMindmapConnection,
} from "../modules/mindmap/mindmap-connection/mindmap-connection.controller";

export const mindmapConnectionRoutes = Router();

mindmapConnectionRoutes.use(requireAuth);
mindmapConnectionRoutes.get("/", (req, res, next) => {
  void listMindmapConnections(req, res, next);
});
mindmapConnectionRoutes.post("/", (req, res, next) => {
  void createMindmapConnection(req, res, next);
});
mindmapConnectionRoutes.patch("/:id", (req, res, next) => {
  void updateMindmapConnection(req, res, next);
});
/** Same handler as **`PATCH`** — fallback for environments that block **`PATCH`**. */
mindmapConnectionRoutes.put("/:id", (req, res, next) => {
  void updateMindmapConnection(req, res, next);
});
mindmapConnectionRoutes.delete("/:id", (req, res, next) => {
  void deleteMindmapConnection(req, res, next);
});
