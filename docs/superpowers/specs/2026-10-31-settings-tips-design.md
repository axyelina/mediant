# Tips in Settings and in the just-emptied Trash: design

Date: 2026-10-31. Status: approved by the user on 2026-10-31. Plan: `docs/superpowers/plans/2026-10-31-settings-tips.md`.
Mockups (HTML, open in a browser):

- `docs/superpowers/mockups/04-settings-tips.html` — layout B was chosen (the order changed
  later, see below).
- `05-tip-prices.html` — fix A, "auto" (one row or 2 × 2), was chosen.
- `06-trash-tips.html` — layout A, "inline chips", was chosen.
- `07-fireworks.html` — live prototype; look A, "app colors", was chosen, with the light-mode
  version as shown.

The main design is `2026-10-28-mediant-photo-cleaner-design.md`; this document changes its
sections "4. Trash tab" (the just-emptied state) and "5. Settings tab", and one anti-goal.

## Intent

Median't stays free: no ads, no subscription, nothing locked. The developer builds it in their
free time, and it would be nice if a happy user could **treat them**. Tips show in two places:
a quiet tip card in Settings, always there, and a few price chips in the Trash right after the
user has just freed space — the moment they are most likely to feel thankful. A tip is a
thank-you, not a purchase of anything: it unlocks nothing. When someone tips, the app thanks them
with Disney-style fireworks in the app colors and a haptic tap on every explosion.

## Goals

- A user who wants to thank the developer tips in two taps (price, then the iOS purchase sheet).
- Prices are always the App Store's own prices in the user's currency, and they always fit.
- A tip feels good: fireworks right after the payment.
- The version is always visible at the bottom of Settings and can be copied (for bug reports).

## Non-goals

- "About the creator" (name, short text, link) — still waits for the user's text (TODO).
- Tip history, a "supporter" badge, a counter of tips, or anything that changes after a tip.
- Restore purchases: tips are consumables, there is nothing to restore.
- Promoting the tips on the App Store page (a separate App Store Connect choice).

## Anti-goals (a failure even if it "works")

- Anything that pushes: a popup, a sheet, a badge, a reminder, a banner, or tips that move, flash
  or ask again. The Settings card is always in the same place and looks the same. The Trash tips
  appear only right after a real deletion and are gone on the next visit.
- Anything unlocked by a tip, even a cosmetic one (App Review would treat it as a normal purchase,
  and it would break the "free" promise).
- The word "donate" anywhere (App Review guideline 3.2.2(iv) keeps donations for nonprofits).
- Fireworks at any other time than right after a real, verified tip.
- An error popup when the user cancels the purchase sheet.

The main design's anti-goal "Any subscription, paywall, ads, or in-app purchase" becomes "Any
subscription, paywall, ads, or in-app purchase that unlocks something. Optional tips that unlock
nothing are allowed (added 2026-10-31)". `CLAUDE.md`'s first paragraph ("No ads, no subscription,
no payments — ever") changes the same way.

## Constraints

- iOS 17+, SwiftUI, StoreKit 2 (`Product`, `Transaction`). No third-party purchase library.
- Product IDs (already live in App Store Connect, consumable, see `fastlane/tips.json`):
  `app.mediant.tip.small` ($0.99), `app.mediant.tip.medium` ($2.99),
  `app.mediant.tip.large` ($4.99), `app.mediant.tip.huge` ($9.99). They are fixed forever.
- StoreKit stays behind a protocol, the same way PhotoKit stays behind `PhotoLibrary`: only one
  type (`StoreKitTipStore` or similar) imports StoreKit; logic and view models take the protocol
  and are tested with a fake (TDD, as `CLAUDE.md` requires for logic and view models).
- A `.storekit` configuration file with the four products, in the repo, also set in the
  `Mediant` scheme's run action through `project.yml` (useful when Xcode runs the app).
- Every text in `Localizable.xcstrings` with Russian. Prices are never translated or formatted by
  the app: they are `Product.displayPrice`.
