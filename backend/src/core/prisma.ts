import { PrismaClient } from "@prisma/client";

/**
 * Single Prisma client for this process. Node’s module cache already ensures one instance
 * per `import` graph — no need for a `globalThis` guard unless you use a dev server that
 * hot-reloads API code without restarting Node (then you can reintroduce the classic
 * `global.prisma ?? new PrismaClient()` pattern).
 *
 * `NODE_ENV` here does not turn Prisma on or off; connection still comes from `DATABASE_URL`.
 */
export const prisma = new PrismaClient();
