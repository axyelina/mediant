import SwiftUI

struct TrashView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    /// Opens the Photos app. iOS has no public link to the Recently Deleted album itself.
    private static let photosURL = URL(string: "photos-redirect://")!

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    /// The Trash item open full screen in `TrashViewer`.
    @State private var viewing: Viewing?
    /// Kind and length of each Trash item, for the video mark on its tile.
    @State private var infos: [String: AssetInfo] = [:]

    private struct Viewing: Identifiable { let id: String }

    var body: some View {
        let trash = model.trash
        let ids = model.store.trashedIDs
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trash").font(.largeTitle.bold())
                    Group {
                        if ids.isEmpty {
                            Text("Nothing to delete")
                        } else {
                            Text("\(ids.count) photos · \(ByteFormat.string(trash.totalBytes, locale: locale)) to free")
                        }
                    }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                if ids.isEmpty {
                    empty
                } else {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(ids.reversed(), id: \.self) { id in
                            tile(id, trash: trash)
                        }
                    }
                    .padding(.bottom, FloatingTabBar.height + 24)
                }
            }

            if !ids.isEmpty { bottomBar(trash) }
        }
        .task(id: ids) { await trash.refreshSize() }
        .task(id: ids) {
            // Off the main thread: this runs on every swipe up, and a big Trash is a slow fetch.
            let library = model.library
            let found = await Task.detached(priority: .utility) { library.assets(withIDs: ids) }.value
            guard !Task.isCancelled else { return }
            infos = Dictionary(found.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }
        .fullScreenCover(item: $viewing) { viewing in
            TrashViewer(startID: viewing.id, items: ids.reversed().compactMap { infos[$0] })
        }
        .alert("Couldn't delete", isPresented: Binding(
            get: { trash.errorMessage != nil },
            set: { if !$0 { trash.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(trash.errorMessage ?? "")
        }
        .sensoryFeedback(.success, trigger: trash.deleteCount)
    }

    private func tile(_ id: String, trash: TrashModel) -> some View {
        let selected = trash.selection.contains(id)
        return Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { AssetImage(id: id) }
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                Text("👹").font(.system(size: 12)).shadow(color: .black.opacity(0.8), radius: 2).padding(3)
            }
            .overlay(alignment: .bottomLeading) {
                if let info = infos[id], info.isVideo {
                    Text("▶ \(VideoTime.string(info.duration))")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.8), radius: 2)
                        .padding(4)
                } else if infos[id]?.isAnimated == true {
                    Text(verbatim: "GIF")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.8), radius: 2)
                        .padding(4)
                }
            }
            .overlay {
                if trash.isSelecting {
                    ZStack(alignment: .topTrailing) {
                        Color.black.opacity(selected ? 0 : 0.35)
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(.white, selected ? Color.accentColor : .clear)
                            .padding(6)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if trash.isSelecting { trash.toggle(id) } else { viewing = Viewing(id: id) }
            }
    }

    /// Same line as the floating tab bar: Select / Cancel on the left, Empty / Restore on the right.
    private func bottomBar(_ trash: TrashModel) -> some View {
        HStack {
            if trash.isSelecting {
                Chip("Cancel") { trash.cancelSelecting() }
                Spacer()
                Chip("Restore (\(trash.selection.count))") { trash.restoreSelected() }
                    .disabled(trash.selection.isEmpty)
                    .opacity(trash.selection.isEmpty ? 0.4 : 1)
            } else {
                Chip("Select") { trash.isSelecting = true }
                Spacer()
                Chip(trash.isDeleting ? "Deleting…" : "Empty", tint: .red) {
                    Task { await model.emptyTrash() }
                }
                .disabled(trash.isDeleting)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: FloatingTabBar.height)
        .padding(.bottom, 8)
    }

    private var empty: some View {
        let emptied = model.trash.justEmptied
        return VStack(spacing: 8) {
            if let emptied {
                // Just emptied: what this delete freed, then the tips.
                SparkleShape(cluster: true)
                    .fill(Self.pink)
                    .frame(width: 44, height: 44)
                Text("Done!").font(.headline)
                if let bytes = emptied.bytes {
                    Text("\(ByteFormat.string(bytes, locale: locale)) freed")
                        .font(.title.weight(.heavy))
                        // Light pink vanishes on a white page, so light appearance runs pink to wine.
                        .foregroundStyle(LinearGradient(colors: colorScheme == .light ? [Self.pink, Self.wine]
                                                                                      : [Self.lightPink, Self.pink],
                                                        startPoint: .leading, endPoint: .trailing))
                }
                Text("\(emptied.count) photos deleted")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("👹").font(.system(size: 44))
                Text("Trash is empty").font(.headline)
            }
            if model.stats.deletedCount > 0 {
                // iOS keeps deleted photos in Recently Deleted; the space comes back only from there.
                Text("Don't forget to delete them from Recently Deleted in Photos too. iOS keeps them there for 30 days, and they still take up space.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Chip("Open Photos", systemImage: "arrow.up.forward.app") { openURL(Self.photosURL) }
                    .padding(.top, 6)
            } else {
                Text("Swipe up on photos you don't want.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if emptied != nil, model.tips.load != .unavailable {
                tipSection
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, emptied == nil ? 120 : 48)
        .padding(.bottom, FloatingTabBar.height + 24)
    }

    /// A thin divider, one quiet line and the pink tip buttons. After a tip from here the line
    /// says thanks (or that it failed) for a moment.
    private var tipSection: some View {
        let tips = model.tips
        let thanks = tips.message == .init(kind: .thanks, place: .trash)
        let failed = tips.message == .init(kind: .failed, place: .trash)
        return VStack(spacing: 10) {
            Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1).padding(.horizontal, 24)
            Group {
                if thanks {
                    Text("Thank you! ✨")
                } else if failed {
                    Text("The tip did not go through.")
                } else {
                    Text("Liked it? Treat the developer ✨")
                }
            }
            .font(.subheadline)
            // Light pink vanishes on a white page, so light appearance takes the wine.
            .foregroundStyle(colorScheme == .light ? Self.wine : Self.lightPink)
            TipButtons(place: .trash, style: .pink)
                .padding(.horizontal, 16)
        }
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.2), value: tips.message)
    }

    private static let lightPink = Color(red: 1, green: 0.820, blue: 0.890)  // #ffd1e3
    private static let pink = Color(red: 1, green: 0.361, blue: 0.576)  // #ff5c93
    private static let wine = Color(red: 0.761, green: 0.094, blue: 0.306)  // #c2184e
}
