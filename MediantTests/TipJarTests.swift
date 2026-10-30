import Foundation
import Testing
@testable import Mediant

@MainActor
struct TipJarTests {
    struct Broken: Error {}

    let store = FakeTipStore()

    static func product(_ size: TipSize, _ price: Decimal) -> TipProduct {
        TipProduct(id: size.productID, displayPrice: "$\(price)", price: price)
    }

    static let small = product(.small, 0.99)
    static let medium = product(.medium, 2.99)
    static let large = product(.large, 4.99)
    static let huge = product(.huge, 9.99)
    static let other = TipProduct(id: "app.mediant.other", displayPrice: "$1.99", price: 1.99)

    @Test func loadsKnownProductsSortedByPrice() async {
        store.products = [Self.huge, Self.small, Self.other, Self.large]
        let jar = TipJar(store: store)
        await jar.loadIfNeeded()
        #expect(jar.load == .loaded([Self.small, Self.large, Self.huge]))
    }

    @Test func noKnownProductsIsUnavailable() async {
        store.products = [Self.other]
        let jar = TipJar(store: store)
        await jar.loadIfNeeded()
        #expect(jar.load == .unavailable)
    }

    @Test func loadErrorIsUnavailableAndRetries() async {
        store.products = [Self.small]
        store.loadError = Broken()
        let jar = TipJar(store: store)
        await jar.loadIfNeeded()
        #expect(jar.load == .unavailable)
        store.loadError = nil
        await jar.loadIfNeeded()
        #expect(jar.load == .loaded([Self.small]))
        #expect(store.loadCalls == 2)
    }

    @Test func loadedDoesNotReload() async {
        store.products = [Self.small]
        let jar = TipJar(store: store)
        await jar.loadIfNeeded()
        await jar.loadIfNeeded()
        #expect(store.loadCalls == 1)
    }

    @Test func concurrentLoadsFetchOnce() async {
        store.products = [Self.small]
        store.holdLoads = true
        let jar = TipJar(store: store)
        let first = Task { await jar.loadIfNeeded() }
        guard await store.waitUntilLoadHeld() else {
            Issue.record("The first load never reached the store")
            store.releaseLoads()
            await first.value
            return
        }
        let second = Task { await jar.loadIfNeeded() }
        // Time for the second call to reach the store, if it would.
        try? await Task.sleep(for: .milliseconds(50))
        #expect(store.loadCalls == 1)
        store.releaseLoads()
        await first.value
        await second.value
        #expect(store.loadCalls == 1)
        #expect(jar.load == .loaded([Self.small]))
    }

    @Test func cancelledCallerDoesNotMarkUnavailable() async {
        // A tip place that goes away cancels its task; the load must still finish.
        store.products = [Self.small]
        store.holdLoads = true
        let jar = TipJar(store: store)
        let caller = Task { await jar.loadIfNeeded() }
        guard await store.waitUntilLoadHeld() else {
            Issue.record("The load never reached the store")
            store.releaseLoads()
            await caller.value
            return
        }
        caller.cancel()
        store.releaseLoads()
        await caller.value
        #expect(jar.load == .loaded([Self.small]))
        #expect(store.loadCalls == 1)
    }

    @Test func startLoadIfNeededStartsAtOnce() async {
        store.loadError = Broken()
        let jar = TipJar(store: store)
        await jar.loadIfNeeded()
        #expect(jar.load == .unavailable)
        store.loadError = nil
        store.products = [Self.small]
        jar.startLoadIfNeeded()
        #expect(jar.load == .loading)
        await jar.loadIfNeeded()
        #expect(jar.load == .loaded([Self.small]))
        #expect(store.loadCalls == 2)
        jar.startLoadIfNeeded()
        #expect(jar.load == .loaded([Self.small]))
        #expect(store.loadCalls == 2)
    }

    @Test func sizeFromProductID() {
        #expect(TipSize(productID: "app.mediant.tip.huge") == .huge)
        #expect(TipSize(productID: "x") == nil)
    }

    // MARK: Buying

    @Test func successCelebratesAndThanksThePlace() async {
        let jar = TipJar(store: store)
        await jar.buy(Self.medium, from: .trash)
        #expect(jar.celebration == TipJar.Celebration(id: 1, size: .medium, place: .trash))
        #expect(jar.message == TipJar.Message(kind: .thanks, place: .trash))
        #expect(jar.purchasing == nil)
        #expect(store.purchases == ["app.mediant.tip.medium"])
    }

    @Test func cancelledDoesNothing() async {
        store.result = .cancelled
        let jar = TipJar(store: store)
        await jar.buy(Self.small, from: .settings)
        #expect(jar.celebration == nil)
        #expect(jar.message == nil)
        #expect(jar.purchasing == nil)
    }

    @Test func pendingDoesNothing() async {
        store.result = .pending
        let jar = TipJar(store: store)
        await jar.buy(Self.small, from: .settings)
        #expect(jar.celebration == nil)
        #expect(jar.message == nil)
        #expect(jar.purchasing == nil)
    }

    @Test func failedShowsFailedNoCelebration() async {
        store.result = .failed
        let jar = TipJar(store: store)
        await jar.buy(Self.small, from: .settings)
        #expect(jar.message == TipJar.Message(kind: .failed, place: .settings))
        #expect(jar.celebration == nil)
        #expect(jar.purchasing == nil)
    }

    @Test func secondTapWhileBuyingIsIgnored() async {
        store.hold = true
        let jar = TipJar(store: store)
        let first = Task { await jar.buy(Self.small, from: .settings) }
        // `purchase` runs off the main actor: wait until the first tap is parked in the store.
        guard await store.waitUntilHeld() else {
            Issue.record("The first purchase never reached the store")
            store.release()
            await first.value
            return
        }
        await jar.buy(Self.large, from: .trash)
        #expect(store.purchases == ["app.mediant.tip.small"])
        #expect(jar.purchasing == TipJar.Purchase(productID: "app.mediant.tip.small", place: .settings))
        store.release()
        await first.value
        #expect(jar.purchasing == nil)
    }

    @Test func messageStaysWithItsPlace() async {
        let jar = TipJar(store: store)
        await jar.buy(Self.small, from: .settings)
        #expect(jar.message?.place == .settings)
        #expect(jar.celebration?.place == .settings)
    }

    @Test func celebrationIdGrowsEachTip() async {
        let jar = TipJar(store: store)
        await jar.buy(Self.small, from: .settings)
        #expect(jar.celebration?.id == 1)
        await jar.buy(Self.large, from: .trash)
        #expect(jar.celebration?.id == 2)
        #expect(jar.celebration?.size == .large)
    }

    @Test func messageClearsAfterDuration() async throws {
        let jar = TipJar(store: store, messageDuration: .milliseconds(300))
        await jar.buy(Self.small, from: .settings)
        try await Task.sleep(for: .milliseconds(100))
        #expect(jar.message != nil)
        try await Task.sleep(for: .milliseconds(500))
        #expect(jar.message == nil)
    }

    @Test func newerMessageIsNotClearedByTheOlderTimer() async throws {
        let jar = TipJar(store: store, messageDuration: .milliseconds(500))
        await jar.buy(Self.small, from: .settings)
        try await Task.sleep(for: .milliseconds(300))
        await jar.buy(Self.small, from: .trash)
        // The first message's timer would have fired at 500 ms; the second one's fires at 800 ms.
        try await Task.sleep(for: .milliseconds(350))
        #expect(jar.message == TipJar.Message(kind: .thanks, place: .trash))
    }
}
