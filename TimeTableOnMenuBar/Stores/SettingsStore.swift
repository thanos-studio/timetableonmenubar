import Foundation
import SwiftUI
import Combine

class SettingsStore: ObservableObject {
    // MARK: - AppStorage (simple types)
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("schoolCode") var schoolCode: Int = 0
    @AppStorage("schoolName") var schoolName: String = ""
    @AppStorage("grade") var grade: Int = 1
    @AppStorage("classNum") var classNum: Int = 1

    // NEIS codes for meal API
    @AppStorage("neisOfficeCode") var neisOfficeCode: String = ""
    @AppStorage("neisSchoolCode") var neisSchoolCode: String = ""

    // MARK: - Published (complex types)
    @Published var periodConfig: PeriodConfig = .defaults
    @Published var cachedTimetable: [ClassTimetable]? = nil
    @Published var cachedMeals: [MealEntry]? = nil
    @Published var cachedWeeklyMeals: [MealEntry]? = nil
    @Published var lastRefreshDate: Date? = nil

    var hasNEISCodes: Bool {
        !neisOfficeCode.isEmpty && !neisSchoolCode.isEmpty
    }

    // MARK: - Init
    init() {
        loadPeriodConfig()
        loadCachedTimetable()
        loadCachedMeals()
        if let interval = UserDefaults.standard.object(forKey: "lastRefreshDate") as? Double {
            lastRefreshDate = Date(timeIntervalSince1970: interval)
        }
    }

    // MARK: - PeriodConfig
    func savePeriodConfig() {
        guard let data = try? JSONEncoder().encode(periodConfig) else { return }
        UserDefaults.standard.set(data, forKey: "periodConfig")
    }

    func loadPeriodConfig() {
        guard let data = UserDefaults.standard.data(forKey: "periodConfig"),
              let config = try? JSONDecoder().decode(PeriodConfig.self, from: data) else {
            periodConfig = .defaults
            return
        }
        periodConfig = config
    }

    // MARK: - Cached Timetable
    func saveCachedTimetable(_ timetable: [ClassTimetable]) {
        guard let data = try? JSONEncoder().encode(timetable) else { return }
        UserDefaults.standard.set(data, forKey: "cachedTimetable")
        lastRefreshDate = Date()
        UserDefaults.standard.set(lastRefreshDate!.timeIntervalSince1970, forKey: "lastRefreshDate")
        cachedTimetable = timetable
    }

    func loadCachedTimetable() {
        guard let data = UserDefaults.standard.data(forKey: "cachedTimetable"),
              let timetable = try? JSONDecoder().decode([ClassTimetable].self, from: data) else {
            cachedTimetable = nil
            return
        }
        cachedTimetable = timetable
    }

    // MARK: - Cached Meals
    func saveCachedMeals(_ meals: [MealEntry]) {
        guard let data = try? JSONEncoder().encode(meals) else { return }
        UserDefaults.standard.set(data, forKey: "cachedMeals")
        cachedMeals = meals
    }

    func saveCachedWeeklyMeals(_ meals: [MealEntry]) {
        guard let data = try? JSONEncoder().encode(meals) else { return }
        UserDefaults.standard.set(data, forKey: "cachedWeeklyMeals")
        cachedWeeklyMeals = meals
    }

    func loadCachedMeals() {
        if let data = UserDefaults.standard.data(forKey: "cachedMeals"),
           let meals = try? JSONDecoder().decode([MealEntry].self, from: data) {
            cachedMeals = meals
        }
        if let data = UserDefaults.standard.data(forKey: "cachedWeeklyMeals"),
           let meals = try? JSONDecoder().decode([MealEntry].self, from: data) {
            cachedWeeklyMeals = meals
        }
    }

    // MARK: - Reset
    func resetAll() {
        let keys = [
            "hasCompletedOnboarding",
            "schoolCode",
            "schoolName",
            "grade",
            "classNum",
            "neisOfficeCode",
            "neisSchoolCode",
            "periodConfig",
            "cachedTimetable",
            "cachedMeals",
            "cachedWeeklyMeals",
            "lastRefreshDate"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        periodConfig = .defaults
        cachedTimetable = nil
        cachedMeals = nil
        cachedWeeklyMeals = nil
        lastRefreshDate = nil
    }
}
