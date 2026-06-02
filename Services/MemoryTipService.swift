import Foundation

struct MemoryTip: Codable, Equatable {
    let type: String
    let content: String
    let icon: String
}

enum MemoryTipService {
    @MainActor private static var _db: [String: [MemoryTip]]?

    @MainActor
    private static func loadDatabase() -> [String: [MemoryTip]] {
        if let cached = _db { return cached }
        guard let url = Bundle.main.url(forResource: "mnemonics", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mnemonicsDict = json["mnemonics"] as? [String: [[String: String]]]
        else {
            _db = [:]
            return [:]
        }

        var db: [String: [MemoryTip]] = [:]
        for (word, tipsArray) in mnemonicsDict {
            let tips = tipsArray.compactMap { dict -> MemoryTip? in
                guard let type = dict["type"], let content = dict["content"], let icon = dict["icon"] else { return nil }
                return MemoryTip(type: type, content: content, icon: icon)
            }
            if !tips.isEmpty {
                db[word.lowercased()] = tips
            }
        }
        _db = db
        return db
    }

    @MainActor
    static func generateTips(for word: Word) -> [MemoryTip] {
        let db = loadDatabase()
        let wordKey = word.word.lowercased()

        if let dbTips = db[wordKey] {
            return dbTips
        }

        return generateFallbackTips(for: word)
    }

    private static func generateFallbackTips(for word: Word) -> [MemoryTip] {
        var tips: [MemoryTip] = []

        if !word.rootAffix.isEmpty {
            tips.append(MemoryTip(
                type: "词根词缀",
                content: word.rootAffix,
                icon: "cube.transparent"
            ))
        }

        if let structureTip = structureTip(for: word.word) {
            tips.append(structureTip)
        }

        if let associationTip = associationTip(for: word.word, meaning: word.meaning) {
            tips.append(associationTip)
        }

        if !word.examples.isEmpty {
            tips.append(MemoryTip(
                type: "例句记忆",
                content: "通过例句记忆单词用法：\"\(word.examples[0])\"",
                icon: "text.quote"
            ))
        }

        return tips
    }

    private static func structureTip(for word: String) -> MemoryTip? {
        let lower = word.lowercased()

        let prefixes: [(String, String)] = [
            ("un", "否定前缀 un- 表示\"不、非\""),
            ("re", "前缀 re- 表示\"再次、重新\""),
            ("pre", "前缀 pre- 表示\"在前、预先\""),
            ("mis", "前缀 mis- 表示\"错误、不当\""),
            ("dis", "前缀 dis- 表示\"否定、相反\""),
            ("in", "前缀 in- 表示\"在内、不\""),
            ("im", "前缀 im- 表示\"不、无\""),
            ("ir", "前缀 ir- 表示\"不、无\""),
            ("il", "前缀 il- 表示\"不、无\""),
            ("over", "前缀 over- 表示\"过度、在上\""),
            ("under", "前缀 under- 表示\"在…下、不足\""),
            ("inter", "前缀 inter- 表示\"在…之间、相互\""),
            ("trans", "前缀 trans- 表示\"跨越、转变\""),
            ("semi", "前缀 semi- 表示\"半、部分\""),
            ("multi", "前缀 multi- 表示\"多、多种\""),
            ("anti", "前缀 anti- 表示\"反对、防止\""),
            ("auto", "前缀 auto- 表示\"自己、自动\""),
            ("bi", "前缀 bi- 表示\"二、双\""),
            ("co", "前缀 co- 表示\"共同、一起\""),
            ("de", "前缀 de- 表示\"去掉、向下\""),
            ("ex", "前缀 ex- 表示\"向外、前任\""),
            ("fore", "前缀 fore- 表示\"前、预\""),
            ("micro", "前缀 micro- 表示\"微、小\""),
            ("mid", "前缀 mid- 表示\"中、中间\""),
            ("mini", "前缀 mini- 表示\"小、迷你\""),
            ("out", "前缀 out- 表示\"超过、向外\""),
            ("post", "前缀 post- 表示\"后、之后\""),
            ("sub", "前缀 sub- 表示\"下、子\""),
            ("super", "前缀 super- 表示\"超级、上方\""),
            ("tele", "前缀 tele- 表示\"远、远程\""),
            ("vice", "前缀 vice- 表示\"副、代理\""),
        ]

        for (prefix, tip) in prefixes {
            if lower.hasPrefix(prefix) && lower.count > prefix.count + 2 {
                let root = String(lower.dropFirst(prefix.count))
                return MemoryTip(
                    type: "构词法",
                    content: "\(tip) \n「\(prefix) + \(root)」= \(word)",
                    icon: "puzzlepiece.extension"
                )
            }
        }

        let suffixes: [(String, String)] = [
            ("tion", "名词后缀 -tion 表示\"…行为/状态\""),
            ("sion", "名词后缀 -sion 表示\"…行为/状态\""),
            ("ment", "名词后缀 -ment 表示\"…行为/结果\""),
            ("ness", "名词后缀 -ness 表示\"…性质/状态\""),
            ("ity", "名词后缀 -ity 表示\"…性质/状态\""),
            ("ance", "名词后缀 -ance 表示\"…行为/状态\""),
            ("ence", "名词后缀 -ence 表示\"…行为/状态\""),
            ("able", "形容词后缀 -able 表示\"可…的\""),
            ("ible", "形容词后缀 -ible 表示\"可…的\""),
            ("ful", "形容词后缀 -ful 表示\"充满…的\""),
            ("less", "形容词后缀 -less 表示\"没有…的\""),
            ("ous", "形容词后缀 -ous 表示\"具有…的\""),
            ("ive", "形容词后缀 -ive 表示\"有…性质的\""),
            ("al", "形容词后缀 -al 表示\"…的\""),
            ("ly", "副词后缀 -ly 表示\"…地\""),
            ("ize", "动词后缀 -ize 表示\"使…化\""),
            ("ify", "动词后缀 -ify 表示\"使…\""),
            ("ate", "动词后缀 -ate 表示\"使…\""),
            ("er", "名词后缀 -er 表示\"做…的人\""),
            ("or", "名词后缀 -or 表示\"做…的人\""),
            ("ist", "名词后缀 -ist 表示\"…主义者/家\""),
            ("ism", "名词后缀 -ism 表示\"…主义\""),
            ("ology", "名词后缀 -ology 表示\"…学/学科\""),
        ]

        for (suffix, tip) in suffixes {
            if lower.hasSuffix(suffix) && lower.count > suffix.count + 2 {
                return MemoryTip(
                    type: "构词法",
                    content: tip,
                    icon: "puzzlepiece.extension"
                )
            }
        }

        return nil
    }

    private static func associationTip(for word: String, meaning: String) -> MemoryTip? {
        let lower = word.lowercased()

        let associations: [(String, String)] = [
            ("ambition", "谐音「俺必胜」→ 有雄心壮志就能赢"),
            ("ambulance", "谐音「俺不能死」→ 救护车来了"),
            ("pregnant", "谐音「扑来个男的」→ 怀孕了"),
            ("economy", "谐音「依靠农民」→ 经济的基础"),
            ("pest", "谐音「拍死它」→ 害虫"),
            ("flee", "谐音「飞离」→ 逃跑"),
            ("shark", "谐音「杀客」→ 鲨鱼"),
            ("obstacle", "谐音「不是太抠」→ 但仍然是障碍"),
            ("famous", "谐音「 fame 名声 + ous → 著名的"),
            ("hesitate", "he(他) + sit(坐) + ate(吃) → 他坐着吃，犹豫不决"),
            ("island", "is(是) + land(陆地) → 是陆地 → 岛也是陆地"),
            ("candidate", "can(能) + did(做) + ate(吃) → 能做能吃 → 候选人"),
        ]

        for (key, tip) in associations {
            if lower == key {
                return MemoryTip(
                    type: "联想记忆",
                    content: tip,
                    icon: "brain"
                )
            }
        }

        for pattern in ["ough", "ight", "eigh"] where lower.contains(pattern) {
            let patternTips: [String: String] = [
                "ough": "注意 ough 的发音变化：though(ðoʊ)/through(θruː)/thought(θɔːt)",
                "ight": "ight 统一发音为 /aɪt/，如 light/right/night",
                "eigh": "eigh 统一发音为 /eɪ/，如 eight/weigh/neighbor",
            ]
            if let tip = patternTips[pattern] {
                return MemoryTip(
                    type: "发音提示",
                    content: tip,
                    icon: "ear"
                )
            }
        }

        return nil
    }
}
