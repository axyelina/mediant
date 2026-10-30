# Tips in Settings and the just-emptied Trash — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Four consumable StoreKit tips in a Settings card and in the just-emptied Trash, with Disney-style fireworks and a haptic per burst after a tip, and a pinned, copyable version line in Settings.

**Architecture:** StoreKit stays behind a `TipStore` protocol (only `StoreKitTipStore` imports StoreKit). One `@Observable` `TipJar` owned by `AppModel` holds the products, the one in-progress purchase, the short "thank you / failed" message and the "celebration" event; both tip places render the shared `TipButtons` view from it. A pure, seeded `FireworksPlan` decides every rocket; a full-screen `FireworksView` overlay in `RootView` only draws the plan over time and fires the haptics.

**Tech Stack:** Swift 5, SwiftUI, iOS 17, StoreKit 2, StoreKitTest (`SKTestSession`, tests only), Swift Testing, XcodeGen, fastlane (Ruby).

**Spec:** `docs/superpowers/specs/2026-10-31-settings-tips-design.md` (approved 2026-10-31). Mockups `docs/superpowers/mockups/04`–`07` (07 is the live fireworks prototype — match its look).

## Global Constraints

- iOS 17.0 deployment target, iPhone only, portrait. No new third-party dependency.
- Product IDs, fixed forever: `app.mediant.tip.small`, `app.mediant.tip.medium`, `app.mediant.tip.large`, `app.mediant.tip.huge` (consumable).
- Only `Mediant/Library/StoreKitTipStore.swift` imports StoreKit; tests may import StoreKitTest.
- Prices are always `Product.displayPrice`; the app never formats or translates a price.
- Every UI text goes into `Mediant/Localizable.xcstrings` with Russian (`CLAUDE.md` rules: literals or `LocalizedStringKey`; counts as `"\(count) …"` with plural forms; sizes through `ByteFormat.string(_, locale:)` with the environment `locale`).
- Never the word "donate". A tip unlocks nothing. No popup, sheet, badge or reminder for tips.
- Haptics through `.sensoryFeedback`.
- Build/test only on the dedicated simulator via `.claude/skills/run-sim/scripts/run.sh` (`--test` for unit tests). After adding/removing files: `xcodegen generate`.
- Commits: conventional prefixes as in `git log` (`feat:`, `test:`, `build:`, `docs:`), identity is the repo-local `axyelina` config, end every message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. `TODO.md` edits get their own `docs:` commit.

## Review Focus

1. **Double tap on a price** (or tapping in Settings while a Trash tip is in progress) → exactly one purchase sheet; the second tap is ignored. Test in Task 2.
2. **The App Store returns fewer, more or unknown products** → only the four known IDs are shown, sorted by price; none known → "not available" (Settings) / hidden (Trash). Test in Task 1.
3. **Very large Dynamic Type** → even 2 × 2 does not fit; the buttons fall back to one column instead of cutting a price. Third `ViewThatFits` option in Task 5, checked on the simulator with the largest accessibility size.
4. **The user leaves the place before the purchase ends** (switches tab while the sheet is up) → fireworks still run once; the message belongs to the place that was tapped and is not shown in the other place. Test in Task 2.
5. **A delete where no file size is known** → the Trash shows "Done!" and the count without a "freed" line, never "— freed". Test in Task 7.

---

### Task 1: Tip products, the store protocol, and loading in `TipJar`

**Files:**
- Create: `Mediant/Model/TipSize.swift`, `Mediant/Library/TipStore.swift`, `Mediant/Model/TipJar.swift`
- Test: `MediantTests/TipJarTests.swift`, `MediantTests/FakeTipStore.swift`

