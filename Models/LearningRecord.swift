// Models/LearningRecord.swift
import Foundation
import SwiftData

/// 用户对一个单词的学习进度记录
@Model
final class LearningRecord: @unchecked Sendable {
    @Attribute(.unique) var id: String          // "userID_wordID"
    var wordID: String
    var courseID: String

    // SM-2 核心字段
    var repetitions: Int = 0                    // 连续正确回答次数
    var easeFactor: Double = 2.5                // 难度系数，初始 2.5
    var interval: TimeInterval = 0              // 当前复习间隔（秒）
    var nextReviewDate: Date = Date()           // 下次复习时间
    var lastReviewDate: Date?

    // 各模式表现
    var choiceCorrectCount: Int = 0
    var choiceWrongCount: Int = 0
    var cardFlipCount: Int = 0
    var spellingCorrectCount: Int = 0
    var spellingWrongCount: Int = 0

    // 掌握状态
    var mastery: Int = 0                        // 0=未学习, 1=学习中, 2=已掌握, 3=熟练

    // 今天是否已完成三种模式
    var choiceDoneToday: Bool = false
    var cardDoneToday: Bool = false
    var spellingDoneToday: Bool = false

    var allModesDoneToday: Bool {
        choiceDoneToday && cardDoneToday && spellingDoneToday
    }

    init(id: String, wordID: String, courseID: String) {
        self.id = id
        self.wordID = wordID
        self.courseID = courseID
    }
}
