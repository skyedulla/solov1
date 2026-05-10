# SOLO codebase index

Inventory of meaningful project files, ordered **alphabetically by file name** (last path segment), using **ASCII / byte order** (e.g. uppercase letters before lowercase). When two files share a name, the **full path** breaks the tie. **This snapshot is no longer actively maintained**; it may drift from the repo.

---

### `.env` (repo root; do not commit secrets)

**Area:** Local / deployment configuration.  
**Purpose:** Single place for `SUPABASE_*`, `API_BASE_URL`, `PORT`, `DATABASE_URL`, `OPENAI_API_KEY`, etc.  
**Contents:** Key–value env vars; **backend** loads this via `dotenv` in `src/index.ts`. Swift reads **mirrored** values (including **`SUPABASE_URL`** / **`SUPABASE_ANON_KEY`**, **`GOOGLE_WEB_OAUTH_CLIENT_ID`**, **`GOOGLE_WEB_OAUTH_REDIRECT_URL`**) via scheme / Info.plist for the Supabase client, not this file at runtime on device when unset. **`GOOGLE_WEB_OAUTH_CLIENT_SECRET`** is for Supabase (or server) only — not bundled in the app.

---

### `.gitignore` (repo root)

**Area:** Git / hygiene.  
**Purpose:** Keep secrets and generated artifacts out of version control.  
**Contents:** Ignores **`.env`**, **`node_modules/`**, **`backend/dist/`**, **`frontend/.build/`**, **`frontend/.swiftpm/`**, **`xcuserdata/`**, common logs and OS junk.

---

### `frontend/lib/core/config/AppConfiguration.swift`

**Area:** Swift client configuration.  
**Purpose:** Resolve **`API_BASE_URL`**, **`SUPABASE_URL`**, **`SUPABASE_ANON_KEY`**, and Google web OAuth–related keys without hardcoding in source.  
**Contents:** **`public`** **`enum`**; reads each from **`ProcessInfo`** environment or **`Info.plist`** (same keys as `.env`); **`preconditionFailure`** if required API/Supabase values are missing; **`googleWebOAuthClientID`** (**optional**); **`googleWebOAuthRedirectURL`** (**`GOOGLE_WEB_OAUTH_REDIRECT_URL`** or default **`{bundleID}://oauth-callback`**).

---

### `frontend/lib/features/auth/controllers/AuthController.swift`

**Area:** Swift auth coordination.  
**Purpose:** App-facing API for login/sign-up, password reset, logout, and Google OAuth via **Supabase Auth**.  
**Contents:** **`public final class`** with injectable **`SupabaseClient`**; **`AuthValidationError`** (**`LocalizedError`**) when sign-up **`firstName` / `lastName`** are missing after trim; **`login(model:)`** → **`signIn`** (**`Session`**); **`googleSignIn(redirectTo:)`** → **`signInWithOAuth`** (**`.google`**); **`signUp(model:)`** validates non-empty names then **`signUp`** with **`first_name` / `last_name`** (**`AuthResponse`**); **`resetPassword(email:redirectTo:)`** → **`resetPasswordForEmail`**; **`logout()`** → **`signOut`**.

---

### `frontend/lib/features/auth/state/AuthFlowViewModel.swift`

**Area:** Swift — auth feature state.  
**Purpose:** Owns which auth screen is shown (log in vs sign up) for the pre–main-shell MVP; the app entry injects this into **`AuthRootView`**.  
**Contents:** **`public enum AuthRoute`** (**.login** / **.signUp**); **`@MainActor`** **`ObservableObject`** with **`@Published var route`**; **`goToSignUp()`**, **`goToLogIn()`**.

---

### `frontend/Tests/SoloLibTests/AuthControllerFlowTests.swift`

**Area:** Swift — auth feature tests.  
**Purpose:** Verify **`AuthController`** runs the real **`SupabaseClient`** Auth stack end-to-end with a stub **`URLSession`** (**`MockURLProtocol`**).  
**Contents:** In-memory **`AuthLocalStorage`**; **`SupabaseClientOptions`** with **`autoRefreshToken: false`** and mocked global session; tests for **`login`**, **`signUp`** (decode **`AuthResponse.user`**), **`resetPassword`**, **`logout`** (after login session), sign-up validation errors; **`testSequentialAuth_invokesLoginResetSignUpLogoutThroughSupabaseSession`** asserts four GoTrue round-trips in order (**`token`**, **`recover`**, **`signup`**, **`logout`**).

---

### `frontend/Tests/SoloLibTests/ConnectionControllerFlowTests.swift`

**Area:** Swift — connections feature tests.  
**Purpose:** Verify **`ConnectionController`** with **`ConnectionsRemoteDataSource`** + stub **`URLSession`**.  
**Contents:** **`MockURLProtocol`** integration tests for **`addConnection`** (with target, open-ended body omitting **`targetNodeId`** / **`targetAnchor`**) and **`deleteConnection`**.

---

### `frontend/lib/features/auth/components/AuthFormContainer.swift`

**Area:** Swift — auth UI.  
**Purpose:** Shared card layout for **`LoginScreen`** / **`SignUpScreen`** on a dark gray background.  
**Contents:** **`AuthFormContainer`**: generic **`VStack`** with max width, padding, rounded rect fill + hairline border (**`AuthTheme`**).

---

### `frontend/lib/features/auth/components/AuthGoogleMark.swift`

**Area:** Swift — auth UI.  
**Purpose:** Logo-only Google mark for the OAuth control (no bundled image asset).  
**Contents:** **`AuthGoogleMark`**: **`SwiftUI`** **`View`** — multicolor ring (**`AngularGradient`**) + blue bar approximating the Google **G**.

---

### `frontend/lib/features/auth/components/AuthLabeledTextField.swift`

**Area:** Swift — auth UI.  
**Purpose:** Consistent labeled field styling for email, names, and password.  
**Contents:** **`AuthLabeledTextField`**: caption label + **`TextField`** or **`SecureField`** with dark fill and border (**`AuthTheme`**).

---

### `frontend/lib/features/auth/components/AuthModeSwitchRow.swift`

**Area:** Swift — auth UI.  
**Purpose:** Secondary line to switch between log-in and sign-up (no navigation logic).  
**Contents:** **`AuthModeSwitchRow`**: secondary text + plain **`Button`** (**`AuthTheme`** link color).

---

### `frontend/lib/features/auth/components/AuthPrimaryButton.swift`

**Area:** Swift — auth UI.  
**Purpose:** Primary CTA on auth forms (light fill on dark UI).  
**Contents:** **`AuthPrimaryButton`**: full-width plain **`Button`** with **`AuthTheme`** primary fill and dark text.

---

### `frontend/lib/features/auth/components/AuthTheme.swift`

**Area:** Swift — auth UI.  
**Purpose:** Central black / gray palette and layout constants for auth screens.  
**Contents:** **`enum AuthTheme`**: background, card, field, text, button colors, corner radii, padding, form max width, square Google OAuth button size + corner radius.

---

### `frontend/lib/features/auth/models/AuthModel.swift`

**Area:** Swift shared model.  
**Purpose:** Sign-up / login field bundle for **`AuthController`**.  
**Contents:** **`public`** **`Codable`** struct with explicit **`public init`**; **`firstName`**, **`lastName`**, **`email`**, **`password`** (metadata fields passed to Supabase on sign-up).

---

### `frontend/lib/features/connections/controllers/ConnectionController.swift`

**Area:** Swift — connections feature coordination.  
**Purpose:** Orchestrates connection (**edge**) **`POST`** / **`DELETE`** against the API.  
**Contents:** **`final class ConnectionController`**: injectable **`ConnectionsRemoteDataSource`**; **`addConnection(sourceNodeId:sourceAnchor:targetNodeId:targetAnchor:mindmapId:accessToken:)`** (optional **`target*`** together — **`POST …/connections`**, **`201`**); **`deleteConnection(id:accessToken:)`** (**`DELETE …/connections/{id}`**, **`204`**); decodes **`ConnectionModel`** with default **`JSONDecoder`** (model uses explicit snake_case **`CodingKeys`**).

---

### `frontend/lib/features/connections/models/ConnectionModel.swift`

