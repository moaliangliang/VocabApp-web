// VocabAppTests/WordBankLoaderTests.swift
import XCTest
@testable import VocabApp

final class WordBankLoaderTests: XCTestCase {

    func testLoadCET4WordsReturnsWords() {
        let words = WordBankLoader.loadWords(courseID: "CET4")
        XCTAssertEqual(words.count, 500)
        XCTAssertEqual(words.first?.word, "abandon")
        XCTAssertEqual(words.first?.courseID, "CET4")
    }

    func testLoadCET6Words() {
        let words = WordBankLoader.loadWords(courseID: "CET6")
        XCTAssertEqual(words.count, 500)
    }

    func testLoadNonexistentCourseReturnsEmpty() {
        let words = WordBankLoader.loadWords(courseID: "NONEXISTENT")
        XCTAssertTrue(words.isEmpty)
    }

    func testWordModelFieldsArePopulated() {
        let words = WordBankLoader.loadWords(courseID: "CET4")
        let first = words.first!
        XCTAssertEqual(first.word, "abandon")
        XCTAssertEqual(first.phonetic, "/əˈbændən/")
        XCTAssertEqual(first.meaning, "放弃，遗弃")
        XCTAssertFalse(first.examples.isEmpty)
        XCTAssertFalse(first.rootAffix.isEmpty)
        XCTAssertFalse(first.synonyms.isEmpty)
        XCTAssertFalse(first.antonyms.isEmpty)
    }
}
