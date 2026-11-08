# THESE HANDZ — G01D Physical Mobile Acceptance & Performance / IP Hold

**Opened:** 2026-11-07 (Pacific)  
**Disposition:** **OPEN / HUMAN DEVICE TEST REQUIRED / NOT RELEASE-APPROVED**  
**Authorized scope:** zero-credit QA readiness, no publishing, no game mutation, no merge.  
**Source under test:** `bthoreau88/these-handz`, G01C review commit `806754e345ad34d83ab69e1bb1546b69e0956f7d`. Stacked draft G01D branch is based on G01C—not on `main`, and not on G01 quality PR #3.

## 1. Why G01D exists

G01C achieved an implemented mobile touch movement concept and safe local Web export, with 73/73 scripted tests reported, a desktop Chrome WebGL2 game-flow smoke test and mobile Chrome emulation. The missing evidence is **real iPhone Safari human input, real-device frame pacing, visual quality/IP source authority and full match progression**.

An independent sibling G01 quality-evidence branch / PR #3 has now been exercised on an MSI: **59/59** headless functional checks (49 inherited + 10 new); three native Windows 1280×720 rendered fixture screenshots captured twice and compared. The screenshot comparison reported 111/507/10 changed pixels out of 921,600 (neutral/mid/wide), all marked REVIEW_REQUIRED. The native G01 Vulkan screenshots **must not** stand in for G01C browser WebGL2 device renders.

Reference: `docs/audits/OVS_GAME_G01_EXECUTION_2026-11-07.md` on PR #3. The separate report is documentary context, not silently incorporated code.

## 2. Protected build and trust boundary

- Start only from G01C **published-source proof**: `C:\Users\thore\Documents\THESE-HANDZ-G01C-PUBLISHED-PROOF` or a newly hashed equivalent, never the original `C:\Users\thore\Documents\these-handz` workspace.
- Local filtered Web build: `build/web/index.html` + `index.js` + `index.wasm` + `index.pck` and icons. Existing inspected `index.pck` length: **2,274,928 bytes** (must re-hash immediately before exposing any private device endpoint).
- Previous G01C independent proof PCK SHA256: `2129EFEBDFDFADC30BFB93C84729FC13F5A246AAB8840DB29E4239A0E501E3F1` (historical receipt; do not assume current bytes are identical).
- The Web export must remain a **local/private test only**. Unfiltered `_HOLD_` / `TRADEMARKS` source artwork was quarantined; do not serve or distribute any unfiltered build. Check the safe-export script/receipt again before any network test.
- A clean string/marker scan does **not** establish IP rights for rendered fighters. Sol Tigre and provisional source art remain separate IP clearance holds.
- Verify the actual test IP, TLS/browser constraints, phone and Windows Wi-Fi segment at test time; **never commit private LAN address** to this public repo.

## 3. Physical-device evidence protocol (required for meaningful PASS)

### Hardware / environment record

Record device model, iOS version, Safari version, orientation and browser zoom; Wi-Fi or network connection; whether low-power mode is on; graphics behavior; Web export SHA256; date/time; test operator and exact build/version. Capture screenshots **from the real phone** and a brief screen recording when possible. Clear caches when comparing different builds.

### Repeatable journey

1. Open the verified local-only link from **physical iPhone Safari**, in landscape. Record load time, blank screen, console/network failures and whether the menu renders.
2. Character selection: **Sol Tigre vs Yellow Dog** as the fixed engineering matchup. Record screen-fit, text legibility, touch target occlusion and first impression. Placeholder/held art is *not* approved.
3. Select solo/CPU. Play countdown to **FIGHT**, test light, medium/forward-swipe, heavy (if offered), low, jump, block and parry. Identify each attempt as **intended / recognized / executed**, not just “it worked.”
4. While idle and while attacking, hold left and right move pads. Release each and verify immediate cessation of movement with **no stuck walk**. Test two independent attack/movement fingers. Repeat 10 times per direction and facing.
5. Cross sides: retest mirrored specials and outward backdash after facing flips. Repeat 10 times each; distinguish input misrecognition from cooldown/recovery lock.
6. Complete **two scored rounds**, KO or timer, rematch/return to character select. Watch for gesture leaks and the CPU activating during countdown.
7. Stress: rapid finger substitution, change of orientation away and back, brief Safari tab background/resume, low battery or thermal warning if naturally encountered. Do not induce unsafe thermal conditions or intentionally crash the phone.
8. Repeat a limited smoke journey on representative Android Chrome if available; Android emulation is not a substitute.

