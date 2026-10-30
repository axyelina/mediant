import Foundation
@testable import Mediant

/// In-memory tip store for unit tests.
final class FakeTipStore: TipStore, @unchecked Sendable {
    var products: [TipProduct] = []
    var loadError: Error?
    var result: TipPurchaseResult = .success
    /// While true, `purchase` waits for `release()`: a tip that is "in progress".
    var hold = false
    private(set) var purchases: [String] = []
    private(set) var loadCalls = 0
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func products(for ids: [String]) async throws -> [TipProduct] {
        loadCalls += 1
        if let loadError { throw loadError }
        return products
    }

    func purchase(_ id: String) async -> TipPurchaseResult {
        purchases.append(id)
        if hold {
            await withCheckedContinuation { waiting.append($0) }
        }
        return result
    }

    func finishUpdates() async {}

    /// Lets every held `purchase` return.
    func release() {
        hold = false
        let continuations = waiting
        waiting = []
        for continuation in continuations { continuation.resume() }
    }
}
