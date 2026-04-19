import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";

import { logDatabaseError } from "../../core/databaseLogger";
import { prisma } from "../../core/prisma";

/** Thrown when a unique constraint on `email` fails (Prisma `P2002`). */
export class DuplicateEmailError extends Error {
  readonly code = "DUPLICATE_EMAIL" as const;

  constructor() {
    super("An account with this email already exists");
    this.name = "DuplicateEmailError";
  }
}

export type UserRow = {
  id: string;
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  createdAt: Date;
  updatedAt: Date;
};

function isUniqueViolation(error: unknown): boolean {
  return error instanceof PrismaClientKnownRequestError && error.code === "P2002";
}

/**
 * Data access only — no hashing, no HTTP. Prisma `findUnique` / `create`.
 */
export const authRepository = {
  async findUserByEmail(email: string): Promise<UserRow | null> {
    try {
      const row = await prisma.user.findUnique({ where: { email } });
      return row;
    } catch (error) {
      logDatabaseError(error, "authRepository.findUserByEmail");
      throw error;
    }
  },

  async createUser(data: {
    email: string;
    passwordHash: string;
    firstName: string;
    lastName: string;
  }): Promise<UserRow> {
    try {
      return await prisma.user.create({ data });
    } catch (error) {
      logDatabaseError(error, "authRepository.createUser");
      if (isUniqueViolation(error)) {
        throw new DuplicateEmailError();
      }
      throw error;
    }
  },
};
