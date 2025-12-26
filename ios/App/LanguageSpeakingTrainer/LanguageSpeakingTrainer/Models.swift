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
        // Grade 6 (Lower Saxony, Gymnasium Sek I) speaking-first topics.
        // Anchored in KC guidance for Jg. 5/6: prioritize listening + speaking and
        // use contexts of immediate personal relevance.
        Topic(id: "classroom-talk", title: "Classroom talk"),
        Topic(id: "friends", title: "Friends"),
        Topic(id: "making-plans", title: "Making plans"),
        Topic(id: "sorry-and-solutions", title: "Sorry & solutions"),
        Topic(id: "school-day", title: "My school day"),
        Topic(id: "food-ordering", title: "Food & ordering"),
        Topic(id: "shopping-clothes", title: "Shopping (clothes)"),
        Topic(id: "my-town", title: "My town"),
        Topic(id: "public-transport", title: "Getting around"),
        Topic(id: "directions", title: "Directions"),
        Topic(id: "animals-nature", title: "Animals & nature"),
        Topic(id: "trips-holidays", title: "Trips & holidays")
    ]
}
