import SwiftUI

/// Opens the swipe screen for an album at one photo.
struct SwipeRoute: Hashable {
    let album: AlbumInfo
    let assets: [AssetInfo]
    let startIndex: Int
}

struct AlbumGridView: View {
    @Environment(AppModel.self) private var model
    let album: AlbumInfo
    @State private var assets: [AssetInfo] = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(assets.enumerated()), id: \.element.id) { index, asset in
                    NavigationLink(value: SwipeRoute(album: album, assets: assets, startIndex: index)) {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay { AssetImage(id: asset.id) }
                            .clipped()
                            .contentShape(Rectangle())
                            .overlay(alignment: .bottomTrailing) {
                                DecisionBadge(decision: model.store.decision(for: asset.id))
                                    .padding(3)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, FloatingTabBar.height + 24)
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.large)
        .task(id: album.id) {
            let library = model.library
            let id = album.id
            assets = await Task.detached(priority: .userInitiated) { library.assets(inAlbum: id) }.value
            await model.thumbs.prefetch(assets.map(\.id))
        }
    }
}

/// 💖 for kept, 👹 for trashed, nothing for undecided.
struct DecisionBadge: View {
    let decision: Decision?

    var body: some View {
        if let decision {
            Text(decision == .kept ? "💖" : "👹")
                .font(.system(size: 12))
                .shadow(color: .black.opacity(0.8), radius: 2)
        }
    }
}
