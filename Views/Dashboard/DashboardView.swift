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
                }
            }
            .navigationTitle("看板")
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
        }
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
