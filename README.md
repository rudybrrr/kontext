# Capture

Capture is an iPhone-first, local-first place for useful text, links, and images. It saves first, enriches on-device, groups captures into flexible contexts, and combines exact-term and semantic search so you do not need to maintain folders.

The name and identifiers are temporary and centralized in `project.yml`, the two entitlements files, and `CapturePersistence.appGroupIdentifier`.

## What is included

- Fast text, URL, and Photos image capture
- Safari, Photos, and selected-text Share Extension
- Shared SwiftData persistence in an App Group
- Images and thumbnails stored as files instead of database blobs
- Vision OCR and best-effort native URL metadata
- Structured Foundation Models enrichment when the system model is available
- Deterministic title/tag enrichment and conservative Inbox assignment otherwise
- NaturalLanguage sentence embeddings with lexical-only fallback
- Context creation, rename, item reassignment, and enrichment retry
- Native SwiftUI home, search, detail, and settings screens

There is no account, backend, cloud sync, external AI service, analytics, or third-party runtime dependency.

## Architecture

The app and extension compile the same models, persistence setup, media store, and share parser from `Capture/Shared`. The Share Extension only parses and persists, then exits. The main app performs optional extraction, enrichment, embedding, assignment, and search.

Every capture follows the same reliability boundary:

```text
validate → persist original → dismiss/finish → extract → enrich → embed → assign
```

An extraction or model failure can change enrichment state to `partial` or `failed`, but it does not delete or roll back the original capture.

## Requirements

- macOS with Xcode 26 or later
- iOS 26 SDK and an iOS 26 simulator or device
- An Apple development team and App Group entitlement for device deployment
- XcodeGen 2.46+ only if regenerating `Capture.xcodeproj` from `project.yml`

The checked-in project targets iOS 26.0 and is iPhone-only.

## Build and test

Open `Capture.xcodeproj` in Xcode, select the `Capture` scheme, choose an iPhone running iOS 26, and Run.

From Terminal, first discover an available simulator:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl list devices available
```

Then substitute its ID:

```sh
xcodebuild \
  -project Capture.xcodeproj \
  -scheme Capture \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' \
  clean test
```

Build the extension independently with:

```sh
xcodebuild \
  -project Capture.xcodeproj \
  -target CaptureShareExtension \
  -sdk iphonesimulator \
  build \
  CODE_SIGNING_ALLOWED=NO \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  SYMROOT=/private/tmp/CaptureExtensionBuild \
  OBJROOT=/private/tmp/CaptureExtensionBuild/obj
```

After changing `project.yml`, regenerate with `xcodegen generate`.

## App Group configuration

Both targets use `group.com.rudy.capture`:

- Main app: `com.rudy.capture`
- Share Extension: `com.rudy.capture.share`
- Entitlements: `Capture/App/Capture.entitlements` and `CaptureShareExtension/CaptureShareExtension.entitlements`

For a physical device, select your development team for both targets and register/enable the same App Group for both bundle IDs in Apple Developer signing. The Share Extension does not require the main app to have been opened before capture.

## Using the Share Extension

Install Capture from Xcode so iOS registers its embedded extension; the main app does not need to be opened before the first shared capture. In Safari, Photos, or a selected-text share sheet, choose **Capture**. The extension saves the URL, text, or image into the shared store, briefly confirms success, and closes. Enrichment runs the next time the main app observes the pending item.

If Capture is not visible, use **More** in the share sheet to enable it. Share-sheet discovery and App Group signing should be verified on a physical iPhone before distribution.

## On-device AI and fallback

When `SystemLanguageModel.default` is available and supports the current locale, Capture requests a structured title, summary, tags, suggested context, and confidence. New contexts require high confidence and are semantically checked against existing contexts before creation.

When Apple Intelligence is disabled, unsupported, not ready, or the model request fails, a deterministic local enricher creates a recognizable title, summary, and tags. Context similarity is attempted when embeddings exist; uncertain captures go to one Inbox context. Settings reports model availability without blocking capture.

## Local search

Each enriched item stores an encoded sentence embedding for its title, summary, original/extracted text, and tags. A query is scored using:

- strong case- and diacritic-insensitive lexical matching
- cosine similarity when query and item vectors are available
- deterministic date and UUID tie-breaking

If NaturalLanguage has no sentence embedding for the device or language, exact and token search still work.

## Known MVP limitations

- No sync, account, import pipeline, camera capture, background daemon, or custom folder hierarchy
- Shared items enrich when the main app next runs; the extension intentionally performs no OCR or model work
- URL title retrieval is best-effort and may contact the saved page's host; saving never depends on network access
- Image understanding on iOS 26 is OCR-based because the installed SDK has no practical Foundation Models image input used by this project
- Foundation Models output varies and is intentionally excluded from deterministic tests
- Share-sheet presentation, Photos selection, and production App Group provisioning still require final physical-device checks for a shipping build

The approved boundary is captured in [`docs/MVP_SPEC.md`](docs/MVP_SPEC.md); the executed sequence is in [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md).
