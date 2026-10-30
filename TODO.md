# TODO / ideas

Loose backlog, not a plan. Before building an item, check it against the design's non-goals and
anti-goals (`docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md`): no ads, no
subscription, no tracking, no per-swipe delete dialog, compact controls in thumb reach.

## ⚠️ Before the first release

- [ ] **Change the bundle ID.** Today it is `com.pisarenko.mediant` (tests:
      `com.pisarenko.mediant.tests`, `bundleIdPrefix: com.pisarenko`) under the free personal team
      `WZHN8Q7J25`. After the first App Store upload the ID can never change, so pick the final one
      first. Change it in `project.yml`, run `xcodegen generate`, and update the scripts that use it
      (`.claude/skills/run-sim/scripts/run.sh`, `.claude/skills/run-device/scripts/run-device.sh`).
      A new ID is a new app on the simulator and the phone: decisions, stats and the Photos
      permission start again.

## From the user

- [ ] **Working with video.** Shipped: looping playback on the top card, scrub on the ▶ chip,
      🔊/🔇 chip, ▶ badge in the album grid. Still open: show the video size more prominently
      (videos are where the space is).
- [ ] **Settings tab — what is left.** Shipped: language switch, progress reset, version. Still to add:
      - about the creator (name, short text, link) — waits for the text;
      - an optional donation link ("Buy me a coffee" style): one quiet row, never a popup,
        badge, reminder or nag, and nothing in the app is locked behind it — waits for the URL.

      Open questions before the donation row:
      - The design says "no payments — ever" — update the spec when this lands (donation stays
        optional, the app stays fully free).
      - App Store review: a link to an outside donation page is often rejected for individual
        developers (guidelines 3.1.1 / 3.2.2); the alternative is an in-app "tip" purchase, which
        is in-app purchase. Check the current rules before choosing.
- [ ] **Research: local push for a forgotten Trash.** Example: the user marked photos to delete,
      did not empty the Trash and left the app for hours → one local notification ("12 photos ·
      340 MB wait in the Trash"); tapping it opens the Trash.

      To find out before building:
      - Local only (`UNUserNotificationCenter` + `UNTimeIntervalNotificationTrigger`), no server,
        no tracking. Schedule on going to background with a non-empty Trash; cancel on return,
        on empty and on restore of everything.
      - The app does not run when it fires: the text is fixed at scheduling time.
      - When to ask for permission: not at launch; maybe the first time the Trash gets items.
      - Delay (2 h? next evening?) and how often: one per batch, never repeat → no nag.
      - Opt-out: iOS Settings is enough, or does it need a switch in the app?

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
