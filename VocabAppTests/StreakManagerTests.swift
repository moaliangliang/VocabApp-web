// VocabAppTests/StreakManagerTests.swift
import XCTest
import SwiftData
@testable import VocabApp

final class StreakManagerTests: XCTestCase {

    func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: DailyLog.self, configurations: config)
    }

    func testStreakWithConsecutiveDays() throws {
        let manager = StreakManager(modelContainer: try makeContainer())
        let today = Date()
        let calendar = Calendar.current
        let ctx = ModelContext(manager.modelContainer)

        // 插入连续 5 天打卡
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let log = DailyLog(date: calendar.startOfDay(for: date))
            log.isCompleted = true
            ctx.insert(log)
        }
        try ctx.save()

        // 重新读取（使用测试专用方法）
        let streak = manager.computeStreak(from: today)
        XCTAssertEqual(streak, 5)
    }

    func testStreakBrokenByMissedDay() throws {
        let manager = StreakManager(modelContainer: try makeContainer())
        let today = Date()
        let calendar = Calendar.current
        let ctx = ModelContext(manager.modelContainer)

        // 连续 3 天，但 4 天前断签
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let log = DailyLog(date: calendar.startOfDay(for: date))
            log.isCompleted = true
            ctx.insert(log)
        }
        try ctx.save()

        let streak = manager.computeStreak(from: today)
        XCTAssertEqual(streak, 3)
    }

    func testMakeupCountsTowardStreak() throws {
        let manager = StreakManager(modelContainer: try makeContainer())
        let today = Date()
        let calendar = Calendar.current
        let ctx = ModelContext(manager.modelContainer)

        // 补签昨天
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let log = DailyLog(date: calendar.startOfDay(for: yesterday))
        log.isCompleted = true
        log.isMakeup = true
        ctx.insert(log)

        // 今天也打卡
        let todayLog = DailyLog(date: calendar.startOfDay(for: today))
        todayLog.isCompleted = true
        ctx.insert(todayLog)
        try ctx.save()

        let streak = manager.computeStreak(from: today)
        XCTAssertEqual(streak, 2)
    }

    func testEmptyLogsReturnZero() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let manager = StreakManager(modelContainer: try ModelContainer(for: DailyLog.self, configurations: config))
        let streak = manager.computeStreak(from: Date())
        XCTAssertEqual(streak, 0)
    }
}
