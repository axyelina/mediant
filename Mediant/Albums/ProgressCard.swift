import SwiftUI

/// All-time cleanup progress at the bottom of the main page.
struct ProgressCard: View {
    let freedBytes: Int64
    let deletedCount: Int
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 0) {
            stat(value: ByteFormat.string(freedBytes, locale: locale), label: "space freed")
            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 28)
            // The catalog's plural forms of this key leave the number out: it is shown above.
            stat(value: deletedCount.formatted(.number.locale(locale)), label: "items deleted \(deletedCount)")
        }
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.12), lineWidth: 1))
    }

    private func stat(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
