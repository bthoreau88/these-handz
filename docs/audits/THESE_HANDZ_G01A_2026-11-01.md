# THESE HANDZ — G01A Source Reconciliation and Full-Match Validation

**Gate:** THESE-HANDZ-G01A · **Date:** 2026-11-01 (America/Los_Angeles)  
**Authority:** OVS review candidate only · **No merge to `main`**  
**Runtime:** Godot 4.7.stable.official.5b4e0cb0f, Windows MSI  
**Disposition:** **AUTOMATED VALIDATION PASSED / HUMAN DEVICE QA PENDING**

## 1. Source safety

- **Original MSI checkout:** `C:\Users\thore\Documents\these-handz`; HEAD `7d49cac27c2f052884db70cb1b98820b3e2f5782`. Remains untouched by this gate. The original checkout had one modified `project.godot` plus generated UID/import metadata.
- **Backup of original working-state differences:** `C:\Users\thore\Documents\THESE-HANDZ-G01A-LOCAL-STATE-20261101.zip`. SHA-256 `A91FB0679643B16775652183C3F4A48C98B0719AE441F881F5187D3437C55005`. Includes working `project.godot`, original untracked Godot metadata, head/status text, and a hash manifest. Existing Git history still protects the tracked code.
- **GitHub baseline:** `main` at `2494586ff9cd91446e7e9d0fe305acadc33dc9f3`.
- **Isolated local validation copy:** `C:\Users\thore\Documents\THESE-HANDZ-G01A-REVIEW`, cloned from the newer GitHub baseline. Godot import and G01 11-check smoke test passed. No forced merge, reset, or replacement of the original working folder.
- **GitHub review branch:** `ovs/these-handz-g01a-validation-20261101`, based on prior G01 review branch. Production changes remain isolated pending review.

## 2. Reconciled architecture

The newer GitHub version already incorporates `StageBackground.gd`, `FightCamera.gd`, and their scene-node bindings, absent from the older MSI checkout. No stage rewrite was needed.

The existing three production laws remain intact:
1. Tunable gameplay values belong to `scripts/GameConstants.gd`.
2. Human input follows `GestureInput → InputRouter → CharacterBase.receive_gesture()`. CPU synthesizes compatible gesture dictionaries.
3. Touch-first design remains governing; no quarter-circle control system was added.

No changes were made to the locked eight-fighter roster, combat balance, original art, or quarantined trademark-affected assets.

## 3. Discovered gameplay defect: CPU violates countdown lock

### Before patch

The baseline AIController ticked its decision loop even when `RoundManager._fighting` was false. Players were prevented from acting during countdown by `InputRouter`, but CPU decisions bypassed that gate and could start walking/attacking before `FIGHT!`.

The expanded smoke test reproduced this on the unmodified baseline: its CPU-countdown test failed. In a 16-check baseline run, 14 checks passed, 2 failed (the second CPU-live-engagement assertion was affected by early movement).

### Review-branch patch

**Exactly three production files changed:**
- `scripts/managers/RoundManager.gd` — exposes `is_round_live()` as a read-only public state check.
- `scripts/ai/AIController.gd` — checks that state before making CPU combat decisions, releasing any lingering walk/block during nonlive phases.
- `scenes/FightScene.gd` — supplies `round_manager` when setting up the CPU controller.

No tunables, input routing rules, roster data, or gameplay timing constants changed.

## 4. Evidence and automated tests

Run against the review candidate after asset import:

```powershell
& "C:\Users\thore\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\thore\Documents\THESE-HANDZ-G01A-REVIEW" --script "res://tests/G01A_full_match.gd"
```

**G01 original smoke harness:** 11/11 PASS.  
**G01A extended harness:** **19/19 PASS**, exit code 0.  

The extended harness covers: round countdown input lock, premature input suppression, activation at `FIGHT!`, gesture-to-attack and real hitbox damage, meter fill, KO round award, round two transition, health reset, 50% meter carry, forced-clock time-out, best-of-three match winner, CPU scene attachment, CPU inactivity before `FIGHT!`, CPU engagement once live, and a complete two-round simulated CPU-opponent match.

Test methods intentionally set `Engine.time_scale=10`, inject deterministic keyboard-equivalent gestures, manually position fighters for a hit, and force KO/timeout inputs through the existing game objects. These tests validate engine/state-machine integration, **not** human-input ergonomics, organically played CPU strategy, performance, or animation quality.

**Reproduction:** Baseline and patched test runs used Godot 4.7 with isolated project copies. The unpatched baseline failed the CPU countdown assertion; patched candidate passed, confirming the regression repair.

## 5. Remaining release blockers

- On-device, human-operated touchscreen match (all gestures, movement, two-finger input, parry).
- Real CPU difficulty and fairness assessment, not forced simulated KO.
- Visual presentation and 60fps performance on a representative phone.
- Character collision, projectiles, specials, and menu→fight→rematch manual walkthrough.
- Browser export verification and Safari/Android compatibility testing.
- The standalone v3 franchise bible is not in the GitHub repo; exact canon move reconciliation still awaits its authoritative source.
- Quarantined Sol Tigre trademark-afflicted art remains explicitly non-shippable.

## 6. Disposition

**G01A — AUTOMATED GATE PASSED / REVIEW CANDIDATE HELD.** No `main` merge, no app-store/export release claim, no paid LMG purchase or proprietary engine adoption, no paid asset generation.

**Next recommended gate:** `THESE-HANDZ-G01B — Human Touch QA, Visual Frame Pacing and Browser Export Feasibility`. Record device/build, inputs, round results, visible artifacts, runtime errors and corrective actions. Promote only after human acceptance and review of the patch.
