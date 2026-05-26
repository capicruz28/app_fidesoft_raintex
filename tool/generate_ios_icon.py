"""Generate a full-bleed 1024x1024 iOS launcher icon from the source logo."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "logo_fidesoft_oc.png"
DST = ROOT / "assets" / "logo_fidesoft_ios.png"

SIZE = 1024
FILL_RATIO = 0.90  # logo occupies ~90% of canvas (iOS safe zone)
BG = (255, 255, 255)  # match Android adaptive_icon_background


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    bbox = im.getbbox()
    if not bbox:
        raise SystemExit(f"No visible pixels in {SRC}")
    im = im.crop(bbox)

    target = int(SIZE * FILL_RATIO)
    w, h = im.size
    scale = min(target / w, target / h)
    nw, nh = int(w * scale), int(h * scale)
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGB", (SIZE, SIZE), BG)
    x = (SIZE - nw) // 2
    y = (SIZE - nh) // 2
    canvas.paste(im, (x, y), im)
    canvas.save(DST, "PNG", optimize=True)
    print(f"Wrote {DST} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
