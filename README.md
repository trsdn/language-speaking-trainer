# Language Speaking Trainer

Native iOS (SwiftUI) app for a kids-friendly English speaking trainer.

## What’s in this repo

- `features/` — BDD/Gherkin acceptance criteria (scenario IDs like `@SE-001`).
- `ios/` — native iOS implementation scaffold (SwiftUI).
- `api/` — Vercel serverless functions (ephemeral token minting).

## iOS app status

Implemented UI flows matching MVP BDD:

- Onboarding: `@ON-001..@ON-003`
- Home/topic selection: `@HO-001..@HO-005`
- Session UI: `@SE-001` + `@SE-004` + `@SE-005`
- Privacy: `@DA-001` (no long-term raw audio storage — nothing is persisted)

Not implemented yet:

- OpenAI Realtime WebRTC connection (currently mocked)

## Backend

See `docs/backend-vercel.md`.

## Run locally

You need **Xcode** installed.

See `ios/README.md` for the quickest way to open and run the app.

