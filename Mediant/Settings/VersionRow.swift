import SwiftUI

/// The content of the Version card, the last card in Settings: the version line and a Copy chip,
/// so the version can go into a bug report. The chip says "Copied" for a second.
struct VersionRow: View {
    @State private var copied = false
    @State private var copyCount = 0
    @State private var resetTask: Task<Void, Never>?

    /// "Median't 1.0 (12)": display name, marketing version, build number.
    static func text(info: [String: Any]?) -> String {
        let name = info?["CFBundleDisplayName"] as? String ?? "Median't"
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(name) \(short) (\(build))"
    }

    private var text: String { Self.text(info: Bundle.main.infoDictionary) }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Version").font(.headline)
                // A name and numbers, nothing to translate.
                Text(verbatim: text)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 12)
            if copied {
                Chip("Copied", systemImage: "checkmark", tint: .pink, action: copy)
            } else {
                Chip("Copy", action: copy)
                    .accessibilityHint("Copies the version")
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: copyCount)
    }

    private func copy() {
        UIPasteboard.general.string = text
        copyCount += 1
        copied = true
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            copied = false
        }
    }
}
