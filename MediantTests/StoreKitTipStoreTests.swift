import StoreKit
import StoreKitTest
import Testing
@testable import Mediant

/// Runs against `Tips.storekit` in a local StoreKit test session: no App Store, no dialogs.
@Suite(.serialized) @MainActor
struct StoreKitTipStoreTests {
    private let ids = TipSize.allCases.map(\.productID)

    private func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "Tips")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    @Test func loadsFourProducts() async throws {
        _ = try makeSession()
        let products = try await StoreKitTipStore().products(for: ids)
        #expect(products.count == 4)
        #expect(products.first { $0.id == TipSize.small.productID }?.price == Decimal(string: "0.99"))
    }

    @Test func purchaseSucceeds() async throws {
        let session = try makeSession()
        let result = await StoreKitTipStore().purchase(TipSize.small.productID)
        #expect(result == .success)
        #expect(session.allTransactions().filter { $0.productIdentifier == TipSize.small.productID }.count == 1)
        // The purchase finished its transaction, so nothing is left to deliver again.
        var unfinished: [String] = []
        for await update in Transaction.unfinished {
            if case .verified(let transaction) = update { unfinished.append(transaction.productID) }
        }
        #expect(!unfinished.contains(TipSize.small.productID))
    }

    @Test func purchaseFails() async throws {
        let session = try makeSession()
        try await session.setSimulatedError(.generic(.unknown), forAPI: .purchase)
        let result = await StoreKitTipStore().purchase(TipSize.small.productID)
        #expect(result == .failed)
    }

    @Test func askToBuyIsPending() async throws {
        let session = try makeSession()
        session.askToBuyEnabled = true
        let result = await StoreKitTipStore().purchase(TipSize.small.productID)
        #expect(result == .pending)
    }
}
