"""Generate web/favicon.png + web/icons/* from a master 1024x1024 RGBA icon.

Usage:
    python3 tool/build_icons.py <master_png>

Master should have the design centered with transparent corners (squircle).
Produces:
  web/favicon.png              (256x256)
  web/icons/Icon-192.png       (192, transparent background)
  web/icons/Icon-512.png       (512, transparent background)
  web/icons/Icon-maskable-192.png  (192 with solid violet bg, 75% safe-zone)
  web/icons/Icon-maskable-512.png  (512 with solid violet bg, 75% safe-zone)
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
WEB = ROOT / "web"
ICONS = WEB / "icons"
MASKABLE_BG = (124, 58, 237, 255)  # match violet from gradient

SAFE_ZONE_RATIO = 0.78   # maskable design fits inside 78% of canvas
SQUIRCLE_MARGIN = 0.06   # 6% margin around the squircle inside the source
SQUIRCLE_RADIUS_RATIO = 0.22  # corner radius as % of canvas


def _center_square(img: Image.Image) -> Image.Image:
    w, h = img.size
    if w == h:
        return img
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def _squircle_alpha(size: int) -> Image.Image:
    """Build a rounded-rectangle alpha mask at `size x size`."""
    margin = int(size * SQUIRCLE_MARGIN)
    radius = int(size * SQUIRCLE_RADIUS_RATIO)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (margin, margin, size - margin - 1, size - margin - 1),
        radius=radius,
        fill=255,
    )
    return mask


def _apply_squircle_alpha(img: Image.Image) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    mask = _squircle_alpha(img.size[0])
    img.putalpha(mask)
    return img


def make_regular(master: Image.Image, size: int, out: Path) -> None:
    img = master.resize((size, size), Image.LANCZOS)
    img.save(out, "PNG")
    print(f"  wrote {out.relative_to(ROOT)} ({size}x{size})")


def make_maskable(master: Image.Image, size: int, out: Path) -> None:
    bg = Image.new("RGBA", (size, size), MASKABLE_BG)
    inner_size = int(size * SAFE_ZONE_RATIO)
    fg = master.resize((inner_size, inner_size), Image.LANCZOS)
    offset = ((size - inner_size) // 2, (size - inner_size) // 2)
    bg.paste(fg, offset, fg)
    bg.save(out, "PNG")
    print(f"  wrote {out.relative_to(ROOT)} ({size}x{size}, maskable)")


def main(master_path: str) -> None:
    src = Path(master_path)
    if not src.exists():
        raise SystemExit(f"Master icon not found: {src}")
    raw = Image.open(src)
    print(f"  master: {raw.size} {raw.mode}")
    master = _apply_squircle_alpha(_center_square(raw))
    print(f"  prepared: {master.size} {master.mode}")

    ICONS.mkdir(parents=True, exist_ok=True)
    make_regular(master, 256, WEB / "favicon.png")
    make_regular(master, 192, ICONS / "Icon-192.png")
    make_regular(master, 512, ICONS / "Icon-512.png")
    make_maskable(master, 192, ICONS / "Icon-maskable-192.png")
    make_maskable(master, 512, ICONS / "Icon-maskable-512.png")
    print("done.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        raise SystemExit(2)
    main(sys.argv[1])
