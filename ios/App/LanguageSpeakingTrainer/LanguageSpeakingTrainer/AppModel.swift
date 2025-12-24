import Foundation
import Combine

enum RealtimeModelPreference: String, CaseIterable, Codable, Identifiable {
    case realtimeMini
    case realtime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .realtimeMini:
            return "Realtime Mini"
        case .realtime:
            return "Realtime"
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedTopic: Topic? = nil

    // First-run onboarding state
    @Published var onboarding: OnboardingSettings

    // Settings
    @Published var realtimeModelPreference: RealtimeModelPreference {
        didSet {
            persistRealtimeModelPreference(realtimeModelPreference)
        }
    }

    init() {
        onboarding = OnboardingSettings.load()
        realtimeModelPreference = Self.loadRealtimeModelPreference()
    }

    func completeOnboarding(ageBand: AgeBand, level: EnglishLevel) {
        onboarding = OnboardingSettings(isCompleted: true, ageBand: ageBand, englishLevel: level)
        onboarding.save()
    }

    func resetTopic() {
        selectedTopic = nil
    }

    private static let realtimeModelPreferenceKey = "realtime.model.preference.v1"

    private static func loadRealtimeModelPreference() -> RealtimeModelPreference {
        guard let raw = UserDefaults.standard.string(forKey: realtimeModelPreferenceKey) else {
            return .realtimeMini
        }
        return RealtimeModelPreference(rawValue: raw) ?? .realtimeMini
    }

    private func persistRealtimeModelPreference(_ pref: RealtimeModelPreference) {
        UserDefaults.standard.set(pref.rawValue, forKey: Self.realtimeModelPreferenceKey)
    }
}

struct OnboardingSettings: Codable, Equatable {
    var isCompleted: Bool
    var ageBand: AgeBand?
    var englishLevel: EnglishLevel?

    static let storageKey = "onboarding.settings.v1"

    static func load() -> OnboardingSettings {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(OnboardingSettings.self, from: data)
        else {
            return OnboardingSettings(isCompleted: false, ageBand: nil, englishLevel: nil)
        }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
