# Prompt constructors

Keep this file aligned with the TypeScript sources when copy changes.

Grounding for SOLO-wide wording (not ad hoc chat): `.cursor/rules/project.mdc` (stack, Swift feature domains such as ideas and mind maps, AI usage from the backend) and `docs/app_feature_description.md` (idea-development narrative, mind maps as a core surface, evolving capabilities). System prompts stay high level so individual users are not boxed into one workflow.

Implementation sources:

- backend/src/modules/ai/prompt_constructor/generalQueryPrompt.ts
- backend/src/modules/ai/prompt_constructor/highlightedFollowUpPrompt.ts
- backend/src/modules/ai/prompt_constructor/objectiveContextPrompt.ts
- backend/src/modules/ai/prompt_constructor/roleContextPrompt.ts
- backend/src/modules/mindmap/prompt_constructor/mindmapSummarizationPrompt.ts

---

## buildGeneralQueryMessages

Source: backend/src/modules/ai/prompt_constructor/generalQueryPrompt.ts. Used by **`POST /ai/prompt`** when **`route`** is omitted or **`general`** (see **`backend/src/modules/ai/ai.service.ts`**).

### System prompt

High-level SOLO assistant stance plus optional **`context.systemSupplement`** (two newlines after the base block when present).

### Guardrails

None beyond the base system copy (project-wide wording stays in **`project.mdc`** / **`docs/app_feature_description.md`**).

### Other controls

- User message order: non-empty **`context.userPreamble`** lines joined with single newlines, blank line, trimmed **`query`**, optional blank line and **`context.userSuffix`**.

---

## buildHighlightedFollowUpQueryMessages

Source: backend/src/modules/ai/prompt_constructor/highlightedFollowUpPrompt.ts. Dispatched from **`POST /ai/prompt`** when **`route`** is **`ai.highlight_follow_up`**; also callable where **`completeChat`** is invoked directly.

### System prompt

```
You assist inside SOLO, an idea-development application for capturing and organizing thinking around ideas.

Their message may include a labeled quotation from text they highlighted earlier in this conversation, followed by a follow-up question.
```

### Guardrails

```
Instructions:
- Anchor your answer to the highlighted excerpt when that block is present.
- You may quote or paraphrase the excerpt briefly when it helps.
- If the question cannot be answered from the excerpt alone, say what you infer or ask one short clarifying question.
- Do not contradict the quoted excerpt; do not invent details as if they appeared there.
- Reply in clear prose unless the user asks for a specific format.
```

### Other controls

- Optional context.systemSupplement: appended after two newlines after the full system block above.
- User message order: non-empty context.userPreamble segments joined with double newlines, blank line, trimmed query, optional blank line and context.userSuffix.

---

## formatHighlightedTextContext

Source: backend/src/modules/ai/prompt_constructor/highlightedFollowUpPrompt.ts (user preamble fragment only; no LLM role).

### System prompt

None.

### Guardrails

The labeled block should appear before the user’s follow-up question so the model treats it as quoted prior chat, not as instructions from the user.

### Other controls

- Empty or whitespace-only highlightedText yields an empty string (omit from preamble).
- Default max body length before truncation: 12000 characters (ellipsis suffix when truncated).
- sourceRole labels the delimiter line: prior assistant message (default) or prior user message.

Template (assistant source; use prior user message when sourceRole is user):

```
[BEGIN HIGHLIGHTED EXCERPT — from prior assistant message]
{body}
[END HIGHLIGHTED EXCERPT]
```

---

## formatObjectiveContext

Source: backend/src/modules/ai/prompt_constructor/objectiveContextPrompt.ts (user preamble or system supplement fragment; no LLM role).

### System prompt

None.

### Guardrails

States what the user wants to achieve in this conversation (AI panel objective). Omit when empty so the model is not given a stale goal.

### Other controls

- Empty or whitespace-only objectiveText yields an empty string.
- Default max body length before truncation: 12000 characters.

```
[BEGIN CHAT OBJECTIVE]
The user stated they want to achieve the following in this conversation while using SOLO (editable in the AI panel):

{body}
[END CHAT OBJECTIVE]
```

---

## formatRoleContext

Source: backend/src/modules/ai/prompt_constructor/roleContextPrompt.ts.

### System prompt

None.

### Guardrails

None defined yet.

### Other controls

Stub: returns empty string until implemented.

---

## buildMindmapSummarizationMessages

Source: backend/src/modules/mindmap/prompt_constructor/mindmapSummarizationPrompt.ts (called via **`completeChat`**).

### System prompt

```
You summarize idea maps in SOLO using only the graph snapshot in the user message—title, nodes, and connections. Mind maps express expanded structure around ideas; stay factual to this snapshot and summarize thoroughly, emphasizing relationships among linked nodes.
```

### Guardrails

```
Write an updated summary of this mind map.
Use as much length as needed to capture every substantive detail from the node texts.
Whenever nodes are linked by a connection, explain how those ideas relate using both endpoints (and anchors where helpful).
Reflect parent/child hierarchy where it clarifies structure.
Stay factual to the title, nodes, and connections given; do not invent goals, users, or missing links.
Reply with plain text only (paragraphs allowed); do not use markdown headings or bullet lists.
```

### Other controls

- User payload starts with mind map title and either current summary text or “Current summary: none”.
- Nodes section: introductory line plus formatted nodes or “(no nodes)”; each node includes id, parent line, position, dimensions, text truncated per node (12000 chars), empty text shown as “(empty text)”.
- Connections section: introductory line plus formatted edges or “(no connections)”; endpoint text snippets truncated shorter (200 chars); open-ended edges called out when target is unset.

---

## Adding constructors

When you add centralized AI dispatch (routes, coordinators), wire builders such as **`buildHighlightedFollowUpQueryMessages`** there and document new sections here using the same headings: System prompt, Guardrails, Other controls.
