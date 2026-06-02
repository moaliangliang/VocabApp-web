// Views/Learning/LearningHomeView.swift
import SwiftUI
import SwiftData
import AVFoundation

// MARK: - 学习 Session

private struct SessionView: View {
    @Bindable var viewModel: LearningViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch viewModel.state {
        case .inSession(let mode, _):
            if let word = viewModel.currentWord {
                Group {
                    switch mode {
                    case .browse:
                        WordBrowseView(
                            word: word,
                            viewModel: viewModel
                        )
                    case .choice:
                        ChoiceQuizView(word: word, distractors: viewModel.distractors(for: word)) { correct in
                            viewModel.advanceAfterResult(for: word.id, mode: .choice, correct: correct)
                        }
                    case .spelling:
                        SpellingView(word: word) { correct in
                            if correct {
                                viewModel.advanceAfterResult(for: word.id, mode: .spelling, correct: true)
                            } else {
                                viewModel.advanceAfterResult(for: word.id, mode: .spelling, correct: false)
                            }
                        }
                    }
                }
                .id("\(word.id)_\(mode)")
                .overlay(alignment: .topTrailing) {
                    closeButton
                }
            }
        case .sessionComplete:
            sessionCompleteView
        default:
            EmptyView()
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            Text("今日学习完成！")
                .font(.title2).bold()
            Text("继续保持！")
                .foregroundColor(.secondary)
            Button("返回") {
                dismiss()
                Task { await viewModel.refreshProgress() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var closeButton: some View {
        Button {
            viewModel.state = .idle
            dismiss()
        } label: {
            Text("返回")
                .font(.body)
                .foregroundColor(.blue)
        }
        .padding(12)
    }
}

// MARK: - 浏览模式（大字卡片 + 滑动标记）

private struct WordBrowseView: View {
    let word: Word
    let viewModel: LearningViewModel
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var showHint = true
    @State private var swipeFeedback: SwipeDirection?
    @State private var feedbackOpacity: Double = 0

    private enum SwipeDirection {
        case known, unknown
    }

    private var masteryDisplay: String { viewModel.currentMasteryDisplay }

    private func speakWord() {
        let utterance = AVSpeechUtterance(string: word.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏：进度
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("第 \(viewModel.currentGroupIndex)/\(viewModel.totalGroups) 组 · 词 \(viewModel.wordIndexInGroup)/50")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.currentWordIndex + 1) / \(viewModel.totalWords)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // 学习状态标签
            HStack(spacing: 6) {
                masteryBadge
                if !word.rootAffix.isEmpty {
                    Text(word.rootAffix)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)

            Spacer()

            // 单词核心区
            VStack(spacing: 16) {
                Text(word.word)
                    .font(.system(size: 40, weight: .bold))

                HStack(spacing: 8) {
                    Text(word.phonetic)
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Button(action: speakWord) {
                        Image(systemName: "speaker.wave.2.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }

                Text("[\(word.partOfSpeech)] \(word.meaning)")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            // 例句
            if !word.examples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    ForEach(word.examples.prefix(2), id: \.self) { example in
                        HStack(alignment: .top, spacing: 6) {
                            Text("·")
                                .foregroundColor(.secondary)
                            Text(example)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // 进入更深模式
            if viewModel.selectedModes.contains(where: { $0 != .browse }) {
                Button(action: { viewModel.startLearningCurrentWord() }) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("开始学习此词")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
            }

            // 滑动提示
            if showHint {
                Text("右滑认识 · 左滑不认识 · 上滑下一个")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                    .transition(.opacity)
            }
        }
        .padding(.bottom, 16)
        .overlay(swipeFeedbackOverlay)
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .onAppear {
            speakWord()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut) { showHint = false }
            }
        }
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - 子视图

    @ViewBuilder
    private var masteryBadge: some View {
        let color: Color = masteryDisplay.hasPrefix("新词") ? .gray :
                           masteryDisplay.hasPrefix("学习中") ? .orange :
                           masteryDisplay.hasPrefix("已掌握") ? .green : .blue
        Text(masteryDisplay)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var swipeFeedbackOverlay: some View {
        Group {
            if feedbackOpacity > 0 {
                HStack {
                    if swipeFeedback == .unknown {
                        Label("不认识", systemImage: "xmark.circle")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.red.opacity(0.85))
                            .clipShape(Capsule())
                    }
                    if swipeFeedback == .known {
                        Label("认识", systemImage: "checkmark.circle")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.green.opacity(0.85))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .opacity(feedbackOpacity)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let h = value.translation.width
                let v = value.translation.height
                if abs(v) * 1.3 > abs(h) && abs(v) > 40 {
                    if v < -40, viewModel.hasNext { viewModel.nextWord() }
                    else if v > 40, viewModel.hasPrevious { viewModel.previousWord() }
                } else if abs(h) > 30 {
                    if h > 30 {
                        viewModel.markAndAdvance(quality: 4)
                        swipeFeedback = .known
                    } else if h < -30 {
                        viewModel.markAndAdvance(quality: 0)
                        swipeFeedback = .unknown
                    }
                    withAnimation(.easeInOut(duration: 0.15)) { feedbackOpacity = 1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.4)) { feedbackOpacity = 0 }
                    }
                }
            }
    }
}

// MARK: - 课程信息

struct CourseInfo: Identifiable {
    let id: String
    let name: String
    let desc: String
    let wordCount: Int
    let color: Color

    static let all: [CourseInfo] = [
        CourseInfo(id: "CET4", name: "四级词汇", desc: "大学英语四级考试大纲词汇", wordCount: 4500, color: .blue),
        CourseInfo(id: "CET6", name: "六级词汇", desc: "大学英语六级考试大纲词汇", wordCount: 6000, color: .purple),
        CourseInfo(id: "Kaoyan", name: "考研词汇", desc: "全国硕士研究生入学考试英语词汇", wordCount: 5500, color: .red),
        CourseInfo(id: "TOEFL", name: "托福词汇", desc: "托福考试核心词汇", wordCount: 8000, color: .orange),
        CourseInfo(id: "IELTS", name: "雅思词汇", desc: "雅思考试核心词汇", wordCount: 7000, color: .green),
        CourseInfo(id: "GRE", name: "GRE词汇", desc: "GRE考试核心词汇", wordCount: 9000, color: .indigo),
    ]
}

// MARK: - 学习首页

struct LearningHomeView: View {
    @State private var viewModel: LearningViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showCoursePicker = false
    @State private var showSession = false

    init(viewModel: LearningViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            if viewModel.currentCourse == nil {
                coursePickerBody
                    .navigationTitle("选择词库")
            } else {
                mainBody
            }
        }
    }

    // MARK: - 主页面

    private var mainBody: some View {
        ScrollView {
            VStack(spacing: 24) {
                currentCourseCard
                todayProgressSection
                modeSelectionSection
                actionButtons
                courseOverviewSection
                Spacer()
            }
            .padding()
        }
        .navigationTitle("背词")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("切换") { showCoursePicker = true }
            }
        }
        .sheet(isPresented: $showCoursePicker) {
            NavigationStack {
                coursePickerBody
                    .navigationTitle("选择词库")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("取消") { showCoursePicker = false }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showSession) {
            SessionView(viewModel: viewModel)
        }
        .onChange(of: showSession) { _, newValue in
            if !newValue { viewModel.state = .idle }
        }
    }

    // MARK: - 当前词库卡片

    private var currentCourseCard: some View {
        Button { showCoursePicker = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.currentCourse?.name ?? "")
                        .font(.title3).bold()
                    if let course = viewModel.currentCourse {
                        Text(course.desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let course = viewModel.currentCourse {
                        ProgressView(value: progressFraction(for: course.id))
                            .tint(.blue)
                        let mastered = viewModel.masteredCount
                        let total = course.wordCount
                        Text("已掌握 \(mastered)/\(total) (\(Int(Double(mastered)/max(Double(total), 1)*100))%)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 今日进度

    private var todayProgressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("今日目标")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.newWordProgress.done)/\(viewModel.newWordProgress.total)")
                    .font(.title3).bold()
            }

            ProgressView(value: Double(viewModel.newWordProgress.done),
                        total: max(Double(viewModel.newWordProgress.total), 1))
                .tint(.blue)

            if viewModel.reviewProgress.total > 0 {
                HStack {
                    Text("复习")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.reviewProgress.done)/\(viewModel.reviewProgress.total)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                ProgressView(value: Double(viewModel.reviewProgress.done),
                            total: max(Double(viewModel.reviewProgress.total), 1))
                    .tint(.orange)
            }

            HStack {
                StatBadge(icon: "flame.fill", value: "\(DailyLog.currentStreak)", label: "连续天数")
                StatBadge(icon: "checkmark.circle.fill", value: "\(viewModel.masteredCount)", label: "已掌握")
                if viewModel.reviewProgress.total > 0 {
                    StatBadge(icon: "arrow.clockwise", value: "\(viewModel.reviewProgress.total)", label: "待复习")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 模式选择

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习模式")
                .font(.headline)

            HStack(spacing: 12) {
                modeToggle(mode: .browse, label: "浏览", icon: "eye.fill", color: .blue,
                          desc: "快速刷词，滑动标记")
                modeToggle(mode: .choice, label: "选择", icon: "list.bullet.clipboard", color: .green,
                          desc: "看词选义，检验记忆")
                modeToggle(mode: .spelling, label: "拼写", icon: "keyboard.fill", color: .orange,
                          desc: "听音默写，巩固拼写")
            }
        }
    }

    private func modeToggle(mode: LearningMode, label: String, icon: String, color: Color, desc: String) -> some View {
        let isSelected = viewModel.selectedModes.contains(mode)
        return Button {
            if isSelected {
                // 至少要保留一个模式
                guard viewModel.selectedModes.count > 1 else { return }
                viewModel.selectedModes.removeAll { $0 == mode }
            } else {
                viewModel.selectedModes.append(mode)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? color : .gray)
                Text(label)
                    .font(.caption).bold()
                    .foregroundColor(isSelected ? color : .gray)
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.startSession()
                showSession = true
            }) {
                Label("开始学习", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedModes.isEmpty)

            if viewModel.reviewProgress.total > 0 {
                Button(action: {
                    viewModel.startReviewSession()
                    showSession = true
                }) {
                    Label("复习", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
    }

    // MARK: - 各词库进度速览

    private var courseOverviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("词库进度")
                .font(.headline)

            ForEach(CourseInfo.all.prefix(4)) { info in
                let progress = courseProgress(for: info.id)
                Button {
                    let course = Course(id: info.id, name: info.name, desc: info.desc, wordCount: info.wordCount)
                    Task { await viewModel.loadCourse(course) }
                } label: {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(info.color)
                            .frame(width: 4, height: 24)
                        Text(info.name)
                            .font(.subheadline)
                        Spacer()
                        ProgressView(value: progress)
                            .tint(info.color)
                            .frame(width: 60)
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 词库选择

    private var coursePickerBody: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("请选择要学习的词库")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                ForEach(CourseInfo.all) { info in
                    Button {
                        let course = Course(
                            id: info.id, name: info.name, desc: info.desc,
                            wordCount: info.wordCount
                        )
                        Task {
                            await viewModel.loadCourse(course)
                            showCoursePicker = false
                        }
                    } label: {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(info.color)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(info.id.prefix(2))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(info.name).font(.headline)
                                Text(info.desc).font(.caption).foregroundColor(.secondary)
                                Text("\(info.wordCount) 词")
                                    .font(.caption2).foregroundColor(.secondary)
                                let goal = UserDefaults.standard.integer(forKey: "dailyNewWordGoal").nonZero
                                let days = info.wordCount / goal
                                let months = days / 30
                                let estimate = months > 0 ? "约 \(months) 个月 (\(goal)词/天)" : "约 \(days) 天 (\(goal)词/天)"
                                Text(estimate)
                                    .font(.caption2)
                                    .foregroundColor(.blue.opacity(0.7))
                            }

                            Spacer()

                            if viewModel.currentCourse?.id == info.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - 辅助

    private func progressFraction(for courseID: String) -> Double {
        max(Double(viewModel.masteredCount) / max(Double(wordCount(for: courseID)), 1), 0)
    }

    private func courseProgress(for courseID: String) -> Double {
        // 简化：从 DashboardViewModel 获取更准确，这里用全局比例
        progressFraction(for: courseID)
    }

    private func wordCount(for courseID: String) -> Int {
        CourseInfo.all.first { $0.id == courseID }?.wordCount ?? 1
    }
}

// MARK: - 小组件

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            Text(value)
                .font(.subheadline).bold()
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

extension DailyLog {
    static var currentStreak: Int { 0 }
}
