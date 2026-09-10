# THESE HANDZ — Project Handoff

**Publisher:** Omnia Vanitas Studios (OVS) · **Creative Director:** Brandon Thoreau
**Repo:** https://github.com/bthoreau88/these-handz
**Engine:** Godot 4 (developed against 4.2+, currently opened in 4.7), GDScript
**Handoff date:** 2026-09-10
**Written by:** the outgoing assistant (Claude), for whatever model or person picks this up next.

---

## 0. READ THIS FIRST — the one thing that isn't verified

**No one has ever run this code and confirmed it behaves correctly beyond a
smoke test.** Everything in `scripts/` and `scenes/` was written without a
Godot binary available in the authoring environment. It is validated by:

- `gdparse` (GDScript parser) — passes
- `gdlint` (GDScript linter) — passes
- Offline geometry checks (a Python tool that mirrors the rig math, see §6)

Brandon **has** launched the game and confirmed it boots to the character
select screen, starts a match, and shows two fighters with health/meter bars
and a running timer, with **0 errors in Godot's Output panel**. That was
before the 16-part rig, the CPU opponent tuning, and the entire stage/camera
system landed. **Those later systems have not been seen running.**

**So: the first job of whoever picks this up is to open the project, press
F5, and report what actually happens.** Do not build new features on top of
this until that is confirmed. If something errors, the fix is likely small —
the architecture is sound, but untested code always has typos.

---

## 1. What the game is

A mobile finger-fighter. Game 1 of a planned 3-game franchise. 8 fighters,
gesture controls (**no quarter-circles**), best-of-3 rounds of 60 seconds,
matches under 4 minutes. iOS + Android targets; desktop keyboard is a testing
fallback only.

Brandon is a **beginner solo developer**, 5–15 hrs/week, learning Godot as he
builds. Explain non-obvious engine concepts briefly when introducing them.
Prefer small verifiable steps over large refactors. Never rewrite a working
module wholesale.

### The Three Project Rules (enforce in every change)

1. **Never hardcode a tunable number.** Every value lives in
   `scripts/GameConstants.gd`. Balance changes happen there, with a comment
   noting the reason.
2. **Characters never read input directly.** The only input path is
   `GestureInput` (autoload) → `InputRouter` → `CharacterBase.receive_gesture()`.
   There is no `Input.is_action_pressed()` in any character script, and there
   must never be. The CPU opponent obeys this too — it synthesizes the same
   gesture dictionaries a human's fingers produce.
3. **Mobile-first.** Any input or UI change must be sane for touch, not just
   keyboard.

---

## 2. HARD IP CONSTRAINTS — the highest-stakes thing in the project

All shipped characters are original OVS IP. The franchise bible has a legal
register (§02b) listing rejected concepts.

**NEVER generate, reference, or scaffold content for:** Mega Man / "Blue
Relay", KAWS, Captain America, X-Men marks, or any real person's name or
likeness. Rejected/pending concepts on record include R. Kelly, Tom Hanks,
Lil Boosie, Shia LaBeouf, MacGyver, Uncle Ruckus, Meteor Man, Blankman.
"Stevie Wondertaker" is on a rename watchlist — do not propagate that name
into new files.

### The live problem: generated wardrobe keeps reproducing real trademarks

AI image generation for streetwear characters **repeatedly drifts back to real
brands** even when the prompt forbids it. This has already happened twice with
Sol Tigre.

Two of his sheets are **quarantined** in `assets/source_sheets/`:
- `_HOLD_sol_tigre_apose_TRADEMARKS.png`
- `_HOLD_sol_tigre_parts16_TRADEMARKS.png`

They carry the **Ralph Lauren pony logo** on both the shirt and the track
pants, plus **Nike swooshes, Air Force 1 sneaker silhouettes, and Nike-branded
socks**. They are beautiful and they cannot ship. They are kept only as a
reference for what to regenerate.

**Every generated sheet must be visually inspected** — zoom the chest, hips,
and shoes — before it enters the repo. This check is documented in
`prompts/ART_PROMPTS.md` and it is not optional.

---

## 3. The locked Game 1 roster (bible §03 — do not add, remove, or rename)

