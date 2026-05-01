import type { NextFunction, Request, RequestHandler, Response } from "express";

/**
 * Logs each completed HTTP request (method, path, status, duration).
 * Use **`logApiError`** for failures; use **`logDatabaseError`** for Prisma / DB client failures.
 * Use **`logSystemError`** from **`systemLogger`** for process/system-level failures outside request handling.
 */
export function logApiAccess(method: string, path: string, statusCode: number, durationMs: number): void {
  console.log(`[api] ${method} ${path} ${statusCode} ${durationMs}ms`);
}

/** Express middleware: logs **`logApiAccess`** on **`res` `'finish'`** (after status is set). */
export function apiAccessLoggingMiddleware(): RequestHandler {
  return (req: Request, res: Response, next: NextFunction) => {
    const start = performance.now();
    res.on("finish", () => {
      const durationMs = Math.round(performance.now() - start);
      logApiAccess(req.method, req.originalUrl, res.statusCode, durationMs);
    });
    next();
  };
}

/**
 * Logs non-database errors for the HTTP API (Express routes, middleware, etc.).
 * Use **`logDatabaseError`** from **`databaseLogger`** for Prisma / DB client failures.
 * Use **`logSystemError`** from **`systemLogger`** for process/system-level failures outside request handling.
 */
export function logApiError(error: unknown, context: string): void {
  const lines: string[] = [`[api:${context}]`];

  if (error instanceof Error) {
    lines.push(`  Error (${error.name})`);
    lines.push(`  Message: ${error.message}`);
    console.error(lines.join("\n"));
    return;
  }

  lines.push(`  Unknown: ${String(error)}`);
  console.error(lines.join("\n"));
}
