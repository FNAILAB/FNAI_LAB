#!/usr/bin/env python3
"""Team photo tool for the FNAI LAB website (Linux/macOS; Windows uses team-photo.ps1). Used by /team-photo.

Every team card photo is saved in ONE standard so all cards look the same:
  900 x 900 px square JPEG; the head (top of hair to chin) fills 62% of the height;
  10% space above the hair; the face is centred left-right.

Modes (run from the website folder):
  inspect: upright copy with a 10% grid, to read off where the head is
    python3 .claude/scripts/team-photo.py inspect --in "<original>"
  crop: cut the standard square (fractions 0-1 of the UPRIGHT photo, read from the grid)
    python3 .claude/scripts/team-photo.py crop --in "<original>" --out assets/team/<slug>.jpg \
        --head-top 0.12 --chin 0.43 --center-x 0.50 [--plain-background]
  sheet: several team photos side by side with the standard's guide lines
    python3 .claude/scripts/team-photo.py sheet assets/team/a.jpg assets/team/b.jpg
inspect and sheet write only to a temporary folder. Needs Pillow (python3 -m pip install --user pillow).
"""
import argparse
import os
import random
import re
import sys
import tempfile
import time

try:
    from PIL import Image, ImageDraw, ImageOps
except ImportError:
    sys.exit("Pillow is not installed. Run: python3 -m pip install --user pillow")

OUT_SIZE = 900
HEAD_FRACTION = 0.62   # head height / frame height  (keep in sync with team-photo.ps1)
TOP_MARGIN = 0.10      # space above the hair / frame height

TMP = os.path.join(tempfile.gettempdir(), "fnai-team-photo")
os.makedirs(TMP, exist_ok=True)


def tmp_name(prefix):
    return os.path.join(TMP, f"{prefix}-{time.strftime('%H%M%S')}-{random.randint(0, 99999)}.jpg")


def open_upright(path):
    if path.lower().endswith((".heic", ".heif")):
        sys.exit("HEIC/HEIF photos are not supported. Please export the photo as JPG first.")
    im = ImageOps.exif_transpose(Image.open(path))
    return im.convert("RGB")


def inspect(a):
    im = open_upright(a.src)
    W, H = im.size
    scale = min(1.0, 1000 / max(W, H))
    v = im.resize((max(1, round(W * scale)), max(1, round(H * scale))), Image.LANCZOS)
    d = ImageDraw.Draw(v)
    w, h = v.size
    for i in range(1, 10):
        x, y = round(w * i / 10), round(h * i / 10)
        d.line([(x, 0), (x, h)], fill=(255, 0, 0), width=1)
        d.line([(0, y), (w, y)], fill=(255, 0, 0), width=1)
        d.rectangle([2, y - 8, 30, y + 8], fill=(255, 255, 255))
        d.text((4, y - 6), f"{i / 10:.1f}", fill=(255, 0, 0))
        d.rectangle([x - 14, 2, x + 14, 18], fill=(255, 255, 255))
        d.text((x - 11, 4), f"{i / 10:.1f}", fill=(255, 0, 0))
    out = tmp_name("inspect")
    v.save(out, "JPEG", quality=88)
    print(f"Upright photo is {W}x{H} px. Grid copy: {out}")
    print("Read off (as fractions 0-1): head-top = top of hair, chin = bottom of chin, center-x = middle of the face (nose).")


