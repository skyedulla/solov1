import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import { createNode, deleteNode, searchNodes, updateNode } from "../modules/nodes/node.controller";

export const nodeRoutes = Router();

nodeRoutes.use(requireAuth);
nodeRoutes.get("/", (req, res, next) => {
  void searchNodes(req, res, next);
});
nodeRoutes.post("/", (req, res, next) => {
  void createNode(req, res, next);
});
nodeRoutes.patch("/:id", (req, res, next) => {
  void updateNode(req, res, next);
});
/** Same handler as **`PATCH`** — fallback for environments that block **`PATCH`**. */
nodeRoutes.put("/:id", (req, res, next) => {
  void updateNode(req, res, next);
});
nodeRoutes.delete("/:id", (req, res, next) => {
  void deleteNode(req, res, next);
});
