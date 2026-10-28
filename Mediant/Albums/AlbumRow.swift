import SwiftUI

struct AlbumRow: View {
    let album: AlbumInfo
    let size: Int64?
    /// False while `size` is a cached value from an earlier launch.
    let sizeIsMeasured: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let cover = album.coverAssetID {
                    AssetImage(id: cover)
                } else {
                    Color(white: 0.15)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                Text(album.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 0) {
                    Text("\(counted(album.count, "item", "items")) · ")
                    Text(size.map { ByteFormat.string($0) } ?? "…")
                        .shimmering(!sizeIsMeasured)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle().fill(.separator).frame(height: 0.5).padding(.leading, 76)
        }
    }
}
