import Foundation

struct PeriodConfig: Codable {
    var startHour: Int
    var startMinute: Int
    var classDuration: Int
    var breakDuration: Int
    var lunchAfterPeriod: Int
    var lunchDuration: Int
    var totalPeriods: Int

    static var defaults: PeriodConfig {
        PeriodConfig(
            startHour: 8,
            startMinute: 40,
            classDuration: 50,
            breakDuration: 10,
            lunchAfterPeriod: 4,
            lunchDuration: 60,
            totalPeriods: 7
        )
    }
}
