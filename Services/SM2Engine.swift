// Services/SM2Engine.swift
import Foundation

struct SM2Result {
    let repetitions: Int
    let interval: TimeInterval
    let easeFactor: Double
}

enum SM2Engine {

    /// quality: 0=不认识, 1=不认识, 2=模糊, 3=模糊, 4=认识, 5=认识
    static func calculate(quality: Int, repetitions: Int, easeFactor: Double,
                          previousInterval: TimeInterval = 0) -> SM2Result {
        let newRepetitions: Int
        let newInterval: TimeInterval
        let clampedQuality = min(max(quality, 0), 5)

        if clampedQuality < 2 {
            // 不认识 — 重置
            newRepetitions = 0
            if previousInterval <= 60 {
                newInterval = 60
            } else if previousInterval <= 600 {
                newInterval = 600
            } else {
                newInterval = 86400   // 当天再学 → 次日
            }
        } else if clampedQuality < 4 {
            // 模糊
            newRepetitions = repetitions + 1
            switch newRepetitions {
            case 1:  newInterval = 600       // 10分钟
            case 2:  newInterval = 86400     // 1天
            default: newInterval = 259200    // 3天
            }
        } else {
            // 认识
            newRepetitions = repetitions + 1
            let rememberedIntervals: [TimeInterval] = [86400, 259200, 604800, 1296000, 2592000]
            // 1天, 3天, 7天, 15天, 30天
            if newRepetitions <= rememberedIntervals.count {
                newInterval = rememberedIntervals[newRepetitions - 1]
            } else {
                newInterval = previousInterval * 2
            }
        }

        // 更新 EF: EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
        var newEF = easeFactor + (0.1 - Double(5 - clampedQuality) * (0.08 + Double(5 - clampedQuality) * 0.02))
        if newEF < 1.3 { newEF = 1.3 }

        return SM2Result(repetitions: newRepetitions, interval: newInterval, easeFactor: newEF)
    }

    /// 将连续正确次数映射为掌握度 (0-3)
    static func masteryScore(for consecutiveCorrect: Int) -> Int {
        switch consecutiveCorrect {
        case ..<1:  return 0
        case 1..<3: return 1
        case 3..<6: return 2
        default:    return 3
        }
    }
}
