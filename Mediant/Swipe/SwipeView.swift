import SwiftUI

struct SwipeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    let route: SwipeRoute

    @State private var session: SwipeSession?
    /// How far the top card has moved: up (< 0) to delete, down (> 0) to keep.
    @State private var dragY: CGFloat = 0
    @State private var isAnimating = false
    @State private var justDecidedID: String?
    @State private var currentSize: Int64?
    @State private var playback = VideoPlayback()

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            ZStack {
                Color.black
                if let session {
                    if session.isFinished {
                        finished(session, height: height)
                    } else {
                        pages(session, height: height)
                            .gesture(drag(session, height: height))
                    }
                    overlay(session)
                    // Over the overlay: its bottom gradient and bar would hide the bottom band.
                    // Sparkles take no taps, so the chips under them still work.
                    if !session.isFinished {
                        SparkleEdge(side: .top, color: Color(red: 0x47 / 255, green: 0x01 / 255, blue: 0x12 / 255), // #470112
                                    progress: dragY < 0 ? progress : 0)
                        SparkleEdge(side: .bottom, color: Color(red: 0x75 / 255, green: 0x01 / 255, blue: 0x3D / 255), // #75013d
                                    progress: dragY > 0 ? progress : 0)
                    }
                }
            }
            // The screen is black in both appearances, so its chips and texts stay dark-styled.
            .environment(\.colorScheme, .dark)
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
        .onChange(of: model.tab, initial: true) { _, tab in playback.setHidden(tab != .albums) }
        .task(id: session?.currentID) {
            currentSize = nil
            guard let id = session?.currentID else { return }
            let library = model.library
            currentSize = await Task.detached(priority: .userInitiated) { library.fileSize(ofAsset: id) }.value
        }
    }

    private var progress: Double { Double(min(abs(dragY) / 110, 1)) }

    // MARK: Pages

    /// The current photo is a card on top: it follows the finger up or down. The next one waits
    /// behind it, smaller and darker, and comes forward as the top card leaves.
    /// Pages are keyed by photo id, so the next page keeps its loaded image when it becomes current.
    private func pages(_ session: SwipeSession, height: CGFloat) -> some View {
        let current = route.assets[session.index]
        // After the last photo the run goes on with unsorted ones, so "next" is not always index + 1.
        let next = session.upcomingIndex.map { [route.assets[$0]] } ?? []
        let lift = min(abs(dragY) / height, 1)
        return ZStack {
            ForEach(next + [current]) { asset in
                let isCurrent = asset.id == current.id
                PhotoPage(asset: asset, plays: isCurrent)
                    .overlay(Color.black.opacity(isCurrent ? 0 : 0.55 * (1 - lift)))
                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                    .scaleEffect(isCurrent ? 1 : 0.9 + 0.1 * lift)
                    .offset(y: isCurrent ? dragY : 0)
            }
        }
    }

    /// Where the top card goes for a decision: off the top for 👹, off the bottom for 💖.
    private func offscreen(_ decision: Decision, height: CGFloat) -> CGFloat {
        decision == .trashed ? -height : height
    }

    /// Up = delete, down = keep (the card follows only vertically); right = back to the album.
    private func drag(_ session: SwipeSession, height: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isAnimating else { return }
                // A mostly horizontal drag is the back swipe: the card stays put.
                dragY = abs(value.translation.height) >= abs(value.translation.width) ? value.translation.height : 0
            }
            .onEnded { value in
                guard !isAnimating else { return }
                switch SwipeGesture.outcome(translation: value.translation, predictedEnd: value.predictedEndTranslation) {
                case .trash: commit(.trashed, session: session, height: height)
                case .keep: commit(.kept, session: session, height: height)
                case .back:
                    dragY = 0
                    dismiss()
                case .none:
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { dragY = 0 }
                }
            }
    }

    private func commit(_ decision: Decision, session: SwipeSession, height: CGFloat) {
        isAnimating = true
        let id = session.currentID
        withAnimation(.easeOut(duration: 0.26)) {
            dragY = offscreen(decision, height: height)
        } completion: {
            withTransaction(Transaction(animation: nil)) {
                session.commit(decision)
                dragY = 0
                justDecidedID = id
            }
            isAnimating = false
        }
    }

    private func undo(_ session: SwipeSession, height: CGFloat) {
        guard session.canUndo, !isAnimating, let last = session.lastCommitted else { return }
        isAnimating = true
        withTransaction(Transaction(animation: nil)) {
            session.undo()
            justDecidedID = nil
            // Start where the photo left the screen, then slide it back.
            dragY = offscreen(last, height: height)
        }
        // Next run loop, so the start position is rendered before the slide.
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                dragY = 0
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
                    GlassGroup { HStack(alignment: .center, spacing: 8) {
                        let asset = route.assets[session.index]
                        if asset.isVideo {
                            VideoChip(asset: asset)
                            Chip(playback.isMuted ? "🔇" : "🔊") { playback.toggleMuted() }
                        }
                        Text(currentSize.map { ByteFormat.string($0, locale: locale) } ?? "")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .monospacedDigit()
                            // On a video row the chips come first; the size shrinks before they do.
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .layoutPriority(-1)
                        Spacer(minLength: 0)
                        trashChip
                        Chip("Undo", systemImage: "arrow.uturn.backward") { undo(session, height: proxy.size.height) }
                            .opacity(session.canUndo ? 1 : 0.4)
                            .disabled(!session.canUndo)
                    } }
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

    private func finished(_ session: SwipeSession, height: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text("✨").font(.system(size: 52))
            Text("All done").font(.title2.bold())
            GlassGroup {
                HStack(spacing: 10) {
                    Chip("Undo", systemImage: "arrow.uturn.backward") { undo(session, height: height) }
                    trashChip
                    Chip("Back to album") { dismiss() }
                }
            }
        }
    }

    /// 👹 with the Trash count; a tap opens the Trash tab.
    private var trashChip: some View {
        Chip("👹 \(model.store.trashCount)") {
            withAnimation(FloatingTabBar.switchAnimation) { model.openTrash() }
        }
    }
}
