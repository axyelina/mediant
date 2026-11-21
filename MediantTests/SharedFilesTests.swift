import Foundation
import Testing
@testable import Mediant

@MainActor
struct SharedFilesTests {
    let library = FakePhotoLibrary()
    let base = FileManager.default.temporaryDirectory.appendingPathComponent("share-\(UUID().uuidString)")

    func folders() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil)) ?? []
    }

    @Test func prepareExportsTheFileIntoANewFolder() async throws {
        let files = SharedFiles(library: library, baseDirectory: base)
        let url = try await files.prepare("a")
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(url.deletingLastPathComponent().deletingLastPathComponent().standardizedFileURL
                == base.standardizedFileURL)
        #expect(folders().count == 1)
    }

    @Test func eachShareGetsItsOwnFolder() async throws {
        let files = SharedFiles(library: library, baseDirectory: base)
        let first = try await files.prepare("a")
        let second = try await files.prepare("a")
        #expect(first != second)
    }

    @Test func finishDeletesTheCopy() async throws {
        let files = SharedFiles(library: library, baseDirectory: base)
        let url = try await files.prepare("a")
        files.finish(url)
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(folders().isEmpty)
    }

    @Test func aFailedExportLeavesNothingBehind() async {
        library.exportError = CocoaError(.fileReadUnknown)
        let files = SharedFiles(library: library, baseDirectory: base)
        await #expect(throws: CocoaError.self) { try await files.prepare("a") }
        #expect(folders().isEmpty)
    }
}