**Interfaces:**
- Produces:
  - `enum TipSize: String, CaseIterable, Sendable { case small, medium, large, huge }` with `var productID: String` (`"app.mediant.tip.\(rawValue)"`) and `init?(productID: String)`.
  - `struct TipProduct: Equatable, Sendable { let id: String; let displayPrice: String; let price: Decimal }` with `var size: TipSize?`.
  - `enum TipPurchaseResult: Equatable, Sendable { case success, cancelled, pending, failed }` (an unverified transaction is `failed`).
  - `protocol TipStore: Sendable { func products(for ids: [String]) async throws -> [TipProduct]; func purchase(_ id: String) async -> TipPurchaseResult; func finishUpdates() async }` — `finishUpdates()` runs until cancelled, finishing every tip transaction from `Transaction.updates` silently.
  - `@MainActor @Observable final class TipJar` with `init(store: TipStore, messageDuration: Duration = .seconds(3))`, `enum Load: Equatable { case loading, loaded([TipProduct]), unavailable }`, `private(set) var load: Load = .loading`, `func loadIfNeeded() async`.
  - Test fake `FakeTipStore` (`@unchecked Sendable` class): settable `products: [TipProduct]`, `loadError: Error?`, `result: TipPurchaseResult`, `var purchases: [String]`, `var loadCalls: Int`, and `var hold: Bool` — when true, `purchase` suspends until `release()` is called (for "in progress" tests).

- [ ] **Step 1: Write the failing tests** in `TipJarTests` (`@MainActor struct`, `import Testing`):
  - `loadsKnownProductsSortedByPrice` — fake returns huge ($9.99), small ($0.99), an unknown `"app.mediant.other"` ($1.99), large ($4.99) → `load == .loaded([small, large, huge])`.
  - `noKnownProductsIsUnavailable` — fake returns only the unknown product → `.unavailable`.
  - `loadErrorIsUnavailableAndRetries` — first call throws → `.unavailable`; clear the error, call again → `.loaded(...)` and `loadCalls == 2`.
  - `loadedDoesNotReload` — two calls after success → `loadCalls == 1`.
  - `sizeFromProductID` — `TipSize(productID: "app.mediant.tip.huge") == .huge`, `TipSize(productID: "x") == nil`.
- [ ] **Step 2: Run** `.claude/skills/run-sim/scripts/run.sh --test` (after `xcodegen generate`). Expected: build fails, `TipJar` / `TipSize` not found.
- [ ] **Step 3: Implement** `TipSize`, `TipProduct`, `TipPurchaseResult`, `TipStore` and `TipJar.loadIfNeeded()`: ask the store for `TipSize.allCases.map(\.productID)`, keep known sizes, sort by `price`; throw or empty → `.unavailable`; skip when already `.loaded`; a call while unavailable retries (sets `.loading` first).
- [ ] **Step 4: Run** `run.sh --test`. Expected: all tests pass.
- [ ] **Step 5: Commit** — `feat: TipJar loads the four tips through a TipStore protocol`.

### Task 2: Buying in `TipJar` — one purchase, message per place, celebration

**Files:**
- Modify: `Mediant/Model/TipJar.swift`
- Test: `MediantTests/TipJarTests.swift`

**Interfaces:**
- Consumes: Task 1.
- Produces, on `TipJar`:
  - `enum Place: Equatable, Sendable { case settings, trash }`
  - `struct Purchase: Equatable { let productID: String; let place: Place }` and `private(set) var purchasing: Purchase?`
  - `struct Message: Equatable { enum Kind { case thanks, failed }; let kind: Kind; let place: Place }` and `private(set) var message: Message?` (cleared after `messageDuration`)
  - `struct Celebration: Equatable, Identifiable { let id: Int; let size: TipSize; let place: Place }` and `private(set) var celebration: Celebration?` (`id` increments on every success; never cleared by `TipJar` — the overlay plays each new id once)
  - `func buy(_ product: TipProduct, from place: Place) async`
  - `func finishUpdates() async` (forwards to the store)

- [ ] **Step 1: Write the failing tests:**
  - `successCelebratesAndThanksThePlace` — buy medium from `.trash` with result `.success` → `celebration == Celebration(id: 1, size: .medium, place: .trash)`, `message == Message(kind: .thanks, place: .trash)`, `purchasing == nil`.
  - `cancelledDoesNothing` — `.cancelled` → `celebration == nil`, `message == nil`.
  - `pendingDoesNothing` — `.pending` → same as cancelled.
  - `failedShowsFailedNoCelebration` — `.failed` from `.settings` → `message == Message(kind: .failed, place: .settings)`, `celebration == nil`.
  - `secondTapWhileBuyingIsIgnored` (Review Focus 1) — `hold = true`, start `buy(small, .settings)` in a `Task`, then `await buy(large, .trash)` → `fake.purchases == ["app.mediant.tip.small"]`, `purchasing == Purchase(productID: "app.mediant.tip.small", place: .settings)`; `release()`, await the first task → `purchasing == nil`.
  - `messageStaysWithItsPlace` (Review Focus 4) — success from `.settings` → `message?.place == .settings` (the Trash view only shows messages whose place is `.trash`); `celebration` is set regardless of place.
  - `celebrationIdGrowsEachTip` — two successes → ids 1 then 2.
  - `messageClearsAfterDuration` — `TipJar(store:, messageDuration: .milliseconds(50))`, success, sleep 150 ms → `message == nil`.
