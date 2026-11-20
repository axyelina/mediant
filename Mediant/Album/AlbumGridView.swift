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
    /// Kept (💖) photos are hidden unless this is on. The "Don't show 💖" button is on while this
    /// is off (the default); the choice is remembered.
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
                    Text(showKept ? LocalizedStringKey("Every photo here is in the Trash.")
                                  : "Tap Don't show 💖 to see the photos you kept.")
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
                                } else if asset.isAnimated {
                                    Text(verbatim: "GIF")
                                        .font(.system(size: 11, weight: .semibold))
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
                HideKeptButton(isOn: !showKept) { showKept.toggle() }
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

/// "Don't show 💖": hides the kept photos while on (pink). On iOS 26+ the navigation bar puts
/// Liquid Glass around toolbar items itself, so a system glass button is used there instead of
/// the `Chip`, which would draw a second capsule inside the system one.
private struct HideKeptButton: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                if isOn {
                    Button("Don't show 💖", action: action)
                        .buttonStyle(.glassProminent)
                        .tint(.pink)
                } else {
                    Button("Don't show 💖", action: action)
                }
            } else {
                Chip("Don't show 💖", tint: isOn ? .pink : nil, action: action)
            }
        }
        .accessibilityAddTraits(isOn ? .isSelected : [])
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
