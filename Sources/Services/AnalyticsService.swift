import Foundation
import SwiftData

struct AnalyticsService {

    let modelContext: ModelContext

    // MARK: – Daily Metrics

    func dailyFocusedTime(for date: Date = .now) -> TimeInterval {
        let sessions = fetchSessions(for: date, isBreak: false)
        return sessions.reduce(0) { $0 + $1.duration }
    }

    func dailyGoalProgress(for date: Date = .now) -> Double {
        let goal = fetchOrCreateGoal(for: date)
        let focused = dailyFocusedTime(for: date)
        guard goal.targetSeconds > 0 else { return 0 }
        return min(focused / Double(goal.targetSeconds), 1.0)
    }

    func dailyGoal(for date: Date = .now) -> DailyGoal {
        return fetchOrCreateGoal(for: date)
    }

    func tasksCompletedToday() -> Int {
        let sessions = fetchSessions(for: .now, isBreak: false)
        return sessions.count
    }

    func totalTasksToday() -> Int {
        return max(tasksCompletedToday(), 12) // Show against a baseline
    }

    // MARK: – Billable

    func billableAmountToday() -> Double {
        let sessions = fetchSessions(for: .now, isBreak: false)
        return sessions.filter(\.isBillable).reduce(0) { $0 + $1.billableAmount }
    }

    // MARK: – Weekly Activity

    func weeklyActivity() -> [TimeInterval] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        // Monday = 1 in our array
        let mondayOffset = (weekday + 5) % 7

        guard let monday = calendar.date(byAdding: .day, value: Int(-mondayOffset), to: today) else {
            return Array(repeating: 0, count: 7)
        }

        var result: [TimeInterval] = []
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: monday) else {
                result.append(0)
                continue
            }
            result.append(dailyFocusedTime(for: day))
        }
        return result
    }

    // MARK: – Session History

    func recentSessions(limit: Int = 10) -> [TimerSession] {
        var descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate<TimerSession> { !$0.isBreak },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: – Weekly Growth

    func weeklyGrowthPercentage() -> Double {
        let thisWeek = weeklyActivity().reduce(0, +)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7

        guard let lastMonday = calendar.date(byAdding: .day, value: -(mondayOffset + 7), to: today) else {
            return 0
        }

        var lastWeekTotal: TimeInterval = 0
        for dayOffset in 0...mondayOffset {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: lastMonday) else { continue }
            lastWeekTotal += dailyFocusedTime(for: day)
        }

        guard lastWeekTotal > 0 else { return 0 }
        return ((thisWeek - lastWeekTotal) / lastWeekTotal) * 100
    }

    // MARK: – Helpers

    private func fetchSessions(for date: Date, isBreak: Bool) -> [TimerSession] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let breakFilter = isBreak

        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate<TimerSession> {
                $0.startTime >= start && $0.startTime < end && $0.isBreak == breakFilter
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchOrCreateGoal(for date: Date) -> DailyGoal {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return DailyGoal()
        }

        let descriptor = FetchDescriptor<DailyGoal>(
            predicate: #Predicate<DailyGoal> {
                $0.date >= start && $0.date < end
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let goal = DailyGoal(date: date)
        modelContext.insert(goal)
        try? modelContext.save()
        return goal
    }

    // MARK: – Formatted Helpers

    func formattedDailyFocusTime(for date: Date = .now, language: Language = .english) -> String {
        Localization.duration(dailyFocusedTime(for: date), lang: language)
    }

    func formattedWeeklyTotal(language: Language = .english) -> String {
        Localization.duration(weeklyActivity().reduce(0, +), lang: language)
    }
}
