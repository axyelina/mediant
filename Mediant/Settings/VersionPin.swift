import SwiftUI

/// The version line pinned above the tab bar on the Settings tab. Tap or long-press copies it, so
/// it can go into a bug report.
struct VersionPin: View {
    /// Space the line takes, with its gap to the tab bar, for the scroll content to leave free.
    static let height: CGFloat = 30

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
        Group {
            if copied {
                Text("Copied")
            } else {
                Text(text)
            }
        }
        .font(.footnote)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1))
        .contentShape(Capsule())
        .onTapGesture(perform: copy)
        .onLongPressGesture(perform: copy)
        .sensoryFeedback(.impact(weight: .light), trigger: copyCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(copied ? Text("Copied") : Text(text))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Copies the version")
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
