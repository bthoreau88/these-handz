# OVS-GAME-G01 — Independent MSI Execution Receipt (2026-11-07)

**Authority:** founder: "Move to next gate."  
**Disposition:** SOURCE/ENGINE TESTS PASS; SCREEN CAPTURE PASS; SAME-SOURCE VISUAL COMPARISON REVIEW-READY; PHYSICAL iPHONE & WEB-RENDERING EQUIVALENCE HOLD.  
**Repository:** `bthoreau88/these-handz` / PR #3; source `ae127ff2bcc49a728c86117124099e658aee264d`; separate clean clone `C:\Users\thore\Documents\OVS-GAME-G01-QUALITY-REVIEW`.  
**Build:** Godot `4.7.stable.official.5b4e0cb0f`, Windows MSI / NVIDIA RTX 4070 Laptop GPU (Vulkan Forward Mobile). **No** edits to original `these-handz`, G01C, production branch, or character assets.

## 1. Engine execution: PASS

The clean PR #3 source was cloned and imported with the installed Godot 4.7 editor; import **exit 0**.

Re-run on 2026-11-07 (all exit code 0, no reported failures):

| Suite | Passed | Failed |
| --- | ---: | ---: |
| G01 original runtime smoke | 11 | 0 |
| G01A full match + CPU | 19 | 0 |
| G01B gesture regression | 13 | 0 |
| G01B dual/solo routing | 3 | 0 |
| G01B buffered-special execution | 3 | 0 |
| **OVS_GAME_G01_quality_probe** | **10** | **0** |
| **Total** | **59** | **0** |

Quality probe structured JSON stored at `%APPDATA%\Godot\app_userdata\THESE HANDZ\OVS_GAME_G01_quality_probe.json`. Key observations:
- 8 configured fighters, 2 fighters + camera in scene.
- Simulated keyboard tap routed to P1 attack on signal; **not** input-to-display latency.
- Distant light at 1,400 px whiffed: defender health **1000→1000**.
- Close light at 120 px landed: **38** health points damage; defender health **1000→962**, HUD **962**.
- Parry authored at **6 physics frames**, expires when unanswered.
- Physics clamps character at **x=40 / x=1880** stage boundaries.

**Limitations:** headless, synthetic stimulus, no measured frame pacing, no human control comfort, no image-quality certification.

## 2. Repeatable live visual captures: PASS as evidence capture, not art approval

`tools/OVS_GAME_G01_capture.gd` executed twice with **exit 0** in a live graphics session. Each run produced 3 PNGs at **1280×720** and `manifest.json`, including fixture positions, camera pose, render backend, engine version, and source PNG SHA-256.

Capture runs are at:
- `%APPDATA%\Godot\app_userdata\THESE HANDZ\OVS_GAME_G01_visual_1794103943`
- `%APPDATA%\Godot\app_userdata\THESE HANDZ\OVS_GAME_G01_visual_1794104012`

Fixture positions:
- `neutral_opening`: P1 x=740, P2 x=1180, camera x=960, zoom ~0.89244
- `mid_range`: P1 x=840, P2 x=1030, camera x=935, zoom ~0.95356
- `wide_separation`: P1 x=200, P2 x=1720, camera x=960, zoom 0.78

Manual inspection of the three rendered frames:
- HUD names, health bars and round timer are visible.
- Both characters remain visible in the inspected wide-separation frame, near opposite screen edges.
- The Miami dusk stage is flat placeholder cityscape; Yellow Dog appears as a bright rectangular placeholder, while Sol Tigre uses provisional art and a debug hurtbox overlay. **Cannot approve visual quality or IP rights.**
- Strongest immediate visual bottleneck is **in-game fighter art/presentation**, not the screenshot capture tool.

## 3. Same-source comparison: REVIEW_READY (not pixel-perfect)

`tools/OVS_GAME_G01_compare.py` ran with exit code **0** and wrote a full comparison/diff record to `C:\Users\thore\Documents\OVS-GAME-G01-COMPARISON-V001`.

At pixel threshold 12/255, per 921,600-pixel image:

| Fixture | Changed pixels | Fraction changed | Tool disposition |
| --- | ---: | ---: | --- |
| neutral_opening | 111 | 0.000120 | REVIEW_REQUIRED |
| mid_range | 507 | 0.000550 | REVIEW_REQUIRED |
| wide_separation | 10 | 0.000011 | REVIEW_REQUIRED |

The changes are small and consistent with dynamic frame timing or transient presentation, but **cause is not proven**. Screenshot comparison proves tooling can detect real differences, not that one render is superior. Equal-source reruns are not byte-identical. Reviewer should inspect change masks and confirm whether fighter animation causes the deltas before using pixel thresholds for an art gate.

## 4. Branching and next gate

- G01 quality PR #3 is a **stacked draft on G01B**, and it remains distinct from G01C PR #4. These branches must not be conflated or merged without reconciliation.
- Separate G01C implementation reports **73/73 scripted passes** and filtered browser Web export, but physical iPhone Safari and mobile frame pacing still require validation.
- **Advance to human-readiness planning, not release:** `THESE-HANDZ-G01D — Physical Mobile Acceptance + Visual/IP Authority + Performance Budget`.
- G01D must examine the **G01C safe Web build**, not a speculative output from G01's Vulkan/Mobile screenshot fixture. Re-run actual browser fixtures under G01C's Compatibility/WebGL2 renderer before comparing visually with phone screenshots.
- Do not publish, grant rights clearance, promote character designs, modify `main`, spend credits or merge any draft PR from this document.

**Reproducibility note:** outputs currently live on the MSI and are **not** attached to GitHub. Filenames/hashes and working folders alone do not create a publicly accessible image archive.
