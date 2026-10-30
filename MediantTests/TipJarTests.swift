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
        // `purchase` runs off the main actor: wait until the store has really seen the first tap.
        while store.purchases.isEmpty { await Task.yield() }
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
        let jar = TipJar(store: store, messageDuration: .milliseconds(50))
        await jar.buy(Self.small, from: .settings)
        #expect(jar.message != nil)
        try await Task.sleep(for: .milliseconds(150))
        #expect(jar.message == nil)
    }

    @Test func newerMessageIsNotClearedByTheOlderTimer() async throws {
        let jar = TipJar(store: store, messageDuration: .milliseconds(200))
        await jar.buy(Self.small, from: .settings)
        try await Task.sleep(for: .milliseconds(120))
        await jar.buy(Self.small, from: .trash)
        try await Task.sleep(for: .milliseconds(120))
        #expect(jar.message == TipJar.Message(kind: .thanks, place: .trash))
    }
}
