# Capture MVP Specification

## Product

Capture is an iPhone-first, local-first utility for quickly saving text, URLs, and images, automatically enriching and grouping them into flexible contexts, and finding them later with natural language.

The working name and identifiers are temporary:

- App: `Capture` / `com.rudy.capture`
- Share extension: `CaptureShareExtension` / `com.rudy.capture.share`
- App Group: `group.com.rudy.capture`

## Approved scope

The MVP includes only capture, shared local persistence, on-device content extraction and enrichment, automatic context assignment, local semantic plus lexical search, an iOS Share Extension, and manual context correction.

It excludes accounts, backend or cloud sync, external AI, agents, integrations, social/collaboration features, subscriptions, Mac/continuity features, and knowledge-graph visualization.

Capture may propose calendar events, reminders, and follow-ups from captured text, but only as user-approved suggestions. Apple Calendar and Reminders hold approved data; Capture is not a task manager and never writes events or reminders externally without explicit user approval.

## Capture and storage

- Capture text, URLs, and Photos images inside the app.
- Accept text, URLs, and images in the Share Extension.
- Store every item before optional enrichment so enrichment failure cannot lose it.
- Store SwiftData in the shared App Group container and media as files in that container.
- Represent enrichment as `pending`, `processing`, `completed`, `partial`, or `failed` and permit retries.

`CaptureItem` stores identity and dates, kind, original text or URL, media paths, extracted text, title, summary, tags, enrichment state, embedding data, context relationship, and assignment confidence. `CaptureContext` stores identity and dates, name, summary, pin state, and its item relationship. Contexts are clusters, not folders. A single Inbox context is the safe fallback.

## Understanding and organization

- Text uses its body as canonical text.
- URLs remain usable offline; native link metadata is a best-effort enhancement.
- Images are copied into shared storage and OCR runs later with Vision.
- Foundation Models structured generation supplies title, summary, tags, and a context suggestion only when the on-device model and locale are available.
- A deterministic enricher always remains available.
- Suggested new contexts are compared with existing ones before creation; uncertain assignments go to Inbox.
- Users can rename contexts, create one manually, and reassign any item.

## Retrieval

NaturalLanguage sentence embeddings are encoded as `Data`. Search combines cosine similarity with case-insensitive lexical matches and stable date/UUID tie-breaking. Lexical-only search remains available when the language embedding is missing.

## UI

SwiftUI provides a native `NavigationStack` home with quick capture, recent contexts, recent captures, dedicated search, context detail, item detail, correction/retry controls, and a small settings/about screen. UI uses system controls, Dynamic Type, dark mode, and accessibility labels/identifiers.

## Verification

The app and extension must build for the installed iOS 26 simulator SDK. Unit tests cover persistence, vectors, ranking, assignment, fallback enrichment, proposed-action extraction and merging, and share-payload normalization. A UI smoke test launches the app, saves text, and finds it on Home. Foundation Model outputs are never test dependencies.

## Known MVP boundaries

There is no sync, background daemon, external API, custom hierarchy, camera capture, or correction-learning system. Link metadata needs network access but capture does not. Share-extension items are enriched when the main app next runs.
