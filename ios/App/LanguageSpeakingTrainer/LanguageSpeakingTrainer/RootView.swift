import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var isShowingInitialSettings: Bool = false

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .sheet(isPresented: $isShowingInitialSettings, onDismiss: {
            appModel.markInitialSetupCompleteIfNeeded()
        }) {
            InitialSettingsSheet(isPresented: $isShowingInitialSettings)
                .environmentObject(appModel)
        }
        .task {
            // Replace onboarding with a one-time Settings sheet so the user has an obvious
            // path to configure the learner context without blocking the main UI.
            if !appModel.onboarding.isCompleted {
                isShowingInitialSettings = true
            }
        }
    }
}

private struct InitialSettingsSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
                        .accessibilityIdentifier("settings.done")
                    }
                }
        }
    }
}
