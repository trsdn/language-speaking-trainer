import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

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
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
