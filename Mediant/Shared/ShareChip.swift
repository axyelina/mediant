import SwiftUI
import UIKit

/// The share chip at the top right of the full-screen photo (swipe screen and Trash viewer).
/// A tap exports the item's real file (`SharedFiles`), with a spinner in the chip meanwhile,
/// then opens the iOS share sheet; the copy is deleted when the sheet closes. A failed load
/// shows an alert. A tap while it loads does nothing.
struct ShareChip: View {
    @Environment(AppModel.self) private var model
    let id: String

    @State private var isLoading = false
    @State private var failed = false

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
        .alert("Couldn't share", isPresented: $failed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The photo could not be loaded. Check the connection and try again.")
        }
    }

    private func share() {
        guard !isLoading else { return }
        isLoading = true
        let files = SharedFiles(library: model.library)
        Task {
            defer { isLoading = false }
            do {
                let url = try await files.prepare(id)
                guard let presenter = Self.topViewController() else { return files.finish(url) }
                let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                sheet.completionWithItemsHandler = { _, _, _, _ in Task { @MainActor in files.finish(url) } }
                // iPad needs an anchor; on iPhone it is ignored.
                sheet.popoverPresentationController?.sourceView = presenter.view
                presenter.present(sheet, animated: true)
            } catch {
                failed = true
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
