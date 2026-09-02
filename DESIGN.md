---
name: Capture
description: A calm native iOS intake utility for saving first and organizing later.
colors:
  system-tint: "light-dark(#007aff, #0a84ff)"
  canvas: "light-dark(#ffffff, #000000)"
  grouped-ground: "light-dark(#f2f2f7, #000000)"
  grouped-surface: "light-dark(#ffffff, #1c1c1e)"
  label-primary: "light-dark(#000000, #ffffff)"
  label-secondary: "light-dark(#8e8e93, #98989d)"
  fill-quaternary: "light-dark(rgba(116, 116, 128, 0.08), rgba(118, 118, 128, 0.18))"
  on-tint: "#ffffff"
typography:
  display:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.21
  headline:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.29
  body:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.29
  subheadline:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.33
  caption:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.33
  title3:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "20px"
    fontWeight: 400
    lineHeight: 1.25
rounded:
  thumbnail: "9px"
  media: "12px"
  capsule: "999px"
spacing:
  compact: "2px"
  standard: "12px"
  edge: "16px"
components:
  button-primary:
    backgroundColor: "{colors.system-tint}"
    textColor: "{colors.on-tint}"
    typography: "{typography.headline}"
    rounded: "{rounded.capsule}"
    width: "100%"
  capture-thumbnail:
    backgroundColor: "{colors.fill-quaternary}"
    textColor: "{colors.system-tint}"
    rounded: "{rounded.thumbnail}"
    size: "44px"
  topic-chip:
    backgroundColor: "{colors.fill-quaternary}"
    textColor: "{colors.label-primary}"
    typography: "{typography.subheadline}"
    rounded: "{rounded.capsule}"
    padding: "6px 10px"
  media-preview:
    rounded: "{rounded.media}"
    width: "100%"
---

# Design System: Capture

## Overview

**Creative North Star: "The Native Intake Utility"**

Capture feels like an Apple utility that was already waiting on the device: immediate, quiet, and legible. Native navigation, controls, semantic colors, SF Symbols, inset lists, forms, and system typography do the visual work; the product does not layer a separate brand costume over them.

The hierarchy serves one story: save first, then let on-device understanding organize the result. A single full-width tint action leads the home surface, while contexts, captures, metadata, and correction tools settle into familiar system structures. Density stays compact at default sizes and expands naturally under Dynamic Type rather than being held to a fixed composition.

**Key Characteristics:**

- System-native and appearance-adaptive.
- One prominent tint action; supporting actions remain standard navigation or form controls.
- Content-led inset lists and forms rather than dashboard panels.
- SF Symbols and semantic system text styles throughout.
- Dynamic Type, VoiceOver, and native control behavior are part of the visual system.

## Colors

The palette is the iOS semantic palette: a single system tint over adaptive system grounds, surfaces, labels, and fills.

### Primary

- **System Tint:** Marks the quick-capture action, context and content symbols, links, and other interactive emphasis. Its light and dark appearances remain platform-controlled.

### Neutral

- **Canvas:** The navigation and page ground outside grouped content.
- **Grouped Ground:** The inset-list and form field behind grouped sections.
- **Grouped Surface:** The raised grouping surface used by list rows and empty-state containers.
- **Primary Label:** Carries titles, body copy, and control labels at full emphasis.
- **Secondary Label:** Carries descriptions, counts, timestamps, section labels, and progress context.
- **Quaternary Fill:** Gives thumbnails and topic capsules quiet separation without becoming a second accent.
- **On Tint:** Keeps the primary action legible over the system tint.

### Named Rules

**The System Semantics Rule.** Use Apple semantic roles and the platform tint; never freeze a light-mode value across appearances.

## Typography

**Display Font:** SF Pro via the system large-title style  
**Body Font:** SF Pro via the system body style  
**Label Font:** SF Pro via native control and caption styles

**Character:** The ramp is unmodified iOS typography: a strong navigation title, semibold item and action headlines, comfortable body text, and restrained secondary metadata. Every role is semantic so the system, not a fixed mock, owns Dynamic Type scaling.

### Hierarchy

- **Display:** The large navigation title on top-level destinations.
- **Headline:** The quick-capture label, capture titles, and empty-state title.
- **Title:** Title-3 sizing is reserved for symbolic thumbnail content where the glyph needs more visual weight.
- **Body:** Default form values, list content, descriptions, and selectable captured text.
- **Subheadline:** Summaries, context descriptions, extracted text, and topic chips.
- **Caption:** Context, time, and processing metadata below capture titles.

