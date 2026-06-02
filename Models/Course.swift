// Models/Course.swift
import Foundation

struct Course: Identifiable {
    let id: String          // "CET4"
    let name: String        // "四级词汇"
    let desc: String        // 课程描述
    let wordCount: Int

    init(id: String, name: String, desc: String, wordCount: Int) {
        self.id = id
        self.name = name
        self.desc = desc
        self.wordCount = wordCount
    }
}
