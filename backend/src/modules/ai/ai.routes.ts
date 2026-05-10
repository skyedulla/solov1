import { Router } from "express";

import { requireAuth } from "../../core/auth.middleware";
import { postAiPrompt } from "./ai.controller";

export const aiModuleRoutes = Router();

aiModuleRoutes.use(requireAuth);

aiModuleRoutes.post("/prompt", (req, res, next) => {
  void postAiPrompt(req, res, next);
});

