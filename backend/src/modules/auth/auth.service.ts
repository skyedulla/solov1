import bcrypt from "bcrypt";

import type { LoginInput, SignUpInput } from "./auth.schema";
import { authRepository, DuplicateEmailError } from "./auth.repository";

const SALT_ROUNDS = 12;

/** Safe to expose to API consumers — never includes password or hash. */
export type PublicUser = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
};

export type LoginResult =
  | { ok: true; user: PublicUser }
  | { ok: false; reason: "invalid_credentials" };

export type SignUpResult =
  | { ok: true; user: PublicUser }
  | { ok: false; reason: "duplicate_email" };

function toPublicUser(row: {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
}): PublicUser {
  return {
    id: row.id,
    email: row.email,
    firstName: row.firstName,
    lastName: row.lastName,
  };
}

/**
 * Business logic: hashing, existence checks, orchestration of repository calls.
 * Passwords and hashes are never part of successful return values.
 */
export const authService = {
  async login(input: LoginInput): Promise<LoginResult> {
    const row = await authRepository.findUserByEmail(input.email);
    if (!row) {
      return { ok: false, reason: "invalid_credentials" };
    }
    const match = await bcrypt.compare(input.password, row.passwordHash);
    if (!match) {
      return { ok: false, reason: "invalid_credentials" };
    }
    return { ok: true, user: toPublicUser(row) };
  },

  async signUp(input: SignUpInput): Promise<SignUpResult> {
    const passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);
    try {
      const row = await authRepository.createUser({
        email: input.email,
        passwordHash,
        firstName: input.firstName,
        lastName: input.lastName,
      });
      return { ok: true, user: toPublicUser(row) };
    } catch (error) {
      if (error instanceof DuplicateEmailError) {
        return { ok: false, reason: "duplicate_email" };
      }
      throw error;
    }
  },
};
