// Views/Settings/SettingsView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

private struct ImportedWord: Codable {
    let word: String
    let meaning: String?
    let phonetic: String?
    let partOfSpeech: String?
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("dailyNewWordGoal") private var dailyGoal = 10

    @State private var showMakeupAlert = false
    @State private var makeupMessage = ""
    @State private var iCloudStatusText = "已启用"
    @State private var showFileImporter = false
    @State private var importMessage = ""
    @State private var showImportAlert = false
    @State private var showResetAlert = false
    @State private var selectedImportCourse = "CET4"

    var body: some View {
        NavigationStack {
            Form {
                // 学习目标
                Section("学习设置") {
                    Stepper("每日新词目标: \(dailyGoal)", value: $dailyGoal, in: 5...50, step: 5)
                }

                // 补签
                Section("打卡") {
                    Button("补签 (今日)") {
                        let manager = StreakManager(modelContainer: modelContext.container)
                        let remaining = manager.remainingMakeups()
                        if remaining > 0 {
                            manager.checkIn(isMakeup: true)
                            makeupMessage = "补签成功！本月剩余 \(remaining - 1) 次"
                        } else {
                            makeupMessage = "本月补签次数已用完"
                        }
                        showMakeupAlert = true
                    }
                }

                // 词库导入
                Section("词库") {
                    Picker("导入到", selection: $selectedImportCourse) {
                        Text("CET4").tag("CET4"); Text("CET6").tag("CET6")
                        Text("考研").tag("Kaoyan"); Text("托福").tag("TOEFL")
                        Text("雅思").tag("IELTS"); Text("GRE").tag("GRE")
                    }

                    Button(action: { showFileImporter = true }) {
                        Label("导入自定义词库 (JSON/CSV)", systemImage: "square.and.arrow.down")
                    }
                }

                // iCloud
                Section("同步") {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("iCloud 同步")
                            Text(iCloudStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0").foregroundColor(.secondary)
                    }
                }

                // 清除数据
                Section("数据管理") {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("清除所有学习数据", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("我的")
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json, .commaSeparatedText], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importWordBank(url)
                case .failure(let error):
                    importMessage = "导入失败: \(error.localizedDescription)"
                    showImportAlert = true
                }
            }
            .alert("补签", isPresented: $showMakeupAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(makeupMessage)
            }
            .alert("导入结果", isPresented: $showImportAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(importMessage)
            }
            .alert("确认清除", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    // 清除所有 LearningRecord
                    try? modelContext.delete(model: LearningRecord.self)
                    try? modelContext.save()
                }
            } message: {
                Text("将清除所有学习记录（单词进度、复习数据），单词库不受影响。此操作不可撤销。")
            }
        }
    }

    private func importWordBank(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importMessage = "无法访问文件"; showImportAlert = true; return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let words: [ImportedWord]

            if url.pathExtension.lowercased() == "csv" {
                guard let content = String(data: data, encoding: .utf8) else {
                    importMessage = "无法读取文件"; showImportAlert = true; return
                }
                words = parseCSV(content)
            } else {
                words = try JSONDecoder().decode([ImportedWord].self, from: data)
            }

            let existingIDs = Set((try? modelContext.fetch(FetchDescriptor<Word>(
                predicate: #Predicate { $0.courseID == selectedImportCourse }
            ))).map { $0.map(\.id) } ?? [])

            var imported = 0; var skipped = 0
            for (i, iw) in words.enumerated() {
                let wordID = "\(selectedImportCourse)_import_\(i)"
                guard !existingIDs.contains(wordID) else { skipped += 1; continue }
                let word = Word(id: wordID, word: iw.word, phonetic: iw.phonetic ?? "",
                                meaning: iw.meaning ?? iw.word, partOfSpeech: iw.partOfSpeech ?? "", courseID: selectedImportCourse)
                modelContext.insert(word)
                modelContext.insert(LearningRecord(id: "user_\(wordID)", wordID: wordID, courseID: selectedImportCourse))
                imported += 1
            }
            try? modelContext.save()
            importMessage = "导入完成: 新增 \(imported) 词，跳过 \(skipped) 个重复"
        } catch {
            importMessage = "解析失败: \(error.localizedDescription)"
        }
        showImportAlert = true
    }

    private func parseCSV(_ content: String) -> [ImportedWord] {
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return [] }
        return lines.dropFirst().compactMap { line in
            let cols = line.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
            guard cols.count >= 1, !cols[0].isEmpty else { return nil }
            return ImportedWord(word: cols[0].lowercased(), meaning: cols.count > 1 ? cols[1] : nil,
                                phonetic: cols.count > 2 ? cols[2] : nil, partOfSpeech: cols.count > 3 ? cols[3] : nil)
        }
    }
}
