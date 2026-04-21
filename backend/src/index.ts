import path from "node:path";

import { config as loadEnv } from "dotenv";

import { createApp } from "./createApp";

loadEnv({ path: path.resolve(__dirname, "../../.env") });

// Before using persisted routes (e.g. `GET /ideas`), apply migrations: `cd backend && npx prisma migrate deploy` (or `npm run db:migrate` in development).

const app = createApp();

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`API listening on ${port}`);
});
