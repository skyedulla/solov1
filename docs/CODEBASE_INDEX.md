# SOLO codebase index

Inventory of meaningful project files, ordered **alphabetically by file name** (last path segment), using **ASCII / byte order** (e.g. uppercase letters before lowercase). When two files share a name, the **full path** breaks the tie. **Update this document** whenever you add, remove, or meaningfully change a tracked file (see `.cursor/rules/codebase-index.mdc`).

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

### `frontend/lib/features/mindmap/models/CanvasModel.swift`

**Area:** Swift — mind map feature model.  
**Purpose:** Persisted canvas appearance and viewport (separate from **`.nodes`** graph data in **`MapModel`**).  
**Contents:** **`Codable`** struct **`CanvasModel`**: **`id`**, **`mindmapId`**, **`backgroundColor`**, **`backgroundDesign`**, **`snapToGrid`** (**`Bool`**, increment **`defaultSnapToGrid`**: **5** when on), **`zoomLevel`**, **`panPosition`** (**`x`**, **`y`**); JSON snake_case for API keys.

---

### `frontend/lib/features/mindmap/models/ConnectionModel.swift`

**Area:** Swift — mind map feature model.  
**Purpose:** Typed bundle for an edge between two nodes (anchors on each end).  
**Contents:** **`ConnectionAnchor`** enum (**`String`**: **`top`**, **`right`**, **`left`**, **`bottom`**); **`Codable`** struct **`ConnectionModel`**: **`id`**, **`ideaId`**, **`mindmapId`**, **`sourceNodeId`**, **`targetNodeId`**, **`sourceAnchor`**, **`targetAnchor`**; JSON keys **`idea_id`**, **`mindmap_id`**, **`source_node_id`**, **`target_node_id`**, **`source_anchor`**, **`target_anchor`**.

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

### `frontend/Tests/SoloLibTests/ObjectiveControllerFlowTests.swift`

**Area:** Swift — workshop objectives feature tests.  
**Purpose:** Verify **`ObjectiveController`** with **`ObjectivesRemoteDataSource`** + stub **`URLSession`**.  
**Contents:** Per-method tests: **`addObjective`**, **`modifyObjective`**, **`completeObjective`**, **`deleteObjective`**.

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
**Contents:** **`IdeasRemoteDataSource`**: **`fetchIdeas(filter:accessToken:)`** → **`GET …/ideas`**; **`createNewIdea(…)`** → **`POST …/ideas`**; **`updateIdea(id:…isPublished:…)`** → **`PATCH …/ideas/{id}`** (optional **`isPublished`** in JSON body); **`deleteIdea(id:accessToken:)`** → **`DELETE …/ideas/{id}`**; all use **`Authorization: Bearer`** where applicable; return raw **`(Data, URLResponse)`** only.

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

### `frontend/lib/features/mindmap/models/MapModel.swift`

**Area:** Swift — mind map feature model.  
**Purpose:** Full graph snapshot and saved viewport.  
**Contents:** **`Codable`** struct **`MapModel`**: **`id`**, **`[NodeModel]`**, **`[ConnectionModel]`**, **`lastTransform`** (**`MapViewTransform`**: **`scale`**, **`translateX`**, **`translateY`**; JSON **`last_transform`**, **`translate_x`**, **`translate_y`**).

---

### `frontend/Tests/SoloLibTests/MockURLProtocol.swift`

**Area:** Swift — test support.  
**Purpose:** Let **`URLSession`** integration tests run without a real server by short-circuiting requests in-process.  
**Contents:** **`URLProtocol`** subclass with a static **`requestHandler`** that returns **`HTTPURLResponse`** + **`Data`**.

---

### `frontend/lib/features/nodes/models/NodeModel.swift`

**Area:** Swift — nodes feature model.  
**Purpose:** Typed bundle for a single mind map node’s fields.  
**Contents:** **`Codable`** struct **`NodeModel`**: **`ideaId`**, **`mindmapId`**, **`id`**, optional **`parentNodeId`**, **`position`** (**`x`**, **`y`** as **`Int`**), **`text`**, **`dimensions`** (**`height`**, **`width`** as **`Int`**); JSON keys **`idea_id`**, **`mindmap_id`**, **`parent_node_id`**.

