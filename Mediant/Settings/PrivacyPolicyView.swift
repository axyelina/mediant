import SwiftUI

/// The privacy policy, opened from the Privacy card in Settings. It leads with what the app never
/// collects, then says plainly what does leave the phone: crash reports (Crashlytics) and App Store
/// tips. Keep it true to the code: a new SDK, server or network call means a new paragraph here.
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    // One line: the Russian word is long and would break with a hyphen.
                    Text("Privacy")
                        .font(.largeTitle.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("Your photos stay on your phone.")
                        .font(.title2.bold())
                        .foregroundStyle(.pink)
                    Text("Median't has no account and no servers. It does not collect your photos, videos or anything about them.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)

                neverCollects

                topic("How it works", systemImage: "iphone") {
                    Text("The app reads your library on your iPhone to show the photos you swipe. Nothing is uploaded anywhere. With iCloud Photos, iOS can download a photo from iCloud to show it; that stays between your iPhone and Apple. When you tap Share, the app makes a temporary copy of that photo or video for the iOS share sheet. It goes only where you send it, and the app deletes the copy when you close the sheet (or, at the latest, when you share the next time).")
                }
                topic("Saved on your iPhone", systemImage: "internaldrive") {
                    Text("The app keeps a few things in its own storage: what you kept or put in the Trash, the space you freed, album sizes, your language and the reminder setting. They are part of your iPhone backup like other app data and go away when you delete the app.")
                }
                topic("Crash reports", systemImage: "ladybug") {
                    Text("If the app crashes, it sends a crash report to Firebase Crashlytics (Google) so the bug can be fixed. A report has the place in the code that crashed, the iPhone model, the iOS and app versions, free memory and storage, and a random ID of this install. It has no photos, album names or anything that tells who you are. Reports are kept for 90 days.")
                }
                topic("Tips", systemImage: "heart") {
                    Text("Tips go through the App Store, and Apple handles the payment. The developer does not get your name, Apple ID or card details. A tip unlocks nothing.")
                }
                topic("Trash reminder", systemImage: "bell") {
                    Text("The reminder is made on your iPhone. No server sends it.")
                }
                topic("Changes", systemImage: "doc.text") {
                    Text("If this policy changes, the new text comes with an app update.")
                }

                Text("Last updated: November 21, 2026")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            // The text scrolls fully above the pinned Done chip.
            .padding(.bottom, 32 + 16 + 32)
        }
        .scrollIndicators(.hidden)
        // In thumb reach, like the app's other primary actions.
        .overlay(alignment: .bottom) {
            Chip("Done") { dismiss() }
                .padding(.bottom, 16)
        }
    }

    /// The point of the page: a glass card that lists, one per line, what never leaves the phone.
    private var neverCollects: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Median't never collects").font(.headline)
            neverRow("Photos and videos")
            neverRow("Album names")
            neverRow("Dates, places and other photo details")
            neverRow("What you keep or delete")
            neverRow("Your name, email or contacts")
            neverRow("Anything for ads, analytics or tracking")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(.pink.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.pink.opacity(0.35), lineWidth: 1))
    }

    private func neverRow(_ text: LocalizedStringKey) -> some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.pink)
                .accessibilityHidden(true)
        }
    }

    private func topic(_ title: LocalizedStringKey, systemImage: String,
                       @ViewBuilder text: () -> Text) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            text()
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
        .preferredColorScheme(.dark)
}