def crop(a):
    for name, val in (("head-top", a.head_top), ("chin", a.chin), ("center-x", a.center_x)):
        if not 0 <= val <= 1:
            sys.exit(f"--{name} must be a fraction between 0 and 1 (read it from the inspect grid)")
    if a.chin <= a.head_top:
        sys.exit("--chin must be below --head-top (a larger number)")
    if os.path.abspath(a.src) == os.path.abspath(a.dst):
        sys.exit("Input and output are the same file. Crop from the original photo instead.")
    if not re.search(r"(^|/)assets/team/[a-z0-9]+(-[a-z0-9]+)*\.jpg$", a.dst.replace("\\", "/")):
        sys.exit("--out must be assets/team/<slug>.jpg (lowercase letters, digits, hyphens)")

    im = open_upright(a.src)
    W, H = im.size
    top_px = a.head_top * H
    head_px = (a.chin - a.head_top) * H
    S = head_px / HEAD_FRACTION
    S = min(S, (H - top_px) / (1 - TOP_MARGIN))          # never past the bottom of the photo
    if not a.plain_background:
        S = min(S, W, H)                                    # stay inside the photo
    limited = head_px / S > HEAD_FRACTION + 0.04
    x0 = a.center_x * W - S / 2
    y0 = top_px - TOP_MARGIN * S
    if a.plain_background:
        if S <= W:
            x0 = max(0, min(W - S, x0))
        y0 = min(H - S, y0)
    else:
        x0 = max(0, min(W - S, x0))
        y0 = max(0, min(H - S, y0))

    # Background colour = average of the two top corners (used only where the square leaves the photo).
    p = max(2, int(min(W, H) * 0.03))
    px = [im.getpixel((x, y)) for cx in (0, W - p) for y in range(0, p, 2) for x in range(cx, cx + p, 2)]
    bg = tuple(sum(c[i] for c in px) // len(px) for i in range(3))

    k = OUT_SIZE / S
    canvas = Image.new("RGB", (OUT_SIZE, OUT_SIZE), bg)
    scaled = im.resize((max(1, round(W * k)), max(1, round(H * k))), Image.LANCZOS)
    canvas.paste(scaled, (round(-x0 * k), round(-y0 * k)))
    canvas.save(a.dst, "JPEG", quality=88, optimize=True, progressive=True)

    top_pct = (top_px - y0) / S * 100
    chin_pct = (a.chin * H - y0) / S * 100
    cx_pct = (a.center_x * W - x0) / S * 100
    kb = os.path.getsize(a.dst) // 1024
    print(f"Saved {a.dst} ({OUT_SIZE}x{OUT_SIZE}, {kb} KB). Head: top {top_pct:.0f}% / chin {chin_pct:.0f}% / "
          f"centre {cx_pct:.0f}%  (standard: 10% / 72% / 50%)")
    if limited:
        print("NOTE: the photo is too tightly framed to reach the standard; the head is clearly larger than the standard 62%. "
              "If the background is plain (studio/ID photo), run again with --plain-background. "
              "Ask for a wider photo if it looks too big next to the others.")
    if abs(top_pct - 10) > 4 or abs(cx_pct - 50) > 6:
        print("NOTE: the face could not be placed at the standard position (it is near the photo's edge). "
              "Check the comparison sheet; a wider photo may be needed.")
    if min(W, H) < 500 or S < 450:
        print("NOTE: the source photo is small; the result may look blurry. A larger photo is better.")


def sheet(a):
    photos = [p for arg in a.photos for p in arg.split(",") if p.strip()]
    cell, pad, label = 220, 10, 22
    cols = min(6, len(photos))
    rows = -(-len(photos) // cols)
    out = Image.new("RGB", ((cell + pad) * cols + pad, (cell + pad + label) * rows + pad), (255, 255, 255))
    d = ImageDraw.Draw(out)
    for k, p in enumerate(photos):
        x = pad + (k % cols) * (cell + pad)
        y = pad + (k // cols) * (cell + pad + label)
        im = open_upright(p.strip())
        s = min(im.size)
        sx, sy = (im.size[0] - s) / 2, (im.size[1] - s) * 0.25   # what the card shows: a square, 25% down
        tile = im.crop((round(sx), round(sy), round(sx) + s, round(sy) + s)).resize((cell, cell), Image.LANCZOS)
        out.paste(tile, (x, y))
        for f in (TOP_MARGIN, TOP_MARGIN + HEAD_FRACTION):
            gy = y + round(cell * f)
            for gx in range(x, x + cell, 8):
                d.line([(gx, gy), (gx + 4, gy)], fill=(255, 0, 0))
        for gy in range(y, y + cell, 8):
            d.line([(x + cell // 2, gy), (x + cell // 2, gy + 4)], fill=(255, 0, 0))
        d.text((x, y + cell + 5), os.path.basename(p.strip()), fill=(0, 0, 0))
    path = tmp_name("sheet")
    out.save(path, "JPEG", quality=88)
    print(f"Comparison sheet: {path}")
    print("Red dashed lines = the standard: top of hair on the upper line, chin on the lower line, nose on the vertical line.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="mode", required=True)
    i = sub.add_parser("inspect"); i.add_argument("--in", dest="src", required=True)
    c = sub.add_parser("crop")
    c.add_argument("--in", dest="src", required=True)
    c.add_argument("--out", dest="dst", required=True)
    c.add_argument("--head-top", dest="head_top", type=float, required=True)
    c.add_argument("--chin", type=float, required=True)
    c.add_argument("--center-x", dest="center_x", type=float, required=True)
    c.add_argument("--plain-background", dest="plain_background", action="store_true")
    s = sub.add_parser("sheet"); s.add_argument("photos", nargs="+")
    a = ap.parse_args()
    {"inspect": inspect, "crop": crop, "sheet": sheet}[a.mode](a)


if __name__ == "__main__":
    main()
