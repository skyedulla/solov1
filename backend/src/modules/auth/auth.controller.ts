import type { NextFunction, Request, Response } from "express";
import type { ZodError } from "zod";

import { authModelSchema, loginSchema } from "./auth.schema";
import { authService } from "./auth.service";

function sendValidationError(res: Response, zodError: ZodError): void {
  res.status(400).json({
    error: "Validation failed",
    details: zodError.flatten(),
  });
}

/**
 * HTTP: parse `req.body` with Zod, call service, map results to status + JSON.
 * No hashing — hashing stays in the service.
 */
export const authController = {
  login: async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parsed = loginSchema.safeParse(req.body);
      if (!parsed.success) {
        sendValidationError(res, parsed.error);
        return;
      }

      const result = await authService.login(parsed.data);

      if (!result.ok) {
        res.status(401).json({ error: "Invalid email or password" });
        return;
      }

      res.status(200).json({ user: result.user });
    } catch (err) {
      next(err);
    }
  },

  signUp: async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parsed = authModelSchema.safeParse(req.body);
      if (!parsed.success) {
        sendValidationError(res, parsed.error);
        return;
      }

      const result = await authService.signUp(parsed.data);

      if (!result.ok) {
        res.status(409).json({ error: "An account with this email already exists" });
        return;
      }

      res.status(201).json({ user: result.user });
    } catch (err) {
      next(err);
    }
  },
};
