// Views/Learning/CardFlipView.swift
import SwiftUI

struct CardFlipView: View {
    let word: Word
    let onComplete: () -> Void

    @State private var isFlipped = false
    @State private var degree: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // 正面：单词
                cardFront
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (0, 1, 0))

                // 反面：释义
                cardBack
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (0, 1, 0))
            }
            .frame(height: 260)
            .onTapGesture {
                withAnimation(.spring(duration: 0.6)) {
                    isFlipped.toggle()
                }
            }

            if isFlipped {
                Text("点击继续")
                    .foregroundColor(.blue)
                    .onTapGesture { onComplete() }
            } else {
                Text("点击翻卡查看释义")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var cardFront: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(word.word)
                .font(.system(size: 32, weight: .bold))
            Text(word.phonetic)
                .font(.title3)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var cardBack: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(word.meaning)
                .font(.title2).bold()
            Text("[\(word.partOfSpeech)]")
                .font(.subheadline).foregroundColor(.secondary)
            if !word.examples.isEmpty {
                Text(word.examples[0])
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
