// Views/WordDetail/WordDetailView.swift
import SwiftUI

struct WordDetailView: View {
    let word: Word

    @State private var showRootAffix = false
    @State private var showSynonyms = false
    @State private var showAntonyms = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 单词头部
                headerSection

                Divider()

                // 释义
                meaningSection

                // 例句
                if !word.examples.isEmpty {
                    examplesSection
                }

                // 词根词缀
                if !word.rootAffix.isEmpty {
                    collapsibleSection(
                        title: "词根词缀",
                        isExpanded: $showRootAffix,
                        content: Text(word.rootAffix).font(.body)
                    )
                }

                // 同义词
                if !word.synonyms.isEmpty {
                    collapsibleSection(
                        title: "同义词",
                        isExpanded: $showSynonyms,
                        content: tagsView(tags: word.synonyms, color: .green)
                    )
                }

                // 反义词
                if !word.antonyms.isEmpty {
                    collapsibleSection(
                        title: "反义词",
                        isExpanded: $showAntonyms,
                        content: tagsView(tags: word.antonyms, color: .red)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("单词详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(word.word)
                .font(.system(size: 36, weight: .bold))

            HStack(spacing: 8) {
                Text(word.phonetic)
                    .font(.title3)
                    .foregroundColor(.secondary)

                Button(action: { TTSPlayer.shared.speak(word.word) }) {
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("释义").font(.headline)
            HStack {
                Text("[\(word.partOfSpeech)]")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(word.meaning)
                    .font(.title3)
            }
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("例句").font(.headline)
            ForEach(word.examples.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(i + 1).")
                        .foregroundColor(.secondary)
                    Text(word.examples[i])
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func collapsibleSection(title: String, isExpanded: Binding<Bool>, content: some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.wrappedValue.toggle() } }) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            if isExpanded.wrappedValue { content }
        }
    }

    private func tagsView(tags: [String], color: Color) -> some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
        }
    }
}
