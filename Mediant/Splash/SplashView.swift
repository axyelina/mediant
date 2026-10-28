import SwiftUI

/// The launch picture drawn in code. Its first frame is the static launch screen
/// (`LaunchScreen.storyboard`), so it takes over with no visible change. Then the three ✨ fly
/// into the `TitleSparkle` and the split background fades into the app.
struct SplashView: View {
    /// Frame of the title ✨, in this view's space (full screen). Nil until the title is laid out.
    let target: CGRect?
    let size: CGSize
    /// The ✨ is in the title: show the real one.
    let onLand: () -> Void
    /// Nothing of the splash is left on screen: remove it.
    let onDone: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started = false
    @State private var landed = false
    @State private var faded = false
    /// Reduce Motion, or no title to fly to: the whole splash fades out in place.
    @State private var gone = false

    var body: some View {
        let art = LaunchArt(screen: size)
        let palette = scheme == .dark ? Palette.dark : Palette.light
        let stars = landed ? (target.map(LaunchArt.clusterStars(in:)) ?? art.stars) : art.stars

        ZStack {
            ZStack {
                palette.keep
                Path { $0.addLines(art.deleteSide) }.fill(palette.delete)
            }
            .opacity(faded ? 0 : 1)

            ForEach(stars.indices, id: \.self) { i in
                // All layers of a star are one view, so they move as one. The title color is
                // underneath; the launch colors fade off on top of it.
                star.fill(palette.title)
                    .overlay { star.fill(palette.stars[i]).opacity(landed ? 0 : 1) }
                    .overlay {
                        if i == 0, let tint = palette.bigStarDeleteSide {
                            star.fill(tint).mask(DeleteHalf()).opacity(landed ? 0 : 1)
                        }
                    }
                    .frame(width: stars[i].size.width, height: stars[i].size.height)
                    .position(stars[i].center)
            }
        }
        .frame(width: size.width, height: size.height)
        .opacity(gone ? 0 : 1)
        .allowsHitTesting(!faded && !gone)
        .task(id: target != nil) {
            // iOS fades the static launch screen out over the first frames; moving before that
            // ends leaves a ghost ✨ behind. Without a title, just fade out.
            try? await Task.sleep(for: .milliseconds(target == nil ? 1000 : 400))
            guard !Task.isCancelled, !started else { return }
            started = true
            if target == nil || reduceMotion {
                onLand()
                withAnimation(.easeOut(duration: 0.35)) { gone = true } completion: { onDone() }
            } else {
                withAnimation(.easeOut(duration: 0.6)) { faded = true }
                // No bounce, and hand over only when the motion has fully stopped: an overshoot,
                // or a hand-over while the spring still settles, makes the ✨ twitch into place.
                withAnimation(.smooth(duration: 0.8), completionCriteria: .removed) { landed = true } completion: {
                    onLand()
                    onDone()
                }
            }
        }
    }

    private var star: StarShape {
        StarShape(pinchX: landed ? SparkleShape.pinch / SparkleShape.widthRatio : LaunchArt.iconPinch,
                  pinchY: landed ? SparkleShape.pinch : LaunchArt.iconPinch)
    }

    /// The delete side of the icon diagonal, in a star's own frame: the line goes through the
    /// star center, 24 points left for every 100 points down.
    private struct DeleteHalf: Shape {
        func path(in rect: CGRect) -> Path {
            let dx = 0.24 * rect.height / 2
            return Path { $0.addLines([
                CGPoint(x: rect.minX - 1, y: rect.minY), CGPoint(x: rect.midX + dx, y: rect.minY),
                CGPoint(x: rect.midX - dx, y: rect.maxY), CGPoint(x: rect.minX - 1, y: rect.maxY),
            ]) }
        }
    }

    /// Same colors as `Design/AppIcon/launch-light.svg` and `launch-dark.svg`.
    private struct Palette {
        var keep: Color
        var delete: Color
        /// Big, top-right small, bottom-left small.
        var stars: [Color]
        /// Dark only: the big ✨ is darker on the delete side of the diagonal.
        var bigStarDeleteSide: Color?
        var title: Color

        static let light = Palette(keep: Color(rgb: 0x75013D), delete: Color(rgb: 0x470112),
                                   stars: [.white, Color(rgb: 0xFFD1E3), Color(rgb: 0xFFB3C4)],
                                   title: Color(rgb: 0x75013D))
        static let dark = Palette(keep: Color(rgb: 0x1C0812), delete: Color(rgb: 0x12050A),
                                  stars: [Color(rgb: 0xFF5C93), Color(rgb: 0xFF5C93), Color(rgb: 0xC2184E)],
                                  bigStarDeleteSide: Color(rgb: 0xC2184E), title: Color(rgb: 0xFF5C93))
    }
}

/// The drawn ✨ cluster next to a title, where the launch ✨ lands. Hidden until the splash lands.
struct TitleSparkle: View {
    @Environment(AppModel.self) private var model
    var size: CGFloat

    var body: some View {
        SparkleShape(cluster: true)
            .fill(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(rgb: 0xFF5C93)) : UIColor(Color(rgb: 0x75013D)) }))
            .frame(width: size, height: size)
            .opacity(model.splashFinished ? 1 : 0)
            .anchorPreference(key: SplashTarget.self, value: .bounds) { $0 }
    }
}

/// Frame of the `TitleSparkle` on screen, for the splash to fly to.
struct SplashTarget: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

private extension Color {
    init(rgb: UInt32) {
        self.init(red: Double(rgb >> 16 & 0xFF) / 255, green: Double(rgb >> 8 & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }
}
