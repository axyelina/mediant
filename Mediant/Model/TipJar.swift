import Foundation
import Observation

/// The tips in Settings: loads the four products from the store.
@MainActor
@Observable
final class TipJar {
    enum Load: Equatable {
        case loading
        case loaded([TipProduct])
        case unavailable
    }

    private(set) var load: Load = .loading

    private let store: TipStore
    private let messageDuration: Duration

    init(store: TipStore, messageDuration: Duration = .seconds(3)) {
        self.store = store
        self.messageDuration = messageDuration
    }

    /// Loads once. After a failure a new call tries again.
    func loadIfNeeded() async {
        if case .loaded = load { return }
        load = .loading
        do {
            let products = try await store.products(for: TipSize.allCases.map(\.productID))
            let tips = products.filter { $0.size != nil }.sorted { $0.price < $1.price }
            load = tips.isEmpty ? .unavailable : .loaded(tips)
        } catch {
            load = .unavailable
        }
    }
}
