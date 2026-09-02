# Kontext Product Specification

**Status:** Active product specification
**Product:** Kontext
**Platform:** iPhone first, Mac companion later
**Current stage:** Post-MVP technical prototype
**Last updated:** September 2026

---

# 1. Product Thesis

Kontext is a local-first, AI-native capture and personal context system.

Its central promise is:

> Throw almost anything into Kontext. It preserves it, understands it, organises it, and helps you find it again without requiring you to maintain a filing system.

Traditional note-taking and personal knowledge management tools make organisation a user responsibility.

The user must decide:

* where something belongs
* which folder to use
* which database to maintain
* which tags to apply
* how to structure projects
* when to reorganise everything
* how to find something months later

Kontext should remove most of this work.

The user captures first.

The system handles organisation by default.

The human remains in control whenever the system is wrong.

---

# 2. Core Product Loop

Every captured object should pass through one conceptual pipeline:

```text
CAPTURE
   ↓
PRESERVE ORIGINAL
   ↓
UNDERSTAND
   ↓
ORGANISE
   ↓
INDEX
   ↓
RETRIEVE
   ↓
RESURFACE / USE
```

The most important invariant is:

> Kontext must never lose the original information simply because an AI, OCR, transcription, extraction, embedding, network, or enrichment process failed.

Persist first.

Enhance second.

---

# 3. Product Principles

## 3.1 Capture must be easier than organisation

Capturing useful information should require almost no thought.

Users should not need to determine where something belongs before saving it.

## 3.2 Organisation should happen automatically

AI and deterministic systems should infer:

* what the item is
* what it means
* what topics it relates to
* which existing context it belongs to
* whether a new context is justified
* how useful it may be later

Manual organisation remains available but should not be required.

## 3.3 Human authority beats AI confidence

Users must always be able to:

* correct a context
* rename a context
* merge or separate information
* pin something
* move something
* mark something as unrelated
* return something to Inbox

Kontext assists organisation. It does not own the user's information architecture.

## 3.4 Contexts are not folders

The primary organisational abstraction is a **Context**.

A Context represents:

> A collection of information that currently makes sense together.

Examples:

```text
mybrowser
browser sidebar redesign
DSAA
Kontext
UI inspiration
PSA Code Sprint
SwiftUI research
```

Contexts may be created automatically or manually.

They are not required to form a rigid hierarchy.

Relationships may eventually form a graph.

## 3.5 The app should get better without demanding maintenance

A good Kontext user should spend their time capturing and using information, not maintaining Kontext itself.

---

# 4. Core Domain Model

## CaptureItem

A CaptureItem represents anything stored in Kontext.

Possible information includes:

```text
id
createdAt
updatedAt
kind
UTType
originalFilename
sourceURL
localAssetPath
rawText
extractedText
transcription
title
summary
topics
entities
context
contextConfidence
enrichmentState
embedding
metadata
```

The exact schema may evolve.

The important rule is that all input types eventually converge into the same knowledge and retrieval pipeline.

## Context

A Context represents related information.

Possible information includes:

```text
id
name
description
createdAt
updatedAt
pinned
items
embedding
activity metadata
```

Contexts should support both automatic and manual creation.

## Inbox / Unsorted

When Kontext cannot confidently determine where something belongs, the correct behaviour is:

> Inbox

Not:

> invent another low-quality context.

Uncertainty should be represented honestly.

---

# 5. Milestone 0: Technical MVP

The existing implementation already proves several foundations.

Current capabilities include:

* SwiftUI application
* local persistence
* basic CaptureItem model
* text capture
* URL capture
* image capture
* iOS Share Extension
* basic enrichment
* automatic context assignment
* semantic/local search
* Foundation Models integration with fallback
* automated unit tests
* automated UI tests
* simulator verification

This milestone proved that the architecture is feasible.

It did **not** prove that Kontext is already a useful product.

The current application should be treated as a technical foundation.

---

# 6. Milestone 1: Universal Capture

This is the immediate next product milestone.

Kontext cannot become the user's default capture destination until it can reliably accept most information the user encounters.

The goal is:

> If something is useful, there should almost always be a way to throw it into Kontext.

## 6.1 User-facing capture surface

The primary capture interface should expose five simple actions:

```text
Write
Record
Photo
Link
File
```

Users should not need to understand MIME types, UTTypes, document formats, or internal CaptureItem kinds.

### Write

Support:

* plain text
* multiline notes
* pasted text
* Markdown
* imported `.txt`
* imported `.md`

Markdown should remain plain and portable.

A complicated rich-text editor is not required.

### Record

Support:

* voice recording
* pause/resume where practical
* stop
* playback
* duration
* persisted audio
* local transcription
* transcription status
* failed-transcription fallback
* imported audio files

