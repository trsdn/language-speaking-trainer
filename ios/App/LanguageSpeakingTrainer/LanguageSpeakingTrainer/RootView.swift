import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            if appModel.onboarding.isCompleted {
                NavigationStack {
                    HomeView()
                }
            } else {
                OnboardingView()
            }
        }
    }
}
