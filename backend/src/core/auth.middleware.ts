import type { NextFunction, Request, Response } from "express";
import { createClient } from "@supabase/supabase-js";

function createSupabaseAuthClient() {
  const url = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error("SUPABASE_URL and SUPABASE_ANON_KEY must be set for auth middleware");
  }
  return createClient(url, anonKey);
}

function isConfigurationError(err: unknown): boolean {
  return err instanceof Error && /SUPABASE_URL|SUPABASE_ANON_KEY|must be set/i.test(err.message);
}

function isLikelyTransientNetworkError(err: unknown): boolean {
  if (!(err instanceof Error)) {
    return false;
  }
  const msg = `${err.name} ${err.message}`;
  return /fetch|network|ECONNREFUSED|ETIMEDOUT|ENOTFOUND|socket|aborted/i.test(msg);
}

/**
 * Requires `Authorization: Bearer <access_token>` (Supabase JWT). Sets **`req.authUser`** on success.
 * Use on every route that should only run for a logged-in user.
 */
export async function requireAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization;
  const token =
    typeof header === "string" && header.startsWith("Bearer ") ? header.slice("Bearer ".length).trim() : undefined;

  if (!token) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }

  try {
    const supabase = createSupabaseAuthClient();
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(token);

    if (error || !user) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    req.authUser = user;
    next();
  } catch (err) {
    console.error("[auth.middleware] requireAuth failed:", err);

    if (isConfigurationError(err)) {
      res.status(500).json({ error: "Auth configuration error" });
      return;
    }

    if (isLikelyTransientNetworkError(err)) {
      res.status(503).json({ error: "Auth service unavailable" });
      return;
    }

    res.status(500).json({ error: "Internal server error" });
  }
}
