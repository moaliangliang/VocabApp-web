// Views/MainTabView.swift
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 背词
            LearningHomeView(viewModel: LearningViewModel(modelContext: modelContext))
                .tabItem {
                    Label("背词", systemImage: "book.fill")
                }
                .tag(0)

            // 看板
            DashboardView()
                .tabItem {
                    Label("看板", systemImage: "chart.bar.fill")
                }
                .tag(1)

            // 我的
            SettingsView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(2)
        }
    }
}
