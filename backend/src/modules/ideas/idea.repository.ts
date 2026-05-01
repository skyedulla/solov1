import type { Idea, Prisma } from "@prisma/client";
import { PrismaClientKnownRequestError } from "@prisma/client/runtime/library";

import { prisma } from "../../core/prisma";
import type { IdeaSortBy, IdeaUpdateBody } from "./idea.schema";

function orderByForSort(sort: IdeaSortBy): Prisma.IdeaOrderByWithRelationInput {
  switch (sort) {
    case "title_asc":
      return { title: "asc" };
    case "created_desc":
      return { createdAt: "desc" };
    case "created_asc":
      return { createdAt: "asc" };
    case "updated_desc":
      return { updatedAt: "desc" };
  }
}

export async function findIdeaByIdForUser(userId: string, ideaId: string): Promise<Idea | null> {
  return prisma.idea.findFirst({
    where: { id: ideaId, userId },
  });
}

export async function findIdeasForUser(
  userId: string,
  params: { sort: IdeaSortBy; searchQuery: string },
): Promise<Idea[]> {
  const q = params.searchQuery;
  const where: Prisma.IdeaWhereInput = {
    userId,
    ...(q.length > 0
      ? {
          OR: [
            { title: { contains: q, mode: "insensitive" } },
            { description: { contains: q, mode: "insensitive" } },
            { purpose: { contains: q, mode: "insensitive" } },
          ],
        }
      : {}),
  };

  return prisma.idea.findMany({
    where,
    orderBy: orderByForSort(params.sort),
  });
}

export async function createIdeaForUser(
  userId: string,
  data: {
    title: string;
    purpose: string;
    description: string;
    targetUser: string;
    isPublished: boolean;
  },
): Promise<Idea> {
  return prisma.idea.create({
    data: {
      userId,
      title: data.title,
      purpose: data.purpose,
      description: data.description,
      targetUser: data.targetUser,
      isPublished: data.isPublished,
    },
  });
}

export async function updateIdeaForUser(
  userId: string,
  ideaId: string,
  body: IdeaUpdateBody,
): Promise<Idea | null> {
  const data: Prisma.IdeaUpdateInput = {
    title: body.title,
    purpose: body.purpose,
  };
  if (body.description !== undefined) {
    data.description = body.description;
  }
  if (body.targetUser !== undefined) {
    data.targetUser = body.targetUser;
  }
  if (body.isPublished !== undefined) {
    data.isPublished = body.isPublished;
  }

  try {
    return await prisma.idea.update({
      where: { id: ideaId, userId },
      data,
    });
  } catch (error) {
    if (error instanceof PrismaClientKnownRequestError && error.code === "P2025") {
      return null;
    }
    throw error;
  }
}

export async function deleteIdeaForUser(userId: string, ideaId: string): Promise<boolean> {
  const result = await prisma.idea.deleteMany({
    where: { id: ideaId, userId },
  });
  return result.count > 0;
}
