import Foundation

struct LearnerContext: Equatable {
    let ageBand: AgeBand?
    let englishLevel: EnglishLevel?
    let profile: LearnerProfile

    /// Settings-derived learner context (only fields configured on the Settings screen).
    /// This is intended to be sent to the backend token endpoint as a compact hint (not as system instructions).
    func settingsSnippet() -> String {
        var lines: [String] = []

        let isGermany = (profile.country == .germany)

        if let age = profile.age {
            lines.append(isGermany ? "- Alter: \(age)" : "- Age: \(age)")
        }
        if let schoolType = profile.schoolType {
            if isGermany {
                lines.append("- Schulform: \(schoolType.germanDisplayName)")
            } else {
                lines.append("- School type: \(schoolType.displayName)")
            }
        }
        if let country = profile.country {
            lines.append(isGermany ? "- Land: \(country.displayName)" : "- Country: \(country.displayName)")
        }
        if let bundesland = profile.bundesland {
            // 'Bundesland' is already German and widely understood.
            lines.append("- Bundesland: \(bundesland.displayName)")
        }
        if let customCountryName = profile.customCountryName {
            lines.append(isGermany ? "- Benutzerdefiniertes Land: \(customCountryName)" : "- Custom country name: \(customCountryName)")
        }
        if let region = profile.region {
            lines.append(isGermany ? "- Region/Bundesland: \(region)" : "- Region/State: \(region)")
        }

        guard !lines.isEmpty else { return "" }
        return "Learner settings:\n" + lines.joined(separator: "\n")
    }

    /// Human-readable, non-identifying context that can be embedded into a system prompt.
    func promptSnippet() -> String {
        var lines: [String] = []

        let isGermany = (profile.country == .germany)

        if let age = profile.age {
            lines.append(isGermany ? "- Alter: \(age)" : "- Age: \(age)")
        }
        if let ageBand {
            lines.append("- Age band: \(ageBand.displayName)")
        }
        if let englishLevel {
            lines.append("- English level: \(englishLevel.displayName)")
        }
        if let schoolType = profile.schoolType {
            if isGermany {
                lines.append("- Schulform: \(schoolType.germanDisplayName)")
            } else {
                lines.append("- School type: \(schoolType.displayName)")
            }
        }

        if let country = profile.country {
            switch country {
            case .germany:
                if let bundesland = profile.bundesland {
                    lines.append("- Ort: Deutschland (\(bundesland.displayName))")
                } else {
                    lines.append("- Ort: Deutschland")
                }
            case .other:
                if let name = profile.customCountryName {
                    if let region = profile.region {
                        lines.append(isGermany ? "- Ort: \(name) (\(region))" : "- Location: \(name) (\(region))")
                    } else {
                        lines.append(isGermany ? "- Ort: \(name)" : "- Location: \(name)")
                    }
                } else if let region = profile.region {
                    lines.append(isGermany ? "- Ort: Andere (\(region))" : "- Location: Other (\(region))")
                } else {
                    lines.append(isGermany ? "- Ort: Andere" : "- Location: Other")
                }
            default:
                if let region = profile.region {
                    lines.append(isGermany ? "- Ort: \(country.displayName) (\(region))" : "- Location: \(country.displayName) (\(region))")
                } else {
                    lines.append(isGermany ? "- Ort: \(country.displayName)" : "- Location: \(country.displayName)")
                }
            }
        }

        guard !lines.isEmpty else { return "" }
        return (isGermany ? "Lernkontext (nicht-identifizierend):\n" : "Learner context (non-identifying):\n") + lines.joined(separator: "\n")
    }
}
