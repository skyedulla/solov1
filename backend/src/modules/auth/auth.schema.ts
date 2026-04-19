import { z } from "zod";

/**
 * Matches Swift `AuthModel` (firstName, lastName, email, password).
 */
export const authModelSchema = z.object({
  firstName: z.string().min(1).max(100),
  lastName: z.string().min(1).max(100),
  email: z.string().email().transform((s) => s.trim().toLowerCase()),
  password: z.string().min(8).max(256),
});

export type AuthModel = z.infer<typeof authModelSchema>;

/** Login body — email + password only. */
export const loginSchema = z.object({
  email: z.string().email().transform((s) => s.trim().toLowerCase()),
  password: z.string().min(1).max(256),
});

export type LoginInput = z.infer<typeof loginSchema>;

export type SignUpInput = AuthModel;
