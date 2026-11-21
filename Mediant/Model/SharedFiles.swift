import Foundation

/// Temporary copies of library items for the iOS share sheet. Each share gets its own folder
/// under `baseDirectory`; `finish` deletes it when the sheet closes, and a failed export leaves
/// nothing behind. A new share first deletes copies left from earlier shares (the app was killed
/// while sharing, or the sheet could not open). One share runs at a time.
@MainActor
final class SharedFiles {
    private let library: PhotoLibrary
    private let baseDirectory: URL

    init(library: PhotoLibrary,
         baseDirectory: URL = FileManager.default.temporaryDirectory.appendingPathComponent("Share")) {
        self.library = library
        self.baseDirectory = baseDirectory
    }

    func prepare(_ id: String) async throws -> URL {
        try? FileManager.default.removeItem(at: baseDirectory)
        let folder = baseDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            return try await library.exportFile(ofAsset: id, to: folder)
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
    }

    /// Deletes the copy and its folder.
    func finish(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}
