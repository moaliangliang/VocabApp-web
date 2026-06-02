// App/VocabApp.swift
import SwiftUI
import SwiftData

@main
struct VocabApp: App {
    let modelContainer: ModelContainer

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }

    init() {
        do {
            let storeURL = Self.sharedStoreURL()
            let config = ModelConfiguration(url: storeURL)
            modelContainer = try ModelContainer(
                for: Word.self, LearningRecord.self, DailyLog.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    static func sharedStoreURL() -> URL {
        let appGroupID = "group.com.vocabapp.personal"
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return URL.applicationSupportDirectory.appendingPathComponent("VocabApp.sqlite")
        }
        return container.appendingPathComponent("model.sqlite")
    }
}
