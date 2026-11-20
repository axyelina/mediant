import ImageIO
import SwiftUI
import UIKit

/// Plays a library GIF in a loop, fitted to the frame (aspect-fit), at its own frame times
/// (ImageIO decodes one frame at a time). It is clear until the data is loaded, so the still
/// picture under it shows; data with one frame never plays. It stops while the screen's
/// `VideoPlayback` is hidden (the Trash tab covers the swipe screen) and when it goes away.
/// It takes no touches: taps and drags go to the card.
struct AnimatedImageView: View {
    @Environment(AppModel.self) private var model
    @Environment(VideoPlayback.self) private var playback: VideoPlayback?
    let id: String
    @State private var data: Data?

    var body: some View {
        AnimationPlayer(id: id, data: data, paused: playback?.isHidden ?? false)
            .allowsHitTesting(false)
            .task(id: id) {
                data = nil
                guard let loaded = await model.thumbs.imageData(for: id), !Task.isCancelled else { return }
                let frames = await Task.detached(priority: .userInitiated) {
                    AnimatedImage.frameCount(of: loaded)
                }.value
                if frames > 1, !Task.isCancelled { data = loaded }
            }
    }
}

private struct AnimationPlayer: UIViewRepresentable {
    let id: String
    let data: Data?
    let paused: Bool

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        // The frame comes from SwiftUI, not from the image size.
        for axis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
            view.setContentHuggingPriority(.defaultLow, for: axis)
            view.setContentCompressionResistancePriority(.defaultLow, for: axis)
        }
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        context.coordinator.update(view, id: id, data: paused ? nil : data)
    }

    static func dismantleUIView(_ view: UIImageView, coordinator: Coordinator) {
        coordinator.stop()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator {
        /// The asset whose frames the view shows.
        private var shownID: String?
        /// True while an animation runs; a pause stops it and the last frame stays on screen.
        private var isPlaying = false
        /// Bumped on every start and stop, so an old animation's block stops itself.
        private var generation = 0

        func update(_ view: UIImageView, id: String, data: Data?) {
            if shownID != id {
                stop()
                view.image = nil
                shownID = id
            }
            guard let data else { return stop() }
            if !isPlaying { start(view, data: data) }
        }

        func stop() {
            generation += 1
            isPlaying = false
        }

        private func start(_ view: UIImageView, data: Data) {
            stop()
            isPlaying = true
            let mine = generation
            // Loop forever whatever loop count the file has, as the Photos app does.
            let options = [kCGImageAnimationLoopCount: kCFNumberPositiveInfinity] as CFDictionary
            // ImageIO calls the block on the main queue for each frame until `stop` is set.
            CGAnimateImageDataWithBlock(data as CFData, options) { [weak self, weak view] _, image, stop in
                MainActor.assumeIsolated {
                    guard let self, let view, self.generation == mine else {
                        stop.pointee = true
                        return
                    }
                    view.image = UIImage(cgImage: image)
                }
            }
        }
    }
}
