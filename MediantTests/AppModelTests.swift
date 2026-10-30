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

    // MARK: Tips

    struct Broken: Error {}

    func makeTipModel() -> (AppModel, FakeTipStore) {
        let tipStore = FakeTipStore()
        tipStore.products = [TipProduct(id: TipSize.small.productID, displayPrice: "$0.99", price: 0.99)]
        tipStore.loadError = Broken()
        let model = AppModel(library: FakePhotoLibrary(), storeURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("model-\(UUID().uuidString)/decisions.json"),
                             defaults: UserDefaults(suiteName: "model-\(UUID().uuidString)")!,
                             notifications: FakeNotificationCenter(), tipStore: tipStore)
        return (model, tipStore)
    }

    @Test(arguments: [AppModel.Tab.settings, .trash])
    func openingATipTabRetriesAFailedLoad(tab: AppModel.Tab) async {
        let (model, tipStore) = makeTipModel()
        await model.tips.loadIfNeeded()
        #expect(model.tips.load == .unavailable)
        tipStore.loadError = nil
        model.tab = tab
        // The tab change started the new attempt; this call waits for it.
        #expect(model.tips.load == .loading)
        await model.tips.loadIfNeeded()
        #expect(tipStore.loadCalls == 2)
        #expect(model.tips.load != .unavailable)
    }

    @Test func comingBackToTheAppRetriesAFailedLoad() async {
        let (model, tipStore) = makeTipModel()
        await model.tips.loadIfNeeded()
        tipStore.loadError = nil
        model.sceneChanged(to: .active)
        #expect(model.tips.load == .loading)
        await model.tips.loadIfNeeded()
        #expect(tipStore.loadCalls == 2)
    }

    @Test func albumsTabDoesNotLoadTips() async {
        let (model, tipStore) = makeTipModel()
        await model.tips.loadIfNeeded()
        model.tab = .trash
        await model.tips.loadIfNeeded()
        model.tab = .albums
        #expect(model.tips.load == .unavailable)
        #expect(tipStore.loadCalls == 2)
    }
}
