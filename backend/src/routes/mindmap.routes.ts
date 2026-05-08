import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import {
  createMindmap,
  deleteMindmap,
  generateMindmapSummary,
  listMindmaps,
  loadMindmap,
} from "../modules/mindmap/mindmap.controller";

export const mindmapRoutes = Router();

mindmapRoutes.use(requireAuth);
mindmapRoutes.post("/", (req, res, next) => {
  void createMindmap(req, res, next);
});
mindmapRoutes.get("/", (req, res, next) => {
  void listMindmaps(req, res, next);
});
mindmapRoutes.post("/:id/generate-summary", (req, res, next) => {
  void generateMindmapSummary(req, res, next);
});
mindmapRoutes.get("/:id", (req, res, next) => {
  void loadMindmap(req, res, next);
});
mindmapRoutes.delete("/:id", (req, res, next) => {
  void deleteMindmap(req, res, next);
});
