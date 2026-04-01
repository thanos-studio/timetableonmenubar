import SwiftUI
import Foundation

struct WeeklyView: View {
    @EnvironmentObject var timetableStore: TimetableStore

    private static let weekdays = ["월", "화", "수", "목", "금"]

    private var todayKey: String? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let index = weekday - 2
        guard index >= 0, index < Self.weekdays.count else { return nil }
        return Self.weekdays[index]
    }

    private var maxPeriods: Int {
        guard let timetable = timetableStore.weeklyTimetable else { return 0 }
        return Self.weekdays.compactMap { timetable.days[$0]?.count }.max() ?? 0
    }

    var body: some View {
        if timetableStore.weeklyTimetable == nil || maxPeriods == 0 {
            emptyState
        } else {
            gridContent
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("📋")
                .font(.system(size: 48))
            Text("시간표 데이터가 없습니다")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Grid

    private var gridContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                Divider()
                ForEach(1...maxPeriods, id: \.self) { period in
                    periodRow(period)
                    if period < maxPeriods {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Header row

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 28)

            ForEach(Self.weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(day == todayKey ? Color.accentColor : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Period row

    private func periodRow(_ period: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(period)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 28)

            ForEach(Self.weekdays, id: \.self) { day in
                cellView(day: day, period: period)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Cell

    private func cellView(day: String, period: Int) -> some View {
        let entry = timetableStore.weeklyTimetable?.days[day]?[safe: period - 1]
        let isToday = day == todayKey

        return ZStack {
            if isToday {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.05))
            }

            if let entry, entry.changed {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.12))
            }

            if let entry, !entry.subject.isEmpty {
                VStack(spacing: 1) {
                    HStack(spacing: 1) {
                        Text(entry.subject)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        if entry.changed {
                            Text("🔄")
                                .font(.system(size: 7))
                        }
                    }
                    if !entry.teacher.isEmpty {
                        Text(entry.teacher)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 2)
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
