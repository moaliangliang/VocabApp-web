// Services/TTSPlayer.swift
import AVFoundation

@MainActor
final class TTSPlayer {
    static let shared = TTSPlayer()
    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(_ text: String, language: String = "en-US") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}
