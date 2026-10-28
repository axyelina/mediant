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
    let thumbs = ThumbnailLoader()

    var access: AccessLevel = .notDetermined
    var albums: [AlbumInfo] = []
    var tab: Tab = .albums
    var albumsPath = NavigationPath()
    /// True while the swipe screen is on screen; it hides the tab bar.
    var isSwiping = false

    @ObservationIgnored private var observer: LibraryObserver?
    @ObservationIgnored private var reloadTask: Task<Void, Never>?

    init(library: PhotoLibrary = PhotoKitLibrary(), storeURL: URL = AppModel.defaultStoreURL) {
        self.library = library
        store = DecisionStore(fileURL: storeURL)
        sizes = AlbumSizes(library: library)
        trash = TrashModel(store: store, library: library)
    }

    func start() async {
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
        albums = library.albums()
        store.removeMissing(keeping: library.existingIDs(among: store.knownIDs))
        await sizes.refresh(albums)
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
