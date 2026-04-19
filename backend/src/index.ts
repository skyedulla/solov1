import path from "node:path";

import { config as loadEnv } from "dotenv";
import express from "express";

import { authRoutes } from "./routes/auth.routes";

loadEnv({ path: path.resolve(__dirname, "../../.env") });

const app = express();
app.use(express.json());

/** Confirms this process is the SOLO API (use before debugging 404s from another server on the same port). */
app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true, service: "solo-api" });
});

app.use("/auth", authRoutes);

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`API listening on ${port}`);
});
