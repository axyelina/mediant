# TODO / ideas

Loose backlog, not a plan. Before building an item, check it against the design's non-goals and
anti-goals (`docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md`): no ads, no
subscription, no tracking, no per-swipe delete dialog, compact controls in thumb reach.

## ⚠️ Before the first release

- [ ] **Firebase: fill in the App Store ID.** In the Firebase console, open Project settings →
      Your apps → the iOS app `app.mediant` and enter the App Store ID. That is the numeric Apple ID
      from App Store Connect (App Information → Apple ID); it exists once the app record is created
      there, before the first upload to the store.
- [ ] **App Store privacy label for Crashlytics:** "Crash Data" and "Other Diagnostic Data"
      (sessions), used for App Functionality, not linked to the user, no tracking. Check against
      Firebase's current data-disclosure page.
- [ ] **Privacy policy URL for App Store Connect.** The policy is in the app (Settings › Privacy,
      `PrivacyPolicyView`), but App Store Connect needs a public URL. Put the same text (English
      and Russian) on a web page, e.g. GitHub Pages, and add a contact (e-mail) there and in the app.
- [ ] **First TestFlight build.** Done: export compliance key, build number lanes
      (`fastlane beta`, see the `testflight` skill), binary check. Still to do:
      - Apple Distribution certificate for team `NDCC8HH7D8` (the user does it: Xcode › Settings ›
        Accounts with an Admin / Account Holder Apple ID; the first `fastlane beta` makes it);
      - an internal tester group in App Store Connect › TestFlight;
      - external testers only: Test Information (description, feedback e-mail, review contact,
        privacy policy URL) and Beta App Review.
- [ ] **Binary check again before the store release** (or after a new dependency or resource) —
      steps in the `testflight` skill. First check 2026-11-10: clean except `/Users/…` paths
      from GoogleDataTransport `__FILE__`, which `fastlane beta` now removes
      (`-fmacro-prefix-map`); an Xcode Organizer archive still has them.

## From the user

- [ ] **Working with video.** Shipped: looping playback on the top card, scrub on the ▶ chip,
      🔊/🔇 chip, ▶ badge in the album grid. Still open: show the video size more prominently
      (videos are where the space is).
- [ ] **Settings tab — what is left.** Shipped: language switch, progress reset, version, the tip
      card (see "Shipped, 2026-10-31"), the Instagram card (@axyelina). Still to add:
      - about the creator (name, short text) — waits for the text. The link shipped as the
        Instagram card.
- [ ] **Tips — what is left.** The tip jar and the Trash tips shipped (2026-10-31). Still open:
      - one real sandbox tip on the phone `LINK` (Settings › App Store › Sandbox Account): check the
        real price, the purchase sheet, the fireworks and the haptic on each burst. If the products
        do not load, the App Review screenshots are not processed yet.
      - App Store Connect: Paid Apps Agreement (bank + tax), join the Small Business Program (15%
        instead of 30%). Review notes: "Optional tips, they unlock nothing, the app is fully free."
        Seller name on the purchase sheet is the team's (Angelina Odegova).
      - Submit the 4 tips together with an app version (by hand in App Store Connect).

      Decided (App Review Guidelines, checked 2026-10-30, page updated 2026-10-16): **tips are
      consumable in-app purchases (StoreKit), not an outside "Buy me a coffee" link.**
      - 3.1.1 lets apps take "tips" for the developer through in-app purchase. Outside links to
        other payment methods are banned in every storefront except the US (3.1.1(a) / 3.1.3), and
        the app ships in Russian too. Forum reports show "Tips" / "Support the developer" links
        rejected under 3.1.1. Collecting "donations" is for approved nonprofits only (3.2.1(vi),
        3.2.2(iv)) — say "tip", never "donate". The 3.2.1(vii) gift rule needs 100% of the money to
        reach the receiver, which Buy Me a Coffee / Ko-fi fees break.
      - 4 consumable tips, prices from `Product.displayPrice`, never hard-coded. A tip unlocks
        nothing — no features, badges or icons. One "thank you" after a tip, then silence.

## From Claude

