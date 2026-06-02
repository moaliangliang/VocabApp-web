// Services/SemanticGroupService.swift
import Foundation

/// 语义场/同义词群服务
/// 将单词按语义分组，用于：
/// 1. 选择题干扰项生成（同组词义相近，最强干扰）
/// 2. 单词详情页"同类词"展示
/// 3. 批量学习一个语义场
enum SemanticGroupService {
    private static var _groups: [SemanticGroup]?
    private static var _wordIndex: [String: SemanticGroup]?

    private static var groups: [SemanticGroup] {
        if let cached = _groups { return cached }
        guard let url = Bundle.main.url(forResource: "SemanticGroups", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([SemanticGroup].self, from: data)
        else {
            _groups = []
            return []
        }
        _groups = decoded
        // 建立单词 → 词群索引
        var index: [String: SemanticGroup] = [:]
        for group in decoded {
            for sw in group.words {
                index[sw.word.lowercased()] = group
            }
        }
        _wordIndex = index
        return decoded
    }

    /// 获取某个单词所在的语义组
    static func group(for word: String) -> SemanticGroup? {
        _wordIndex?[word.lowercased()] ?? groups.first { g in
            g.words.contains { $0.word.lowercased() == word.lowercased() }
        }
    }

    /// 获取某个单词的同组其他词
    static func peers(for word: String) -> [SemanticWord] {
        guard let g = group(for: word) else { return [] }
        return g.words.filter { $0.word.lowercased() != word.lowercased() }
    }

    /// 获取语义组中除指定词以外的释义列表（用于干扰项）
    static func distractors(for word: String, maxCount: Int = 3) -> [String] {
        peers(for: word).prefix(maxCount).map { $0.meaning }
    }

    static var allGroups: [SemanticGroup] { groups }
}
