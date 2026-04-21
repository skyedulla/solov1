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
