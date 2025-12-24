# Vercel backend (ephemeral token minting)

This repo includes a minimal Vercel backend to mint **ephemeral Realtime client secrets** for client-side WebRTC.

## Why

- The iOS app must **not** embed a standard OpenAI API key.
- The backend uses `OPENAI_API_KEY` server-side to call:
  - `POST https://api.openai.com/v1/realtime/client_secrets`

## Endpoints

- `GET /api/health` → `{ ok: true }`
- `GET /api/realtime/token?topic=Space` → `{ value, expires_at, session }`

## Environment variables

Create `.env` (or configure Vercel Project Env Vars):

- `OPENAI_API_KEY` (required)
- `REALTIME_EPHEMERAL_TTL_SECONDS` (optional, default 600)
- `REALTIME_VOICE` (optional, default `alloy`)
- `REALTIME_TOKEN_RPM` (optional, default 30) — best-effort per-instance rate limit

## iOS configuration

In the iOS app `Info.plist`, set:

- `TOKEN_SERVICE_BASE_URL` to your Vercel deployment URL (e.g. `https://your-vercel-app.vercel.app`).