- [ ] **Step 2: Run** `run.sh --test`. Expected: compile errors for `buy`, `Place`, etc.
- [ ] **Step 3: Implement** `buy`: return if `purchasing != nil`; set `purchasing`; await the store; clear `purchasing`; map the result; schedule the message clear with a stored `Task` that is cancelled when a newer message arrives.
- [ ] **Step 4: Run** `run.sh --test`. Expected: pass.
- [ ] **Step 5: Commit** — `feat: TipJar buys one tip at a time and celebrates a success`.

### Task 3: StoreKit behind the protocol, the `.storekit` file, wiring into the app

**Files:**
- Create: `Mediant/Library/StoreKitTipStore.swift`, `MediantTests/Tips.storekit`, `MediantTests/StoreKitTipStoreTests.swift`
- Modify: `project.yml` (test target resources include `Tips.storekit`; scheme `run: storeKitConfiguration: MediantTests/Tips.storekit`), `Mediant/App/AppModel.swift` (new `let tips: TipJar`, init parameter `tipStore: TipStore = StoreKitTipStore()`), `Mediant/MediantApp.swift` (`.task { await model.tips.finishUpdates() }`)

**Interfaces:**
- Consumes: `TipStore`, `TipProduct`, `TipPurchaseResult` (Task 1).
- Produces: `struct StoreKitTipStore: TipStore` (`init()` does no StoreKit work); `AppModel.tips: TipJar`.

- [ ] **Step 1: Create `MediantTests/Tips.storekit`** — StoreKit configuration JSON (`"version": {"major": 4, "minor": 0}`, storefront `USA`, locale `en_US`) with four `"type": "Consumable"` products: IDs from Global Constraints, `displayPrice` `0.99` / `2.99` / `4.99` / `9.99`, `referenceName` and `en_US` localization `displayName` / `description` copied from `fastlane/tips.json`, `familyShareable: false`, unique `internalID`s. Easiest: create it in Xcode (File › New › StoreKit Configuration File) and fill these values, then check the JSON matches.
- [ ] **Step 2: Write the failing tests** in `StoreKitTipStoreTests` (`import StoreKitTest`; each test creates `try SKTestSession(configurationFileNamed: "Tips")`, sets `disableDialogs = true`, `clearTransactions()`):
  - `loadsFourProducts` — `products(for:)` with the four IDs → 4 products, small has `price == 0.99`.
  - `purchaseSucceeds` → `.success`, and afterwards `session.allTransactions()` has one finished transaction for the small tip.
  - `purchaseFails` — `session.setSimulatedError(.generic(.unknown), forAPI: .purchase)` → `.failed`.
  - `askToBuyIsPending` — `session.askToBuyEnabled = true` → `.pending`.
  - (Cancel cannot be simulated with dialogs off; it is checked by hand on the simulator in Task 8.)
- [ ] **Step 3: Run** `xcodegen generate && run.sh --test`. Expected: fails, `StoreKitTipStore` missing.
- [ ] **Step 4: Implement** `StoreKitTipStore`: `Product.products(for:)` → `TipProduct(id:, displayPrice:, price:)`; `purchase` finds the product, calls `purchase()`, maps `.success(.verified)` → finish + `.success`, `.success(.unverified)` → `.failed` (do not finish), `.userCancelled` → `.cancelled`, `.pending` → `.pending`, thrown error → `.failed`; `finishUpdates()` loops `for await update in Transaction.updates` and finishes verified tip transactions. Wire into `AppModel` and `MediantApp`.
- [ ] **Step 5: Run** `run.sh --test`. Expected: all pass (existing `AppModelTests` still pass with the default store).
- [ ] **Step 6: Commit** — `feat: StoreKitTipStore, the Tips.storekit test file and AppModel.tips`.