The audio file must survive even when transcription fails.

The transcription becomes canonical searchable content.

### Photo

Support:

* Photos picker
* screenshots
* imported images
* Share Sheet images
* original image preservation
* thumbnails
* Vision OCR
* image metadata

Multimodal understanding may enhance image comprehension when supported, but OCR and storage must work without it.

### Link

Support:

* pasted URLs
* Safari Share Sheet
* shared links from other applications
* source URL preservation
* title
* description
* preview metadata
* representative image where available
* useful webpage text extraction where practical

Saving a URL must never depend on successful network retrieval.

### File

Support importing from Files/iCloud Drive and receiving shared files.

At minimum support intelligent extraction for:

* PDF
* plain text
* Markdown
* RTF
* HTML
* supported Word / Office Open XML documents
* supported OpenDocument text
* audio files
* images

Unknown files should still be capturable.

Unsupported formats should preserve:

* original file
* filename
* UTType
* extension
* size
* metadata
* thumbnail where available

"Captured but not understood" is better than "cannot capture."

---

# 7. Milestone 2: Context Organisation

Universal Capture provides information.

This milestone makes the information manageable.

Kontext should automatically infer useful contexts from captured information.

Example:

```text
Capture:
Pinterest screenshot of a vertical browser sidebar

Possible result:
Context: mybrowser
Subtopic/relationship: sidebar redesign
Type: UI inspiration
```

Users should be able to:

* create contexts
* rename contexts
* pin contexts
* reassign items
* send items to Inbox
* merge contexts
* correct wrong assignments
* inspect which items belong to a context

Nested folder management should not become the primary model.

## Context creation control

Kontext must actively avoid context explosion.

Before creating a new context, the system should consider:

* semantic similarity to existing contexts
* lexical similarity
* recent context activity
* known relationships
* confidence

A weak match should go to Inbox instead of generating a meaningless new context.

---

# 8. Milestone 3: Retrieval

Saving information is worthless if finding it later remains difficult.

Retrieval should support multiple strategies.

## Exact search

Useful for:

```text
SwiftData
AVL tree
Arc
BuilderLab
```

## Semantic search

Useful for:

```text
that dark browser sidebar I liked

the thing about Swift concurrency

the tree algorithm material

that design reference from Pinterest
```

## Contextual browsing

Users should be able to enter a context and inspect everything currently related to it.

## Recency

Recent information should be easy to recover without searching.

## Original-source access

Every result must make it easy to return to:

* original webpage
* original image
* original file
* original recording
* original note

AI-generated metadata should never replace the source itself.

---

# 9. Milestone 4: Resurfacing

Traditional PKM systems depend heavily on the user remembering to search them.

Kontext should eventually become more useful by surfacing relevant information at useful moments.

Examples:

```text
You are working on mybrowser again.

Kontext surfaces:
3 sidebar references you saved previously.
```

or:

```text
You reopened your Kontext project.

Last unresolved idea:
"Should contexts behave like dynamic clusters instead of folders?"
```

Resurfacing must remain relevant and restrained.

The product must not turn into a notification spam system.

This milestone comes only after capture, organisation, and retrieval are strong.

---

# 10. Milestone 5: Core Application Experience

The application itself must become pleasant enough to live in daily.

## Home

Home should eventually contain:

```text
Search
Capture anything
Inbox / Unsorted
Pinned / active contexts
Recent captures
Relevant resurfaced information
```

Do not turn Home into a dashboard full of cards.

## Capture

Capture should feel instant.

The application should visually communicate:

```text
Captured
Understanding…
Organised into Kontext
```

without making the user wait.

## Item Detail

Item detail adapts to content type.

Text:

* readable source

Link:

* metadata
* preview
* original URL
* useful extracted content

Image:

* image
* OCR
* metadata

Audio:

* playback
* duration
* transcription

Document:

* preview
* original file
* extracted content

Every item should expose:

* title
* summary
* context
* created date
* organisation correction
* enrichment state

## Context Detail

Show:

* context name
* optional description
* related captures
* recent activity
* organisation controls

---

# 11. Milestone 6: Onboarding

Onboarding should only be designed once the core product is strong enough to explain.

It should demonstrate the behaviour rather than explain AI architecture.

Potential onboarding loop:

```text
Save something
↓
Kontext understands it
↓
Kontext organises it
↓
Find it again
```

Avoid long onboarding questionnaires.

Avoid forcing users to create a taxonomy before using the application.

---

# 12. Milestone 7: Accounts and Sync

Accounts are not required while Kontext is being developed and dogfooded locally.

Eventually accounts may support:

* authentication
* account ownership
* multiple devices
* encrypted cloud synchronisation
* restoration
* future web access

