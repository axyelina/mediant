import SwiftUI

/// One full-screen photo. The whole photo always shows (aspect-fit) over a blurred copy.
struct PhotoPage: View {
    let asset: AssetInfo

    var body: some View {
        ZStack {
            Color.black
            AssetImage(id: asset.id)
                .blur(radius: 26)
                .brightness(-0.45)
                .scaleEffect(1.15)
            AssetImage(id: asset.id, contentMode: .fit)
        }
        .clipped()
    }
}
