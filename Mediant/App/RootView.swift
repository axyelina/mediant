import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model
        Group {
            if model.hasAccess {
                ZStack(alignment: .bottom) {
                    switch model.tab {
                    case .albums:
                        NavigationStack(path: $model.albumsPath) {
                            AlbumsView()
                                .navigationDestination(for: AlbumInfo.self) { album in
                                    AlbumGridView(album: album)
                                }
                                .navigationDestination(for: SwipeRoute.self) { route in
                                    SwipeView(route: route)
                                }
                        }
                    case .trash:
                        TrashView()
                    }
                    if !model.isSwiping {
                        FloatingTabBar(selection: $model.tab, trashCount: model.store.trashCount)
                            .padding(.bottom, 8)
                    }
                }
            } else {
                AccessView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Coming back from Settings with new access.
            if phase == .active, !model.hasAccess { Task { await model.start() } }
        }
    }
}
