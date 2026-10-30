#if DEBUG
import Foundation

/// A tip store for the simulator, chosen with the launch arguments `-fakeTips <preset>`.
/// It never talks to the App Store, and its prices are fixed strings.
/// Presets: `usd` (a short row), `kzt` and `idr` (long prices: 2 × 2), `fail` (every purchase fails),
/// `none` (the products never load).
struct DemoTipStore: TipStore {
    private enum Preset: String {
        case usd, kzt, idr, fail, none
    }

    private struct LoadFailed: Error {}

    private let preset: Preset

    /// `nil` unless `-fakeTips <preset>` is in the arguments.
    init?(launchArguments: [String]) {
        guard let flag = launchArguments.firstIndex(of: "-fakeTips"),
              launchArguments.indices.contains(flag + 1),
              let preset = Preset(rawValue: launchArguments[flag + 1]) else { return nil }
        self.preset = preset
    }

    func products(for ids: [String]) async throws -> [TipProduct] {
        if preset == .none { throw LoadFailed() }
        // The prices go up with the size, so the tip jar's sort keeps the order.
        let prices: [(text: String, value: Decimal)]
        switch preset {
        case .kzt:
            prices = [("499,00 ₸", 499), ("1 790,00 ₸", 1790), ("2 990,00 ₸", 2990), ("5 990,00 ₸", 5990)]
        case .idr:
            prices = [("Rp 19.000,00", 19000), ("Rp 59.000,00", 59000),
                      ("Rp 99.000,00", 99000), ("Rp 199.000,00", 199000)]
        default:
            prices = [("$0.99", 0.99), ("$2.99", 2.99), ("$4.99", 4.99), ("$9.99", 9.99)]
        }
        return zip(TipSize.allCases, prices)
            .map { TipProduct(id: $0.productID, displayPrice: $1.text, price: $1.value) }
            .filter { ids.contains($0.id) }
    }

    func purchase(_ id: String) async -> TipPurchaseResult {
        try? await Task.sleep(for: .milliseconds(500))
        return preset == .fail ? .failed : .success
    }

    func finishUpdates() async {}
}
#endif
