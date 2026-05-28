// Services/StoreManager.swift
import Foundation
import StoreKit

typealias Transaction = StoreKit.Transaction

@Observable
final class StoreManager: @unchecked Sendable {
    var purchasedProductIDs: Set<String> = []
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?

    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit { updateListenerTask?.cancel() }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Constants.StoreProductIDs.all)
            isLoading = false
        } catch {
            errorMessage = "加载商品失败: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
            case .pending:
                errorMessage = "购买等待中..."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "购买失败: \(error.localizedDescription)"
        }
    }

    func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    // 检查用户是否有权访问某个课程（购买 or 免费体验）
    func canAccess(courseID: String, wordIndex: Int) -> Bool {
        if wordIndex < Constants.freeWordLimit { return true }
        return purchasedProductIDs.contains { $0 == courseID } || isBundleOwner(of: courseID)
    }

    private func isBundleOwner(of courseID: String) -> Bool {
        // 简化：如果买了四六级包，则 CET4 和 CET6 都可访问
        if courseID == "CET4" || courseID == "CET6" {
            return purchasedProductIDs.contains(Constants.StoreProductIDs.cet46Bundle)
        }
        return false
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw StoreError.verificationFailed(error)
        case .verified(let safe):
            return safe
        }
    }

    private func updatePurchasedProducts() async {
        var updatedIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                updatedIDs.insert(transaction.productID)
            }
        }
        purchasedProductIDs = updatedIDs
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                if case .verified(let transaction) = result {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }
}

enum StoreError: Error {
    case verificationFailed(Error)
}
