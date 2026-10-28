import SwiftUI

/// "⏸ 0:12 / 0:32" for the top card's video, with the played part as a light fill.
/// Tap it to pause or play; the icon shows what a tap does. Drag it sideways to scrub: the video
/// stops while you drag, and a drag across `scrubWidth` covers all of it.
struct VideoChip: View {
    @Environment(VideoPlayback.self) private var playback
    let asset: AssetInfo

    private static let scrubWidth: Double = 300

    var body: some View {
        let isPlaying = playback.id == asset.id
        let progress = isPlaying && playback.duration > 0 ? min(playback.time / playback.duration, 1) : 0
        HStack(spacing: 6) {
            Image(systemName: isPlaying && !playback.isPaused ? "pause.fill" : "play.fill")
                .font(.system(size: 11, weight: .bold))
                .frame(width: 12)
                .contentTransition(.symbolEffect(.replace))
            Text(isPlaying ? "\(VideoTime.string(playback.time)) / \(VideoTime.string(asset.duration))"
                           : VideoTime.string(asset.duration))
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background {
            Capsule().fill(.ultraThinMaterial)
            GeometryReader { proxy in
                Rectangle()
                    .fill(.white.opacity(0.22))
                    .frame(width: proxy.size.width * progress)
            }
            .clipShape(Capsule())
        }
        .overlay(Capsule().strokeBorder(.white.opacity(playback.isScrubbing ? 0.6 : 0.14), lineWidth: 1))
        .scaleEffect(playback.isScrubbing ? 1.08 : 1)
        .animation(.easeOut(duration: 0.15), value: playback.isScrubbing)
        .contentShape(Capsule())
        .onTapGesture { playback.togglePaused() }
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    guard isPlaying else { return }
                    playback.beginScrub()
                    playback.scrub(by: value.translation.width, width: Self.scrubWidth)
                }
                .onEnded { _ in playback.endScrub() }
        )
    }
}
