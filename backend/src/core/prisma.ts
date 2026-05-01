import { PrismaClient } from "@prisma/client";
import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";

import { logDatabaseError } from "./databaseLogger";

/**
 * Single Prisma client for this process. Node’s module cache already ensures one instance
 * per `import` graph — no need for a `globalThis` guard unless you use a dev server that
 * hot-reloads API code without restarting Node (then you can reintroduce the classic
 * `global.prisma ?? new PrismaClient()` pattern).
 *
 * `NODE_ENV` here does not turn Prisma on or off; connection still comes from `DATABASE_URL`.
 *
 * **Query extension:** Every ORM and raw query (`$queryRaw`, `$executeRaw`, etc.) runs through
 * **`$allOperations`**. Failures are logged once via **`logDatabaseError`** with context
 * **`Prisma.{Model}.{operation}`** or **`Prisma.raw.{operation}`**. **`P2025`** (record not found
 * on update/delete) is **not** logged — repositories map it to **`null`** / optional flows.
 */
const prismaBase = new PrismaClient();

export const prisma = prismaBase.$extends({
  query: {
    async $allOperations({ operation, model, args, query }) {
      try {
        return await query(args);
      } catch (error) {
        if (error instanceof PrismaClientKnownRequestError && error.code === "P2025") {
          throw error;
        }
        const ctx = model ? `Prisma.${model}.${operation}` : `Prisma.raw.${operation}`;
        logDatabaseError(error, ctx);
        throw error;
      }
    },
  },
}) as PrismaClient;
