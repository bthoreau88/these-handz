#!/usr/bin/env python3
"""
preview_rig.py — assemble a fighter's sliced parts using the SAME joint math
as FighterVisual.gd, so a rig can be eyeballed without launching Godot.

Renders the fighter in several poses side by side (idle / walk / punch-active /
block / KO) and writes one preview PNG.

Usage:
    python3 tools/preview_rig.py assets/sprites/fighters/sol_tigre out.png

If a pose looks wrong here it will look wrong in the game — the constants
below are mirrored from FighterVisual.gd. Keep them in sync.
"""

import sys
import os
import math

from PIL import Image

# --- Mirrored from FighterVisual.gd -----------------------------------------
JOINT_INSET = 0.16
BONE_LENGTH = 0.70
HEAD_PIVOT = 0.88
SHOULDER_DROP = 0.12
NECK_DROP = 0.06

PART_NAMES = [
    "head", "torso",
    "upper_arm_front", "forearm_front",
    "upper_arm_back", "forearm_back",
    "thigh_front", "shin_front",
    "thigh_back", "shin_back",
]

POSES = {
    "idle": {
        "torso": 0, "head": 0,
        "arm_front": 8, "elbow_front": -18, "arm_back": -7, "elbow_back": -14,
        "leg_front": 2, "knee_front": 2, "leg_back": -2, "knee_back": 4,
    },
    "walk": {
        "torso": 3, "head": -2,
        "arm_front": -14, "elbow_front": -30, "arm_back": 14, "elbow_back": -20,
        "leg_front": 26, "knee_front": 0, "leg_back": -26, "knee_back": 23,
    },
    "punch": {
        "torso": -9, "head": 4,
        "arm_front": -92, "elbow_front": -4, "arm_back": 26, "elbow_back": -40,
        "leg_front": -14, "knee_front": 4, "leg_back": 14, "knee_back": 10,
    },
    "block": {
        "torso": -8, "head": 6,
        "arm_front": -58, "elbow_front": -96, "arm_back": -44, "elbow_back": -90,
        "leg_front": -6, "knee_front": 8, "leg_back": 6, "knee_back": 10,
    },
    "ko": {
        "torso": 6, "head": 18,
        "arm_front": 30, "elbow_front": -14, "arm_back": -28, "elbow_back": -10,
        "leg_front": -16, "knee_front": 22, "leg_back": 12, "knee_back": 16,
        "_root": -80,
    },
}


def load_parts(folder):
    parts = {}
    for name in PART_NAMES:
        path = os.path.join(folder, name + ".png")
        if not os.path.exists(path):
            raise SystemExit("missing part: " + path)
        parts[name] = Image.open(path).convert("RGBA")
    return parts


def paste_limb(canvas, image, joint_abs, angle_deg, origin_frac_y):
    """
    Place `image` so the pivot (origin_frac_y down its own height) lands on
    `joint_abs`, then rotate it about that point. Rotation happens on a
    full-size layer so a swung-out limb is never clipped — Sprite2D in Godot
    has no bounding box to clip against, and the preview must match.
    Returns the absolute position of the far end of the bone.
    """
    width, height = image.size
    pivot_x, pivot_y = width / 2.0, height * origin_frac_y

    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.alpha_composite(
        image,
        (int(round(joint_abs[0] - pivot_x)), int(round(joint_abs[1] - pivot_y))))
    layer = layer.rotate(
        -angle_deg, resample=Image.BICUBIC, center=joint_abs, expand=False)
    canvas.alpha_composite(layer)

    # Far end of this bone, rotated about the pivot.
    reach = height * (BONE_LENGTH - origin_frac_y)
    rad = math.radians(angle_deg)
    return (joint_abs[0] - math.sin(rad) * reach, joint_abs[1] + math.cos(rad) * reach)


def chain(canvas, parts, upper_name, lower_name, joint, upper_deg, lower_deg):
    upper = parts[upper_name]
    elbow = paste_limb(canvas, upper, joint, upper_deg, JOINT_INSET)
    lower = parts[lower_name]
    # The lower segment inherits the upper's rotation (parented in Godot).
    paste_limb(canvas, lower, elbow, upper_deg + lower_deg, JOINT_INSET)


def render(parts, pose, canvas_size):
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    origin = (canvas_size[0] / 2.0, canvas_size[1] * 0.52)  # hip position

    torso_h = parts["torso"].size[1]
    torso_top = -torso_h
    # Absolute canvas coordinates for each anchor.
    shoulder = (origin[0], origin[1] + torso_top + torso_h * SHOULDER_DROP)
    neck = (origin[0], origin[1] + torso_top + torso_h * NECK_DROP)
    hip = (origin[0], origin[1])

    # Back limbs, torso, head, then front limbs — matching Godot draw order.
    chain(canvas, parts, "upper_arm_back", "forearm_back",
          (shoulder[0] - 8, shoulder[1]), pose["arm_back"], pose["elbow_back"])
    chain(canvas, parts, "thigh_back", "shin_back",
          (hip[0] - 6, hip[1]), pose["leg_back"], pose["knee_back"])

    paste_limb(canvas, parts["torso"], hip, pose["torso"], 1.0)
    paste_limb(canvas, parts["head"], neck, pose["head"], HEAD_PIVOT)

    chain(canvas, parts, "thigh_front", "shin_front",
          (hip[0] + 6, hip[1]), pose["leg_front"], pose["knee_front"])
    chain(canvas, parts, "upper_arm_front", "forearm_front",
          (shoulder[0] + 9, shoulder[1]), pose["arm_front"], pose["elbow_front"])

    if "_root" in pose:
        canvas = canvas.rotate(
            -pose["_root"], resample=Image.BICUBIC, center=origin, expand=False)
    return canvas


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    folder, out_path = sys.argv[1], sys.argv[2]
    parts = load_parts(folder)

    cell = (640, 1250)
    sheet = Image.new("RGB", (cell[0] * len(POSES), cell[1]), (58, 56, 68))
    for index, (name, pose) in enumerate(POSES.items()):
        frame = render(parts, pose, cell)
        sheet.paste(frame, (cell[0] * index, 0), frame)
    sheet.thumbnail((1700, 1700))
    sheet.save(out_path)
    print("wrote", out_path, "poses:", ", ".join(POSES))
    return 0


if __name__ == "__main__":
    sys.exit(main())
