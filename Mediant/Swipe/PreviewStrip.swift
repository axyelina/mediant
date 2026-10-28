import SwiftUI

/// Small previews of the album at the bottom of the swipe screen; the current one is centered.
struct PreviewStrip: View {
    @Environment(AppModel.self) private var model
    let assets: [AssetInfo]
    let currentIndex: Int
    /// The photo that was just trashed; its 👹 plays the pop animation once.
    let justTrashedID: String?
    let onSelect: (Int) -> Void

    @State private var scrolledID: String?

    static let height: CGFloat = 36
    static let currentHeight: CGFloat = 42

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(Array(assets.enumerated()), id: \.element.id) { index, asset in
                        let isCurrent = index == currentIndex
                        let height = isCurrent ? Self.currentHeight : Self.height
                        PreviewTile(asset: asset,
                                    decision: model.store.decision(for: asset.id),
                                    size: CGSize(width: height * min(max(asset.aspect, 0.45), 2.2), height: height),
                                    isCurrent: isCurrent,
                                    animateBadge: asset.id == justTrashedID)
                            .id(asset.id)
                            .onTapGesture { onSelect(index) }
                    }
                }
                .scrollTargetLayout()
                .frame(height: Self.currentHeight + 4)
            }
            .contentMargins(.horizontal, proxy.size.width / 2, for: .scrollContent)
            .scrollPosition(id: $scrolledID, anchor: .center)
            .onAppear { scrolledID = id(at: currentIndex) }
            .onChange(of: currentIndex) { _, index in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { scrolledID = id(at: index) }
            }
        }
        .frame(height: Self.currentHeight + 4)
    }

    private func id(at index: Int) -> String? {
        assets.indices.contains(index) ? assets[index].id : assets.last?.id
    }
}

private struct PreviewTile: View {
    let asset: AssetInfo
    let decision: Decision?
    let size: CGSize
    let isCurrent: Bool
    let animateBadge: Bool

    var body: some View {
        AssetImage(id: asset.id)
            .frame(width: size.width, height: size.height)
            .overlay { if decision == .trashed { Color.black.opacity(0.55) } }
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay {
                if isCurrent { RoundedRectangle(cornerRadius: 5).strokeBorder(.white, lineWidth: 2) }
            }
            .overlay(alignment: .bottomTrailing) {
                if decision == .kept {
                    Text("💖").font(.system(size: 11)).offset(x: 3, y: 3)
                } else if decision == .trashed {
                    OgreBadge(tileSize: size, animate: animateBadge)
                }
            }
            .animation(.easeOut(duration: 0.25), value: isCurrent)
    }
}

/// 👹 in the corner. When `animate`, it fades in at the tile's full size, then shrinks into the corner.
private struct OgreBadge: View {
    let tileSize: CGSize
    let animate: Bool
    @State private var shown: Bool
    @State private var settled: Bool

    init(tileSize: CGSize, animate: Bool) {
        self.tileSize = tileSize
        self.animate = animate
        _shown = State(initialValue: !animate)
        _settled = State(initialValue: !animate)
    }

    var body: some View {
        // Offset from the corner position to the tile center.
        let toCenter = CGSize(width: tileSize.width / 2 - 4, height: tileSize.height / 2 - 4)
        Text("👹")
            .font(.system(size: 11))
            .shadow(color: .black.opacity(0.8), radius: 2)
            .scaleEffect(settled ? 1 : 3)
            .offset(x: 3 - (settled ? 0 : toCenter.width), y: 3 - (settled ? 0 : toCenter.height))
            .opacity(shown ? 1 : 0)
            .onAppear {
                guard animate, !settled else { return }
                withAnimation(.easeOut(duration: 0.15)) { shown = true }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.15)) { settled = true }
            }
    }
}
