import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import { createNewIdea, deleteIdea, listIdeas, updateIdea } from "../modules/ideas/idea.controller";

export const ideaRoutes = Router();

ideaRoutes.use(requireAuth);
ideaRoutes.get("/", (req, res, next) => {
  void listIdeas(req, res, next);
});
ideaRoutes.post("/", (req, res, next) => {
  void createNewIdea(req, res, next);
});
ideaRoutes.patch("/:id", (req, res, next) => {
  void updateIdea(req, res, next);
});
/** Same handler as PATCH — some proxies or tools block PATCH; PUT is a supported fallback. */
ideaRoutes.put("/:id", (req, res, next) => {
  void updateIdea(req, res, next);
});
ideaRoutes.delete("/:id", (req, res, next) => {
  void deleteIdea(req, res, next);
});