Privacy architecture must be considered before implementation.

Local-first behaviour should remain an important property even after syncing exists.

---

# 13. Milestone 8: Mac Companion and Relay

Kontext should eventually expand from an iPhone capture tool into an Apple ecosystem context layer.

The Mac application should not simply display the same database on a larger screen.

Its major future value is **Relay**.

Relay transfers working context between devices.

Example:

```text
iPhone:
research browser sidebar designs during commute

Mac:
Continue "mybrowser sidebar redesign"

Saved:
6 references

Current direction:
vertical navigation

Unresolved:
ephemeral vs persistent tabs
```

This is state continuity, not simple file syncing.

Mac development should not begin until the iPhone product is worth using independently.

---

# 14. Milestone 9: Intent

Intent is a future natural-language command layer over Kontext.

Examples:

```text
Remember this for my browser project.

Show me the sidebar references I saved.

Save this and bring it back when I work on DSAA.

What did I save about Swift concurrency?
```

Possible surfaces eventually include:

* App Intents
* Siri
* Shortcuts
* Action Button
* Spotlight
* widgets

Intent should act on the same context system rather than becoming a separate chatbot.

---

# 15. Milestone 10: Agent and Tool Interoperability

Kontext should eventually become usable context for AI tools instead of remaining an isolated information silo.

Potential consumers include:

* Codex
* Claude Code
* Claude
* ChatGPT
* Cursor
* Grok
* local agents
* developer tools
* future personal agents

Possible future interfaces include:

* MCP
* local API
* controlled context export
* scoped project access
* user-approved retrieval
* structured context packages

Example:

```text
Codex asks Kontext:

"Give me the relevant context for the mybrowser sidebar redesign."

Kontext provides:
- selected references
- prior decisions
- notes
- screenshots
- unresolved questions
```

Access must be explicit, scoped, inspectable, and revocable.

---

# 16. Future Attention Layer: Drift

Drift is a possible later layer of Kontext.

It compares:

```text
what the user intends to be doing
```

with:

```text
what their digital behaviour suggests they are doing
```

Example:

```text
Intent:
Study DSAA for one hour

Relevant:
lecture slides
AVL tree videos
Python
notes

Potential drift:
Instagram
Reddit
unrelated YouTube
```

Drift could eventually use contextual knowledge from Kontext to determine relevance more intelligently than simple Screen Time limits.

It is explicitly **not part of the current product milestones**.

---

# 17. Automation

Automation may eventually allow Kontext to act when useful.

Examples:

```text
When this project becomes active again, surface these references.

When I reach my Mac, make this context available.

When a captured item matches an existing project, organise it automatically.

Periodically identify duplicate or stale contexts.
```

Automation comes after Kontext has reliable context.

Automating a weak context model would only automate mistakes.

---

# 18. Privacy

Kontext contains highly personal information.

Privacy is therefore a product requirement, not merely a legal requirement.

The architecture should favour:

* local processing
* on-device AI where practical
* transparent storage
* minimal data collection
* explicit external access
* clear permission boundaries

No captured data should silently become training data for external services.

External AI providers should only be introduced deliberately and with clear user control.

---

# 19. What Kontext Is Not

Kontext is not currently trying to become:

* another Todoist
* another Notion clone
* another Apple Notes clone
* another generic AI chatbot
* a calendar
* a habit tracker
* a Screen Time clone
* a project-management platform
* an AI wrapper around a CRUD database

Tasks, calendar, finance, productivity analytics, and other vertical features should only be considered if they naturally emerge from the context system later.

---

# 20. Product Completion Threshold

Kontext starts making sense as a real product when these four capabilities are strong:

## A. Universal Capture

I can throw almost anything useful into it.

## B. Automatic + Human Organisation

I rarely need to organise manually, but I can easily correct the system.

## C. Retrieval

I can find something without remembering exactly how or where it was stored.

## D. Pleasant Daily UX

Using Kontext is lower-friction than leaving information scattered across screenshots, tabs, bookmarks, Notes, Files, and chats.

Until A-D are strong, features such as agents, Mac continuity, automations, authentication, and Drift are secondary.

---

# 21. Immediate Development Priority

The next development milestone is:

> **Milestone 1: Universal Capture**

Do not implement future milestones merely because the architecture could support them.

The immediate product question is:

> Can Kontext become the place I instinctively throw useful information because almost anything can be captured quickly and safely?

Once Universal Capture is complete, dogfood the application before selecting the next implementation milestone.

---

# 22. Development Rule

Every implementation task should be evaluated against one question:

> Does this make Kontext substantially better at capturing, understanding, organising, retrieving, or using personal context?

If not, it probably does not belong yet.
