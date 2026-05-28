// Views/Learning/LearningHomeView.swift
import SwiftUI
import SwiftData

struct LearningHomeView: View {
    @State private var viewModel: LearningViewModel
    @Environment(\.modelContext) private var modelContext

    init(viewModel: LearningViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            if viewModel.currentCourse == nil {
                ContentUnavailableView(
                    "请先在商店购买课程",
                    systemImage: "bag",
                    description: Text("购买后即可开始背单词")
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // 今日进度圆环
                        progressRingSection

                        // 课程选择
                        courseSelector

                        // 学习统计
                        statsSection

                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("学习")
                .onAppear {
                    viewModel = LearningViewModel(modelContext: modelContext)
                }
            }
        }
    }

    private var progressRingSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progressFraction)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progressFraction)

                VStack(spacing: 4) {
                    Text("\(viewModel.newWordProgress.done)/\(viewModel.newWordProgress.total)")
                        .font(.title).bold()
                    Text("今日新词").font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(width: 160, height: 160)

            Button(action: { viewModel.startSession() }) {
                Label("开始学习", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var progressFraction: CGFloat {
        let total = viewModel.newWordProgress.total
        guard total > 0 else { return 0 }
        return CGFloat(viewModel.newWordProgress.done) / CGFloat(total)
    }

    private var courseSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前课程").font(.headline)
            // 简化：显示已购课程列表
            Text("四级词汇").foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            StatCard(title: "今日复习", value: "\(viewModel.reviewProgress.done)", icon: "arrow.clockwise")
            StatCard(title: "连续天数", value: "\(DailyLog.currentStreak)", icon: "flame.fill")
            StatCard(title: "已掌握", value: "\(totalMastered)", icon: "checkmark.circle.fill")
        }
    }

    private var totalMastered: Int {
        (try? modelContext.fetch(FetchDescriptor<LearningRecord>(
            predicate: #Predicate { $0.mastery >= 2 }
        )).count) ?? 0
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(.blue)
            Text(value).font(.title3).bold()
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension DailyLog {
    static var currentStreak: Int {
        // 简化：真实实现通过 StreakManager 计算
        return 0
    }
}
