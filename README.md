# THESE HANDZ

OVS mobile finger-fighter — Godot 4.2+, GDScript.
Publisher: **Omnia Vanitas Studios**. Creative Director: **Brandon Thoreau**.

Game 1 of a 3-game mobile fighting franchise. Game 1 ships 8 fighters
(locked roster — see the franchise bible §03). Gesture-based controls,
NO quarter-circles, matches under 4 minutes.

## The Three Project Rules

Every change in this repo is checked against these. No exceptions.

1. **Never hardcode a tunable number.** All values live in
   `scripts/GameConstants.gd`. Balance changes happen there, with a comment
   noting the reason.
2. **Characters never read input directly.** The only input path is
   `GestureInput` (autoload) → `InputRouter` → `CharacterBase.receive_gesture()`.
   No `Input.is_action_pressed()` in character scripts, ever.
3. **Mobile-first.** Any input or UI change must be sane for touch, not just
   keyboard. Keyboard is a desktop testing fallback only.

## File map

```
project.godot                      Godot 4 project (autoloads: GameConstants, GestureInput)
scenes/
  CharacterSelect.tscn/.gd         Touch-first select screen (main scene)
  FightScene.tscn                  Gray-box fight: spawns picked fighters + UI
  FightScene.gd                    Scene glue: wires input, bars, round flow
  fighters/                        One scene per roster fighter (placeholder colors)
  projectiles/                     Brick, Tiger, Chain, Cipher Orb, Dot/Knot traps
scripts/
  GameConstants.gd                 ALL tunable numbers (bible §05-§06)   [autoload]
  Roster.gd                        LOCKED Game 1 roster + select-screen picks
  input/
    GestureInput.gd                Tap/swipe/2-finger recognizer + keyboard [autoload]
  managers/
    InputRouter.gd                 Left half of screen = P1, right = P2; keyboard = P1
    RoundManager.gd                Best-of-3, 60s rounds, countdown, win tracking
  combat/
    HandzMeter.gd                  25% EX / 50% BREAK / 100% Super, 50% round carry
    ParrySystem.gd                 6-frame window, +15% meter / 12f advantage on success
    ProjectileBase.gd              Shared projectile/trap logic (arm delay, lifetime)
    BrickProjectile.gd / TigerCompanion.gd / ChainProjectile.gd
    CipherOrb.gd / DotTrap.gd / KnotTrap.gd
  visual/
    FighterVisual.gd               Placeholder animation puppet posing off FightState
  ai/
    AIController.gd                CPU opponent (feeds gestures like a human)
  characters/
    CharacterBase.gd               Health, FightState machine, damage, meter/parry
    SolTigre.gd                    G1-01 Rushdown + Tiger Companion
    CrownSaint.gd                  G1-02 Brawler, Crown Sign burst
    TheArchitect.gd                G1-03 Zoner: Cipher Orb, Coat Catch, Phase Step
    Dotty.gd                       G1-04 Setplay: Dot Trap, Runway Rush, Scarf Snare
    Fresh.gd                       G1-05 Grappler: command grab, Bucket Counter
    CyborgStitch.gd                G1-06 Power: Circuit Slam, Chain Break
    PurpleThread.gd                G1-07 Whip zoner: Yarn Lash, Knot Trap, Thread Spin
    YellowDog.gd                   G1-08 Wild card (brick damage FLAGGED OP)
```

## Solo play vs CPU

On the select screen the **P2** button cycles Player 2 between a CPU
(NORMAL / EASY / DUMMY difficulty) and a second human. With a CPU opponent
the human controls the whole screen (or keyboard), so the game is playable
solo — including on a phone. DUMMY is a training dummy that mostly stands and
occasionally blocks, for practicing combos. CPU tuning lives in
`GameConstants.AI_DIFFICULTY`.

## Desktop test controls (Player 1)

`Z` light · `X` medium · `C` heavy · `V` super · `A` Special A · `S` Special B ·
`D` hold to block · `F` parry · `Q` charge move · `←`/`→` walk (testing only)

Mouse emulates touch: click/drag on the **right half** of the window to drive
Player 2 with real gestures (tap, swipe, etc.).

## Canonical documents (priority order)

1. `THESE_HANDZ_Bible_v3.0_PUBLIC_RELEASE.html` — franchise bible (keep a copy
   next to this repo; not committed here).
2. `ROADMAP.md` — 26-week phased build plan with milestone tests.
3. This file.

All shipped characters are **original OVS IP** — see bible §02b for the legal
register before adding any character content.
