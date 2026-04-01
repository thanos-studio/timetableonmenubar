import Foundation

enum PeriodCalculator {
    static func generateSlots(from config: PeriodConfig, on date: Date) -> [PeriodTimeSlot] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = config.startHour
        components.minute = config.startMinute
        components.second = 0

        guard var cursor = calendar.date(from: components) else { return [] }

        var slots: [PeriodTimeSlot] = []

        for period in 1...config.totalPeriods {
            // Class slot
            let classEnd = cursor.addingTimeInterval(TimeInterval(config.classDuration * 60))
            slots.append(PeriodTimeSlot(period: period, startTime: cursor, endTime: classEnd, type: .class))
            cursor = classEnd

            if period == config.lunchAfterPeriod {
                // Lunch slot
                let lunchEnd = cursor.addingTimeInterval(TimeInterval(config.lunchDuration * 60))
                slots.append(PeriodTimeSlot(period: period, startTime: cursor, endTime: lunchEnd, type: .lunch))
                cursor = lunchEnd
            } else if period < config.totalPeriods {
                // Break slot
                let breakEnd = cursor.addingTimeInterval(TimeInterval(config.breakDuration * 60))
                slots.append(PeriodTimeSlot(period: period, startTime: cursor, endTime: breakEnd, type: .break))
                cursor = breakEnd
            }
        }

        return slots
    }

    static func currentPeriodSlot(at date: Date, slots: [PeriodTimeSlot]) -> PeriodTimeSlot? {
        return slots.first { slot in
            slot.startTime <= date && date < slot.endTime
        }
    }

    static func nextPeriodSlot(at date: Date, slots: [PeriodTimeSlot]) -> PeriodTimeSlot? {
        return slots.first { slot in
            slot.startTime > date
        }
    }

    static func remainingTime(at date: Date, in slot: PeriodTimeSlot) -> TimeInterval {
        return slot.endTime.timeIntervalSince(date)
    }

    static func isSchoolHours(at date: Date, slots: [PeriodTimeSlot]) -> Bool {
        return slots.contains { slot in
            slot.startTime <= date && date < slot.endTime
        }
    }
}
