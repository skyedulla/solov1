import type { Idea, Prisma } from "@prisma/client";

import { prisma } from "../../core/prisma";
import { logDatabaseError } from "../../core/databaseLogger";
import type { IdeaSortBy } from "./idea.schema";

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

export async function findIdeasForUser(
  userId: string,
  params: { sort: IdeaSortBy; searchQuery: string },
): Promise<Idea[]> {
  try {
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

    return await prisma.idea.findMany({
      where,
      orderBy: orderByForSort(params.sort),
    });
  } catch (error) {
    logDatabaseError(error, "IdeaRepository.findIdeasForUser");
    throw error;
  }
}
