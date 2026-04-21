# SOLO codebase index

Inventory of meaningful project files, ordered **alphabetically by file name** (last path segment), using **ASCII / byte order** (e.g. uppercase letters before lowercase). When two files share a name, the **full path** breaks the tie. **Update this document** whenever you add, remove, or meaningfully change a tracked file (see `.cursor/rules/codebase-index.mdc`).

---

### `.env` (repo root; do not commit secrets)

**Area:** Local / deployment configuration.  
**Purpose:** Single place for `SUPABASE_*`, `API_BASE_URL`, `PORT`, `DATABASE_URL`, `OPENAI_API_KEY`, etc.  
**Contents:** Key–value env vars; **backend** loads this via `dotenv` in `src/index.ts`. Swift reads **mirrored** values (including **`SUPABASE_URL`** / **`SUPABASE_ANON_KEY`**) via scheme / Info.plist for the Supabase client, not this file at runtime on device when unset.

---

### `.gitignore` (repo root)

**Area:** Git / hygiene.  
**Purpose:** Keep secrets and generated artifacts out of version control.  
**Contents:** Ignores **`.env`**, **`node_modules/`**, **`backend/dist/`**, **`frontend/.build/`**, common logs and OS junk.

---

### `frontend/lib/core/config/AppConfiguration.swift`

**Area:** Swift client configuration.  
**Purpose:** Resolve **`API_BASE_URL`**, **`SUPABASE_URL`**, and **`SUPABASE_ANON_KEY`** without hardcoding in source.  
**Contents:** Reads each from **`ProcessInfo`** environment or **`Info.plist`** (same keys as `.env`); **`preconditionFailure`** if any required value is missing.

---

### `frontend/lib/features/auth/controllers/AuthController.swift`

**Area:** Swift auth coordination.  
**Purpose:** App-facing API for login/sign-up, password reset, and logout via **Supabase Auth**.  
**Contents:** **`login(model:)`** → **`signIn`** (**`Session`**); **`signUp(model:)`** → **`signUp`** with **`first_name` / `last_name`** (**`AuthResponse`**); **`resetPassword(email:redirectTo:)`** → **`resetPasswordForEmail`**; **`logout()`** → **`signOut`**.

---

### `frontend/lib/features/auth/models/AuthModel.swift`

**Area:** Swift shared model.  
**Purpose:** Sign-up / login field bundle for **`AuthController`**.  
**Contents:** **`Codable`** struct: **`firstName`**, **`lastName`**, **`email`**, **`password`** (metadata fields passed to Supabase on sign-up).

---

### `frontend/lib/features/ideas/controllers/IdeaController.swift`

**Area:** Swift — ideas coordination.  
**Purpose:** Orchestrates idea CRUD and related flows; future **`URLSession`** / repository I/O lives behind this type.  
**Contents:** **`final class IdeaController`**: injectable **`IdeasRemoteDataSource`**; **`fetchIdeas(using:accessToken:)`** → **`[IdeaModel]`**; **`createNewIdea(title:purpose:description:targetUser:accessToken:)`** → **`IdeaModel`** (decode single-object **`POST`** response).

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
**Contents:** **`IdeasRemoteDataSource`**: **`fetchIdeas(filter:accessToken:)`** → **`GET …/ideas`**; **`createNewIdea(title:purpose:description:targetUser:accessToken:)`** → **`POST …/ideas`** with JSON body; both use **`Authorization: Bearer`**; return raw **`(Data, URLResponse)`** only.

---

### `frontend/Package.swift`

**Area:** Swift Package / smoke test harness.  
**Purpose:** Defines executable **`solo-auth-smoke`**, SPM dependencies, and sources under **`lib/`**.  
**Contents:** SwiftPM manifest; depends on **`supabase-swift`** (**`Supabase`** product); Swift tools 5.10+.

---

### `backend/postman/SOLO-auth.postman_collection.json`

**Area:** API testing (Postman).  
**Purpose:** Importable collection for manual HTTP checks.  
**Contents:** Collection vars **`baseUrl`** (default **`http://localhost:3000`**) and **`accessToken`** (Supabase JWT for protected routes); **`GET /health`**; Ideas folder — **`GET /ideas`** (list / `fetchIdeas`, query **`sort`**, **`q`**, **`Authorization: Bearer`**), **`POST /ideas`** (create / **`createNewIdea`**, JSON body **`title`** / **`purpose`** + optional fields).

---

### `frontend/lib/smoke/SoloAuthSmoke.swift`

