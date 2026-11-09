---
name: testflight
description: Upload Median't to TestFlight, raise the build number, start a new version, or check the Release binary before an upload. Use when the user wants a TestFlight build, a new version number, or to check what goes into the store build.
---

# TestFlight uploads, version and build numbers

## Numbers

`project.yml` holds both (XcodeGen is the source of truth; never edit them in Xcode):

- `MARKETING_VERSION` — the version users see (`1.0`).
- `CURRENT_PROJECT_VERSION` — the build number. **It goes up by one after every TestFlight upload
  and back to 1 with a new version** (Apple needs a new build number only within one version).

The logic is `fastlane/versioning.rb`, tested by `ruby fastlane/test/versioning_test.rb`.

## Lanes (from the repo root)

| Command | What it does |
|---|---|
| `bundle exec fastlane beta` | Clean git required. `xcodegen generate`, archive Release, export for the App Store, upload to TestFlight with the API key (does not wait for processing), then build number + 1, regenerate, **commit** `project.yml` + `project.pbxproj`. Does not push. |
| `bundle exec fastlane bump_build` | Only build number + 1 and commit — after an upload done by hand (Xcode Organizer). |
| `bundle exec fastlane set_version version:1.1` | New version (must be higher, `1.1` or `1.1.2`), build number back to 1, commit. Run it before the first upload of the new version. |

The commits use the repo-local git identity. Push the build-number commit after a successful
upload. If the upload fails, nothing is committed and the same build number is used again.

## Requirements

- **Xcode 26 or later** (iOS 26 SDK). App Store Connect refuses builds from older SDKs with
  "SDK version issue" (409) after the export: archive and signing succeed, the upload fails.
  Check first: `xcodebuild -version`.
- `xcodegen`, Ruby with `bundle install` (fastlane is pinned in `Gemfile`).
- `fastlane/.env` and the `.p8` key it points to (copied by the user; never in git).
- A clean git working tree (`beta` refuses otherwise) and the repo-local git identity
  `axyelina <axyelina@gmail.com>` for the build-number commit.

## Before the first upload (one time)

- **Distribution certificate:** the team `NDCC8HH7D8` has one (Angelina Odegova, until
  2027-11-09), but its private key lives only in the keychain of the Mac that made it. On a new
  Mac, sign in to Xcode › Settings › Accounts with an Apple ID that is Admin or Account Holder on
  the team; `-allowProvisioningUpdates` then creates that Mac's certificate and the App Store
  profile on the first `beta` run. Check: `security find-identity -v -p codesigning` lists
  "Apple Distribution: Angelina Odegova (NDCC8HH7D8)". The App Store Connect API key in
  `fastlane/.env` has the App Manager role: it uploads builds, but cannot be relied on to create
  certificates.
- **Testers:** App Store Connect › TestFlight › create an internal group and add team members.
  Internal testers need no review. External testers need Test Information (description, feedback
  e-mail, review contact, privacy policy URL) and a Beta App Review.

## Prefer `fastlane beta` over Xcode Organizer

The lane passes `OTHER_CFLAGS=$(inherited) -fmacro-prefix-map=<repo>/=` on the command line. Without
it, Google's package code (GoogleDataTransport asserts use `__FILE__`) puts this Mac's
`/Users/<name>/…` path into the binary. `project.yml` settings do not reach package targets, so an
Organizer archive still has the paths.

## Binary check (before a release, or after adding a dependency or resource)

```bash
xcodebuild -project Mediant.xcodeproj -scheme Mediant -configuration Release -sdk iphoneos \
  -destination "generic/platform=iOS" -derivedDataPath build/release-check \
  -clonedSourcePackagesDirPath build/SourcePackages CODE_SIGNING_ALLOWED=NO \
  "OTHER_CFLAGS=\$(inherited) -fmacro-prefix-map=$PWD/=" -quiet build
```

Unsigned, so the dSYM upload phase skips it. Then in
`build/release-check/Build/Products/Release-iphoneos/Mediant.app`:

1. `find . -type f` — only the app's resources, `GoogleService-Info.plist` (its `API_KEY` is a public
   client ID, fine) and the Firebase bundles with their privacy manifests. No sample media, notes,
   `.md`, configs or keys.
2. `strings -a Mediant` and grep for `/Users/`, e-mail addresses, real names, `fakeTips` /
   `DemoTipStore` (Debug only), `localhost`, `password`, `secret`. Expected: none, except links the
   app shows on purpose (e.g. the creator's Instagram in Settings).
3. `plutil -p Info.plist` — version, build, `ITSAppUsesNonExemptEncryption = 0`, the photo usage
   text, portrait only.
