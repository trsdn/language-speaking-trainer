# Feature registry

This registry tracks which product features are **specified** (BDD/Gherkin) and which are **implemented** in the codebase.

It is intentionally lightweight: update it whenever you ship meaningful progress so that “what works today?” is always obvious.

## Status legend

- **Implemented**: works end-to-end in the app (manual verification done)
- **Implemented (UI only)**: UI exists, but backend/realtime behavior is not yet fully validated
- **In progress**: code exists but is incomplete or blocked on verification
- **Planned**: defined in BDD/specs, not started in code

## MVP feature map

| Area | BDD spec | Implementation entry points | Status | Notes |
| --- | --- | --- | --- | --- |
| Home & topic selection | `features/home/home.feature` | `ios/App/LanguageSpeakingTrainer/LanguageSpeakingTrainer/HomeView.swift`, `Models.swift` | Implemented | Includes preset topics, surprise topic, custom topic + empty validation. |
| First-run onboarding | `features/onboarding/onboarding.feature` | `ios/App/LanguageSpeakingTrainer/LanguageSpeakingTrainer/OnboardingView.swift`, `AppModel.swift` | Implemented | Persists onboarding completion + selected values in `UserDefaults`. |
| Settings (Realtime model) | `features/settings/settings.feature` | `ios/App/LanguageSpeakingTrainer/LanguageSpeakingTrainer/SettingsView.swift`, `AppModel.swift`, `TokenService.swift`, `api/realtime/token.js` | Implemented | UI + persistence + end-to-end usage of the selected Realtime model (including backend validation and model ID resolution). |
| Session UI (start/mute/end) | `features/session/session.feature` | `ios/App/LanguageSpeakingTrainer/LanguageSpeakingTrainer/SessionView.swift`, `SessionModel.swift`, `MicrophoneMonitor.swift` | Implemented (UI only) | UI indicators + mute/end are wired; realtime behavior depends on client backend/WebRTC verification. |
| Realtime (OpenAI WebRTC) connection | `features/session/session.feature` | `ios/App/LanguageSpeakingTrainer/LanguageSpeakingTrainer/OpenAIRealtimeWebRTCClient.swift`, `OpenAIWebRTCSession.swift`, `api/realtime/token.js` | In progress | Code is present; validate SDP exchange/ICE/data channel end-to-end. (See issue #2.) |
| Safety boundaries (child-safe teacher) | `features/safety/safety.feature` | `ios/App/LanguageSpeakingTrainer/LanguageSpeakingTrainer/SafetySystemPrompt.swift` | In progress | Implemented as a system prompt; still needs adversarial testing + monitoring for regressions. |
| Local-first data / minimal retention | `features/data/data.feature` | (No audio persistence code present) | Implemented (for @DA-001) | No long-term raw audio storage by default. Summaries + deletion flows are post-MVP. |
| Rewards & motivation | `features/rewards/rewards.feature` | — | Planned | Nice-to-have. |

## Backend capabilities

| Capability | Location | Status | Notes |
| --- | --- | --- | --- |
| Health endpoint | `api/health.js` | Implemented | Simple connectivity check. |
| Realtime ephemeral token minting | `api/realtime/token.js` | Implemented | Mints ephemeral client secret for OpenAI Realtime usage. |

## How to update this file

When you mark something **Implemented**, add a short note in the “Notes” column indicating:

- where it was verified (device vs simulator)
- the date (YYYY-MM-DD)

Example: “Verified on device (iPhone), 2025-12-24.”
