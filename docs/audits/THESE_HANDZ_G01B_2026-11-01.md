# THESE HANDZ — G01B Touch Input, Visual Feasibility & Web Export Audit

**OVS gate:** THESE-HANDZ-G01B  
**Date:** 2026-11-01 (America/Los_Angeles)  
**Disposition:** **AUTOMATED TESTS PASS / WEB EXPORT BLOCKED BY MISSING TEMPLATES / HUMAN DEVICE QA PENDING**  
**Source:** `bthoreau88/these-handz`, stacked review branch `ovs/these-handz-g01b-touch-web-audit-20261101`  
**No merge, paid generation, or LMG course purchase authorized.**

## 1. Protected source and local workspace

- **Immutable original MSI working copy:** `C:\Users\thore\Documents\these-handz`; HEAD `7d49cac27c2f052884db70cb1b98820b3e2f5782`, with prior local Godot metadata/config still unmodified by these gates.
- **Prior G01A backup:** `C:\Users\thore\Documents\THESE-HANDZ-G01A-LOCAL-STATE-20261101.zip`, SHA-256 `A91FB0679643B16775652183C3F4A48C98B0719AE441F881F5187D3437C55005`.
- **Isolated G01B development/test copy:** `C:\Users\thore\Documents\THESE-HANDZ-G01B-REVIEW`, originally based on G01A review commit `7f2edf03eee72414353c634221f55368e98cabcf`.
- **Runtime:** Godot `4.7.stable.official.5b4e0cb0f` on Windows MSI.
- **GitHub staging:** G01B review branch based on G01A review branch; main branch and original MSI files untouched.

## 2. Findings and targeted patches

### A. Mirrored specials were not recognized
**Prior behavior:** The gesture parser only completed `←→` or `↓→`; right-side left-facing moves `→←` and `↓←` were not recognized.  
**Patch:** `scripts/input/GestureInput.gd` now recognizes either horizontal completion direction, still requiring the same screen half and the `SPECIAL_SEQUENCE_WINDOW_MS` interval. The raw input authority and routing remain unchanged.

### B. Special B could be swallowed even when recognized
**Reproduction:** A real `down → right` touch sequence sent a downward swipe, starting the low attack; the subsequent `special_b` was rejected because `CharacterBase.receive_gesture()` blocks actions while `ATTACKING`. The direct gameplay-path test failed before patch.
**Patch:** `CharacterBase` accepts only `special_a`/`special_b` as bounded buffered commands while already attacking, executes after normal attack recovery, expires the buffer, and cancels it when interrupted or on round reset. `GameConstants.SPECIAL_INPUT_BUFFER_FRAMES = 30` is the sole tuning value. No hitbox numbers, fighter kits, or cooldown values were changed.
**Validation:** Yellow Dog starts a low from the first swipe, queues the completed Special B, then executes Smoke Cloud after recovery.

### C. Touch walking remains unimplemented
The recognizer currently maps press/release gestures to taps, swipes, hold-charge, block, parry and specials. Continuous touch movement is not implemented; keyboard `←/→` is a desktop fallback. A true mobile movement design and backdash treatment remain **release blockers**, not silently assumed working.

## 3. Automated execution matrix

| Test | Result | Evidence scope |
|---|---|---|
| `tests/G01_runtime_smoke.gd` | **11/11 PASS** | Original runtime smoke tests, roster scenes, hit detection, HUD and stage/camera nodes |
| `tests/G01A_full_match.gd` | **19/19 PASS** | Simulated KO, timeout, meter carry, round flow, CPU countdown, complete simulated CPU match |
| `tests/G01B_gesture_regression.gd` | **13/13 PASS** | Synthetic InputEventScreenTouch press/release, four swipes, tap, hold, two-finger gestures, normal and mirrored specials |
| `tests/G01B_touch_router.gd` | **3/3 PASS** | P1 left-side, P2 right-side, solo full-screen touch routing |
| `tests/G01B_special_combo.gd` | **3/3 PASS** | Low opener, special input buffer, delayed special execution |
| **Total** | **49/49 PASS** | In-engine scripted validation only |

