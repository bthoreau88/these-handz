#!/usr/bin/env python3
"""
slice_parts.py — cut an AI-generated "part-out sheet" into individual
transparent PNGs, ready to hang on the FighterVisual puppet rig.

The sheets come back from the image model as one flat picture: an assembled
character on the left, then the separated body parts laid out with gaps and
small text labels beneath each one, all on a white background.

This script:
  1. Makes the white background transparent.
  2. Finds every separate blob of non-white pixels (flood fill / union-find).
  3. Throws away the tiny blobs (the text labels) and the big one on the far
     left (the assembled reference figure).
  4. Sorts what's left into reading order (top row left-to-right, then the
     next row) and writes each out as its own cropped, trimmed PNG.

Usage:
    python3 tools/slice_parts.py assets/source_sheets/sol_tigre_parts.png \
        assets/sprites/fighters/sol_tigre

The output names follow the part order used by the Prompt B sheet layout,
which is also the order FighterVisual expects.
"""

import sys
import os
from collections import deque

from PIL import Image
import numpy as np

# Part names in the order the sheets lay them out.
# The 16-part layout (current) splits out hands, feet, and chest/pelvis so
# wrists, ankles, and the waist can move. The 10-part layout is the older
# sheets. Pick with --parts=10.
PART_NAMES_16 = [
    "head",
    "chest",
    "pelvis",
    "upper_arm_front",
    "forearm_front",
    "hand_front",
    "upper_arm_back",
    "forearm_back",
    "hand_back",
    "thigh_front",
    "shin_front",
    "foot_front",
    "thigh_back",
    "shin_back",
    "foot_back",
]

PART_NAMES_10 = [
    "head",
    "torso",
    "upper_arm_front",
    "forearm_front",
    "upper_arm_back",
    "forearm_back",
    "thigh_front",
    "shin_front",
    "thigh_back",
    "shin_back",
]

# A pixel counts as "background" if every channel is at least this bright.
WHITE_CUTOFF = 238
# Blobs smaller than this many pixels are text labels / specks, not body parts.
MIN_BLOB_PIXELS = 2500


def load_mask(path):
    """Return (rgb array, boolean mask of non-background pixels)."""
    image = Image.open(path).convert("RGB")
    rgb = np.asarray(image)
    solid = ~np.all(rgb >= WHITE_CUTOFF, axis=2)
    return rgb, solid


def find_blobs(solid):
    """Label connected regions of True pixels. Returns list of bounding boxes."""
    height, width = solid.shape
    seen = np.zeros((height, width), dtype=bool)
    boxes = []

    for start_y in range(height):
        for start_x in range(width):
            if not solid[start_y, start_x] or seen[start_y, start_x]:
                continue

            # Breadth-first flood fill over this blob.
            queue = deque([(start_y, start_x)])
            seen[start_y, start_x] = True
            min_x = max_x = start_x
            min_y = max_y = start_y
            count = 0

            while queue:
                y, x = queue.popleft()
                count += 1
                min_x, max_x = min(min_x, x), max(max_x, x)
                min_y, max_y = min(min_y, y), max(max_y, y)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < height and 0 <= nx < width \
                                and solid[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            queue.append((ny, nx))

            if count >= MIN_BLOB_PIXELS:
                boxes.append({
                    "box": (min_x, min_y, max_x + 1, max_y + 1),
                    "pixels": count,
                    "height": max_y - min_y,
                })
    return boxes


def reading_order(boxes):
    """
    Sort boxes into rows (top band first), left-to-right within each row.

    Parts on one row vary a lot in height (a hand next to a whole leg), so
    rows are detected by VERTICAL OVERLAP rather than by matching tops: two
    parts belong to the same row if their y-ranges overlap by a decent share
    of the shorter one.
    """
    if not boxes:
        return []

    rows = []
    for box in sorted(boxes, key=lambda b: b["box"][1]):
        top, bottom = box["box"][1], box["box"][3]
        placed = False
        for row in rows:
            row_top = min(b["box"][1] for b in row)
            row_bottom = max(b["box"][3] for b in row)
            overlap = min(bottom, row_bottom) - max(top, row_top)
            shorter = min(bottom - top, row_bottom - row_top)
            if shorter > 0 and overlap > shorter * 0.45:
                row.append(box)
                placed = True
                break
        if not placed:
            rows.append([box])

    ordered = []
    for row in sorted(rows, key=lambda r: min(b["box"][1] for b in r)):
        ordered.extend(sorted(row, key=lambda b: b["box"][0]))
    return ordered


def cut(rgb, solid, box):
    """Crop a blob out and give it an alpha channel from the solid mask."""
    x0, y0, x1, y1 = box
    patch = rgb[y0:y1, x0:x1]
    alpha = (solid[y0:y1, x0:x1] * 255).astype(np.uint8)
    rgba = np.dstack([patch, alpha])
    return Image.fromarray(rgba, mode="RGBA")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    if len(args) < 2:
        print(__doc__)
        return 1

    part_names = PART_NAMES_10 if "--parts=10" in flags else PART_NAMES_16
    sheet_path, out_dir = args[0], args[1]
    os.makedirs(out_dir, exist_ok=True)

    rgb, solid = load_mask(sheet_path)
    boxes = find_blobs(solid)
    if not boxes:
        print("No parts found — is the background white?")
        return 1

    # The assembled reference figure is the leftmost and tallest blob; drop it.
    tallest = max(b["height"] for b in boxes)
    parts = [b for b in boxes
             if not (b["height"] > tallest * 0.85 and b["box"][0] < rgb.shape[1] * 0.25)]

    ordered = reading_order(parts)
    print(f"{len(boxes)} blobs -> {len(ordered)} parts")

    for index, blob in enumerate(ordered):
        name = part_names[index] if index < len(part_names) else f"part_{index + 1:02d}"
        image = cut(rgb, solid, blob["box"])
        out_path = os.path.join(out_dir, f"{name}.png")
        image.save(out_path)
        print(f"  {name:18s} {image.size[0]:4d}x{image.size[1]:4d}  {out_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
