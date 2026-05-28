// Utilities/Constants.swift
import Foundation

enum Constants {
    static let appGroup = "group.com.yourapp.VocabApp"
    static let freeWordLimit = 100
    static let freeArticleLimit = 3
    static let maxMakeupsPerMonth = 3

    static let milestones: [Int] = [7, 30, 100, 365]

    enum StoreProductIDs {
        static let cet4 = "com.vocabapp.course.cet4"
        static let cet6 = "com.vocabapp.course.cet6"
        static let kaoyan = "com.vocabapp.course.kaoyan"
        static let toefl = "com.vocabapp.course.toefl"
        static let ielts = "com.vocabapp.course.ielts"
        static let gre = "com.vocabapp.course.gre"
        static let cet46Bundle = "com.vocabapp.bundle.cet46"
        static let studyAbroadBundle = "com.vocabapp.bundle.studyabroad"

        static let all: [String] = [cet4, cet6, kaoyan, toefl, ielts, gre, cet46Bundle, studyAbroadBundle]
    }
}