### Named Rules

**The System Voice Rule.** Use semantic system styles so hierarchy remains native and Dynamic Type remains authoritative.

## Layout

Top-level screens use a `NavigationStack`; content screens use inset-grouped `List` or `Form` containers. The home screen alone places the primary action above the list, using the edge inset and standard vertical rhythm from the token scale. Rows use a leading 44-point thumbnail, a 12-point content gap, and vertically stacked title, summary, and metadata.

The spatial model is single-column and fluid. Controls and rows expand vertically when Dynamic Type wraps, horizontal topic chips scroll rather than compress, image previews fit proportionally, and platform safe areas govern all screen edges. Interactive controls retain at least a 44-point target.

## Elevation & Depth

There are no custom shadows. Depth comes from adaptive grouped-surface contrast and OS-owned materials on navigation chrome, sheets, alerts, menus, segmented controls, and buttons. This lets the current iOS visual language, including material changes between OS releases, remain authoritative.

### Named Rules

**The Platform Depth Rule.** Let navigation chrome, sheets, lists, and controls receive depth from system materials; do not add custom shadows.

## Shapes

Shapes follow native control geometry. The prominent action and topic tags use capsule silhouettes; capture thumbnails use the smaller rounded rectangle; captured and selected media use the broader rounded rectangle. Lists, forms, toolbar groups, search fields, segmented controls, sheets, and alerts inherit their corners from the platform.

### Named Rules

**The Content Geometry Rule.** Reserve explicit rounded rectangles for media and thumbnails; let standard controls inherit their native silhouette.

## Components

### Buttons

- **Primary:** One full-width, large bordered-prominent button with a filled plus-circle symbol and headline label. It uses the system tint and remains above the home list.
- **Secondary:** Save, cancel, rename, create, retry, and new-context actions use standard SwiftUI button roles and placements.
- **States:** Press, focus, disabled, hover, and confirmation behavior remain native. Save disables until content is valid or while work is in progress.

### Segmented Picker

- **Style:** A native segmented picker switches between Text, URL, and Image capture modes.
- **State:** The selected segment uses platform selection treatment; no parallel custom tab style is introduced.

### Chips

- **Style:** Topics are content-sized subheadline labels on quaternary fill with capsule geometry and compact insets.
- **Behavior:** The chip row scrolls horizontally with hidden indicators; chips are informational, not a second navigation system.

### Cards / Containers

- **Style:** Inset-grouped lists and forms supply the recurring container language. Grouped surfaces separate content from grouped ground without borders or custom shadows.
- **Empty State:** Native `ContentUnavailableView` combines one SF Symbol, one headline, and concise secondary guidance inside the list surface.

### Inputs / Fields

- **Style:** Capture uses native `TextEditor`, `TextField`, `PhotosPicker`, alert text fields, pickers, and searchable navigation fields.
- **Focus and Error:** Keyboard, focus, clear, disabled, and error behavior remain native. Error text uses the semantic destructive color only at the point of failure.

### Navigation

- **Style:** Large titles identify top-level destinations; detail and modal titles use inline display where implemented. Trailing toolbar actions use labeled SF Symbols, and rows use `NavigationLink` disclosure behavior.
- **Search:** Search is a dedicated destination with a persistent native search field and native unavailable states before and after a query.

### Capture Row

- **Style:** A 44-point media or symbol thumbnail leads a flexible text stack. Headline title, optional secondary summary, then caption metadata establish a stable scan order; processing and failure indicators live in the metadata line.

## Do's and Don'ts

### Do:

- **Do** build new surfaces from native SwiftUI navigation, list, form, control, and feedback patterns.
- **Do** use semantic colors, SF Symbols, and semantic text styles so light mode, dark mode, and Dynamic Type stay coherent.
- **Do** keep one clearly dominant capture action and place secondary actions in their expected navigation or form locations.
- **Do** preserve 44-point minimum targets, useful VoiceOver labels, and content that reflows rather than clips.

### Don't:

- **Don't** introduce folder-first navigation, dashboard furniture, or a custom productivity-app shell.
- **Don't** add custom display faces, decorative icon sets, gradients, hard offset shadows, or ornamental labels.
- **Don't** hard-code light-only colors, fixed text sizes, or fixed-height containers around variable copy.
- **Don't** replace native control states and materials with lookalike custom components without a demonstrated product need.
