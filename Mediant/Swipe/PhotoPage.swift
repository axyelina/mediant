import SwiftUI

/// One full-screen photo or video. The whole item always shows (aspect-fit) over a blurred copy.
/// A video shows its poster frame and a GIF its still picture; they play in a loop only while
/// `plays` (the top card).
struct PhotoPage: View {
    let asset: AssetInfo
    var plays = false

    var body: some View {
        ZStack {
            Color.black
            AssetImage(id: asset.id)
                .blur(radius: 26)
                .brightness(-0.45)
                .scaleEffect(1.15)
            AssetImage(id: asset.id, contentMode: .fit)
            if plays && asset.isVideo {
                LoopingVideo(asset: asset)
            }
            if plays && asset.isAnimated {
                AnimatedImageView(id: asset.id)
            }
        }
        .clipped()
    }
}
