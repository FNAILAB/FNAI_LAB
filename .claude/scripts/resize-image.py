#!/usr/bin/env python3
"""Resize a photo for the FNAI LAB website (Linux, macOS).

Same behaviour as resize-image.ps1 (the Windows version):
  - fixes phone photos that would otherwise appear sideways (EXIF orientation),
  - shrinks so the longest side is at most --max-side pixels (never enlarges),
  - saves JPEG at quality 85 (or PNG if the output ends in .png).

Usage (from the website folder):
  python3 .claude/scripts/resize-image.py --in "/path/photo.jpg" --out "assets/news/kcc2026-1.jpg" --max-side 1600

Needs Pillow. If "No module named PIL": python3 -m pip install --user pillow
(add --break-system-packages if pip refuses with "externally-managed-environment").
HEIC/HEIF (iPhone) files are not supported: export the photo as JPG first.
"""
import argparse
import os
import sys

try:
    from PIL import Image, ImageOps
except ImportError:
    sys.exit("Pillow is not installed. Run: python3 -m pip install --user pillow")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--in", dest="src", required=True, help="original photo")
    p.add_argument("--out", dest="dst", required=True, help="output path inside assets/")
    p.add_argument("--max-side", dest="max_side", type=int, default=1600)
    a = p.parse_args()

    src = os.path.abspath(a.src)
    dst = os.path.abspath(a.dst)
    if not os.path.isfile(src):
        sys.exit(f"Input file not found: {a.src}")
    if src.lower().endswith((".heic", ".heif")):
        sys.exit("HEIC/HEIF photos are not supported. Please export the photo as JPG first.")
    if src == dst:
        sys.exit("Input and output are the same file. Use a different --out path.")
    if not os.path.isdir(os.path.dirname(dst)):
        sys.exit(f"Output folder does not exist: {os.path.dirname(dst)}")
    if a.max_side < 1:
        sys.exit("--max-side must be a positive number")

    with Image.open(src) as im:
        im = ImageOps.exif_transpose(im)          # upright, orientation tag removed
        w, h = im.size
        scale = min(1.0, a.max_side / max(w, h))  # never enlarge
        nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
        if (nw, nh) != (w, h):
            im = im.resize((nw, nh), Image.LANCZOS)

        if dst.lower().endswith(".png"):
            im.save(dst, "PNG", optimize=True)
        else:
            if im.mode in ("RGBA", "LA", "P"):
                im = im.convert("RGBA")
                bg = Image.new("RGB", im.size, (255, 255, 255))  # JPEG has no transparency
                bg.paste(im, mask=im.split()[-1])
                im = bg
            elif im.mode != "RGB":
                im = im.convert("RGB")
            im.save(dst, "JPEG", quality=85, optimize=True, progressive=True)

    kb = os.path.getsize(dst) // 1024
    print(f"Saved {a.dst} ({nw}x{nh}, {kb} KB)")


if __name__ == "__main__":
    main()