**Area:** CLI smoke test.  
**Purpose:** End-to-end check of **`AuthController.signUp`** against **Supabase Auth**.  
**Contents:** **`@main`** builds a random email, calls **`signUp`**, prints **`SUPABASE_URL`** and result (**`AuthResponse`** session vs user).

---

### `frontend/lib/features/auth/supabase/SupabaseClientProvider.swift`

**Area:** Swift — Supabase client wiring.  
**Purpose:** Single **`SupabaseClient`** configured from **`AppConfiguration`**.  
**Contents:** **`SupabaseClientProvider.shared`** lazy client using **`SUPABASE_URL`** + **`SUPABASE_ANON_KEY`**; imported by **`AuthController`**.

---

### `backend/src/core/apiLogger.ts`

**Area:** Backend observability — non-database errors.  
**Purpose:** Single place to log API/HTTP-layer failures that are not Prisma-related.  
**Contents:** **`logApiError(error, context)`** prints **`[api:…]`** blocks for **`Error`** instances or unknown values; used by **`index.ts`** global handler (when **`isPrismaError`** is false) and **`auth.middleware`**.

---

### `backend/src/core/auth.middleware.ts`

**Area:** Backend — HTTP auth.  
**Purpose:** Verify Supabase access tokens for protected routes.  
**Contents:** **`requireAuth`**: reads **`Authorization: Bearer`**, **`supabase.auth.getUser(token)`**, sets **`req.authUser`**; **`401`** on missing/invalid token; **`500`** only for missing env / config; **`503`** when auth request looks like a transient network failure; otherwise **`500`** generic; **`logApiError`** on thrown errors in the **`catch`** block.

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
**Purpose:** Boot Express, load `.env` from repo root, mount JSON body parser.  
**Contents:** `dotenv` path resolution; comment to run **`prisma migrate deploy`** before relying on DB-backed routes; **`GET /health`** for liveness; **`app.use("/ideas", ideaRoutes)`**; global **`500`** JSON error handler that routes **`logDatabaseError`** vs **`logApiError`** via **`isPrismaError`**; listens on **`PORT`** (default 3000).

---

### `backend/src/modules/ideas/idea.controller.ts`

**Area:** Backend — ideas HTTP handlers.  
**Purpose:** Validate query params, call service, set status codes, format JSON for the client.  
**Contents:** **`listIdeas`**: **`listIdeasQuerySchema.safeParse`**, **`400`** on invalid query; **`createNewIdea`**: **`ideaCreateBodySchema.safeParse`**, **`400`** on invalid body; **`toIdeaResponseBody`** + **`ideaResponseBodySchema.parse`**; **`200`** JSON array / **`201`** JSON object; **`req.authUser!.id`** (router uses **`requireAuth`**); **`next(error)`** on failure.

---

### `backend/src/modules/ideas/idea.repository.ts`

**Area:** Backend — ideas persistence.  
**Purpose:** Prisma-only access for ideas.  
**Contents:** **`findIdeasForUser`**: **`findMany`** by **`userId`** (Supabase id), **`sort`** → **`orderBy`**, optional **`q`** text filter; **`createIdeaForUser`**: **`create`** with scoped **`userId`** (errors propagate to the global handler / **`logDatabaseError`** when Prisma-related).

---

### `backend/src/modules/ideas/idea.schema.ts`

**Area:** Backend — ideas validation.  
**Purpose:** Zod schemas aligned with Prisma **`Idea`**, Swift **`IdeaModel`**, and API wire JSON.  
**Contents:** **`listIdeasQuerySchema`**; **`ideaCreateBodySchema`** / **`IdeaCreateBody`** (**`POST /ideas`**: required **`title`** / **`purpose`**, optional **`description`** / **`targetUser`** with defaults); **`ideaResponseBodySchema`** + **`IdeaResponseBody`** (outbound snake_case JSON aligned with Swift **`IdeaModel`**).

---

### `backend/src/modules/ideas/idea.service.ts`

**Area:** Backend — ideas domain orchestration.  
**Purpose:** Business-facing entry for listing ideas (extend with cross-domain / external calls later).  
**Contents:** **`toRepositoryListParams`** maps **`ListIdeasQuery`** → repository args; **`listIdeasForUser`** → **`idea.repository.findIdeasForUser`**; **`createIdeaForUser`** → **`idea.repository.createIdeaForUser`**.

---

### `backend/src/routes/idea.routes.ts`

