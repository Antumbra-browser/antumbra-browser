#!/usr/bin/env python3
"""Generate placeholder PNG and ICO icons for Antumbra branding.

Run from the repo root: python scripts/gen-placeholder-icons.py
Output: branding/antumbra/content/*.png and branding/antumbra/*.ico
"""
import struct, zlib, os

VOID = (11, 13, 16)      # #0B0D10
CORONA = (255, 176, 32)  # #FFB020

def png_chunk(name, data):
    c = zlib.crc32(name + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + name + data + struct.pack(">I", c)

def make_png(w, h, bg=VOID, ring=None):
    """Minimal valid PNG. ring draws a 1-pixel amber border if requested."""
    raw = b""
    for y in range(h):
        row = b"\x00"
        for x in range(w):
            if ring and (x == 0 or y == 0 or x == w-1 or y == h-1):
                row += bytes(CORONA)
            else:
                row += bytes(bg)
        raw += row
    compressed = zlib.compress(raw, 9)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n"
            + png_chunk(b"IHDR", ihdr)
            + png_chunk(b"IDAT", compressed)
            + png_chunk(b"IEND", b""))

def make_ico(sizes):
    """Minimal ICO containing one image per size."""
    images = [make_png(s, s, ring=True) for s in sizes]
    n = len(images)
    header = struct.pack("<HHH", 0, 1, n)
    offset = 6 + n * 16
    entries = b""
    for i, (s, img) in enumerate(zip(sizes, images)):
        entries += struct.pack("<BBBBHHII", s if s < 256 else 0, s if s < 256 else 0,
                               0, 0, 1, 24, len(img), offset)
        offset += len(img)
    return header + entries + b"".join(images)

out = "branding/antumbra/content"
os.makedirs(out, exist_ok=True)

# Standard sizes
for size in [16, 22, 24, 32, 48, 64, 128, 256]:
    with open(f"{out}/default{size}.png", "wb") as f:
        f.write(make_png(size, size, ring=True))

# About logo variants
for name, w, h in [("about-logo", 512, 512), ("about-logo@2x", 1024, 1024),
                    ("about-logo-private", 512, 512), ("about-logo-private@2x", 1024, 1024),
                    ("about", 302, 302)]:
    with open(f"{out}/{name}.png", "wb") as f:
        f.write(make_png(w, h, ring=True))

# Windows VisualElements PNGs
ve_dir = "branding/antumbra"
os.makedirs(ve_dir, exist_ok=True)
for name, size in [("VisualElements_150", 150), ("VisualElements_70", 70),
                    ("PrivateBrowsing_150", 150), ("PrivateBrowsing_70", 70)]:
    with open(f"{ve_dir}/{name}.png", "wb") as f:
        f.write(make_png(size, size))

# ICO files
ico_dir = "branding/antumbra"
for name, sizes in [("firefox", [16, 32, 48, 64, 128, 256]),
                     ("firefox64", [64, 128, 256]),
                     ("document", [16, 32, 48]),
                     ("document_pdf", [16, 32, 48]),
                     ("newtab", [16, 32]),
                     ("newwindow", [16, 32]),
                     ("pbmode", [16, 32])]:
    with open(f"{ico_dir}/{name}.ico", "wb") as f:
        f.write(make_ico(sizes))

print("Placeholder icons generated.")
