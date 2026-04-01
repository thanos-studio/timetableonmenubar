import SwiftUI
import Foundation

enum OnboardingStep: Hashable {
    case schoolSearch
    case gradeClass
    case periodConfig
}

struct OnboardingContainerView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var path: [OnboardingStep] = []

    var body: some View {
        NavigationStack(path: $path) {
            SchoolSearchView(path: $path)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .schoolSearch:
                        SchoolSearchView(path: $path)
                    case .gradeClass:
                        GradeClassView(path: $path)
                    case .periodConfig:
                        PeriodConfigView()
                    }
                }
        }
        .frame(width: 450, height: 550)
    }
}
