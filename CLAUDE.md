# Median't

Free, Tinder-style photo cleaner for iOS: swipe **up to delete**, **down to keep**. No ads,
no subscription, no paywall, nothing locked behind a payment — ever. Optional tips that unlock
nothing are allowed. SwiftUI, iOS 17+, iPhone only, portrait, dark-first.
Display name is **Median't**; everything code-facing (folders, targets, module, scheme) is
`Mediant` because the apostrophe breaks paths.

Design (the "project map"): `docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md`.
Mockups from the brainstorm: `docs/superpowers/mockups/` (open in a browser).
Ideas backlog: `TODO.md` — add new ideas there; tick or remove items when they ship. Commit
`TODO.md` right after each edit (its own `docs:` commit, not mixed into code changes).

## Code map

| Folder | What lives there |
|---|---|
| `Mediant/Model/` | Pure logic, unit-tested: `visibleAssets` (album filter: no 👹, 💖 only when "Don't show 💖" is off), `orderedAlbums` (Recents, then Favorites, Recently Added, Videos, Screenshots, Selfies, then A–Z), `TabSwipe` (which tab a swipe leads to), `SwipeGesture` (what a drag on the swipe screen means: trash / keep / next / previous), `TipJar` (loads the four tips through `TipStore`, buys one at a time, the thank-you / failure message and the "celebration" event for the fireworks), `TipSize` (the four fixed product IDs, `TipProduct`, `TipPurchaseResult`), `FireworksPlan` (the seeded fireworks show per tip size, in fractions of the screen width), `AppLanguage` (English / Russian, saved or from the phone), `TrashReminder` (one local reminder for a forgotten Trash: schedule on leaving, cancel on return, never twice for the same Trash), `DecisionStore` (kept/trashed per photo id, JSON in Application Support), `CleanupStats` (all-time deleted count + freed bytes, `stats.json`; reset from Settings), `SwipeSession` (current index + undo stack; after the last photo it goes on with the unsorted ones, `upcomingIndex`), `ByteFormat` / `counted()`, `VideoTime` (time text, scrub math) |
| `Mediant/Library/` | `PhotoLibrary` protocol + `PhotoKitLibrary`; `NotificationCenterClient` protocol + `SystemNotifications` (UserNotifications, tap → Trash); `AlbumSizes` (background size sums, cached in `album-sizes.json`; a cached size shimmers until it is measured again); `ThumbnailLoader` (PHCachingImageManager); `TipStore` protocol + `StoreKitTipStore` (StoreKit 2) + `DemoTipStore` (Debug only: `-fakeTips usd|kzt|idr|fail|none`) |
| `Mediant/App/` | `AppModel` (owns everything, reloads on library changes), `RootView` (both tabs stay alive and slide; edge swipe), `FloatingTabBar` (tap or swipe), `AccessView`, `LaunchScreen.storyboard` (the `LaunchArt` image, aspect-fill), `CrashReporting` (starts Firebase Crashlytics; off in unit tests), `GoogleService-Info.plist` (Firebase project `mediant-ba64c`) |
| `Mediant/Splash/` | `LaunchArt` (launch picture geometry in screen points, unit-tested), `SplashView` (launch ✨ flies into the title), `TitleSparkle` (the drawn ✨ cluster in the Albums / access titles, the landing spot) |
| `Mediant/Albums/`, `Album/` | Albums list (main page) with the `ProgressCard` (space freed / items deleted), and the album grid |
| `Mediant/Swipe/` | Swipe screen: `SwipeView` (card-stack drag: top card moves up = 👹 / down = 💖, next waits behind; left / right = next / previous photo, no decision), `PreviewStrip` (💖/👹 + ogre pop, drag to scroll), `SparkleEdge`/`SparkleShape` (✨ edges), `PhotoPage` (photo or video card), `LoopingVideo` (shows the top card's video), `VideoPlayback` (the one looping player: time, pause, mute, scrub), `VideoChip` (time chip: tap = pause/play, drag = scrub) |
| `Mediant/Trash/` | `TrashModel` (one-batch delete, restore, `justEmptied`: what the last delete freed, ended by `AppModel` when the user leaves the tab or the app goes to the background) and `TrashView` (the just-emptied state shows the freed size and the pink tip chips) |
| `Mediant/Settings/` | `SettingsView` (third tab: language chips, Trash reminder on/off, `TipCard`, progress reset, Privacy card, Instagram card ("Dev's Instagram 💅🏻", @axyelina), Version card), `PrivacyPolicyView` (the privacy policy sheet: what the app never collects, then crash reports and tips), `TipCard` (the icon-art card with the tip buttons), `VersionRow` (the Version card: version line and a Copy chip) |
| `Mediant/Tips/` | `TipButtons` (the four tip buttons for Settings and the Trash: row, 2 × 2 or column; Reduce Motion glow), `FireworksView` (the show after a tip, over the whole app from `RootView`: draws `FireworksPlan` in a `Canvas`, a haptic at each burst, nothing with Reduce Motion) |
| `Mediant/PrivacyInfo.xcprivacy` | The app's privacy manifest: no tracking; collects only Crashlytics crash + diagnostic data (not linked, app functionality); `UserDefaults` with reason `CA92.1` |
| `Mediant/Localizable.xcstrings`, `InfoPlist.xcstrings` | All UI texts, English + Russian (plural forms) |
| `Mediant/Shared/` | `Chip` (the glass capsule button), `.glassBackground(in:)` + `GlassGroup` (Liquid Glass on iOS 26+, thin material before; for controls only, cards keep their material), `AssetImage`, `.shimmering(_:)` (a value that is not final yet) |
| `MediantTests/` | Swift Testing; `FakePhotoLibrary` stands in for PhotoKit, `FakeTipStore` for the tip store; `Tips.storekit` (the four tips) is the StoreKit test file for `StoreKitTipStoreTests` and the `Mediant` scheme |
| `Design/AppIcon/` | App icon sources: `light.svg` (✨ on the delete/keep diagonal split), `dark.svg`, `tinted.svg`; launch screen sources `launch-light.svg` / `launch-dark.svg` (the icon art in a 100×220 canvas). `Design/Tips/tip-*.svg`: the 4 tip images (more ✨ for a bigger tip, same art). Edit the SVG, then `swift Design/AppIcon/render.swift` from the repo root writes the PNGs into `AppIcon.appiconset`, `LaunchArt.imageset` and `fastlane/tips/` |
| `Design/AppStore/` | App Store screenshots: `en/` and `ru/` finals (6.9" 1320 × 2868, 6.3" 1206 × 2622), `screens/<lang>/` raw simulator captures, `src/screenshots.html` (captions, wine banner, sparkles, thumb-swipe hint) and `src/render.sh` (headless Chrome). How they were made and how to upload: its `README.md` |
| `fastlane/` | App Store Connect automation: `tips.json` (the tip in-app purchases), `asc.rb` (direct App Store Connect API calls — Spaceship has no in-app purchase models), `Fastfile` (`tips` lane; `beta` uploads to TestFlight, `bump_build`, `set_version`), `versioning.rb` (version / build number in `project.yml`, tested by `test/versioning_test.rb`), `tips/` (rendered tip images, 1024×1024, uploaded by the lane as promotional images). `Gemfile` pins fastlane |

## Rules

- **PhotoKit stays behind `PhotoLibrary`.** Logic takes the protocol, so it is tested with
  `FakePhotoLibrary`. Only `PhotoKitLibrary` and `ThumbnailLoader` import Photos
  (`ThumbnailLoader.playerItem(for:)` loads videos). Likewise only `SystemNotifications` imports
  UserNotifications; logic takes `NotificationCenterClient` and is tested with a fake.
- **StoreKit stays behind `TipStore`.** Only `StoreKitTipStore` imports StoreKit; logic (`TipJar`)
  takes the protocol and is tested with `FakeTipStore`. The real store is tested with `Tips.storekit` and
  `SKTestSession`. Prices are always `Product.displayPrice`, never formatted or hard-coded. A tip
  unlocks nothing; never the word "donate"; no popup, badge or reminder for tips.
- **Firebase is crash reports only.** Only `CrashReporting` imports Firebase. Link only the
  `FirebaseCrashlytics` product — never `FirebaseAnalytics` or anything that tracks users (design
  anti-goal). Firebase is on 12.19.x; 13.x needs Xcode 26 — move to it only on a Mac with Xcode
  26+, as its own change. The `Upload dSYM to Crashlytics` build phase runs only for signed device
  builds (it skips the simulator and `CODE_SIGNING_ALLOWED=NO`).
- **The privacy policy tells the truth about the code.** `PrivacyPolicyView` lists everything
  that leaves the phone (Crashlytics crash reports, App Store tips, iCloud downloads by iOS). A new
  SDK, server, network call or stored file means a new or changed paragraph there (both languages)
  and a new "Last updated" date. Update `PrivacyInfo.xcprivacy` in the same change: collected
  data types, and a reason for every required-reason API (file timestamps, disk space, system
  boot time, `UserDefaults`, …) the app code starts to use.
- **Deleting is only `TrashModel.emptyTrash()`** → one iOS dialog for the whole Trash. Never add an
  app-made confirmation on top, never delete per swipe. The UI calls it through
  `AppModel.emptyTrash()`, which also closes a swipe screen whose photos may be gone.
- **Compact UI in thumb reach.** Controls are small glass `Chip`s, primary actions at the bottom.
- An image that fills its frame overflows it, and `.clipped()` does not stop the overflow from
  taking taps. `AssetImage` already turns off hit testing on the image; keep a
  `.contentShape(Rectangle())` on tappable cells.
- The preview strip has **no ScrollView**: `PreviewStrip.centers(around:in:)` calculates every tile
  position from the current photo and one animation moves them. A scroll view animating to a
  target while tiles resize made the strip jump — do not go back to `scrollPosition`.
- **Icon → launch screen → splash → title ✨ is one picture.** `SplashView` draws the launch art
  in code and must match `launch-*.svg` exactly on its first frame (`LaunchArt` holds the shared
  geometry, `SplashView.Palette` the colors). Change the icon art in all three places. The title ✨
  is a drawn `SparkleShape(cluster: true)`, not the emoji. The splash waits 0.4 s before it moves:
  iOS is still fading the static launch screen out, and moving earlier leaves a ghost ✨.
- **Every UI text goes into `Localizable.xcstrings` with a Russian translation.** Pass texts as
  literals or `LocalizedStringKey` (a `String` variable or a ternary of strings is not translated);
  counts go in as `"\(count) items"` with plural forms in the catalog, sizes through
  `ByteFormat.string(_, locale:)` with the environment `locale`. `RootView` sets that locale from
  `AppModel.language`. System-supplied buttons (e.g. a dialog's Cancel) follow the phone, so add
  your own. Plural forms without the number need a substitution (`%#@name@`) in the catalog.
- `project.yml` is the source of truth (XcodeGen). After adding/removing files run
  `xcodegen generate`. Never hand-edit the `.xcodeproj`.
- TDD for anything in `Model/`, `Library/` logic and view models.

## Simulator — HARD RULE

Use only the dedicated simulator **`Median't iPhone 16`** (iPhone 16, iOS 18.4) for building,
running and testing. Never target another simulator, even if one is already booted or attached.
It is kept in **dark appearance**. Use the `run-sim` skill (`.claude/skills/run-sim/`).
`run.sh` creates the simulator when it is missing (another Mac). If that Mac has no iOS 18.4
runtime, ask the user before you install one or use another runtime — never just pick a
different simulator. A UI check on iOS 26+ (Liquid Glass look of system sheets and dialogs) is a
separate, explicit task.

## Build, test, sample photos

```bash
.claude/skills/run-sim/scripts/run.sh          # build, install, launch on the dedicated sim
.claude/skills/run-sim/scripts/run.sh --test   # unit tests (replaces the running app!)
.claude/skills/run-sim/scripts/seed-photos.sh  # add 40 generated sample photos + 4 videos (once per sim)
.claude/skills/run-sim/scripts/seed-photos.sh --videos  # add only the 4 sample videos
```

Real iPhone (the user's phone `LINK`): `.claude/skills/run-device/scripts/run-device.sh` — see the
`run-device` skill. Signing uses the paid individual team `NDCC8HH7D8`
(Angelina Odegova); development profiles last a year. Bundle ID: `app.mediant` (tests `app.mediant.tests`).

TestFlight: `bundle exec fastlane beta` archives, uploads, then raises the build number and commits
— see the `testflight` skill. Change the version and build number only with the lanes
(`set_version version:1.1` puts the build number back to 1), never by hand in Xcode. Push the
build-number commit after a successful upload, so every Mac starts from the next free number.

Tip in-app purchases in App Store Connect: `fastlane/tips.json` is the source of truth,
`bundle exec fastlane tips [dry_run:true]` applies it — see the `asc-tips` skill. The API key lives
in `~/.appstoreconnect/private_keys/` and `fastlane/.env` (gitignored); never read or commit it.

## Toolchain and release state

- **Uploads need the iOS 26 SDK (Xcode 26 or later).** App Store Connect refused the first upload
  (2026-11-10, build 1.0 (1)) because it was built with Xcode 16.3 / iOS 18.4 SDK. A Mac with an
  older Xcode can still build, test and run on the phone, but not upload. Xcode 26.3 needs macOS
  15.6+, Xcode 27 needs macOS 26.6+ and Apple silicon. `SWIFT_VERSION` stays `5.0`. Xcode 27.2
  (iOS 27.2 SDK) builds the app with 0 warnings and Firebase 12.19.x (checked 2026-11-10 on the
  phone `LINK`, iOS 27.0.1).
- **App Store Connect:** app record "Median't" (SKU `app.mediant`, primary language en-US) and
  the 4 tip in-app purchases exist. First accepted build: 1.0 (1), uploaded with `fastlane beta`
  from Xcode 27.2 on 2026-11-10, processing `VALID`, export compliance answered by the plist.
  Latest build: 1.0 (2), uploaded the same way on 2026-11-17, processing `VALID`; `project.yml`
  now has build number 3 (the next upload). Not yet: TestFlight groups, TestFlight Test Information, privacy policy URL, App Store listing. Open items are in `TODO.md`
  ("Before the first release").
- **App Store Connect API key** (`fastlane/.env` → `.p8` in `~/.appstoreconnect/private_keys/`):
  App Manager role. It uploads builds and manages the tips; it cannot be relied on to create
  certificates. To read App Store Connect state, reuse `MediantASC::Client` from `fastlane/asc.rb`
  in a `bundle exec ruby` script that loads `fastlane/.env` with Dotenv (print only what you
  need, never the key).
- **Signing:** team `NDCC8HH7D8`, automatic signing. Apple Distribution certificate "Angelina
  Odegova" valid until 2027-11-09; its private key is only in the keychain of the Mac that made
  it. On another Mac, sign in to Xcode › Settings › Accounts with an Admin / Account Holder Apple ID
  and let `-allowProvisioningUpdates` create that Mac's own certificate, or import a `.p12`
  export from the first Mac. The App Store profile ("iOS Team Store Provisioning Profile:
  app.mediant") is managed by Xcode.
- **Export compliance:** `ITSAppUsesNonExemptEncryption = NO` (only standard HTTPS).
- **Firebase / Crashlytics:** project `mediant-ba64c`, iOS app ID
  `1:148272214498:ios:0e5313407624f1dee3c9bb`. The Crashlytics MCP tools need a valid Firebase CLI
  login (`firebase login --reauth`, done by the user). Not yet verified: a crash arriving in the
  console from a real device.

## Paths and simulator notes

DerivedData and Swift packages go to `./build/` (gitignored); the scripts pass
`-clonedSourcePackagesDirPath build/SourcePackages` because Xcode on this Mac shares one package
folder between projects (`IDEClonedSourcePackagesDirPathOverride`). `simctl privacy grant photos` does not work on
iOS 18.4 here: accept the app's permission dialog in the simulator instead. The Trash reminder
fires 30 s after leaving the app in Debug builds; the simulator ignores injected taps on
notification banners, so check "tap opens the Trash" on the phone.

## Git

Remote: `origin` = `git@github.com:axyelina/mediant.git` (private, branch `master`). Commits go
out as `axyelina <axyelina@gmail.com>`, set repo-locally (`git config --local user.*`) — use it,
never change it. Git in this repo talks to GitHub with its own SSH key through the repo-local
`core.sshCommand` (see `CLAUDE.local.md`); do not switch the remote to HTTPS or to `gh` auth,
which is logged in as a different account.

## Chat language

Write all chat replies in this project in **ASD-STE100 Simplified Technical English**: approved
words, one meaning per word, short sentences (procedures max 20 words, descriptions max 25),
active voice, one instruction per sentence, imperative for steps, vertical lists for sequences.
This rule applies to chat replies only, not to code, comments or docs, and only in this project.

## Maintenance

Keep this file and the project skills in `.claude/skills/` up to date as the project evolves:
when a workflow, convention or rule changes or is added, update them in the same change. When a
repeated multi-step workflow appears, capture it as a new skill.
