import Foundation

#if canImport(WebRTC)
import WebRTC
import AVFoundation

/// Minimal WebRTC session that:
/// 1) creates a peer connection
/// 2) creates an SDP offer
/// 3) POSTs offer.sdp to `POST https://api.openai.com/v1/realtime/calls` using an ephemeral key
/// 4) applies the SDP answer
/// 5) opens the `oai-events` data channel for JSON events
///
/// Notes:
/// - Audio output from the model arrives via `RTCPeerConnectionDelegate.onTrack`.
/// - By default, WebRTC audio input can start immediately once a local audio track is added.
final class OpenAIWebRTCSession: NSObject {
    private let ephemeralKey: String
    private let topic: Topic
    private let onEvent: (RealtimeEvent) -> Void

    private let factory: RTCPeerConnectionFactory
    private var pc: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?

    private var localAudioTrack: RTCAudioTrack?
    private var audioSender: RTCRtpSender?

    private var isStopped = false
    private var isMuted: Bool

    // Accumulate text deltas into a single message (best-effort).
    private var pendingText: String = ""

    init(ephemeralKey: String, topic: Topic, isMuted: Bool, onEvent: @escaping (RealtimeEvent) -> Void) {
        self.ephemeralKey = ephemeralKey
        self.topic = topic
        self.isMuted = isMuted
        self.onEvent = onEvent

        RTCInitializeSSL()
        self.factory = RTCPeerConnectionFactory()
        super.init()
    }

    deinit {
        RTCCleanupSSL()
    }

    func start() {
        onEvent(.systemNote("Starting WebRTC session…"))

        // Configure iOS audio session for WebRTC.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setMode(.voiceChat)
            try session.setActive(true)
        } catch {
            onEvent(.systemNote("Audio session setup warning: \(error.localizedDescription)"))
        }

        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually

