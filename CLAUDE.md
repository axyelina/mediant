# Median't

iOS app (SwiftUI, iOS 17+, iPhone only, portrait). Display name is **Median't**; everything
code-facing (folders, targets, module, scheme) is `Mediant` because the apostrophe breaks paths.

## Project layout

- `project.yml` — XcodeGen spec, the source of truth. `Mediant.xcodeproj` is generated from it:
  after adding/removing files or changing settings, run `xcodegen generate`. Never hand-edit the
  `.xcodeproj`.
- `Mediant/` — app sources and assets (`MediantApp.swift` entry point, `ContentView.swift`).
- `MediantTests/` — unit tests, Swift Testing (`import Testing`, `@Test`, `#expect`).
- Bundle ID `com.pisarenko.mediant`; no development team set (Simulator only for now).

## Simulator — HARD RULE

Use only the dedicated simulator **`Median't iPhone 16`** (iPhone 16, iOS 18.4) for building,
running and testing. Never target another simulator, even if one is already booted or attached.
It is kept in **dark appearance**. Run the app with the `run-sim` skill
(`.claude/skills/run-sim/`), which finds/creates this simulator by name.

## Build & test

```bash
.claude/skills/run-sim/scripts/run.sh          # build, install, launch on the dedicated sim
.claude/skills/run-sim/scripts/run.sh --test   # run unit tests on the dedicated sim
```

DerivedData goes to `./build/` (gitignored).

## Git

No remote yet. The repo-local identity (`git config --local user.*`) is set by the user for this
repo; use it. If a remote is added, re-check the identity rule in the global instructions.

## Chat language

Write all chat replies in this project in **ASD-STE100 Simplified Technical English**: approved
words, one meaning per word, short sentences (procedures max 20 words, descriptions max 25),
active voice, one instruction per sentence, imperative for steps, vertical lists for sequences.
This rule applies to chat replies only, not to code, comments or docs, and only in this project.

## Maintenance

Keep this file and the project skills in `.claude/skills/` up to date as the project evolves:
when a workflow, convention or rule changes or is added, update them in the same change. When a
repeated multi-step workflow appears, capture it as a new skill.