### Task 4: `FireworksPlan` — the seeded, tested show

**Files:**
- Create: `Mediant/Model/FireworksPlan.swift`
- Test: `MediantTests/FireworksPlanTests.swift`

**Interfaces:**
- Consumes: `TipSize`.
- Produces:
  - `struct FireworksPlan: Equatable { struct Rocket: Equatable { let launch: TimeInterval; let flight: TimeInterval; let start: CGPoint; let burst: CGPoint; let bend: CGFloat; let radius: CGFloat; let pair: Int; let isFinale: Bool; var burstTime: TimeInterval { launch + flight } }; let rockets: [Rocket]; static let burstLife: TimeInterval = 1.5; var duration: TimeInterval; init(size: TipSize, canvas: CGSize, seed: UInt64) }`
  - `struct SeededGenerator: RandomNumberGenerator` (SplitMix64) in the same file.

Values from the spec: rockets per size 1 / 2 / 3 / 5, plus a finale for huge; launch `i × 0.38` s; flight 0.75–0.95 s; start x 30–70 % of width at y = height + 10; burst y 20–45 % of height, but never closer than `radius + 8` to the top; radius 190–220 (single rocket), 130–175 (several), finale 250 at the center x, y = 36 % of height, launched 0.35 s after the last rocket; burst x in `radius + 10 … width − radius − 10`; `bend` −90…90; `pair` = rocket index (the view takes it modulo its palette count); `duration` = last `burstTime + burstLife`.

- [ ] **Step 1: Write the failing tests:**
  - `rocketCountPerSize` — small 1, medium 2, large 3, huge 6 with only the last `isFinale`.
  - `launchesAreSpaced` — large: launches `[0, 0.38, 0.76]` (± 0.001).
  - `burstsStayOnScreen` — for every size, seeds 1…50, canvases 393×852 and 375×667: `burst.x - radius >= 0`, `burst.x + radius <= width`, `burst.y - radius >= 0`, `burst.y <= 0.45 * height + 0.001`.
  - `sameSeedSamePlan` / `otherSeedOtherPlan`.
  - `hugeEndsInAboutFourSeconds` — `duration` between 3.5 and 4.5.
- [ ] **Step 2: Run** `run.sh --test`. Expected: compile error.
- [ ] **Step 3: Implement** `FireworksPlan.init` with the values above.
- [ ] **Step 4: Run** `run.sh --test`. Expected: pass.
- [ ] **Step 5: Commit** — `feat: FireworksPlan, the seeded fireworks show per tip size`.

### Task 5: Shared `TipButtons` and the Debug `-fakeTips` store

**Files:**
- Create: `Mediant/Tips/TipButtons.swift`, `Mediant/Library/DemoTipStore.swift` (whole file inside `#if DEBUG`)
- Modify: `Mediant/MediantApp.swift` (Debug: `AppModel(tipStore: DemoTipStore(launchArguments:) ?? StoreKitTipStore())`), `.claude/skills/run-sim/scripts/run.sh` (arguments after `--` go to `simctl launch`), `.claude/skills/run-sim/SKILL.md`, `Mediant/Localizable.xcstrings`

**Interfaces:**
- Consumes: `TipJar` (Tasks 1–2) through `@Environment(AppModel.self)`.
- Produces:
  - `struct TipButtons: View { enum Style { case glass, pink }; let place: TipJar.Place; let style: Style }` — loads with `.task { await tips.loadIfNeeded() }`.
  - `DemoTipStore.init?(launchArguments: [String])` — `nil` unless `-fakeTips <preset>` is present. Presets: `usd` ($0.99/$2.99/$4.99/$9.99), `kzt` (`499,00 ₸`, `1 790,00 ₸`, `2 990,00 ₸`, `5 990,00 ₸`), `idr` (`Rp 19.000,00` … `Rp 199.000,00`), `fail` (prices as usd, every purchase `.failed`), `none` (loading throws). Purchases succeed after 0.5 s unless `fail`.

