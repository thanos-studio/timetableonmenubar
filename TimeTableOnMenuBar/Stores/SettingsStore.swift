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

    // MARK: - Published (complex types)
    @Published var periodConfig: PeriodConfig = .defaults
    @Published var cachedTimetable: [ClassTimetable]? = nil
    @Published var lastRefreshDate: Date? = nil

    // MARK: - Init
    init() {
        loadPeriodConfig()
        loadCachedTimetable()
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

    // MARK: - Reset
    func resetAll() {
        let keys = [
            "hasCompletedOnboarding",
            "schoolCode",
            "schoolName",
            "grade",
            "classNum",
            "periodConfig",
            "cachedTimetable",
            "lastRefreshDate"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        periodConfig = .defaults
        cachedTimetable = nil
        lastRefreshDate = nil
    }
}
