import type { Objective } from "@prisma/client";

import type { ObjectiveCreateBody, ObjectiveUpdateBody } from "./objective.schema";
import * as objectiveRepository from "./objective.repository";

export async function createObjectiveForUser(
  authUserId: string,
  body: ObjectiveCreateBody,
): Promise<Objective> {
  return objectiveRepository.createObjectiveForUser(authUserId, {
    text: body.text,
    isCompleted: false,
  });
}

export async function updateObjectiveForUser(
  authUserId: string,
  objectiveId: string,
  body: ObjectiveUpdateBody,
): Promise<Objective | null> {
  return objectiveRepository.updateObjectiveTextForUser(authUserId, objectiveId, body);
}

export async function toggleCompleteForUser(
  authUserId: string,
  objectiveId: string,
): Promise<Objective | null> {
  return objectiveRepository.toggleObjectiveCompleteForUser(authUserId, objectiveId);
}

export async function deleteObjectiveForUser(
  authUserId: string,
  objectiveId: string,
): Promise<boolean> {
  return objectiveRepository.deleteObjectiveForUser(authUserId, objectiveId);
}
