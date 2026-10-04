#!/usr/bin/env python3
"""Build branding/AppIcon.icns and branding/AppIcon.iconset from branding/icon-1024.png.

The running app takes its icon from Resources/Assets.xcassets (compiled by Xcode),
same as Brink. This icns is the press-kit and Finder-drag icon.

Requires Pillow: pip install pillow
"""

from __future__ import annotations

import struct
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "icon-1024.png"
ICONSET = ROOT / "AppIcon.iconset"
ICNS = ROOT / "AppIcon.icns"

# (iconset filename, pixel size). @2x files are the doubled bitmap, as iconutil expects.
ICONSET_FILES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

# PNG-backed icns types. These are the ones a modern iconutil icns actually carries.
ICNS_TYPES = [
    ("icp4", 16),
    ("icp5", 32),
    ("ic11", 32),  # 16x16@2x
    ("icp6", 64),
    ("ic12", 64),  # 32x32@2x
    ("ic07", 128),
    ("ic08", 256),
    ("ic13", 256),  # 128x128@2x
    ("ic09", 512),
    ("ic14", 512),  # 256x256@2x
    ("ic10", 1024),
]


def png_bytes(im: Image.Image, size: int) -> bytes:
    from io import BytesIO

    out = im.resize((size, size), Image.Resampling.LANCZOS)
    buf = BytesIO()
    out.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


def pack_icns(chunks: list[tuple[str, bytes]]) -> bytes:
    body = b""
    for ostype, data in chunks:
        if len(ostype) != 4:
            raise SystemExit(f"bad icns type {ostype}")
        body += ostype.encode("ascii") + struct.pack(">I", len(data) + 8) + data
    return b"icns" + struct.pack(">I", len(body) + 8) + body


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"missing {SRC}")
    im = Image.open(SRC).convert("RGBA")
    if im.size != (1024, 1024):
        raise SystemExit(f"{SRC.name} is {im.size}, expected 1024x1024")

    ICONSET.mkdir(exist_ok=True)
    for name, size in ICONSET_FILES:
        (ICONSET / name).write_bytes(png_bytes(im, size))

    blob = pack_icns([(ostype, png_bytes(im, size)) for ostype, size in ICNS_TYPES])
    ICNS.write_bytes(blob)
    print(f"Wrote {ICNS.relative_to(ROOT.parent)} ({len(blob)} bytes) and {ICONSET.name}/")


if __name__ == "__main__":
    try:
        main()
    except ModuleNotFoundError:
        sys.exit("Pillow is required: pip install pillow")
