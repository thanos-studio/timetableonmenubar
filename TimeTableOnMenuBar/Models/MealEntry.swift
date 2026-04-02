import Foundation

enum MealType: Int, Codable, Sendable {
    case breakfast = 1
    case lunch = 2
    case dinner = 3

    var label: String {
        switch self {
        case .breakfast: return "조식"
        case .lunch: return "급식"
        case .dinner: return "석식"
        }
    }
}

struct MealItem: Codable, Sendable, Identifiable {
    let name: String
    let allergens: [Int]

    var id: String { name }

    var cleanName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
}

struct MealEntry: Codable, Sendable, Identifiable {
    let date: String          // yyyyMMdd
    let mealType: MealType
    let items: [MealItem]
    let calorie: String?
    let origin: String?

    var id: String { "\(date)-\(mealType.rawValue)" }
}