---

### `frontend/lib/features/workshop/controllers/ObjectiveController.swift`

**Area:** Swift — workshop objectives coordination.  
**Purpose:** Decode **`ObjectiveModel`** from authenticated **`/objectives`** calls.  
**Contents:** **`final class`**, injectable **`ObjectivesRemoteDataSource`**; **`addObjective`**, **`modifyObjective`**, **`completeObjective`**, **`deleteObjective`**; expects **`201`** / **`200`** / **`204`** from the API.

---

### `frontend/lib/features/workshop/data_source/ObjectivesRemoteDataSource.swift`

**Area:** Swift — workshop objectives API I/O.  
**Purpose:** Raw **`URLSession`** for objective CRUD + toggle.  
**Contents:** **`POST …/objectives`**, **`PATCH …/objectives/{id}`**, **`POST …/objectives/{id}/complete`**, **`DELETE …/objectives/{id}`** with **`Authorization: Bearer`**.

---

### `frontend/lib/features/workshop/models/ObjectiveModel.swift`

**Area:** Swift — workshop feature model.  
**Purpose:** Typed bundle for a single workshop objective.  
**Contents:** **`Codable`** struct **`ObjectiveModel`**: **`id`**, **`text`**, **`isCompleted`**; API JSON uses **`is_completed`** (decode with **`convertFromSnakeCase`** in **`ObjectiveController`**).

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
**Purpose:** Importable collection for manual HTTP checks.  
**Contents:** Collection vars **`baseUrl`**, **`accessToken`**, **`ideaId`**, **`objectiveId`**; **`GET /health`**; Ideas — list/create/update (**`PATCH`** + **`PUT`**)/toggle **`isPublished`**/delete; Objectives — **`POST/PATCH/DELETE /objectives…`**, **`POST …/complete`** (test script sets **`objectiveId`** from **`201`**); **`info.description`** maps Swift **`IdeaController`** / **`ObjectiveController`** and notes **`AuthController`** (Supabase-only) and **`IdeaSearchController`** (no HTTP yet).

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

**Area:** Backend observability — non-database errors.  
**Purpose:** Single place to log API/HTTP-layer failures that are not Prisma-related.  
**Contents:** **`logApiError(error, context)`** prints **`[api:…]`** blocks for **`Error`** instances or unknown values; used by **`index.ts`** global handler (when **`isPrismaError`** is false) and **`auth.middleware`**.

---

### `backend/e2e/auth.e2e.test.ts`

**Area:** Backend — Jest E2E.  
**Purpose:** Exercise real **Supabase Auth** flows that mirror the Swift **`AuthController`** (**`signInWithPassword`**, **`signUp`**, **`resetPasswordForEmail`**, **`signOut`**).  
**Contents:** Uses **`@supabase/supabase-js`** and repo-root **`.env`** (**`SUPABASE_*`**, **`EMAIL`**, **`PASSWORD`**); disposable sign-up email.

---

### `backend/e2e/globalSetup.cjs`

**Area:** Backend — Jest E2E lifecycle.  
**Purpose:** Start **`launch_dev_build.sh --api-only`** (Docker Postgres + migrate + API) before tests, or wait on **`/health`** when **`SOLO_E2E_SKIP_STACK=1`**.  
**Contents:** Loads **`.env`**; validates required keys; spawns detached **`bash launch_dev_build.sh --api-only`** from repo root; writes **`e2e/.api-stack.pid`**; polls **`API_BASE_URL`** **`/health`**.

---

### `backend/e2e/globalTeardown.cjs`

**Area:** Backend — Jest E2E lifecycle.  
**Purpose:** Stop the API process tree started by **`globalSetup`** via **`tree-kill`** (**`SIGTERM`**).  
**Contents:** Reads **`e2e/.api-stack.pid`**; no-op when **`SOLO_E2E_SKIP_STACK=1`**.

---

### `backend/e2e/ideas.e2e.test.ts`

