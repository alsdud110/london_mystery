# London Mystery — Claude Code Project Instructions

## 1. Project Overview

London Mystery is a mobile mystery/adventure game built with Flutter.

The goal is to create a polished, immersive, premium-feeling mobile game rather than a generic Flutter application.

The visual identity should feel:

* Mysterious
* Atmospheric
* Elegant
* Story-driven
* Slightly vintage / British
* Cinematic
* Premium
* Intuitive for mobile users

Avoid making the UI look like a generic productivity app, admin dashboard, or ordinary mobile utility app.

---

# 2. Design Skill Strategy

The project has the following design skills installed:

* `design-taste-frontend`
* `mobile-ios-design`
* `mobile-android-design`
* `impeccable`

Use them according to the following hierarchy.

### Primary Design Direction

Use `design-taste-frontend` as the primary source of visual design direction.

It should establish:

* Overall visual language
* Color system
* Typography
* Spacing
* Component styling
* Visual hierarchy
* Composition
* Overall UI polish

Do not allow platform-specific conventions to unnecessarily override the game's established visual identity.

### Platform Design

Use `mobile-ios-design` and `mobile-android-design` for platform-specific interaction and usability considerations.

They should influence:

* Navigation behavior
* Touch targets
* Gestures
* Platform conventions
* System UI integration
* Accessibility
* Mobile interaction patterns

Do NOT automatically redesign the entire visual appearance according to iOS or Android conventions.

London Mystery is a game, so game identity takes priority over generic platform UI.

### Final Polish

Use `impeccable` when reviewing or improving an existing UI.

It should be used to identify and improve:

* Visual hierarchy
* Spacing
* Typography
* Contrast
* Alignment
* Component consistency
* Unnecessary visual clutter
* Weak visual emphasis
* Generic-looking UI
* Overall perceived quality

Do not introduce unnecessary redesigns if the existing design already serves the game's visual identity.

---

# 3. Design Priority

When design principles conflict, use this priority:

1. Game identity and immersion
2. Usability and clarity
3. Consistent project design system
4. Mobile platform conventions
5. Decorative effects

Never sacrifice usability merely for visual decoration.

Never sacrifice the game's atmosphere merely to imitate a standard mobile application.

---

# 4. London Mystery Visual Direction

The UI should evoke the feeling of investigating a mysterious story in London.

Possible visual references include:

* Old London
* Detective notebooks
* Case files
* Newspaper clippings
* Letters
* Seals
* Maps
* Evidence boards
* Vintage typography
* Subtle paper textures
* Brass / antique details
* Dim atmospheric lighting
* Cinematic shadows
* Elegant British interiors

However, these elements must be used subtly.

Avoid excessive:

* Paper textures
* Noise
* Grunge
* Decorative borders
* Shadows
* Gold effects
* Victorian ornaments

The result should feel modern and premium, not like a cheap "old paper" theme.

---

# 5. UI Principles

Every screen should have a clear visual hierarchy.

Users should immediately understand:

1. Where they are
2. What the current objective is
3. What they can interact with
4. What action is primary
5. What information is secondary

Interactive elements must visually communicate that they are interactive.

Avoid:

* Ambiguous buttons
* Tiny touch targets
* Excessive text
* Inconsistent spacing
* Random font sizes
* Random colors
* Excessive rounded cards
* Generic Material UI appearance
* Generic Cupertino appearance

---

# 6. Mobile Interaction

Design for one-handed mobile use where practical.

Interactive controls should have comfortable touch areas.

Prefer:

* Large enough touch targets
* Clear pressed states
* Subtle feedback
* Smooth transitions
* Predictable navigation
* Minimal unnecessary gestures

Do not introduce gestures merely because they look impressive.

Every animation or interaction should communicate something useful.

---

# 7. Animation

Animations should feel cinematic and intentional.

Prefer:

* Subtle fade
* Slide transitions
* Scale feedback
* Parallax
* Layered reveals
* Sequential clue/evidence presentation
* Soft transitions between story scenes

Avoid:

* Excessive bouncing
* Cartoonish animations
* Long transitions
* Constant motion
* Animations that delay gameplay
* Decorative animation with no purpose

Animation should enhance mystery and storytelling rather than distract from it.

---

# 8. Typography

Typography is a major part of the game's atmosphere.

Use a limited and consistent typography system.

Define clear roles such as:

* Display / chapter title
* Screen title
* Section heading
* Body
* Caption
* Button
* Evidence / clue text

Do not randomly introduce fonts for individual screens.

Typography must remain readable on small mobile screens.

Decorative fonts should be reserved for titles or special story elements, not long-form body text.

---

# 9. Color System

Do not introduce arbitrary colors directly into widgets.

