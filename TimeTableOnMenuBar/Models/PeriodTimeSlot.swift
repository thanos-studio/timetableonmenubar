import Foundation

enum PeriodType: String, Codable {
    case `class`
    case `break`
    case lunch
}

struct PeriodTimeSlot: Codable {
    let period: Int
    let startTime: Date
    let endTime: Date
    let type: PeriodType
}