Spec values: buttons ≥ 32 pt tall (`Chip` height), bold; `.glass` = white fill 14 %, white border 22 %; `.pink` = `#ff375f` fill 18 %, `#ff5c93` border 40 %, `#ffb3c4` text. `ViewThatFits`: one row of four equal buttons → 2 × 2 equal → one column (Review Focus 3); prices never shrink (`.fixedSize()` on the label, no `minimumScaleFactor`). Loading: four empty capsules `.shimmering(true)`. Purchasing: all disabled, the tapped one shows `ProgressView()`. Accessibility label `"Tip, \(displayPrice)"` ("Чаевые, %@"). Reduce Motion + a `celebration` for this `place`: a soft pink glow behind the buttons fading over 1 s and one `.impact` haptic.

- [ ] **Step 1: Implement** `DemoTipStore`, the launch-argument switch in `MediantApp`, and `TipButtons`. Add the strings to the catalog with Russian.
- [ ] **Step 2: Change `run.sh`** so `run.sh -- -fakeTips kzt` passes `-fakeTips kzt` to `xcrun simctl launch`; document it in the `run-sim` skill (`SKILL.md`): presets and what each is for.
- [ ] **Step 3: Build and run** `run.sh` (the view is not on a screen yet; this checks the build). Expected: "Launched app.mediant".
- [ ] **Step 4: Commit** — `feat: shared TipButtons (row, 2 × 2 or column) and the Debug -fakeTips store`.

### Task 6: Settings screen — new order, tip card, pinned copyable version

**Files:**
- Modify: `Mediant/Settings/SettingsView.swift`, `Mediant/Localizable.xcstrings`
- Create: `Mediant/Settings/TipCard.swift`, `Mediant/Settings/VersionPin.swift`
- Test: `MediantTests/VersionPinTests.swift`

**Interfaces:**
- Consumes: `TipButtons(place: .settings, style: .glass)`, `TipJar.message`, `TipJar.load`.
- Produces: `struct VersionPin: View` with `static func text(info: [String: Any]?) -> String`.

- [ ] **Step 1: Write the failing test** `textUsesDisplayNameVersionAndBuild` — `VersionPin.text(info: ["CFBundleDisplayName": "Median't", "CFBundleShortVersionString": "1.0", "CFBundleVersion": "12"]) == "Median't 1.0 (12)"`; `textWithoutInfo` — `text(info: nil) == "Median't ? (?)"`.
- [ ] **Step 2: Run** `run.sh --test`. Expected: compile error.
- [ ] **Step 3: Implement** `VersionPin` (glass capsule, secondary, monospaced digits; tap and long-press copy `text` to `UIPasteboard.general.string`, show "Copied" for 1 s, `.sensoryFeedback(.impact(weight: .light), …)`), `TipCard` (diagonal split `#470112` / `#75013d` along the line from 62 % of the top edge to 38 % of the bottom edge, 18 pt corners, 1 pt `#ff5c93` border at 35 %; title "Treat the developer ✨" ↔ "Thank you! ✨" when `message == Message(kind: .thanks, place: .settings)`; text in `#ffd1e3` at 85 % ↔ "The tip did not go through." on a failed message for `.settings`; `.unavailable` → "Tips are not available right now." instead of the buttons). Reorder `SettingsView`: Language, Trash reminder, `TipCard`, Progress; remove the Version card; overlay `VersionPin` at the bottom, 8 pt above `FloatingTabBar` (`.padding(.bottom, 8 + FloatingTabBar.height + 8)`), and raise the scroll content's bottom padding so Progress scrolls fully above it. All texts and their Russian from the spec into the catalog.
- [ ] **Step 4: Run** `run.sh --test`, then `run.sh -- -fakeTips usd` and `run.sh -- -fakeTips kzt`; open Settings, take simulator screenshots. Expected: one row (usd), 2 × 2 (kzt), version pinned and copied on tap, Russian texts after switching the language chip.
- [ ] **Step 5: Commit** — `feat: Settings tip card and the pinned, copyable version`.

### Task 7: The just-emptied Trash with inline tip chips

