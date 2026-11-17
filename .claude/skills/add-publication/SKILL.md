---
name: add-publication
description: Add, edit or move a paper on the FNAI LAB website's Publications page (publications.html) — add a new paper in the correct section (In Press, International Journal, International Conference) and order with co-first/corresponding author marks and lab-member highlighting; correct or add details (date, pages, DOI, title, authors, presentation date) to a paper already listed; or move a paper from In Press to its published section. Use whenever a lab paper is accepted, published, presented or needs a correction.
---

# Add, edit or move a publication (publications.html)

Follow the **Workflow for every website change** in `CLAUDE.md` (check you are on `main`, then start clean and up to date; preview and
approval before editing; version bump; site check; approval before push; chat summary). This file only adds the
Publications specifics. Reply in the user's language.

## 1. Collect (copy exactly, never invent)

- Authors in order, with marks: `*` right after each **co-first** author's name (`Chaebin Jeong*`), and ` º`
  (space + the character º, U+00BA) after each **corresponding** author (`Donghyeon Park º`).
- Title (exact capitalisation).
- Venue with details as available: full venue name, volume/pages, city/country, month/year.
- DOI or URL (optional but preferred).
- Section: **In Press** (accepted, not yet published), **International Journal**, or **International Conference**.
  The site has no domestic (Korean) section. If the paper is a domestic journal/conference, STOP and ask the user;
  do not put it in an international section and do not create a new section unless the user explicitly asks.

First search `publications.html` for the title (and first words of it). If it is already listed, this is an update or
a move, not a new entry.

## 2. Entry format (one `<li>` per line)

```html
<li>Author One, Author Two*, Author Three*, Donghyeon Park º, &quot;Paper Title&quot;, Venue details, City, Country, Month YYYY, <a href="https://doi.org/10.xxxx/yyyy">https://doi.org/10.xxxx/yyyy</a></li>
```

- Title wrapped in `&quot;…&quot;`. Escape `&` as `&amp;`.
- The link (if any) is a plain `<a href="URL">URL</a>` with the same URL as its text (no class, no target) —
  the style of the most recent entries. If there is no DOI/URL, end after the venue details.
- Look at the 2–3 newest entries in the same section and match their punctuation.

## 3. Where to insert

Each section looks like `<div class="pub-group"><h2>SECTION</h2><ul class="pub-list">` followed by `<li>` lines,
and the last `<li>` of a section ends with `</li></ul></div>`. Entries are newest first.

- **Newest in International Journal / International Conference (usual case):** insert a new line directly after the
  line ending in `<h2>SECTION</h2><ul class="pub-list">`, in front of that section's current first `<li>`. Anchor on
  the start of the current first entry so the edit is unique.
- **Somewhere in the middle:** insert a new line in front of the first entry of that section that is older.
- **Oldest in a section:** insert just before `</ul></div>` at the end of that section's last `<li>` line.
- **In Press:** this section is written inline as `<h2>In Press</h2><ul class="pub-list"><li></li></ul>`. The empty
  `<li></li>` is a placeholder: replace it with the new entry. If In Press already has entries, add the new one first.

## 4a. Editing a paper that is already listed

Use this for corrections or extra details (e.g. add a presentation date, fix pages, add a DOI).

1. Find the entry: search `publications.html` for a distinctive part of the title. It must match exactly **one**
   `<li>`. If it matches none or several, show what you found and ask the user which one.
2. Change only what the user asked for, inside that one `<li>`. Keep every other character of the entry the same:
   authors, marks (`*`, ` º`), `&quot;` quotes, punctuation and the link.
3. If the user does not say exactly where new text goes, put it with the other details in the same style, just
   **before the link** (or at the end if there is no link), separated by `, ` — and include it in the preview so the
   user can confirm the wording and position. Example: adding a presentation date
   `…, Expert Systems with Applications (Volume 309, 11 January 2026, 131184), Presented on November 10, 2026, <a href=…`.
   Ask how the user wants it labelled if it is unclear what the date means (published, presented, accepted).
4. Do not move the entry or change the order unless the date change makes the user ask for it.
5. In the preview, show the entry **before** and **after** so the user can compare.

## 4b. Moving In Press → published

Remove the `<li>` from In Press, update its details (venue, pages, DOI) and insert it in the right published section
and position. If In Press becomes empty, put the placeholder back exactly: `<ul class="pub-list"><li></li></ul>`.

## 5. Lab-member highlighting (script.js)

`script.js` highlights lab members' names in yellow using the `labMembers` array near the top:
```js
const labMembers = [
  'Nilufar Khodzhaeva', 'Sunghyun Ryu', 'Donghyeon Park',
  ...
];
```
For every author who is (or was) an FNAI Lab member — check `team.html` and ask the user if unsure — make sure the
**exact spelling used in this entry** (without `*` / `º`) is in the array. Spellings can differ from the team page
(e.g. team page "Chaebin Jung" vs papers "Chaebin Jeong"); the paper spelling is what matters. Add missing names as
`'First Last'` at the end of the array, keeping the existing formatting. Do not remove names.

Then continue with steps 6–10 of the workflow in `CLAUDE.md` (bump version, site check, review, approval, push, chat line).
After adding, ask whether a News item should be posted too (`/add-news`).