**Area:** Swift — connections feature model.  
**Purpose:** Typed bundle for an edge between two nodes (anchors on each end).  
**Contents:** **`ConnectionAnchor`** enum (**`String`**: **`top`**, **`right`**, **`left`**, **`bottom`**); **`Codable`** struct **`ConnectionModel`**: **`id`**, **`mindmapId`**, **`sourceNodeId`**, optional **`targetNodeId`** / **`targetAnchor`** (open link until set); **`sourceAnchor`**; JSON keys **`mindmap_id`**, **`source_node_id`**, **`target_node_id`**, **`source_anchor`**, **`target_anchor`** (idea scope via **`MindmapModel.ideaId`**).

---

### `frontend/lib/features/connections/data_source/ConnectionsRemoteDataSource.swift`

**Area:** Swift — connections API I/O.  
**Purpose:** **`URLSession`** **`POST /connections`** (camelCase JSON body) and **`DELETE …/connections/{id}`** with **`Authorization: Bearer`**.  
**Contents:** **`ConnectionsRemoteDataSource`**: **`addConnection(…)`** (camelCase body; optional **`targetNodeId`** / **`targetAnchor`** omitted unless both set), **`deleteConnection(id:accessToken:)`**; returns raw **`(Data, URLResponse)`**.

---

### `frontend/lib/features/mindmap/models/MindmapCanvasModel.swift`

**Area:** Swift — mind map feature model.  
**Purpose:** Persisted canvas appearance and viewport (separate from **`.nodes`** graph data in **`MindmapModel`**).  
**Contents:** **`Codable`** struct **`MindmapCanvasModel`**: **`id`**, **`backgroundColor`**, **`backgroundDesign`**, **`snapToGrid`** (**`Bool`**, increment **`defaultSnapToGrid`**: **5** when on), **`zoomLevel`**, **`panPosition`** (**`x`**, **`y`**); JSON snake_case for API keys.

---

### `frontend/lib/features/mindmap/controllers/MindmapController.swift`

**Area:** Swift — mind map coordination.  
**Purpose:** Persist new mind maps via the API and build **`MindmapModel`** with the server-assigned **`id`**.  
**Contents:** **`final class MindmapController`**: injectable **`MindmapsRemoteDataSource`**; **`createMindmap`**, **`listMindmaps(ideaId:accessToken:)`** (**`GET …/mindmaps?idea_id=…`**, **`[MindmapSummaryModel]`**), **`loadMindmap`**, **`generateMindmapSummary(id:ideaId:accessToken:)`** (**`POST …/mindmaps/{id}/generate-summary`**, **`String`** summary); **`deleteMindmap`**, **`MindmapControllerError`** (**`unexpectedGenerateSummaryResponse`**, **`summaryGenerationUnavailable`**, list/load/delete/not-found cases); **`loadMindmap`** decodes **`MindmapModel`** with a plain **`JSONDecoder`** (explicit model **`CodingKeys`**); create/list/generate-summary use **`convertFromSnakeCase`** + ISO-8601 where applicable.

---

### `frontend/lib/features/mindmap/models/MindmapModel.swift`

**Area:** Swift — mind map feature model.  
**Purpose:** Full graph snapshot and saved viewport.  
**Contents:** **`Codable`** struct **`MindmapModel`**: **`id`**, **`ideaId`** (JSON **`idea_id`**), **`title`**, **`[NodeModel]`**, **`[ConnectionModel]`**, **`lastTransform`** (**`MindmapViewTransform`**: **`scale`**, **`translateX`**, **`translateY`**; JSON **`last_transform`**, **`translate_x`**, **`translate_y`**).

---

### `frontend/lib/features/mindmap/models/MindmapSummaryModel.swift`

**Area:** Swift — mind map feature model.  
**Purpose:** Metadata for one server mind map row (list endpoint; no nodes/edges).  
**Contents:** **`Codable`** struct **`MindmapSummaryModel`**: **`id`**, **`ideaId`**, **`title`**, **`summary`**, **`createdAt`**, **`lastUpdatedAt`** (wire snake_case via decoder **`convertFromSnakeCase`** + ISO-8601 dates).

---

### `frontend/lib/features/mindmap/data_source/MindmapsRemoteDataSource.swift`

**Area:** Swift — mind map API I/O.  
**Purpose:** **`POST`**, **`GET`**, **`DELETE /mindmaps`** with **`Authorization: Bearer`**.  
**Contents:** **`MindmapsRemoteDataSource`**: **`createMindmap`**, **`listMindmaps`**, **`loadMindmap`**, **`generateMindmapSummary`** (**`POST …/mindmaps/{id}/generate-summary?idea_id=`**), **`deleteMindmap`**; returns raw **`(Data, URLResponse)`**.

---

### `backend/src/core/llm_service/chatCompletion.ts`

**Area:** Backend — core LLM I/O.  
**Purpose:** Thin non-streaming **`chat.completions`** wrapper with typed **`usage`** (including **`cachedPromptTokens`** for prompt-cache visibility).  
**Contents:** **`completeChat`** → **`LlmCompletionResult`**; maps **`APIError`** to **`ok: false`**; default model **`gpt-4o-mini`**.

---

### `backend/src/core/llm_service/index.ts`

**Area:** Backend — core LLM I/O.  
**Purpose:** Barrel exports for **`llm_service`**.  
**Contents:** Re-exports **`completeChat`**, **`LlmChatMessage`** types, **`getOpenAiClient`**, **`tryGetOpenAiClient`**.

---

### `backend/src/core/llm_service/openaiClient.ts`

**Area:** Backend — core LLM I/O.  
**Purpose:** Single lazily constructed **`OpenAI`** SDK instance keyed off **`OPENAI_API_KEY`**.  
**Contents:** **`getOpenAiClient`** (throws if unset); **`tryGetOpenAiClient`** (**`null`** if unset).

---

### `backend/src/modules/ai/ai.controller.ts`

**Area:** Backend — AI HTTP handlers.  
**Purpose:** Validate **`POST /ai/prompt`** with Zod and return **`LlmCompletionResult`** JSON.  
**Contents:** **`sendPrompt`** — **`sendPromptBodySchema.safeParse`**, **`sendPromptForUser`**, **`200`** always on handled requests (**`400`** on validation failure).

---

### `backend/src/modules/ai/ai.repository.ts`

**Area:** Backend — AI persistence / policy stub.  
**Purpose:** Boundary for quotas, audit logs, or future Prisma-backed invocation rows.  
**Contents:** **`assertAiInvocationAllowed`** — currently returns **`true`** for any authenticated user id.

---

### `backend/src/modules/ai/ai.schema.ts`

**Area:** Backend — AI validation.  
**Purpose:** Zod for **`POST /ai/prompt`** (camelCase JSON, Swift-aligned).  
**Contents:** **`aiPromptContextSchema`** / **`AiPromptContext`**; **`sendPromptHistoryMessageSchema`** / **`SendPromptHistoryMessage`** (**`user`** | **`assistant`**, max **100**); **`sendPromptBodySchema`** / **`SendPromptBody`** (**`query`**, optional **`route`**, **`context`**, **`history`**, **`model`**, **`temperature`**, **`maxCompletionTokens`**).

---

### `backend/src/modules/ai/ai.service.ts`

**Area:** Backend — AI orchestration.  
**Purpose:** Dispatch **`body.route`** (**`general`** default vs **`HIGHLIGHT_FOLLOW_UP_ROUTE_ID`**) and run **`completeChat`**.  
**Contents:** **`sendPromptForUser`** — **`assertAiInvocationAllowed`**; builds **`[system, …history, currentUser]`** from route constructors + optional **`body.history`**; **`completeChat`** with optional model / sampling params.

---

### `backend/src/modules/ai/prompt_constructor/generalQueryPrompt.ts`

**Area:** Backend — AI prompt helpers / default chat layout.  
**Purpose:** System + user messages for the **`general`** **`POST /ai/prompt`** route.  
**Contents:** **`buildGeneralQueryMessages`** — SOLO-wide base system line + optional **`AiPromptContext`** fragments around **`query`**.

---

### `backend/src/modules/ai/prompt_constructor/highlightedFollowUpPrompt.ts`

**Area:** Backend — AI prompt helpers / highlight follow-up message builder.  
**Purpose:** Labeled excerpt preamble (**`formatHighlightedTextContext`**) and **`buildHighlightedFollowUpQueryMessages`** for **`completeChat`**; stable **`HIGHLIGHT_FOLLOW_UP_ROUTE_ID`** for dispatch.  
**Contents:** **`AiPromptContext`** (via **`../ai.schema`** type import); **`FormatHighlightedTextContextParams`**, **`HighlightedExcerptSourceRole`**; **`formatHighlightedTextContext`**; **`HIGHLIGHT_FOLLOW_UP_ROUTE_ID`**; **`buildHighlightedFollowUpQueryMessages`** (SOLO stance + highlight-follow-up guardrails).

