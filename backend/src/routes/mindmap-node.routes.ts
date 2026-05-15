import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import {
  createMindmapNode,
  deleteMindmapNode,
  searchMindmapNodes,
  updateMindmapNode,
} from "../modules/mindmap/mindmap-node/mindmap-node.controller";

export const mindmapNodeRoutes = Router();

mindmapNodeRoutes.use(requireAuth);
mindmapNodeRoutes.get("/", (req, res, next) => {
  void searchMindmapNodes(req, res, next);
});
mindmapNodeRoutes.post("/", (req, res, next) => {
  void createMindmapNode(req, res, next);
});
mindmapNodeRoutes.patch("/:id", (req, res, next) => {
  void updateMindmapNode(req, res, next);
});
/** Same handler as **`PATCH`** — fallback for environments that block **`PATCH`**. */
mindmapNodeRoutes.put("/:id", (req, res, next) => {
  void updateMindmapNode(req, res, next);
});
mindmapNodeRoutes.delete("/:id", (req, res, next) => {
  void deleteMindmapNode(req, res, next);
});
