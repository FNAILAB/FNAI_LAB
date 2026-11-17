---
name: add-event
description: Add a new event with a photo gallery to the FNAI LAB website's Events & Pictures page (events.html), or add more photos to an existing event. Use for conference trips, awards ceremonies, lab outings and other lab moments with pictures.
---

# Add an event or photos (events.html)

Follow the **Workflow for every website change** in `CLAUDE.md` (check you are on `main`, then start clean and up to date; preview and
approval before editing; version bump; site check; approval before push; chat summary). This file only adds the
Events specifics. Reply in the user's language.

## 1. Collect

Required: year and month, a short title (English, or Korean if the user prefers — existing titles mix both), and the
photos (JPG/PNG; HEIC must be exported first). Never invent the date, place or award name.

Title format: `YYYY. MM. Title` — e.g. `2026. 06. KCC Conference in Jeju`. Read the existing cards in `events.html`
and match their style.

## 2. Photos

Resize each photo (commands in `CLAUDE.md` → Photo rules) into
`assets/events/<yyyy>-<mm>-<event-slug>-<n>.jpg` with MaxSide 1600, e.g. `assets/events/2026-12-ksc-busan-1.jpg`.
Check the names are not already used. Older events use `e1-1.jpg`… — leave those files and names alone.
Look at every resized photo (upright, belongs to this event). Suggest at most about 8 photos per event; ask the user to
pick if they send many more.

## 3. Card format (one line per event)

```html
<article class="event-card"><h3>TITLE</h3><div class="carousel" data-carousel aria-roledescription="carousel" aria-label="TITLE"><div class="carousel-track"><img src="assets/events/FILE-1.jpg" alt="TITLE (1/3)" loading="lazy"><img src="assets/events/FILE-2.jpg" alt="TITLE (2/3)" loading="lazy"><img src="assets/events/FILE-3.jpg" alt="TITLE (3/3)" loading="lazy"></div></div></article>
```

- `TITLE` is identical in `<h3>`, `aria-label` and every `alt` (escape `&` as `&amp;`, `"` as `&quot;` in attributes).
- Every `alt` ends with ` (i/n)` — position i, total n. A single photo is still a carousel with one image `(1/1)`.

## 4. Where to insert

Events are ordered newest first.

- **Newest event (usual case):** insert the new line in front of the current first `<article class="event-card">`
  (the line right after `<div class="event-grid">`). Anchor on `<article class="event-card"><h3>` + the current first
  title so the edit is unique.
- **Older date:** insert in front of the first existing card whose date is older.

## 5. Adding photos to an existing event

Append the new `<img>` tags at the end of that event's `carousel-track`, then **renumber every alt** in that event to
`(1/n)` … `(n/n)` with the new total. Do not change other events.

Then continue with steps 6–10 of the workflow in `CLAUDE.md` (bump version, site check, review, approval, push, chat line).
The site check verifies the `(i/n)` numbering and that every photo file exists.
