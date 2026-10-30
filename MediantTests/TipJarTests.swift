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
}
