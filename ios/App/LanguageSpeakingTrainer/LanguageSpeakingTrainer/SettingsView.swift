import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var ageText: String = ""
    @State private var ageError: String? = nil
    @FocusState private var isAgeFieldFocused: Bool

    @State private var openAIAPIKeyDraft: String = ""
    @State private var googleAPIKeyDraft: String = ""

    var body: some View {
        Form {
            Section {
                Picker("Provider", selection: $appModel.realtimeProviderPreference) {
                    ForEach(RealtimeProviderPreference.allCases) { option in
                        Text(option.displayName)
                            .tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Text("Choose which realtime backend to use for new sessions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Realtime provider")
            }

            Section {
                if appModel.realtimeProviderPreference == .openAI {
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
                } else {
                    Picker("Gemini Live model", selection: $appModel.geminiLiveModelPreference) {
                        ForEach(GeminiLiveModelPreference.allCases) { option in
                            Text(option.displayName)
                                .tag(option)
                        }
                    }

                    Text("This changes which Gemini Live model is used for new sessions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Model")
            }

            Section {
                Toggle("Show system/debug messages", isOn: $appModel.showSystemMessages)

                Text("When off, the session transcript hides diagnostics (but still shows errors). The \"Teacher ready\" indicator still works.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Session")
            }

            Section {
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

            if appModel.realtimeProviderPreference == .openAI {
                Section {
                    if appModel.hasOpenAIAPIKey {
                        LabeledContent("API key") {
                            Text("Saved")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        LabeledContent("API key") {
                            Text("Not set")
                                .foregroundStyle(.secondary)
                        }
                    }

                    SecureField(appModel.hasOpenAIAPIKey ? "Enter new OpenAI API key" : "Enter OpenAI API key", text: $openAIAPIKeyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)

                    HStack {
                        Button("Save") {
                            appModel.storeOpenAIAPIKey(openAIAPIKeyDraft)
                            openAIAPIKeyDraft = ""
                        }
                        .disabled(openAIAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Spacer()

                        Button("Clear", role: .destructive) {
                            appModel.clearOpenAIAPIKey()
                            openAIAPIKeyDraft = ""
                        }
                        .disabled(!appModel.hasOpenAIAPIKey)
                    }

                    Text("For safety, the stored key cannot be displayed again. To change it, enter a new value and tap Save.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("OpenAI (BYOK)")
                } footer: {
                    Text("Dev/personal use only: storing an API key on-device can be risky. If a key is set here, the app will mint Realtime client secrets directly from OpenAI.")
                }
            } else {
                Section {
                    if appModel.hasGoogleAPIKey {
                        LabeledContent("API key") {
                            Text("Saved")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        LabeledContent("API key") {
                            Text("Not set")
                                .foregroundStyle(.secondary)
                        }
                    }

                    SecureField(appModel.hasGoogleAPIKey ? "Enter new Google API key" : "Enter Google API key", text: $googleAPIKeyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)

                    HStack {
                        Button("Save") {
                            appModel.storeGoogleAPIKey(googleAPIKeyDraft)
                            googleAPIKeyDraft = ""
                        }
                        .disabled(googleAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Spacer()

                        Button("Clear", role: .destructive) {
                            appModel.clearGoogleAPIKey()
                            googleAPIKeyDraft = ""
                        }
                        .disabled(!appModel.hasGoogleAPIKey)
                    }

                    Text("For safety, the stored key cannot be displayed again. To change it, enter a new value and tap Save.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Google (Gemini Live BYOK)")
                } footer: {
                    Text("Dev/personal use only: storing an API key on-device can be risky. For broader distribution, prefer server-minted ephemeral tokens.")
                }
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
