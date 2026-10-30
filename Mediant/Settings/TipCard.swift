import SwiftUI

/// The tip card in Settings: the icon's diagonal split, a short text and the four tip buttons.
/// After a tip from here the title says thanks for a moment; after a failed one the text says so.
struct TipCard: View {
    @Environment(AppModel.self) private var model

    private var tips: TipJar { model.tips }
    private var thanks: Bool { tips.message == .init(kind: .thanks, place: .settings) }
    private var failed: Bool { tips.message == .init(kind: .failed, place: .settings) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if thanks {
                    Text("Thank you! ✨")
                } else {
                    Text("Treat the developer ✨")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)

            Group {
                if failed {
                    Text("The tip did not go through.")
                } else {
                    Text("Median't is free: no ads, no subscription. I build it in my free time. If it helps you, you can leave a tip. It unlocks nothing.")
                }
            }
            .font(.subheadline)
            .foregroundStyle(Self.lightPink.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)

            if tips.load == .unavailable {
                Text("Tips are not available right now.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Self.lightPink)
            } else {
                TipButtons(place: .settings, style: .glass)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TipCardSplit())
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Self.pink.opacity(0.35), lineWidth: 1))
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: tips.message)
    }

    private static let lightPink = Color(red: 1, green: 0.820, blue: 0.890)  // #ffd1e3
    private static let pink = Color(red: 1, green: 0.361, blue: 0.576)  // #ff5c93
}

/// The icon art: wine on the left, darker magenta on the right, split along the line from 62 % of
/// the top edge to 38 % of the bottom edge.
private struct TipCardSplit: View {
    var body: some View {
        ZStack {
            Color(red: 0.278, green: 0.004, blue: 0.071)  // #470112
            SplitRight().fill(Color(red: 0.459, green: 0.004, blue: 0.239))  // #75013d
        }
    }

    private struct SplitRight: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
}
