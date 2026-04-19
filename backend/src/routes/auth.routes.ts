import { Router } from "express";

import { authController } from "../modules/auth/auth.controller";

export const authRoutes = Router();

authRoutes.post("/login", authController.login);
authRoutes.post("/signup", authController.signUp);
