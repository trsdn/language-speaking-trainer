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

enum RealtimeProviderPreference: String, CaseIterable, Codable, Identifiable {
    case openAI
    case geminiLive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI Realtime"
        case .geminiLive:
            return "Gemini Live"
        }
    }
}

enum GeminiLiveModelPreference: String, CaseIterable, Codable, Identifiable {
    /// Gemini 2.5 Flash with native audio (Live preview).
    case gemini25FlashNativeAudioPreview_2025_12 = "gemini-2.5-flash-native-audio-preview-12-2025"

    /// Older/alternate Live preview identifier seen in docs/examples.
    case geminiLive25FlashPreview = "gemini-live-2.5-flash-preview"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gemini25FlashNativeAudioPreview_2025_12:
            return "Gemini 2.5 Flash (native audio preview)"
        case .geminiLive25FlashPreview:
            return "Gemini Live 2.5 Flash (preview)"
        }
    }

    /// Full model resource name required by the Live API setup message.
    var resourceName: String {
        "models/\(rawValue)"
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
    @Published var onboarding: OnboardingSettings {
        didSet {
            onboarding.save()
        }
    }

    // Settings
    @Published var realtimeProviderPreference: RealtimeProviderPreference {
        didSet {
            persistRealtimeProviderPreference(realtimeProviderPreference)
        }
    }

    @Published var realtimeModelPreference: RealtimeModelPreference {
        didSet {
            persistRealtimeModelPreference(realtimeModelPreference)
        }
    }

    @Published var geminiLiveModelPreference: GeminiLiveModelPreference {
        didSet {
            persistGeminiLiveModelPreference(geminiLiveModelPreference)
        }
    }

    /// Whether to show system/debug notes in the session transcript.
    ///
    /// When disabled, the session screen becomes much quieter (you still get the
    /// "Teacher ready" indicator). If something doesn't work, turn this back on
    /// to see connection diagnostics and errors.
    @Published var showSystemMessages: Bool {
        didSet {
            persistShowSystemMessages(showSystemMessages)
        }
    }

    /// Whether to show transcript text (teacher + user text) in the session UI.
    ///
    /// When disabled, the session becomes audio-first and much quieter visually.
    @Published var showTranscript: Bool {
        didSet {
            persistShowTranscript(showTranscript)
        }
    }

    /// Whether an OpenAI API key is stored on this device (BYOK mode).
    /// We intentionally never expose the stored value via the UI.
    @Published private(set) var hasOpenAIAPIKey: Bool

    /// Whether a Google API key is stored on this device (Gemini Live BYOK mode).
    /// We intentionally never expose the stored value via the UI.
    @Published private(set) var hasGoogleAPIKey: Bool

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

        // Initialize stored properties using locals first (Swift forbids accessing `self`
        // before all stored properties are initialized).
        var initialOnboarding = OnboardingSettings.load()
        // Provide sensible defaults so the app can work without a dedicated onboarding screen.
        if initialOnboarding.ageBand == nil { initialOnboarding.ageBand = .earlyElementary }
        if initialOnboarding.englishLevel == nil { initialOnboarding.englishLevel = .beginner }
        initialOnboarding.save()

        let initialRealtimePref = Self.loadRealtimeModelPreference()
        let initialProviderPref = Self.loadRealtimeProviderPreference()
        let initialGeminiModelPref = Self.loadGeminiLiveModelPreference()
        let initialShowSystemMessages = Self.loadShowSystemMessages()
        let initialShowTranscript = Self.loadShowTranscript()
        let initialLearnerProfile = LearnerProfile.load()
        let initialHasOpenAIKey = Self.loadHasOpenAIAPIKey()
        let initialHasGoogleKey = Self.loadHasGoogleAPIKey()

        onboarding = initialOnboarding
        realtimeProviderPreference = initialProviderPref
        realtimeModelPreference = initialRealtimePref
        geminiLiveModelPreference = initialGeminiModelPref
        showSystemMessages = initialShowSystemMessages
        showTranscript = initialShowTranscript
        hasOpenAIAPIKey = initialHasOpenAIKey
        hasGoogleAPIKey = initialHasGoogleKey
        learnerProfile = initialLearnerProfile
    }

    private static func resetPersistentStateForUITests() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: OnboardingSettings.storageKey)
        defaults.removeObject(forKey: LearnerProfile.storageKey)
        defaults.removeObject(forKey: realtimeProviderPreferenceKey)
        defaults.removeObject(forKey: realtimeModelPreferenceKey)
        defaults.removeObject(forKey: geminiLiveModelPreferenceKey)
        defaults.removeObject(forKey: showSystemMessagesKey)
        defaults.removeObject(forKey: showTranscriptKey)
        defaults.synchronize()

        // Best-effort: also clear Keychain secrets so UITests don't leak state between runs.
        try? KeychainStore.delete(.openAIAPIKey)
        try? KeychainStore.delete(.googleAPIKey)
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
    }

    /// Marks the first-run setup as complete.
    ///
    /// We keep `OnboardingSettings` as the persistence mechanism for learner basics
    /// (age band + English level) even though the dedicated onboarding screen is no longer used.
    func markInitialSetupCompleteIfNeeded() {
        guard onboarding.isCompleted == false else { return }
        var updated = onboarding
        updated.isCompleted = true
        if updated.ageBand == nil { updated.ageBand = .earlyElementary }
        if updated.englishLevel == nil { updated.englishLevel = .beginner }
        onboarding = updated
    }

    func resetTopic() {
        selectedTopic = nil
    }

    private static let realtimeModelPreferenceKey = "realtime.model.preference.v1"
    private static let realtimeProviderPreferenceKey = "realtime.provider.preference.v1"
    private static let geminiLiveModelPreferenceKey = "gemini.live.model.preference.v1"
    private static let showSystemMessagesKey = "session.showSystemMessages.v1"
    private static let showTranscriptKey = "session.showTranscript.v1"

    private static func loadRealtimeProviderPreference() -> RealtimeProviderPreference {
        guard let raw = UserDefaults.standard.string(forKey: realtimeProviderPreferenceKey) else {
            return .openAI
        }
        return RealtimeProviderPreference(rawValue: raw) ?? .openAI
    }

    private func persistRealtimeProviderPreference(_ pref: RealtimeProviderPreference) {
        UserDefaults.standard.set(pref.rawValue, forKey: Self.realtimeProviderPreferenceKey)
    }

    private static func loadRealtimeModelPreference() -> RealtimeModelPreference {
        guard let raw = UserDefaults.standard.string(forKey: realtimeModelPreferenceKey) else {
            return .realtimeMini
        }
        return RealtimeModelPreference(rawValue: raw) ?? .realtimeMini
    }

    private func persistRealtimeModelPreference(_ pref: RealtimeModelPreference) {
        UserDefaults.standard.set(pref.rawValue, forKey: Self.realtimeModelPreferenceKey)
    }

    private static func loadGeminiLiveModelPreference() -> GeminiLiveModelPreference {
        guard let raw = UserDefaults.standard.string(forKey: geminiLiveModelPreferenceKey) else {
            return .gemini25FlashNativeAudioPreview_2025_12
        }
        return GeminiLiveModelPreference(rawValue: raw) ?? .gemini25FlashNativeAudioPreview_2025_12
    }

    private func persistGeminiLiveModelPreference(_ pref: GeminiLiveModelPreference) {
        UserDefaults.standard.set(pref.rawValue, forKey: Self.geminiLiveModelPreferenceKey)
    }

    private static func loadShowSystemMessages() -> Bool {
        // Default is "true" to preserve current behavior.
        if UserDefaults.standard.object(forKey: showSystemMessagesKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: showSystemMessagesKey)
    }

    private func persistShowSystemMessages(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.showSystemMessagesKey)
    }

    private static func loadShowTranscript() -> Bool {
        // Default is "true" to preserve current behavior.
        if UserDefaults.standard.object(forKey: showTranscriptKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: showTranscriptKey)
    }

    private func persistShowTranscript(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.showTranscriptKey)
    }

    private static func loadHasOpenAIAPIKey() -> Bool {
        let v = KeychainStore.readString(for: .openAIAPIKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !v.isEmpty
    }

    private static func loadHasGoogleAPIKey() -> Bool {
        let v = KeychainStore.readString(for: .googleAPIKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !v.isEmpty
    }

    func storeOpenAIAPIKey(_ apiKey: String) {
        let v = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return }
        do {
            try KeychainStore.writeString(v, for: .openAIAPIKey)
            hasOpenAIAPIKey = true
        } catch {
            // Intentionally do not log the key.
        }
    }

    func clearOpenAIAPIKey() {
        do {
            try KeychainStore.delete(.openAIAPIKey)
        } catch {
            // Ignore failures; we still recompute.
        }
        hasOpenAIAPIKey = Self.loadHasOpenAIAPIKey()
    }

    func storeGoogleAPIKey(_ apiKey: String) {
        let v = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return }
        do {
            try KeychainStore.writeString(v, for: .googleAPIKey)
            hasGoogleAPIKey = true
        } catch {
            // Intentionally do not log the key.
        }
    }

    func clearGoogleAPIKey() {
        do {
            try KeychainStore.delete(.googleAPIKey)
        } catch {
            // Ignore failures; we still recompute.
        }
        hasGoogleAPIKey = Self.loadHasGoogleAPIKey()
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
