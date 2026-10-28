import SwiftUI

/// The small glass capsule button used for Back, 👹, Undo, Select and Empty.
/// `systemImage` puts an SF Symbol before the text.
struct Chip: View {
    let text: String
    var systemImage: String?
    var tint: Color?
    let action: () -> Void

    init(_ text: String, systemImage: String? = nil, tint: Color? = nil, action: @escaping () -> Void) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 12, weight: .bold))
                }
                Text(text)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(tint ?? .white)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background {
                Capsule().fill(.ultraThinMaterial)
                if let tint { Capsule().fill(tint.opacity(0.22)) }
            }
            .overlay(Capsule().strokeBorder((tint ?? .white).opacity(tint == nil ? 0.14 : 0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
