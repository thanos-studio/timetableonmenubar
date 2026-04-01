import SwiftUI
import Foundation

struct PopoverContentView: View {
    @EnvironmentObject var timetableStore: TimetableStore
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.openWindow) private var openWindow

    enum Tab { case today, weekly }
    @State private var selectedTab: Tab = .today
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: tabs + gear
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("오늘").tag(Tab.today)
                    Text("주간").tag(Tab.weekly)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                Spacer()

                Button { showSettings.toggle() } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Content
            switch selectedTab {
            case .today:
                TodayView()
            case .weekly:
                WeeklyView()
            }

            Divider()

            // Bottom bar: last updated + refresh
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
                    Task { await timetableStore.refreshTimetable() }
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
