# Gemini Live API (Gemini 2.5 Flash) – iOS notes

This project adds experimental support for **Gemini Live** as an alternative realtime backend.

## Official documentation

- Live API (overview / get started): [ai.google.dev/gemini-api/docs/live](https://ai.google.dev/gemini-api/docs/live)
- Live API WebSockets reference (message schema): [ai.google.dev/api/live](https://ai.google.dev/api/live)

## Transport choice

The direct Gemini Live API is documented as a **WebSockets** protocol. WebRTC is referenced as a possibility via partner integrations, not as the canonical first-party endpoint.

## Audio formats

- **Input**: uncompressed **16-bit PCM little-endian**. Declare the sample rate in the MIME type, e.g. `audio/pcm;rate=44100`.
- **Output**: **24 kHz** 16-bit PCM little-endian.

## Security

For broad distribution, Google recommends using **ephemeral / one-time auth tokens** instead of shipping a long-lived API key in a client app.

For development/personal use, the iOS app supports BYOK storage in Keychain via **Settings → Realtime provider → Gemini Live**.