---

### `backend/src/modules/ai/prompt_constructor/objectiveContextPrompt.ts`

**Area:** Backend — AI prompt helpers.  
**Purpose:** Formats the AI-panel **chat objective** (what the user wants to achieve) for **`AiPromptContext`** injection.  
**Contents:** **`FormatObjectiveContextParams`** (**`objectiveText`**, optional **`maxChars`**); **`formatObjectiveContext`** wraps trimmed text in **`[BEGIN / END CHAT OBJECTIVE]`** (intro line references SOLO’s AI panel) or returns **`""`** when unset.

---

### `backend/src/modules/ai/prompt_constructor/roleContextPrompt.ts`

**Area:** Backend — AI prompt helpers.  
**Purpose:** Builds prompt-ready copy from role / persona context (stub until flows define inputs).  
**Contents:** **`formatRoleContext`** — placeholder returning **`""`**; signature and body to be implemented next.

---

### `frontend/lib/features/ai/viewmodel/AIController.swift`

**Area:** Swift — AI coordination.  
**Purpose:** Parses **`POST /ai/prompt`** responses after **`AIRemoteDataSource`** transport.  
**Contents:** **`actor AIController`**: **`conversationHistory`** (**`SendPromptHistoryMessage`** tape); **`sendPrompt(query:route:context:model:temperature:maxCompletionTokens:accessToken:)`** sends accumulated **`history`** then appends user **`query`** + assistant reply on **`.success`** (trimmed); **`sendPrompt(body:accessToken:)`** stateless; **`resetConversation()`**, **`setMaxStoredHistoryMessages`**.

---

### `frontend/lib/features/ai/data_source/AIRemoteDataSource.swift`

**Area:** Swift — AI API I/O.  
**Purpose:** Raw **`URLSession`** **`POST …/ai/prompt`** with Bearer auth.  
**Contents:** **`final class AIRemoteDataSource`**; **`sendPrompt(body:accessToken:)`** → **`(Data, URLResponse)`**.

---

### `frontend/lib/features/ai/models/SendPromptModels.swift`

**Area:** Swift — AI wire / domain types.  
**Purpose:** Encodable request + decodable **`LlmCompletionResult`** envelope for **`/ai/prompt`**.  
**Contents:** **`AiPromptRouteID`**, **`AiPromptContextPayload`**, **`SendPromptHistoryRole`**, **`SendPromptHistoryMessage`**, **`SendPromptRequestBody`** (optional **`history`**), **`LlmCompletionUsageModel`**, **`SendPromptResult`** (**`success`** / **`failure`**).

---

### `frontend/lib/features/ideas/screens/.gitkeep`

**Area:** Swift — ideas feature UI.  
**Purpose:** Holds full-page **`Screen`** views for the ideas domain; directory is tracked until Swift sources are added.  
**Contents:** Empty marker file only.

---

### `frontend/lib/features/ideas/controllers/IdeaController.swift`

**Area:** Swift — ideas coordination.  
**Purpose:** Orchestrates idea CRUD and related flows; future **`URLSession`** / repository I/O lives behind this type.  
**Contents:** **`final class IdeaController`**: injectable **`IdeasRemoteDataSource`**; **`fetchIdeas(using:accessToken:)`** → **`[IdeaModel]`**; **`createNewIdea(title:purpose:description:targetUser:accessToken:)`** → **`IdeaModel`**; **`editIdea(id:title:purpose:description:targetUser:isPublished:accessToken:)`** → **`IdeaModel`** (**`PATCH …/ideas/{id}`**, expects **`200`**; optional **`isPublished`**); **`togglePublished(idea:accessToken:)`** flips **`isPublished`** via **`editIdea`**; **`deleteIdea(id:accessToken:)`** (**`DELETE …/ideas/{id}`**, expects **`204`**).

---

### `frontend/Tests/SoloLibTests/IdeaControllerFlowTests.swift`

**Area:** Swift — ideas feature tests.  
**Purpose:** Verify **`IdeaController`** entry points run the real stack (**`IdeasRemoteDataSource`** + **`URLSession`**) end-to-end with a stub transport.  
**Contents:** **`XCTestCase`**; registers **`MockURLProtocol`** on an ephemeral **`URLSession`**; per-method tests for **`fetchIdeas`**, **`createNewIdea`**, **`editIdea`**, **`togglePublished`** (false↔true), **`deleteIdea`** (plus error cases); **`testSequentialCRUD_invokesAllFourControllerMethodsThroughDataSource`** asserts five HTTP round-trips (**`POST`**, **`GET`**, **`PATCH`** edit, **`PATCH`** toggle publish, **`DELETE`**).

---

### `frontend/Tests/SoloLibTests/MindmapControllerFlowTests.swift`

**Area:** Swift — mind map document tests.  
**Purpose:** Verify **`MindmapController`** with **`MindmapsRemoteDataSource`** + stub **`URLSession`**.  
**Contents:** Tests for **`createMindmap`**, **`loadMindmap`** (including **`404`** → **`mindmapNotFound`**), **`listMindmaps`**, **`deleteMindmap`**.

---

### `frontend/Tests/SoloLibTests/ObjectiveControllerFlowTests.swift`

**Area:** Swift — workshop objectives feature tests.  
**Purpose:** Verify **`ObjectiveController`** with **`ObjectivesRemoteDataSource`** + stub **`URLSession`**.  
**Contents:** Per-method tests: **`addObjective`** (**`ideaId`** + **`text`** POST JSON, response includes **`idea_id`**), **`modifyObjective`**, **`completeObjective`**, **`deleteObjective`**.

---

### `frontend/lib/features/ideas/controllers/IdeaSearchController.swift`

**Area:** Swift — ideas search coordination.  
**Purpose:** Orchestrates search/filter UI/state using **`IdeaFilterModel`**.  
**Contents:** **`final class IdeaSearchController`**: **`Sendable`** coordinator with a default **`init()`** (behaviour to be wired with search UX).

---

### `frontend/lib/features/ideas/models/IdeaFilterModel.swift`

**Area:** Swift — ideas search/filter model.  
**Purpose:** Query and sort state for idea lists (mind map **IdeaFilter**).  
**Contents:** **`Codable`** struct **`IdeaFilterModel`**: **`sortBy`** (API token from each option’s **`value`** in **`SortByConstants.options`**), **`searchQuery`**.

---

### `frontend/lib/features/ideas/models/IdeaModel.swift`

**Area:** Swift — ideas feature model.  
**Purpose:** Typed bundle for a single idea’s fields.  
**Contents:** **`Codable`** struct **`IdeaModel`**: **`id`**, **`title`**, **`description`**, **`isPublished`**, **`createdAt`**, **`lastUpdatedAt`**, **`targetUser`**, **`purpose`**.

---

### `frontend/lib/features/ideas/data_source/IdeasRemoteDataSource.swift`

**Area:** Swift — ideas API I/O.  
**Purpose:** **`URLSession`** **`GET /ideas`** with **`sort`**, optional **`q`**, and **`Authorization: Bearer`**.  
**Contents:** **`IdeasRemoteDataSource`**: **`fetchIdeas(filter:accessToken:)`** → **`GET …/ideas`**; **`createNewIdea(…)`** → **`POST …/ideas`**; **`editIdea(id:…isPublished:…)`** → **`PATCH …/ideas/{id}`** (optional **`isPublished`** in JSON body); **`deleteIdea(id:accessToken:)`** → **`DELETE …/ideas/{id}`**; all use **`Authorization: Bearer`** where applicable; return raw **`(Data, URLResponse)`** only.

---

### `frontend/lib/features/auth/screens/AuthRootView.swift`

**Area:** Swift — auth UI shell.  
**Purpose:** Single place that switches **`LoginScreen`** / **`SignUpScreen`** from **`AuthFlowViewModel.route`**; keeps **`Solo.swift`** free of navigation details.  
**Contents:** **`public struct AuthRootView`**: **`@EnvironmentObject`**, **`switch`** on **`authFlow.route`**; same window **`frame`** as before; still uses stub **`onLogIn`**, **`onCreateAccount`**.

---

### `frontend/lib/features/auth/screens/LoginScreen.swift`