**Area:** Backend — Jest E2E.  
**Purpose:** Real HTTP against **`/ideas`** matching **`IdeaController`** (list, create, patch edit, patch publish toggle, delete).  
**Contents:** **`getTestAccessToken`** + **`apiFetch`**; serial tests sharing a created idea id; expects **`200/201/204`** and JSON shapes aligned with **`idea.schema`**.

---

### `backend/jest.e2e.config.cjs`

**Area:** Backend — Jest E2E.  
**Purpose:** Separate Jest config for integration tests without changing **`src`** **`tsconfig`** **`rootDir`**.  
**Contents:** **`ts-jest`** transform with inline **`tsconfig`**; **`globalSetup`** / **`globalTeardown`**; **`setupFilesAfterEnv`** **`jest.env.ts`**; **`maxWorkers: 1`**, long timeout, **`forceExit`**.

---

### `backend/e2e/jest.env.ts`

**Area:** Backend — Jest E2E.  
**Purpose:** Load repo-root **`.env`** before each test file (Jest **`cwd`** is **`backend/`**).  
**Contents:** **`dotenv.config`** on **`../.env`**.

---

### `backend/e2e/objectives.e2e.test.ts`

**Area:** Backend — Jest E2E.  
**Purpose:** Real HTTP against **`/objectives`** matching **`ObjectiveController`** (POST create, PATCH, POST complete, DELETE).  
**Contents:** Bearer token from **`getTestAccessToken`**; asserts status codes and **`is_completed`** toggle.

---

### `backend/e2e/testHelpers.ts`

**Area:** Backend — Jest E2E.  
**Purpose:** Shared **`fetch`** wrapper and Supabase sign-in for authenticated API calls.  
**Contents:** **`apiBaseURL`**, **`requireEnv`**, **`getTestAccessToken`** (**`signInWithPassword`**), **`apiFetch`** with **`Authorization: Bearer`**.

---

### `backend/src/core/auth.middleware.ts`

**Area:** Backend — HTTP auth.  
**Purpose:** Verify Supabase access tokens for protected routes.  
**Contents:** **`requireAuth`**: reads **`Authorization: Bearer`**, **`supabase.auth.getUser(token)`**, sets **`req.authUser`**; **`401`** on missing/invalid token; **`500`** only for missing env / config; **`503`** when auth request looks like a transient network failure; otherwise **`500`** generic; **`logApiError`** on thrown errors in the **`catch`** block.

---

### `backend/src/createApp.ts`

**Area:** Backend — Express application factory.  
**Purpose:** Build the JSON-enabled Express app (health + **`/ideas`** + error handler) without opening a port — reused by **`index.ts`**.  
**Contents:** **`createApp()`** returns **`express.Application`** with **`/health`**, **`app.use("/ideas", ideaRoutes)`**, **`app.use("/objectives", objectiveRoutes)`**, and the shared Prisma vs non-Prisma **`500`** handler.

---

### `backend/src/core/databaseLogger.ts`

**Area:** Backend observability — Prisma / database client errors.  
**Purpose:** Structured logging when the Postgres path fails via Prisma.  
**Contents:** **`getPrismaCodeDescription`**; **`isPrismaError`** (type guard); **`logDatabaseError(error, context)`** for Prisma only (known request, init, validation, unknown, rust panic); repositories and scripts should call this on ORM failures; global handler uses it when **`next(err)`** receives a Prisma error.

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

### `backend/src/modules/ideas/idea.controller.ts`

**Area:** Backend — ideas HTTP handlers.  
**Purpose:** Validate query params, call service, set status codes, format JSON for the client.  
**Contents:** **`listIdeas`**, **`createNewIdea`**, **`updateIdea`**, **`deleteIdea`**; param validation via **`ideaIdParamsSchema`**; body validation via **`ideaCreateBodySchema`** / **`ideaUpdateBodySchema`**; **`toIdeaResponseBody`** + **`ideaResponseBodySchema.parse`** for JSON bodies; statuses **`200`** (list / update), **`201`** (create), **`204`** (delete), **`404`** when id missing or not owned; **`req.authUser!.id`**; **`next(error)`** on failure.

---

### `backend/src/modules/ideas/idea.repository.ts`

