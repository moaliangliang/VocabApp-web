// Models/PurchaseRecord.swift
import Foundation
import SwiftData

@Model
final class PurchaseRecord: @unchecked Sendable {
    @Attribute(.unique) var productID: String
    var courseID: String
    var transactionID: String
    var purchaseDate: Date
    var isActive: Bool = true

    init(productID: String, courseID: String, transactionID: String, purchaseDate: Date) {
        self.productID = productID
        self.courseID = courseID
        self.transactionID = transactionID
        self.purchaseDate = purchaseDate
    }
}
