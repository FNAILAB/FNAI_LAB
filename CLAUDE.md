# FNAI LAB website — rules for Claude

This folder is the public website of the Food & Nutrition AI Lab (FNAI Lab), Sejong University.
It is a plain static site (HTML/CSS/JS, no build step) published by GitHub Pages from the `main` branch of
`github.com/FNAILAB/FNAI_LAB`. Live site: https://fnailab.github.io/FNAI_LAB/
Anything pushed to `main` is public within 1–2 minutes, so be careful and conservative.

Lab members use these skills for routine edits (type `/` to see them):

| Skill | Use it to |
|---|---|
| `/add-member` | add, update or move a person on the Our Team page |
| `/add-news` | add a News item on the home page |
| `/add-event` | add an event (or more photos) on Events & Pictures |
| `/add-publication` | add, edit or move a paper on Publications |

For any other change, follow the same workflow below.

## Workflow for every website change (skills follow this too)

1. **Start clean and up to date.**
   - Run `git branch --show-current`. It must print `main`: this lab publishes by pushing straight to `main` and does
     not use branches or pull requests. If it prints anything else — for example a `claude/...` branch, which is what
     Claude Code on the web (claude.ai/code) always uses — STOP: make no edits, create no branch, and tell the user
     that website changes must be made from a computer with the repository on `main` (see the setup steps the lab
     shares). Never create, switch to or push any other branch.
   - Run `git status`. If there are uncommitted changes you did not make in this session, STOP: show them to
     the user and ask what to do. Never stash, discard, reset or overwrite someone's work on your own.
   - Run `git pull --rebase`. If it fails (conflict, no upstream, login problem), STOP and explain; do not force anything.
2. **Collect facts from the user; never invent them.** Names (English and Korean), dates, titles, venues, DOIs,
   URLs, awards and photos must come from the user or from files/links the user gave. If a required fact is missing,
   ask. Leave optional parts out rather than guessing. Copy titles, names and DOIs exactly as given.
3. **Show a preview and get approval before editing.** Show the exact text that will be added (as it will read on the
   page), where it goes (page, section, position) and which photo files will be created. Wait for an explicit OK.
4. **Edit narrowly.**
   - Use exact-string edits that insert or change only the intended element. Never rewrite, reformat, re-indent or
     "clean up" other parts of a page. Never change the layout, CSS design, navigation or footer unless the user
     asked for exactly that.
   - Copy the HTML pattern of the neighbouring items exactly (class names, attribute order, spacing, punctuation).
   - Escape text for HTML: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`; inside attribute values also `"` → `&quot;`.
   - Do not touch the professor's (P.I.) profile unless the user explicitly asks to edit it.
5. **Photos** (see "Photo rules" below): always resize with the helper script; never commit an original camera file.
6. **Bump the version tag** so visitors see the change immediately: `perl .claude/scripts/bump-version.pl`
7. **Run the site check:** `perl .claude/scripts/check-site.pl`. It must print `SITE CHECK PASSED`.
   Warnings about missing team photos are OK. If it fails, fix the cause (do not weaken or edit the checker) and run it again.
8. **Review the diff:** `git status` and `git diff --stat`. Only the files you meant to change may appear
   (plus the 8 pages touched by the version bump). Show the user a short summary and ask before pushing.
