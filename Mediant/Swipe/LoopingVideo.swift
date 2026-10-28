import AVFoundation
import SwiftUI

/// Plays a library video in a loop through the screen's `VideoPlayback`, fitted to the frame
/// (aspect-fit). It is clear until the first frame is ready, so the poster under it shows while
/// the video loads. It takes no touches: taps and drags go to the card.
struct LoopingVideo: View {
    @Environment(AppModel.self) private var model
    @Environment(VideoPlayback.self) private var playback
    let asset: AssetInfo

    var body: some View {
        PlayerLayerView(player: playback.id == asset.id ? playback.player : nil)
            .allowsHitTesting(false)
            .task(id: asset.id) {
                guard let item = await model.thumbs.playerItem(for: asset.id), !Task.isCancelled else { return }
                playback.play(item, id: asset.id, duration: asset.duration)
            }
            .onDisappear { playback.stop(asset.id) }
    }
}

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerUIView { PlayerUIView() }

    func updateUIView(_ view: PlayerUIView, context: Context) {
        view.playerLayer.player = player
    }

    final class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            playerLayer.videoGravity = .resizeAspect
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    }
}
