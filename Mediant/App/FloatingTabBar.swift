import SwiftUI

/// Icon-only tab bar in a small glass capsule at the bottom center. Tap an icon, or swipe the
/// capsule sideways: left to Trash, right to Albums.
struct FloatingTabBar: View {
    @Binding var selection: AppModel.Tab
    let trashCount: Int

    static let height: CGFloat = 40

    var body: some View {
        HStack(spacing: 3) {
            item(.albums, symbol: "photo.on.rectangle", label: "Albums")
            item(.trash, symbol: "trash", label: "Trash")
                .overlay(alignment: .top) {
                    if trashCount > 0 {
                        Text("\(trashCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Capsule().fill(.red))
                            .offset(x: 10, y: -5)
                    }
                }
        }
        .padding(3)
        .frame(width: 92, height: Self.height)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1))
        .contentShape(Capsule())
        // Simultaneous, so a drag that starts on an icon still switches tabs.
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    let target = TabSwipe.target(translation: value.translation,
                                                 predictedEnd: value.predictedEndTranslation, from: selection)
                    guard target != selection else { return }
                    withAnimation(Self.switchAnimation) { selection = target }
                }
        )
    }

    static let switchAnimation = Animation.easeInOut(duration: 0.3)

    private func item(_ tab: AppModel.Tab, symbol: String, label: String) -> some View {
        Button {
            withAnimation(Self.switchAnimation) { selection = tab }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(selection == tab ? .white : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if selection == tab { Capsule().fill(.white.opacity(0.14)) }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
