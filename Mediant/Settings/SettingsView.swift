import SwiftUI

/// The third tab: app language, the Trash reminder, the tip card, resetting the progress dashboard,
/// the privacy policy, the creator's Instagram and the version.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var confirmsReset = false
    @State private var showsPrivacy = false

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
                    GlassGroup { HStack(spacing: 6) {
                        ForEach(AppLanguage.allCases) { language in
                            // Names stay in their own language, so they are not translated.
                            Chip(LocalizedStringKey(language.nativeName),
                                 tint: model.language == language ? .pink : nil) {
                                withAnimation(.easeInOut(duration: 0.2)) { model.language = language }
                            }
                            .accessibilityAddTraits(model.language == language ? .isSelected : [])
                        }
                    } }
                }

                reminderSection

                TipCard()

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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Privacy").font(.headline)
                        Text("Your photos, videos and albums never leave your phone.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Chip("Read") { showsPrivacy = true }
                }

                section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dev's instagram 💅🏻").font(.headline)
                        // A handle, nothing to translate.
                        Text(verbatim: "@\(Self.instagramHandle)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Chip("Open") { openURL(Self.instagramURL) }
                        .accessibilityHint("Opens Instagram")
                }

                section { VersionRow() }
            }
            // The last card scrolls fully above the tab bar.
            .padding(.bottom, Self.tabBarSpace + 16)
        }
        .sheet(isPresented: $showsPrivacy) {
            PrivacyPolicyView()
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Reset progress?", isPresented: $confirmsReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { model.stats.reset() }
            // Our own, so it is in the app language; the system one follows the phone.
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Space freed and items deleted go back to zero. Your photos do not change.")
        }
    }

    /// On / Off chips; when iOS blocks notifications, a link to the app's iOS notification settings.
    private var reminderSection: some View {
        let reminder = model.reminder
        let blocked = reminder.isEnabled && reminder.permission == .denied
        return section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Trash reminder").font(.headline)
                Group {
                    if blocked {
                        Text("Notifications are off in iOS Settings.")
                    } else {
                        Text("One reminder when you leave photos in the Trash.")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                if blocked {
                    Chip("Open Settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                    }
                    .padding(.top, 4)
                }
            }
            Spacer(minLength: 12)
            GlassGroup {
                HStack(spacing: 6) {
                    Chip("On", tint: reminder.isEnabled ? .pink : nil) { Task { await reminder.turnOn() } }
                    Chip("Off", tint: reminder.isEnabled ? nil : .pink) { reminder.isEnabled = false }
                }
            }
        }
    }

    /// The creator's Instagram. iOS opens it in the Instagram app when it is installed, else in Safari.
    private static let instagramHandle = "axyelina"
    private static let instagramURL = URL(string: "https://www.instagram.com/\(instagramHandle)/")!

    private var isProgressZero: Bool { model.stats.deletedCount == 0 && model.stats.freedBytes == 0 }

    /// The tab bar sits 8 pt above the bottom (`RootView`).
    private static let tabBarSpace: CGFloat = FloatingTabBar.height + 8

    /// One glass card row, in the style of the progress card.
    private func section(@ViewBuilder _ content: () -> some View) -> some View {
        HStack(alignment: .center, spacing: 0, content: content)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.12), lineWidth: 1))
            .padding(.horizontal, 16)
    }
}