### Video
- [ ] "Biggest first" order for an album, or a "Large videos" smart source — fastest way to free space.

### Swiping
- [ ] Swipe up = "decide later" / skip without marking (leaves the photo undecided).
- [ ] Burst photos and Live Photos: show the count of frames / the "LIVE" badge so the user knows
      what they delete.
- [ ] "On this day" / by-month source: swipe through one month at a time, a natural session size.
- [ ] Undo after leaving and coming back. Going to the Trash and back keeps Undo now; Back to the
      albums list and an app restart still lose it (the undo stack lives only in the session).

### Trash
- [ ] Show the total size of the Trash on the "Empty" button (e.g. "Empty · 1.2 GB").
- [ ] Group Trash items by album or date.

### Albums / progress
- [ ] Per-album progress ring (decided / total) on the album row.
- [ ] Hide albums that are fully reviewed, or sort them to the bottom.
- [ ] Small celebration when an album is fully reviewed (✨, haptic).

### Platform
- [ ] Home Screen widget with "space freed" from `CleanupStats`.
- [ ] VoiceOver: actions for keep / delete / undo on the swipe screen, labels on emoji-only chips.
- [ ] More languages after Russian (the String Catalog makes each one cheap).
- [ ] Reduce Motion: tone down sparkles and the ogre pop.

## Shipped

### 2026-11-10
- [x] Settings: Privacy card and the in-app privacy policy (what the app never collects; crash
      reports and tips said plainly), English + Russian.
- [x] Settings: the version is a card like the others, with a Copy chip (no longer a capsule
      pinned above the tab bar).
- [x] The app's privacy manifest `PrivacyInfo.xcprivacy` (no tracking, Crashlytics data,
      `UserDefaults` reason CA92.1); Firebase's own manifests are in its bundles.

### 2026-10-31
- [x] Tip jar: four consumable tips (StoreKit 2 behind `TipStore`, `Tips.storekit` for tests), a
      tip card in Settings, Disney-style fireworks with a haptic per burst after a tip. Created in
      App Store Connect on 2026-10-30 (`fastlane/tips.json`, `asc-tips` skill); the `tips` lane now
      also uploads the App Review screenshot.
- [x] Tips in the just-emptied Trash: right after "Empty" deletes photos, the empty Trash shows
      what was freed and the tip chips inline; gone on the next visit.
- [x] Settings: the version is a pinned capsule above the tab bar; tap or long-press copies it.

### 2026-10-30
- [x] Firebase Crashlytics (crash reports only, no Analytics); dSYMs upload on device builds.
- [x] Final bundle ID `app.mediant` (tests `app.mediant.tests`), signed with team `NDCC8HH7D8`
      (Angelina Odegova, paid individual team; development profiles last a year).
- [x] Settings tab: English / Русский switch, progress reset, version; all texts in Russian.
- [x] Trash reminder: one local notification 2 h after leaving a full Trash (30 s in Debug), tap
      opens the Trash, never twice for the same Trash; On / Off in Settings.

### 2026-10-29
- [x] App icon in light, dark and tinted variants.
- [x] Splash: the launch ✨ flies from the icon art into the Albums title.
- [x] Album sizes are cached and shimmer until they are measured again.
- [x] Swipe screen: every photo shows whole; card-stack drag with a soft sparkle fade-out; drag
      the preview strip to scroll it; tap the photo to skip it.
- [x] Video (part of "Working with video"): looping playback on the top card, tap the time chip
      to pause/play, drag it to scrub, 🔊/🔇 chip (sound plays on silent, volume up turns it on),
      ▶ badge in the album grid.
- [x] Album order: Recents, Favorites, Recently Added, Videos, Screenshots, Selfies first.
- [x] Swipe between Albums and Trash.
- [x] 👹 Trash counter next to Undo in the bottom row; Undo uses the `arrow.uturn.backward` symbol.
- [x] The 👹 chip opens the Trash and coming back returns to the same photo with its Undo.
- [x] Empty Trash reminds to clear Recently Deleted in Photos ("Open Photos" chip).
- [x] Per-item size on the swipe screen for every photo (it was already there; idea removed).
