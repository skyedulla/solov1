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
**Purpose:** App-facing API for login/sign-up via **Supabase Auth**.  
**Contents:** **`login(model:)`** → **`supabase.auth.signIn(email:password:)`** (returns **`Session`**); **`signUp(model:)`** → **`supabase.auth.signUp`** with **`first_name` / `last_name`** metadata (returns **`AuthResponse`**).

---

### `frontend/lib/features/auth/models/AuthModel.swift`

**Area:** Swift shared model.  
**Purpose:** Sign-up / login field bundle for **`AuthController`**.  
**Contents:** **`Codable`** struct: **`firstName`**, **`lastName`**, **`email`**, **`password`** (metadata fields passed to Supabase on sign-up).

---

### `frontend/Package.swift`

**Area:** Swift Package / smoke test harness.  
**Purpose:** Defines executable **`solo-auth-smoke`**, SPM dependencies, and sources under **`lib/`**.  
**Contents:** SwiftPM manifest; depends on **`supabase-swift`** (**`Supabase`** product); Swift tools 5.10+.

---

### `backend/postman/SOLO-auth.postman_collection.json`

**Area:** API testing (Postman).  
**Purpose:** Importable collection for manual HTTP checks.  
**Contents:** `GET /health`, `POST /auth/signup`, `POST /auth/login` with variable **`baseUrl`** (collection default `http://localhost:4000`; set it to match your API **`PORT`**, e.g. `http://localhost:3000` if using the server default).

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

### `backend/src/modules/auth/auth.controller.ts`

**Area:** Auth HTTP layer.  
**Purpose:** Map requests to `authService` and HTTP responses (no hashing).  
**Contents:** **`login`** / **`signUp`** handlers: **`loginSchema`** / **`authModelSchema`** `safeParse` on **`req.body`** → 400 on validation failure; 200/401 for login; 201/409 for signup; JSON **`user`** payloads without secrets.

---

### `backend/src/modules/auth/auth.repository.ts`

**Area:** Auth persistence.  
**Purpose:** Prisma-only access to **`users`**; map **`P2002`** to **`DuplicateEmailError`**.  
**Contents:** **`findUserByEmail`**, **`createUser`**; on failure calls **`logDatabaseError`** then rethrows or maps duplicate email.

---

### `backend/src/routes/auth.routes.ts`

**Area:** HTTP routing.  
**Purpose:** Wire **`/login`** and **`/signup`** under the **`/auth`** mount.  
**Contents:** Express **`Router`**; **`POST /login`** → **`authController.login`**; **`POST /signup`** → **`authController.signUp`**.

---

### `backend/src/modules/auth/auth.schema.ts`

**Area:** Auth validation (Zod).  
**Purpose:** Shared shapes for login and sign-up bodies (aligned with Swift **`AuthModel`**).  
**Contents:** **`authModelSchema`** (firstName, lastName, email, password rules); **`loginSchema`** (email + password); exported TypeScript types **`AuthModel`**, **`LoginInput`**, **`SignUpInput`**.

---

### `backend/src/modules/auth/auth.service.ts`

**Area:** Auth business logic.  
**Purpose:** Password hashing (`bcrypt`), credential verification, orchestration of **`authRepository`**.  
**Contents:** **`login`** / **`signUp`** return **`PublicUser`**-style results or failure reasons; never returns password hashes to callers.

---

### `backend/src/core/databaseLogger.ts`

**Area:** Backend observability — database errors.  
**Purpose:** Central logging for Prisma failures (terminal + structured text).  
**Contents:** Maps Prisma error codes (and inferred codes for init errors) to short descriptions; **`logDatabaseError(error, context)`** used from repositories; handles known, initialization, validation, unknown, and rust-panic errors.

---

### `docker-compose.yml`

**Area:** Local infrastructure.  
**Purpose:** Run PostgreSQL for development.  
**Contents:** **`postgres:16-alpine`** service **`solo-postgres-dev`**, env **`POSTGRES_*`**, host port mapping **`5434:5432`** (avoids clash with a local Postgres on 5432), named volume **`solo_pgdata`**.

---

### `backend/src/index.ts`

**Area:** API entrypoint.  
**Purpose:** Boot Express, load `.env` from repo root, mount JSON body parser and routes.  
**Contents:** `dotenv` path resolution; **`GET /health`** for liveness; **`app.use("/auth", authRoutes)`**; listens on **`PORT`** (default 3000).

---

### `backend/prisma/migrations/20250418180000_init_users/migration.sql`

**Area:** Database / Prisma.  
**Purpose:** Initial SQL migration for the **`users`** table.  
**Contents:** `CREATE TABLE users` with columns matching `User` in `schema.prisma` (snake_case in DB, mapped in Prisma).

---

### `backend/prisma/migrations/migration_lock.toml`

**Area:** Database / Prisma.  
**Purpose:** Locks migration provider to PostgreSQL for `prisma migrate`.  
**Contents:** `provider = "postgresql"`.

---

### `backend/package.json`

**Area:** Node API package.  
**Purpose:** Backend dependencies and scripts (`build`, `start`, Prisma).  
**Contents:** Declares `express`, `zod`, `@prisma/client`, `bcrypt`, `dotenv`, `prisma`, TypeScript; scripts run `prisma generate` + `tsc` and `node dist/index.js`.

---

### `package.json` (repo root)

**Area:** Workspace convenience.  
**Purpose:** Shortcuts to backend scripts without **`cd backend`**.  
**Contents:** **`npm run build`**, **`start`**, **`start:api`** delegate to **`--prefix backend`**.

---

### `backend/src/core/prisma.ts`

**Area:** Database — Prisma client singleton.  
**Purpose:** Export a single **`PrismaClient`** for the app process.  
**Contents:** `export const prisma = new PrismaClient()`; connection uses **`DATABASE_URL`** from `schema.prisma`’s env.

---

### `.cursor/rules/project.mdc`

**Area:** Project-wide Cursor / AI rules.  
**Purpose:** Defines stack conventions (Swift client, TypeScript API, Docker, Supabase, env var names, layered architecture for routes → controller → service → repository, Zod validation).  
**Contents:** Non-code policy; guides how features should be structured and what not to hardcode.

---

### `backend/prisma/schema.prisma`

**Area:** Database / Prisma ORM.  
**Purpose:** Defines the **`User`** model and `DATABASE_URL` datasource.  
**Contents:** `generator client`, `datasource db`, `User` fields (`id`, `email`, `passwordHash`, `firstName`, `lastName`, timestamps); table mapped to **`users`**.

---

### `.vscode/settings.json`

**Area:** Editor tooling.  
**Purpose:** VS Code / Cursor TypeScript workspace settings.  
**Contents:** Points **`typescript.tsdk`** at **`backend/node_modules/typescript`** so the IDE resolves types (e.g. Prisma) consistently with the backend.

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

`backend/src/modules/` may contain other feature folders (**`ai`**, **`ideas`**, **`mindmaps`**, **`nodes`**, **`workshop`**, **`core`**) reserved for future code; add entries here when files land.
