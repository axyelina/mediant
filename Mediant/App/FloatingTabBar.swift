import SwiftUI

/// Icon-only tab bar in a small glass capsule (Liquid Glass on iOS 26+) at the bottom center. Tap an icon, or swipe the
/// capsule sideways to the next or previous tab (Albums, Trash, Settings).
struct FloatingTabBar: View {
    @Binding var selection: AppModel.Tab
    let trashCount: Int

    static let height: CGFloat = 40

    var body: some View {
        HStack(spacing: 3) {
            item(.albums, symbol: "photo.on.rectangle", label: "Albums")
            item(.trash, symbol: "trash", label: "Trash")
            item(.settings, symbol: "gearshape", label: "Settings")
        }
        .padding(3)
        .frame(width: 134, height: Self.height)
        .contentShape(Capsule())
        .glassBackground(in: Capsule(), interactive: true)
        // On the glass, not in it: inside, the glass tinted the badge with the pages sliding
        // behind it and clipped it where it sticks out, so it blinked on every tab switch.
        // The Trash icon is the middle one, so the bar's center is its center.
        .overlay(alignment: .top) {
            if trashCount > 0 {
                Text("\(trashCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Capsule().fill(.red))
                    .offset(x: 10, y: -2)
                    .allowsHitTesting(false)
            }
        }
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

    private func item(_ tab: AppModel.Tab, symbol: String, label: LocalizedStringKey) -> some View {
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