| # | Fighter | Archetype | Signature kit | Implemented tuning |
|---|---------|-----------|---------------|--------------------|
| 01 | **SOL TIGRE** | Rushdown + Tiger Companion (Tigre Flujo, Miami FL) | Tiger assist, 6s cooldown | walk 360, dmg ×0.95 |
| 02 | **CROWN SAINT** | Brawler · Faith Power | Crown Sign burst (radial, centered hitbox) | walk 320, dmg ×1.05 |
| 03 | **THE ARCHITECT** | Zoner · Soul Cipher | Cipher Orb, Coat Catch (negates projectiles), Phase Step teleport | walk 300, dmg ×0.95 |
| 04 | **DOTTY** | Setplay Trickster | Dot Trap mines (arm delay), Runway Rush, Scarf Snare | walk 330, dmg ×0.9 |
| 05 | **FRESH** | Pure Grappler — **NO projectiles ever** | Unblockable command grab, Bucket Counter auto-reversal | walk 290, dmg ×1.1 |
| 06 | **CYBORG STITCH** | Power Striker | Circuit Slam, Chain Break projectile | walk 260, dmg ×1.15 |
| 07 | **PURPLE THREAD** | Whip Zoner | Yarn Lash (longest poke), Knot Trap, Thread Spin | walk 300, dmg ×0.95 |
| 08 | **YELLOW DOG** | Wild Card — **mascot** | Brick Toss, Smoke Cloud, Deadpan Charge | walk 270, **brick 90 = FLAGGED OVERPOWERED** |

All 8 are playable in gray-box right now. Roster lives in `scripts/Roster.gd`.

**Game 2 (context only, do not build):** Sock Prophet (G2-09), Professor Belly
(G2-10), Trill (G2-11) are locked conversions. Drya, Thoreau, and Ashen Ward
cleared as original.

---

## 4. Current state — what actually works

### Combat core (`scripts/`)
- **`GameConstants.gd`** — every tunable: health, rounds, meter, parry, block,
  per-attack frame data, movement, pushback, gesture thresholds, per-character
  stats, projectiles, AI difficulty, stage/camera, art spec. One file.
- **`characters/CharacterBase.gd`** — health, `FightState` machine (IDLE /
  ATTACKING / BLOCKING / PARRYING / HITSTUN / KO), real Area2D hitbox+hurtbox
  hit detection with **startup → active → recovery** frame timing, pushback,
  walk/dash, Desperation Mode at 20% HP (+15% damage, super at half cost).
- **`combat/HandzMeter.gd`** — 0–100. +3% landing a hit, +5% taking one, +15%
  parry success, +2% parry fail. 25% EX / 50% BREAK / 100% Super. **50% carries
  between rounds.**
- **`combat/ParrySystem.gd`** — 6-frame window. Success = +15% meter and the
  attacker eats a 12-frame stun. Whiff = 24 punishable frames.
- **`combat/ProjectileBase.gd`** + brick / tiger / chain / cipher orb / dot
  trap / knot trap. Traps support an arm delay. All join a `"projectiles"`
  group that `RoundManager` clears between rounds.
- **`input/GestureInput.gd`** (autoload) — the ONLY script that touches raw
  input. Tap / swipe / hold / 2-finger tap / 2-finger swipe, plus ←→ and ↓→
  swipe sequences for specials. Keyboard fallback for desktop.
- **`managers/InputRouter.gd`** — left screen half = P1, right = P2. In solo
  (vs CPU) mode the human owns the whole screen.
- **`managers/RoundManager.gd`** — best-of-3, 60s, countdown, KO and time-out
  endings, draw rounds replay, 50% meter carry.
- **`ai/AIController.gd`** — CPU opponent. Feeds gestures through
  `receive_gesture()` exactly like a human, so it needs **zero per-fighter
  code** and works for all 8. Difficulties NORMAL / EASY / DUMMY in
  `GameConstants.AI_DIFFICULTY`.

### Presentation
- **`visual/FighterVisual.gd`** — the animation puppet. Three-segment limbs
  (shoulder→elbow→wrist, hip→knee→ankle) plus a chest/pelvis split so the
  waist twists. Poses are joint-angle dictionaries selected by `FightState`.
  Auto-detects 16-part or 10-part art, auto-scales any art resolution to the
  bible's 180px fighter height, and falls back to placeholder limbs when a
  fighter has no art.
- **`stages/StageBackground.gd`** — 4-layer parallax. **Every layer is
  optional** — a missing PNG is replaced by a procedural stand-in (gradient
  sky, seeded skyline silhouettes with lit windows), so real art can land one
  layer at a time and the stage never looks broken.
- **`stages/FightCamera.gd`** — sits on the midpoint between fighters, pulls
  back as they separate. Its motion is what drives the parallax.
- **`scenes/CharacterSelect.tscn`** — touch-first select screen, main scene.
  P2 button cycles CPU difficulty / 2nd human.

### Desktop test controls (Player 1)
`Z` light · `X` medium · `C` heavy · `V` super · `A` Special A · `S` Special B ·
`D` hold block · `F` parry · `Q` charge move · `←`/`→` walk