**Files:**
- Modify: `Mediant/Trash/TrashModel.swift`, `Mediant/App/AppModel.swift`, `Mediant/Trash/TrashView.swift`, `Mediant/Localizable.xcstrings`
- Test: `MediantTests/TrashModelTests.swift`, `MediantTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `TipButtons(place: .trash, style: .pink)`, `TipJar.message`, `TipJar.load`.
- Produces: `struct EmptiedTrash: Equatable { let count: Int; let bytes: Int64? }`, `TrashModel.justEmptied: EmptiedTrash?` (private(set)), `TrashModel.endJustEmptied()`.

- [ ] **Step 1: Write the failing tests:**
  - `TrashModelTests.successfulDeleteRemembersWhatWasFreed` — sizes a = 100, b = 50 in the fake → `justEmptied == EmptiedTrash(count: 2, bytes: 150)`.
  - `deleteWithoutSizesHasNoBytes` (Review Focus 5) — no sizes → `EmptiedTrash(count: 2, bytes: nil)`.
  - `declinedOrFailedDeleteIsNotJustEmptied` — `justEmptied == nil` in both cases.
  - `endJustEmptiedClears`.
  - `AppModelTests.leavingTrashEndsJustEmptied` — after a delete with `tab = .trash`, set `tab = .albums` → `trash.justEmptied == nil`.
  - `backgroundEndsJustEmptied` — `sceneChanged(to: .background)` → `nil`.
- [ ] **Step 2: Run** `run.sh --test`. Expected: compile errors.
- [ ] **Step 3: Implement** the model parts (sum of known sizes; `nil` when none known); `AppModel.tab` `didSet` ends it when leaving `.trash`; `sceneChanged(to: .background)` ends it. (New photos can only be trashed from the Albums tab, so leaving the tab covers "new photos land in the Trash".)
- [ ] **Step 4: Implement the view** — in `TrashView.empty`, when `trash.justEmptied` is set: `SparkleShape(cluster: true)` in pink tones in place of 👹; "Done!"; `"\(ByteFormat.string(bytes, locale: locale)) freed"` with the `#ffd1e3` → `#ff5c93` gradient, left out when `bytes == nil`; `"\(count) photos deleted"` (plural forms); the existing hint and "Open Photos"; a thin divider; the line "Liked it? Treat the developer ✨" (↔ "Thank you! ✨" / the failed line for `.trash` messages) in `#ffd1e3`; `TipButtons(place: .trash, style: .pink)`. Hide the line and the buttons when `tips.load == .unavailable`. Strings + Russian from the spec.
- [ ] **Step 5: Run** `run.sh --test`; then `seed-photos.sh` (if the sim has no sample photos), `run.sh -- -fakeTips usd`, trash a few photos, Empty, allow → screenshot; switch tabs and back → normal empty Trash.
- [ ] **Step 6: Commit** — `feat: the just-emptied Trash shows what was freed and the tip chips`.

### Task 8: Fireworks overlay and haptics

**Files:**
- Create: `Mediant/Tips/FireworksView.swift`
- Modify: `Mediant/App/RootView.swift` (overlay above the tab bar)

**Interfaces:**
- Consumes: `TipJar.celebration` (Task 2), `FireworksPlan` (Task 4).
- Produces: `struct FireworksView: View` (no parameters; reads the model from the environment).

Look and numbers: `docs/superpowers/mockups/07-fireworks.html` look A and the spec's "Fireworks" section — tapered two-color streaks (48, finale 72) that start near the center and whose inner ends move outward, flickering rim dots, a 16-point star flash fading in 0.6 s, 7 (finale 12) twinkling `SparkleShape` ✨, droop and fade over `FireworksPlan.burstLife`, curved tapered trail with a ✨ head. Dark palette pairs: (`#ff5c93`, `#ffd1e3`), (`#c2184e`, white), (`#ffd1e3`, `#ff5c93`), (white, `#c2184e`); trail `#ffd1e3`; star and ✨ white; additive blending and glow. Light palette (`colorScheme == .light`): (`#c2184e`, `#ff5c93`), (`#470112`, `#ff5c93`), (`#ff5c93`, `#75013d`); trail and star `#c2184e`; no glow, normal blending.

