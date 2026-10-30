import Foundation

/// The four tips. The product IDs are fixed forever: they are set up in App Store Connect.
enum TipSize: String, CaseIterable, Sendable {
    case small, medium, large, huge

    var productID: String { "app.mediant.tip.\(rawValue)" }

    init?(productID: String) {
        guard let size = Self.allCases.first(where: { $0.productID == productID }) else { return nil }
        self = size
    }
}

/// A tip as the store sells it. `displayPrice` is the store's own text: the app never formats a price.
struct TipProduct: Equatable, Sendable {
    let id: String
    let displayPrice: String
    let price: Decimal

    var size: TipSize? { TipSize(productID: id) }
}

/// How a tip purchase ended. A transaction that fails verification is `failed`.
enum TipPurchaseResult: Equatable, Sendable {
    case success, cancelled, pending, failed
}
