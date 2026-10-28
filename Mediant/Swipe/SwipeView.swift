import SwiftUI

struct SwipeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let route: SwipeRoute

    @State private var session: SwipeSession?
    @State private var dragX: CGFloat = 0
    @State private var isAnimating = false
    @State private var justTrashedID: String?
    @State private var currentSize: Int64?

    private let commitDistance: CGFloat = 90
    private let flingDistance: CGFloat = 160

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                Color.black
                if let session {
                    if session.isFinished {
                        finished
                    } else {
                        pages(session, width: width)
                            .gesture(drag(session, width: width))
                        SparkleEdge(side: .leading, color: Color(red: 1, green: 0.27, blue: 0.23),
                                    progress: dragX < 0 ? progress : 0)
                        SparkleEdge(side: .trailing, color: Color(red: 0.19, green: 0.82, blue: 0.35),
                                    progress: dragX > 0 ? progress : 0)
                    }
                    overlay(session)
                }
            }
        }
        .ignoresSafeArea(edges: .vertical)
        .toolbar(.hidden, for: .navigationBar)
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

    /// The current photo follows the finger; the next one slides in from the other side.
    private func pages(_ session: SwipeSession, width: CGFloat) -> some View {
        let next = session.index + 1
        return ZStack {
            if route.assets.indices.contains(next) {
                PhotoPage(asset: route.assets[next])
                    .offset(x: dragX <= 0 ? width + dragX : -width + dragX)
            }
            PhotoPage(asset: route.assets[session.index])
                .offset(x: dragX)
        }
        .id(session.index)
    }

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
        withAnimation(.easeOut(duration: 0.22)) {
            dragX = decision == .trashed ? -width : width
        } completion: {
            withTransaction(Transaction(animation: nil)) {
                session.commit(decision)
                dragX = 0
                justTrashedID = decision == .trashed ? id : nil
            }
            isAnimating = false
        }
    }

    private func undo(_ session: SwipeSession, width: CGFloat) {
        guard session.canUndo, !isAnimating, let last = session.lastCommitted else { return }
        isAnimating = true
        withTransaction(Transaction(animation: nil)) {
            session.undo()
            justTrashedID = nil
            // Start where the photo left the screen, then slide it back.
            dragX = last == .trashed ? -width : width
        }
        withAnimation(.easeOut(duration: 0.25)) {
            dragX = 0
        } completion: {
            isAnimating = false
        }
    }

    // MARK: Overlay

    private func overlay(_ session: SwipeSession) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack {
                    Chip("‹ Back") { dismiss() }
                    Spacer()
                    Chip("👹 \(model.store.trashCount)") { model.openTrash() }
                }
                .padding(.horizontal, 12)
                .padding(.top, proxy.safeAreaInsets.top + 52)

                Spacer()

                if !session.isFinished {
                    HStack(alignment: .center) {
                        Text(sizeText(session))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .monospacedDigit()
                        Spacer()
                        Chip("↶ Undo") { undo(session, width: proxy.size.width) }
                            .opacity(session.canUndo ? 1 : 0.4)
                            .disabled(!session.canUndo)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)

                    PreviewStrip(assets: route.assets, currentIndex: session.index,
                                 justTrashedID: justTrashedID) { index in
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

    private func sizeText(_ session: SwipeSession) -> String {
        let asset = route.assets[session.index]
        let size = currentSize.map { ByteFormat.string($0) } ?? ""
        guard asset.isVideo else { return size }
        let seconds = Int(asset.duration.rounded())
        return "▶ \(seconds / 60):\(String(format: "%02d", seconds % 60))  \(size)"
    }

    private var finished: some View {
        VStack(spacing: 12) {
            Text("✨").font(.system(size: 52))
            Text("All done").font(.title2.bold())
            Chip("Back to album") { dismiss() }
        }
    }
}
