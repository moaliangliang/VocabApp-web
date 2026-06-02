// Views/Dashboard/DashboardView.swift
import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @Environment(\.modelContext) private var modelContext

    init() {
        _viewModel = State(initialValue: DashboardViewModel(modelContext: ModelContext(try! ModelContainer(for: DailyLog.self, LearningRecord.self))))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CalendarView(logs: viewModel.lastMonthLogs, streak: viewModel.streak)
                        .padding()

                    ProgressCharts(
                        masteredFraction: viewModel.masteredFraction,
                        masteredCount: viewModel.masteredWords,
                        learningCount: viewModel.learningWords,
                        totalCount: viewModel.totalWords
                    )
                    .padding(.horizontal)

                    // 总览卡片
                    overviewSection
                        .padding(.horizontal)

                    // 里程碑成就
                    if !viewModel.earnedMilestones.isEmpty {
                        milestoneSection
                            .padding(.horizontal)
                    }

                    // 各课程进度
                    if !viewModel.courseProgress.isEmpty {
                        courseProgressSection
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("看板")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: WordBookView()) {
                        Image(systemName: "book.pages")
                    }
                }
            }
            .onAppear {
                viewModel = DashboardViewModel(modelContext: modelContext)
                viewModel.refresh()
            }
        }
    }

    private var overviewSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            OverviewCard(title: "累积学习", value: "\(viewModel.streak)", unit: "天", icon: "calendar")
            OverviewCard(title: "已掌握", value: "\(viewModel.masteredWords)", unit: "词", icon: "brain")
            OverviewCard(title: "学习中", value: "\(viewModel.learningWords)", unit: "词", icon: "book")
            OverviewCard(title: "课程进度", value: "\(Int(viewModel.masteredFraction * 100))", unit: "%", icon: "chart.pie")
            OverviewCard(title: "本月新词", value: "\(viewModel.monthNewWords)", unit: "词", icon: "plus.circle")
            OverviewCard(title: "本月复习", value: "\(viewModel.monthReviews)", unit: "词", icon: "arrow.clockwise")
        }
    }
    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🏆 里程碑成就").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.earnedMilestones, id: \.self) { days in
                        VStack(spacing: 4) {
                            Image(systemName: days >= 100 ? "star.circle.fill" : "medal.fill")
                                .font(.title)
                                .foregroundColor(days >= 100 ? .yellow : .orange)
                            Text("\(days)天")
                                .font(.caption).bold()
                        }
                        .frame(width: 64, height: 64)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    if let next = viewModel.nextMilestone {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.circle")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text("\(next)天")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 64, height: 64)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundColor(.gray.opacity(0.4))
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var courseProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("各课程进度").font(.headline)

            ForEach(viewModel.courseProgress, id: \.id) { progress in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(courseColor(progress.color))
                        .frame(width: 4, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(progress.name).font(.subheadline).bold()
                        ProgressView(value: progress.fraction)
                            .tint(courseColor(progress.color))
                        HStack {
                            Text("已掌握 \(progress.masteredWords)/\(progress.totalWords)")
                                .font(.caption2).foregroundColor(.secondary)
                            if progress.learningWords > 0 {
                                Text("· 学习中 \(progress.learningWords)")
                                    .font(.caption2).foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
    }

    private func courseColor(_ name: String) -> Color {
        switch name {
        case "blue": .blue
        case "purple": .purple
        case "red": .red
        case "orange": .orange
        case "green": .green
        case "indigo": .indigo
        default: .gray
        }
    }
}

// MARK: - Word Book ViewModel (inline)

@Observable
final class WordBookViewModel {
    private let modelContext: ModelContext
    var courseID: String = ""
    var wordsByMastery: [(label: String, mastery: Int, words: [Word])] = []
    var isLoading = true

    private let masterySections: [(label: String, mastery: Int)] = [
        ("未学习", 0), ("学习中", 1), ("已掌握", 2), ("熟练", 3),
    ]

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func refresh() {
        isLoading = true
        let allWords = (try? modelContext.fetch(FetchDescriptor<Word>(
            predicate: courseID.isEmpty ? nil : #Predicate { $0.courseID == courseID },
            sortBy: [SortDescriptor(\.word)]
        ))) ?? []

        let allRecords = (try? modelContext.fetch(FetchDescriptor<LearningRecord>())) ?? []
        let records = Dictionary(uniqueKeysWithValues: allRecords.map { ($0.wordID, $0) })

        wordsByMastery = masterySections.compactMap { section in
            let words = allWords.filter { (records[$0.id]?.mastery ?? 0) == section.mastery }
            return words.isEmpty ? nil : (section.label, section.mastery, words)
        }
        isLoading = false
    }
}

// MARK: - Word Book View (inline)

struct WordBookView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WordBookViewModel?
    @State private var selectedCourseID = ""

    private let courses: [(id: String, name: String)] = [
        ("CET4", "四级"), ("CET6", "六级"), ("Kaoyan", "考研"),
        ("TOEFL", "托福"), ("IELTS", "雅思"), ("GRE", "GRE"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        courseButton(id: "", name: "全部")
                        ForEach(courses, id: \.id) { c in courseButton(id: c.id, name: c.name) }
                    }
                    .padding(.horizontal).padding(.vertical, 8)
                }
                .background(Color(.systemGray6))

                if let vm = viewModel {
                    if vm.isLoading {
                        Spacer(); ProgressView(); Spacer()
                    } else if vm.wordsByMastery.isEmpty {
                        Spacer(); ContentUnavailableView("暂无单词", systemImage: "book", description: Text("请先选择课程")); Spacer()
                    } else {
                        List {
                            ForEach(vm.wordsByMastery, id: \.mastery) { section in
                                Section {
                                    ForEach(section.words, id: \.id) { word in
                                        NavigationLink(destination: WordDetailView(word: word)) {
                                            HStack {
                                                Text(word.word).font(.body)
                                                Spacer()
                                                if !word.rootAffix.isEmpty {
                                                    Text(word.rootAffix).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                                                }
                                            }
                                        }
                                    }
                                } header: {
                                    HStack(spacing: 6) {
                                        Text(section.label).font(.subheadline.bold())
                                        Text("(\(section.words.count))").font(.caption).foregroundColor(.secondary)
                                    }
                                    .foregroundColor(masteryColor(section.mastery))
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                } else {
                    Spacer(); ProgressView(); Spacer()
                }
            }
            .navigationTitle("单词本")
            .onAppear { viewModel = WordBookViewModel(modelContext: modelContext); viewModel?.refresh() }
            .onChange(of: selectedCourseID) { _, newID in viewModel?.courseID = newID; viewModel?.refresh() }
        }
    }

    private func courseButton(id: String, name: String) -> some View {
        Button {
            selectedCourseID = id
            viewModel?.courseID = id
            viewModel?.refresh()
        } label: {
            Text(name).font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(selectedCourseID == id ? Color.blue : Color(.systemGray5))
                .foregroundColor(selectedCourseID == id ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func masteryColor(_ mastery: Int) -> Color {
        switch mastery { case 0: .gray; case 1: .orange; case 2: .green; case 3: .blue; default: .gray }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(.blue)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title).bold()
                Text(unit).font(.caption).foregroundColor(.secondary)
            }
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
