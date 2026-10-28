import Foundation
import Observation

/// All-time progress: how many photos the app deleted and how much space that freed.
@MainActor
@Observable
final class CleanupStats {
    private struct State: Codable {
        var deletedCount = 0
        var freedBytes: Int64 = 0
    }

    private let fileURL: URL
    private var state: State

    init(fileURL: URL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(State.self, from: data) {
            state = saved
        } else {
            state = State()
        }
    }

    var deletedCount: Int { state.deletedCount }
    var freedBytes: Int64 { state.freedBytes }

    func record(deleted: Int, bytes: Int64) {
        state.deletedCount += deleted
        state.freedBytes += bytes
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Saving stats failed: \(error)")
        }
    }
}
