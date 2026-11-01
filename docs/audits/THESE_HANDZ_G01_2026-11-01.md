# OVS / THESE HANDZ — G01 Runtime Audit + LMG Selective Adoption Proof

**Audit date:** 2026-11-01 (Pacific)  
**Disposition:** G01 technical audit complete; production-ready alpha **NOT** certified.  
**Credit / purchase cost:** $0.  
**Branch:** `ovs/these-handz-g01-runtime-audit-20261101` (review only; no merge authorized).  
**Repository:** `bthoreau88/these-handz`.

## 1. Immutable source baselines

| Source | Git commit | Status |
| --- | --- | --- |
| MSI working folder `C:\Users\thore\Documents\these-handz` | `7d49cac27c2f052884db70cb1b98820b3e2f5782` | Original preserved, local modifications left untouched |
| GitHub `main` | `2494586ff9cd91446e7e9d0fe305acadc33dc9f3` | Independently cloned and audited |

The MSI original had an uncommitted `project.godot` migration (4.2 → 4.7 metadata) and generated Godot UID/import files. **No reset, pull, overwrite, or in-place merge was performed.** Both tests ran against fresh, disposable clones under `%TEMP%`.

## 2. Real engine and execution

**Runtime:** Godot 4.7.stable.official.5b4e0cb0f, Windows MSI.  
**Editor startup / import:** exit 0 on both isolated snapshots, without reported script errors.  
**Direct FightScene headless smoke:** exit 0 for old local source; this only establishes initial scene startup and frames.

The 11-check scripted harness used:
```powershell
& "<path-to-Godot-console-exe>" --headless --path "<isolated-project-clone>" --script "res://tests/G01_runtime_smoke.gd"
```
If executed directly from this branch, first let the Godot editor import project assets. The prior temporary copies used the equivalent script from their root folders.

## 3. Repeatable harness results

| Check | Older local HEAD | GitHub main |
| --- | :---: | :---: |
| Two selected fighter instances | PASS | PASS |
| Full-health initialization | PASS | PASS |
| Meter and parry initialization | PASS | PASS |
| InputRouter receives fighter references | PASS | PASS |
| Round 1 starts | PASS | PASS |
| Keyboard-equivalent gesture enters ATTACKING | PASS | PASS |
| Active-frame hitbox reduces opposing health | PASS | PASS |
| Health UI reflects damage | PASS | PASS |
| Stage background node present | FAIL | PASS |
| Camera node present | FAIL | PASS |
| All eight roster scenes instantiate | PASS | PASS |
| **TOTAL** | **9 / 11** | **11 / 11** |

**Failure classification:** stale local Git version, not a demonstrated regression on GitHub main. Local HEAD lacks `scripts/stages/StageBackground.gd`, `scripts/stages/FightCamera.gd`, and the corresponding scene wiring. Current `main` includes all of them.

**What this proves:** engine startup, initial scene setup, deterministic gesture-to-damage path (through `GestureInput.gesture_detected`, `InputRouter`, and `CharacterBase`), UI signal binding, existence of scene-camera/stage nodes, and eight-fighter instantiation.

**What this does NOT prove:** visual render quality, live player touch input, full best-of-three completion, actual CPU combat quality, every special/throw/trap, full parry timing, online play, frame pacing or FPS on real mobile hardware, finished art, nor release/export readiness. Tests inject a synthetic keyboard-equivalent gesture and move fighters into range; they do not simulate finger contact.

## 4. LMG adoption proof / limits

- **Adopt now:** agent-assisted, small-scope code investigation; repeatable headless runtime smoke harness; short test → inspect → correct iteration cycle. Implemented here without modifying combat source.
- **Potential pilot only:** AI-generated fighter animation assets. Test one original character against the existing 16-part puppet/AnimationPlayer pipeline before considering a change in rendering architecture.
- **Defer:** proprietary LMG engine, netcode, multiplayer, wholesale rewrite. Access to code, exact licensing and engine compatibility remains unverified. No vendor course files, assets or code were obtained or embedded.
- **Remain governing:** centralized `GameConstants`; exclusive `GestureInput → InputRouter → CharacterBase.receive_gesture()` path; mobile-first controls; original OVS roster/IP; trademark-contaminated art quarantined.

This G01 proof validates **selective AI-assisted workflow adoption**, not the quality or suitability of LMG's paywalled framework.

## 5. Gate disposition and immediate next step

**G01: AUDIT COMPLETE / CONDITIONAL ADVANCE.**

**G01A — Local Source Reconciliation + Full-Match Validation**:
1. Back up the MSI's changed `project.godot` and generated import metadata as needed.
2. Review `7d49cac` vs GitHub `2494586`; reconcile on a separate branch/worktree, **not** by resetting the original checkout.
3. Run this smoke test on the reconciled copy and require 11/11.
4. Conduct actual keyboard and touchscreen matches, KO and time-outs, meter carry, CPU engagement, parry window, and hitbox/debug tests.
5. Advance to Sol Tigre versus Yellow Dog visual vertical slice only after results are observed.

**Governance:** No canon changes, no paid generation, no course purchase, no merge to `main`, and no alteration of the user’s active MSI working copy.
