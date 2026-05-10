import type { LlmCompletionUsage } from "./llm_service";

type LlmUsageLogInput = {
  source: string;
  sessionId?: string;
  model: string;
  usage: LlmCompletionUsage;
};

type Pricing = {
  inputCentsPer1k: number;
  outputCentsPer1k: number;
  cachedInputCentsPer1k: number;
};

type SessionAggregate = {
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  cachedPromptTokens: number;
  estimatedCents: number;
};

const MODEL_PRICING: Record<string, Pricing> = {
  "gpt-4o-mini": {
    inputCentsPer1k: 0.015,
    outputCentsPer1k: 0.06,
    cachedInputCentsPer1k: 0.0075,
  },
  "gpt-4o": {
    inputCentsPer1k: 0.25,
    outputCentsPer1k: 1,
    cachedInputCentsPer1k: 0.125,
  },
};

const sessionAggregates = new Map<string, SessionAggregate>();

function pricingForModel(model: string): Pricing | null {
  return MODEL_PRICING[model] ?? null;
}

function estimateCents(model: string, usage: LlmCompletionUsage): number | null {
  const pricing = pricingForModel(model);
  if (!pricing) {
    return null;
  }

  const cachedPromptTokens = usage.cachedPromptTokens ?? 0;
  const uncachedPromptTokens = Math.max(usage.promptTokens - cachedPromptTokens, 0);
  return (
    (uncachedPromptTokens / 1000) * pricing.inputCentsPer1k +
    (cachedPromptTokens / 1000) * pricing.cachedInputCentsPer1k +
    (usage.completionTokens / 1000) * pricing.outputCentsPer1k
  );
}

function updateAggregate(sessionId: string, usage: LlmCompletionUsage, estimatedCents: number): SessionAggregate {
  const current =
    sessionAggregates.get(sessionId) ??
    {
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
      cachedPromptTokens: 0,
      estimatedCents: 0,
    };

  const next = {
    inputTokens: current.inputTokens + usage.promptTokens,
    outputTokens: current.outputTokens + usage.completionTokens,
    totalTokens: current.totalTokens + usage.totalTokens,
    cachedPromptTokens: current.cachedPromptTokens + (usage.cachedPromptTokens ?? 0),
    estimatedCents: current.estimatedCents + estimatedCents,
  };
  sessionAggregates.set(sessionId, next);
  return next;
}

export function logLlmUsage(input: LlmUsageLogInput): void {
  const estimatedCents = estimateCents(input.model, input.usage);
  const usageCents = estimatedCents === null ? "unknown" : estimatedCents.toFixed(6);

  let aggregateText = "";
  if (input.sessionId && estimatedCents !== null) {
    const aggregate = updateAggregate(input.sessionId, input.usage, estimatedCents);
    aggregateText = ` session_total_cents=${aggregate.estimatedCents.toFixed(6)}`;
  }

  console.log(
    [
      `[llm:${input.source}]`,
      `model=${input.model}`,
      `session=${input.sessionId ?? "(none)"}`,
      `input_tokens=${input.usage.promptTokens}`,
      `output_tokens=${input.usage.completionTokens}`,
      `total_tokens=${input.usage.totalTokens}`,
      `cached_prompt_tokens=${input.usage.cachedPromptTokens ?? 0}`,
      `usage_cents=${usageCents}${aggregateText}`,
    ].join(" "),
  );
}

export function getLlmSessionAggregate(sessionId: string): SessionAggregate | null {
  return sessionAggregates.get(sessionId) ?? null;
}

