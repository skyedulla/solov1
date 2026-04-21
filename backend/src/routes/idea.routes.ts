import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import { createNewIdea, listIdeas } from "../modules/ideas/idea.controller";

export const ideaRoutes = Router();

ideaRoutes.use(requireAuth);
ideaRoutes.get("/", (req, res, next) => {
  void listIdeas(req, res, next);
});
ideaRoutes.post("/", (req, res, next) => {
  void createNewIdea(req, res, next);
});
