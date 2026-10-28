import SwiftUI

struct AlbumRow: View {
    let album: AlbumInfo
    let size: Int64?

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
                Text("\(album.count.formatted()) items · \(size.map { ByteFormat.string($0) } ?? "…")")
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
