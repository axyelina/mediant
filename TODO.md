# TODO / ideas

Loose backlog, not a plan. Before building an item, check it against the design's non-goals and
anti-goals (`docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md`): no ads, no
subscription, no tracking, no per-swipe delete dialog, compact controls in thumb reach.

## From the user

- [ ] **Working with video.** Shipped: looping playback on the top card, scrub on the ▶ chip,
      🔊/🔇 chip, ▶ badge in the album grid. Still open: show the video size more prominently
      (videos are where the space is).
- [ ] **Russian localization.** All strings are inline English today. Move them to a String
      Catalog (`Localizable.xcstrings`) and add Russian, including plurals ("1 фото", "5 фото",
      "items deleted") and byte formats.
- [ ] **Settings / About tab.** Third tab in the floating tab bar with:
      - app version and build number;
      - about the creator (name, short text, link);
      - an optional donation link ("Buy me a coffee" style): one quiet row, never a popup,
        badge, reminder or nag, and nothing in the app is locked behind it.

      Open questions before building:
      - The design lists "A Settings tab" as a v1 non-goal and "no payments — ever" — update the
        spec when this lands (donation stays optional, the app stays fully free).
      - App Store review: a link to an outside donation page is often rejected for individual
        developers (guidelines 3.1.1 / 3.2.2); the alternative is an in-app "tip" purchase, which
        is in-app purchase. Check the current rules before choosing.
      - Maybe "About" fits better than "Settings" while there is nothing to set.

## From Claude

### Video
- [ ] "Biggest first" order for an album, or a "Large videos" smart source — fastest way to free space.
- [ ] Show the per-item size on the swipe screen for every photo, not only on the album row.

### Swiping
- [ ] Swipe up = "decide later" / skip without marking (leaves the photo undecided).
- [ ] Burst photos and Live Photos: show the count of frames / the "LIVE" badge so the user knows
      what they delete.
- [ ] "On this day" / by-month source: swipe through one month at a time, a natural session size.
- [ ] Undo after leaving and coming back (the undo stack lives only in the session now).

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
