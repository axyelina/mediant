import SwiftUI

/// Small previews of the album at the bottom of the swipe screen; the current one is centered.
///
/// No ScrollView: every tile's position is calculated from the current photo, so one animation
/// moves all tiles and resizes the current one together. (A scroll view animating to a target
/// while tiles change size made the strip jump.)
struct PreviewStrip: View {
    @Environment(AppModel.self) private var model
    let assets: [AssetInfo]
    let currentIndex: Int
    /// The photo that was just decided; its 💖 or 👹 plays the pop animation once.
    let justDecidedID: String?
    let onSelect: (Int) -> Void

    static let height: CGFloat = 36
    static let currentHeight: CGFloat = 42
    private static let gap: CGFloat = 4
    /// Tiles drawn on each side of the current one; more than enough to fill the screen.
    private static let reach = 30

    var body: some View {
        GeometryReader { proxy in
            let centers = Self.centers(around: currentIndex, in: assets)
            ZStack {
                ForEach(Array(centers.keys).sorted(), id: \.self) { index in
                    let asset = assets[index]
                    let size = Self.size(of: asset, current: index == currentIndex)
                    PreviewTile(asset: asset,
                                decision: model.store.decision(for: asset.id),
                                size: size,
                                isCurrent: index == currentIndex,
                                animateBadge: asset.id == justDecidedID)
                        .position(x: proxy.size.width / 2 + centers[index]!, y: proxy.size.height / 2)
                        .onTapGesture { onSelect(index) }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentIndex)
        }
        .frame(height: Self.currentHeight + 4)
    }

    static func size(of asset: AssetInfo, current: Bool) -> CGSize {
        let height = current ? currentHeight : height
        return CGSize(width: height * min(max(asset.aspect, 0.45), 2.2), height: height)
    }

    /// Center x of each tile near the current one, relative to the current tile's center.
    static func centers(around current: Int, in assets: [AssetInfo]) -> [Int: CGFloat] {
        guard assets.indices.contains(current) else { return [:] }
        var result = [current: CGFloat(0)]
        let half = size(of: assets[current], current: true).width / 2
        var edge = half
        for index in (current + 1)..<min(current + 1 + reach, assets.count) {
            let width = size(of: assets[index], current: false).width
            result[index] = edge + gap + width / 2
            edge += gap + width
        }
        edge = half
        for index in stride(from: current - 1, through: max(current - reach, 0), by: -1) {
            let width = size(of: assets[index], current: false).width
            result[index] = -(edge + gap + width / 2)
            edge += gap + width
        }
        return result
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
                if let decision {
                    PopBadge(emoji: decision == .kept ? "💖" : "👹", tileSize: size, animate: animateBadge)
                        .id(decision)
                }
            }
            .contentShape(Rectangle())
    }
}

/// 💖 or 👹 in the corner. When `animate`, it fades in at the tile's full size, then shrinks into the corner.
private struct PopBadge: View {
    let emoji: String
    let tileSize: CGSize
    let animate: Bool
    @State private var shown: Bool
    @State private var settled: Bool

    init(emoji: String, tileSize: CGSize, animate: Bool) {
        self.emoji = emoji
        self.tileSize = tileSize
        self.animate = animate
        _shown = State(initialValue: !animate)
        _settled = State(initialValue: !animate)
    }

    var body: some View {
        // Offset from the corner position to the tile center.
        let toCenter = CGSize(width: tileSize.width / 2 - 4, height: tileSize.height / 2 - 4)
        Text(emoji)
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
