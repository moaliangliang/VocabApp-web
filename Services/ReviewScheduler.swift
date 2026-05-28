// Services/ReviewScheduler.swift
import Foundation
import SwiftData

actor ReviewScheduler {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getDueRecords(for courseID: String) async throws -> [LearningRecord] {
        let ctx = ModelContext(modelContainer)
        let now = Date()
        let predicate = #Predicate<LearningRecord> { record in
            record.courseID == courseID && record.nextReviewDate <= now
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.nextReviewDate)])
        return try ctx.fetch(descriptor)
    }

    func getNewWords(for courseID: String, count: Int) async throws -> [LearningRecord] {
        let ctx = ModelContext(modelContainer)
        let predicate = #Predicate<LearningRecord> { record in
            record.courseID == courseID && record.mastery == 0
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.id)])
        let all = try ctx.fetch(descriptor)
        return Array(all.prefix(count))
    }

    func getTodayStats(for courseID: String) async throws -> (new: Int, review: Int, totalMinutes: Int) {
        let ctx = ModelContext(modelContainer)
        let todayStart = Calendar.current.startOfDay(for: Date())

        let allRecords = try ctx.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.courseID == courseID }
        ))

        let newToday = allRecords.filter { $0.mastery == 1 && ($0.lastReviewDate ?? todayStart) >= todayStart }.count
        let reviewsToday = allRecords.filter { ($0.lastReviewDate ?? todayStart) >= todayStart && $0.mastery > 0 }.count

        // totalMinutes 从 DailyLog 取，非此方法计算
        return (newToday, reviewsToday, 0)
    }
}
