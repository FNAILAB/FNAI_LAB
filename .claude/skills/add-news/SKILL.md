---
name: add-news
description: Add a News item to the FNAI LAB website home page (index.html) — paper acceptances, conference presentations, awards, grants, publications — with optional paper link, DOI and photos, in the site's existing News format. Use whenever the lab has news to announce on the website.
---

# Add a News item (index.html)

Follow the **Workflow for every website change** in `CLAUDE.md` (check you are on `main`, then start clean and up to date; preview and
approval before editing; version bump; site check; approval before push; chat summary). This file only adds the
News specifics. Reply in the user's language; write the News text in English, in the same tone as the existing items.

## 1. Collect

Required: month and year; what happened; the people involved (as they want to be named, e.g. "our Ph.D. student,
Nilufar Khodzhaeva"). Ask for these if missing.
Optional: paper title and link, DOI, venue full name and city, photos (or a logo of the venue/journal).
Never invent a DOI, link, award name, ranking or impact factor. Copy titles exactly.

Read the first few existing News items in `index.html` and match their style and wording.

## 2. Format

One `<article class="news-item">` per item, on its own line, inside `<div class="news-list">`.

```html
<article class="news-item"><p>🎉 Dec. 2026: Congratulations to our M.S. student, Hong Gildong, on ... The paper, <a class="external" href="PAPER-URL" target="_blank" rel="noopener">“Paper Title”</a>, was authored by Hong Gildong, Chaebin Jeong, and Prof. Donghyeon Park.</p><p>DOI: <a class="external" href="https://doi.org/10.xxxx/yyyy" target="_blank" rel="noopener">10.xxxx/yyyy</a></p>MEDIA</article>
```

- Date prefix: emoji, space, `Mon. YYYY:` with these month spellings: `Jan.` `Feb.` `Mar.` `Apr.` `May` `Jun.` `Jul.`
  `Aug.` `Sep.` `Oct.` `Nov.` `Dec.` Default emoji 🎉 (🥳 also used for publications). Use another only if the user asks.
- Paper title inside the link uses curly quotes “…”. Leave the link out if there is no URL; leave the DOI paragraph
  out if there is no DOI. If only a DOI is given, the paper link may use `https://doi.org/<DOI>`.
- A list of several papers/people may use `<ul><li>…</li></ul>` after the first `<p>`, as in existing items.
- Escape `&` as `&amp;` in text. Keep the whole article on one line.

`MEDIA` is one of:

- **Nothing** (no image).
- **A logo or graphic** (venue/journal logo — shown small):
  ```html
  <figure class="news-media"><img src="assets/news/FILE.png" alt="Venue or journal name" loading="lazy"></figure>
  ```
- **One or more photos** (shown as a swipeable 3:4 photo box; use this even for a single photo, because the `figure`
  style above shrinks images to logo size):
  ```html
  <div class="carousel news-media" data-carousel aria-roledescription="carousel" aria-label="LABEL"><div class="carousel-track"><img src="assets/news/SLUG-1.jpg" alt="LABEL (1/2)" loading="lazy"><img src="assets/news/SLUG-2.jpg" alt="LABEL (2/2)" loading="lazy"></div></div>
  ```
  `LABEL` = short English description, e.g. `KCC 2026 award ceremony`. Every photo's alt is `LABEL (i/n)` with the
  correct position i and total n.

## 3. Photos

Resize each photo into `assets/news/` (commands and naming in `CLAUDE.md` → Photo rules): photos → `SLUG-1.jpg`,
`SLUG-2.jpg`… with MaxSide 1600; a logo → `SLUG.png` with MaxSide 1200. `SLUG` is short, lowercase, e.g.
`kcc2026-award`. Check the name is not already used in `assets/news/`. Look at each result (upright, correct photo).
Keep photo sets small (about 1–5 photos).

## 4. Where to insert

News is ordered newest first.

- **Newest item (usual case):** insert the new line directly after the line that ends with `<div class="news-list">`,
  i.e. in front of the current first `<article class="news-item">`. Anchor on the start of the current first item
  (`<article class="news-item"><p>` + its first words) so the edit is unique.
- **Older date:** insert in front of the first existing item that is older than the new one.

Do not edit or reorder other items unless the user asks.

Then continue with steps 6–10 of the workflow in `CLAUDE.md` (bump version, site check, review, approval, push, chat line).
After a paper News item, ask whether the paper should also be added to Publications (`/add-publication`).