**Area:** Swift — auth UI.  
**Purpose:** Black/gray log-in page; wires stub **`@State`** fields and primary / mode-switch actions for later view-model hookup.  
**Contents:** **`public struct LoginScreen`**: square rounded Google-only button (**`AuthGoogleMark`**) → **`AuthController.googleSignIn()`**; email + password (**`AuthLabeledTextField`**), **`AuthPrimaryButton`**, **`AuthModeSwitchRow`**; **`onLogIn`** (also after successful Google sign-in), **`onRequestSignUp`**; **`#Preview`**.

---

### `frontend/Tests/SoloLibTests/MockURLProtocol.swift`

**Area:** Swift — test support.  
**Purpose:** Let **`URLSession`** integration tests run without a real server by short-circuiting requests in-process.  
**Contents:** **`URLProtocol`** subclass with a static **`requestHandler`** that returns **`HTTPURLResponse`** + **`Data`**.

---

### `frontend/Tests/SoloLibTests/NodeControllerFlowTests.swift`

**Area:** Swift — mind map node tests.  
**Purpose:** Verify **`NodeController`** with **`NodesRemoteDataSource`** + stub **`URLSession`**.  
**Contents:** Tests for **`searchNodes`** (with query and whitespace-only / no-**`q`**), **`syncNodeToServer`** (**`POST`** / **`PATCH`**), **`deleteNode`**.

---

### `frontend/lib/features/nodes/controllers/NodeController.swift`

**Area:** Swift — nodes coordination.  
**Purpose:** Decode **`NodeModel`** from authenticated **`/nodes`** CRUD.  
**Contents:** **`final class`**, injectable **`NodesRemoteDataSource`**; **`searchNodes(mindmapId:query:)`** (**`GET …/nodes`** with optional **`q`**), **`syncNodeToServer(_:isNew:)`**, **`deleteNode`**; **`200`** / **`201`** / **`204`** expectations; decodes **`NodeModel`** with default **`JSONDecoder`** (explicit model **`CodingKeys`**).

---

### `frontend/lib/features/nodes/data_source/NodesRemoteDataSource.swift`

**Area:** Swift — nodes API I/O.  
**Purpose:** Raw **`URLSession`** for mind map nodes.  
**Contents:** **`GET …/nodes?mindmap_id=`** with optional **`q`** (matches at most **5** nodes; suffix sort when **`q`** present), **`syncNodeToServer`** (**`POST`** / **`PATCH`** JSON with camelCase keys), **`DELETE …/nodes/{id}`** with **`Authorization: Bearer`**.

---

### `frontend/lib/features/nodes/models/NodeModel.swift`

**Area:** Swift — nodes feature model.  
**Purpose:** Typed bundle for a single mind map node’s fields.  
**Contents:** **`Codable`** struct **`NodeModel`**: **`mindmapId`**, **`id`**, optional **`parentNodeId`**, **`position`** (**`x`**, **`y`** as **`Int`**), **`text`**, **`dimensions`** (**`height`**, **`width`** as **`Int`**); JSON keys **`mindmap_id`**, **`parent_node_id`** (idea scope via **`MindmapModel.ideaId`**).

---

### `frontend/lib/features/workshop/controllers/ObjectiveController.swift`

**Area:** Swift — workshop objectives coordination.  
**Purpose:** Decode **`ObjectiveModel`** from authenticated **`/objectives`** calls.  
**Contents:** **`final class`**, injectable **`ObjectivesRemoteDataSource`**; **`addObjective(ideaId:text:accessToken:)`**, **`modifyObjective`**, **`completeObjective`**, **`deleteObjective`**; expects **`201`** / **`200`** / **`204`** from the API.

---

### `frontend/lib/features/workshop/data_source/ObjectivesRemoteDataSource.swift`

**Area:** Swift — workshop objectives API I/O.  
**Purpose:** Raw **`URLSession`** for objective CRUD + toggle.  
**Contents:** **`POST …/objectives`** with JSON **`ideaId`** + **`text`**; **`PATCH …/objectives/{id}`**, **`POST …/objectives/{id}/complete`**, **`DELETE …/objectives/{id}`** with **`Authorization: Bearer`**.

---

### `frontend/lib/features/workshop/models/ObjectiveModel.swift`

**Area:** Swift — workshop feature model.  
**Purpose:** Typed bundle for a single workshop objective.  
**Contents:** **`Codable`** struct **`ObjectiveModel`**: **`id`**, **`ideaId`**, **`text`**, **`isCompleted`**; API JSON uses **`idea_id`** / **`is_completed`** (decode with **`convertFromSnakeCase`** in **`ObjectiveController`**).

---

### `frontend/Solo.xcodeproj/project.pbxproj`

**Area:** Xcode project (generated + committed).  
**Purpose:** Check-in friendly project so the repo opens in Xcode without running XcodeGen first.  
**Contents:** Native targets, SPM **`Package.resolved`** under **`project.xcworkspace/xcshareddata/swiftpm/`**; re-run **`xcodegen`** when **`project.yml`** changes so this file stays in sync.

---

### `frontend/project.yml`

