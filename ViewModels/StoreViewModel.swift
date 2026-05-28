// ViewModels/StoreViewModel.swift
import Foundation
import SwiftData

@Observable
final class StoreViewModel: @unchecked Sendable {
    let storeManager: StoreManager
    let modelContext: ModelContext

    var courses: [Course] = []

    init(storeManager: StoreManager, modelContext: ModelContext) {
        self.storeManager = storeManager
        self.modelContext = modelContext
        loadCourses()
    }

    private func loadCourses() {
        courses = [
            Course(id: "CET4", name: "四级词汇", desc: "大学英语四级考试大纲词汇，约4500词", wordCount: 4500, articleCount: 15, price: 18, productID: Constants.StoreProductIDs.cet4),
            Course(id: "CET6", name: "六级词汇", desc: "大学英语六级考试大纲词汇，约6000词", wordCount: 6000, articleCount: 15, price: 18, productID: Constants.StoreProductIDs.cet6),
            Course(id: "Kaoyan", name: "考研词汇", desc: "全国硕士研究生入学考试英语词汇", wordCount: 5500, articleCount: 20, price: 25, productID: Constants.StoreProductIDs.kaoyan),
            Course(id: "TOEFL", name: "托福词汇", desc: "托福考试核心词汇，约8000词", wordCount: 8000, articleCount: 20, price: 30, productID: Constants.StoreProductIDs.toefl),
            Course(id: "IELTS", name: "雅思词汇", desc: "雅思考试核心词汇，约7000词", wordCount: 7000, articleCount: 20, price: 30, productID: Constants.StoreProductIDs.ielts),
            Course(id: "GRE", name: "GRE词汇", desc: "GRE考试核心词汇，约9000词", wordCount: 9000, articleCount: 20, price: 30, productID: Constants.StoreProductIDs.gre),
        ]
    }

    func purchase(_ course: Course) async {
        if let product = storeManager.products.first(where: { $0.id == course.productID }) {
            await storeManager.purchase(product)
        }
    }

    func canAccess(courseID: String, wordIndex: Int) -> Bool {
        storeManager.canAccess(courseID: courseID, wordIndex: wordIndex)
    }
}
