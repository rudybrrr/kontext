# Changelog

## Week 4 — Visibility

- Added the Kontext marketing site (`/site`) with hero, how-it-works, privacy summary, eval results table, TestFlight CTA, and changelog feed.
- Added `EVALS.md` cross-links from the README and a `docs/DEMO_SCRIPT.md` shot list for a 60–90s product demo.

## Eval suite

- Added `CaptureEvals` labelled fixtures (`Evals/captures.json`, `Evals/search_queries.json`) and on-device metrics for extraction and search quality.
- Documented targets and device run instructions in `EVALS.md`.

## Week 3 — Background & URL depth

- URL “Read …” follow-up proposals, Share Extension “Remind me” intent flag, webpage body extraction for enrichment, and `BGProcessingTask` background draining.
- Settings surface for on-device action extraction (Foundation Models vs deterministic).

## Week 2 — Approval UI & EventKit

- Suggested-action cards, Home “Needs review” list, write-only Calendar and Reminders approval flows, and deep links after approval.
- `ActionCommitting` protocol with EventKit implementation and unit tests.

## Week 1 — Capture, then act (foundation)

- `ProposedAction` SwiftData model, deterministic and Foundation Models action extractors, merger rules, and enrichment pipeline stage.
- Documentation updates for propose-only, user-approves behaviour; no external writes without approval.
