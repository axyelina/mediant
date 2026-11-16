import SwiftUI

/// Shown when the app has no access to Photos.
struct AccessView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 14) {
            TitleSparkle(size: 56)
            Text("Median't needs your photos")
                .font(.title2.bold())
            Text("Swipe up to delete, down to keep. Your photos never leave your phone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Chip(model.access == .notDetermined ? "Allow access" : "Open Settings") {
                if model.access == .notDetermined {
                    Task { await model.start() }
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .padding(.top, 6)
        }
        .padding(32)
    }
}
