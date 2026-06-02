// Services/DistractorEngine.swift
import Foundation

/// 选择题干扰项生成引擎
///
/// 按优先级从以下来源生成干扰项：
/// 1. 同义词语义场（最强干扰—同义词之间的混淆是考试常见考点）
/// 2. 同词库的其他词（取不同词的释义）
/// 3. 形近词（如有数据）
enum DistractorEngine {

    /// 为指定单词生成 N 个干扰项
    /// - Parameters:
    ///   - word: 当前学习的单词
    ///   - count: 需要的干扰项数量（默认 3）
    ///   - allWords: 同词库的所有单词（用于同词库随机取）
    /// - Returns: 干扰项释义数组
    static func generate(for word: Word, count: Int = 3, allWords: [Word] = []) -> [String] {
        var pool: [String] = []
        var seen = Set<String>()
        seen.insert(word.meaning) // 避免和正确答案重复

        // ----- 第1层：同义词群取 -----
        let groupDistractors = SemanticGroupService.distractors(for: word.word, maxCount: count)
        for d in groupDistractors where !seen.contains(d) {
            pool.append(d)
            seen.insert(d)
        }

        // ----- 第2层：同词库随机取 -----
        if pool.count < count {
            let shuffled = allWords
                .filter { $0.id != word.id && !seen.contains($0.meaning) }
                .shuffled()
                .prefix(count - pool.count)

            for w in shuffled {
                pool.append(w.meaning)
                seen.insert(w.meaning)
            }
        }

        // ----- 第3层：兜底 -----
        let fallbacks = ["拒绝，否认", "接受，承认", "忽略，忽视", "建立，创立", "破坏，摧毁"]
        while pool.count < count {
            for f in fallbacks where !seen.contains(f) {
                pool.append(f)
                seen.insert(f)
                if pool.count >= count { break }
            }
            // 如果 fallbacks 也用完了还不够，从已有池重复
            if pool.count < count {
                pool.append(pool.randomElement() ?? fallbacks[0])
            }
        }

        return pool.shuffled().prefix(count).map { $0 }
    }
}