**Area:** Backend — ideas persistence.  
**Purpose:** Prisma-only access for ideas.  
**Contents:** **`findIdeasForUser`**: **`findMany`** by **`userId`**, **`sort`** → **`orderBy`**, optional **`q`**; **`createIdeaForUser`**: **`create`**; **`updateIdeaForUser`**: **`update`** by **`id`** + **`userId`** (optional **`isPublished`** in body when present), **`null`** on **`P2025`**; **`deleteIdeaForUser`**: **`deleteMany`** by **`id`** + **`userId`**, returns whether a row was removed; **`logDatabaseError`** on unexpected Prisma failures for update/delete.

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

### `backend/src/routes/idea.routes.ts`

**Area:** Backend — ideas routes.  
**Purpose:** Register ideas paths and apply auth to the whole router.  
**Contents:** **`Router`** with **`requireAuth`** then **`GET /`** → **`listIdeas`**, **`POST /`** → **`createNewIdea`**, **`PATCH /:id`** and **`PUT /:id`** → **`updateIdea`**, **`DELETE /:id`** → **`deleteIdea`** (mounted at **`/ideas`** in **`index.ts`** → **`/ideas/{id}`** for by-id routes).

---

### `backend/src/modules/objectives/objective.controller.ts`

**Area:** Backend — objectives HTTP handlers.  
**Purpose:** Zod validate bodies and params, call service, return **`ObjectiveResponseBody`** (snake_case JSON) or **`204`**.  
**Contents:** **`addObjective`** (**`POST /`**), **`modifyObjective`** (**`PATCH /:id`**, text only), **`completeObjective`** (**`POST /:id/complete`**, flips completion), **`removeObjective`** (**`DELETE /:id`**); **`404`** if not found / not owned.

---

### `backend/src/modules/objectives/objective.repository.ts`

**Area:** Backend — objectives persistence.  
**Purpose:** Prisma only for **`Objective`**.  
**Contents:** **`createObjectiveForUser`**, **`updateObjectiveTextForUser`**, **`toggleObjectiveCompleteForUser`** (transaction: read + flip), **`deleteObjectiveForUser`**; **`logDatabaseError`** on unexpected errors.

---

### `backend/src/modules/objectives/objective.schema.ts`

**Area:** Backend — objectives validation.  
**Purpose:** Zod for **`/objectives`** create/update and response shape.  
**Contents:** **`objectiveIdParamsSchema`**; **`objectiveCreateBodySchema`**, **`objectiveUpdateBodySchema`**; **`objectiveResponseBodySchema`** ( **`id`**, **`text`**, **`is_completed`** ).

---

### `backend/src/modules/objectives/objective.service.ts`

**Area:** Backend — objectives orchestration.  
**Purpose:** Map HTTP-validated data to repository calls.  
**Contents:** **`createObjectiveForUser`**, **`updateObjectiveForUser`**, **`toggleCompleteForUser`**, **`deleteObjectiveForUser`**.

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

### `backend/prisma/migrations/migration_lock.toml`

**Area:** Database / Prisma.  
**Purpose:** Locks migration provider to PostgreSQL for `prisma migrate`.  
**Contents:** `provider = "postgresql"`.

---

### `backend/package.json`

**Area:** Node API package.  
**Purpose:** Backend dependencies and scripts (`build`, `start`, Prisma).  
**Contents:** Declares `express`, `@prisma/client`, `@supabase/supabase-js`, `dotenv`, `zod`, `prisma`, TypeScript; devDependencies **`jest`**, **`ts-jest`**, **`@types/jest`**, **`tree-kill`**; scripts **`clean`** (remove **`dist/`**), **`build`** (`clean` + `prisma generate` + **`tsc -p tsconfig.json`**), **`start`** (`node dist/index.js`), Prisma **`db:migrate`** / **`db:push`**, **`token`** (prints Supabase JWT from repo **`.env`**), **`test:e2e`** (Jest **`jest.e2e.config.cjs`** — Docker stack + real API + Supabase Auth).

---

### `backend/scripts/print-supabase-token.cjs`

