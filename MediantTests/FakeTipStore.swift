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
        var holdLoads = false
        var purchases: [String] = []
        var loadCalls = 0
        var waiting: [CheckedContinuation<Void, Never>] = []
        var waitingLoads: [CheckedContinuation<Void, Never>] = []
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

    /// While true, `products(for:)` waits for `releaseLoads()`: a load that is "in progress".
    var holdLoads: Bool {
        get { locked { $0.holdLoads } }
        set { locked { $0.holdLoads = newValue } }
    }

    var purchases: [String] { locked { $0.purchases } }
    var loadCalls: Int { locked { $0.loadCalls } }
    /// How many purchases are parked, waiting for `release()`.
    var heldCount: Int { locked { $0.waiting.count } }
    /// How many loads are parked, waiting for `releaseLoads()`.
    var heldLoadCount: Int { locked { $0.waitingLoads.count } }

    func products(for ids: [String]) async throws -> [TipProduct] {
        locked { $0.loadCalls += 1 }
        await withCheckedContinuation { continuation in
            let parked = locked { state -> Bool in
                guard state.holdLoads else { return false }
                state.waitingLoads.append(continuation)
                return true
            }
            if !parked { continuation.resume() }
        }
        // Like StoreKit: a request whose task was cancelled fails.
        if Task.isCancelled { throw CancellationError() }
        let (products, error) = locked { ($0.products, $0.loadError) }
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

    /// Lets every held `products(for:)` return.
    func releaseLoads() {
        let continuations = locked { state -> [CheckedContinuation<Void, Never>] in
            state.holdLoads = false
            defer { state.waitingLoads = [] }
            return state.waitingLoads
        }
        for continuation in continuations { continuation.resume() }
    }

    /// Waits until a purchase is parked. Returns false after `timeout` instead of hanging.
    func waitUntilHeld(timeout: Duration = .seconds(2)) async -> Bool {
        await wait(timeout: timeout) { $0.heldCount > 0 }
    }

    /// Waits until a load is parked. Returns false after `timeout` instead of hanging.
    func waitUntilLoadHeld(timeout: Duration = .seconds(2)) async -> Bool {
        await wait(timeout: timeout) { $0.heldLoadCount > 0 }
    }

    private func wait(timeout: Duration, until done: (FakeTipStore) -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while !done(self) {
            if ContinuousClock.now >= deadline { return false }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return true
    }
}
