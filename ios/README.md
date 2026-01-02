# iOS app (native)

This folder contains the native iOS (SwiftUI) implementation for **Language Speaking Trainer**.

## Status

- SwiftUI app skeleton is implemented (onboarding → home → session).
- Microphone permission + local mic level monitoring (for the “mic activity animation” requirement) is included.
- OpenAI Realtime (WebRTC) is **not fully wired yet**.
  - The app mints ephemeral Realtime client secrets **directly from OpenAI** when an API key is configured.
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

Realtime token minting: **BYOK (Bring Your Own Key)**

- You can enter an **OpenAI API key directly in the app** under **Settings → OpenAI (BYOK)**.
- The key is stored in the **Keychain** and is **write-only** from the UI (it cannot be displayed again after saving).
- With a BYOK key set, the app will mint Realtime client secrets **directly from OpenAI**.

How to set this (recommended for local dev):

1. Run the app.
2. Open **Settings**.
3. Under **OpenAI (BYOK)**, paste your OpenAI API key and tap **Save**.

Alternative (Xcode env var): set `OPENAI_API_KEY` as a Run environment variable.

Note: there is an older scaffold folder at `ios/LanguageSpeakingTrainer/` from before the `.xcodeproj` existed. The canonical sources going forward are the ones inside the Xcode project folder under `ios/App/...`.

## Next steps

- Implement OpenAI Realtime WebRTC connection.
- Replace mock teacher messages with realtime audio + transcripts.

## WebRTC (SwiftPM)

See `docs/ios-webrtc-swiftpm.md`.
