import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var ageText: String = ""
    @State private var ageError: String? = nil
    @FocusState private var isAgeFieldFocused: Bool

    var body: some View {
        Form {
            Section {
                Picker("Realtime model", selection: $appModel.realtimeModelPreference) {
                    ForEach(RealtimeModelPreference.allCases) { option in
                        Text(option.displayName)
                            .tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Text("This changes which OpenAI Realtime model is used for new sessions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Realtime")
            }

            Section {
                Picker("Age band", selection: ageBandBinding) {
                    ForEach(AgeBand.allCases) { band in
                        Text(band.displayName).tag(band)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings.ageBand")

                Picker("English level", selection: englishLevelBinding) {
                    ForEach(EnglishLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings.englishLevel")

                TextField("Age (4–16)", text: $ageText)
                    .keyboardType(.numberPad)
                    .focused($isAgeFieldFocused)
                    .onChange(of: isAgeFieldFocused) { _, focused in
                        if !focused {
                            commitAgeIfNeeded()
                        }
                    }

                if let ageError {
                    Text(ageError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Picker(appModel.learnerProfile.country == .germany ? "Schulform" : "School type", selection: schoolTypeRawBinding) {
                    Text("Not set").tag("none")
                    ForEach(SchoolType.options(for: appModel.learnerProfile.country)) { t in
                        Text(t.displayName).tag(t.rawValue)
                    }
                }

                Picker("Country", selection: countryRawBinding) {
                    Text("Not set").tag("none")
                    ForEach(CountrySelection.allCases) { c in
                        Text(c.displayName).tag(c.rawValue)
                    }
                }

                if appModel.learnerProfile.country == .germany {
                    Picker("Bundesland", selection: bundeslandRawBinding) {
                        Text("Not set").tag("none")
                        ForEach(Bundesland.allCases) { s in
                            Text(s.displayName).tag(s.rawValue)
                        }
                    }
                } else if appModel.learnerProfile.country == .other {
                    TextField("Country (optional)", text: customCountryNameBinding)
                        .textInputAutocapitalization(.words)

                    TextField("Region/State (optional)", text: regionBinding)
                        .textInputAutocapitalization(.words)
                } else if appModel.learnerProfile.country != nil {
                    TextField("Region/State (optional)", text: regionBinding)
                        .textInputAutocapitalization(.words)
                }

                Text("Tip: Keep this non-identifying (no full school name, no address).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Learner")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isAgeFieldFocused = false
                }
            }
        }
        .onAppear {
            ageText = appModel.learnerProfile.age.map(String.init) ?? ""
        }
    }

    private var ageBandBinding: Binding<AgeBand> {
        Binding(
            get: { appModel.onboarding.ageBand ?? .earlyElementary },
            set: { newValue in
                var o = appModel.onboarding
                o.ageBand = newValue
                appModel.onboarding = o
            }
        )
    }

    private var englishLevelBinding: Binding<EnglishLevel> {
        Binding(
            get: { appModel.onboarding.englishLevel ?? .beginner },
            set: { newValue in
                var o = appModel.onboarding
                o.englishLevel = newValue
                appModel.onboarding = o
            }
        )
    }

    private var schoolTypeRawBinding: Binding<String> {
        Binding(
            get: { appModel.learnerProfile.schoolType?.rawValue ?? "none" },
            set: { raw in
                var p = appModel.learnerProfile
                p.schoolType = (raw == "none") ? nil : SchoolType(rawValue: raw)
                appModel.learnerProfile = p
            }
        )
    }

    private var countryRawBinding: Binding<String> {
        Binding(
            get: { appModel.learnerProfile.country?.rawValue ?? "none" },
            set: { raw in
                var p = appModel.learnerProfile
                p.country = (raw == "none") ? nil : CountrySelection(rawValue: raw)
                appModel.learnerProfile = p
            }
        )
    }

    private var bundeslandRawBinding: Binding<String> {
        Binding(
            get: { appModel.learnerProfile.bundesland?.rawValue ?? "none" },
            set: { raw in
                var p = appModel.learnerProfile
                p.bundesland = (raw == "none") ? nil : Bundesland(rawValue: raw)
                appModel.learnerProfile = p
            }
        )
    }

    private var regionBinding: Binding<String> {
        Binding(
            get: { appModel.learnerProfile.region ?? "" },
            set: { newValue in
                var p = appModel.learnerProfile
                p.region = newValue
                appModel.learnerProfile = p
            }
        )
    }

    private var customCountryNameBinding: Binding<String> {
        Binding(
            get: { appModel.learnerProfile.customCountryName ?? "" },
            set: { newValue in
                var p = appModel.learnerProfile
                p.customCountryName = newValue
                appModel.learnerProfile = p
            }
        )
    }

    private func commitAgeIfNeeded() {
        let trimmed = ageText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            ageError = nil
            var p = appModel.learnerProfile
            p.age = nil
            appModel.learnerProfile = p
            return
        }

        guard let age = Int(trimmed) else {
            ageError = "Please enter a whole number (4–16)."
            return
        }

        guard (4...16).contains(age) else {
            ageError = "Age must be between 4 and 16."
            return
        }

        ageError = nil
        var p = appModel.learnerProfile
        p.age = age
        appModel.learnerProfile = p
    }
}
