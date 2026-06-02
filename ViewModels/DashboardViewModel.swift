// ViewModels/DashboardViewModel.swift
import Foundation
import SwiftData

struct CourseProgress {
    let id: String
    let name: String
    let totalWords: Int
    let masteredWords: Int
    let learningWords: Int
    let color: String  // hex or name for mapping

    var fraction: Double {
        totalWords > 0 ? Double(masteredWords) / Double(totalWords) : 0
    }
}

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
    var courseProgress: [CourseProgress] = []
    var earnedMilestones: [Int] = []
    var nextMilestone: Int?
    var monthNewWords: Int = 0
    var monthReviews: Int = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.streakManager = StreakManager(modelContainer: modelContext.container)
    }

    @MainActor
    func refresh() {
        streak = streakManager.computeStreak()
        earnedMilestones = Constants.milestones.filter { streak >= $0 }
        nextMilestone = Constants.milestones.first { $0 > streak }
        let records = (try? modelContext.fetch(FetchDescriptor<LearningRecord>())) ?? []
        totalWords = records.count
        masteredWords = records.filter { $0.mastery >= 2 }.count
        learningWords = records.filter { $0.mastery == 1 }.count
        masteredFraction = totalWords > 0 ? Double(masteredWords) / Double(totalWords) : 0

        logs = (try? modelContext.fetch(FetchDescriptor<DailyLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))) ?? []

        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        lastMonthLogs = logs.filter { $0.date >= oneMonthAgo }
        monthNewWords = lastMonthLogs.reduce(0) { $0 + $1.newWordsLearned }
        monthReviews = lastMonthLogs.reduce(0) { $0 + $1.reviewsDone }

        // 各课程进度
        let words = (try? modelContext.fetch(FetchDescriptor<Word>())) ?? []
        let courseIDs = Set(words.map(\.courseID))
        let courseNames: [String: String] = [
            "CET4": "四级词汇", "CET6": "六级词汇", "Kaoyan": "考研词汇",
            "TOEFL": "托福词汇", "IELTS": "雅思词汇", "GRE": "GRE词汇"
        ]
        let courseColors: [String: String] = [
            "CET4": "blue", "CET6": "purple", "Kaoyan": "red",
            "TOEFL": "orange", "IELTS": "green", "GRE": "indigo"
        ]

        courseProgress = courseIDs.sorted().map { cid in
            let total = words.filter { $0.courseID == cid }.count
            let mastered = records.filter { $0.courseID == cid && $0.mastery >= 2 }.count
            let learning = records.filter { $0.courseID == cid && $0.mastery == 1 }.count
            return CourseProgress(
                id: cid, name: courseNames[cid] ?? cid,
                totalWords: total, masteredWords: mastered,
                learningWords: learning, color: courseColors[cid] ?? "gray"
            )
        }
    }
}
