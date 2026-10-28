import SwiftUI

/// One full-screen photo. Tall photos fill the screen; wider ones fit over a blurred copy.
struct PhotoPage: View {
    let asset: AssetInfo

    private var fills: Bool { asset.aspect < 0.7 }

    var body: some View {
        ZStack {
            Color.black
            if !fills {
                AssetImage(id: asset.id)
                    .blur(radius: 26)
                    .brightness(-0.45)
                    .scaleEffect(1.15)
            }
            AssetImage(id: asset.id, contentMode: fills ? .fill : .fit)
        }
        .clipped()
    }
}
