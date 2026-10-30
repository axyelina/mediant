---
name: asc-tips
description: Create or change Median't's tip in-app purchases (product IDs, names, descriptions, prices) in App Store Connect with fastlane. Use when the user wants to add, rename, reprice or check the tips in App Store Connect.
---

# Tip in-app purchases in App Store Connect

The tips are consumable in-app purchases that unlock nothing (see `TODO.md`, tip jar).
`fastlane/tips.json` is the source of truth; `bundle exec fastlane tips` makes App Store Connect
match it. fastlane's Spaceship has no in-app purchase (v2 API) models, so `fastlane/asc.rb` calls
the App Store Connect API directly and only borrows Spaceship's JWT.

## One-time setup

1. The Account Holder signs the **Paid Apps Agreement** (bank + tax) in App Store Connect →
   Business. Without it Apple refuses to create in-app purchases.
2. App Store Connect → Users and Access → Integrations → App Store Connect API → **Team Keys** →
   generate a key with the **App Manager** role (the Account Holder may first need to request API
   access). Download the `.p8` — Apple gives it only once.
3. Save it as `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` — never inside the repo.
   Never read, print or commit the key; fastlane reads it from the path.
4. Copy `fastlane/.env.example` to `fastlane/.env` (gitignored) and fill in the Key ID, Issuer ID
   and key path. fastlane loads `fastlane/.env` on its own.
5. `bundle install` from the repo root.

## Change the tips

1. Edit `fastlane/tips.json`: `reference_name` (internal, max 64), `price` in USD (the base
   territory; Apple sets the other countries), and `en-US` + `ru` `name` (max 30) / `description`
   (max 45). Keep "tip", never "donate" (guideline 3.2.2(iv)).
2. `bundle exec fastlane tips dry_run:true` — shows what would change, writes nothing.
3. `bundle exec fastlane tips` — creates missing tips, fixes names, descriptions, review note and
   price, and uploads each tip's promotional `image` and App Review screenshot
   (`review_screenshot`; a file with the same MD5 is left alone, a changed one is replaced). Run
   it again: a second run must report no changes. A tip goes from `MISSING_METADATA` to
   `READY_TO_SUBMIT` once it has the screenshot. Apple may need a minute to process an upload,
   so run a third time if the second one re-uploads a screenshot.
4. A new tip also needs an image: copy a `Design/Tips/tip-*.svg`, add it to the jobs in
   `Design/AppIcon/render.swift`, run `swift Design/AppIcon/render.swift`, and set the tip's
   `image` in `tips.json` (path relative to `fastlane/`). Re-render and re-run the lane after an
   art change.
5. Commit `tips.json`. The app's StoreKit code and `.storekit` test file use the same product IDs.

## Rules

- Never delete a tip in App Store Connect: a deleted product ID can never be used again. To stop
  selling one, remove it from the app and mark it "Removed from Sale" by hand.
- Availability is set once (all territories, new territories on) and then left alone.
- The App Review screenshot is `fastlane/tips/review-settings.png`, one file shared by all tips:
  the Settings tab with the tip card, English, dark. Retake it after a change of that screen:
  `run.sh -- -fakeTips usd`, open Settings, then
  `xcrun simctl io <udid> screenshot fastlane/tips/review-settings.png`, and run the lane.
- Not automated — do this by hand in App Store Connect: submitting the tips together with an app
  version.
- An API error is printed with Apple's own text (`POST /v2/inAppPurchases → 403 …`). A 403 on
  create usually means the Paid Apps Agreement is not active or the key's role is too low.
