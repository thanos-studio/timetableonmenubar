import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject var timetableStore: TimetableStore
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        VStack {
            Text("시간표")
                .font(.headline)
            Text("Coming soon...")
        }
        .frame(width: 320, height: 450)
    }
}
