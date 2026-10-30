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

    func makeModel() -> (AppModel, FakePhotoLibrary) {
        let library = FakePhotoLibrary()
        let model = AppModel(library: library, storeURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("model-\(UUID().uuidString)/decisions.json"))
        return (model, library)
    }

    @Test func openTrashKeepsTheSwipeScreenToComeBackTo() {
        let (model, _) = makeModel()
        model.albumsPath.append("album")
        model.albumsPath.append("swipe")
        model.openTrash()
        #expect(model.tab == .trash)
        #expect(model.albumsPath.count == 2)
    }

    @Test func emptyingTheTrashClosesTheSwipeScreen() async {
        // Its photos may be gone now, and its Undo would point at them.
        let (model, _) = makeModel()
        model.albumsPath.append("album")
        model.albumsPath.append("swipe")
        model.store.set(.trashed, for: "a")
        await model.emptyTrash()
        #expect(model.albumsPath.isEmpty)
    }

    @Test func declinedEmptyKeepsTheSwipeScreen() async {
        let (model, library) = makeModel()
        library.deleteError = DeleteError.declined
        model.albumsPath.append("swipe")
        model.store.set(.trashed, for: "a")
        await model.emptyTrash()
        #expect(model.albumsPath.count == 1)
    }

    @Test func leavingTrashEndsJustEmptied() async {
        let (model, _) = makeModel()
        model.tab = .trash
        model.store.set(.trashed, for: "a")
        await model.emptyTrash()
        #expect(model.trash.justEmptied != nil)
        model.tab = .albums
        #expect(model.trash.justEmptied == nil)
    }

    @Test func backgroundEndsJustEmptied() async {
        let (model, _) = makeModel()
        model.tab = .trash
        model.store.set(.trashed, for: "a")
        await model.emptyTrash()
        #expect(model.trash.justEmptied != nil)
        model.sceneChanged(to: .background)
        #expect(model.trash.justEmptied == nil)
    }
}
