import SwiftUI

@main
struct MediantApp: App {
    @State private var model: AppModel

    init() {
        CrashReporting.start()
        #if DEBUG
        // `-fakeTips <preset>` swaps the App Store for a fixed demo store (see DemoTipStore).
        let tipStore: TipStore = DemoTipStore(launchArguments: ProcessInfo.processInfo.arguments) ?? StoreKitTipStore()
        #else
        let tipStore: TipStore = StoreKitTipStore()
        #endif
        _model = State(initialValue: AppModel(tipStore: tipStore))
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
