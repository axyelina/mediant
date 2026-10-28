import SwiftUI

struct TrashView: View {
    @Environment(AppModel.self) private var model

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        let trash = model.trash
        let ids = model.store.trashedIDs
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trash").font(.largeTitle.bold())
                    Text(ids.isEmpty ? "Nothing to delete"
                         : "\(counted(ids.count, "photo", "photos")) · \(ByteFormat.string(trash.totalBytes)) to free")
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
            .onTapGesture { if trash.isSelecting { trash.toggle(id) } }
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
                    Task { await trash.emptyTrash() }
                }
                .disabled(trash.isDeleting)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: FloatingTabBar.height)
        .padding(.bottom, 8)
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Text("👹").font(.system(size: 44))
            Text("Trash is empty").font(.headline)
            Text("Swipe left on photos you don't want.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }
}
