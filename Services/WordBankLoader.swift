// Services/WordBankLoader.swift
import Foundation

struct WordJSON: Codable {
    let id: String
    let word: String
    let phonetic: String
    let partOfSpeech: String
    let meaning: String
    let examples: [String]
    let rootAffix: String
    let synonyms: [String]
    let antonyms: [String]
}

struct WordBankJSON: Codable {
    let courseID: String
    let courseName: String
    let words: [WordJSON]
}

enum WordBankLoader {

    static func load(courseID: String) -> WordBankJSON? {
        guard let url = Bundle.main.url(forResource: courseID, withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WordBankJSON.self, from: data)
    }

    static func loadWords(courseID: String) -> [Word] {
        guard let bank = load(courseID: courseID) else { return [] }
        return bank.words.map { w in
            Word(id: w.id, word: w.word, phonetic: w.phonetic, meaning: w.meaning,
                 partOfSpeech: w.partOfSpeech, examples: w.examples,
                 rootAffix: w.rootAffix, synonyms: w.synonyms, antonyms: w.antonyms,
                 courseID: bank.courseID)
        }
    }

    static func allCourseIDs() -> [String] {
        return ["CET4", "CET6", "Kaoyan", "TOEFL", "IELTS", "GRE"]
    }
}
