/// Photos the album grid shows: never trashed ones; kept (💖) ones only when asked.
@MainActor
func visibleAssets(_ assets: [AssetInfo], store: DecisionStore, showKept: Bool) -> [AssetInfo] {
    assets.filter { asset in
        switch store.decision(for: asset.id) {
        case .trashed: false
        case .kept: showKept
        case nil: true
        }
    }
}
