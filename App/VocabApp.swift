// App/VocabApp.swift
import SwiftUI
import SwiftData

@main
struct VocabApp: App {
    let modelContainer: ModelContainer

    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            MainTabView(storeManager: storeManager)
        }
        .modelContainer(modelContainer)
    }

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Word.self, Course.self, LearningRecord.self, DailyLog.self, PurchaseRecord.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
