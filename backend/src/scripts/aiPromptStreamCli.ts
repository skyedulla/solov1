import { randomUUID } from "node:crypto";
import path from "node:path";
import readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";

import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

import { AI_TOOL_TYPE_VALUES, AI_TOOL_TYPES } from "../modules/ai/constants";
import { ideaCreateBodySchema } from "../modules/ideas/idea.schema";
import * as ideaService from "../modules/ideas/idea.service";

/** Loads repo-root `.env`, then **`backend/.env`** (compiled path is **`dist/scripts`**). */
dotenv.config({ path: path.resolve(__dirname, "../../../.env") });
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

const CHECK = { ok: "[✓]", fail: "[✗]" } as const;

function printChecklistHeader(title: string): void {
  output.write(`\n── ${title} ──\n`);
}

function logChecklistOk(step: string, detail?: string): void {
  output.write(`${CHECK.ok} ${step}${detail ? ` — ${detail}` : ""}\n`);
}

function logChecklistFail(step: string, error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);
  output.write(`${CHECK.fail} ${step}\n`);
  output.write(`    cause: ${message}\n`);
}

async function runChecklistStep<T>(step: string, fn: () => Promise<T>, detail?: (value: T) => string | undefined): Promise<T> {
  try {
    const value = await fn();
    logChecklistOk(step, detail?.(value));
    return value;
  } catch (error: unknown) {
    logChecklistFail(step, error);
    throw error;
  }
}

type StreamChunk =
  | { type: "conversation"; conversation_id: string }
  | {
      type: "formatted_prompt";
      messages: Array<{ role: "system" | "user" | "assistant"; content: string }>;
    }
  | { type: "content"; content: string }
  | {
      type: "done";
      model: string;
      usage: {
        prompt_tokens: number;
        completion_tokens: number;
        total_tokens: number;
        cached_prompt_tokens: number | null;
      };
    }
  | { type: "error"; error: string; status?: number };

function formatDoneFooter(parsed: Extract<StreamChunk, { type: "done" }>): string {
  const { model, usage } = parsed;
  const inputTokens = usage.prompt_tokens;
  const outputTokens = usage.completion_tokens;
  const cached = usage.cached_prompt_tokens;
  let cachedPctOfInput: string;
  if (cached == null) {
    cachedPctOfInput = "n/a";
  } else if (inputTokens === 0) {
    cachedPctOfInput = "n/a";
  } else {
    cachedPctOfInput = `${((cached / inputTokens) * 100).toFixed(1)}%`;
  }
  const cachedDisplay = cached == null ? "null" : String(cached);
  return (
    `\n\n[done] model=${model} ` +
    `input_tokens=${inputTokens} ` +
    `output_tokens=${outputTokens} ` +
    `cached_input_tokens=${cachedDisplay} ` +
    `cached_pct_of_input=${cachedPctOfInput} ` +
    `total_tokens=${usage.total_tokens}\n`
  );
}

const MARS_TEST_IDEA_BODY = ideaCreateBodySchema.parse({
  title: "MARS",
  purpose:
    "To simplify the coding process by enabling users to work with visual elements while generating code simultaneously.",
  description:
    "Users can leverage various templates within a canvas to map out features, functionality, and system architecture, then generate code directly from those visuals. An AI assistant oversees the process and prompts users to fill in missing details in their mind maps, such as properties, functionalities, and UI components. Users are expected to provide complete information expressed in terms of variables, functions, algorithms (represented through flowcharts), UI components (defining end-to-end event flows), and state management. The AI supports this process by identifying gaps in the user’s visual inputs.",
  targetUser:
    "Computer science students (primarily undergraduate level) and entrepreneurs looking to build MVPs independently.",
  isPublished: false,
});

function resolveApiBaseUrl(): string {
  const apiBaseUrl = process.env.API_BASE_URL ?? "http://localhost:4000";
  return apiBaseUrl.endsWith("/") ? apiBaseUrl.slice(0, -1) : apiBaseUrl;
}

async function promptForAccessToken(rl: readline.Interface): Promise<string> {
  output.write("\nPaste your Supabase access token (JWT), then press Enter.\n");
  output.write("Optional: prefix with `Bearer ` — it will be stripped.\n");
  while (true) {
    const raw = (await rl.question("access_token> ")).trim();
    const token = raw.startsWith("Bearer ") ? raw.slice("Bearer ".length).trim() : raw;
    if (token) {
      return token;
    }
    output.write("Token cannot be empty.\n");
  }
}

