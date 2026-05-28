// VocabAppTests/ReviewSchedulerTests.swift
import XCTest
import SwiftData
@testable import VocabApp

final class ReviewSchedulerTests: XCTestCase {

    func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: LearningRecord.self, Word.self, configurations: config)
    }

    func testPendingReviewWordsFiltersByNextReviewDate() async {
        let modelContainer = try! makeContainer()
        let scheduler = ReviewScheduler(modelContainer: modelContainer)

        let now = Date()
        let past = now.addingTimeInterval(-86400)  // 昨天到期
        let future = now.addingTimeInterval(86400)  // 明天才到期

        // 手动构造测试数据（通过 SwiftData context）
        let ctx = ModelContext(modelContainer)
        let record1 = LearningRecord(id: "1", wordID: "CET4_001", courseID: "CET4")
        record1.nextReviewDate = past
        let record2 = LearningRecord(id: "2", wordID: "CET4_002", courseID: "CET4")
        record2.nextReviewDate = future
        ctx.insert(record1)
        ctx.insert(record2)
        try? ctx.save()

        let due = try? await scheduler.getDueRecords(for: "CET4")
        XCTAssertNotNil(due)
        XCTAssertEqual(due?.count, 1)
        XCTAssertEqual(due?.first?.wordID, "CET4_001")
    }

    func testNewWordsForTodayReturnsCorrectCount() async {
        let modelContainer = try! makeContainer()
        let scheduler = ReviewScheduler(modelContainer: modelContainer)
        let ctx = ModelContext(modelContainer)

        // 插入 10 个未学习的词
        for i in 1...10 {
            let record = LearningRecord(id: "\(i)", wordID: "CET4_00\(i)", courseID: "CET4")
            record.mastery = 0
            ctx.insert(record)
        }
        try? ctx.save()

        let newWords = try? await scheduler.getNewWords(for: "CET4", count: 5)
        XCTAssertEqual(newWords?.count, 5)
    }

    func testNoDueRecordsWhenNoneExist() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: LearningRecord.self, configurations: config)
        let scheduler = ReviewScheduler(modelContainer: modelContainer)
        let due = try? await scheduler.getDueRecords(for: "CET4")
        XCTAssertEqual(due?.count, 0)
    }
}
