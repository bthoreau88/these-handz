# THESE HANDZ — G01C Mobile Movement + Web Export Recovery + Device Proof

**Date:** 2026-11-06, Pacific  
**Project:** `bthoreau88/these-handz`  
**Review branch:** `ovs/these-handz-g01c-mobile-web-proof-20261106` (stacked on G01B)  
**Gate disposition:** **AUTOMATED MOVEMENT PASS / SAFE WEB EXPORT PASS / DESKTOP BROWSER PLAY PASS / PHYSICAL IPHONE SAFARI PROOF ON HUMAN HOLD**  
**Canonical/production promotion:** NONE. **Merge:** NONE. **Paid generation/course purchases:** NONE.

## 1. Source and asset authority

- Original MSI working copy `C:\Users\thore\Documents\these-handz` remains on original HEAD `7d49cac27c2f052884db70cb1b98820b3e2f5782`; its uncommitted Godot configuration and generated IDs remain preserved.
- Prior backup of local changes: `C:\Users\thore\Documents\THESE-HANDZ-G01A-LOCAL-STATE-20261101.zip`; SHA256 `A91FB0679643B16775652183C3F4A48C98B0719AE441F881F5187D3437C55005`.
- New isolated MSI worktree: `C:\Users\thore\Documents\THESE-HANDZ-G01C-REVIEW`. No forced reset of the user's original checkout.
- Separate G01C GitHub review branch based on G01B; production inputs stay governed by `GameConstants`, `GestureInput → InputRouter → CharacterBase.receive_gesture()`, and the locked 8-fighter roster.
- No licensed LMG engine/code/curriculum imported.

## 2. Mobile movement implementation

**Visual design:** two oversized directional touch targets at the lower left for P1, and a matching lower-right pair for P2 when human-vs-human. Solo CPU mode displays only P1's pads. Teal indicates P1; gold indicates P2. A dedicated `TouchControlsVisual` draws shapes and receives no pointer events (`MOUSE_FILTER_IGNORE`).

**Single input authority:** `GestureInput` owns touch-hit testing for the pads and emits the exact same `walk_left_start/end` and `walk_right_start/end` semantic actions already understood by `InputRouter` and `CharacterBase`. Movement fingers are tracked separately from attack fingers; one movement finger does not turn a simultaneous normal tap into an accidental two-finger parry. Finger release, round end and scene exit clear held movement, including when a scene is shutting down and has lost its viewport.

**Animation/combat behavior:** movement intent can be captured during an attack and takes effect only once neutral. Normal attacks, specials, hitstop/attack frame data, parry, roster kits and meter tuning were not altered by this gate.

**Backdash:** an outward horizontal swipe triggers a timed retreat relative to current facing. Forward swipe retains its original conditional medium/dash behavior. Backdash speed and duration are the only new movement-tuning numbers, centralized in `GameConstants.gd`.

**Changed production sources:** `scripts/GameConstants.gd`, `scripts/input/GestureInput.gd`, `scripts/characters/CharacterBase.gd`, `scripts/managers/InputRouter.gd`, `scripts/visual/TouchControlsVisual.gd` (new), `scenes/FightScene.gd`, `project.godot`, `export_presets.cfg`.

## 3. Executed regression evidence

Godot 4.7.stable.official.5b4e0cb0f on MSI, headless, with all scripts exiting code 0 and **zero reported script errors** after shutdown correction:

| Suite | Checks | Result |
| --- | ---: | --- |
| G01 smoke: combat, stage/camera and roster | 11 | PASS |
| G01A full match: KO, timeout, meter and CPU | 19 | PASS |
| G01B raw touch recognizer and mirrored specials | 13 | PASS |
| G01B dual-player/solo routing | 3 | PASS |
| G01B two-swipe special execution | 3 | PASS |
| G01C virtual pad, simultaneous touch + attack, sustained movement, release, backdash and scene cleanup | 24 | PASS |
| **Total** | **73** | **PASS** |

Run the G01C suite:
```powershell
& "C:\Users\thore\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\thore\Documents\THESE-HANDZ-G01C-REVIEW" --script res://tests/G01C_mobile_movement.gd
```

This does not prove real iPhone ergonomics, hardware FPS or latency.

## 4. Official Godot 4.7 Web template recovery

Official source: https://godotengine.org/download/archive/4.7-stable/ . The official download redirects to a Godot release object-storage archive, `Godot_v4.7-stable_export_templates.tpz` (~1.28 GB).

`tools/G01C_install_web_templates.ps1` uses HTTP byte ranges to read the ZIP central directory and fetch **only** these required entries, then validates each ZIP entry's decompressed length and CRC32, and installs into `%APPDATA%\Godot\export_templates\4.7.stable` without overwriting an existing file:

- `web_nothreads_debug.zip`: **10,227,986 bytes**; CRC32 1004355425; SHA256 `3467F4B041216D43F0ABD590BB995BF6C8EB1E2DE715E1D7C9B5B765509EFEB8`.
- `web_nothreads_release.zip`: **10,243,416 bytes**; CRC32 1212310623; SHA256 `6E1D01E7D8995A2DFEC8B33DC530F02C034906267EC441288C2A3318D49E00B9`.

