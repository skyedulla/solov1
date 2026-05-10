import OpenAI from "openai";

let instance: OpenAI | undefined;

function resolvedApiKey(): string | undefined {
  const key = process.env.OPENAI_API_KEY?.trim();
  return key || undefined;
}

/**
 * Shared OpenAI SDK client for server-side calls. Reads **`OPENAI_API_KEY`** from the environment.
 */
export function getOpenAiClient(): OpenAI {
  const apiKey = resolvedApiKey();
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not set");
  }
  instance ??= new OpenAI({ apiKey });
  return instance;
}

/** Same as **`getOpenAiClient`** when the key exists; otherwise **`null`** (no throw). */
export function tryGetOpenAiClient(): OpenAI | null {
  const apiKey = resolvedApiKey();
  if (!apiKey) {
    return null;
  }
  instance ??= new OpenAI({ apiKey });
  return instance;
}
