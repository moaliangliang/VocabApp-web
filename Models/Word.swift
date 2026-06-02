// Models/Word.swift
import Foundation
import SwiftData

@Model
final class Word: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var word: String
    var phonetic: String
    var meaning: String
    var partOfSpeech: String
    var rootAffix: String
    var courseID: String
    var examplesJSON: String = "[]"
    var synonymsJSON: String = "[]"
    var antonymsJSON: String = "[]"

    var examples: [String] {
        get { decodeJSON(examplesJSON) }
        set { examplesJSON = encodeJSON(newValue) }
    }

    var synonyms: [String] {
        get { decodeJSON(synonymsJSON) }
        set { synonymsJSON = encodeJSON(newValue) }
    }

    var antonyms: [String] {
        get { decodeJSON(antonymsJSON) }
        set { antonymsJSON = encodeJSON(newValue) }
    }

    init(id: String, word: String, phonetic: String, meaning: String, partOfSpeech: String,
         examples: [String] = [], rootAffix: String = "", synonyms: [String] = [],
         antonyms: [String] = [], courseID: String) {
        self.id = id
        self.word = word
        self.phonetic = phonetic
        self.meaning = meaning
        self.partOfSpeech = partOfSpeech
        self.rootAffix = rootAffix
        self.courseID = courseID
        self.examplesJSON = encodeJSON(examples)
        self.synonymsJSON = encodeJSON(synonyms)
        self.antonymsJSON = encodeJSON(antonyms)
    }
}

private func encodeJSON(_ arr: [String]) -> String {
    (try? String(data: JSONEncoder().encode(arr), encoding: .utf8)) ?? "[]"
}

private func decodeJSON(_ json: String) -> [String] {
    guard let data = json.data(using: .utf8),
          let arr = try? JSONDecoder().decode([String].self, from: data) else {
        return []
    }
    return arr
}