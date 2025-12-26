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

enum SchoolType: String, CaseIterable, Codable, Identifiable {
    case kindergarten
    case primarySchool
    case middleSchool
    case highSchool
    /// Germany-specific school forms.
    case grundschule
    case gymnasium
    case realschule
    case hauptschule
    /// Common term in some German states (e.g., Bavaria) roughly corresponding to lower secondary.
    case mittelschule
    case gesamtschule
    case foerderschule
    case berufsschule
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kindergarten: return "Kindergarten"
        case .primarySchool: return "Primary school"
        case .middleSchool: return "Middle school"
        case .highSchool: return "High school"
        case .grundschule: return "Grundschule"
        case .gymnasium: return "Gymnasium"
        case .realschule: return "Realschule"
        case .hauptschule: return "Hauptschule"
        case .mittelschule: return "Mittelschule"
        case .gesamtschule: return "Gesamtschule"
        case .foerderschule: return "Förderschule"
        case .berufsschule: return "Berufsschule"
        case .other: return "Other"
        }
    }

    /// A German label intended for prompts/context when the learner is in Germany.
    /// (We keep it separate from `displayName` so non-Germany flows remain English.)
    var germanDisplayName: String {
        switch self {
        case .kindergarten: return "Kindergarten"
        case .grundschule: return "Grundschule"
        case .gymnasium: return "Gymnasium"
        case .realschule: return "Realschule"
        case .hauptschule: return "Hauptschule"
        case .mittelschule: return "Mittelschule"
        case .gesamtschule: return "Gesamtschule"
        case .foerderschule: return "Förderschule"
        case .berufsschule: return "Berufsschule"
        // Generic types don't map cleanly to the German system.
        case .primarySchool: return "(nicht spezifiziert)"
        case .middleSchool: return "(nicht spezifiziert)"
        case .highSchool: return "(nicht spezifiziert)"
        case .other: return "Andere"
        }
    }

    static func options(for country: CountrySelection?) -> [SchoolType] {
        switch country {
        case .germany:
            // Keep this short and age-appropriate; can be expanded later.
            return [.kindergarten, .grundschule, .gymnasium, .realschule, .hauptschule, .mittelschule, .gesamtschule, .foerderschule, .berufsschule, .other]
        default:
            return [.kindergarten, .primarySchool, .middleSchool, .highSchool, .other]
        }
    }

    /// Ensures the selected value makes sense for the currently selected country.
    ///
    /// This prevents the Settings picker from having a selection that isn't in its option list.
    func normalized(for country: CountrySelection) -> SchoolType {
        switch country {
        case .germany:
            switch self {
            case .primarySchool: return .grundschule
            // No reliable mapping from generic secondary school types to Germany.
            // Return `.other` to avoid accidentally misclassifying.
            case .middleSchool: return .other
            case .highSchool: return .other
            default: return self
            }
        default:
            switch self {
            case .grundschule: return .primarySchool
            // German secondary school forms don't map 1:1; keep something roughly equivalent.
            case .gymnasium: return .highSchool
            case .realschule: return .middleSchool
            case .hauptschule: return .middleSchool
            case .mittelschule: return .middleSchool
            case .gesamtschule: return .middleSchool
            case .foerderschule: return .other
            case .berufsschule: return .other
            default: return self
            }
        }
    }
}

enum CountrySelection: String, CaseIterable, Codable, Identifiable {
    case germany = "DE"
    case austria = "AT"
    case switzerland = "CH"
    case unitedKingdom = "GB"
    case unitedStates = "US"
    case other = "OTHER"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .germany: return "Germany"
        case .austria: return "Austria"
        case .switzerland: return "Switzerland"
        case .unitedKingdom: return "United Kingdom"
        case .unitedStates: return "United States"
        case .other: return "Other"
        }
    }
}

enum Bundesland: String, CaseIterable, Codable, Identifiable {
    case bw // Baden-Württemberg
    case by // Bayern
    case be // Berlin
    case bb // Brandenburg
    case hb // Bremen
    case hh // Hamburg
    case he // Hessen
    case mv // Mecklenburg-Vorpommern
    case ni // Niedersachsen
    case nw // Nordrhein-Westfalen
    case rp // Rheinland-Pfalz
    case sl // Saarland
    case sn // Sachsen
    case st // Sachsen-Anhalt
    case sh // Schleswig-Holstein
    case th // Thüringen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bw: return "Baden-Württemberg"
        case .by: return "Bavaria"
        case .be: return "Berlin"
        case .bb: return "Brandenburg"
        case .hb: return "Bremen"
        case .hh: return "Hamburg"
        case .he: return "Hesse"
        case .mv: return "Mecklenburg-Vorpommern"
        case .ni: return "Lower Saxony"
        case .nw: return "North Rhine-Westphalia"
        case .rp: return "Rhineland-Palatinate"
        case .sl: return "Saarland"
        case .sn: return "Saxony"
        case .st: return "Saxony-Anhalt"
        case .sh: return "Schleswig-Holstein"
        case .th: return "Thuringia"
        }
    }
}

struct LearnerProfile: Codable, Equatable {
    /// Exact age in years.
    var age: Int?
    var schoolType: SchoolType?
    var country: CountrySelection?

    /// Only used when `country == .germany`.
    var bundesland: Bundesland?

    /// Used for non-Germany countries (optional).
    var region: String?

    /// Only used when `country == .other`.
    var customCountryName: String?

    static let storageKey = "learner.profile.v1"

    static func load() -> LearnerProfile {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(LearnerProfile.self, from: data)
        else {
            return LearnerProfile(age: nil, schoolType: nil, country: nil, bundesland: nil, region: nil, customCountryName: nil)
        }
        return decoded.sanitized()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    func sanitized() -> LearnerProfile {
        var copy = self

        if let age = copy.age, !(4...16).contains(age) {
            copy.age = nil
        }

        copy.region = copy.region?.trimmingCharacters(in: .whitespacesAndNewlines)
        if copy.region?.isEmpty == true {
            copy.region = nil
        }

        copy.customCountryName = copy.customCountryName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if copy.customCountryName?.isEmpty == true {
            copy.customCountryName = nil
        }

        switch copy.country {
        case .germany:
            copy.region = nil
            copy.customCountryName = nil
        case .other:
            copy.bundesland = nil
        case .none:
            copy.bundesland = nil
            copy.region = nil
            copy.customCountryName = nil
        default:
            copy.bundesland = nil
            copy.customCountryName = nil
        }

        if let country = copy.country, let schoolType = copy.schoolType {
            copy.schoolType = schoolType.normalized(for: country)
        }

        return copy
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

    @Published var learnerProfile: LearnerProfile {
        didSet {
            let sanitized = learnerProfile.sanitized()
            if sanitized != learnerProfile {
                learnerProfile = sanitized
                return
            }
            learnerProfile.save()
        }
    }

    init() {
        if AppConfig.isUITesting, AppConfig.shouldResetStateOnLaunch {
            Self.resetPersistentStateForUITests()
        }
        onboarding = OnboardingSettings.load()
        realtimeModelPreference = Self.loadRealtimeModelPreference()
        learnerProfile = LearnerProfile.load()
    }

    private static func resetPersistentStateForUITests() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: OnboardingSettings.storageKey)
        defaults.removeObject(forKey: LearnerProfile.storageKey)
        defaults.removeObject(forKey: realtimeModelPreferenceKey)
        defaults.synchronize()
    }

    var learnerContext: LearnerContext {
        LearnerContext(
            ageBand: onboarding.ageBand,
            englishLevel: onboarding.englishLevel,
            profile: learnerProfile
        )
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
