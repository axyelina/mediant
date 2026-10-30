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
                        .tabPage(.albums, current: model.tab, width: screenWidth)
                        TrashView()
                            .tabPage(.trash, current: model.tab, width: screenWidth)
                        SettingsView()
                            .tabPage(.settings, current: model.tab, width: screenWidth)
                    }
                    .simultaneousGesture(edgeSwipe, including: edgeSwipeEnabled ? .all : .subviews)
                    // The swipe screen hides the tab bar, but not while another tab covers it.
                    if !model.isSwiping || model.tab != .albums {
                        FloatingTabBar(selection: $model.tab, trashCount: model.store.trashCount)
                            .padding(.bottom, 8)
                    }
                }
            } else {
                AccessView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The app's own texts follow the language chosen in Settings.
        .environment(\.locale, model.language.locale(region: Locale.current.region))
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
        model.tab != .albums || (!model.isSwiping && model.albumsPath.isEmpty)
    }

    /// A swipe from a page edge with a tab behind it switches to that tab.
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
    /// A tab page: in place when it is the current tab, otherwise slid out to its side of the bar
    /// (one screen width per tab between them), and then it takes no touches.
    func tabPage(_ page: AppModel.Tab, current: AppModel.Tab, width: CGFloat) -> some View {
        let shown = page == current
        return offset(x: CGFloat(page.rawValue - current.rawValue) * width)
            .allowsHitTesting(shown)
            .accessibilityHidden(!shown)
    }
}
