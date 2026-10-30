import SwiftUI

@main
struct MediantApp: App {
    @State private var model = AppModel()

    init() {
        CrashReporting.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task { await model.start() }
                // Tips that finish outside a purchase (Ask to Buy, an interrupted payment).
                .task { await model.tips.finishUpdates() }
        }
    }
}