The headless synthetic tap test explicitly compensates for input-event coordinate scaling in a headless viewport; its passing result does not measure actual touch latency or device gesture drift. The expanded match test forces some events/positions rather than proving natural CPU quality. The tests do not verify 60 FPS, iOS compatibility, touch walking, player enjoyment, accessibility, or in-game animation rendering.

### Reproduction commands (on MSI review clone)

```powershell
$godot = "C:\Users\thore\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
$project = "C:\Users\thore\Documents\THESE-HANDZ-G01B-REVIEW"
& $godot --headless --path $project --script res://tests/G01_runtime_smoke.gd
& $godot --headless --path $project --script res://tests/G01A_full_match.gd
& $godot --headless --path $project --script res://tests/G01B_gesture_regression.gd
& $godot --headless --path $project --script res://tests/G01B_touch_router.gd
& $godot --headless --path $project --script res://tests/G01B_special_combo.gd
```

## 4. Visual & frame-pacing audit

**Five-pose offline rig preview:** `tools/preview_rig.py` executed successfully against the existing clean `assets/sprites/fighters/crown_saint` source parts, creating `build/G01B_crown_saint_rig_preview.png` (~476 KB) with idle/walk/punch/block/KO composites. This verifies the offline puppet preview script runs, **not** in-engine render quality or frame pacing.

**Frame pacing:** **NOT MEASURED ON DEVICE.** No valid 60 FPS claim can be made from a headless engine harness. Required: inspect render/physics frame times on an actual representative mobile device, assess parallax and camera behavior during active fights, and confirm assets/stage scale cleanly.

**Art completeness:** Most of the eight-fighter roster still uses placeholders; Sol Tigre has trademark-contaminated source assets that remain quarantined. The preview is an engineering artifact, not shipping art approval.

## 5. Web export feasibility

The review branch contains a single-threaded `Web` export preset (`variant/thread_support=false`, no extension support, mobile VRAM compression enabled, PWA disabled) compatible in concept with Godot 4's WebAssembly + WebGL 2 compatibility renderer requirements.

**Attempted on MSI, actual result:** `--export-release Web build/web/index.html` failed with exit code 1 because the matching Godot 4.7 templates were absent. Exact missing files:
- `C:\Users\thore\AppData\Roaming\Godot\export_templates\4.7.stable\web_nothreads_debug.zip`
- `C:\Users\thore\AppData\Roaming\Godot\export_templates\4.7.stable\web_nothreads_release.zip`

No `index.html` or runnable Web build was produced. `tools/G01B_export_web.ps1` was added, and its template preflight executed with a deliberate, explicit `G01B_WEB_BLOCKED` result and exit code 2. This is a real environment blocker rather than a game-code regression.

**After installing the official matching export templates** in Godot Editor > Manage Export Templates, run:
```powershell
& ".\tools\G01B_export_web.ps1" -GodotExe "C:\Users\thore\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
```

**Browser restrictions:** The Godot Web exporter uses WebAssembly and WebGL 2.0 / Compatibility. Single-threaded exports avoid COOP/COEP isolation requirements, but mobile Safari, WebGL support and runtime performance must be tested on actual hardware. No hosting or publication is authorized by this audit.

References:
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html

## 6. Governance and next gate

**G01B = CODE/TESTS APPROVED FOR DRAFT REVIEW ONLY. NOT RELEASE/CANON LOCKED.**
- No changes to `main`.
- No paid LMG content or proprietary engine imported.
- No new fighters; no trademark-contaminated art promoted.
- Touch controls are not device-certified; browser export is blocked.
- Manual performance and visual inspection remain pending.

**Next recommended gate: `THESE-HANDZ-G01C — Mobile Movement Design, Export Template Recovery & Physical Device Proof`.** It must establish a workable touch-walk/backdash interaction, generate a real Web build after templates install, then run the full menu → fight → rematch flow on a phone with frame pacing and gesture error logs. Maintain zero-credit and advance-only review governance.
