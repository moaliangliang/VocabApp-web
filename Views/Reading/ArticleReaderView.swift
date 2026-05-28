// Views/Reading/ArticleReaderView.swift
import SwiftUI

struct ArticleReaderView: View {
    let article: Article
    @State private var showWordDetail = false
    @State private var selectedWord: String = ""
    @State private var lookupWord: Word?

    // 模拟词库（实际从环境传入）
    let sampleWords: [Word] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.title2).bold()

                Text(article.content)
                    .font(.body)
                    .lineSpacing(8)
                    .environment(\.openURL, OpenURLAction { url in
                        // 点击单词高亮查词 — 通过 gesture 实现
                        .systemAction
                    })
                    .overlay(
                        GeometryReader { _ in
                            Color.clear
                                .frame(width: 0, height: 0)
                        }
                    )

                // 用 Button 模拟查词（完整版用 Text+gesture 逐词响应）
                VStack(alignment: .leading, spacing: 8) {
                    Text("点击下方单词查词").font(.caption).foregroundColor(.secondary)
                    ForEach(extractUniqueWords(from: article.content).prefix(10), id: \.self) { word in
                        Button(word) {
                            selectedWord = word
                            lookupWord = Word(id: "lookup", word: word, phonetic: "", meaning: "查词中...",
                                              partOfSpeech: "", courseID: article.courseID)
                            showWordDetail = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("阅读")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWordDetail) {
            if let word = lookupWord {
                NavigationStack {
                    WordDetailView(word: word)
                        .toolbar { Button("关闭") { showWordDetail = false } }
                }
            }
        }
    }

    private func extractUniqueWords(from text: String) -> [String] {
        let words = text.split { !$0.isLetter }.map(String.init)
        return Array(Set(words)).sorted()
    }
}
