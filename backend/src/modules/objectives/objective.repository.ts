import type { Objective, Prisma } from "@prisma/client";
import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";

import { prisma } from "../../core/prisma";
import type { ObjectiveUpdateBody } from "./objective.schema";

export async function createObjectiveForUser(
  userId: string,
  data: { ideaId: string; text: string; isCompleted: boolean },
): Promise<Objective> {
  return prisma.objective.create({
    data: {
      userId,
      ideaId: data.ideaId,
      text: data.text,
      isCompleted: data.isCompleted,
    },
  });
}

export async function updateObjectiveTextForUser(
  userId: string,
  objectiveId: string,
  body: ObjectiveUpdateBody,
): Promise<Objective | null> {
  const data: Prisma.ObjectiveUpdateInput = { text: body.text };
  try {
    return await prisma.objective.update({
      where: { id: objectiveId, userId },
      data,
    });
  } catch (error) {
    if (error instanceof PrismaClientKnownRequestError && error.code === "P2025") {
      return null;
    }
    throw error;
  }
}

/**
 * Toggles `isCompleted` for the given row, scoped to **userId**.
 */
export async function toggleObjectiveCompleteForUser(
  userId: string,
  objectiveId: string,
): Promise<Objective | null> {
  return prisma.$transaction(async (tx) => {
    const row = await tx.objective.findFirst({
      where: { id: objectiveId, userId },
      select: { isCompleted: true },
    });
    if (!row) {
      return null;
    }
    return tx.objective.update({
      where: { id: objectiveId, userId },
      data: { isCompleted: !row.isCompleted },
    });
  });
}

export async function deleteObjectiveForUser(userId: string, objectiveId: string): Promise<boolean> {
  const result = await prisma.objective.deleteMany({
    where: { id: objectiveId, userId },
  });
  return result.count > 0;
}
