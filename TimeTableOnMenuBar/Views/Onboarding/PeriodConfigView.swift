import SwiftUI
import Foundation

struct PeriodConfigView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var timetableStore: TimetableStore
    @Environment(\.dismiss) private var dismiss

    @State private var startHour: Int = 8
    @State private var startMinute: Int = 40
    @State private var classDuration: Int = 50
    @State private var breakDuration: Int = 10
    @State private var lunchAfterPeriod: Int = 4
    @State private var lunchDuration: Int = 60
    @State private var totalPeriods: Int = 7

    private var currentConfig: PeriodConfig {
        PeriodConfig(
            startHour: startHour,
            startMinute: startMinute,
            classDuration: classDuration,
            breakDuration: breakDuration,
            lunchAfterPeriod: lunchAfterPeriod,
            lunchDuration: lunchDuration,
            totalPeriods: totalPeriods
        )
    }

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

    private var previewSlots: [PeriodTimeSlot] {
        PeriodCalculator.generateSlots(from: currentConfig, on: Date())
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            Text("수업 시간 설정")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 24)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Start time
                    configRow("수업 시작 시간") {
                        DatePicker("", selection: startTimeDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    // Class duration
                    configRow("수업 시간 (분)") {
                        HStack {
                            Text("\(classDuration)분")
                                .monospacedDigit()
                                .frame(minWidth: 40, alignment: .trailing)
                            Stepper("", value: $classDuration, in: 30...60)
                                .labelsHidden()
                        }
                    }

                    // Break duration
                    configRow("쉬는 시간 (분)") {
                        HStack {
                            Text("\(breakDuration)분")
                                .monospacedDigit()
                                .frame(minWidth: 40, alignment: .trailing)
                            Stepper("", value: $breakDuration, in: 5...30)
                                .labelsHidden()
                        }
                    }

                    configRow("점심시간 전 수업 수") {
                        HStack {
                            Text("\(lunchAfterPeriod)교시 후")
                                .monospacedDigit()
                                .frame(minWidth: 70, alignment: .trailing)
                            Stepper("", value: $lunchAfterPeriod, in: 1...10)
                                .labelsHidden()
                        }
                    }

                    // Lunch duration
                    configRow("점심시간 (분)") {
                        HStack {
                            Text("\(lunchDuration)분")
                                .monospacedDigit()
                                .frame(minWidth: 40, alignment: .trailing)
                            Stepper("", value: $lunchDuration, in: 30...90)
                                .labelsHidden()
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // Preview
                    Text("시간표 미리보기")
                        .font(.headline)

                    VStack(spacing: 4) {
                        ForEach(0..<previewSlots.count, id: \.self) { index in
                            let slot = previewSlots[index]
                            HStack {
                                slotLabel(slot)
                                Spacer()
                                Text("\(Self.timeFormatter.string(from: slot.startTime)) - \(Self.timeFormatter.string(from: slot.endTime))")
                                    .font(.callout)
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(slotBackground(slot))
                            .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            Divider()

            // Done button
            HStack {
                Spacer()
                Button("완료") {
                    settingsStore.periodConfig = currentConfig
                    settingsStore.savePeriodConfig()
                    settingsStore.hasCompletedOnboarding = true
                    timetableStore.regenerateSlots()
                    Task { await timetableStore.refreshTimetable() }
                    NSApp.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
                .padding(16)
            }
        }
        .onAppear {
            let config = settingsStore.periodConfig
            startHour = config.startHour
            startMinute = config.startMinute
            classDuration = config.classDuration
            breakDuration = config.breakDuration
            lunchAfterPeriod = config.lunchAfterPeriod
            lunchDuration = config.lunchDuration
            totalPeriods = config.totalPeriods
        }
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private func configRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }

    @ViewBuilder
    private func slotLabel(_ slot: PeriodTimeSlot) -> some View {
        switch slot.type {
        case .class:
            Text("\(slot.period)교시")
                .font(.callout)
                .fontWeight(.medium)
        case .break:
            Text("쉬는 시간")
                .font(.caption)
                .foregroundColor(.secondary)
        case .lunch:
            Text("점심시간")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }

    private func slotBackground(_ slot: PeriodTimeSlot) -> Color {
        switch slot.type {
        case .class:
            return Color.accentColor.opacity(0.06)
        case .break:
            return Color.clear
        case .lunch:
            return Color.orange.opacity(0.06)
        }
    }
}
