// Models/Word.swift
import Foundation
import SwiftData

@Model
final class Word: @unchecked Sendable {
    @Attribute(.unique) var id: String       // 格式: "CET4_001"
    var word: String
    var phonetic: String
    var meaning: String                      // 中文释义
    var partOfSpeech: String                 // 词性
    var examples: [String]                   // 例句数组
    var rootAffix: String                    // 词根词缀拆解
    var synonyms: [String]                   // 同义词
    var antonyms: [String]                   // 反义词
    var courseID: String                     // 所属课程 ID

    init(id: String, word: String, phonetic: String, meaning: String, partOfSpeech: String,
         examples: [String] = [], rootAffix: String = "", synonyms: [String] = [],
         antonyms: [String] = [], courseID: String) {
        self.id = id
        self.word = word
        self.phonetic = phonetic
        self.meaning = meaning
        self.partOfSpeech = partOfSpeech
        self.examples = examples
        self.rootAffix = rootAffix
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.courseID = courseID
    }
}
