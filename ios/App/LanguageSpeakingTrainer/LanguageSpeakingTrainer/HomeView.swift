import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var customTopicText: String = ""
    @State private var validationMessage: String? = nil

    private let surpriseTopics: [Topic] = Topic.presets

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Practice speaking")
                    .font(.largeTitle.weight(.bold))

                Text("Choose a topic and start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            topicPicker

            if let msg = validationMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            NavigationLink {
                SessionView(
                    topic: appModel.selectedTopic ?? Topic.presets[0],
                    modelPreference: appModel.realtimeModelPreference,
                    learnerContext: appModel.learnerContext
                )
            } label: {
                Text("Start")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .disabled(appModel.selectedTopic == nil)
            .accessibilityIdentifier("home.start")

            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .onChange(of: appModel.selectedTopic) { _, _ in
            validationMessage = nil
        }
    }

    private var topicPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topic")
                .font(.headline)

            let columns: [GridItem] = [GridItem(.adaptive(minimum: 120), spacing: 10, alignment: .leading)]

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(Topic.presets) { topic in
                    TopicChip(title: topic.title, isSelected: appModel.selectedTopic == topic) {
                        appModel.selectedTopic = topic
                    }
                    .accessibilityIdentifier("home.topic.\(topic.id)")
                }

                TopicChip(title: "Surprise", isSelected: false) {
                    appModel.selectedTopic = surpriseTopics.randomElement()
                }
                .accessibilityIdentifier("home.topic.surprise")
            }
            .padding(.vertical, 4)

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
        .padding()
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
                .frame(maxWidth: .infinity, minHeight: 36)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .blue : .gray)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
