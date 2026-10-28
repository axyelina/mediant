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
    /// Kept (💖) photos are hidden unless this is on; it stays on until tapped again.
    @AppStorage("showKept") private var showKept = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        // Trashed photos never show; the swipe screen gets the same list the grid shows.
        let shown = visibleAssets(assets, store: model.store, showKept: showKept)
        ScrollView {
            if shown.isEmpty && !assets.isEmpty {
                VStack(spacing: 8) {
                    Text("✨").font(.system(size: 44))
                    Text("All sorted").font(.headline)
                    Text(showKept ? "Every photo here is in the Trash." : "Tap Show 💖 to see the photos you kept.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
            }
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { index, asset in
                    NavigationLink(value: SwipeRoute(album: album, assets: shown, startIndex: index)) {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay { AssetImage(id: asset.id) }
                            .clipped()
                            .contentShape(Rectangle())
                            .overlay(alignment: .bottomTrailing) {
                                DecisionBadge(decision: model.store.decision(for: asset.id))
                                    .padding(3)
                            }
                            .overlay(alignment: .bottomLeading) {
                                if asset.isVideo {
                                    Text("▶ \(VideoTime.string(asset.duration))")
                                        .font(.system(size: 11, weight: .semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.8), radius: 2)
                                        .padding(4)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, FloatingTabBar.height + 24)
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Chip("Show 💖", tint: showKept ? .pink : nil) { showKept.toggle() }
                    .accessibilityAddTraits(showKept ? .isSelected : [])
            }
        }
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
