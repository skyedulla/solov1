import type { User } from "@supabase/supabase-js";

declare global {
  namespace Express {
    interface Request {
      /** Set by **`requireAuth`** after a valid Supabase access token is verified. */
      authUser?: User;
    }
  }
}

export {};