async function resolveAuthUserId(accessToken: string): Promise<string> {
  const url = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error("SUPABASE_URL and SUPABASE_ANON_KEY must be set (e.g. in repo-root .env) to resolve user id.");
  }
  const supabase = createClient(url, anonKey);
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(accessToken);
  if (error || !user) {
    throw new Error(error?.message ?? "Could not resolve user from access token.");
  }
  return user.id;
}

/** Create the MARS idea via **`createIdeaForUser`** (same as **`createNewIdea`** after validation). */
async function createMarsTestIdea(accessToken: string): Promise<string> {
  const userId = await runChecklistStep("Resolve Supabase user from token (getUser)", () =>
    resolveAuthUserId(accessToken),
  );
  const ideaId = await runChecklistStep("Create MARS idea in database (Prisma)", async () => {
    const idea = await ideaService.createIdeaForUser(userId, MARS_TEST_IDEA_BODY);
    return idea.id;
  }, (id) => `idea_id=${id}`);
  return ideaId;
}

const TOOL_MENU: { key: string; value: (typeof AI_TOOL_TYPE_VALUES)[number] }[] = [
  { key: "1", value: AI_TOOL_TYPES.highlightedSnippet },
  { key: "2", value: AI_TOOL_TYPES.planning },
  { key: "3", value: AI_TOOL_TYPES.mindmap },
  { key: "4", value: AI_TOOL_TYPES.research },
];

async function selectToolType(rl: readline.Interface): Promise<(typeof AI_TOOL_TYPE_VALUES)[number]> {
  output.write("\nSelect tool type:\n");
  output.write(`  1) ${AI_TOOL_TYPES.highlightedSnippet}\n`);
  output.write(`  2) ${AI_TOOL_TYPES.planning}\n`);
  output.write(`  3) ${AI_TOOL_TYPES.mindmap}\n`);
  output.write(`  4) ${AI_TOOL_TYPES.research}\n`);

  while (true) {
    const line = (await rl.question("Enter 1–4 [default 2]: ")).trim();
    const choice = line === "" ? "2" : line;
    const entry = TOOL_MENU.find((m) => m.key === choice);
    if (entry) {
      return entry.value;
    }
    output.write("Invalid choice. Use 1, 2, 3, or 4.\n");
  }
}

