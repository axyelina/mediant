import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @State private var splashGone = false
    @State private var screenWidth: CGFloat = 0

    var body: some View {
        @Bindable var model = model
        Group {
            if model.hasAccess {
                ZStack(alignment: .bottom) {
                    // Both tabs stay alive, so the swipe screen keeps its photo and Undo while the
                    // Trash is on top. Tabs sit left to right as in the tab bar and slide that way.
                    ZStack {
                        NavigationStack(path: $model.albumsPath) {
                            AlbumsView()
                                .navigationDestination(for: AlbumInfo.self) { album in
                                    AlbumGridView(album: album)
                                }
                                .navigationDestination(for: SwipeRoute.self) { route in
                                    SwipeView(route: route)
                                }
                        }
                        .tabPage(shown: model.tab == .albums, offset: -screenWidth)
                        TrashView()
                            .tabPage(shown: model.tab == .trash, offset: screenWidth)
                    }
                    .simultaneousGesture(edgeSwipe, including: edgeSwipeEnabled ? .all : .subviews)
                    // The swipe screen hides the tab bar, but not while the Trash covers it.
                    if !model.isSwiping || model.tab == .trash {
                        FloatingTabBar(selection: $model.tab, trashCount: model.store.trashCount)
                            .padding(.bottom, 8)
                    }
                }
            } else {
                AccessView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { screenWidth = $0 }
        .overlayPreferenceValue(SplashTarget.self) { target in
            if !splashGone {
                GeometryReader { proxy in
                    SplashView(target: target.map { proxy[$0] }, size: proxy.size,
                               onLand: { model.splashFinished = true },
                               onDone: { splashGone = true })
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Coming back from Settings with new access.
            if phase == .active, !model.hasAccess { Task { await model.start() } }
        }
    }

    /// Only on the root pages: the swipe screen has its own drag, and the left edge of a pushed
    /// album page is the system's back swipe.
    private var edgeSwipeEnabled: Bool {
        model.tab == .trash || (!model.isSwiping && model.albumsPath.isEmpty)
    }

    /// A swipe from the page edge on the side of the other tab switches to it.
    private var edgeSwipe: some Gesture {
        DragGesture(minimumDistance: 15, coordinateSpace: .global)
            .onEnded { value in
                guard edgeSwipeEnabled,
                      TabSwipe.startsAtEdge(x: value.startLocation.x, width: screenWidth, on: model.tab) else { return }
                let target = TabSwipe.target(translation: value.translation,
                                             predictedEnd: value.predictedEndTranslation, from: model.tab)
                guard target != model.tab else { return }
                withAnimation(FloatingTabBar.switchAnimation) { model.tab = target }
            }
    }
}

private extension View {
    /// A tab page that slides out by `offset` when it is not shown, and then takes no touches.
    func tabPage(shown: Bool, offset: CGFloat) -> some View {
        self.offset(x: shown ? 0 : offset)
            .allowsHitTesting(shown)
            .accessibilityHidden(!shown)
    }
}
