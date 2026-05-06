import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import { postAiPrompt } from "../modules/ai/ai.controller";

export const aiRoutes = Router();

aiRoutes.use(requireAuth);

aiRoutes.post("/prompt", (req, res, next) => {
  void postAiPrompt(req, res, next);
});
