import SwiftUI
import Foundation
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var timetableStore: TimetableStore
    @Environment(\.openWindow) private var openWindow
    @Binding var showSettings: Bool

    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    // Grade/Class
    @State private var grade: Int = 1
    @State private var classNum: Int = 1

    // Period config
    @State private var startHour: Int = 8
    @State private var startMinute: Int = 40
    @State private var classDuration: Int = 50
    @State private var breakDuration: Int = 10
    @State private var lunchAfterPeriod: Int = 4
    @State private var lunchDuration: Int = 60
    @State private var totalPeriods: Int = 7

    private var startTimeDate: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = startHour
                components.minute = startMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                startHour = components.hour ?? 8
                startMinute = components.minute ?? 40
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    showSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .modifier(GlassCircleButtonModifier())

                Text("설정")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: School info
                    sectionHeader("학교 정보")

                    HStack {
                        Text(settingsStore.schoolName.isEmpty ? "학교 미설정" : settingsStore.schoolName)
                            .foregroundColor(settingsStore.schoolName.isEmpty ? .secondary : .primary)
                        Spacer()
                        Button("학교 변경") {
                            openWindow(id: "school-search")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 12)

                    Divider()

                    // MARK: Grade/Class
                    sectionHeader("학년/반")

                    VStack(spacing: 8) {
                        configRow("학년") {
                            Picker("", selection: $grade) {
                                Text("1학년").tag(1)
                                Text("2학년").tag(2)
                                Text("3학년").tag(3)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }

                        configRow("반") {
                            HStack {
                                Text("\(classNum)반")
                                    .monospacedDigit()
                                    .frame(minWidth: 40, alignment: .trailing)
                                Stepper("", value: $classNum, in: 1...20)
                                    .labelsHidden()
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    Divider()

                    // MARK: Period config
                    sectionHeader("수업 시간 설정")

                    VStack(spacing: 8) {
                        configRow("수업 시작 시간") {
                            DatePicker("", selection: startTimeDate, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }

                        configRow("수업 시간 (분)") {
                            HStack {
                                Text("\(classDuration)분")
                                    .monospacedDigit()
                                    .frame(minWidth: 40, alignment: .trailing)
                                Stepper("", value: $classDuration, in: 30...60)
                                    .labelsHidden()
                            }
                        }

                        configRow("쉬는 시간 (분)") {
                            HStack {
                                Text("\(breakDuration)분")
                                    .monospacedDigit()
                                    .frame(minWidth: 40, alignment: .trailing)
                                Stepper("", value: $breakDuration, in: 5...30)
                                    .labelsHidden()
                            }
                        }

                        configRow("총 교시 수") {
                            HStack {
                                Text("\(totalPeriods)교시")
                                    .monospacedDigit()
                                    .frame(minWidth: 50, alignment: .trailing)
                                Stepper("", value: $totalPeriods, in: 4...10)
                                    .labelsHidden()
                            }
                        }

                        configRow("점심시간 전 수업 수") {
                            HStack {
                                Text("\(lunchAfterPeriod)교시 후")
                                    .monospacedDigit()
                                    .frame(minWidth: 70, alignment: .trailing)
                                Stepper("", value: $lunchAfterPeriod, in: 1...totalPeriods)
                                    .labelsHidden()
                            }
                        }

                        configRow("점심시간 (분)") {
                            HStack {
                                Text("\(lunchDuration)분")
                                    .monospacedDigit()
                                    .frame(minWidth: 40, alignment: .trailing)
                                Stepper("", value: $lunchDuration, in: 30...90)
                                    .labelsHidden()
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    Divider()

                    sectionHeader("일반")

                    Toggle("로그인 시 자동 시작", isOn: $launchAtLogin)
                        .padding(.horizontal, 12)
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                launchAtLogin = !newValue
                            }
                        }

                    Divider()

                    // MARK: Actions
                    Button("저장") {
                        saveSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)

                    Button("종료") {
                        NSApp.terminate(nil)
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
                .padding(.top, 12)
            }
        }
        .frame(width: 320, height: 450)
        .onAppear {
            grade = settingsStore.grade
            classNum = settingsStore.classNum
            let config = settingsStore.periodConfig
            startHour = config.startHour
            startMinute = config.startMinute
            classDuration = config.classDuration
            breakDuration = config.breakDuration
            lunchAfterPeriod = config.lunchAfterPeriod
            lunchDuration = config.lunchDuration
            totalPeriods = config.totalPeriods
        }
    }

    private func saveSettings() {
        settingsStore.grade = grade
        settingsStore.classNum = classNum
        settingsStore.periodConfig = PeriodConfig(
            startHour: startHour,
            startMinute: startMinute,
            classDuration: classDuration,
            breakDuration: breakDuration,
            lunchAfterPeriod: lunchAfterPeriod,
            lunchDuration: lunchDuration,
            totalPeriods: totalPeriods
        )
        settingsStore.savePeriodConfig()
        Task { await timetableStore.refreshTimetable() }
        showSettings = false
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func configRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }
}

// MARK: - School Search Sheet Wrapper

struct SchoolSearchSheet: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) var dismiss
    @State private var dummyPath: [OnboardingStep] = []

    var body: some View {
        NavigationStack(path: $dummyPath) {
            SchoolSearchView(path: $dummyPath)
        }
        .frame(width: 400, height: 450)
        .onChange(of: settingsStore.schoolCode) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}
