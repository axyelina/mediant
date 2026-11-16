# Vertical Swipe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the swipe screen, up = delete, down = keep, a swipe to the right = back to the album; sparkles at the top/bottom; no tap-to-skip.

**Architecture:** A pure `SwipeGesture` enum in `Model/` classifies a finished drag (unit-tested, like `TabSwipe`). `SwipeView` moves the card vertically and acts on the outcome; `SparkleEdge` draws along the top/bottom edge.

**Tech Stack:** SwiftUI, Swift Testing, XcodeGen.

**Spec:** `docs/superpowers/specs/2026-11-17-vertical-swipe-design.md`

## Global Constraints

- iOS 17+, `SWIFT_VERSION` 5.0; new files → `xcodegen generate`.
- Thresholds: commit past 90 pt, or predicted end past 160 pt.
- Sparkle colors: top (delete) `#470112`, bottom (keep) `#75013d`.
- Every UI text in `Localizable.xcstrings` with Russian.
- Tests on the `Median't iPhone 16` simulator only (`run-sim` skill).

## Review Focus

- A diagonal drag (|dx| ≈ |dy|): the bigger axis wins; a tie counts as vertical.
- A fling up/down that is short (< 90 pt) but fast (predicted > 160 pt) decides.
- A horizontal drag to the left does nothing (no back, no decision).
- A slow short horizontal drag to the right (< 90 pt, predicted < 160 pt) does not go back.
- Undo after a keep brings the photo back from the bottom, after a delete from the top.

---

### Task 1: `SwipeGesture.outcome`

**Files:**
- Create: `Mediant/Model/SwipeGesture.swift`
- Test: `MediantTests/SwipeGestureTests.swift`

**Interfaces:**
- Produces: `enum SwipeGesture { enum Outcome: Equatable { case trash, keep, back, none }; static func outcome(translation: CGSize, predictedEnd: CGSize) -> Outcome }`

- [ ] **Step 1: Write the failing tests** (helper `outcome(dx, dy, predicted: CGSize? = nil)`):
  - `upPastThresholdTrashes`: (0, -100) → `.trash`
  - `downPastThresholdKeeps`: (0, 100) → `.keep`
  - `shortFastFlingUpTrashes`: (0, -40), predicted (0, -200) → `.trash`
  - `shortSlowDragDoesNothing`: (0, 40), predicted (0, 60) → `.none`
  - `rightSwipeGoesBack`: (100, 10) → `.back`; fling (40, 0) predicted (200, 0) → `.back`
  - `leftSwipeDoesNothing`: (-100, 0) → `.none`
  - `diagonalUsesBiggerAxis`: (60, -100) → `.trash`; (100, -60) → `.back`; tie (100, -100) → `.trash`
- [ ] **Step 2: Run `run.sh --test`** — expected: build fails (no `SwipeGesture`).
- [ ] **Step 3: Implement** — axis: vertical when `abs(dy) >= abs(dx)` of `translation`; value = translation if past 90, else predicted if past 160, else 0. Vertical: < 0 → trash, > 0 → keep. Horizontal: > 0 → back, else none.
- [ ] **Step 4: `xcodegen generate`, run `run.sh --test`** — expected: Tests passed.

### Task 2: Swipe screen, sparkles, skip removal, texts, docs

**Files:**
- Modify: `Mediant/Swipe/SwipeView.swift`, `Mediant/Swipe/SparkleEdge.swift`, `Mediant/Model/SwipeSession.swift` (remove `skip()`), `MediantTests/SwipeSessionTests.swift` (remove the 2 skip tests), `Mediant/Localizable.xcstrings`, `Mediant/App/AccessView.swift`, `Mediant/Trash/TrashView.swift`, `CLAUDE.md`, `docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md`

**Interfaces:**
- Consumes: `SwipeGesture.outcome(translation:predictedEnd:)`
- Produces: `SparkleEdge.Side { case top, bottom }`

- [ ] **Step 1:** `SwipeView`: `dragY` replaces `dragX` and `skipY`; card offset y only, no rotation; next-card lift = `abs(dragY) / height`; on end, `.trash`/`.keep` → commit (fly to ∓1.5 × height), `.back` → spring back + `dismiss()`, `.none` → spring back. Undo starts at the edge of the last decision. Remove `.onTapGesture` and `skip(_:height:)`.
- [ ] **Step 2:** `SparkleEdge`: sides `.top`/`.bottom`; sparkle x random across the width, inset from the top/bottom edge.
- [ ] **Step 3:** Remove `SwipeSession.skip()` and `skipAdvancesWithoutDeciding`, `skipPastLastFinishes`.
- [ ] **Step 4:** Texts: "Swipe up to delete, down to keep. Your photos never leave your phone." / "Смахните вверх, чтобы удалить, и вниз, чтобы оставить. Фото не покидают ваш телефон."; "Swipe up on photos you don't want." / "Смахните вверх ненужные фото."
- [ ] **Step 5:** Docs: `CLAUDE.md` intro + code map (`SwipeView`, `SwipeGesture`), main spec swipe-screen section.
- [ ] **Step 6:** `run.sh --test` → Tests passed; `run.sh` → drag up/down/right on the simulator and check screenshots.
- [ ] **Step 7:** Commit (`feat:`), build to the phone `LINK` (`run-device` skill).