async function printStreamingPrompt(params: {
  prompt: string;
  ideaId: string;
  conversationId: string;
  toolType: (typeof AI_TOOL_TYPE_VALUES)[number];
  token: string;
}): Promise<void> {
  const { prompt, ideaId, conversationId, toolType, token } = params;
  printChecklistHeader(`Prompt round — POST ${resolveApiBaseUrl()}/ai/prompt`);

  const body = await runChecklistStep("Build JSON body (tool, query, ids, flags)", async () => ({
    tool_type: toolType,
    query: prompt,
    context: {
      idea_id: ideaId,
      conversation_id: conversationId,
    },
    llm_model: "gpt-4o-mini",
    temperature: 0.2,
    max_tokens: 500,
    idea_id: ideaId,
    conversation_id: conversationId,
    include_formatted_prompt: true,
  }));

  const response = await runChecklistStep("Send HTTP request (fetch)", () =>
    fetch(`${resolveApiBaseUrl()}/ai/prompt`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        Accept: "application/x-ndjson",
      },
      body: JSON.stringify(body),
    }),
  );

  await runChecklistStep("Validate HTTP status (expect 2xx before streaming)", async () => {
    if (!response.ok) {
      const rawError = await response.text();
      throw new Error(`HTTP ${response.status}: ${rawError}`);
    }
    return response.status;
  }, (status) => `status=${status}`);

  const streamBody = await runChecklistStep("Open response body stream", async () => {
    const b = response.body;
    if (!b) {
      throw new Error("No response stream returned by server.");
    }
    return b;
  });

  const decoder = new TextDecoder();
  let buffer = "";
  let printedFormattedPrompt = false;
  let sawDoneChunk = false;
  let sawStreamErrorChunk = false;

  function handleParsedLine(parsed: StreamChunk, lineIndex: number): void {
    if (parsed.type === "conversation") {
      logChecklistOk(`NDJSON line ${lineIndex}: conversation id`, parsed.conversation_id);
      return;
    }
    if (parsed.type === "formatted_prompt") {
      printedFormattedPrompt = true;
      output.write("\n\nFinal Input Prompt:\n\n");
      output.write(JSON.stringify(parsed.messages, null, 2));
      output.write("\n\n");
      return;
    }
    if (parsed.type === "content") {
      output.write(parsed.content);
      return;
    }
    if (parsed.type === "error") {
      sawStreamErrorChunk = true;
      logChecklistFail(`NDJSON line ${lineIndex}: stream error chunk`, new Error(parsed.error));
      output.write(`\n\n[stream-error] ${parsed.error}\n`);
      return;
    }
    sawDoneChunk = true;
    output.write(formatDoneFooter(parsed));
  }

  let lineCounter = 0;
  try {
    for await (const chunk of streamBody) {
      buffer += decoder.decode(chunk, { stream: true });

      let newline = buffer.indexOf("\n");
      while (newline >= 0) {
        const line = buffer.slice(0, newline).trim();
        buffer = buffer.slice(newline + 1);
        newline = buffer.indexOf("\n");

        if (!line) {
          continue;
        }

        lineCounter += 1;
        let parsed: StreamChunk;
        try {
          parsed = JSON.parse(line) as StreamChunk;
        } catch (parseErr: unknown) {
          throw new Error(`Invalid JSON on NDJSON line ${lineCounter}: ${line.slice(0, 120)}…`, { cause: parseErr });
        }
        handleParsedLine(parsed, lineCounter);
      }
    }

    const tail = buffer.trim();
    if (tail) {
      lineCounter += 1;
      let parsed: StreamChunk;
      try {
        parsed = JSON.parse(tail) as StreamChunk;
      } catch (parseErr: unknown) {
        throw new Error(`Invalid JSON on NDJSON tail (line ${lineCounter})`, { cause: parseErr });
      }
      handleParsedLine(parsed, lineCounter);
    }
  } catch (error: unknown) {
    logChecklistFail("Consume NDJSON stream (read / parse lines)", error);
    throw error;
  }

  if (!printedFormattedPrompt) {
    output.write("\n\n[warning] No formatted_prompt chunk received from server.\n\n");
  }

  if (sawStreamErrorChunk) {
    logChecklistOk("Stream terminal state", "error chunk from provider (see [stream-error] above)");
  } else if (!sawDoneChunk) {
    logChecklistFail("Stream terminal state", new Error("No done chunk and no stream error chunk"));
  }

  output.write("\n");
}

async function main(): Promise<void> {
  printChecklistHeader("Startup — environment");
  logChecklistOk("Load .env (repo root, then backend)");

  const baseUrl = resolveApiBaseUrl();
  logChecklistOk("Resolve API base URL", baseUrl);

  const rl = readline.createInterface({ input, output });

  printChecklistHeader("Startup — interactive");
  const token = await runChecklistStep("Paste access token (JWT)", () => promptForAccessToken(rl));
  const toolType = await runChecklistStep("Select AI tool type", () => selectToolType(rl), (t) => String(t));

  printChecklistHeader("Startup — MARS fixture");
  const ideaId = await createMarsTestIdea(token);
  const conversationId = randomUUID();
  logChecklistOk("Generate conversation_id for this session", conversationId);

  printChecklistHeader("Startup — complete");
  logChecklistOk("Ready for prompts (type exit to quit)");

  output.write("\nTerminal AI stream test ready. Each line you send is one user turn.\n");
  output.write("The same conversation_id is reused so the API includes prior turns in history.\n");
  output.write("After each request you will see Final Input Prompt (full message list) then the assistant reply.\n");
  output.write("Type 'exit' to quit.\n");
  output.write(`API base URL: ${baseUrl}\n`);
  output.write(`idea_id: ${ideaId}\n`);
  output.write(`conversation_id: ${conversationId}\n`);
  output.write(`tool_type: ${toolType}\n\n`);

  while (true) {
    const prompt = (await rl.question("> ")).trim();
    if (!prompt) {
      continue;
    }
    if (prompt.toLowerCase() === "exit") {
      break;
    }

    try {
      await printStreamingPrompt({ prompt, ideaId, conversationId, toolType, token });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      output.write(`\n[request-failed] ${message}\n\n`);
    }
  }

  rl.close();
}

void main();
