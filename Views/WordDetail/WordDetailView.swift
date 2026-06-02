// Views/WordDetail/WordDetailView.swift
import SwiftUI
import SwiftData

struct WordDetailView: View {
    let word: Word
    @Environment(\.modelContext) private var modelContext

    @State private var showRootAffix = false
    @State private var showSynonyms = false
    @State private var showAntonyms = false
    @State private var markedResult: String?
    @State private var memoryTips: [MemoryTip] = []
    @State private var showTips = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                Divider()

                meaningSection

                if !word.examples.isEmpty {
                    examplesSection
                }

                if !word.rootAffix.isEmpty {
                    collapsibleSection(
                        title: "词根词缀",
                        isExpanded: $showRootAffix,
                        content: Text(word.rootAffix).font(.title3)
                    )
                }

                if !word.synonyms.isEmpty {
                    collapsibleSection(
                        title: "同义词",
                        isExpanded: $showSynonyms,
                        content: tagsView(tags: word.synonyms, color: .green)
                    )
                }

                if !word.antonyms.isEmpty {
                    collapsibleSection(
                        title: "反义词",
                        isExpanded: $showAntonyms,
                        content: tagsView(tags: word.antonyms, color: .red)
                    )
                }

                // 记忆技巧
                if !memoryTips.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: { withAnimation { showTips.toggle() } }) {
                            HStack {
                                Text("💡 记忆技巧").font(.headline)
                                Spacer()
                                Image(systemName: showTips ? "chevron.up" : "chevron.down")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        if showTips {
                            ForEach(memoryTips.indices, id: \.self) { i in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: memoryTips[i].icon)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .frame(width: 16)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(memoryTips[i].type).font(.caption).bold()
                                        Text(memoryTips[i].content)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // 快速标记
                Divider()
                VStack(spacing: 8) {
                    Text("标记掌握程度").font(.headline)

                    if let result = markedResult {
                        Text(result)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }

                    HStack(spacing: 16) {
                        markButton(label: "不认识", color: .red, quality: 0)
                        markButton(label: "模糊", color: .orange, quality: 2)
                        markButton(label: "认识", color: .green, quality: 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("单词详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            memoryTips = MemoryTipService.generateTips(for: word)
        }
    }

    private func markButton(label: String, color: Color, quality: Int) -> some View {
        Button {
            markWord(quality: quality)
        } label: {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(markedResult != nil)
    }

    private func markWord(quality: Int) {
        let wordID = word.id
        let records = try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.wordID == wordID }
        ))
        let record: LearningRecord
        if let existing = records?.first {
            record = existing
        } else {
            let new = LearningRecord(id: "user_\(word.id)", wordID: word.id, courseID: word.courseID)
            modelContext.insert(new)
            record = new
        }

        let result = SM2Engine.calculate(quality: quality, repetitions: record.repetitions,
                                          easeFactor: record.easeFactor, previousInterval: record.interval)
        record.repetitions = result.repetitions
        record.interval = result.interval
        record.easeFactor = result.easeFactor
        record.nextReviewDate = Date().addingTimeInterval(result.interval)
        record.lastReviewDate = Date()
        record.mastery = SM2Engine.masteryScore(for: result.repetitions)

        try? modelContext.save()

        withAnimation {
            markedResult = quality >= 4 ? "已标记为认识，\(formatInterval(result.interval))后复习" :
                         quality >= 2 ? "已标记为模糊，\(formatInterval(result.interval))后复习" :
                                        "已标记为不认识，稍后再次出现"
        }
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let days = Int(interval / 86400)
        if days > 30 { return "\(days / 30)个月" }
        if days > 0 { return "\(days)天" }
        let minutes = Int(interval / 60)
        if minutes > 0 { return "\(minutes)分钟" }
        return "即将"
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
