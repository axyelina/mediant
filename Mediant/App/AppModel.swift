import Foundation
import Observation
import Photos
import SwiftUI

@MainActor
@Observable
final class AppModel {
    enum Tab {
        case albums, trash
    }

    let library: PhotoLibrary
    let store: DecisionStore
    let sizes: AlbumSizes
    let trash: TrashModel
    let stats: CleanupStats
    let thumbs = ThumbnailLoader()

    var access: AccessLevel = .notDetermined
    var albums: [AlbumInfo] = []
    var tab: Tab = .albums
    var albumsPath = NavigationPath()
    /// True while the swipe screen is on screen; it hides the tab bar.
    var isSwiping = false
    /// False until the launch ✨ lands in the title; the title ✨ stays hidden until then.
    var splashFinished = false

    @ObservationIgnored private var observer: LibraryObserver?
    @ObservationIgnored private var reloadTask: Task<Void, Never>?
    @ObservationIgnored private var startTask: Task<Void, Never>?

    init(library: PhotoLibrary = PhotoKitLibrary(), storeURL: URL = AppModel.defaultStoreURL) {
        self.library = library
        store = DecisionStore(fileURL: storeURL)
        let folder = storeURL.deletingLastPathComponent()
        sizes = AlbumSizes(library: library, cacheURL: folder.appending(path: "album-sizes.json"))
        stats = CleanupStats(fileURL: folder.appending(path: "stats.json"))
        trash = TrashModel(store: store, library: library, stats: stats)
        access = library.accessLevel()
    }

    /// Asks for access and loads the library. Calls while one is running wait for it.
    func start() async {
        if let startTask { return await startTask.value }
        let task = Task { await runStart() }
        startTask = task
        await task.value
        startTask = nil
    }

    private func runStart() async {
        access = library.accessLevel()
        if access == .notDetermined {
            access = await library.requestAccess()
        }
        guard hasAccess else { return }
        if observer == nil {
            observer = LibraryObserver { [weak self] in self?.scheduleReload() }
        }
        await reload()
    }

    var hasAccess: Bool { access == .full || access == .limited }

    /// Shows the Trash tab, leaving the swipe screen.
    func openTrash() {
        albumsPath = NavigationPath()
        tab = .trash
    }

    func reload() async {
        let library = library
        albums = await Self.offMain { library.albums() }
        let known = store.knownIDs
        let existing = await Self.offMain { library.existingIDs(among: known) }
        // Keep ids decided while the query ran.
        store.removeMissing(keeping: existing.union(Set(store.knownIDs).subtracting(known)))
        await sizes.refresh(albums)
    }

    /// Runs synchronous PhotoKit work off the main actor.
    private nonisolated static func offMain<T: Sendable>(_ work: @Sendable () -> T) async -> T {
        work()
    }

    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await reload()
        }
    }

    nonisolated static var defaultStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: "decisions.json")
    }
}

/// Calls back on the main actor when the photo library changes.
private final class LibraryObserver: NSObject, PHPhotoLibraryChangeObserver {
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in onChange() }
    }
}
