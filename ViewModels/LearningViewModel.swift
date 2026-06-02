// ViewModels/LearningViewModel.swift
import Foundation
import SwiftData

enum LearningMode: CaseIterable {
    case browse
    case choice
    case spelling
}

enum LearningState {
    case idle                     // 今日还未开始
    case inSession(currentMode: LearningMode, wordIndex: Int)
    case sessionComplete
}

@Observable
final class LearningViewModel {
    private let modelContext: ModelContext
    private let scheduler: ReviewScheduler

    var state: LearningState = .idle
    var currentCourse: Course?

    /// 用户选择的本次学习模式（自由组合）
    var selectedModes: [LearningMode] = [.browse, .choice, .spelling]

    var todayNewWords: [Word] = []
    var todayReviewWords: [Word] = []
    var newWordProgress: (done: Int, total: Int) = (0, 0)
    var reviewProgress: (done: Int, total: Int) = (0, 0)
    /// 已掌握词数缓存（避免重复查询）
    var masteredCount: Int = 0

    // 当前 session 队列
    private var sessionWords: [Word] = []
    private var sessionIndex: Int = 0
    /// 当前处于第几个模式（selectedModes 下标）
    private var modeIndex: Int = 0
    private var choiceResults: [String: Bool] = [:]     // wordID: correct
    private var spellingResults: [String: Bool] = [:]

    var currentWord: Word? {
        guard sessionIndex < sessionWords.count else { return nil }
        return sessionWords[sessionIndex]
    }

    var currentMode: LearningMode? {
        guard modeIndex < selectedModes.count else { return nil }
        return selectedModes[modeIndex]
    }

