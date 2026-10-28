import SwiftUI

struct AlbumsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Albums").font(.largeTitle.bold())
                    Text("\(counted(model.albums.count, "album", "albums")) · \(ByteFormat.string(model.sizes.total))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                if model.access == .limited {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } label: {
                        Text("You shared only some photos. Allow all in Settings ›")
                            .font(.footnote)
                            .foregroundStyle(.tint)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                LazyVStack(spacing: 0) {
                    ForEach(model.albums) { album in
                        NavigationLink(value: album) {
                            AlbumRow(album: album, size: model.sizes.size(of: album.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, FloatingTabBar.height + 100)
        }
        .overlay(alignment: .bottom) {
            ProgressCard(freedBytes: model.stats.freedBytes, deletedCount: model.stats.deletedCount)
                .padding(.horizontal, 16)
                .padding(.bottom, FloatingTabBar.height + 18)
        }
        .navigationTitle("Albums")
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await model.reload() }
    }
}
