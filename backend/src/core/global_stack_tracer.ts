/**
 * Stack-trace helpers for debugging:
 *
 * - **`withStackTrace` / `wrapAsyncWithStackTrace`** — wrap workflow calls (e.g. in tests) so failures log **`error.stack`** + **`cause`** to stderr before rethrowing.
 * - **`installGlobalStackTracer`** — optional process handlers for uncaught errors (CLI scripts).
 */

export type GlobalStackTracerOptions = {
  /** Default **`true`**. After logging, exit with code 1. */
  exitOnUncaughtException?: boolean;
  /** Default **`false`** — enable for strict CLI scripts if you want immediate exit. */
  exitOnUnhandledRejection?: boolean;
};

let installed = false;

/** Builds a string suitable for logs: **`stack`** when present, else message / `String(error)`**, plus **`cause`** recursively. */
export function formatErrorStack(error: unknown): string {
  const lines: string[] = [];

  let current: unknown = error;
  let depth = 0;
  const maxDepth = 8;

  while (current !== undefined && current !== null && depth < maxDepth) {
    if (depth > 0) {
      lines.push("Caused by:");
    }
    if (current instanceof Error) {
      lines.push(current.stack ?? `${current.name}: ${current.message}`);
      current = current.cause;
    } else {
      lines.push(String(current));
      break;
    }
    depth += 1;
  }

  return lines.join("\n");
}

/** Writes **`label`** and **`formatErrorStack(error)`** to **stderr**. */
export function logErrorWithStack(label: string, error: unknown): void {
  console.error(`[global_stack_tracer:${label}]`);
  console.error(formatErrorStack(error));
}

/**
 * Runs **`fn()`**; on failure logs a full stack trace under **`label`**, then rethrows.
 * Use in tests or one-off scripts when exercising a workflow.
 */
export async function withStackTrace<T>(label: string, fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (error: unknown) {
    logErrorWithStack(label, error);
    throw error;
  }
}

/**
 * Synchronous **`withStackTrace`**.
 */
export function withStackTraceSync<T>(label: string, fn: () => T): T {
  try {
    return fn();
  } catch (error: unknown) {
    logErrorWithStack(label, error);
    throw error;
  }
}

/**
 * Returns a function that invokes **`fn`** with the same arguments; on rejection or throw,
 * logs stacks under **`label`** (append **`#`** + invocation index when **`suffixInvocations`** is true).
 */
export function wrapAsyncWithStackTrace<A extends unknown[], R>(
  label: string,
  fn: (...args: A) => Promise<R>,
  options?: { suffixInvocations?: boolean },
): (...args: A) => Promise<R> {
  let invocation = 0;
  const suffix = options?.suffixInvocations ?? false;

  return async (...args: A): Promise<R> => {
    const traceLabel = suffix ? `${label}#${(invocation += 1)}` : label;
    return withStackTrace(traceLabel, () => fn(...args));
  };
}

/**
 * Synchronous **`wrapAsyncWithStackTrace`**.
 */
export function wrapSyncWithStackTrace<A extends unknown[], R>(
  label: string,
  fn: (...args: A) => R,
  options?: { suffixInvocations?: boolean },
): (...args: A) => R {
  let invocation = 0;
  const suffix = options?.suffixInvocations ?? false;

  return (...args: A): R => {
    const traceLabel = suffix ? `${label}#${(invocation += 1)}` : label;
    return withStackTraceSync(traceLabel, () => fn(...args));
  };
}

/**
 * Registers **`uncaughtException`** and **`unhandledRejection`** handlers once.
 * Safe to call twice (second call is a no-op).
 */
export function installGlobalStackTracer(options?: GlobalStackTracerOptions): void {
  if (installed) {
    return;
  }
  installed = true;

  const exitOnUncaught = options?.exitOnUncaughtException ?? true;
  const exitOnUnhandled = options?.exitOnUnhandledRejection ?? false;

  process.on("uncaughtException", (err, origin) => {
    console.error(`[global_stack_tracer:uncaughtException origin=${origin}]`);
    console.error(formatErrorStack(err));
    if (exitOnUncaught) {
      process.exit(1);
    }
  });

  process.on("unhandledRejection", (reason) => {
    console.error("[global_stack_tracer:unhandledRejection]");
    console.error(formatErrorStack(reason));
    if (exitOnUnhandled) {
      process.exit(1);
    }
  });
}
