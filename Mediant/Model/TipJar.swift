import Foundation
import Observation

/// The tips in Settings and in the just-emptied Trash: loads the four products, buys one at a time.
@MainActor
@Observable
final class TipJar {
    enum Load: Equatable {
        case loading
        case loaded([TipProduct])
        case unavailable
    }

    enum Place: Equatable, Sendable { case settings, trash }

    /// The tip that is being bought, and where its button was.
    struct Purchase: Equatable {
        let productID: String
        let place: Place
    }

    /// A short text for the place that started the purchase.
    struct Message: Equatable {
        enum Kind { case thanks, failed }
        let kind: Kind
        let place: Place
    }

    /// A tip that went through. `id` grows with every success; the overlay plays each new id once.
    struct Celebration: Equatable, Identifiable {
        let id: Int
        let size: TipSize
        let place: Place
    }

    private(set) var load: Load = .loading
    private(set) var purchasing: Purchase?
    private(set) var message: Message?
    /// Never cleared here: a new `id` is the signal.
    private(set) var celebration: Celebration?

    private let store: TipStore
    private let messageDuration: Duration
    private var messageTimer: Task<Void, Never>?
    private var celebrationCount = 0

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

    /// Buys one tip. A tap while another purchase runs does nothing.
    func buy(_ product: TipProduct, from place: Place) async {
        guard purchasing == nil else { return }
        purchasing = Purchase(productID: product.id, place: place)
        let result = await store.purchase(product.id)
        purchasing = nil
        switch result {
        case .success:
            if let size = product.size {
                celebrationCount += 1
                celebration = Celebration(id: celebrationCount, size: size, place: place)
            }
            show(Message(kind: .thanks, place: place))
        case .failed:
            show(Message(kind: .failed, place: place))
        case .cancelled, .pending:
            break
        }
    }

    /// Runs until cancelled: finishes the tip transactions that arrive from outside a purchase.
    func finishUpdates() async {
        await store.finishUpdates()
    }

    private func show(_ new: Message) {
        message = new
        messageTimer?.cancel()
        messageTimer = Task { [weak self, messageDuration] in
            try? await Task.sleep(for: messageDuration)
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }
}
