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
        }
    }
}
