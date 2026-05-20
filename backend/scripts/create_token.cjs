#!/usr/bin/env node
"use strict";

/**
 * Signs in with repo-root `.env` (**`SUPABASE_URL`**, **`SUPABASE_ANON_KEY`**, **`EMAIL`**, **`PASSWORD`**)
 * and prints a Supabase access JWT (one line, no prefix) to stdout.
 *
 * From repo root: `npm run create_token`
 * From `backend/`: `npm run create_token` or `node scripts/create_token.cjs`
 */
const path = require("node:path");
const { config } = require("dotenv");
const { createClient } = require("@supabase/supabase-js");

const envPath = path.resolve(__dirname, "../../.env");
config({ path: envPath });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const email = process.env.EMAIL;
const password = process.env.PASSWORD;

function fail(message) {
  console.error(message);
  process.exit(1);
}

if (!supabaseUrl) fail("Missing SUPABASE_URL (set in repo root .env)");
if (!supabaseAnonKey) fail("Missing SUPABASE_ANON_KEY");
if (!email) fail("Missing EMAIL (dev user email for password sign-in)");
if (!password) fail("Missing PASSWORD");

async function main() {
  const supabase = createClient(supabaseUrl, supabaseAnonKey);
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) fail(`Sign-in failed: ${error.message}`);
  const token = data.session?.access_token;
  if (!token) fail("No access_token on session.");
  process.stdout.write(`${token}\n`);
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : String(err));
  process.exit(1);
});
