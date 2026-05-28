// ViewModels/DashboardViewModel.swift
import Foundation
import SwiftData

@Observable
final class DashboardViewModel {
    private let modelContext: ModelContext
    private let streakManager: StreakManager

    var totalWords: Int = 0
    var masteredWords: Int = 0
    var learningWords: Int = 0
    var streak: Int = 0
    var masteredFraction: Double = 0
    var logs: [DailyLog] = []
    var lastMonthLogs: [DailyLog] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.streakManager = StreakManager(modelContainer: modelContext.container)
    }

    @MainActor
    func refresh() {
        streak = streakManager.computeStreak()
        let records = (try? modelContext.fetch(FetchDescriptor<LearningRecord>())) ?? []
        totalWords = records.count
        masteredWords = records.filter { $0.mastery >= 2 }.count
        learningWords = records.filter { $0.mastery == 1 }.count
        masteredFraction = totalWords > 0 ? Double(masteredWords) / Double(totalWords) : 0

        logs = (try? modelContext.fetch(FetchDescriptor<DailyLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))) ?? []

        // 上个月记录
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        lastMonthLogs = logs.filter { $0.date >= oneMonthAgo }
    }
}
