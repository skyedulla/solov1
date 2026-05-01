import { Router } from "express";

import { requireAuth } from "../core/auth.middleware";
import {
  addObjective,
  completeObjective,
  modifyObjective,
  removeObjective,
} from "../modules/objectives/objective.controller";

export const objectiveRoutes = Router();

objectiveRoutes.use(requireAuth);
objectiveRoutes.post("/", (req, res, next) => {
  void addObjective(req, res, next);
});
objectiveRoutes.patch("/:id", (req, res, next) => {
  void modifyObjective(req, res, next);
});
objectiveRoutes.post("/:id/complete", (req, res, next) => {
  void completeObjective(req, res, next);
});
objectiveRoutes.delete("/:id", (req, res, next) => {
  void removeObjective(req, res, next);
});
