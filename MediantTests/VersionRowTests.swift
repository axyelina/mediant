import Testing
@testable import Mediant

struct VersionRowTests {
    @Test func textUsesDisplayNameVersionAndBuild() {
        let info: [String: Any] = [
            "CFBundleDisplayName": "Median't",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "12",
        ]
        #expect(VersionRow.text(info: info) == "Median't 1.0 (12)")
    }

    @Test func textWithoutInfo() {
        #expect(VersionRow.text(info: nil) == "Median't ? (?)")
    }
}