**Area:** Backend — ideas routes.  
**Purpose:** Register ideas paths and apply auth to the whole router.  
**Contents:** **`Router`** with **`requireAuth`** then **`GET /`** → **`listIdeas`**, **`POST /`** → **`createNewIdea`** (mounted at **`/ideas`** in **`index.ts`**).

---

### `backend/src/types/express.d.ts`

**Area:** Backend — TypeScript.  
**Purpose:** Augment **`Express.Request`** with **`authUser`**.  
**Contents:** Global **`Express`** namespace merge; **`authUser?: User`** (**`@supabase/supabase-js`**).

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

### `backend/prisma/migrations/migration_lock.toml`

**Area:** Database / Prisma.  
**Purpose:** Locks migration provider to PostgreSQL for `prisma migrate`.  
**Contents:** `provider = "postgresql"`.

---

### `backend/package.json`

**Area:** Node API package.  
**Purpose:** Backend dependencies and scripts (`build`, `start`, Prisma).  
**Contents:** Declares `express`, `@prisma/client`, `@supabase/supabase-js`, `dotenv`, `zod`, `prisma`, TypeScript; scripts run `prisma generate` + `tsc` and `node dist/index.js`.

---

### `package.json` (repo root)

**Area:** Workspace convenience.  
**Purpose:** Shortcuts to backend scripts without **`cd backend`**.  
**Contents:** **`npm run build`**, **`start`**, **`start:api`**, **`start:stack`** delegate to **`--prefix backend`** or run **`start-api-stack.sh`**.

---

### `backend/src/core/prisma.ts`

**Area:** Database — Prisma client singleton.  
**Purpose:** Export a single **`PrismaClient`** for the app process.  
**Contents:** `export const prisma = new PrismaClient()`; connection uses **`DATABASE_URL`** from `schema.prisma`’s env.

---

### `start-api-stack.sh` (repo root)

**Area:** Local development workflow.  
**Purpose:** One command to bring up Docker **Postgres** and the **API** (matches **`DATABASE_URL`** on **`localhost:5434`**).  
**Contents:** Requires Docker; **`docker compose up -d postgres`**; waits on **`pg_isready`**; then **`exec npm run start:api`** (build + **`node dist/index.js`**). Same as **`npm run start:stack`**.

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
**Contents:** `generator client`, `datasource db`, **`User`** (users table); **`Idea`** ( **`user_id`** = Supabase auth id, content fields, timestamps); **`ideas`** table mapping.

---

### `.vscode/settings.json`

**Area:** Editor tooling.  
**Purpose:** VS Code / Cursor TypeScript workspace settings.  
**Contents:** Points **`typescript.tsdk`** at **`backend/node_modules/typescript`** so the IDE resolves types (e.g. Prisma) consistently with the backend.

---

### `frontend/lib/core/constants/sort_by_constants.swift`

**Area:** Swift — ideas list sorting.  
**Purpose:** Pair UI labels with API sort parameter values for **`sortBy`**.  
**Contents:** **`SortByConstants`** enum; **`options`** is an array of **`[String: String]`** dicts with keys **`label`** (display) and **`value`** (API token, e.g. **`title_asc`**, **`created_desc`**).

---

### `backend/tsconfig.json`

**Area:** TypeScript tooling.  
**Purpose:** Compile **`backend/src`** → **`backend/dist`**.  
**Contents:** `strict`, `rootDir`/`outDir`, CommonJS module settings.

---

### `tsconfig.json` (repo root)

**Area:** Editor / TypeScript project.  
**Purpose:** Lets IDE typecheck **`backend/src`** when workspace root is **`SOLO`**.  
**Contents:** **`include`**: `backend/src/**/*.ts`; **`noEmit`**: true; aligns with resolving **`@prisma/client`** from **`backend/node_modules`**.

---

## Excluded from this index (by design)

- **`backend/dist/`** — compiled output; regenerate with **`npm run build`**.
- **`backend/node_modules/`** — dependencies.
- **`frontend/.build/`** — SwiftPM build artifacts.
- **`package-lock.json`** — lockfile; regenerate with **`npm install`**.

---

## Module placeholders (empty folders)

`backend/src/modules/` may contain other feature folders (**`ai`**, **`mindmaps`**, **`nodes`**, **`workshop`**, **`core`**) reserved for future code; **`ideas`** has **`idea.controller.ts`**, **`idea.repository.ts`**, **`idea.schema.ts`**, **`idea.service.ts`**. The former **`auth`** module was removed (client auth uses Supabase only). Add entries here when files land.
