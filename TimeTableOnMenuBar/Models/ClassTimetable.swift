import Foundation

struct ClassTimetable: Codable, Sendable {
    let grade: Int
    let classNumber: Int
    let days: [String: [TimetableEntry]]
}
