import Foundation

/// The App Store, as the tip jar sees it. Only `StoreKitTipStore` talks to StoreKit.
protocol TipStore: Sendable {
    /// The products the store knows for these ids, in any order.
    func products(for ids: [String]) async throws -> [TipProduct]
    func purchase(_ id: String) async -> TipPurchaseResult
    /// Runs until cancelled: finishes every tip transaction that arrives from outside a purchase.
    func finishUpdates() async
}
