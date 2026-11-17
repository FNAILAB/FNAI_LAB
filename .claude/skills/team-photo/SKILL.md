---
name: team-photo
description: Add, replace or re-frame (calibrate) team member photos on the FNAI LAB website's Our Team page so every card photo follows one fixed standard - same square size, same head size, same eye line, face centred. Use when a member's photo is new, wrong, too zoomed in/out, off-centre, or when the user wants all team photos to look consistent.
---

# Team photos in one fixed standard (assets/team/)

Follow the **Workflow for every website change** in `CLAUDE.md` (check you are on `main`, then start clean and up to
date; preview and approval before editing; version bump; site check; approval before push; chat summary). This file
only adds the photo specifics. Reply in the user's language.

## The standard (every card photo, no exceptions)

- **900 × 900 px square JPEG**, saved as `assets/team/<slug>.jpg` (`<slug>` = the card's `data-photo` value in `team.html`).
- **Head** (top of the hair to the bottom of the chin) = **62%** of the height; **10%** empty space above the hair;
  face (nose) centred left-right. On the comparison sheet: hair touches the upper red line, chin sits on the lower red
  line, nose on the vertical line.
- The tool does all the maths; you only read three numbers off a grid. Never hand-edit pixel sizes and never use
  per-photo CSS (`object-position`) to fix framing — fix the photo file instead.
- **Not for the professor (P.I.) photo** — that card uses a tall portrait layout. Change it only if the user explicitly
  asks, and then with `resize-image` (CLAUDE.md → Photo rules), not with this tool.

## Tools

Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .claude/scripts/team-photo.ps1 -Mode <mode> ...`
Linux/macOS: `python3 .claude/scripts/team-photo.py <mode> ...` (needs Pillow: `python3 -m pip install --user pillow`;
this version has not been tested on a Mac yet — if it errors, STOP and tell the user)

| Step | Windows | Linux/macOS |
|---|---|---|
| Grid view | `-Mode inspect -In "<original>"` | `inspect --in "<original>"` |
| Cut the photo | `-Mode crop -In "<original>" -Out assets/team/<slug>.jpg -HeadTop T -Chin C -CenterX X [-PlainBackground]` | `crop --in "<original>" --out assets/team/<slug>.jpg --head-top T --chin C --center-x X [--plain-background]` |
| Compare | `-Mode sheet -Photos a.jpg,b.jpg,...` | `sheet a.jpg b.jpg ...` |

`inspect` and `sheet` write preview images to a temporary folder (never into the website); open them with the Read tool.

## Steps for each photo

1. **Which card.** Find the person in `team.html` and note the `data-photo` slug. If the person has no card yet, add the
   card first with `/add-member`. Tell the user which person and which source photo you will use, and get an OK.
2. **Source photo.**
   - New/replacement photo: the file the user gives (JPG/PNG; HEIC must be exported to JPG first). Prefer a photo with
     some space around the head and shoulders.
   - Re-framing an existing photo with no better original: first copy the current `assets/team/<slug>.*` to the
     temporary folder (e.g. `$env:TEMP\fnai-team-photo\` or `/tmp/fnai-team-photo/`) and use **that copy** as the
     source (the tool refuses to read and write the same file). If it is small (< 500 px), say the result may be blurry
     and suggest asking the person for a better photo.
3. **Inspect.** Run `inspect`, open the grid image, and read off, as fractions of the picture (0 = top/left, 1 = bottom/right):
   `HeadTop` = top of the hair, `Chin` = bottom of the chin, `CenterX` = the middle of the face (the nose).
   Use 2 decimals (e.g. 0.31). Ignore hats/hands; use the real top of the head.
4. **Crop.** Run `crop` with those numbers. Add `-PlainBackground` only for studio/ID photos whose background is one plain
   colour (white, grey, pink…) — it lets the square extend past the sides/top with that colour. Never use it for photos
   with scenery or people behind. Read the `NOTE:` lines the tool prints.
5. **Compare and adjust.** Run `sheet` with the new photo **plus 3–5 existing photos from the same section** and open it.
   If the hair is not on the upper line, the chin not on the lower line, or the nose not on the centre line (off by more
   than ~3% of the square), adjust the three numbers and crop again (at most 3 tries). If it still cannot match
   (photo too tight or the face at the edge), say so and suggest a wider photo.
6. **Clean up for this slug.**
   - Only one file per slug: if `assets/team/<slug>.png`/`.jpeg`/`.webp` also exists, `git rm` it (the site would use
     `.jpg` first anyway).
   - If `style.css` has a line `.profile:not(.lead) img.has-photo[data-photo="<slug>"]{object-position:...}`, delete
     that one line — standard square photos do not need it. Do not touch any other CSS.
   - New member: add `<slug>.jpg<spaces>English Name` to `assets/team/README.txt`.
7. **Show the user** the comparison sheet path and the tool's head numbers, and ask whether it looks right. If they
   say no, adjust (step 5), or undo with `git restore assets/team/<slug>.jpg` (or delete the new file if it was new).

## Re-framing all team photos at once

When the user asks for all photos to be made consistent: do steps 2–6 for every slug in `#graduate`, `#undergraduate`,
`#affiliated`, `#alumni` and `#past` (not `#pi`); skip slugs that have no photo file. Then show one comparison sheet per
section and list any photo that could not reach the standard (too small, too tight, face at the edge).

Then continue with steps 6–10 of the workflow in `CLAUDE.md` (bump version, site check, review, approval, push, chat line).
