import { findIdeaByIdForUser } from "../../ideas/idea.repository";

export type PromptVariableResolverParams = {
  userId: string;
  ideaId: string;
  requiredVariables: string[];
};

export async function resolvePromptVariables(
  params: PromptVariableResolverParams,
): Promise<Record<string, string> | null> {
  if (params.requiredVariables.length === 0) {
    return {};
  }

  const idea = await findIdeaByIdForUser(params.userId, params.ideaId);
  if (!idea) {
    return null;
  }

  return params.requiredVariables.reduce<Record<string, string>>((acc, variable) => {
    const value = idea[variable as keyof typeof idea];
    acc[variable] = value == null ? "" : String(value);
    return acc;
  }, {});
}

