# Product

<!-- impeccable:product-schema 1 -->

> Product facts below are inferred directly from the approved MVP brief supplied on 2026-09-02; no additional interview was run because the brief directs autonomous implementation without product questions.

## Platform

ios

## Stack

Swift, SwiftUI, SwiftData, Foundation Models, NaturalLanguage, Vision, UniformTypeIdentifiers, LinkPresentation, and native Apple testing tools. No third-party runtime dependencies.

## Users

The primary user is an iPhone owner who currently scatters useful information across screenshots, tabs, bookmarks, notes, and chats and wants to capture it without maintaining an organization system.

## Product Purpose

Capture makes saving text, URLs, and images nearly immediate, organizes them into flexible contexts on-device, and makes them retrievable later without remembering where they were filed. The MVP succeeds when it becomes the instinctive place to throw useful things.

## Positioning

Capture treats organization as an on-device inference followed by optional user correction, rather than a folder, tag, or database-design task imposed before saving.

## Operating Context

Users capture inside the app or from the iOS share sheet, often while browsing Safari or Photos. Captures must succeed offline and remain useful when Apple Intelligence, OCR, link metadata, or sentence embeddings are unavailable.

## Capabilities and Constraints

The MVP supports text, URL, and image capture; App Group-backed local persistence; OCR and lightweight link metadata; structured Foundation Models enrichment with deterministic fallback; conservative context reuse or Inbox fallback; semantic plus lexical search; context rename/reassignment/creation; retryable enrichment; on-device proposed events, reminders, and follow-ups; and user-driven approval flows that write to Calendar or Reminders only after an explicit tap (with permission prompts on first approval). Capture proposes actions only and is not a task manager. It has no accounts, backend, sync, external AI, agents, collaboration, subscriptions, analytics, or custom hierarchy.

## Brand Commitments

`Capture` is a temporary, easily replaceable name. The app should feel like a highly native Apple utility: minimal, calm, direct, and never like a generic SaaS dashboard or over-designed productivity system.

## Evidence on Hand

The repository contains the approved MVP specification and deterministic domain tests. There are no logos, custom brand assets, testimonials, claims, or external reference designs; future work must not fabricate them.

## Product Principles

- Persist first; enhancement may fail but the capture must survive.
- AI organizes; the user remains the authority.
- Unsorted is better than confidently wrong.
- Local-first means capture content never leaves the device.
- The smallest complete capture-and-retrieval loop wins over speculative platform work.

## Accessibility & Inclusion

Use Dynamic Type, VoiceOver labels, 44-point minimum targets, semantic colors, dark mode, Reduce Motion-aware transitions, and native interaction conventions.
