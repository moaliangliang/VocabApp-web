// ViewModels/ReadingViewModel.swift
import Foundation
import SwiftData

struct Article: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let courseID: String
    let level: String
}

@Observable
final class ReadingViewModel {
    private let wordBank: [Word]

    var articles: [Article] = []
    var currentArticle: Article?
    var lookupWord: Word?
    var showWordDetail = false
    var highlightedWords: [String] = []      // 文章中的核心词汇

    init(words: [Word]) {
        self.wordBank = words
        loadDemoArticles()
    }

    private func loadDemoArticles() {
        // 简化：内置一篇示例文章；真实场景从 Resources/Articles/ 加载 JSON
        let cet4Words = wordBank.filter { $0.courseID == "CET4" }
        let highlighted = cet4Words.map { $0.word.lowercased() }
        self.highlightedWords = highlighted

        articles = [
            Article(
                id: "CET4_ART_001",
                title: "The Importance of Learning English",
                content: """
                English is an essential tool for global communication. Many students choose to study hard to master this language. \
                Some people abandon their studies when they face difficulties, but those who persist can access better opportunities. \
                Education accelerates personal growth and opens doors to academic success. \
                The ability to absorb new knowledge is a key skill in today's fast-paced world.
                """,
                courseID: "CET4",
                level: "初级"
            )
        ]
    }

    func lookup(word text: String) {
        let lower = text.lowercased()
        lookupWord = wordBank.first { $0.word.lowercased() == lower }
        if lookupWord != nil { showWordDetail = true }
    }

    func addToLearningQueue(wordID: String) {
        // 标记该词在复习时优先出现（通过修改 nextReviewDate 为过去）
        // 简化：此功能在详细实现中通过 StreakManager 或 LearningRecord 调整
    }
}
