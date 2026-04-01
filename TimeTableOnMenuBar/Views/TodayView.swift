import SwiftUI
import Foundation

struct TodayView: View {
    @EnvironmentObject var timetableStore: TimetableStore

    var body: some View {
        if let errorMessage = timetableStore.errorMessage {
            errorState(errorMessage)
        } else if timetableStore.todayTimetable.isEmpty {
            emptyState
        } else {
            timetableList
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🏖️")
                .font(.system(size: 48))
            Text("오늘은 수업이 없어요")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var timetableList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(
                    Array(timetableStore.todayTimetable.enumerated()),
                    id: \.offset
                ) { offset, entry in
                    let periodNumber = offset + 1
                    let slot = timetableStore.periodSlots.first {
                        $0.type == .class && $0.period == periodNumber
                    }
                    let isCurrent = timetableStore.currentSlot?.period == periodNumber
                        && timetableStore.currentSlot?.type == .class

                    TimetableRowView(
                        entry: entry,
                        period: periodNumber,
                        timeSlot: slot,
                        isCurrent: isCurrent
                    )

                    if offset < timetableStore.todayTimetable.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