9. **Commit and push** to `main`:
   - Commit message format: `[웹사이트] <what>: <short summary>` — e.g. `[웹사이트] 뉴스 추가: KCC 2026 우수논문상 (홍길동)`.
   - If git says "Author identity unknown", ask the user for the name and email to use and set them with
     `git config user.name` / `git config user.email` (this repository only, not `--global`).
   - `git push` (to `main`; never to another branch).
   - If the push is rejected because someone else pushed first, run `git pull --rebase`. Your version tag must then be
     made newer than the one they just published, otherwise visitors may keep seeing a cached page:
     - **Rebase finished without conflict:** `perl .claude/scripts/bump-version.pl`, run the site check,
       `git commit -a --amend --no-edit`, then `git push`.
     - **Rebase stopped with a conflict:** run `perl .claude/scripts/resolve-version-conflicts.pl`. It fixes only
       conflicts where the two sides differ in nothing but the `?v=` version tag (common when two people publish
       minutes apart). If it prints `All conflicts resolved`: `perl .claude/scripts/bump-version.pl`, run the site
       check, `git add -A`, `git -c core.editor=true rebase --continue`, then `git push`. If it prints `NOT resolved`
       (for example two people edited neighbouring lines), STOP and show the user both versions; `git rebase --abort`
       returns to the state before the pull.
   - Never use `--force`.
10. **Report.** Tell the user the site updates in 1–2 minutes at https://fnailab.github.io/FNAI_LAB/ and give them one
    line they can paste into the lab group chat, for example:
    `✅ [웹사이트] 뉴스 추가: 2026.12 KCC 우수논문상 (홍길동) — https://fnailab.github.io/FNAI_LAB/`

Never: push with `--force`, rewrite history, delete other people's content (move members to Past Students / Alumni
instead of deleting, unless the user insists), commit secrets or personal phone numbers/emails that are not already
public on the site, or add tracking scripts or external libraries.

## Photo rules

Resize every new photo with the helper. It fixes phone photos that would show sideways, shrinks them and saves a JPEG.

- **Windows:** `powershell -NoProfile -ExecutionPolicy Bypass -File .claude/scripts/resize-image.ps1 -In "<original>" -Out "<assets/...jpg>" -MaxSide <N>`
- **macOS:** `sips -Z <N> -s format jpeg -s formatOptions 85 "<original>" --out "<assets/...jpg>"`
  (`-Z` can enlarge: if the photo's longest side is already ≤ N — check with `sips -g pixelWidth -g pixelHeight` — leave out `-Z <N>`.)
- **Linux (or macOS with Python):** `python3 .claude/scripts/resize-image.py --in "<original>" --out "<assets/...jpg>" --max-side <N>`
  (needs Pillow: if it says Pillow is not installed, run `python3 -m pip install --user pillow`).

| Kind | Folder | File name | MaxSide |
|---|---|---|---|
| Team member photo | `assets/team/` | `<data-photo slug>.jpg` (e.g. `minkyeong-jun.jpg`) | 1200 |
| News photo | `assets/news/` | `<short-event-slug>-<n>.jpg` (e.g. `kcc2026-award-1.jpg`) | 1600 |
| News logo/graphic (venue or journal logo) | `assets/news/` | `<slug>.png` (keep PNG for logos) | 1200 |
| Event photo | `assets/events/` | `<yyyy>-<mm>-<event-slug>-<n>.jpg` (e.g. `2026-12-ksc-busan-1.jpg`) | 1600 |

- File names: lowercase ASCII letters, digits and hyphens only; never reuse an existing file name unless the user
  asked to replace that photo. Never rename or delete existing photos that other pages use.
- HEIC/HEIF (iPhone) files cannot be used: ask the user for a JPG/PNG export.
- After resizing, look at each resulting image to confirm it is upright and is the right person/event.
- Each photo must be under 1 MB (the site check enforces this).

## Site facts

- Pages: `index.html` (home + News), `team.html`, `events.html`, `research.html`, `publications.html`,
  `activities.html`, `media.html`, `join.html`. Shared files: `style.css` (imports `brand.css`), `script.js`.
- Each page loads `style.css?v=<tag>` and `script.js?v=<tag>`; the tag must be identical on all pages (bump script does this).
- `script.js` loads team photos automatically from `assets/team/<data-photo>.jpg|jpeg|png|webp` and builds the
  photo carousels (`data-carousel`). It also highlights lab members' names in Publications using the `labMembers` list.
- Pages keep one news item / card / publication per line. Keep that style.
