/**
 * Logs process/system-level failures (startup, shutdown, timers, uncaught handlers, etc.).
 * Use **`logApiError`** from **`apiLogger`** for Express middleware/route errors tied to a request.
 * Use **`logDatabaseError`** from **`databaseLogger`** for Prisma / database client failures.
 */
export function logSystemError(error: unknown, context: string): void {
  const lines: string[] = [`[system:${context}]`];

  if (error instanceof Error) {
    lines.push(`  Error (${error.name})`);
    lines.push(`  Message: ${error.message}`);
    if (error.stack) {
      lines.push(`  Stack: ${error.stack}`);
    }
    console.error(lines.join("\n"));
    return;
  }

  lines.push(`  Unknown: ${String(error)}`);
  console.error(lines.join("\n"));
}

/** Convenience namespace; delegates to **`logSystemError`**. */
export const SystemLogger = {
  error: logSystemError,
} as const;
