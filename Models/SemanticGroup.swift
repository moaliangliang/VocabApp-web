// Models/SemanticGroup.swift
import Foundation

struct SemanticGroup: Codable, Identifiable {
    let id: String
    let name: String
    let words: [SemanticWord]
}

struct SemanticWord: Codable, Identifiable {
    let word: String
    let meaning: String

    var id: String { word.lowercased() }
}
