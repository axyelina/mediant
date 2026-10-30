import SwiftUI

/// The third tab: app language, resetting the progress dashboard, and the app version.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmsReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                section {
                    Text("Language").font(.headline)
                    Spacer(minLength: 12)
                    HStack(spacing: 6) {
                        ForEach(AppLanguage.allCases) { language in
                            // Names stay in their own language, so they are not translated.
                            Chip(LocalizedStringKey(language.nativeName),
                                 tint: model.language == language ? .pink : nil) {
                                withAnimation(.easeInOut(duration: 0.2)) { model.language = language }
                            }
                            .accessibilityAddTraits(model.language == language ? .isSelected : [])
                        }
                    }
                }

                section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress").font(.headline)
                        Text("Space freed and items deleted on the Albums page.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Chip("Reset", tint: .red) { confirmsReset = true }
                        .disabled(isProgressZero)
                        .opacity(isProgressZero ? 0.4 : 1)
                }

                section {
                    Text("Version").font(.headline)
                    Spacer()
                    Text(Self.version)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.bottom, FloatingTabBar.height + 24)
        }
        .confirmationDialog("Reset progress?", isPresented: $confirmsReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { model.stats.reset() }
            // Our own, so it is in the app language; the system one follows the phone.
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Space freed and items deleted go back to zero. Your photos do not change.")
        }
    }

    private var isProgressZero: Bool { model.stats.deletedCount == 0 && model.stats.freedBytes == 0 }

    /// "1.0 (1)": the marketing version and the build number.
    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    /// One glass card row, in the style of the progress card.
    private func section(@ViewBuilder _ content: () -> some View) -> some View {
        HStack(alignment: .center, spacing: 0, content: content)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.12), lineWidth: 1))
            .padding(.horizontal, 16)
    }
}
