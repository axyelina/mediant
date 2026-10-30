import StoreKit

/// The tip jar's App Store, on StoreKit 2. `init()` does no StoreKit work: nothing runs until
/// the tip jar asks.
struct StoreKitTipStore: TipStore {
    func products(for ids: [String]) async throws -> [TipProduct] {
        try await Product.products(for: ids).map {
            TipProduct(id: $0.id, displayPrice: $0.displayPrice, price: $0.price)
        }
    }

    func purchase(_ id: String) async -> TipPurchaseResult {
        do {
            guard let product = try await Product.products(for: [id]).first else { return .failed }
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                return .success
            case .success(.unverified):
                // Not finished: StoreKit offers it again, and `finishUpdates()` may still sort it out.
                return .failed
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    func finishUpdates() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update, TipSize(productID: transaction.productID) != nil {
                await transaction.finish()
            }
        }
    }
}
