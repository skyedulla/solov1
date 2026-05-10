import { APIError } from "openai";

export type LlmCallSource = {
  module: string;
  operation: string;
  toolType?: string;
  sessionId?: string;
};

export type LlmHandledError = {
  error: string;
  status?: number;
  source: LlmCallSource;
};

export function llmSourceToString(source: LlmCallSource | undefined): string {
  if (!source) {
    return "unknown.unknown";
  }
  return [source.module, source.operation, source.toolType].filter(Boolean).join(".");
}

export function handleLlmError(error: unknown, source: LlmCallSource | undefined): LlmHandledError {
  const resolvedSource = source ?? { module: "unknown", operation: "unknown" };

  if (error instanceof APIError) {
    const handled = {
      error: error.message,
      status: error.status,
      source: resolvedSource,
    };
    logLlmError(handled);
    return handled;
  }

  const handled = {
    error: error instanceof Error ? error.message : String(error),
    source: resolvedSource,
  };
  logLlmError(handled);
  return handled;
}

export function logLlmError(error: LlmHandledError): void {
  console.error(
    [
      `[llm-error:${llmSourceToString(error.source)}]`,
      `session=${error.source.sessionId ?? "(none)"}`,
      `status=${error.status ?? "(none)"}`,
      `message=${error.error}`,
    ].join(" "),
  );
}

