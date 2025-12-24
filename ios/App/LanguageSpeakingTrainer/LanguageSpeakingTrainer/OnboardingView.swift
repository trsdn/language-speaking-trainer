import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var selectedAgeBand: AgeBand? = nil
    @State private var selectedLevel: EnglishLevel? = nil

    var canContinue: Bool {
        selectedAgeBand != nil && selectedLevel != nil
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Let’s set up your practice")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                Text("Age band")
                    .font(.headline)

                Picker("Age band", selection: Binding(
                    get: { selectedAgeBand ?? .earlyElementary },
                    set: { selectedAgeBand = $0 }
                )) {
                    ForEach(AgeBand.allCases) { band in
                        Text(band.displayName).tag(band)
                    }
                }
                .pickerStyle(.segmented)

                Text("English level")
                    .font(.headline)
                    .padding(.top, 8)

                Picker("English level", selection: Binding(
                    get: { selectedLevel ?? .beginner },
                    set: { selectedLevel = $0 }
                )) {
                    ForEach(EnglishLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)

            Button {
                guard let age = selectedAgeBand, let level = selectedLevel else { return }
                appModel.completeOnboarding(ageBand: age, level: level)
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .disabled(!canContinue)

            Spacer()

            Text("This app uses an AI teacher. Don’t share personal info.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .onAppear {
            // Preselect defaults so the UI is simple, but still requires explicit confirmation.
            if selectedAgeBand == nil { selectedAgeBand = .earlyElementary }
            if selectedLevel == nil { selectedLevel = .beginner }
        }
    }
}
