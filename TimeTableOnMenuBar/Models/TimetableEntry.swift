import Foundation

struct TimetableEntry: Codable, Sendable {
    let subject: String
    let teacher: String
    let changed: Bool
    let originalSubject: String?
    let originalTeacher: String?
}
