# iOS app (native)

This folder contains the native iOS (SwiftUI) implementation for **Language Speaking Trainer**.

## Status

- SwiftUI app skeleton is implemented (onboarding → home → session).
- Microphone permission + local mic level monitoring (for the “mic activity animation” requirement) is included.
- OpenAI Realtime (WebRTC) is **not fully wired yet**.
  - If `TOKEN_SERVICE_BASE_URL` is set, the app will attempt to use the realtime client and fetch an ephemeral token.
  - Actual WebRTC audio requires adding a WebRTC SDK module named `WebRTC` to the Xcode project.

## Prerequisites

You need **Xcode** installed (Command Line Tools alone is not enough).

## How to open

Open the checked-in Xcode project:

1. Open `ios/App/LanguageSpeakingTrainer/LanguageSpeakingTrainer.xcodeproj` in Xcode.
2. Set the deployment target to iOS 17+ (recommended).
3. Ensure your app target includes the SwiftUI sources under `ios/App/LanguageSpeakingTrainer/LanguageSpeakingTrainer/`.
4. Ensure your app `Info.plist` contains `NSMicrophoneUsageDescription` (see template below).

Template value suggestion:

- `NSMicrophoneUsageDescription`: "We use the microphone so you can practice speaking English with your virtual teacher."

Optional (for later Realtime token minting):

- `TOKEN_SERVICE_BASE_URL`: `https://your-vercel-app.vercel.app`
- `TOKEN_SERVICE_SHARED_SECRET`: a shared secret that the backend requires on `/api/realtime/token`

How to set these (recommended for local dev):

1. In Xcode, select the app scheme → **Edit Scheme…**
2. Run → **Arguments** → **Environment Variables**
3. Add:

- `TOKEN_SERVICE_BASE_URL` (example: `https://language-speaking-trainer.vercel.app`)
- `TOKEN_SERVICE_SHARED_SECRET` (must match the backend `TOKEN_SERVICE_SHARED_SECRET`)

Alternative: set these as **User-Defined** Build Settings on the app target (so the Info.plist entries can expand `$(TOKEN_SERVICE_BASE_URL)` and `$(TOKEN_SERVICE_SHARED_SECRET)`).

Note: This is MVP protection suitable for a single-user/private deployment. For a public app, a shipped secret can be extracted.

Note: there is an older scaffold folder at `ios/LanguageSpeakingTrainer/` from before the `.xcodeproj` existed. The canonical sources going forward are the ones inside the Xcode project folder under `ios/App/...`.

## Next steps

- Add Vercel token endpoint config + fetch.
- Implement OpenAI Realtime WebRTC connection.
- Replace mock teacher messages with realtime audio + transcripts.

## WebRTC (SwiftPM)

See `docs/ios-webrtc-swiftpm.md`.
