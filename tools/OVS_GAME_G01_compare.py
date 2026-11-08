#!/usr/bin/env python3
"""OVS-GAME-G01: compare equivalent Godot visual captures. Detection != quality.
Requires Pillow (pip install pillow). No game files are modified.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def load_manifest(folder: Path) -> dict:
    with (folder / "manifest.json").open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if data.get("gate") != "OVS-GAME-G01":
        raise ValueError(f"Not a G01 manifest: {folder}")
    return data


def comparable_fixture(a: dict, b: dict) -> list[str]:
    issues = []
    for key in ("fighters", "size"):
        if a.get(key) != b.get(key):
            issues.append(f"{key} differs")
    for key in ("p1_position", "p2_position", "camera_position", "camera_zoom"):
        av, bv = a.get(key, {}), b.get(key, {})
        if not isinstance(av, dict) or not isinstance(bv, dict):
            issues.append(f"{key} missing")
            continue
        for axis in ("x", "y"):
            if axis not in av or axis not in bv or abs(float(av[axis]) - float(bv[axis])) > 0.5:
                issues.append(f"{key}.{axis} differs")
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--pixel-threshold", type=int, default=12)
    args = parser.parse_args()
    if not 0 <= args.pixel_threshold <= 255:
        parser.error("--pixel-threshold must be 0..255")
    try:
        from PIL import Image, ImageChops, ImageStat
    except ImportError:
        print("BLOCKED: Pillow missing. Install with: python -m pip install pillow", file=sys.stderr)
        return 2

    try:
        baseline = load_manifest(args.baseline)
        candidate = load_manifest(args.candidate)
        args.output.mkdir(parents=True, exist_ok=True)
        report: dict = {
            "gate": "OVS-GAME-G01",
            "automated_visual_quality_claim": False,
            "pixel_threshold": args.pixel_threshold,
            "baseline": str(args.baseline),
            "candidate": str(args.candidate),
            "comparisons": [],
        }
        mismatch = [
            key for key in ("engine", "display_backend")
            if baseline.get(key) != candidate.get(key)
        ]
        ba = {item["name"]: item for item in baseline["captures"]}
        ca = {item["name"]: item for item in candidate["captures"]}
        names = sorted(set(ba) | set(ca))
        invalid = bool(mismatch)
        if mismatch:
            report["environment_mismatch"] = mismatch
        for name in names:
            entry = {"fixture": name, "status": "NO_EVIDENCE"}
            report["comparisons"].append(entry)
            if name not in ba or name not in ca:
                entry["reason"] = "missing fixture in baseline or candidate"
                invalid = True
                continue
            mismatches = comparable_fixture(ba[name], ca[name]) + mismatch
            if mismatches:
                entry.update(status="NOT_COMPARABLE", reason=", ".join(mismatches))
                invalid = True
                continue
            a_path = args.baseline / ba[name]["filename"]
            b_path = args.candidate / ca[name]["filename"]
            if not a_path.is_file() or not b_path.is_file():
                entry["reason"] = "PNG does not exist"
                invalid = True
                continue
            with Image.open(a_path) as a_image, Image.open(b_path) as b_image:
                a = a_image.convert("RGB")
                b = b_image.convert("RGB")
                if a.size != b.size:
                    entry.update(status="NOT_COMPARABLE", reason="PNG dimensions differ")
                    invalid = True
                    continue
                diff = ImageChops.difference(a, b)
                stats = ImageStat.Stat(diff)
                changed = sum(1 for px in diff.getdata() if max(px) > args.pixel_threshold)
                fraction = changed / (a.width * a.height)
                diff_file = f"diff_{name}.png"
                diff.save(args.output / diff_file)
                entry.update(
                    status="REVIEW_REQUIRED" if changed else "UNCHANGED",
                    mean_absolute_channel_error=round(sum(stats.mean) / 3, 4),
                    changed_pixel_fraction=round(fraction, 6),
                    changed_pixels=changed,
                    pixel_count=a.width * a.height,
                    diff_png=diff_file,
                )
        if not names:
            invalid = True
            report["error"] = "No fixtures found"
        report["status"] = "INCOMPLETE" if invalid else "REVIEW_READY"
        output_path = args.output / "comparison.json"
        output_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"OVS_GAME_G01_COMPARISON={output_path}")
        for item in report["comparisons"]:
            print(item["fixture"], item["status"], item.get("changed_pixel_fraction", ""))
        print("Human reviewer required. Pixel differences do not prove quality.")
        return 2 if invalid else 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"BLOCKED: invalid input/capture: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
