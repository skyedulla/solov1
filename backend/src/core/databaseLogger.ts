import {
  PrismaClientInitializationError,
  PrismaClientKnownRequestError,
  PrismaClientRustPanicError,
  PrismaClientUnknownRequestError,
  PrismaClientValidationError,
} from "@prisma/client/runtime/library";

/**
 * Short human-readable descriptions for Prisma error codes.
 * @see https://www.prisma.io/docs/reference/api-reference/error-reference
 */
const PRISMA_CODE_DESCRIPTIONS: Record<string, string> = {
  P1000: "Authentication failed against the database server.",
  P1001: "Can't reach database server (host/port unreachable or refused).",
  P1002: "Database server was reached but timed out.",
  P1003: "Database does not exist on the server.",
  P1008: "Operations timed out after a period of time.",
  P1009: "Database already exists on the server.",
  P1010: "User denied access on the database (credentials or permissions).",
  P1011: "TLS / SSL connection error.",
  P1012: "Invalid value in configuration or connection string.",
  P1013: "Invalid database string provided.",
  P1014: "The underlying model for the field does not exist.",
  P1015: "Unsupported feature for this connector.",
  P1016: "Incorrect number of parameters in raw query.",
  P1017: "Server has closed the connection.",
  P2000: "Provided value is too long for the column type.",
  P2001: "Record searched in the where condition does not exist.",
  P2002: "Unique constraint failed (duplicate key).",
  P2003: "Foreign key constraint failed.",
  P2004: "A constraint failed on the database.",
  P2005: "Invalid value for field type.",
  P2006: "Invalid value provided.",
  P2007: "Data validation error.",
  P2010: "Raw query failed.",
  P2011: "Null constraint violation.",
  P2012: "Missing a required value.",
  P2013: "Missing an argument in a raw query.",
  P2014: "Violation of a required relation between models.",
  P2015: "Related record could not be found.",
  P2016: "Query interpretation error.",
  P2017: "Records for relation are not connected.",
  P2018: "Required connected records were not found.",
  P2019: "Input error.",
  P2020: "Value out of range for the type.",
  P2021: "Table does not exist in the current database.",
  P2022: "Column does not exist in the current database.",
  P2023: "Inconsistent column data.",
  P2024: "Timed out while fetching from the database.",
  P2025: "Record to update or delete was not found.",
  P2027: "Multiple errors occurred on the database.",
  P2030: "Fulltext search index not found.",
  P2033: "A number value in the query is out of range.",
  P2034: "Transaction failed due to a write conflict or deadlock.",
};

export function getPrismaCodeDescription(code: string | undefined): string {
  if (!code) {
    return "No Prisma error code available; see message below.";
  }
  return PRISMA_CODE_DESCRIPTIONS[code] ?? "See https://www.prisma.io/docs/reference/api-reference/error-reference";
}

/** Prisma sometimes omits `errorCode` on initialization errors — infer from text / embedded Pxxxx. */
function inferInitializationCode(message: string): string | undefined {
  const embedded = message.match(/\b(P\d{4})\b/);
  if (embedded) {
    return embedded[1];
  }
  if (message.includes("User was denied access")) {
    return "P1010";
  }
  if (message.includes("Can't reach database server") || message.includes("Connection refused")) {
    return "P1001";
  }
  if (message.includes("Server has closed the connection")) {
    return "P1017";
  }
  return undefined;
}

type PrismaClientError =
  | PrismaClientKnownRequestError
  | PrismaClientInitializationError
  | PrismaClientValidationError
  | PrismaClientUnknownRequestError
  | PrismaClientRustPanicError;

export function isPrismaError(error: unknown): error is PrismaClientError {
  return (
    error instanceof PrismaClientKnownRequestError ||
    error instanceof PrismaClientInitializationError ||
    error instanceof PrismaClientValidationError ||
    error instanceof PrismaClientUnknownRequestError ||
    error instanceof PrismaClientRustPanicError
  );
}

/**
 * Logs Prisma (database client) errors with code + description.
 * Call from **`prisma.ts`** query extension for queries through the shared client, from **any TypeScript file that uses another Prisma client or driver**, or from **`createApp`** only for non-Prisma paths (Prisma errors are already logged at the query boundary).
 * For HTTP-layer non-Prisma failures, use **`logApiError`** from **`apiLogger`**.
 */
export function logDatabaseError(error: unknown, context: string): void {
  if (!isPrismaError(error)) {
    return;
  }

  const lines: string[] = [`[database:${context}]`];

  if (error instanceof PrismaClientKnownRequestError) {
    lines.push(`  PrismaKnownRequest`);
    lines.push(`  Code: ${error.code}`);
    lines.push(`  Meaning: ${getPrismaCodeDescription(error.code)}`);
    lines.push(`  Message: ${error.message}`);
    if (error.meta && Object.keys(error.meta).length > 0) {
      lines.push(`  Meta: ${JSON.stringify(error.meta)}`);
    }
    console.error(lines.join("\n"));
    return;
  }

  if (error instanceof PrismaClientInitializationError) {
    const inferred = inferInitializationCode(error.message);
    const code = error.errorCode ?? inferred ?? "(no code)";
    lines.push(`  PrismaInitialization`);
    lines.push(`  Code: ${code}${error.errorCode ? "" : inferred ? " (inferred)" : ""}`);
    lines.push(`  Meaning: ${getPrismaCodeDescription(error.errorCode ?? inferred)}`);
    lines.push(`  Message: ${error.message}`);
    console.error(lines.join("\n"));
    return;
  }

  if (error instanceof PrismaClientValidationError) {
    lines.push(`  PrismaValidation`);
    lines.push(`  Message: ${error.message}`);
    console.error(lines.join("\n"));
    return;
  }

  if (error instanceof PrismaClientUnknownRequestError) {
    lines.push(`  PrismaUnknownRequest`);
    lines.push(`  Message: ${error.message}`);
    console.error(lines.join("\n"));
    return;
  }

  if (error instanceof PrismaClientRustPanicError) {
    lines.push(`  PrismaRustPanic`);
    lines.push(`  Message: ${error.message}`);
    console.error(lines.join("\n"));
    return;
  }
}
