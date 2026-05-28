// Views/Learning/SpellingView.swift
import SwiftUI
import AVFoundation

struct SpellingView: View {
    let word: Word
    let onResult: (Bool) -> Void

    @State private var userInput: String = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @FocusState private var isFocused: Bool

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 24) {
            Text("听发音，拼出单词")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: speak) {
                Image(systemName: "speaker.wave.2.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }

            TextField("输入单词...", text: $userInput)
                .textFieldStyle(.plain)
                .font(.system(size: 28, design: .monospaced))
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .disabled(showResult)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if showResult {
                VStack(spacing: 12) {
                    Text(isCorrect ? "✓ 正确！" : "✗ 正确拼写：\(word.word)")
                        .font(.headline)
                        .foregroundColor(isCorrect ? .green : .red)
                    Button("继续") { onResult(isCorrect) }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Button("确认") { checkSpelling() }
                    .buttonStyle(.bordered)
                    .disabled(userInput.trimmed().isEmpty)
            }
        }
        .padding()
        .onAppear { isFocused = true; speak() }
    }

    private func speak() {
        let utterance = AVSpeechUtterance(string: word.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }

    private func checkSpelling() {
        isCorrect = userInput.trimmed().lowercased() == word.word.lowercased()
        showResult = true
    }
}

extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
