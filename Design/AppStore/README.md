# App Store marketing images

Screenshots (and later the header video) for the App Store product page. Chosen in the brainstorm
of 2026-11-04 … 2026-11-17 (mockups were in the brainstorm companion, not kept).

## What is here

| Path | What |
|---|---|
| `en/6.9/*.png` | Final English screenshots, 1320 × 2868 (iPhone 6.9", "Dynamic Island, large") |
| `en/6.3/*.png` | The same, 1206 × 2622 (iPhone 6.3", "Dynamic Island, medium") |
| `ru/6.9/*.png`, `ru/6.3/*.png` | The same set in Russian |
| `screens/<lang>/*.png` | Raw captures from the simulator (1179 × 2556), the input of the renderer |
| `src/screenshots.html` | The banner: captions, wine bands, dotted ✨ trail, sparkles, phone frame |
| `src/render.sh` | Renders every screenshot of a language with headless Chrome |

## The set (style C: one banner across all screenshots)

The wine background (the icon's diagonal split, `#470112` / `#75013d`) and a dotted ✨ trail run
across all five, so next to the header video in search results the first ones read as one wide
banner. A few sparkles per screenshot (one or two, as the user asked). The order is fixed.

1. `01-swipe` — a blurry shot leaves the card stack upward, sparkle edge on top. A glowing
   thumb-swipe hint (the only overlay on a screen) fills the black space under the photo: a
   curved trail from the lower right, where a right thumb sits, a touch dot and two chevrons up
   (`OVERLAYS` / `thumbSwipe()` in `src/screenshots.html`; `TURN` turns it around the finger).
   "Swipe up to delete / Down to keep 💖"
2. `02-freed` — the just-emptied Trash. "Get gigabytes back / One tap empties the Trash"
3. `03-albums` — albums with sizes and the progress card. "See what takes space / Every album with its size"
4. `04-trash` — the Trash grid with 👹 and Empty. "Nothing goes until you say so / iOS keeps it 30 days in Recently Deleted"
5. `05-undo` — the swipe screen with the 💖 / 👹 strip and Undo. "Changed your mind? / Undo any swipe"

Russian captions (`CAPTIONS.ru`) use the app's own words: «Смахните вверх», «Корзина»,
«Недавно удалённые», «Отменить». Known gap in `ru/03-albums`: the smart album names (Recents,
Videos, Portrait, Recently Saved) come from iOS and stayed English on the simulator even with the
phone in Russian (a restart and `-AppleLanguages (ru)` did not help); on a Russian iPhone they
are Russian. Re-capture on a phone if that matters.

Rules kept: no "Free" or other price words (App Review can reject price references in
screenshots and previews), no tip prices (the app was launched with `-fakeTips none`, so the
just-emptied Trash shows no tip chips), no Settings or tip screen — the page must not look like it
sells something. Only real app screens.

## Photos

The dog photos are the user's own (a folder outside the repo; not committed: the originals carry
EXIF and GPS data). Used: 17 of 21 — four left out (a brand logo on a clothing tag, a QR code and
brand labels on a workbench, two "note" photos the user dropped). The story is "the same dog, a
hundred times": blurry, cut-off, too-far and almost-identical shots go up (delete), the best ones
go down (keep).

To make the sizes real, the library also had ~750 grainy filler crops of the same photos (dated
2024–2025, so they sit below the dog photos and never show in a capture) and four 20 s videos made
from the photos. 250 fillers were put in the Trash and really deleted with Empty, so "GB freed"
on screenshot 2 and the progress card on screenshot 3 are what the app really measured.

## Re-render

From the repo root:

```bash
Design/AppStore/src/render.sh en
```

Needs Google Chrome and ImageMagick (`magick`). Edit captions in `src/screenshots.html`
(`CAPTIONS`); replace a screen by putting a new 1179 × 2556 capture into `screens/<lang>/`.

New captures: the dedicated simulator `Median't iPhone 16`, dark appearance, region `en_US` for
English (`ru_RU` and Russian first in `AppleLanguages`, then reboot the simulator, for Russian;
pick «Русский» in the app's Settings too); afterwards the simulator goes back to `en_RU`, status bar `xcrun simctl status_bar <udid> override --time 9:41
--batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi`, the
app launched with `run.sh -- -fakeTips none`. The simulator runs iOS 18.4, so chips use the
pre-iOS 26 material, not Liquid Glass.

## Upload to App Store Connect (by hand, or ask Claude first)

1. App Store Connect › Apps › Median't › the iOS version being prepared › English (U.S.).
2. "Previews and Screenshots" › iPhone: drag `en/6.9/01…05` in that order into the 6.9" slot.
   App Store Connect scales them for the smaller iPhones. Optionally also upload `en/6.3/` into
   the 6.3" slot (App Store Connect asks for at least one screenshot of that class; without it,
   it scales the 6.9" set down).
3. Check the order (drag to reorder), then Save. Repeat for Russian with `ru/`.

Limits (Apple's screenshot specifications, checked 2026-11-17): 1–10 screenshots per size,
`.png` or `.jpeg`, no alpha channel. App previews: 886 × 1920 portrait, 15–30 s, up to 30 fps,
H.264 or ProRes 422 HQ, max 500 MB.
