// Services/StreakManager.swift
import Foundation
import SwiftData

final class StreakManager {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// 从 today 开始向前计算连续打卡天数
    func computeStreak(from today: Date = Date()) -> Int {
        let calendar = Calendar.current
        let ctx = ModelContext(modelContainer)

        let logs = (try? ctx.fetch(FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))) ?? []

        guard !logs.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: today)

        // 检查今天是否已打卡
        let todayLog = logs.first { calendar.isDate($0.date, inSameDayAs: checkDate) }
        if todayLog == nil {
            // 今天没打卡，检查昨天
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        for log in logs {
            if calendar.isDate(log.date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if log.date < checkDate {
                break
            }
        }

        return streak
    }

    /// 获取本月剩余补签次数
    func remainingMakeups(for month: Date = Date()) -> Int {
        let calendar = Calendar.current
        let ctx = ModelContext(modelContainer)

        let range = calendar.range(of: .day, in: .month, for: month)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth)!

        let makeupLogs = (try? ctx.fetch(FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.isMakeup == true && $0.date >= startOfMonth && $0.date <= endOfMonth }
        ))) ?? []

        return max(0, Constants.maxMakeupsPerMonth - makeupLogs.count)
    }

    /// 打卡
    func checkIn(date: Date = Date(), isMakeup: Bool = false) {
        let ctx = ModelContext(modelContainer)
        let startOfDay = Calendar.current.startOfDay(for: date)

        let existing = try? ctx.fetch(FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date == startOfDay }
        ))

        let log = existing?.first ?? DailyLog(date: startOfDay)
        log.isCompleted = true
        log.isMakeup = isMakeup
        if existing?.first == nil { ctx.insert(log) }
        try? ctx.save()
    }
}
