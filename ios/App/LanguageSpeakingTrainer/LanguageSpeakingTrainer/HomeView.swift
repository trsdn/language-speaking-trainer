import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var customTopicText: String = ""
    @State private var validationMessage: String? = nil

    private static let topicGridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 10, alignment: .leading)
    ]

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    LogoMarkView(size: 28)

                    Text("Practice speaking")
                        .font(.title.weight(.bold))
                }

                Text("Choose a topic and start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            topicPicker

            if let msg = validationMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        // Avoid the default translucent navigation bar drawing over our custom header.
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .imageScale(.medium)
                }
                .accessibilityLabel("Settings")
            }
        }
        // Keep the primary action visible above the home indicator.
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                SessionView(
                    topic: appModel.selectedTopic ?? Topic.presets[0],
                    providerPreference: appModel.realtimeProviderPreference,
                    modelPreference: appModel.realtimeModelPreference,
                    geminiModelPreference: appModel.geminiLiveModelPreference,
                    showSystemMessages: appModel.showSystemMessages,
                    learnerContext: appModel.learnerContext
                )
            } label: {
                Text("Start")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(appModel.selectedTopic == nil)
            .accessibilityIdentifier("home.start")
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(.clear)
        }
        .onChange(of: appModel.selectedTopic) { _, _ in
            validationMessage = nil
        }
    }

    private var topicPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topic")
                .font(.headline)

            LazyVGrid(columns: Self.topicGridColumns, alignment: .leading, spacing: 10) {
                ForEach(Topic.presets) { topic in
                    TopicChip(title: topic.title, isSelected: appModel.selectedTopic == topic) {
                        appModel.selectedTopic = topic
                    }
                    .accessibilityIdentifier("home.topic.\(topic.id)")
                }
            }
            .padding(.vertical, 2)

            HStack(spacing: 8) {
                TextField("Custom topic (e.g. Space)", text: $customTopicText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("home.customTopic")

                Button("Set") {
                    let trimmed = customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        validationMessage = "Please enter a topic."
                        return
                    }
                    appModel.selectedTopic = .custom(trimmed)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("home.setCustomTopic")
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct TopicChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 30)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .blue : .gray)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