**Area:** Xcode (XcodeGen).  
**Purpose:** Single declarative spec for the **macOS** **`Solo`** app, static **`SoloLib`** (sources under **`lib/`**), and **`SoloLibTests`**; Supabase is an SPM package dependency.  
**Contents:** Target **`Solo`**: **macOS** app with **`PRODUCT_BUNDLE_IDENTIFIER` `app.solo.macos`**, **`Info.plist`**, optional **`__TEXT` / `__info_plist`** link of **`macOS/Info.plist`**; **`SoloLib`**: static library + **`supabase-swift`** (**`Supabase`**); **`Solo`** and **`SoloLibTests`** also link **`Supabase`** for correct symbol resolution. Regenerate: **`xcodegen generate`** in **`frontend/`** (install [**XcodeGen**](https://github.com/yonaskolb/XcodeGen)); then open **`Solo.xcodeproj`**. Tests: **`xcodebuild -project Solo.xcodeproj -scheme Solo -destination 'platform=macOS' test`**.

---

### `backend/postman/SOLO-auth.postman_collection.json`

**Area:** API testing (Postman).  
**Purpose:** Importable collection for manual HTTP checks and quick Supabase password auth.  
**Contents:** Collection vars **`accessToken`**, **`authEmail`**, **`authFirstName`**, **`authLastName`**, **`authPassword`**, **`baseUrl`**, **`connectionId`**, **`ideaId`**, **`mindmapId`**, **`nodeId`**, **`objectiveId`**, **`supabaseAnonKey`**, **`supabaseUrl`**; **`GET /health`**; **Auth (Supabase)** — **`POST …/auth/v1/token?grant_type=password`** (**Sign in**, Tests → **`accessToken`**), **`POST …/auth/v1/signup`** (**Sign up** with **`first_name`** / **`last_name`** **`data`**, sets **`accessToken`** when the response includes **`access_token`**); Ideas — list/create/update (**`PATCH`** + **`PUT`**)/toggle **`isPublished`**/delete; Mindmaps — **`POST /mindmaps`** (**`201`** sets **`mindmapId`**), **`GET /mindmaps?idea_id=`**, **`GET /mindmaps/:id?idea_id=`** (full document), **`DELETE /mindmaps/:id?idea_id=`**; Nodes — **`GET /nodes`** with required **`mindmap_id`** + optional **`q`** (≤5 rows), **`POST/PATCH`/`PUT`/`DELETE /nodes…`** with required JSON **`mindmapId`** (create sets **`nodeId`**); Connections — **`GET /connections?mindmap_id=`** (required), **`POST`** (draft + with-target examples), **`PATCH`/`PUT`/`DELETE /connections/:id`** (**`201`** / Tests may set **`connectionId`**); Objectives — **`POST /objectives`** with **`ideaId`** + **`text`**, **`PATCH/DELETE /objectives…`**, **`POST …/complete`**; **`info.description`** recommends Supabase sign-in then idea → mindmap → nodes/connections flow.

---

### `frontend/lib/features/auth/screens/SignUpScreen.swift`

**Area:** Swift — auth UI.  
**Purpose:** Black/gray sign-up page; stub **`@State`** for name + email + password; delegates actions for future **`AuthController`** integration.  
**Contents:** **`public struct SignUpScreen`**: four fields, **`AuthPrimaryButton`**, **`AuthModeSwitchRow`**; **`onCreateAccount`**, **`onRequestLogIn`**; **`#Preview`**.

---

### `frontend/macOS/Info.plist`

**Area:** Swift — macOS executable metadata.  
**Purpose:** **`CFBundleIdentifier`** and related keys for the **`Solo`** binary; embedded at link time via **`__TEXT` / `__info_plist`** so **`Bundle.main`** sees the bundle ID at runtime; URL scheme for Supabase OAuth return.  
**Contents:** **`app.solo.macos`** (change to your reverse-DNS ID and register in Apple Developer if distributing); **`CFBundleName`**, version, **`LSMinimumSystemVersion`**; **`CFBundleURLTypes`** with scheme **`app.solo.macos`** (align with **`GOOGLE_WEB_OAUTH_REDIRECT_URL`** / default **`app.solo.macos://oauth-callback`**).

---

### `frontend/macOS/Solo.swift`

**Area:** Swift — macOS app entry.  
**Purpose:** Single launch file: **`@main`** SwiftUI app for the **Solo** scheme; only wires the auth shell and shared **`AuthFlowViewModel`**.  
**Contents:** **`struct Solo: App`**, **`@StateObject`** **`AuthFlowViewModel`**, **`WindowGroup`** with **`AuthRootView`** and **`environmentObject`**; targets live in **`Solo.xcodeproj`**.

---

### `frontend/lib/features/auth/supabase/SupabaseClientProvider.swift`

**Area:** Swift — Supabase client wiring.  
**Purpose:** Single **`SupabaseClient`** configured from **`AppConfiguration`**.  
**Contents:** **`public enum`** with **`public static let shared`** lazy **`SupabaseClient`** using **`SUPABASE_URL`** + **`SUPABASE_ANON_KEY`** and **`AuthOptions.redirectToURL`** (**`AppConfiguration.googleWebOAuthRedirectURL`**); imported by **`AuthController`**.

---

### `backend/src/core/apiLogger.ts`

**Area:** Backend observability — request access + non-database errors.  
**Purpose:** Log every completed request; centralize API error formatting outside Prisma.  
**Contents:** **`logApiAccess(method, path, statusCode, durationMs)`**; **`apiAccessLoggingMiddleware()`** (one **`[api]`** line per response on **`res`** **`'finish'`**); **`logApiError(error, context)`** prints **`[api:…]`** blocks — used by **`createApp`** global error handler (when **`isPrismaError`** is false) and **`auth.middleware`**.

---

### `backend/src/core/auth.middleware.ts`

**Area:** Backend — HTTP auth.  
**Purpose:** Verify Supabase access tokens for protected routes.  
**Contents:** **`requireAuth`**: reads **`Authorization: Bearer`**, **`supabase.auth.getUser(token)`**, sets **`req.authUser`**; **`401`** on missing/invalid token; **`500`** only for missing env / config; **`503`** when auth request looks like a transient network failure; otherwise **`500`** generic; **`logApiError`** on thrown errors in the **`catch`** block.

---

### `backend/src/createApp.ts`

**Area:** Backend — Express application factory.  
**Purpose:** Build the JSON-enabled Express app (health + **`/ai`** + **`/ideas`** + **`/mindmaps`** + **`/nodes`** + **`/connections`** + **`/objectives`** + error handler) without opening a port — reused by **`index.ts`**.  
**Contents:** **`createApp()`** returns **`express.Application`** with **`express.json()`**, **`apiAccessLoggingMiddleware`**, **`/health`**, route **`use`** for ai/ideas/mindmaps/nodes/connections/objectives, and **`500`** handler: **`logApiError`** for non-Prisma errors (**Prisma** failures are already logged in **`core/prisma.ts`** query extension, so they are not duplicated here).

---

### `backend/src/core/databaseLogger.ts`

**Area:** Backend observability — Prisma / database client errors.  
**Purpose:** Structured logging when the Postgres path fails via Prisma.  
**Contents:** **`getPrismaCodeDescription`**; **`isPrismaError`** (type guard); **`logDatabaseError(error, context)`** for Prisma only (known request, init, validation, unknown, rust panic); invoked from **`prisma.ts`** query extension and any non-shared DB client / scripts; **`createApp`** uses **`isPrismaError`** only to skip duplicate logging for ORM failures.

---

### `docker-compose.yml`

**Area:** Local infrastructure.  
**Purpose:** Run PostgreSQL for development.  
**Contents:** **`postgres:16-alpine`** service **`solo-postgres-dev`**, env **`POSTGRES_*`**, host port mapping **`5434:5432`** (avoids clash with a local Postgres on 5432), named volume **`solo_pgdata`**.

---

### `backend/src/index.ts`

**Area:** API entrypoint.  
**Purpose:** Load env, create the app via **`createApp()`**, listen for HTTP.  
**Contents:** `dotenv` path resolution for repo-root **`.env`**; comment to run **`prisma migrate deploy`** before relying on DB-backed routes; **`createApp()`** then **`listen`** on **`PORT`** (default 3000).

---

### `backend/src/modules/connections/connection.controller.ts`

**Area:** Backend — mind map connections HTTP handlers.  
**Purpose:** Validate query, params, and bodies; return **`ConnectionResponseBody`** (snake_case) or **`204`**.  
**Contents:** **`listConnections`** (**`GET /`** + **`mindmap_id`** → all edges for the map), **`createConnection`**, **`updateConnection`**, **`deleteConnection`**; **`connectionResponseBodySchema.parse`** on outbound rows; **`404`** when id missing or not owned.

---

### `backend/src/modules/connections/connection.repository.ts`

**Area:** Backend — mind map connections persistence.  
**Purpose:** Prisma-only access for **`MindmapConnection`**.  
**Contents:** **`findConnectionsForUserMindmap`**; **`createConnectionForUser`**, **`findConnectionByIdForUser`**, **`updateConnectionForUser`** (**`P2025`** → **`null`**), **`deleteConnectionForUser`**; empty PATCH → **`findFirst`**.

---

### `backend/src/modules/connections/connection.schema.ts`

**Area:** Backend — connections validation.  
**Purpose:** Zod for **`/connections`** list query, create/update bodies, response aligned with Swift **`ConnectionModel`**.  
**Contents:** **`listConnectionsQuerySchema`** (**`mindmap_id`** UUID); **`connectionCreateBodySchema`** / **`connectionUpdateBodySchema`** (camelCase JSON; optional **`targetNodeId`** / **`targetAnchor`** together on create; **`null`** clears targets on update); **`connectionAnchorSchema`**; **`connectionResponseBodySchema`** (**`mindmap_id`**, **`target_*`** nullable).

---

### `backend/src/modules/connections/connection.service.ts`

**Area:** Backend — mind map connections orchestration.  
**Purpose:** Map validated HTTP data to repository calls.  
**Contents:** **`listConnectionsForUser`**; **`createConnectionForUser`** (**`ConnectionCreateResult`** — **`mindmap_not_found`** before insert); **`updateConnectionForUser`** (**`ConnectionUpdateResult`** — validates target **`mindmap`** when **`mindmapId`** changes); **`deleteConnectionForUser`**.

---

### `backend/src/modules/ideas/idea.controller.ts`

**Area:** Backend — ideas HTTP handlers.  
**Purpose:** Validate query params, call service, set status codes, format JSON for the client.  
**Contents:** **`listIdeas`**, **`createNewIdea`**, **`updateIdea`**, **`deleteIdea`**; param validation via **`ideaIdParamsSchema`**; body validation via **`ideaCreateBodySchema`** / **`ideaUpdateBodySchema`**; **`toIdeaResponseBody`** + **`ideaResponseBodySchema.parse`** for JSON bodies; statuses **`200`** (list / update), **`201`** (create), **`204`** (delete), **`404`** when id missing or not owned; **`req.authUser!.id`**; **`next(error)`** on failure.

---

### `backend/src/modules/ideas/idea.repository.ts`

**Area:** Backend — ideas persistence.  
**Purpose:** Prisma-only access for ideas.  
**Contents:** **`findIdeasForUser`**: **`findMany`** by **`userId`**, **`sort`** → **`orderBy`**, optional **`q`**; **`findIdeaByIdForUser`**: **`findFirst`** by **`id`** + **`userId`**; **`createIdeaForUser`**: **`create`**; **`updateIdeaForUser`**: **`update`** by **`id`** + **`userId`**, **`null`** on **`P2025`**; **`deleteIdeaForUser`**: **`deleteMany`** by **`id`** + **`userId`**, returns whether a row was removed.

---

### `backend/src/modules/ideas/idea.schema.ts`

**Area:** Backend — ideas validation.  
**Purpose:** Zod schemas aligned with Prisma **`Idea`**, Swift **`IdeaModel`**, and API wire JSON.  
**Contents:** **`listIdeasQuerySchema`**; **`ideaIdParamsSchema`**; **`ideaCreateBodySchema`** / **`IdeaCreateBody`**; **`ideaUpdateBodySchema`** / **`IdeaUpdateBody`** (**`PATCH /ideas/:id`**: required **`title`** / **`purpose`**, optional **`description`** / **`targetUser`** / **`isPublished`** — omit to leave unchanged); **`ideaResponseBodySchema`** + **`IdeaResponseBody`** (snake_case JSON aligned with Swift **`IdeaModel`**).

---

### `backend/src/modules/ideas/idea.service.ts`

**Area:** Backend — ideas domain orchestration.  
**Purpose:** Business-facing entry for listing ideas (extend with cross-domain / external calls later).  
**Contents:** **`toRepositoryListParams`** maps **`ListIdeasQuery`** → repository args; **`listIdeasForUser`**, **`createIdeaForUser`**, **`updateIdeaForUser`**, **`deleteIdeaForUser`** → matching **`idea.repository`** methods.

---

### `backend/src/modules/mindmap/mindmap.controller.ts`

**Area:** Backend — mind map resource HTTP handlers.  
**Purpose:** Validate **`POST`**, **`GET /`** (list), **`POST /:id/generate-summary`**, **`GET /:id`**, **`DELETE /:id`**; mind map list, summarization, and load payloads.  
**Contents:** **`createMindmap`**; **`listMindmaps`** (**`listMindmapsQuerySchema`**, **`200`**, **`MindmapResponseBody[]`**); **`generateMindmapSummary`** (**`idea_id`** query, **`200`** **`{ summary }`**, **`503`** LLM/config failure); **`loadMindmap`**; **`deleteMindmap`**; node/connection mappers; **`404`** when applicable.

---

### `backend/src/modules/mindmap/mindmap.repository.ts`

**Area:** Backend — mind map (`Mindmap`) persistence.  
**Purpose:** Prisma **`create`**, **`findFirst`**, **`updateMany`** (**`summary`**), cascade delete for **`mindmaps`**.  
**Contents:** **`createMindmapForUser`**, **`findMindmapByIdForUser`**, **`findMindmapByIdForUserAndIdea`**, **`findMindmapsForUserByIdea`** ( **`updatedAt`** desc), **`updateMindmapSummaryForUser`**, **`deleteMindmapCascadeForUser`** (**`$transaction`** — clears edges/nodes by **`userId`** + **`mindmapId`**).

---

### `backend/src/modules/mindmap/mindmap.schema.ts`

**Area:** Backend — mind map validation.  
**Purpose:** Zod for **`POST /mindmaps`**, **`POST /mindmaps/:id/generate-summary`**, **`GET` / **`DELETE /mindmaps/:id`**, and nested node/connection wire shapes on load.  
**Contents:** **`mindmapCreateBodySchema`** (optional **`title`**, **`summary`**); **`mindmapResponseBodySchema`** (**`title`**, **`summary`** + ids/timestamps); **`mindmapGenerateSummaryResponseSchema`** (**`summary`**); **`mindmapIdParamsSchema`**, **`loadMindmapQuerySchema`**, **`listMindmapsQuerySchema`** (alias of **`idea_id`** query); **`mindmapLoadDocumentResponseSchema`** (**`idea_id`**, **`title`**, graph + **`last_transform`**).

---

### `backend/src/modules/mindmap/mindmap.service.ts`

**Area:** Backend — mind map orchestration.  
**Purpose:** Create mind maps, assemble full documents for **`GET`**, LLM summarization (**`completeChat`** + **`mindmapSummarizationPrompt`**), persist **`summary`**, cascade delete for **`DELETE`**.  
**Contents:** **`createMindmapForUser`**, **`listMindmapsForUser`**; **`loadMindmapDocumentForUser`** (document includes **`ideaId`** + **`title`**); **`generateMindmapSummaryForUser`**; **`deleteMindmapForUser`**.

---

### `backend/src/modules/mindmap/prompt_constructor/mindmapSummarizationPrompt.ts`

**Area:** Backend — mind map LLM prompts.  
**Purpose:** Pure **`LlmChatMessage[]`** builder for AI-assisted **`Mindmap`** summary refresh.  
**Contents:** **`MindmapSummarizationNode`**, **`MindmapSummarizationConnection`**, **`MindmapSummarizationPromptInput`** (**`title`**, **`nodes`**, **`connections`**, optional stale **`currentSummary`**); **`mindmapSummarizationInputFromPersisted`** (Prisma **`MindmapNode`** / **`MindmapConnection`** → input); **`buildMindmapSummarizationMessages`** (concise SOLO **system** stance for graph-only summarization + structured graph sections and edge-aware user instructions).

---

### `backend/src/modules/nodes/node.controller.ts`

**Area:** Backend — mind map nodes HTTP handlers.  
**Purpose:** Validate query, params, and bodies; return **`NodeResponseBody`** (snake_case + nested **`position`** / **`dimensions`**) or **`204`**.  
**Contents:** **`searchNodes`** (**`GET /`** + **`mindmap_id`** + optional **`q`**; **≤5** nodes, suffix-based sort when **`q`** set), **`createNode`**, **`updateNode`**, **`deleteNode`**; **`nodeResponseBodySchema.parse`** on outbound rows; **`404`** when id missing or not owned.

---

### `backend/src/modules/nodes/node.repository.ts`

**Area:** Backend — mind map nodes persistence.  
**Purpose:** Prisma-only access for **`MindmapNode`**.  
**Contents:** **`NODES_SEARCH_LIMIT`** (**5**); **`findNodesForUserMindmap`**: at most 5 rows — empty **`q`** → **`findMany`** **`text`** / **`id`** asc; non-empty **`q`** → raw SQL **`strpos`** match + **`ORDER BY`** lowercased substring after first match + **`id`**; **`findAllNodesForUserMindmap`**; **`createNodeForUser`**, **`findNodeByIdForUser`**, **`updateNodeForUser`** (**`P2025`** → **`null`**), **`deleteNodeForUser`**; empty PATCH → **`findFirst`**.

---

### `backend/src/routes/mindmap.routes.ts`

**Area:** Backend — mind maps routes.  
**Purpose:** Register **`/mindmaps`** with auth.  
**Contents:** **`requireAuth`**; **`POST /`**, **`GET /`** (**`listMindmaps`**, **`idea_id`** query), **`POST /:id/generate-summary`** (**`generateMindmapSummary`**, **`idea_id`** query — register before **`GET /:id`**), **`GET /:id`** (**`loadMindmap`**), **`DELETE /:id`** (**`deleteMindmap`**).

---

### `backend/src/routes/node.routes.ts`

**Area:** Backend — mind map nodes routes.  
**Purpose:** Register **`/nodes`** with auth.  
**Contents:** **`requireAuth`**; **`GET /`** (**`searchNodes`**, **`mindmap_id`** + optional **`q`**), **`POST /`**, **`PATCH /:id`** and **`PUT /:id`**, **`DELETE /:id`**.

---

### `backend/src/modules/nodes/node.schema.ts`

**Area:** Backend — nodes validation.  
**Purpose:** Zod for **`/nodes`** list query, create/update bodies, and response shape aligned with Swift **`NodeModel`**.  
**Contents:** **`searchNodesQuerySchema`** (**`mindmap_id`** UUID, optional **`q`** trimmed, max 500 chars — empty **`q`** → first 5 by **`text`**; non-empty → up to 5 matches); **`nodeCreateBodySchema`** / **`nodeUpdateBodySchema`** (camelCase JSON); **`nodeResponseBodySchema`** (**`mindmap_id`**, **`parent_node_id`**, nested **`position`** / **`dimensions`**).

---

### `backend/src/modules/nodes/node.service.ts`

**Area:** Backend — nodes orchestration.  
**Purpose:** Map validated HTTP data to repository calls.  
**Contents:** **`searchNodesForUser`**; **`createNodeForUser`** (**`NodeCreateResult`** — verifies owning **`mindmap`** via **`findMindmapByIdForUser`**); **`updateNodeForUser`** (**`NodeUpdateResult`** — verifies **`mindmap`** when **`mindmapId`** changes); **`deleteNodeForUser`**.

---

### `backend/src/routes/ai.routes.ts`

**Area:** Backend — AI routes.  
**Purpose:** Register **`/ai`** paths with auth (mounted so **`POST /ai/prompt`**).  
**Contents:** **`requireAuth`**; **`POST /prompt`** → **`sendPrompt`**.

---

### `backend/src/routes/connection.routes.ts`

**Area:** Backend — mind map connections routes.  
**Purpose:** Register **`/connections`** with auth.  
**Contents:** **`requireAuth`**; **`GET /`** (**`listConnections`**, **`mindmap_id`**), **`POST /`**, **`PATCH /:id`** and **`PUT /:id`**, **`DELETE /:id`**.

---

### `backend/src/routes/idea.routes.ts`

**Area:** Backend — ideas routes.  
**Purpose:** Register ideas paths and apply auth to the whole router.  
**Contents:** **`Router`** with **`requireAuth`** then **`GET /`** → **`listIdeas`**, **`POST /`** → **`createNewIdea`**, **`PATCH /:id`** and **`PUT /:id`** → **`updateIdea`**, **`DELETE /:id`** → **`deleteIdea`** (mounted at **`/ideas`** in **`index.ts`** → **`/ideas/{id}`** for by-id routes).

---

### `backend/src/modules/objectives/objective.controller.ts`

**Area:** Backend — objectives HTTP handlers.  
**Purpose:** Zod validate bodies and params, call service, return **`ObjectiveResponseBody`** (snake_case JSON) or **`204`**.  
**Contents:** **`addObjective`** (**`POST /`** — body **`ideaId`** + **`text`**, **`404`** if idea missing / not owned), **`modifyObjective`** (**`PATCH /:id`**, text only), **`completeObjective`** (**`POST /:id/complete`**, flips completion), **`removeObjective`** (**`DELETE /:id`**); **`404`** for objective not found / not owned.

---

### `backend/src/modules/objectives/objective.repository.ts`

**Area:** Backend — objectives persistence.  
**Purpose:** Prisma only for **`Objective`**.  
**Contents:** **`createObjectiveForUser`** (**`ideaId`** on row), **`updateObjectiveTextForUser`** (**`P2025`** → **`null`**), **`toggleObjectiveCompleteForUser`** (transaction: read + flip), **`deleteObjectiveForUser`**.

---

### `backend/src/modules/objectives/objective.schema.ts`

**Area:** Backend — objectives validation.  
**Purpose:** Zod for **`/objectives`** create/update and response shape.  
**Contents:** **`objectiveIdParamsSchema`**; **`objectiveCreateBodySchema`** (**`ideaId`**, **`text`**), **`objectiveUpdateBodySchema`**; **`objectiveResponseBodySchema`** ( **`id`**, **`idea_id`**, **`text`**, **`is_completed`** ).

---

### `backend/src/modules/objectives/objective.service.ts`

**Area:** Backend — objectives orchestration.  
**Purpose:** Map HTTP-validated data to repository calls.  
**Contents:** **`createObjectiveForUser`** (checks idea ownership via **`ideas`** repository; **`null`** → controller **`404`**) **`updateObjectiveForUser`**, **`toggleCompleteForUser`**, **`deleteObjectiveForUser`**.

---

### `backend/src/routes/objective.routes.ts`

**Area:** Backend — objectives routes.  
**Purpose:** Register **`/objectives`** with auth.  
**Contents:** **`requireAuth`**; **`POST /`**, **`PATCH /:id`**, **`POST /:id/complete`**, **`DELETE /:id`**.

---

### `backend/src/types/express.d.ts`

**Area:** Backend — TypeScript.  
**Purpose:** Augment **`Express.Request`** with **`authUser`**.  
**Contents:** Global **`Express`** namespace merge; **`authUser?: User`** (**`@supabase/supabase-js`**).

---

### `launch_dev_build.sh` (repo root)

**Area:** Local development workflow.  
**Purpose:** One command: Docker **Postgres**, **Prisma** **`migrate deploy`**, **API** in the background, then **`xcodebuild`** the **Solo** **macOS** app and **`open -W`**; closing the app (or **Ctrl+C**) stops **Node** and runs **`docker compose down`**. Use **`--api-only`** to match the former **`start-api-stack`** (foreground **`npm run start:api`**).  
**Contents:** Verifies **Docker** and **`xcodebuild`**; fixed **`frontend/.derivedData/`**; **`BUILT_PRODUCTS_DIR`**-style app path; **`open -W -n`**.

---

### `backend/prisma/migrations/20250418180000_init_users/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Initial SQL migration for the **`users`** table.  
**Contents:** `CREATE TABLE users` with columns matching `User` in `schema.prisma` (snake_case in DB, mapped in Prisma).

---

### `backend/prisma/migrations/20260420120000_add_ideas/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Create **`ideas`** table for user-scoped idea records.  
**Contents:** **`CREATE TABLE ideas`** with **`user_id`**, content fields, timestamps; index on **`user_id`**.

---

### `backend/prisma/migrations/20260421120000_add_objectives/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Create **`objectives`** table for user-scoped workshop objectives.  
**Contents:** **`CREATE TABLE objectives`** ( **`user_id`**, **`text`**, **`is_completed`**, timestamps); index on **`user_id`**.

---

### `backend/prisma/migrations/20260430120000_add_mindmap_nodes/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Create **`mindmap_nodes`** for user-scoped mind map node records ( **`idea_id`**, **`mindmap_id`**, layout fields, timestamps).  
**Contents:** **`CREATE TABLE mindmap_nodes`** with **`user_id`**, **`parent_node_id`**, **`position_x`** / **`position_y`**, **`text`**, **`width`** / **`height`**; indexes on **`user_id`** and **`(user_id, mindmap_id)`**.

---

### `backend/prisma/migrations/20260430140000_add_mindmap_connections/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Create **`mindmap_connections`** and **`MindmapConnectionAnchor`** enum for user-scoped edges (**optional **`target`** columns).  
**Contents:** **`CREATE TYPE`** **`MindmapConnectionAnchor`**; **`CREATE TABLE mindmap_connections`** (**`user_id`**, **`idea_id`**, **`mindmap_id`**, **`source_node_id`**, nullable **`target_node_id`** / **`target_anchor`**, **`source_anchor`**, timestamps); indexes on **`user_id`** and **`(user_id, mindmap_id)`**.

---

### `backend/prisma/migrations/20260430160000_add_mindmaps/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Create **`mindmaps`** for user-scoped mind map documents keyed by **`idea_id`** ( **`mindmap_id`** on nodes and connections references **`mindmaps.id`**).  
**Contents:** **`CREATE TABLE mindmaps`** (**`user_id`**, **`idea_id`**, timestamps); indexes on **`user_id`** and **`(user_id, idea_id)`**.

---

### `backend/prisma/migrations/20260501120000_add_objective_idea_id/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Add **`idea_id`** to **`objectives`** so each row belongs to a user’s idea.  
**Contents:** Add nullable **`idea_id`**, backfill from each **`user_id`**’s oldest **`ideas`** row (delete objectives that cannot be assigned), **`SET NOT NULL`**, index **`(user_id, idea_id)`**.

---

### `backend/prisma/migrations/20260501140000_add_mindmap_title_summary/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Store human-readable **`title`** and **`summary`** on each **`mindmaps`** row (list / create response metadata).  
**Contents:** **`ALTER TABLE mindmaps`** — **`title`** and **`summary`** **`TEXT NOT NULL DEFAULT ''`**.

---

### `backend/prisma/migrations/20260503120000_drop_mindmap_node_connection_idea_id/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Remove denormalized **`idea_id`** from **`mindmap_nodes`** and **`mindmap_connections`** (idea scope remains on **`mindmaps.idea_id`**).  
**Contents:** **`ALTER TABLE`** **`DROP COLUMN idea_id`** on both tables.

---

### `backend/prisma/migrations/migration_lock.toml`

**Area:** Database / Prisma.  
**Purpose:** Locks migration provider to PostgreSQL for `prisma migrate`.  
**Contents:** `provider = "postgresql"`.

---

### `backend/package.json`

**Area:** Node API package.  
**Purpose:** Backend dependencies and scripts (`build`, `start`, Prisma).  
**Contents:** Declares `express`, `@prisma/client`, `@supabase/supabase-js`, `dotenv`, `openai`, `zod`, `prisma`, TypeScript; devDependencies **`jest`**, **`ts-jest`**, **`@types/jest`**, **`tree-kill`**; scripts **`clean`** (remove **`dist/`**), **`build`** (`clean` + `prisma generate` + **`tsc -p tsconfig.json`**), **`start`** (`node dist/index.js`), Prisma **`db:migrate`** / **`db:push`**, **`create_token`** / **`token`** (prints Supabase JWT from repo **`.env`**), **`test:e2e`** (**`jest --config jest.e2e.config.cjs`** — config/suite files are not in this repo until restored).

---

### `backend/scripts/create_token.cjs`

**Area:** Backend — local dev helper.  
**Purpose:** Print a Supabase access token for Postman or **`curl`** without fragile one-line shell escaping.  
**Contents:** Reads repo-root **`.env`** (**`SUPABASE_URL`**, **`SUPABASE_ANON_KEY`**, **`EMAIL`**, **`PASSWORD`**); **`@supabase/supabase-js`** **`signInWithPassword`**; writes JWT to stdout. Run: **`npm run create_token --prefix backend`** (or **`npm run token --prefix backend`**, same script).

---

### `package.json` (repo root)

**Area:** Workspace convenience.  
**Purpose:** Shortcuts to backend scripts without **`cd backend`**.  
**Contents:** **`npm run build`**, **`start`**, **`start:api`**, **`start:stack`** (Docker + migrate + API via **`launch_dev_build.sh --api-only`**) and **`npm run launch:dev`** (full **`launch_dev_build.sh`**: also **`xcodebuild`** + **`Solo.app`**; quit app tears down); **`create_token`** / **`token`** prints a Supabase JWT via **`backend`**; **`test:e2e`** forwards to **`backend`** (see **`backend/package.json`**).

---

### `backend/src/core/prisma.ts`

**Area:** Database — Prisma client singleton.  
**Purpose:** Single **`PrismaClient`** for the app; central **`logDatabaseError`** on failed queries (via **`$extends`** **`query.$allOperations`**).  
**Contents:** Wraps **`new PrismaClient()`** with **`$extends`**: logs **`Prisma.{Model}.{operation}`** or **`Prisma.raw.{operation}`**, skips **`P2025`**, rethrows; export cast **`as PrismaClient`**; **`DATABASE_URL`** from **`schema.prisma`**.

---

### `.cursor/rules/backend-layers.mdc`

**Area:** Cursor / AI rules — backend layering.  
**Purpose:** Pin **`controller`** vs **`service`** vs **`repository`** responsibilities (Zod + HTTP in controller; orchestration in service; ORM only in repository).  
**Contents:** Required pipeline; **`logDatabaseError`** at **`prisma`** query extension (**`core/prisma.ts`**) and for any DB code outside the shared client.

---

### `.cursor/rules/project.mdc`

**Area:** Project-wide Cursor / AI rules.  
**Purpose:** Defines stack conventions (Swift client, TypeScript API, Docker, Supabase, env var names, layered architecture for routes → controller → service → repository, Zod validation).  
**Contents:** Non-code policy; stack conventions; **`databaseLogger`** via **`prisma.ts`** extension for the shared client — scripts / alternate clients still call **`logDatabaseError`** on DB failures.

---

### `docs/app_feature_description.md`

**Area:** Documentation — product draft.  
**Purpose:** Draft narrative of SOLO as an idea-development app so prompts and features stay aligned with intent.  
**Contents:** Idea stores and formats; mind maps; AI research and controls; documents/sheets and referencing stored idea data; attachments and RAG-style ingestion (e.g. codebases); note that capabilities evolve.

---

### `docs/prompt_constructors.md`

**Area:** Documentation — LLM prompts.  
**Purpose:** Lets developers review prompt wording; high-level SOLO stance is grounded in `.cursor/rules/project.mdc` and `docs/app_feature_description.md`, not ad hoc chat.  
**Contents:** One section per prompt constructor with System prompt, Guardrails, Other controls; implementation paths listed at top.

---

### `backend/prisma/schema.prisma`

**Area:** Database / Prisma ORM.  
**Purpose:** Defines PostgreSQL models and **`DATABASE_URL`** datasource.  
**Contents:** `generator client`, `datasource db`, **`User`**, **`Idea`**, **`Mindmap`** (**`title`**, **`summary`**, **`idea_id`**), **`Objective`** (**`user_id`**, **`idea_id`**, **`text`**, **`is_completed`** — Supabase **`sub`** on **`user_id`**), **`MindmapNode`** (**`mindmap_id`** only — idea via **`Mindmap`**), enum **`MindmapConnectionAnchor`** + **`MindmapConnection`** (**`mindmap_id`** only, nullable **`target_*`**); snake_case **`@@map`** table names.

---

### `.vscode/settings.json`

**Area:** Editor tooling.  
**Purpose:** VS Code / Cursor TypeScript workspace settings.  
**Contents:** Points **`typescript.tsdk`** at **`backend/node_modules/typescript`** so the IDE resolves types (e.g. Prisma) consistently with the backend; **`files.exclude`** / **`search.exclude`** hide **`backend/dist`** so stale compiled JS does not clutter search or Problems.

---

### `frontend/lib/core/constants/settings/mindmap_canvas_background_design_options.swift`

**Area:** Swift — mind map canvas settings (constants).  
**Purpose:** Stable enum values for **`MindmapCanvasModel.backgroundDesign`**.  
**Contents:** **`BackgroundDesign`** (**`String`**, **`Codable`**): **`none`**, **`dots`**; **`BackgroundDesignConstants.options`** re-exports all cases for pickers.

---

### `frontend/lib/core/constants/sort_by_constants.swift`

**Area:** Swift — ideas list sorting.  
**Purpose:** Pair UI labels with API sort parameter values for **`sortBy`**.  
**Contents:** **`SortByConstants`** enum; **`options`** is an array of **`[String: String]`** dicts with keys **`label`** (display) and **`value`** (API token, e.g. **`title_asc`**, **`created_desc`**).

---

### `backend/tsconfig.json`

**Area:** TypeScript tooling.  
**Purpose:** Compile **`backend/src`** → **`backend/dist`** (used as **`tsc -p tsconfig.json`**).  
**Contents:** `strict`, **`rootDir`** **`src`**, **`outDir`** **`dist`**, CommonJS module settings.

---

### `tsconfig.json` (repo root)

**Area:** Editor / TypeScript project.  
**Purpose:** Lets IDE typecheck **`backend/src`** when workspace root is **`SOLO`**.  
**Contents:** **`include`**: `backend/src/**/*.ts`; **`noEmit`**: true; aligns with resolving **`@prisma/client`** from **`backend/node_modules`**.

---

## Excluded from this index (by design)

- **`backend/dist/`** — compiled output; regenerate with **`npm run build`**.
- **`backend/node_modules/`** — dependencies.
- **`frontend/.build/`** — legacy SwiftPM build dir if ever used.  
- **`frontend/.swiftpm/`** — SwiftPM UI support files when a package is opened; not used for the main **Xcode** flow.
- **`package-lock.json`** — lockfile; regenerate with **`npm install`**.

---

## Module placeholders (empty folders)

`backend/src/modules/` includes **`ai/`** (**`ai.controller.ts`**, **`ai.repository.ts`**, **`ai.schema.ts`**, **`ai.service.ts`**) plus **`ai/prompt_constructor/`** (**`generalQueryPrompt.ts`**, **`highlightedFollowUpPrompt.ts`**, **`objectiveContextPrompt.ts`**, **`roleContextPrompt.ts`** stub); other feature folders (**`workshop`**, **`core`**) may be reserved for future code; **`connections`** has **`connection.controller.ts`**, **`connection.repository.ts`**, **`connection.schema.ts`**, **`connection.service.ts`**; **`ideas`** has **`idea.controller.ts`**, **`idea.repository.ts`**, **`idea.schema.ts`**, **`idea.service.ts`**; **`mindmap`** has **`mindmap.controller.ts`**, **`mindmap.repository.ts`**, **`mindmap.schema.ts`**, **`mindmap.service.ts`**; **`nodes`** has **`node.controller.ts`**, **`node.repository.ts`**, **`node.schema.ts`**, **`node.service.ts`**; **`objectives`** has **`objective.controller.ts`**, **`objective.repository.ts`**, **`objective.schema.ts`**, **`objective.service.ts`**. The former **`auth`** module was removed (client auth uses Supabase only). Add entries here when files land.
