---
name: add-member
description: Add a new person to the FNAI LAB website's Our Team page (team.html), update an existing member's card (status, research topic, major, degree, photo), or move someone between sections (e.g. undergraduate to M.S., current student to Past Students or Alumni). Use whenever a lab member's information or photo on the website must change.
---

# Add or update a team member (team.html)

Follow the **Workflow for every website change** in `CLAUDE.md` (clean + `git pull --rebase` first; preview and
approval before editing; version bump; site check; approval before push; chat summary). This file only adds the
team-page specifics. Reply in the user's language; the page text itself is in English (plus the Korean name).

## 1. Find out what is needed

Ask only for what is missing. Never guess a Korean name, date or degree.

| Section (id) | Who | Required | Optional |
|---|---|---|---|
| `#graduate` "Ph.D. & M.S. Students" | Ph.D., M.S., Undergrad-M.S integrated | English name, Korean name, status, start (YYYY. MM.), major, research topic, previous degree | photo |
| `#undergraduate` "Undergraduate Students" | undergraduate interns | English name, Korean name, department, admission year (2 digits), university | photo |
| `#affiliated` "Affiliated Researchers" | outside collaborators | English name, Korean name, position, institution | topic lines, photo |
| `#alumni` "Alumni" | graduated M.S./Ph.D. | English name, Korean name, degree, period (start ~ end), major, research topic | current job, photo |
| `#past` "Past Students" | former undergraduate interns | English name, Korean name, department, admission year, university | photo |
| `#pi` Principal Investigator | the professor | — | edit only the exact text the user asks for |

Before adding, search `team.html` for the person's English and Korean name. If they already exist, this is an
update or a move — never create a second card for the same person.

## 2. Card templates (copy exactly; one `<article>` per person)

`SLUG` = photo id: the English name in lowercase ASCII, words joined by hyphens, other characters removed
(e.g. `MinKyeong Jun` → `minkyeong-jun`, `DENIISE LIZ NAMAYANJA` → `deniise-liz-namayanja`). It must be unique in
`team.html`. `ALT` = the English name as written in `<h3>` (without the Korean part). The `<img>` always points to
`assets/avatar-placeholder.svg`; `script.js` swaps in `assets/team/SLUG.jpg` automatically when that file exists.

**Graduate** (`#graduate`):
```html
<article class="profile"><img src="assets/avatar-placeholder.svg" data-photo="SLUG" alt="ALT"><div class="profile-body"><h3>English Name (한글이름)</h3><p>M.S. Student (2026. 09. ~ )</p><p>Major: Artificial Intelligence and Data Science</p><p>Research Topic: Topic A, Topic B</p><p>B.S. in Something</p></div></article>
```
Status text is exactly one of: `Ph.D. Student`, `M.S. Student`, `Undergrad-M.S Integrated Program`, followed by ` (YYYY. MM. ~ )`.

**Undergraduate** (`#undergraduate`) and **Past Students** (`#past`):
```html
<article class="profile"><img src="assets/avatar-placeholder.svg" data-photo="SLUG" alt="ALT"><div class="profile-body"><h3>English Name (한글이름)</h3><p>Artificial Intelligence '22</p><p>Sejong University</p></div></article>
```
The first `<p>` is `Department 'YY` with a straight apostrophe (`'22` = admitted 2022).

**Alumni** (`#alumni`):
```html
<article class="profile"><img src="assets/avatar-placeholder.svg" data-photo="SLUG" alt="ALT"><div class="profile-body"><h3>English Name (한글이름), M.S.</h3><p>M.S. Student (2023. 09 ~ 2025. 08)</p><p>Major: Software (Data Science)</p><p>Research Topic: Topic</p><p>Current job: Job title (Organization)</p></div></article>
```
Leave out the `Current job` paragraph if unknown.

**Affiliated** (`#affiliated`):
```html
<article class="profile"><img src="assets/avatar-placeholder.svg" data-photo="SLUG" alt="ALT"><div class="profile-body"><h3>English Name (한글이름)</h3><p>Assistant Professor</p><p>Institution</p><p>Topic</p></div></article>
```

Escape `&` as `&amp;` in all text.

## 3. Where to put the card

The file keeps the section heading and grid opening on one line, and each section ends with `</div></section>`
right after its last card. To insert:

- **Before an existing card:** use that card's start as the anchor — `<article class="profile"><img src="assets/avatar-placeholder.svg" data-photo="NEXT-SLUG"` — and put the new card immediately in front of it. In `#graduate` put the new card on its own line (that section has one card per line); in the other sections cards sit side by side on one line, so insert it inline.
- **As the last card of a section:** anchor on the end of the current last card, i.e. the unique text near its end followed by `</div></article></div></section>`, and insert the new card between `</div></article>` and `</div></section>`.

Default order, unless the user says otherwise:
- `#graduate`: Ph.D. students first, then M.S. students by start date (oldest first), then Undergrad-M.S integrated last.
- `#undergraduate`: add at the end.
- `#alumni` and `#past`: most recent first (add at the start).

## 4. Updates and moves

- **Update:** change only the specific `<p>` text asked for, inside that person's card. Keep everything else.
- **Move** (e.g. graduated, finished internship, became M.S.): remove the whole `<article>…</article>` from the old
  section and insert a new card in the target section using the target template; keep the same `data-photo` SLUG so the
  photo still works. Ask for any fields the target template needs that you do not have.
- **Remove:** prefer moving to Past Students or Alumni. Delete only if the user explicitly insists, after confirming.

## 5. Photo

1. Ask for the photo file (JPG/PNG; HEIC must be exported to JPG first). A clear face, ideally portrait.
2. Resize to `assets/team/SLUG.jpg` with MaxSide 1200 (commands in `CLAUDE.md` → Photo rules). If the person already
   has a photo and the user wants it replaced, the new file overwrites `SLUG.jpg`; remove any other file for the same
   SLUG with a different extension (`git rm assets/team/SLUG.png`) so only one remains.
3. Look at the resized image: upright, correct person.
4. Framing: the cards show a centred **square** crop taken 25% of the way down the image. For a tall photo where the face
   sits low (face centre below ~45% of the height), add one rule at the end of `style.css` so the face is centred, e.g.
   `.profile:not(.lead) img.has-photo[data-photo="SLUG"]{object-position:center 65%}` (0% = top, 100% = bottom).
   Existing examples are already in `style.css`.
5. Add a line `SLUG.jpg<spaces>English Name` to `assets/team/README.txt` for a new member.

## 6. Publications highlighting

If the person will appear as an author in Publications, make sure the spelling used in papers is in the
`labMembers` list in `script.js` (the `/add-publication` skill does this when a paper is added).

Then continue with steps 6–10 of the workflow in `CLAUDE.md` (bump version, site check, review, approval, push, chat line).
