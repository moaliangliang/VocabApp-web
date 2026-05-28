// Views/Learning/ChoiceQuizView.swift
import SwiftUI

struct ChoiceQuizView: View {
    let word: Word
    let onAnswer: (Bool) -> Void

    @State private var selectedAnswer: String?
    @State private var showResult = false

    /// 生成 3 个干扰项 + 正确答案
    private var options: [String] {
        // 简化：从同课程其他词取释义作为干扰项
        var pool = [word.meaning]
        // 从预置干扰项中取 3 个
        let distractors = ["拒绝，否认", "接受，承认", "忽略，忽视", "建立，创立", "破坏，摧毁"]
        pool.append(contentsOf: distractors.shuffled().prefix(3))
        return pool.shuffled()
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(word.word)
                .font(.system(size: 36, weight: .bold))

            Text(word.phonetic)
                .font(.title3)
                .foregroundColor(.secondary)

            Text("请选择正确的中文释义")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        guard selectedAnswer == nil else { return }
                        selectedAnswer = option
                        showResult = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            onAnswer(option == word.meaning)
                        }
                    }) {
                        Text(option)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(buttonColor(for: option))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(borderColor(for: option), lineWidth: selectedAnswer == option ? 2 : 1)
                            )
                    }
                    .disabled(selectedAnswer != nil)
                }
            }
        }
        .padding()
    }

    private func buttonColor(for option: String) -> Color {
        guard showResult else { return Color(.systemGray6) }
        if option == word.meaning { return Color.green.opacity(0.2) }
        if option == selectedAnswer { return Color.red.opacity(0.2) }
        return Color(.systemGray6)
    }

    private func borderColor(for option: String) -> Color {
        guard showResult else { return Color.gray.opacity(0.3) }
        if option == word.meaning { return .green }
        if option == selectedAnswer { return .red }
        return Color.gray.opacity(0.3)
    }
}
