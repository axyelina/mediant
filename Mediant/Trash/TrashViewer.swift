import SwiftUI

/// One Trash item full screen, shown over the whole app from the Trash grid. Looks like the swipe
/// screen: the whole photo over a blurred copy, a video loops with its chips. Left / right =
/// next / previous Trash item (grid order); right from the left edge or "‹ Back" closes;
/// up / down do nothing. "Restore" takes this one item out of the Trash. It never deletes.
struct TrashViewer: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var currentID: String
    /// The Trash in grid order (last trashed first); ids gone from the library are left out.
    @State private var items: [AssetInfo] = []
    @State private var dragX: CGFloat = 0
    @State private var isAnimating = false
    @State private var currentSize: Int64?
    @State private var restoreCount = 0
    @State private var playback = VideoPlayback()

    init(startID: String) {
        _currentID = State(initialValue: startID)
    }

    private var index: Int? { items.firstIndex { $0.id == currentID } }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                Color.black
                if let index {
                    pages(index, width: width)
                        .gesture(drag(index, width: width))
                    overlay(items[index])
                }
            }
            // A black screen in both appearances, like the swipe screen.
            .environment(\.colorScheme, .dark)
        }
        .ignoresSafeArea(edges: .vertical)
        .environment(playback)
        .sensoryFeedback(.impact(weight: .light), trigger: restoreCount)
        .task(id: model.store.trashedIDs) { await reload() }
        .task(id: currentID) {
            currentSize = nil
            let id = currentID
            let library = model.library
            currentSize = await Task.detached(priority: .userInitiated) { library.fileSize(ofAsset: id) }.value
        }
    }

    /// Follows the Trash: after a restore here, or when the library forgets the shown item, it
    /// shows the item that took its place (the previous one at the end); an empty Trash closes.
    private func reload() async {
        let oldIndex = index
        let ids = Array(model.store.trashedIDs.reversed())
        let library = model.library
        // Off the main thread: a big Trash is a slow PhotoKit fetch.
        let fresh = await Task.detached(priority: .userInitiated) { library.assets(withIDs: ids) }.value
        guard !Task.isCancelled else { return }
        items = fresh
        guard !fresh.contains(where: { $0.id == currentID }) else { return }
        if fresh.isEmpty {
            dismiss()
        } else {
            currentID = fresh[min(oldIndex ?? 0, fresh.count - 1)].id
        }
    }

    // MARK: Pages

    /// The current item follows a sideways drag; its neighbor comes in from that side.
    private func pages(_ index: Int, width: CGFloat) -> some View {
        let sideIndex = dragX == 0 ? nil : neighbor(of: index, step: dragX < 0 ? 1 : -1)
        let sideOffset = dragX < 0 ? dragX + width + Self.pageGap : dragX - width - Self.pageGap
        let shown = [sideIndex, index].compactMap { $0 }.map { items[$0] }
        return ZStack {
            ForEach(shown) { asset in
                let isCurrent = asset.id == currentID
                PhotoPage(asset: asset, plays: isCurrent)
                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                    .offset(x: isCurrent ? dragX : sideOffset)
            }
        }
    }

    private static let pageGap: CGFloat = 12

    private func neighbor(of index: Int, step: Int) -> Int? {
        items.indices.contains(index + step) ? index + step : nil
    }

    private func drag(_ index: Int, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isAnimating else { return }
                let t = value.translation
                let isBack = SwipeGesture.startsAtBackEdge(x: value.startLocation.x) && t.width > 0
                let dx = abs(t.height) >= abs(t.width) || isBack ? 0 : t.width
                // No item on that side: the card only gives a little.
                dragX = neighbor(of: index, step: dx < 0 ? 1 : -1) == nil ? dx / 4 : dx
            }
            .onEnded { value in
                guard !isAnimating else { return }
                switch SwipeGesture.outcome(startX: value.startLocation.x, translation: value.translation,
                                            predictedEnd: value.predictedEndTranslation) {
                case .next: browse(1, from: index, width: width)
                case .previous: browse(-1, from: index, width: width)
                case .back:
                    dragX = 0
                    dismiss()
                case .trash, .keep, .none: springBack()
                }
            }
    }

    private func springBack() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { dragX = 0 }
    }

    private func browse(_ step: Int, from index: Int, width: CGFloat) {
        guard let target = neighbor(of: index, step: step) else { return springBack() }
        // By id, not index: a Restore or a library change during the slide can shorten the list.
        let targetID = items[target].id
        isAnimating = true
        withAnimation(.easeOut(duration: 0.24)) {
            dragX = step > 0 ? -(width + Self.pageGap) : width + Self.pageGap
        } completion: {
            withTransaction(Transaction(animation: nil)) {
                if items.contains(where: { $0.id == targetID }) { currentID = targetID }
                dragX = 0
            }
            isAnimating = false
        }
    }

    private func restore(_ index: Int) {
        guard !isAnimating else { return }
        let remaining = items.filter { $0.id != currentID }
        let next = TrashBrowse.index(afterRestoring: index, count: items.count).map { remaining[$0].id }
        model.trash.restore(currentID)
        restoreCount += 1
        if let next { currentID = next } else { dismiss() }
    }

    // MARK: Overlay

    private func overlay(_ asset: AssetInfo) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack {
                    Chip("‹ Back") { dismiss() }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, proxy.safeAreaInsets.top + 52)

                Spacer()

                GlassGroup { HStack(spacing: 8) {
                    if asset.isVideo {
                        VideoChip(asset: asset)
                        Chip(playback.isMuted ? "🔇" : "🔊") { playback.toggleMuted() }
                    }
                    Text(currentSize.map { ByteFormat.string($0, locale: locale) } ?? "")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(-1)
                    Spacer(minLength: 0)
                    Chip("Restore") {
                        if let index { restore(index) }
                    }
                } }
                .padding(.horizontal, 14)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 24)
            }
            .background(alignment: .bottom) {
                LinearGradient(colors: [.black.opacity(0.85), .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 160)
                    .allowsHitTesting(false)
            }
        }
    }
}