Both official templates recovered and installed, no paid credits used.

## 5. Web export proof and asset containment

- Godot 4.7 Web requires **Compatibility renderer / WebGL 2.0**, so this *review-only* project `project.godot` was switched from Mobile to Compatibility rendering. This change has not been promoted to main or native production.
- Initial export validation found a second dependency: the Web preset requested mobile VRAM compression without ETC2/ASTC import. For the browser proof, `vram_texture_compression/for_mobile=false` corrected that without changing art source files.
- Actual `--export-release Web` returned **exit 0**, producing `build/web/index.html`, `index.wasm`, `index.js`, and `index.pck`.
- **Security catch:** first unfiltered experimental Web pack included `_HOLD_` / `TRADEMARKS` source-authority assets. That old pack was renamed under `build/_HOLD_web_unfiltered_20261106/`, not published.
- The Web export preset now excludes `res://assets/source_sheets/*`, `res://tests/*`, `res://tools/*`, `res://docs/*`, and `res://build/*` to avoid both quarantined assets and generated output self-inclusion.
- Final clean `index.pck`: **2,274,928 bytes**, SHA256 `83A755D280700BAAABD0200D73B637642C8932A8F5A4105C33615325AB5FB9B2`. Binary audit confirmed absence of `_HOLD_`, `TRADEMARKS`, `source_sheets`, and `res://build/` markers, while checking that playable `assets/sprites` paths remain.
- Total build directory around 42.1MB (includes a few locally generated `.import` metadata files; actual required Web artifacts are HTML/JS/WASM/PCK and icons). No restricted source sheets intentionally bundled.
- `tools/G01C_export_web_safe.ps1` is a repeatable local-only exporter / quarantine marker checker / SHA256 receipt generator. A successful validation produced `build/G01C_WEB_EXPORT_RECEIPT.txt`.

**Limitation:** This automated binary exclusion check proves the named quarantined paths/markers are absent, **not** that all rendered art has passed final IP or visual clearance. Sol Tigre artwork remains subject to independent visual/rights approval before any public exposure.

## 6. Real browser smoke evidence

A temporary Python HTTP server was started on loopback to serve the local export. Puppeteer-controlled installed Chrome (headless, separate profile) loaded `index.html`, `index.wasm`, and `index.pck` over HTTP 200.

**Verified from Chrome console:** Godot 4.7 engine initialized; WebGL 2.0 / OpenGL ES 3.0 / Compatibility active; Emscripten 4.0.20, single-threaded; **0 page JavaScript errors**.

**Actual gameplay path:** automated Chrome clicked Sol Tigre and Yellow Dog, entered the fight scene, sent a held touch event to the on-screen move pad and then a touch attack. All returned without browser errors. Screenshots captured locally as `build/G01C_browser_fight_entry.png`, `build/G01C_browser_touch_hold.png`, and `build/G01C_browser_after_touch_attack.png`.

**Mobile-responsive smoke:** Chrome device emulation at 852x393 CSS pixels, deviceScaleFactor 3, `isMobile=true`, `hasTouch=true`, loaded the menu and WebGL 2.0 with no reported console/page errors. Screenshot at `build/G01C_mobile_chrome_landscape.png`. **Emulation is not a physical iPhone Safari pass.**

## 7. Private device test and acceptance hold

A local-only/private Wi-Fi HTTP server was set up to host the **filtered** build from the MSI, with a transient device-test link shared directly with the founder. The network address is deliberately **not committed to this public repository**. The MSI confirmed HTTP 200 against its own Wi-Fi IP. Incoming access from a second physical device has NOT been verified.

**Human approval criteria:**
1. On actual iPhone Safari, same Wi-Fi, landscape, select both fighters and start an entire CPU match without loading errors.
2. Hold each P1 directional pad for several seconds; check travel, movement while attacking, and immediate stop on release. In P2 human mode, validate each side independently.
3. Test light/medium/heavy, jump/low, two-finger block/parry, normal and mirrored specials, combo buffer and backdash. Repeat under stress and rapid finger changes.
4. Play through countdown, KO, transition, 2 rounds and return to character select; inspect unexpected input carry and accidental hits.
5. Observe responsiveness, screen fit, thermal/load time, frame pacing and text legibility. Attach screenshots or a short screen recording if possible.
6. Record device/browser version and explicit human PASS/FAIL before promoting.

## 8. Release governance / next gate

**G01C technical implementation: PASS. Browser export: PASS. Private desktop-browser interaction: PASS. Physical iPhone verification: HOLD.**

No merge into `main`, no public deployment, no asset/IP clearance, no paid spending, no canonical release. The app remains a gray-box with provisional sprites and placeholder Yellow Dog visuals. Touchscreen device comfort, Safari performance, and rights clearance still need human sign-off.

**Recommended next gate once device evidence exists:** `THESE-HANDZ-G01D — Physical Mobile Acceptance + Visual/IP Authority + Performance Budget`. Run one named matchup across a short repeatable test matrix; confirm stable user feel, original art, and measurable frame pacing before any distribution.
