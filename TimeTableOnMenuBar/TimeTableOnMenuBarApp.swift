import SwiftUI

@main
struct TimeTableOnMenuBarApp: App {
    @StateObject private var settingsStore: SettingsStore
    @StateObject private var timetableStore: TimetableStore

    init() {
        let settings = SettingsStore()
        _settingsStore = StateObject(wrappedValue: settings)
        _timetableStore = StateObject(wrappedValue: TimetableStore(settingsStore: settings))
    }

    var body: some Scene {
        MenuBarExtra(timetableStore.menuBarTitle) {
            PopoverContentView()
                .environmentObject(settingsStore)
                .environmentObject(timetableStore)
        }
        .menuBarExtraStyle(.window)

        Window("설정", id: "onboarding") {
            OnboardingContainerView()
                .environmentObject(settingsStore)
                .environmentObject(timetableStore)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("학교 검색", id: "school-search") {
            SchoolSearchSheet()
                .environmentObject(settingsStore)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
