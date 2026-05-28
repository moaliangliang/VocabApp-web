// Models/DailyLog.swift
import Foundation
import SwiftData

@Model
final class DailyLog: @unchecked Sendable {
    @Attribute(.unique) var date: Date          // yyyy-MM-dd 的日期
    var newWordsLearned: Int = 0                // 当日新学词数
    var reviewsDone: Int = 0                    // 当日复习词数
    var totalStudyMinutes: Int = 0              // 学习分钟数
    var isMakeup: Bool = false                  // 是否补签
    var isCompleted: Bool = false               // 是否完成打卡

    init(date: Date) {
        self.date = date
    }
}
