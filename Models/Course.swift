// Models/Course.swift
import Foundation
import SwiftData

@Model
final class Course: @unchecked Sendable {
    @Attribute(.unique) var id: String          // "CET4"
    var name: String                            // "四级词汇"
    var desc: String                            // 课程描述
    var wordCount: Int
    var articleCount: Int
    var price: Decimal
    var productID: String                       // StoreKit 产品 ID
    var isFree: Bool = false

    init(id: String, name: String, desc: String, wordCount: Int, articleCount: Int,
         price: Decimal, productID: String, isFree: Bool = false) {
        self.id = id
        self.name = name
        self.desc = desc
        self.wordCount = wordCount
        self.articleCount = articleCount
        self.price = price
        self.productID = productID
        self.isFree = isFree
    }
}
