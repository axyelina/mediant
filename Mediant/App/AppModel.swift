import Foundation
import Observation
import Photos
import SwiftUI

@MainActor
@Observable
final class AppModel {
    /// Left to right, as in the tab bar.
    enum Tab: Int, CaseIterable {
        case albums, trash, settings
    }

    let library: PhotoLibrary
    let store: DecisionStore
    let sizes: AlbumSizes
    let trash: TrashModel
    let stats: CleanupStats
    let reminder: TrashReminder
    let thumbs = ThumbnailLoader()

    var access: AccessLevel = .notDetermined
    var albums: [AlbumInfo] = []
    var tab: Tab = .albums
    var albumsPath = NavigationPath()
    /// True while the swipe screen is on screen; it hides the tab bar.
    var isSwiping = false
    /// False until the launch ✨ lands in the title; the title ✨ stays hidden until then.
    var splashFinished = false
    /// The app's own texts; remembered. Without a choice it follows the phone's language.
    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Self.languageKey) }
    }

    private static let languageKey = "appLanguage"
    private let defaults: UserDefaults

    @ObservationIgnored private var observer: LibraryObserver?
    @ObservationIgnored private var reloadTask: Task<Void, Never>?
    @ObservationIgnored private var startTask: Task<Void, Never>?

    init(library: PhotoLibrary = PhotoKitLibrary(), storeURL: URL = AppModel.defaultStoreURL,
         defaults: UserDefaults = .standard, notifications: NotificationCenterClient = SystemNotifications()) {
        self.library = library
        self.defaults = defaults
        language = AppLanguage.resolve(saved: defaults.string(forKey: Self.languageKey),
                                       preferred: Locale.preferredLanguages)
        store = DecisionStore(fileURL: storeURL)
        let folder = storeURL.deletingLastPathComponent()
        sizes = AlbumSizes(library: library, cacheURL: folder.appending(path: "album-sizes.json"))
        stats = CleanupStats(fileURL: folder.appending(path: "stats.json"))
        trash = TrashModel(store: store, library: library, stats: stats)
        reminder = TrashReminder(center: notifications, defaults: defaults)
        access = library.accessLevel()
        notifications.setTapHandler { [weak self] in self?.openTrash() }
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

    /// Shows the Trash tab. The swipe screen stays behind it, so swiping back returns to the same photo.
    func openTrash() {
        tab = .trash
    }

    /// Empties the Trash (one iOS dialog, see `TrashModel.emptyTrash()`). After a real delete the
    /// swipe screen closes: its photos may be gone, and its Undo would point at them.
    func emptyTrash() async {
        let before = trash.deleteCount
        await trash.emptyTrash()
        if trash.deleteCount != before { albumsPath = NavigationPath() }
    }

    /// Leaving with photos in the Trash schedules the reminder; coming back cancels it. A tap on the
    /// reminder opens the Trash.
    func sceneChanged(to phase: ScenePhase) {
        switch phase {
        case .background:
            let ids = store.trashedIDs
            let title = "Median't"
            let body = reminderText(count: ids.count, bytes: trash.totalBytes)
            // A few seconds of background time, so the schedule call can finish.
            let task = UIApplication.shared.beginBackgroundTask()
            Task {
                await reminder.appLeft(trash: ids, title: title, body: body)
                UIApplication.shared.endBackgroundTask(task)
            }
        case .active:
            reminder.appCameBack()
            Task { await reminder.refreshPermission() }
        default:
            break
        }
    }

    /// In the app's language, not the phone's: it is written now and shown later.
    private func reminderText(count: Int, bytes: Int64?) -> String {
        let bundle = Bundle.main.path(forResource: language.rawValue, ofType: "lproj").flatMap(Bundle.init(path:))
            ?? .main
        let locale = language.locale(region: Locale.current.region)
        guard let bytes else {
            return String(localized: "\(count) photos wait in the Trash. Empty it to free the space.",
                          bundle: bundle, locale: locale)
        }
        let size = ByteFormat.string(bytes, locale: locale)
        return String(localized: "\(count) photos (\(size)) wait in the Trash. Empty it to free the space.",
                      bundle: bundle, locale: locale)
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