        // NOTE: The OpenAI answer SDP includes host candidates; we generally don't need to provide custom ICE servers.
        config.iceServers = []

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: [
                "DtlsSrtpKeyAgreement": "true"
            ]
        )

        guard let pc = factory.peerConnection(with: config, constraints: constraints, delegate: self) else {
            onEvent(.systemNote("Failed to create RTCPeerConnection."))
            return
        }
        self.pc = pc

        // Local audio track (microphone)
        let audioSource = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        self.localAudioTrack = audioTrack
        self.audioSender = pc.add(audioTrack, streamIds: ["stream0"])

        // Apply initial mute
        setMuted(isMuted)

        // Data channel for JSON events
        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true
        if let dc = pc.dataChannel(forLabel: "oai-events", configuration: dcConfig) {
            dc.delegate = self
            dataChannel = dc
        } else {
            onEvent(.systemNote("Failed to create data channel."))
        }

        let offerConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true"
            ],
            optionalConstraints: nil
        )

        pc.offer(for: offerConstraints) { [weak self] offer, error in
            guard let self else { return }
            if let error {
                self.onEvent(.systemNote("Failed to create offer: \(error.localizedDescription)"))
                return
            }
            guard let offer, !self.isStopped else { return }

            pc.setLocalDescription(offer) { [weak self] error in
                guard let self else { return }
                if let error {
                    self.onEvent(.systemNote("Failed to set local description: \(error.localizedDescription)"))
                    return
                }
                guard let sdp = offer.sdp as String?, !self.isStopped else { return }
                Task { await self.exchangeSDP(offerSDP: sdp) }
            }
        }
    }

    func stop() {
        isStopped = true

        dataChannel?.delegate = nil
        dataChannel?.close()
        dataChannel = nil

        pc?.close()
        pc = nil

        localAudioTrack = nil
        audioSender = nil

        onEvent(.systemNote("WebRTC session stopped."))
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted

        // Mute by disabling the outgoing audio track.
        // (This is the WebRTC equivalent of stopping mic capture.)
        localAudioTrack?.isEnabled = !muted
    }

    private func exchangeSDP(offerSDP: String) async {
        guard !isStopped else { return }

        onEvent(.systemNote("Exchanging SDP with OpenAI…"))

        // Per WebRTC guide: POST raw SDP with Content-Type: application/sdp and Authorization: Bearer <EPHEMERAL_KEY>
        // Response body: SDP answer (text).
        guard let url = URL(string: "https://api.openai.com/v1/realtime/calls") else {
            onEvent(.systemNote("Invalid OpenAI calls URL."))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(ephemeralKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        req.httpBody = offerSDP.data(using: .utf8)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                onEvent(.systemNote("No HTTP response from OpenAI."))
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                onEvent(.systemNote("OpenAI calls failed (\(http.statusCode)): \(body)"))
                return
            }

            let answerSDP = String(data: data, encoding: .utf8) ?? ""
            if answerSDP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onEvent(.systemNote("OpenAI returned an empty SDP answer."))
                return
            }

            guard !isStopped, let pc else { return }

            let answer = RTCSessionDescription(type: .answer, sdp: answerSDP)
            pc.setRemoteDescription(answer) { [weak self] error in
                guard let self else { return }
                if let error {
                    self.onEvent(.systemNote("Failed to set remote description: \(error.localizedDescription)"))
                    return
                }

                self.onEvent(.connected)

                // Trigger a first response. The session instructions (from the ephemeral key) should cause the teacher to greet first.
                self.sendClientEvent([
                    "type": "response.create",
                    "response": [
                        "output_modalities": ["audio", "text"]
                    ]
                ])
            }
        } catch {
            onEvent(.systemNote("SDP exchange failed: \(error.localizedDescription)"))
        }
    }

    private func sendClientEvent(_ obj: [String: Any]) {
        guard let dc = dataChannel else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: []) else { return }
        guard let str = String(data: data, encoding: .utf8) else { return }
        dc.sendData(RTCDataBuffer(data: Data(str.utf8), isBinary: false))
    }

    private func handleServerEvent(_ json: [String: Any]) {
        guard let type = json["type"] as? String else { return }

        switch type {
        case "session.created":
            onEvent(.systemNote("Session created."))

        case "session.updated":
            onEvent(.systemNote("Session updated."))

        case "response.output_text.delta":
            if
                let delta = json["delta"] as? String,
                !delta.isEmpty
            {
                pendingText += delta
            }

        case "response.output_text.done":
            if !pendingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onEvent(.teacherMessage(pendingText.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
            pendingText = ""

        case "response.done":
            // Best-effort: sometimes the final transcript is only in response.done; if we have pending text, flush it.
            if !pendingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onEvent(.teacherMessage(pendingText.trimmingCharacters(in: .whitespacesAndNewlines)))
                pendingText = ""
            }

        case "error", "invalid_request_error":
            let message = (json["message"] as? String) ?? (json["error"] as? String) ?? "Unknown error"
            onEvent(.systemNote("Realtime error: \(message)"))

        default:
            // Keep noise low; uncomment while debugging:
            // onEvent(.systemNote("Event: \(type)"))
            break
        }
    }
}

// MARK: - RTCPeerConnectionDelegate

extension OpenAIWebRTCSession: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        if newState == .connected || newState == .completed {
            onEvent(.systemNote("ICE connected."))
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        dataChannel.delegate = self
        self.dataChannel = dataChannel
        onEvent(.systemNote("Data channel opened."))
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        // Remote audio arrives here (or via onTrack depending on WebRTC build).
        // We don't need to manually play it; the WebRTC stack will route to audio output.
        onEvent(.systemNote("Received remote track."))
    }

    // Some WebRTC builds use this newer delegate callback:
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams: [RTCMediaStream], transceiver: RTCRtpTransceiver) {
        onEvent(.systemNote("Received remote track."))
    }
}

// MARK: - RTCDataChannelDelegate

extension OpenAIWebRTCSession: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        if dataChannel.readyState == .open {
            onEvent(.systemNote("Events channel ready."))

            // Keep us on-topic (in case server-side instructions were minimal):
            sendClientEvent([
                "type": "session.update",
                "session": [
                    "type": "realtime",
                    "instructions": "You are a friendly English teacher for children. Stay on the topic: \(topic.title). Greet first and ask one simple question.",
                ]
            ])
        }
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard !buffer.isBinary else { return }
        guard let str = String(data: buffer.data, encoding: .utf8) else { return }
        guard let data = str.data(using: .utf8) else { return }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []), let json = obj as? [String: Any] else {
            return
        }
        handleServerEvent(json)
    }
}

#endif
