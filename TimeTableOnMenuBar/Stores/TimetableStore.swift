import Foundation
import SwiftUI
import Combine

class TimetableStore: ObservableObject {
    // MARK: - Published properties
    @Published var menuBarTitle: String = "🏖️"
    @Published var todayTimetable: [TimetableEntry] = []
    @Published var weeklyTimetable: ClassTimetable? = nil
    @Published var currentSlot: PeriodTimeSlot? = nil
    @Published var isLoading: Bool = false
    @Published var periodSlots: [PeriodTimeSlot] = []
    @Published var lastRefreshDate: Date? = nil

    // MARK: - Private
    private let comciganService = ComciganService()
    private let settingsStore: SettingsStore
    private var timerTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var activityToken: NSObjectProtocol?

    private static let weekdayKeys = ["월", "화", "수", "목", "금"]

    // MARK: - Init
    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore

        // Generate period slots for today
        periodSlots = PeriodCalculator.generateSlots(from: settingsStore.periodConfig, on: Date())

        // Load cached timetable if available
        if let cached = settingsStore.cachedTimetable {
            applyTimetableData(cached)
        }
        lastRefreshDate = settingsStore.lastRefreshDate

        // Prevent App Nap
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Timetable countdown timer"
        )

        startTimerLoop()
        startRefreshLoop()
    }

    nonisolated deinit {
        timerTask?.cancel()
        refreshTask?.cancel()
    }

    // MARK: - Loops

    private func startTimerLoop() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.updateMenuBarTitle()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func startRefreshLoop() {
        refreshTask = Task { [weak self] in
            await self?.refreshTimetable()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_600_000_000_000)
                await self?.refreshTimetable()
            }
        }
    }

    // MARK: - Update menu bar title

    private func updateMenuBarTitle() {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)

        // Weekend check
        if weekday == 1 || weekday == 7 {
            menuBarTitle = "🏖️"
            currentSlot = nil
            return
        }

        // Regenerate slots if date changed
        let todayStart = calendar.startOfDay(for: now)
        if let firstSlot = periodSlots.first,
           calendar.startOfDay(for: firstSlot.startTime) != todayStart {
            periodSlots = PeriodCalculator.generateSlots(from: settingsStore.periodConfig, on: now)
        }

        let slot = PeriodCalculator.currentPeriodSlot(at: now, slots: periodSlots)
        currentSlot = slot

        guard let slot else {
            menuBarTitle = "🏖️"
            return
        }

        let remaining = PeriodCalculator.remainingTime(at: now, in: slot)
        let minutes = Int(ceil(remaining / 60.0))

        switch slot.type {
        case .class:
            let subject = subjectForPeriod(slot.period)
            menuBarTitle = "\(slot.period)교시 \(subject) \(minutes)분"
        case .break:
            menuBarTitle = "쉬는시간 \(minutes)분"
        case .lunch:
            menuBarTitle = "점심시간 \(minutes)분"
        }
    }

    private func subjectForPeriod(_ period: Int) -> String {
        // period is 1-based, todayTimetable array is 0-based
        let index = period - 1
        guard index >= 0, index < todayTimetable.count else { return "자습" }
        let entry = todayTimetable[index]
        return entry.subject.isEmpty ? "자습" : entry.subject
    }

    // MARK: - Refresh timetable

    func refreshTimetable() async {
        guard settingsStore.schoolCode > 0 else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let results = try await comciganService.getTimetable(
                schoolCode: settingsStore.schoolCode,
                grade: settingsStore.grade,
                classNum: settingsStore.classNum
            )
            applyTimetableData(results)
            settingsStore.saveCachedTimetable(results)
            lastRefreshDate = settingsStore.lastRefreshDate
        } catch {
            // Fall back to cached data
            if let cached = settingsStore.cachedTimetable {
                applyTimetableData(cached)
            }
        }
    }

    // MARK: - Helpers

    private func applyTimetableData(_ results: [ClassTimetable]) {
        weeklyTimetable = results.first
        todayTimetable = extractTodayEntries(from: weeklyTimetable)
    }

    private func extractTodayEntries(from timetable: ClassTimetable?) -> [TimetableEntry] {
        guard let timetable else { return [] }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Monday=2 → index 0, Tuesday=3 → index 1, etc.
        let index = weekday - 2
        guard index >= 0, index < Self.weekdayKeys.count else { return [] }
        let key = Self.weekdayKeys[index]
        return timetable.days[key] ?? []
    }
}
