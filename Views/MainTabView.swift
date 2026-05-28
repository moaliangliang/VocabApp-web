// Views/MainTabView.swift
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    let storeManager: StoreManager

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 学习
            LearningHomeView(viewModel: LearningViewModel(modelContext: modelContext))
                .tabItem {
                    Label("学习", systemImage: "book.fill")
                }
                .tag(0)

            // 阅读
            NavigationStack {
                ArticleListView(articles: ReadingViewModel(words: []).articles)
            }
            .tabItem {
                Label("阅读", systemImage: "text.alignleft")
            }
            .tag(1)

            // 看板
            DashboardView()
                .tabItem {
                    Label("看板", systemImage: "chart.bar.fill")
                }
                .tag(2)

            // 商店
            CourseStoreView(
                viewModel: StoreViewModel(storeManager: storeManager, modelContext: modelContext)
            )
            .tabItem {
                Label("商店", systemImage: "bag.fill")
            }
            .tag(3)

            // 设置
            SettingsView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(4)
        }
    }
}