Prefer a centralized design system.

Colors should communicate:

* Background
* Surface
* Primary action
* Secondary action
* Text
* Muted text
* Accent
* Success
* Warning
* Error
* Evidence / clue states

Maintain sufficient contrast.

The accent color should be used intentionally rather than everywhere.

---

# 10. Components

Prefer reusable components over duplicated UI implementations.

Before creating a new component, check whether an existing project component can be reused.

Common components should remain visually consistent:

* Buttons
* Cards
* Dialogs
* Bottom sheets
* Tabs
* Navigation
* Evidence cards
* Clue cards
* Character panels
* Story panels
* Input fields
* Progress indicators

If a component is modified, consider whether the change should apply consistently throughout the application.

---

# 11. Storytelling UI

UI is part of the storytelling.

Whenever appropriate, use visual hierarchy to reinforce narrative importance.

Examples:

* Important clues receive stronger visual emphasis.
* Newly discovered evidence can have a subtle reveal animation.
* Important dialogue can receive stronger typography.
* Case progression can visually communicate investigation progress.
* Letters and documents can feel like physical artifacts without sacrificing readability.

Do not turn every piece of information into a card.

Not everything needs a container, border, shadow, or rounded rectangle.

---

# 12. Asset Usage

Use existing project assets when they meaningfully contribute to the screen.

Do not force every asset into the UI.

If an asset does not fit the scene, story, puzzle, or visual composition, leave it unused.

Asset selection should prioritize:

1. Narrative relevance
2. Visual composition
3. Consistency
4. Technical quality

Never add an asset merely because it exists.

---

# 13. Flutter Implementation

Keep visual design decisions separate from business logic where practical.

Prefer:

* Theme-based colors
* Theme-based typography
* Reusable widgets
* Design tokens
* Centralized spacing
* Centralized dimensions
* Reusable animation definitions

Avoid:

* Hard-coded colors scattered throughout widgets
* Hard-coded spacing everywhere
* Duplicated UI code
* Screen-specific versions of identical components
* Unnecessary architectural rewrites during visual improvements

When modifying UI, preserve existing functionality unless the task explicitly requires functional changes.

---

# 14. Existing Functionality Comes First

When improving visual design:

DO NOT break:

* Navigation
* Game state
* Puzzle logic
* Save/load behavior
* Asset loading
* Story progression
* Existing interactions
* Tests

Before making large changes, inspect the existing implementation.

Prefer incremental improvements over unnecessary rewrites.

---

# 15. Responsive Design

The game must work across common mobile screen sizes.

Consider:

* Small phones
* Large phones
* Different aspect ratios
* Portrait orientation
* Safe areas
* System navigation areas

Do not rely on fixed pixel positioning when responsive layout can be used.

Avoid layouts that only look correct on one emulator size.

---

# 16. Accessibility

Maintain reasonable accessibility without destroying the game's visual identity.

Consider:

* Text readability
* Contrast
* Touch target size
* Semantic labels
* Dynamic text considerations
* Motion sensitivity where appropriate

Accessibility improvements should be integrated naturally into the existing design.

---

# 17. Before Changing a Screen

Before modifying an existing screen:

1. Inspect the current implementation.
2. Identify the screen's purpose.
3. Identify the primary user action.
4. Identify existing reusable components.
5. Identify existing design tokens/theme values.
6. Check whether assets already exist.
7. Preserve existing functionality.
8. Then make the visual improvements.

Do not blindly rewrite the screen.

---

# 18. Design Review Checklist

Before considering a UI task complete, verify:

### Visual

* Is the hierarchy obvious?
* Does the screen feel like London Mystery?
* Is the design cohesive with the rest of the game?
* Are spacing and alignment consistent?
* Are typography choices consistent?
* Are colors intentional?
* Is the UI too generic?

### UX

* Is the primary action obvious?
* Are interactive elements obvious?
* Are touch targets comfortable?
* Are transitions understandable?
* Is there unnecessary friction?

### Game Experience

* Does the UI enhance immersion?
* Does it support the story?
* Does it feel like a mystery game rather than a utility app?
* Are clues and important information appropriately emphasized?

### Technical

* Is existing functionality preserved?
* Are reusable components used?
* Are hard-coded design values minimized?
* Does the layout work on different mobile sizes?
* Does Flutter analyze successfully?
* Do existing tests still pass?

---

# 19. Important Rule

Do not optimize for "more design."

Optimize for:

**better hierarchy + stronger atmosphere + clearer interaction + stronger storytelling + consistent polish.**

A screen with fewer visual elements can be better than a screen filled with decorative elements.

When uncertain, prefer the solution that feels:

**restrained, cinematic, mysterious, elegant, and intentional.**
