import Foundation

struct LearnerContext: Equatable {
    let ageBand: AgeBand?
    let englishLevel: EnglishLevel?
    let profile: LearnerProfile

    /// Human-readable, non-identifying context that can be embedded into a system prompt.
    func promptSnippet() -> String {
        var lines: [String] = []

        if let age = profile.age {
            lines.append("- Age: \(age)")
        }
        if let ageBand {
            lines.append("- Age band: \(ageBand.displayName)")
        }
        if let englishLevel {
            lines.append("- English level: \(englishLevel.displayName)")
        }
        if let schoolType = profile.schoolType {
            lines.append("- School type: \(schoolType.displayName)")
        }

        if let country = profile.country {
            switch country {
            case .germany:
                if let bundesland = profile.bundesland {
                    lines.append("- Location: Germany (\(bundesland.displayName))")
                } else {
                    lines.append("- Location: Germany")
                }
            case .other:
                if let name = profile.customCountryName {
                    if let region = profile.region {
                        lines.append("- Location: \(name) (\(region))")
                    } else {
                        lines.append("- Location: \(name)")
                    }
                } else if let region = profile.region {
                    lines.append("- Location: Other (\(region))")
                } else {
                    lines.append("- Location: Other")
                }
            default:
                if let region = profile.region {
                    lines.append("- Location: \(country.displayName) (\(region))")
                } else {
                    lines.append("- Location: \(country.displayName)")
                }
            }
        }

        guard !lines.isEmpty else { return "" }
        return "Learner context (non-identifying):\n" + lines.joined(separator: "\n")
    }
}