- Haptics: SwiftUI `.sensoryFeedback`, as the app already does in `SwipeView` and `TrashView`.
- **One tip model for both places.** The products, the purchase state and the "a tip just
  succeeded" event are shared: one store, one in-progress purchase at a time, one fireworks
  overlay. The two places only differ in how they look.

## Shared tip buttons

Used in both places; only the colors differ.

- Four buttons, sorted by price, each showing only `displayPrice`, at least 32 pt tall (the `Chip`
  height), bold text.
- **Fit rule (chosen fix A):** one row of four equal buttons when every price fits on one line at
  the normal font size; otherwise a 2 × 2 grid of equal buttons. `ViewThatFits` (row first, grid
  second) is the expected tool. Prices never shrink, wrap or get cut. With today's prices, USD,
  EUR, RUB, INR, JPY get one row; KZT, IDR, VND, KRW get the grid.
- Accessibility: each button reads as "Tip, $2.99" ("Чаевые, 2,99 $").

States:

| State | Buttons |
|---|---|
| Loading the products | Four empty capsules with the app's `.shimmering` effect |
| Products loaded | The four prices |
| A purchase in progress (in either place) | All buttons disabled; the tapped one shows a small spinner instead of its price |
| Products cannot load (no internet, App Store down) | Settings: no buttons, one line "Tips are not available right now." / "Чаевые сейчас недоступны."; the rest of the card stays. Trash: the whole tip part (line and chips) is hidden. Loading is tried again the next time either place appears |

Purchase results:

- **Success, verified:** finish the transaction, then fireworks and a "Thank you! ✨" /
  "Спасибо! ✨" line for about 3 s in the place where the user tapped (see each place).
- **Cancelled by the user:** nothing, no message.
- **Pending** (Ask to Buy, extra bank check): nothing now. When it completes later, the
  transaction is finished silently, with no fireworks.
- **Failed, or not verified:** no fireworks; "The tip did not go through." / "Чаевые не прошли."
  for about 3 s in the place where the user tapped. No popup.

The app listens to `Transaction.updates` from launch and finishes every tip transaction it
receives there (pending ones that complete later, interrupted ones). It never shows fireworks for
those.

## Settings screen

