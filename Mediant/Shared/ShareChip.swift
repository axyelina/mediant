import SwiftUI
import UIKit

/// The share chip at the top right of the full-screen photo (swipe screen and Trash viewer).
/// A tap exports the item's real file (`SharedFiles`), with a spinner in the chip meanwhile,
/// then opens the iOS share sheet; the copy is deleted when the sheet closes. A failed load
/// shows an alert. A tap while it loads does nothing. The load stops when the chip goes away;
/// give the chip `.id(asset.id)` so a new item gets a new chip.
struct ShareChip: View {
    @Environment(AppModel.self) private var model
    let asset: AssetInfo
    private var id: String { asset.id }

    @State private var isLoading = false
    @State private var failed = false
    @State private var loading: Task<Void, Never>?

    var body: some View {
        Button(action: share) {
            ZStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().controlSize(.small).tint(.primary) }
            }
            .foregroundStyle(.primary)
            .frame(width: 40, height: 32)
            .contentShape(Capsule())
            .glassBackground(in: Capsule(), interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share")
        .onDisappear { loading?.cancel() }
        .alert("Couldn't share", isPresented: $failed) {
            Button("OK", role: .cancel) {}
        } message: {
            switch MediaKind(asset) {
            case .photo: Text("The photo could not be loaded. Check the connection and try again.")
            case .video: Text("The video could not be loaded. Check the connection and try again.")
            case .gif: Text("The GIF could not be loaded. Check the connection and try again.")
            }
        }
    }

    private func share() {
        guard !isLoading else { return }
        isLoading = true
        let files = SharedFiles(library: model.library)
        loading = Task {
            defer { isLoading = false }
            do {
                let url = try await files.prepare(id)
                // The user left this item meanwhile: no sheet for it.
                guard !Task.isCancelled, let presenter = Self.topViewController() else { return files.finish(url) }
                let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                sheet.completionWithItemsHandler = { _, _, _, _ in Task { @MainActor in files.finish(url) } }
                // iPad needs an anchor; on iPhone it is ignored.
                sheet.popoverPresentationController?.sourceView = presenter.view
                presenter.present(sheet, animated: true)
            } catch {
                if !Task.isCancelled { failed = true }
            }
        }
    }

    /// The view controller on top, so the sheet also opens over the Trash viewer (a full-screen cover).
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
