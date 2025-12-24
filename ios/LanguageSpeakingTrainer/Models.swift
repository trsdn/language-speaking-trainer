import Foundation

enum AgeBand: String, CaseIterable, Identifiable, Codable {
    case preschool = "4–6"
    case earlyElementary = "7–9"
    case lateElementary = "10–12"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

enum EnglishLevel: String, CaseIterable, Identifiable, Codable {
    case beginner
    case intermediate

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

struct Topic: Equatable, Hashable, Codable, Identifiable {
    let id: String
    let title: String

    static func custom(_ title: String) -> Topic {
        Topic(id: "custom:\(title.lowercased())", title: title)
    }

    static let presets: [Topic] = [
        Topic(id: "animals", title: "Animals"),
        Topic(id: "school", title: "School"),
        Topic(id: "sports", title: "Sports"),
        Topic(id: "food", title: "Food"),
        Topic(id: "space", title: "Space")
    ]
}