- [ ] **Step 1: Implement** `FireworksView`: on each new `celebration.id` (and Reduce Motion off) build `FireworksPlan(size:, canvas: proxy.size, seed: random)`, draw it with `TimelineView(.animation)` + `Canvas` until `plan.duration`, then draw nothing; `.allowsHitTesting(false)`, `.ignoresSafeArea()`. Haptics: a `Task` sleeps until each `rocket.burstTime` and bumps a counter used by `.sensoryFeedback(.impact(weight: .medium), trigger:)`; the finale uses `.impact(weight: .heavy)`. Add it in `RootView` above `FloatingTabBar`.
- [ ] **Step 2: Run** `run.sh -- -fakeTips usd`; tap each tip in Settings and in the just-emptied Trash; record with `xcrun simctl io <udid> recordVideo` for a few seconds and look at frames. Expected: the show matches the prototype, stays on screen, the app stays tappable. Repeat in light appearance (`xcrun simctl ui <udid> appearance light`, then back to dark) and with Reduce Motion (`Settings › Accessibility › Motion` on the sim) → glow, no rockets.
- [ ] **Step 3: Run** `run.sh -- -fakeTips fail` → no fireworks, the failed line for 3 s. `run.sh -- -fakeTips none` → Settings shows "Tips are not available right now.", the Trash shows no tips. Largest Dynamic Type (Review Focus 3) → buttons in one column, no cut prices.
- [ ] **Step 4: Run** `run.sh --test`. Expected: all pass.
- [ ] **Step 5: Commit** — `feat: Disney-style fireworks with a haptic per burst after a tip`.

### Task 9: App Review screenshots through the `tips` lane

**Files:**
- Modify: `fastlane/asc.rb` (`sync_review_screenshot`), `fastlane/tips.json` (`"review_screenshot": "tips/review-settings.png"` on each tip), `.claude/skills/asc-tips/SKILL.md`
- Create: `fastlane/tips/review-settings.png`

**Interfaces:**
- Consumes: the existing `MediantASC::Tips` sync and `Client#upload`.

API: `GET /v2/inAppPurchases/{id}/appStoreReviewScreenshot` (no data / 404 = none; attribute `sourceFileChecksum`), `DELETE /v1/inAppPurchaseAppStoreReviewScreenshots/{id}`, reserve with `POST /v1/inAppPurchaseAppStoreReviewScreenshots` (`fileName`, `fileSize`, relationship `inAppPurchaseV2`), upload the operations, then `PATCH` with `sourceFileChecksum` (MD5) and `uploaded: true` — the same pattern as `sync_image`.

- [ ] **Step 1: Take the screenshot** — `run.sh -- -fakeTips usd`, open Settings, `xcrun simctl io <udid> screenshot fastlane/tips/review-settings.png` (English, dark, the tip card fully visible).
- [ ] **Step 2: Implement** `sync_review_screenshot(iap, tip)` like `sync_image` and call it in `sync`.
- [ ] **Step 3: Run** `bundle exec fastlane tips dry_run:true`. Expected: four "would upload review screenshot" lines, nothing else.
- [ ] **Step 4: Run** `bundle exec fastlane tips`, then once more. Expected: four uploads; the second run reports no changes; each tip's state is no longer `MISSING_METADATA` (expected `READY_TO_SUBMIT`).
- [ ] **Step 5: Commit** — `build: tips lane uploads the App Review screenshot`.

### Task 10: Docs, and the phone check

**Files:**
- Modify: `docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md` (sections 4 and 5, the anti-goal, as the new spec's "Docs to update" says), `CLAUDE.md` (first paragraph, code map rows for `Tips/`, the StoreKit rule next to the PhotoKit rule, `Tips.storekit`, `-fakeTips`), `TODO.md` (own `docs:` commit: tick the tip jar and the Trash tips)

- [ ] **Step 1: Update the docs** listed above.
- [ ] **Step 2: Run** `run.sh --test`. Expected: all pass.
- [ ] **Step 3: Commit** — `docs: tips in the main design and CLAUDE.md`; then `docs: TODO tips shipped` with `TODO.md` alone.
- [ ] **Step 4: Phone check (with the user)** — `.claude/skills/run-device/scripts/run-device.sh`; the user signs in with a sandbox Apple account (Settings › App Store › Sandbox Account) and buys the small tip. Expected: real sandbox price, purchase sheet, fireworks, a haptic tap on each burst. If the products do not load, the review screenshots are not processed yet — say so and stop.
