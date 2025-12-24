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

1. Create a new Xcode project (iOS → App) named `LanguageSpeakingTrainer`.
2. Set the deployment target to iOS 17+ (recommended).
3. Copy the Swift files from `ios/LanguageSpeakingTrainer/` into the Xcode target.
4. Ensure your app `Info.plist` contains `NSMicrophoneUsageDescription` (see template below).

Template value suggestion:

- `NSMicrophoneUsageDescription`: "We use the microphone so you can practice speaking English with your virtual teacher."

Optional (for later Realtime token minting):

- `TOKEN_SERVICE_BASE_URL`: `https://your-vercel-app.vercel.app`

## Next steps

- Add Vercel token endpoint config + fetch.
- Implement OpenAI Realtime WebRTC connection.
- Replace mock teacher messages with realtime audio + transcripts.

## WebRTC (SwiftPM)

See `docs/ios-webrtc-swiftpm.md`.