Order, top to bottom (the user's choice):

1. Large title "Settings" (as now).
2. **Language** card (as now).
3. **Trash reminder** card (as now).
4. **Tip card** (new, below).
5. **Progress** card (as now, with Reset).

The current "Version" card is removed; the version moves to the pinned line below.

### Tip card

- Shape: the same 18 pt rounded card as the others, but filled with the icon art: a diagonal
  split, `#470112` on the left part and `#75013d` on the right (the split line runs like the
  icon's, from 62 % of the top edge to 38 % of the bottom edge), with a 1 pt `#ff5c93` border at
  about 35 % opacity. The same in light mode (it is the icon art).
- Title: "Treat the developer ✨" — Russian "Угостить разработчика ✨". After a tip from this card:
  "Thank you! ✨" for about 3 s, then back.
- Text (light pink `#ffd1e3` at about 85 %): "Median't is free: no ads, no subscription. I build
  it in my free time. If it helps you, you can leave a tip. It unlocks nothing." — Russian:
  "Median't бесплатный: без рекламы и подписок. Я делаю его в свободное время. Если он вам помог,
  можно оставить чаевые. Они ничего не открывают." A failed tip replaces this text with the
  failure line for about 3 s.
- Buttons: glass capsules (white fill about 14 %, white border about 22 %).

### Pinned version

- A small glass capsule with "Median't 1.0 (12)" (display name, marketing version, build number),
  secondary color, monospaced digits, centered above the floating tab bar, about 8 pt above it.
- It stays in place while the cards scroll under it. The scroll content gets enough bottom
  padding that the last card (Progress) can scroll fully above the version and the tab bar.
- Tap: copies exactly "Median't 1.0 (12)" to the pasteboard, the capsule shows "Copied" /
  "Скопировано" for about 1 s, and a light haptic plays. Long-press does the same (people try
  both).
- The version is only on the Settings tab.

## Tips in the just-emptied Trash (layout A, "inline chips")

**When:** right after "Empty" really deleted photos (the iOS dialog was allowed and the delete
succeeded). Not after "Don't Allow", not after a failed delete, not when the Trash was emptied by
restoring photos.

**What replaces today's empty state, top to bottom, centered:**

- The title "Trash" and the subtitle "Nothing to delete" (as now).
- A ✨ in place of the 👹: the app's drawn `SparkleShape(cluster: true)` in pink tones (the same
  shape as the title ✨, not the emoji).
- "Done!" / "Готово!" (headline).
- "1.2 GB freed" / "Освобождено 1,2 ГБ" — large, bold, light-pink-to-pink gradient
  (`#ffd1e3` → `#ff5c93`). The bytes of this one delete (the sizes `TrashModel.emptyTrash()`
  already measures before deleting), through `ByteFormat` with the app locale. If no size is
  known, this line is left out.
- "48 photos deleted" (plural forms in the catalog), then the existing Recently Deleted hint and
  the "Open Photos" chip, as now.
- A thin divider.
- One quiet line in light pink: "Liked it? Treat the developer ✨" / "Понравилось? Угостите
  разработчика ✨". After a tip from here: "Thank you! ✨" for about 3 s; after a failure, the
  failure line for about 3 s.
- The four shared tip buttons, pink style: pink fill `#ff375f` at about 18 %, `#ff5c93` border at
  about 40 %, `#ffb3c4` text.

**Gone on the next visit:** the "just emptied" state ends when the user leaves the Trash tab, when
the app goes to the background, or when new photos land in the Trash. After that the empty Trash
looks as it does today (👹, "Trash is empty", the hint, "Open Photos"), with no "freed" line and
no tips. It is not saved: after a restart it is gone too. *(Claude's call on the exact end
events.)*

The existing `.success` haptic on a delete stays.

## Fireworks (look A, "app colors"; live prototype `07-fireworks.html`)

- Trigger: only a verified, successful tip from a button the user tapped, in either place.
- Where: one overlay over the whole app, above the tab bar, edge to edge (ignores safe areas).
  It takes no taps (`allowsHitTesting(false)`), so the app stays usable during the show.
- **Rocket:** launches from just below the bottom edge, flies up on a gently curved path with a
  glowing tapered trail and a small bright ✨ head, slows down and explodes between about 20 % and
  45 % of the screen height from the top. The trail fades out after the burst.
- **Burst ("Disney" chrysanthemum, like the user's reference picture):**
  - about 48 long glowing streaks (72 for the Huge finale) flying out in a full circle, in **two
    colors per burst** (alternating). Each streak is tapered: transparent near the center,
    brightest at its outer end; at first the streaks reach almost to the center, then the inner
    ends move outward;
  - a ring of small round dots just outside the streaks, flickering;
  - a bright many-pointed star flash in the center that fades in about 0.6 s;
  - 7 small ✨ (`SparkleShape`) twinkling around the burst (12 for the finale);
  - everything slows down, droops a little (gravity) and fades out over about 1.5 s.
- **Burst size:** about 190–220 pt radius for a single rocket, 130–175 pt when there are several,
  250 pt for the finale; each burst center stays far enough from the side edges that the whole
  burst is on screen.
- **Colors, dark mode (look A):** color pairs from the app palette — pink `#ff5c93` + light pink
  `#ffd1e3`, wine `#c2184e` + white, light pink + pink, white + wine. Trail light pink, star flash
  and ✨ white. Glow (additive blending and a soft blur), as in the prototype.
- **Colors, light mode:** pairs wine `#c2184e` + pink `#ff5c93`, dark wine `#470112` + pink,
  pink + `#75013d`. Wine trail and star flash, no glow, no additive blending.
- Size of the show (a bigger tip gives a bigger show):

| Tip | Rockets | Extra |
|---|---|---|
| Small | 1 | — |
| Medium | 2 | — |
| Large | 3 | — |
| Huge | 5 | then one big finale burst in the middle |

- Rockets start about 0.38 s apart; each flies about 0.75–0.95 s. The whole show ends in about
  2.5–3 s (Huge about 4 s).
- **Haptic:** one tap at the moment each rocket explodes (`.impact`, medium weight; the Huge
  finale heavy). Nothing on launch.
- **Reduce Motion on:** no rockets, no streaks. A soft pink glow appears behind the tapped tip
  buttons and fades out in about 1 s, with one haptic tap. The "Thank you!" line works as usual.
- The show is decided by a pure, unit-tested plan (which rocket starts when, from where, its
  path, where and when it explodes, the burst radius and color pair), made from the tip size, the
  screen size and a random seed; the view only draws the plan over time. Tests check the rocket
  count per tip, the timing, the explosion times (they drive the haptics) and that every burst
  stays on screen.

## What the builder decides

- Type and file names, how the tip store is created and injected (`AppModel` owns the other
  services today), and where the `Transaction.updates` listener lives.
- How the fireworks are drawn (for example `TimelineView` + `Canvas` with additive blending), as
  long as they stay smooth on the iPhone 16 and do not block the main thread. The prototype's
  numbers are a starting point; match its look, not its code.
- Exact sizes, easing and random ranges inside the limits above.
- Whether products load at app start or when a tip place first appears (it must be fast enough
  that the shimmer is rarely seen).
- The App Review notes are already in `fastlane/tips.json`.

## Testing

- Unit tests (Swift Testing, fake tip store): products sorted by price; each purchase result
  (success, cancelled, pending, failed, unverified) leads to the right state in the place that
  was tapped; one purchase at a time across both places; fireworks only for a verified success;
  "not available" when loading fails, and a retry later; the Trash "just emptied" state starts
  only after a successful delete and ends on each end event; the freed bytes and count of one
  delete; the fireworks plan (above); the version string.
- The real StoreKit type is tested against the `.storekit` file with `SKTestSession` inside the
  test target (buy, cancel, fail, pending/Ask to Buy, storefront change). *(Claude's call: a
  scheme's StoreKit configuration only works when Xcode starts the app, and the project's
  `run-sim` script starts it with `simctl`.)*
- On the dedicated simulator through `run-sim`: a Debug-only launch argument (for example
  `-fakeTips usd|kzt|idr|fail|none`) swaps in a fake tip store with real-looking prices, so the
  one-row / 2 × 2 fit, the loading and error states, the "Thank you!" lines, the fireworks (dark
  and light) and Reduce Motion can be seen and screenshotted without Xcode. `#if DEBUG` only,
  never in Release; the `run-sim` skill documents it. *(Claude's call.)* The Trash part needs a
  real delete of seeded sample photos (`seed-photos.sh`).
- App Review screenshots: one per tip, taken from the Settings screen in the simulator, uploaded
  by the `tips` lane (add review-screenshot upload next to the promotional image upload). This
  moves the tips out of "Missing Metadata", which sandbox needs. *(Claude's call: products in
  "Missing Metadata" are expected not to load in sandbox — confirm on the phone.)*
- Last, on the phone (`LINK`, sandbox account): one real sandbox tip, to feel the haptics.

## Docs to update in the same change

- Main design: section 4 (the just-emptied Trash), section 5 (new order, tip card, pinned
  version), the anti-goal (above).
- `CLAUDE.md`: first paragraph (payments), code map (new files), the StoreKit rule (only one type
  imports StoreKit), the `.storekit` file.
- `TODO.md`: tick the tip jar and the Trash tips.
- `run-sim` skill: the `-fakeTips` launch argument. `asc-tips` skill: review screenshots are now
  uploaded by the lane.
