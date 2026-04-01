import SwiftUI
import Foundation

struct TimetableRowView: View {
    let entry: TimetableEntry
    let period: Int
    let timeSlot: PeriodTimeSlot?
    let isCurrent: Bool

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Left: period number
            Text("\(period)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(isCurrent ? .accentColor : .primary)
                .frame(width: 44)

            // Center: subject + time + change info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.subject.isEmpty ? "자습" : entry.subject)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)

                if let slot = timeSlot {
                    Text("\(Self.timeFormatter.string(from: slot.startTime)) ~ \(Self.timeFormatter.string(from: slot.endTime))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                if entry.changed,
                   let origSubject = entry.originalSubject {
                    HStack(spacing: 3) {
                        Text("🔄")
                            .font(.system(size: 10))
                        Text(origSubject + (entry.originalTeacher.map { " · \($0)" } ?? ""))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Right: teacher + current badge
            VStack(alignment: .trailing, spacing: 4) {
                if !entry.teacher.isEmpty {
                    Text(entry.teacher)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                if isCurrent {
                    Text("현재")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(currentPeriodBackground)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var currentPeriodBackground: some View {
        if isCurrent {
            if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 10))
            } else {
                Color.primary.opacity(0.05)
            }
        } else {
            Color.clear
        }
    }
}
