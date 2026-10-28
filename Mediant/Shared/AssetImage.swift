import Photos
import SwiftUI

/// A PhotoKit image that loads for the view's size.
struct AssetImage: View {
    @Environment(AppModel.self) private var model
    let id: String
    var contentMode: ContentMode = .fill
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // A fitted image keeps whatever is behind it visible.
                if contentMode == .fill { Color(white: 0.12) }
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .clipped()
            .task(id: TaskKey(id: id, size: proxy.size)) {
                guard proxy.size.width > 0 else { return }
                image = await model.thumbs.image(
                    for: id, target: proxy.size,
                    contentMode: contentMode == .fill ? .aspectFill : .aspectFit)
            }
        }
    }

    private struct TaskKey: Equatable {
        let id: String
        let size: CGSize
    }
}
