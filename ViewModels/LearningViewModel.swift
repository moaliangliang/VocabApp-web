// ViewModels/LearningViewModel.swift
import Foundation
import SwiftData

enum LearningMode: CaseIterable {
    case choice
    case card
    case spelling
}

enum LearningState {
    case idle                     // 今日还未开始
    case inSession(currentMode: LearningMode, wordIndex: Int)
    case wordResult(mode: LearningMode, word: Word, correct: Bool)
    case sessionComplete
    case allDone                  // 今日全部完成
}

@Observable
final class LearningViewModel {
    private let modelContext: ModelContext
    private let scheduler: ReviewScheduler

    var state: LearningState = .idle
    var currentCourse: Course?
    var todayNewWords: [Word] = []
    var todayReviewWords: [Word] = []
    var newWordProgress: (done: Int, total: Int) = (0, 0)
    var reviewProgress: (done: Int, total: Int) = (0, 0)

    // 当前 session 队列
    private var sessionWords: [Word] = []
    private var sessionIndex: Int = 0
    private var choiceResults: [String: Bool] = [:]     // wordID: correct
    private var cardDone: Set<String> = []
    private var spellingResults: [String: Bool] = [:]

    var currentWord: Word? {
        guard sessionIndex < sessionWords.count else { return nil }
        return sessionWords[sessionIndex]
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.scheduler = ReviewScheduler(modelContainer: modelContext.container)
    }

    @MainActor
    func loadCourse(_ course: Course) async {
        currentCourse = course
        let courseID = course.id
        // 从 db 加载课程相关记录
        let wordBank = WordBankLoader.loadWords(courseID: courseID)
        // 查验哪些 word 已有 LearningRecord
        // 简化：第一次使用时导入词库到 Word 表
        let existingWords = try? modelContext.fetch(FetchDescriptor<Word>(
            predicate: #Predicate { $0.courseID == courseID }
        ))
        if existingWords?.isEmpty ?? true {
            for w in wordBank {
                modelContext.insert(w)
            }
            // 为每个词创建 LearningRecord
            for w in wordBank {
                let record = LearningRecord(id: "user_\(w.id)", wordID: w.id, courseID: courseID)
                modelContext.insert(record)
            }
            try? modelContext.save()
        }

        await refreshProgress()
    }

    @MainActor
    func refreshProgress() async {
        guard let course = currentCourse else { return }
        let courseID = course.id
        let stats = try? await scheduler.getTodayStats(for: courseID)
        // 简化：从 LearningRecord 中统计
        let records = try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.courseID == courseID && $0.mastery > 0 }
        ))
        let newWordsCount = records?.filter { $0.mastery == 1 && Calendar.current.isDateInToday($0.lastReviewDate ?? Date()) }.count ?? 0
        let totalNewGoal = UserDefaults.standard.integer(forKey: "dailyNewWordGoal").nonZero

        let dueRecords = (try? await scheduler.getDueRecords(for: courseID)) ?? []
        newWordProgress = (newWordsCount, totalNewGoal)
        reviewProgress = (dueRecords.filter { $0.mastery > 1 }.count, dueRecords.count)
    }

    // 开始今日学习
    @MainActor
    func startSession() {
        guard let course = currentCourse else { return }
        let courseID = course.id
        var descriptor = FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.courseID == courseID && !$0.allModesDoneToday }
        )
        descriptor.sortBy = [SortDescriptor(\.nextReviewDate)]
        let records = try? modelContext.fetch(descriptor)

        let wordIDs = records?.map { $0.wordID } ?? []

        let allCourseWords = try? modelContext.fetch(
            FetchDescriptor<Word>(predicate: #Predicate { $0.courseID == courseID })
        )
        let allWords = allCourseWords ?? []
        let words = allWords.filter { wordIDs.contains($0.id) }

        let recordByWordID = Dictionary(uniqueKeysWithValues: (records ?? []).map { ($0.wordID, $0) })

        // 优先复习，再加入新词
        let reviewWords = words.filter { w in
            (recordByWordID[w.id]?.mastery ?? 0) > 0
        }
        let newWords = words.filter { w in
            (recordByWordID[w.id]?.mastery ?? 0) == 0
        }

        sessionWords = reviewWords + newWords
        sessionIndex = 0
        state = .inSession(currentMode: .choice, wordIndex: 0)
    }

    // 模式切换
    func advanceMode(for wordID: String, correct: Bool) {
        switch state {
        case .inSession(let mode, let index):
            switch mode {
            case .choice:
                choiceResults[wordID] = correct
                state = .inSession(currentMode: .card, wordIndex: index)
            case .card:
                cardDone.insert(wordID)
                state = .inSession(currentMode: .spelling, wordIndex: index)
            case .spelling:
                spellingResults[wordID] = correct
                // 完成三种模式 → 更新 LearningRecord
                updateRecord(wordID: wordID, choiceCorrect: choiceResults[wordID] ?? false,
                             spellingCorrect: correct)
                // 移动到下一个词
                let nextIndex = index + 1
                if nextIndex < sessionWords.count {
                    sessionIndex = nextIndex
                    state = .inSession(currentMode: .choice, wordIndex: nextIndex)
                } else {
                    state = .sessionComplete
                }
            }
        default:
            break
        }
    }

    private func updateRecord(wordID: String, choiceCorrect: Bool, spellingCorrect: Bool) {
        let records = try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.wordID == wordID }
        ))
        guard let record = records?.first else { return }

        record.choiceDoneToday = true
        record.cardDoneToday = true
        record.spellingDoneToday = true

        if choiceCorrect { record.choiceCorrectCount += 1 } else { record.choiceWrongCount += 1 }
        record.cardFlipCount += 1
        if spellingCorrect { record.spellingCorrectCount += 1 } else { record.spellingWrongCount += 1 }

        // 计算综合质量分
        let quality: Int
        if choiceCorrect && spellingCorrect {
            quality = 4   // 认识
        } else if choiceCorrect || spellingCorrect {
            quality = 2   // 模糊
        } else {
            quality = 0   // 不认识
        }

        let result = SM2Engine.calculate(quality: quality, repetitions: record.repetitions,
                                          easeFactor: record.easeFactor, previousInterval: record.interval)
        record.repetitions = result.repetitions
        record.interval = result.interval
        record.easeFactor = result.easeFactor
        record.nextReviewDate = Date().addingTimeInterval(result.interval)
        record.lastReviewDate = Date()
        record.mastery = SM2Engine.masteryScore(for: record.choiceCorrectCount + record.spellingCorrectCount)

        try? modelContext.save()
    }
}

extension Int {
    var nonZero: Int { self == 0 ? 10 : self }
}
