# Capture MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working iOS 26 Capture app and Share Extension that persist first, enrich and organize on-device, and retrieve with deterministic semantic/lexical ranking.

**Architecture:** SwiftData models and persistence/media primitives are shared by the app and extension. The extension ends after parsing and saving; the app owns OCR, metadata, embeddings, Foundation Models, assignment, search, and SwiftUI presentation. Small protocols isolate nondeterministic AI and embeddings from deterministic domain tests.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Foundation Models, NaturalLanguage, Vision, PhotosUI, LinkPresentation, UniformTypeIdentifiers, XCTest, XcodeGen 2.46.

**Spec:** `docs/MVP_SPEC.md`

## Global Constraints

- Deployment target is iOS 26.0; do not raise it for future multimodal APIs.
- No third-party runtime dependencies, backend, API keys, accounts, analytics, or sync.
- Persist original captures before enrichment and never delete them on enrichment failure.
- Use App Group `group.com.rudy.capture` for the shared store and media.
- Foundation Models and sentence embeddings must have deterministic unavailable fallbacks.

---

### Task 1: Project, models, and shared persistence

**Files:** `project.yml`, `Capture/Shared/Models.swift`, `Capture/Shared/CapturePersistence.swift`, `CaptureTests/PersistenceTests.swift`, entitlements and plist files.

**Interfaces:** Produce `CaptureItem`, `CaptureContext`, `CaptureKind`, `EnrichmentState`, `CapturePersistence.makeContainer(inMemory:)`, and `CaptureStore` capture/context operations.

- [ ] Add persistence tests that insert text, URL, image metadata, and a context relationship into an in-memory container.
- [ ] Generate the Xcode project and run the focused tests, confirming they fail because the shared types do not exist.
- [ ] Add the minimum models and store implementation using `ModelConfiguration(groupContainer: .identifier("group.com.rudy.capture"), cloudKitDatabase: .none)`.
- [ ] Run the persistence tests until they pass, then commit `feat: add shared capture persistence`.

### Task 2: Vectors, search, and context assignment

**Files:** `Capture/Shared/VectorCodec.swift`, `Capture/App/Services/EmbeddingService.swift`, `Capture/App/Services/SearchService.swift`, `Capture/App/Services/ContextAssignmentService.swift`, `CaptureTests/SearchTests.swift`, `CaptureTests/ContextAssignmentTests.swift`.

**Interfaces:** Produce `VectorCodec.encode/decode`, `VectorMath.cosineSimilarity`, `EmbeddingProviding`, `NaturalLanguageEmbeddingService`, `SearchService.rank`, and `ContextAssignmentService.assignment`.

- [ ] Add tests with hand-derived vectors for round trips, cosine values, lexical precedence, semantic order, deterministic ties, empty queries, missing vectors, similar-context reuse, and Inbox fallback.
- [ ] Run focused tests and confirm missing-symbol failures.
- [ ] Implement only the tested encoding, cosine, combined scoring, and threshold assignment behavior.
- [ ] Run focused tests until green, then commit `feat: add local semantic retrieval`.

### Task 3: Enrichment and media extraction

**Files:** `Capture/App/Services/EnrichmentService.swift`, `FoundationModelEnrichmentService.swift`, `MediaStore.swift`, `OCRService.swift`, `LinkMetadataService.swift`, `EnrichmentCoordinator.swift`, `CaptureTests/EnrichmentTests.swift`.

**Interfaces:** Produce `EnrichmentProviding.enrich(text:contexts:)`, `EnrichmentResult`, deterministic fallback, SDK-verified structured Foundation Models output, OCR, metadata, and a coordinator that updates but never deletes an item.

- [ ] Add tests for deterministic titles/tags, unavailable-model fallback, thrown-enricher preservation, state transitions, and manual context correction.
- [ ] Run tests and confirm failures for absent behavior.
- [ ] Implement fallback first, then the Foundation Models adapter using `SystemLanguageModel.default.availability`, `LanguageModelSession`, `@Generable`, and `respond(to:generating:)`.
- [ ] Add best-effort URL metadata, Vision OCR, media file/thumbnail storage, embedding persistence, safe context assignment, and retry.
- [ ] Run tests until green, then commit `feat: add local enrichment pipeline`.

### Task 4: Share Extension

**Files:** `Capture/Shared/SharePayloadParser.swift`, `CaptureShareExtension/ShareViewController.swift`, `CaptureTests/SharePayloadParserTests.swift`, extension plist and entitlements.

**Interfaces:** Produce `SharePayload`, pure normalization helpers, async `NSItemProvider` parsing, and extension persistence through the shared store.

- [ ] Add tests for text, URL, and image payload normalization and priority.
- [ ] Run tests and confirm missing-symbol failures.
- [ ] Implement the parser and a minimal UIKit success/error view controller that stores media, saves once, and completes without enrichment.
- [ ] Run tests and build the extension target, then commit `feat: support share extension capture`.

### Task 5: Native application UI

**Files:** `Capture/App/CaptureApp.swift`, `Capture/App/Views/*.swift`, `CaptureUITests/CaptureUITests.swift`.

**Interfaces:** Produce Home, capture sheet, recent rows, search, context detail/rename, item detail/reassignment/retry, and Settings/About.

- [ ] Add a UI smoke test using stable accessibility identifiers for launching, entering capture text, saving, and finding it on Home.
- [ ] Run it and confirm failure before the app flow exists.
- [ ] Implement the smallest native SwiftUI flow for all required screens and image/URL/text capture; dismiss immediately after persistence and enrich asynchronously.
- [ ] Run unit tests and the UI smoke test until green, then commit `feat: add native capture experience`.

### Task 6: Documentation and complete verification

**Files:** `README.md`, generated `Capture.xcodeproj`.

**Interfaces:** Document requirements, build steps, App Group signing, extension use, AI/embedding fallback, search, and known limits.

- [ ] Generate the final project and inspect the diff for credentials, accidental scope, and warnings.
- [ ] Run a clean full test on a discovered iPhone simulator and a separate extension build.
- [ ] Fix each failure with a reproducing test when it concerns production behavior, rerun full verification, and record exact remaining physical-device checks.
- [ ] Update README from verified commands and commit `docs: add Capture build and architecture guide`.
