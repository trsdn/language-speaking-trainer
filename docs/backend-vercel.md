# Vercel backend (ephemeral token minting)

This repo includes a minimal Vercel backend to mint **ephemeral Realtime client secrets** for client-side WebRTC.

## Why

- The iOS app must **not** embed a standard OpenAI API key.
- The backend uses `OPENAI_API_KEY` server-side to call:
  - `POST https://api.openai.com/v1/realtime/client_secrets`

## Endpoints

- `GET /api/health` → `{ ok: true }`
- `GET /api/realtime/token?topic=Space` → `{ value, expires_at, session }`
  - **Authentication required**: Include `X-Token-Service-Secret` header or `Authorization: Bearer <secret>` header with the shared secret.
  - Returns `401 Unauthorized` if secret is missing or invalid.

## Environment variables

Create `.env` (or configure Vercel Project Env Vars):

- `OPENAI_API_KEY` (required)
- `TOKEN_SERVICE_SHARED_SECRET` (required) — shared secret for authentication between iOS app and backend. Generate a strong random secret using `openssl rand -base64 32`.
- `REALTIME_EPHEMERAL_TTL_SECONDS` (optional, default 600)
- `REALTIME_VOICE` (optional, default `alloy`)
- `REALTIME_TOKEN_RPM` (optional, default 30) — best-effort per-instance rate limit

## Run locally (Vercel CLI)

If you don't have the `vercel` binary on your PATH, you can still use it via `npx vercel`.

Typical local flow:

1. Ensure `.env` contains a valid `OPENAI_API_KEY` (the token endpoint will return an OpenAI error if it's missing/invalid).
2. Link the folder to a Vercel project (important if your folder name contains spaces, because Vercel project names must be lowercase and cannot contain spaces):
  Link to an existing project name like `language-speaking-trainer`.
3. Start local dev with `vercel dev` and test:
  `GET http://127.0.0.1:3000/api/health`
  `GET http://127.0.0.1:3000/api/realtime/token?topic=Space`

## iOS configuration

In the iOS app `Info.plist`, set:

- `TOKEN_SERVICE_BASE_URL` to your Vercel deployment URL (e.g. `https://your-vercel-app.vercel.app`).
- `TOKEN_SERVICE_SHARED_SECRET` to the same shared secret configured in the backend's `TOKEN_SERVICE_SHARED_SECRET` env var.