    var currentWordIndex: Int { sessionIndex }
    var totalWords: Int { sessionWords.count }
    var hasNext: Bool { sessionIndex + 1 < sessionWords.count }
    var hasPrevious: Bool { sessionIndex > 0 }
    var currentGroupIndex: Int { sessionIndex / 50 + 1 }
    var totalGroups: Int { max(1, (sessionWords.count + 49) / 50) }
    var wordIndexInGroup: Int { sessionIndex % 50 + 1 }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.scheduler = ReviewScheduler(modelContainer: modelContext.container)
    }

    @MainActor
    func loadCourse(_ course: Course) async {
        let courseID = course.id
        let wordBank = WordBankLoader.loadWords(courseID: courseID)

        let existingWords = try? modelContext.fetch(FetchDescriptor<Word>(
            predicate: #Predicate { $0.courseID == courseID }
        ))
        if existingWords?.isEmpty ?? true {
            for w in wordBank {
                modelContext.insert(w)
            }
            for w in wordBank {
                let record = LearningRecord(id: "user_\(w.id)", wordID: w.id, courseID: courseID)
                modelContext.insert(record)
            }
            try? modelContext.save()
        }

        currentCourse = course
        await refreshProgress()
    }

    @MainActor
    func refreshProgress() async {
        guard let course = currentCourse else { return }
        let courseID = course.id

        let records = try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.courseID == courseID && $0.mastery > 0 }
        ))
        let newWordsCount = records?.filter { $0.mastery == 1 && Calendar.current.isDateInToday($0.lastReviewDate ?? Date()) }.count ?? 0
        let totalNewGoal = UserDefaults.standard.integer(forKey: "dailyNewWordGoal").nonZero

        let dueRecords = (try? await scheduler.getDueRecords(for: courseID)) ?? []
        newWordProgress = (newWordsCount, totalNewGoal)
        reviewProgress = (dueRecords.filter { $0.mastery > 1 }.count, dueRecords.count)
        masteredCount = (try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.mastery >= 2 }
        )).count) ?? 0
    }

    // MARK: - 开始学习

    /// 开始今日新词学习（包含到期复习 + 新词）
    @MainActor
    func startSession() {
        guard let course = currentCourse, !selectedModes.isEmpty else { return }
        let courseID = course.id
        loadWordsIfNeeded(courseID: courseID)

        let allWords = allCourseWords(courseID: courseID)
        let now = Date()

        // 1. 到期复习
        let dueRecords = (try? modelContext.fetch(
            FetchDescriptor<LearningRecord>(
                predicate: #Predicate { $0.courseID == courseID && $0.mastery > 0 && $0.nextReviewDate <= now },
                sortBy: [SortDescriptor(\.nextReviewDate)]
            )
        )) ?? []

        if !dueRecords.isEmpty {
            let dueWordIDs = Set(dueRecords.map { $0.wordID })
            sessionWords = allWords.filter { dueWordIDs.contains($0.id) }
        } else {
            // 2. 无到期复习 → 学习中（未完成今日模式）+ 新词
            let pendingRecords = (try? modelContext.fetch(
                FetchDescriptor<LearningRecord>(
                    predicate: #Predicate { $0.courseID == courseID && !($0.choiceDoneToday && $0.spellingDoneToday) }
                )
            )) ?? []

            if pendingRecords.isEmpty {
                sessionWords = allWords
            } else {
                let pendingIDs = Set(pendingRecords.map { $0.wordID })
                let pending = allWords.filter { pendingIDs.contains($0.id) }
                let newPending = allWords.filter { !pendingIDs.contains($0.id) }
                sessionWords = pending + newPending
            }
        }

        modeIndex = 0
        sessionIndex = 0
        choiceResults.removeAll()
        spellingResults.removeAll()

        if !sessionWords.isEmpty {
            state = .inSession(currentMode: selectedModes[0], wordIndex: 0)
        }
    }

    /// 仅复习到期单词
    @MainActor
    func startReviewSession() {
        guard let course = currentCourse, !selectedModes.isEmpty else { return }
        let courseID = course.id
        loadWordsIfNeeded(courseID: courseID)
        let now = Date()

        let dueRecords = (try? modelContext.fetch(
            FetchDescriptor<LearningRecord>(
                predicate: #Predicate { $0.courseID == courseID && $0.mastery > 0 && $0.nextReviewDate <= now },
                sortBy: [SortDescriptor(\.nextReviewDate)]
            )
        )) ?? []
        guard !dueRecords.isEmpty else { return }

        let allWords = allCourseWords(courseID: courseID)
        let dueWordIDs = Set(dueRecords.map { $0.wordID })
        sessionWords = allWords.filter { dueWordIDs.contains($0.id) }

        modeIndex = 0
        sessionIndex = 0
        choiceResults.removeAll()
        spellingResults.removeAll()
        state = .inSession(currentMode: selectedModes[0], wordIndex: 0)
    }

    // MARK: - 模式推进

    /// 当前词在当前模式下完成处理，前进到下一个词或下一个模式
    func advanceAfterResult(for wordID: String, mode: LearningMode, correct: Bool) {
        switch mode {
        case .browse:
            // 浏览模式直接更新 SM-2（已由 markAndAdvance 处理）
            break
        case .choice:
            choiceResults[wordID] = correct
        case .spelling:
            spellingResults[wordID] = correct
            // 拼写完成 → 更新 LearningRecord
            let choiceCorrect = choiceResults[wordID] ?? false
            updateRecord(wordID: wordID, choiceCorrect: choiceCorrect, spellingCorrect: correct)
        }

        advanceToNext()
    }

    /// 拼写熔断：拼错时重新进入选择题
    func retryAfterSpellingError(for wordID: String) {
        guard let modeIdx = selectedModes.firstIndex(of: .choice) else {
            advanceToNext()
            return
        }
        // 回到选择题模式（同一个词）
        modeIndex = modeIdx
        state = .inSession(currentMode: .choice, wordIndex: sessionIndex)
    }

    private func advanceToNext() {
        let nextIndex = sessionIndex + 1
        if nextIndex < sessionWords.count {
            sessionIndex = nextIndex
            state = .inSession(currentMode: currentMode!, wordIndex: nextIndex)
        } else {
            // 所有词在当前模式完成 → 进入下一个模式
            advanceMode()
        }
    }

    private func advanceMode() {
        let nextModeIdx = modeIndex + 1
        if nextModeIdx < selectedModes.count {
            modeIndex = nextModeIdx
            sessionIndex = 0
            state = .inSession(currentMode: selectedModes[nextModeIdx], wordIndex: 0)
        } else {
            // 所有模式完成
            state = .sessionComplete
            autoCheckIn()
        }
    }

    // MARK: - SM-2 更新

    private func updateRecord(wordID: String, choiceCorrect: Bool, spellingCorrect: Bool) {
        let records = try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.wordID == wordID }
        ))
        guard let record = records?.first else { return }

        record.choiceDoneToday = true
        record.spellingDoneToday = true

        if choiceCorrect { record.choiceCorrectCount += 1 } else { record.choiceWrongCount += 1 }
        if spellingCorrect { record.spellingCorrectCount += 1 } else { record.spellingWrongCount += 1 }

        // 综合质量分
        let quality: Int
        if choiceCorrect && spellingCorrect {
            quality = 4
        } else if choiceCorrect || spellingCorrect {
            quality = 2
        } else {
            quality = 0
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

    // MARK: - 浏览模式快速标记

    /// 浏览模式左右滑动快速标记：quality=4认识, quality=0不认识 → 更新SM-2并跳到下一个词
    func markAndAdvance(quality: Int) {
        guard let word = currentWord else { return }
        let cid = word.courseID
        let allRecords = (try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.courseID == cid }
        ))) ?? []
        if let record = allRecords.first(where: { $0.wordID == word.id }) {
            let result = SM2Engine.calculate(quality: quality, repetitions: record.repetitions,
                                              easeFactor: record.easeFactor, previousInterval: record.interval)
            record.repetitions = result.repetitions
            record.interval = result.interval
            record.easeFactor = result.easeFactor
            record.nextReviewDate = Date().addingTimeInterval(result.interval)
            record.lastReviewDate = Date()
            record.mastery = SM2Engine.masteryScore(for: result.repetitions)
        }
        try? modelContext.save()
        advanceToNext()
    }

    // MARK: - 浏览模式下开始深入学习（进入选择/拼写）

    func startLearningCurrentWord() {
        guard case .inSession(.browse, let index) = state,
              let nextMode = selectedModes.first(where: { $0 != .browse }) else { return }
        // 找到第一个非浏览模式
        if let modeIdx = selectedModes.firstIndex(of: nextMode) {
            modeIndex = modeIdx
            state = .inSession(currentMode: nextMode, wordIndex: index)
        }
    }

    // MARK: - 导航

    func nextWord() {
        guard sessionIndex + 1 < sessionWords.count else { return }
        sessionIndex += 1
        if let mode = currentMode {
            state = .inSession(currentMode: mode, wordIndex: sessionIndex)
        }
    }

    func previousWord() {
        guard sessionIndex > 0 else { return }
        sessionIndex -= 1
        if let mode = currentMode {
            state = .inSession(currentMode: mode, wordIndex: sessionIndex)
        }
    }

    /// 当前词掌握状态描述文本
    var currentMasteryDisplay: String {
        guard let word = currentWord else { return "新词" }
        let cid = word.courseID
        let allRecords = (try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.courseID == cid }
        ))) ?? []
        guard let record = allRecords.first(where: { $0.wordID == word.id }) else { return "新词" }
        if record.mastery == 0 { return "新词" }
        let days = Int(record.nextReviewDate.timeIntervalSince(Date()) / 86400)
        let label: String
        switch record.mastery {
        case 1: label = "学习中"
        case 2: label = "已掌握"
        default: label = "熟练"
        }
        if days <= 0 { return "\(label) · 待复习" }
        if days == 1 { return "\(label) · 明天复习" }
        return "\(label) · \(days)天后复习"
    }

    // MARK: - 自动打卡

    func autoCheckIn() {
        guard let course = currentCourse else { return }
        let courseID = course.id
        let todayStart = Calendar.current.startOfDay(for: Date())

        let records = (try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.courseID == courseID }
        ))) ?? []

        let newToday = records.filter { $0.mastery > 0 && ($0.lastReviewDate ?? todayStart) >= todayStart }.count
        let reviewToday = records.filter { ($0.lastReviewDate ?? todayStart) >= todayStart && $0.repetitions > 0 }.count

        let existing = try? modelContext.fetch(FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date == todayStart }
        ))
        let log = existing?.first ?? DailyLog(date: todayStart)
        log.isCompleted = true
        log.newWordsLearned = newToday
        log.reviewsDone = reviewToday
        if existing?.first == nil { modelContext.insert(log) }
        try? modelContext.save()
    }

    // MARK: - 干扰项生成

    /// 为指定单词生成选择题干扰项
    func distractors(for word: Word) -> [String] {
        let allWords = allCourseWords(courseID: word.courseID)
        return DistractorEngine.generate(for: word, allWords: allWords)
    }

    // MARK: - 工具方法

    private func loadWordsIfNeeded(courseID: String) {
        let existing = try? modelContext.fetch(FetchDescriptor<Word>(
            predicate: #Predicate { $0.courseID == courseID }
        ))
        if existing?.isEmpty ?? true {
            let wordBank = WordBankLoader.loadWords(courseID: courseID)
            guard !wordBank.isEmpty else { return }
            for w in wordBank { modelContext.insert(w) }
            for w in wordBank {
                let record = LearningRecord(id: "user_\(w.id)", wordID: w.id, courseID: courseID)
                modelContext.insert(record)
            }
            try? modelContext.save()
        }
    }

    private func allCourseWords(courseID: String) -> [Word] {
        (try? modelContext.fetch(
            FetchDescriptor<Word>(predicate: #Predicate { $0.courseID == courseID })
        )) ?? []
    }
}

extension Int {
    var nonZero: Int { self == 0 ? 10 : self }
}
