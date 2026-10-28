import SwiftUI

struct SwipeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let route: SwipeRoute

    @State private var session: SwipeSession?
    @State private var dragX: CGFloat = 0
    /// How far the top card has moved up on a skip (a tap on the photo).
    @State private var skipY: CGFloat = 0
    @State private var isAnimating = false
    @State private var justDecidedID: String?
    @State private var currentSize: Int64?
    @State private var playback = VideoPlayback()

    private let commitDistance: CGFloat = 90
    private let flingDistance: CGFloat = 160

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                Color.black
                if let session {
                    if session.isFinished {
                        finished(session, width: width)
                    } else {
                        pages(session, width: width, height: proxy.size.height)
                            .onTapGesture { skip(session, height: proxy.size.height) }
                            .gesture(drag(session, width: width))
                        SparkleEdge(side: .leading, color: Color(red: 0x47 / 255, green: 0x01 / 255, blue: 0x12 / 255), // #470112
                                    progress: dragX < 0 ? progress : 0)
                        SparkleEdge(side: .trailing, color: Color(red: 0x75 / 255, green: 0x01 / 255, blue: 0x3D / 255), // #75013d
                                    progress: dragX > 0 ? progress : 0)
                    }
                    overlay(session)
                }
            }
        }
        .ignoresSafeArea(edges: .vertical)
        .toolbar(.hidden, for: .navigationBar)
        .environment(playback)
        .sensoryFeedback(.impact(weight: .light), trigger: session?.index)
        .onAppear {
            if session == nil {
                session = SwipeSession(assetIDs: route.assets.map(\.id), startIndex: route.startIndex, store: model.store)
            }
            model.isSwiping = true
        }
        .onDisappear { model.isSwiping = false }
        .task(id: session?.currentID) {
            currentSize = nil
            guard let id = session?.currentID else { return }
            let library = model.library
            currentSize = await Task.detached(priority: .userInitiated) { library.fileSize(ofAsset: id) }.value
        }
    }

    private var progress: Double { Double(min(abs(dragX) / 110, 1)) }

    // MARK: Pages

    /// The current photo is a card on top: it follows the finger and tilts. The next one waits
    /// behind it, smaller and darker, and comes forward as the top card leaves.
    /// Pages are keyed by photo id, so the next page keeps its loaded image when it becomes current.
    private func pages(_ session: SwipeSession, width: CGFloat, height: CGFloat) -> some View {
        let current = route.assets[session.index]
        let next = route.assets.indices.contains(session.index + 1) ? [route.assets[session.index + 1]] : []
        let lift = min(max(abs(dragX) / width, -skipY / height), 1)
        return ZStack {
            ForEach(next + [current]) { asset in
                let isCurrent = asset.id == current.id
                PhotoPage(asset: asset, plays: isCurrent)
                    .overlay(Color.black.opacity(isCurrent ? 0 : 0.55 * (1 - lift)))
                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                    .scaleEffect(isCurrent ? 1 : 0.9 + 0.1 * lift)
                    .rotationEffect(.degrees(isCurrent ? Double(dragX / width) * 12 : 0), anchor: .bottom)
                    .offset(x: isCurrent ? dragX : 0, y: isCurrent ? skipY : 0)
            }
        }
    }

    /// How far the top card travels to leave the screen; it is tilted, so a width is not enough.
    private func offscreen(_ width: CGFloat) -> CGFloat { width * 1.5 }

    private func drag(_ session: SwipeSession, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isAnimating else { return }
                dragX = value.translation.width
            }
            .onEnded { value in
                guard !isAnimating else { return }
                let dx = value.translation.width
                if abs(dx) > commitDistance || abs(value.predictedEndTranslation.width) > flingDistance {
                    commit(dx < 0 || (dx == 0 && value.predictedEndTranslation.width < 0) ? .trashed : .kept,
                           session: session, width: width)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { dragX = 0 }
                }
            }
    }

    private func commit(_ decision: Decision, session: SwipeSession, width: CGFloat) {
        isAnimating = true
        let id = session.currentID
        withAnimation(.easeOut(duration: 0.26)) {
            dragX = decision == .trashed ? -offscreen(width) : offscreen(width)
        } completion: {
            withTransaction(Transaction(animation: nil)) {
                session.commit(decision)
                dragX = 0
                justDecidedID = id
            }
            isAnimating = false
        }
    }

    /// A tap skips the photo without a decision: the card slides up and away.
    private func skip(_ session: SwipeSession, height: CGFloat) {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(.easeOut(duration: 0.26)) {
            skipY = -height
        } completion: {
            withTransaction(Transaction(animation: nil)) {
                session.skip()
                skipY = 0
            }
            isAnimating = false
        }
    }

    private func undo(_ session: SwipeSession, width: CGFloat) {
        guard session.canUndo, !isAnimating, let last = session.lastCommitted else { return }
        isAnimating = true
        withTransaction(Transaction(animation: nil)) {
            session.undo()
            justDecidedID = nil
            // Start where the photo left the screen, then slide it back.
            dragX = last == .trashed ? -offscreen(width) : offscreen(width)
        }
        // Next run loop, so the start position is rendered before the slide.
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                dragX = 0
            } completion: {
                isAnimating = false
            }
        }
    }

    // MARK: Overlay

    private func overlay(_ session: SwipeSession) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack {
                    Chip("‹ Back") { dismiss() }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, proxy.safeAreaInsets.top + 52)

                Spacer()

                if !session.isFinished {
                    HStack(alignment: .center, spacing: 8) {
                        let asset = route.assets[session.index]
                        if asset.isVideo {
                            VideoChip(asset: asset)
                            Chip(playback.isMuted ? "🔇" : "🔊") { playback.toggleMuted() }
                        }
                        Text(currentSize.map { ByteFormat.string($0) } ?? "")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .monospacedDigit()
                            // On a video row the chips come first; the size shrinks before they do.
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .layoutPriority(-1)
                        Spacer(minLength: 0)
                        trashChip
                        Chip("↶ Undo") { undo(session, width: proxy.size.width) }
                            .opacity(session.canUndo ? 1 : 0.4)
                            .disabled(!session.canUndo)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)

                    PreviewStrip(assets: route.assets, currentIndex: session.index,
                                 justDecidedID: justDecidedID) { index in
                        guard !isAnimating else { return }
                        session.jump(to: index)
                    }
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 34)
                }
            }
            .background(alignment: .bottom) {
                LinearGradient(colors: [.black.opacity(0.85), .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 200)
                    .allowsHitTesting(false)
            }
        }
    }

    private func finished(_ session: SwipeSession, width: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text("✨").font(.system(size: 52))
            Text("All done").font(.title2.bold())
            HStack(spacing: 10) {
                Chip("↶ Undo") { undo(session, width: width) }
                trashChip
                Chip("Back to album") { dismiss() }
            }
        }
    }

    /// 👹 with the Trash count; a tap opens the Trash tab.
    private var trashChip: some View {
        Chip("👹 \(model.store.trashCount)") { model.openTrash() }
    }
}
