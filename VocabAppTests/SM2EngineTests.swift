// VocabAppTests/SM2EngineTests.swift
import XCTest
@testable import VocabApp

final class SM2EngineTests: XCTestCase {

    func testForgotQualityResetsRepetitions() {
        let result = SM2Engine.calculate(quality: 0, repetitions: 5, easeFactor: 2.5)
        XCTAssertEqual(result.repetitions, 0)
        XCTAssertEqual(result.interval, 60)
    }

    func testForgotQualityShortInterval() {
        let result1 = SM2Engine.calculate(quality: 1, repetitions: 0, easeFactor: 2.5)
        XCTAssertEqual(result1.interval, 60)

        let result2 = SM2Engine.calculate(quality: 0, repetitions: 1, easeFactor: 2.5)
        XCTAssertEqual(result2.interval, 60)
    }

    func test模糊QualityTenMinFirst() {
        let result = SM2Engine.calculate(quality: 2, repetitions: 0, easeFactor: 2.5)
        XCTAssertEqual(result.interval, 600)
        XCTAssertEqual(result.repetitions, 1)
    }

    func test模糊QualityOneDaySecond() {
        let result = SM2Engine.calculate(quality: 3, repetitions: 1, easeFactor: 2.5)
        XCTAssertEqual(result.interval, 86400)
    }

    func test模糊QualityThreeDaysAfterTwo() {
        let result = SM2Engine.calculate(quality: 2, repetitions: 2, easeFactor: 2.5)
        XCTAssertEqual(result.interval, 259200)
    }

    func testRememberedQualityOneDayFirst() {
        let result = SM2Engine.calculate(quality: 4, repetitions: 0, easeFactor: 2.5)
        XCTAssertEqual(result.interval, 86400)
    }

    func testRememberedQualityThreeDaysSecond() {
        let result = SM2Engine.calculate(quality: 5, repetitions: 1, easeFactor: 2.5)
        XCTAssertEqual(result.interval, 259200)
    }

    func testRememberedQualityProgressiveIntervals() {
        let intervals: [TimeInterval] = [86400, 259200, 604800, 1296000, 2592000]
        var reps = 0
        var ef = 2.5
        var lastInterval: TimeInterval = 0

        for expectedInterval in intervals {
            let result = SM2Engine.calculate(quality: 4, repetitions: reps, easeFactor: ef, previousInterval: lastInterval)
            XCTAssertEqual(result.interval, expectedInterval)
            reps = result.repetitions
            ef = result.easeFactor
            lastInterval = result.interval
        }
    }

    func testEaseFactorNeverBelowMin() {
        var ef = 2.5
        for _ in 0..<20 {
            let result = SM2Engine.calculate(quality: 0, repetitions: 0, easeFactor: ef)
            ef = result.easeFactor
        }
        XCTAssertGreaterThanOrEqual(ef, 1.3)
    }

    func testMasteryScoreMapping() {
        XCTAssertEqual(SM2Engine.masteryScore(for: 0), 0)     // 未学习
        XCTAssertEqual(SM2Engine.masteryScore(for: 2), 1)     // 学习中
        XCTAssertEqual(SM2Engine.masteryScore(for: 4), 2)     // 已掌握
        XCTAssertEqual(SM2Engine.masteryScore(for: 6), 3)     // 熟练
    }
}
