import SwiftUI

extension View {
    /// The glass behind the app's own controls (`Chip`, `VideoChip`, `FloatingTabBar`).
    /// iOS 26+: Liquid Glass, tinted when `tint` is set; `interactive` makes it react to touches.
    /// Earlier iOS: a thin material with a hairline border (a stronger border when tinted).
    /// Controls only: content such as cards stays on its material (Apple keeps glass for controls).
    @ViewBuilder
    func glassBackground<S: InsettableShape>(in shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.tint(tint?.opacity(0.3)).interactive(interactive), in: shape)
        } else {
            background {
                shape.fill(.ultraThinMaterial)
                if let tint { shape.fill(tint.opacity(0.22)) }
            }
            .overlay(shape.strokeBorder((tint ?? .primary).opacity(tint == nil ? 0.14 : 0.35), lineWidth: 1))
        }
    }
}

/// Glass controls that sit side by side. iOS 26+ renders them together in a
/// `GlassEffectContainer` (glass cannot sample other glass); earlier iOS shows the content as is.
struct GlassGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer { content }
        } else {
            content
        }
    }
}