### Recordable event schema

Use `docs/audits/THESE_HANDZ_G01D_DEVICE_LOG_TEMPLATE.csv` for each trial:
`timestamp_local,device,os_version,browser_version,build_sha256,matchup,round,scenario,facing,attempt,intended_action,recognized_action,executed_action,frame_time_ms,outcome,notes,evidence_file`.

Never invent a latency estimate from the headless signal probe, or an FPS metric from a single screen recording.

## 4. Performance budget and measurement

**Target:** responsive 60 FPS presentation where hardware supports it, with frame budget **16.67 ms** (target, **not measured**). Required evidence: in-session frame-interval samples over warmup, neutral, active combat and camera movement. Capture sample count, median, p95, worst/longest-frame, continuous freeze counts and graphics/WebGL context loss; note if vsync, browser throttling, battery/thermal/network conditions distort measurement. Record input timing separately from render interval. No desktop Vulkan result can certify mobile Safari performance.

**G01D objective, not yet pass law:** 60 FPS target under the fixed matchup; consistent touch intent and no game-breaking blocked moves, dropped input releases or match-flow failure. A technically “passing” numeric budget does not override human observations of poor feel.

## 5. Independent visual & asset/IP review

- **Presently observed (native G01 fixture):** flat Miami dusk blocks, clear placeholder Yellow Dog rectangle, provisional Sol Tigre appearance, visible debug hurtbox overlay, readable HUD. This is useful for spatial QA but not fit for release.
- Device screenshots must verify correct 16:9/landscape framing on phone, readable health/meter/timer labels, consistent input target placement, two fighters visible and no overlay collision.
- Record per-fighter asset origin, permissions, licensed/trademark risks and whether the art actually corresponds to the approved character identity/wardrobe authority. Held or uncertain inputs remain quarantined. **No implied license or canon promotion.**
- Compare WebGL2 screenshot vs WebGL2 screenshot using a repeatable fixture before accepting any “visual improvement.” Use the G01 visual report as a methodological template, not as pixel-identical baseline.

## 6. Disposition matrix

| Gate | Current evidence | Disposition |
| --- | --- | --- |
| Isolated development | G01C/PR #4, G01/PR #3, G01D all draft review | PASS (branch separation) |
| Headless engine functionality | G01C previously 73/73; new sibling G01 59/59 rerun | PASS for respective source branches |
| Actual browser Web export | G01C filtered pack, Chrome menu/fight smoke | PASS for local browser preflight only |
| Physical iPhone Safari menu→match | Not observed/recorded here | **HOLD** |
| 10-trial control matrix / backdash / release | No physical-phone dataset | **HOLD** |
| Real-device 60fps frame intervals | No sampled metrics | **HOLD** |
| Final art and source rights | Placeholder visuals and held source assets | **HOLD** |
| Public deployment / release / merge | Not authorized | **PROHIBITED** |

## 7. Stop conditions and founder review

STOP on: unfiltered Web pack, evidence of third-party IP infringement, repeated stuck movement, wrong routing between P1/P2, browser security warning or graphics context loss, inaccessible buttons, unresponsive back/exit, or any actual phone thermal distress. Record failing state, do not patch it directly on original sources, and assign a separate controlled issue/branch.

**G01D gate completion requires human device evidence and explicit approval.** The present action advances a **test-readiness package**, not a release claim, production merge, art clearance or paid-generation authorization.