Mouse emulates touch — click/drag the right half of the window to drive P2 in
a two-human match.

---

## 5. Art direction and pipeline

**Chosen: puppet-rigged HD anime** (the BlazBlue/Guilty Gear look, made
solo-affordable). Draw each fighter ONCE in separated body parts, then animate
by rotating joints instead of redrawing frames.

Alternatives, with tools and trade-offs, are documented in `ART_DIRECTION.md`:
crisp pixel-art (Aseprite), true 3D-cel Guilty Gear (Blender, hardest by far),
and 3D-render-to-2D sprites (Blender → sprite sheets).

**Where AI art helps:** 512×512 portraits, concept exploration, key art, and
the part-out sheets themselves. **Where it does not:** frame-by-frame fight
animation — identity drift between frames makes characters strobe. That is the
core reason the puppet rig was chosen over generated keyframes.

### The 16-part layout (current standard)
```
head, chest, pelvis,
upper_arm_front, forearm_front, hand_front,
upper_arm_back,  forearm_back,  hand_back,
thigh_front, shin_front, foot_front,
thigh_back,  shin_back,  foot_back
```
Plus an assembled reference figure on the sheet (dropped by the slicer).

### A hard-won prompting lesson — do not repeat this mistake
The first part-out prompt asked for *"rounded caps, extra material at the
joint."* The image model read that as **literal cut cylinder ends**, so every
limb came back looking amputated and the assembled rigs read as segmented
mannequins. Brandon's exact words: *"they all look disfigured."*

The fix is the **ABSOLUTELY FORBIDDEN** block now in `prompts/ART_PROMPTS.md`
— it bans cross-sections, discs, and "detached mannequin part" looks outright,
and instead asks for anatomy that **continues past** the joint (the upper arm
includes the whole rounded shoulder, the thigh includes the full hip curve).
That single change fixed it. The postmortem is preserved in the prompts file
so it doesn't get reintroduced.

Second lesson: independently-drawn parts don't fully agree with each other.
**Prompt A** (one A-pose master figure, cut afterwards) is the most consistent
route and is the recommended default.

---

## 6. Tools built (both plain Python + Pillow, no other dependencies)

**`tools/slice_parts.py`** — cuts an AI-generated part-out sheet into
individual transparent PNGs. Flood-fills non-white blobs, discards the small
ones (text labels) and the assembled reference figure, sorts the rest into
reading order by **vertical overlap** (necessary because a hand sits next to a
whole leg on the same row), and writes each out named by rig position.
```bash
python3 tools/slice_parts.py assets/source_sheets/<name>_parts.png \
    assets/sprites/fighters/<name>          # 16-part (default)
python3 tools/slice_parts.py <sheet> <dir> --parts=10   # legacy sheets
```

**`tools/preview_rig.py`** — composites a fighter in five poses (idle / walk /
punch / block / KO) using the **same joint math as `FighterVisual.gd`**, so a
rig can be checked without launching Godot. This is how the rig bugs were
caught before Brandon ever saw them. **If you change the rig constants in the
GDScript, change them here too** — the file says so at the top.
```bash
python3 tools/preview_rig.py assets/sprites/fighters/crown_saint out.png
```
(Requires the 16-part layout.)

### Giving any fighter art — the whole process
1. Generate a part-out sheet (Prompt B in `prompts/ART_PROMPTS.md`).
2. **Inspect for real-world trademarks.**
3. Run `slice_parts.py`.
4. Run `preview_rig.py` and eyeball it.
5. Set `parts_dir` on that fighter scene's `FighterVisual` node to
   `res://assets/sprites/fighters/<name>`.

**No code changes.** That's the point of the pipeline.

---

## 7. Open items, in priority order

### Blocking / do first
1. **Run it.** F5, play a match, report errors. Nothing else matters until
   this is confirmed, especially the stage + camera which have never been seen.
2. **Regenerate Sol Tigre** without trademarks — he is the flagship and his
   current 16-part art is unusable. Use Prompt B plus an explicit wardrobe
   override (plain rugby shirt with no chest logo, plain navy track pants with
   a gold stripe, generic unbranded white sneakers; the only marks are the
   tiger-sun medallion and the ST crown monogram).

### Identify these two characters
`assets/sprites/fighters/fighter_denim/` and `fighter_tattoo/` hold two sliced
10-part fighters whose roster identity was **never confirmed by Brandon**:
- **fighter_denim** — denim jacket over a white hoodie, ripped black jeans,
  exposed musculature / flayed-looking face. Guess: Cyborg Stitch (the
  "stitch" read), but there are no visible cybernetics. **Unconfirmed.**