**Area:** Backend — local dev helper.  
**Purpose:** Print a Supabase access token for Postman or **`curl`** without fragile one-line shell escaping.  
**Contents:** Reads repo-root **`.env`** (**`SUPABASE_URL`**, **`SUPABASE_ANON_KEY`**, **`EMAIL`**, **`PASSWORD`**); **`@supabase/supabase-js`** **`signInWithPassword`**; writes JWT to stdout. Run: **`npm run token --prefix backend`**.

---

### `package.json` (repo root)

**Area:** Workspace convenience.  
**Purpose:** Shortcuts to backend scripts without **`cd backend`**.  
**Contents:** **`npm run build`**, **`start`**, **`start:api`**, **`start:stack`** (Docker + migrate + API via **`launch_dev_build.sh --api-only`**) and **`npm run launch:dev`** (full **`launch_dev_build.sh`**: also **`xcodebuild`** + **`Solo.app`**; quit app tears down); **`token`** prints a Supabase JWT via **`backend`** **`token`** script; **`test:e2e`** runs **`backend`** Jest E2E suite.

---

### `backend/src/core/prisma.ts`

**Area:** Database — Prisma client singleton.  
**Purpose:** Export a single **`PrismaClient`** for the app process.  
**Contents:** `export const prisma = new PrismaClient()`; connection uses **`DATABASE_URL`** from `schema.prisma`’s env.

---

### `backend/src/core/systemLogger.ts`

**Area:** Backend observability — system / process errors.  
**Purpose:** Single place to log failures outside HTTP request handling (startup, shutdown, timers, global handlers) without conflating them with **`[api:…]`** or Prisma.  
**Contents:** **`logSystemError(error, context)`** prints **`[system:…]`** blocks with optional stack; **`SystemLogger.error`** alias; callers use **`apiLogger`** / **`databaseLogger`** for request-scoped or ORM errors.

---

### `.cursor/rules/backend-layers.mdc`

**Area:** Cursor / AI rules — backend layering.  
**Purpose:** Pin **`controller`** vs **`service`** vs **`repository`** responsibilities (Zod + HTTP in controller; orchestration in service; ORM only in repository).  
**Contents:** Required pipeline; **`logDatabaseError`** at repository boundary.

---

### `.cursor/rules/project.mdc`

**Area:** Project-wide Cursor / AI rules.  
**Purpose:** Defines stack conventions (Swift client, TypeScript API, Docker, Supabase, env var names, layered architecture for routes → controller → service → repository, Zod validation).  
**Contents:** Non-code policy; guides how features should be structured, what not to hardcode, and that repositories / any Prisma-using code should call **`databaseLogger`** (`logDatabaseError`, etc.) on DB failures.

---

### `backend/prisma/schema.prisma`

**Area:** Database / Prisma ORM.  
**Purpose:** Defines **`User`** and **`Idea`** models and `DATABASE_URL` datasource.  
**Contents:** `generator client`, `datasource db`, **`User`** (users table); **`Idea`**, **`Objective`** ( **`user_id`** = Supabase auth id, **`text`**, **`is_completed`**, timestamps); table mappings.

---

### `.vscode/settings.json`

**Area:** Editor tooling.  
**Purpose:** VS Code / Cursor TypeScript workspace settings.  
**Contents:** Points **`typescript.tsdk`** at **`backend/node_modules/typescript`** so the IDE resolves types (e.g. Prisma) consistently with the backend; **`files.exclude`** / **`search.exclude`** hide **`backend/dist`** so stale compiled JS does not clutter search or Problems.

---

### `frontend/lib/core/constants/background_design_constants.swift`

**Area:** Swift — mind map canvas background.  
**Purpose:** Stable enum values for **`CanvasModel.backgroundDesign`**.  
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

`backend/src/modules/` may contain other feature folders (**`ai`**, **`mindmaps`**, **`nodes`**, **`workshop`**, **`core`**) reserved for future code; **`ideas`** has **`idea.controller.ts`**, **`idea.repository.ts`**, **`idea.schema.ts`**, **`idea.service.ts`**; **`objectives`** has **`objective.controller.ts`**, **`objective.repository.ts`**, **`objective.schema.ts`**, **`objective.service.ts`**. The former **`auth`** module was removed (client auth uses Supabase only). Add entries here when files land.
