import type { Objective, Prisma } from "@prisma/client";
import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";

import { prisma } from "../../core/prisma";
import { logDatabaseError } from "../../core/databaseLogger";
import type { ObjectiveUpdateBody } from "./objective.schema";

export async function createObjectiveForUser(
  userId: string,
  data: { text: string; isCompleted: boolean },
): Promise<Objective> {
  try {
    return await prisma.objective.create({
      data: {
        userId,
        text: data.text,
        isCompleted: data.isCompleted,
      },
    });
  } catch (error) {
    logDatabaseError(error, "ObjectiveRepository.createObjectiveForUser");
    throw error;
  }
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
    logDatabaseError(error, "ObjectiveRepository.updateObjectiveTextForUser");
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
  try {
    return await prisma.$transaction(async (tx) => {
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
  } catch (error) {
    logDatabaseError(error, "ObjectiveRepository.toggleObjectiveCompleteForUser");
    throw error;
  }
}

export async function deleteObjectiveForUser(userId: string, objectiveId: string): Promise<boolean> {
  try {
    const result = await prisma.objective.deleteMany({
      where: { id: objectiveId, userId },
    });
    return result.count > 0;
  } catch (error) {
    logDatabaseError(error, "ObjectiveRepository.deleteObjectiveForUser");
    throw error;
  }
}
