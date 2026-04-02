import SwiftUI
import Foundation

struct PopoverContentView: View {
    @EnvironmentObject var timetableStore: TimetableStore
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.openWindow) private var openWindow

    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                settingsButton
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            tabContent

            Divider()

            bottomBar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 320, height: 450)
        .overlay {
            if showSettings {
                SettingsView(showSettings: $showSettings)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .task {
            if !settingsStore.hasCompletedOnboarding {
                openWindow(id: "onboarding")
            }
        }
    }

    @ViewBuilder
    private var settingsButton: some View {
        if #available(macOS 26, *) {
            Button { showSettings.toggle() } label: {
                Image(systemName: "gearshape")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
        } else {
            Button { showSettings.toggle() } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        if #available(macOS 15, *) {
            TabView {
                Tab("오늘", systemImage: "sun.max") {
                    TodayView()
                }
                Tab("주간", systemImage: "calendar") {
                    WeeklyView()
                }
                Tab("급식", systemImage: "fork.knife") {
                    MealView()
                }
            }
        } else {
            TabView {
                TodayView()
                    .tabItem { Label("오늘", systemImage: "sun.max") }
                WeeklyView()
                    .tabItem { Label("주간", systemImage: "calendar") }
                MealView()
                    .tabItem { Label("급식", systemImage: "fork.knife") }
            }
        }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 8) {
                HStack {
                    if let date = timetableStore.lastRefreshDate {
                        Text("마지막 업데이트: \(formatDate(date))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("업데이트 정보 없음")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task {
                            await timetableStore.refreshTimetable()
                            await timetableStore.refreshMeals()
                        }
                    } label: {
                        if timetableStore.isLoading {
                            ProgressView().controlSize(.small)
                                .frame(width: 28, height: 28)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .frame(width: 28, height: 28)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(timetableStore.isLoading)
                    .glassEffect(.regular.interactive(), in: .circle)
                }
            }
        } else {
            HStack {
                if let date = timetableStore.lastRefreshDate {
                    Text("마지막 업데이트: \(formatDate(date))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("업데이트 정보 없음")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    Task {
                        await timetableStore.refreshTimetable()
                        await timetableStore.refreshMeals()
                    }
                } label: {
                    if timetableStore.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
                .disabled(timetableStore.isLoading)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
