import Foundation
import Testing
@testable import Mediant

@MainActor
struct AppModelTests {
    @Test func knowsAccessBeforeStart() {
        // The first frame must show the right screen, so the splash ✨ flies to the right title.
        let library = FakePhotoLibrary()
        library.level = .limited
        let model = AppModel(library: library, storeURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("model-\(UUID().uuidString)/decisions.json"))
        #expect(model.access == .limited)
    }
}
