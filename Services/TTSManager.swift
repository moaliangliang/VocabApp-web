// Services/TTSManager.swift
// 高质量 TTS 朗读管理 — 智能语调、分角色朗读、Premium 语音检测
import AVFoundation

enum TTSManager {
    // MARK: - 语音选择

    /// 按质量排序选择最佳语音
    private static func bestVoice(gender: AVSpeechSynthesisVoiceGender? = nil) -> AVSpeechSynthesisVoice? {
        let available = AVSpeechSynthesisVoice.speechVoices().filter { v in
            guard v.language == "en-US" else { return false }
            if let gender = gender, v.gender != gender, v.gender != .unspecified { return false }
            return true
        }

        return available.max(by: { a, b in
            let rank: (AVSpeechSynthesisVoiceQuality) -> Int = {
                switch $0 {
                case .premium: return 3
                case .enhanced: return 2
                case .default: return 1
                @unknown default: return 0
                }
            }
            if rank(a.quality) != rank(b.quality) { return rank(a.quality) < rank(b.quality) }
            return a.identifier < b.identifier
        })
    }

    static var bestEnglishVoice: AVSpeechSynthesisVoice? { bestVoice() }

    /// 最佳女声（用于角色 A）
    static var femaleVoice: AVSpeechSynthesisVoice? { bestVoice(gender: .female) }

    /// 最佳男声（先试 Tom，再试 Siri 男声，最后按质量排序）
    static var maleVoice: AVSpeechSynthesisVoice? {
        let preferred: [String] = [
            "com.apple.voice.compact.en-US.Tom",
            "com.apple.ttsbundle.siri_male_en-US_compact",
        ]
        for id in preferred {
            if let v = AVSpeechSynthesisVoice(identifier: id) { return v }
        }
        // 回退：按质量排序选最佳男声
        return bestVoice(gender: .male) ?? bestVoice()
    }

    /// 是否已安装 Premium 语音
    static var hasPremiumVoice: Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { $0.language == "en-US" && $0.quality == .premium }
    }

    // MARK: - 智能语调参数

    private static let baseRate: Float = 0.44

    /// 根据句子类型和说话人生成朗读请求
    static func utterance(_ text: String, speaker: String? = nil) -> AVSpeechUtterance {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastChar = trimmed.last ?? "."

        let u = AVSpeechUtterance(string: trimmed)
        // 分角色：A=女声, B=男声, 其他=默认
        if let speaker = speaker {
            u.voice = (speaker == "A" || speaker == "a") ? femaleVoice
                    : (speaker == "B" || speaker == "b") ? maleVoice
                    : bestEnglishVoice
        } else {
            u.voice = bestEnglishVoice
        }
        u.volume = 1.0

        switch lastChar {
        case "?":
            u.rate = baseRate - 0.02
            u.pitchMultiplier = speaker == "A" ? 1.15 : speaker == "B" ? 0.95 : 1.12
        case "!":
            u.rate = baseRate + 0.03
            u.pitchMultiplier = 1.08
        case "—", "…":
            u.rate = baseRate - 0.05
            u.pitchMultiplier = 0.92
        default:
            u.rate = baseRate
            u.pitchMultiplier = speaker == "A" ? 1.05 : speaker == "B" ? 0.9 : 1.0
        }

        return u
    }

    /// 句间停顿（秒）
    static func pauseDuration(for text: String, isLastInParagraph: Bool = false) -> TimeInterval {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastChar = trimmed.last ?? "."
        switch lastChar {
        case "?":
            return 0.5
        case "!":
            return 0.5
        case "—", "…":
            return 0.6
        default:
            return isLastInParagraph ? 0.8 : 0.3
        }
    }

    /// 批量生成 utterance（逐句朗读用）
    static func utterances(_ sentences: [String]) -> [AVSpeechUtterance] {
        sentences.enumerated().map { i, s in
            let u = utterance(s)
            u.postUtteranceDelay = pauseDuration(for: s, isLastInParagraph: i == sentences.count - 1)
            return u
        }
    }
}
