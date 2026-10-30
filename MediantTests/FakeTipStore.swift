import Foundation
@testable import Mediant

/// In-memory tip store for unit tests. All state sits behind one lock: the tip jar calls it from
/// the main actor while `purchase` runs off it.
final class FakeTipStore: TipStore, @unchecked Sendable {
    private struct State {
        var products: [TipProduct] = []
        var loadError: Error?
        var result: TipPurchaseResult = .success
        var hold = false
        var purchases: [String] = []
        var loadCalls = 0
        var waiting: [CheckedContinuation<Void, Never>] = []
    }

    private let lock = NSLock()
    private var state = State()

    private func locked<T>(_ body: (inout State) -> T) -> T {
        lock.withLock { body(&state) }
    }

    var products: [TipProduct] {
        get { locked { $0.products } }
        set { locked { $0.products = newValue } }
    }

    var loadError: Error? {
        get { locked { $0.loadError } }
        set { locked { $0.loadError = newValue } }
    }

    var result: TipPurchaseResult {
        get { locked { $0.result } }
        set { locked { $0.result = newValue } }
    }

    /// While true, `purchase` waits for `release()`: a tip that is "in progress".
    var hold: Bool {
        get { locked { $0.hold } }
        set { locked { $0.hold = newValue } }
    }

    var purchases: [String] { locked { $0.purchases } }
    var loadCalls: Int { locked { $0.loadCalls } }
    /// How many purchases are parked, waiting for `release()`.
    var heldCount: Int { locked { $0.waiting.count } }

    func products(for ids: [String]) async throws -> [TipProduct] {
        let (products, error) = locked { state -> ([TipProduct], Error?) in
            state.loadCalls += 1
            return (state.products, state.loadError)
        }
        if let error { throw error }
        return products
    }

    func purchase(_ id: String) async -> TipPurchaseResult {
        locked { $0.purchases.append(id) }
        // The hold check and the parking happen under one lock, so `release()` cannot slip between them.
        await withCheckedContinuation { continuation in
            let parked = locked { state -> Bool in
                guard state.hold else { return false }
                state.waiting.append(continuation)
                return true
            }
            if !parked { continuation.resume() }
        }
        return result
    }

    func finishUpdates() async {}

    /// Lets every held `purchase` return.
    func release() {
        let continuations = locked { state -> [CheckedContinuation<Void, Never>] in
            state.hold = false
            defer { state.waiting = [] }
            return state.waiting
        }
        for continuation in continuations { continuation.resume() }
    }

    /// Waits until a purchase is parked. Returns false after `timeout` instead of hanging.
    func waitUntilHeld(timeout: Duration = .seconds(2)) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while heldCount == 0 {
            if ContinuousClock.now >= deadline { return false }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return true
    }
}
