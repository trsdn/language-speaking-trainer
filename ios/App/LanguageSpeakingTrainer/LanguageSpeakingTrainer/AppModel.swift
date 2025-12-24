import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedTopic: Topic? = nil

    // First-run onboarding state
    @Published var onboarding: OnboardingSettings

    init() {
        onboarding = OnboardingSettings.load()
    }

    func completeOnboarding(ageBand: AgeBand, level: EnglishLevel) {
        onboarding = OnboardingSettings(isCompleted: true, ageBand: ageBand, englishLevel: level)
        onboarding.save()
    }

    func resetTopic() {
        selectedTopic = nil
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