- **fighter_tattoo** — shirtless, heavily tattooed, bucket hat, gold chain,
  black shorts, white socks with slides, "FORTITUDE" forearm tattoo. Guess:
  Fresh (grappler build). **Unconfirmed.**

Ask Brandon. Then rename the folders and point the fighter scenes at them.

### Gameplay tuning (needs a human playing it)
- **Yellow Dog's brick damage is deliberately left at its flagged-overpowered
  value (90)** so the problem is visible in playtests. Tune in
  `GameConstants.YELLOW_DOG["brick_damage"]`, nowhere else.
- Parry's 6-frame window may be brutal on touch — needs a real phone test.
- Fresh's counter window/damage, trap cooldowns, CPU aggression.
- **Phase 1 step 5 is still open:** hand-test every gesture on a real phone
  (tap, all four swipes, ←→, ↓→, hold, 2-finger tap, 2-finger swipe) and tune
  the recognizer thresholds in `GameConstants`.

### Features not yet built
- Real MIAMI DUSK stage layer art (Prompt D). Procedural placeholder runs now.
- Graduating the code-driven poses into `AnimationPlayer` clips authored to
  the existing frame data.
- 512×512 character portraits (bible §06).
- The Architect's Coat Catch currently **negates** projectiles; the bible says
  **reflect**.
- Per-fighter frame data — all 8 currently share the universal `ATTACKS` table
  plus their signature moves.
- Web (HTML5) export for phone demos (see §8).
- SFX, music, hitstop, screen shake.

---

## 8. Getting it onto a phone

**Native iOS requires a Mac.** Xcode is macOS-only and there is no way around
it. Brandon is on Windows (RTX 4070 laptop). Native builds are a Phase 6 item
gated on Mac access.

**The path that works today: Godot's HTML5 export**, hosted somewhere that
serves the right cross-origin headers (itch.io handles this automatically and
is free), opened in mobile Safari. Touch input already works — `GestureInput`
handles real touch events, not just the keyboard fallback.

The CPU opponent exists specifically so a phone demo is playable solo. Without
it the game is two-thumb hotseat.

---

## 9. Working environment notes (things that cost time)

- Brandon is on **Windows / PowerShell**. Give him PowerShell commands, not
  bash.
- His **Documents folder is OneDrive-redirected**, which caused real confusion:
  `C:\Users\thore\Documents` and `C:\Users\thore\OneDrive\Documents` are
  different folders. The live clone is at **`C:\Users\thore\Documents\these-handz`**.
- Two **old scaffold folders** still sit in `OneDrive\Documents\` and appear in
  Godot's project list. They throw harmless missing-icon errors and are not
  this project. He was advised to Remove them from the list.
- The original `TheseHandz_Godot4_Scaffold_v0.1` scaffold was **never committed
  anywhere** — the version in this repo was rebuilt from a written spec. If the
  original folder still exists locally and contains tuning he cares about,
  diff before overwriting.
- He also has repos `bthoreau88/2025May_Team04` and `bthoreau88/dev-brandon`.
  Those are **unrelated** (Android Studio / QuickPhrase coursework). The game
  briefly lived on a branch of `2025May_Team04` before getting its own repo;
  ignore that history.

---

## 10. Canonical documents (priority order)

1. `THESE_HANDZ_Bible_v3.0_PUBLIC_RELEASE.html` — the franchise bible.
   **§03 locked roster · §04 move sets · §05 mechanics · §06 art/sprite spec ·
   §02b legal register.** *Not in this repo* — Brandon keeps it locally. The
   outgoing assistant **never saw it**; everything here was built from a
   written handoff summary of it. **Whoever picks this up should ask for the
   bible and check the kits against §04**, because the gray-box move sets were
   built from one-line archetype summaries, not the real move descriptions.
2. `HANDOFF.md` — this document. Full project state.
3. `ROADMAP.md` — 26-week phased plan with milestone tests.
4. `README.md` — file map, three rules, controls.
5. `ART_DIRECTION.md` — pipeline choice and alternatives.
6. `prompts/ART_PROMPTS.md` — style lock and generation prompts.

---

## 11. How to work on this project

- One roadmap phase at a time. State which step a change serves.
- After each change, give Brandon **the exact in-editor steps to test it**. He
  is learning the editor — "connect the signal" needs the click path the first
  time.
- Balance changes go through `GameConstants.gd` only, with a comment.
- Flag anything that would violate the three rules or the IP constraints
  **before** doing it.
- Validate GDScript with `gdparse` / `gdlint` (`pip install gdtoolkit`) if you
  cannot run the engine. It catches syntax and style but **not** runtime
  behavior — say so plainly rather than implying the code is tested.
- Never animate all 8 fighters before one is proven end to end.
