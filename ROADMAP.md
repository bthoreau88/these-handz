# THESE HANDZ — 26-Week Build Roadmap (Game 1)

Solo beginner developer, 5–15 hrs/week. One phase at a time; every phase ends
with a milestone test you can run yourself. Never move on with a red milestone.

Legend: `[x]` done · `[~]` in progress · `[ ]` not started

---

## Phase 0 — Project setup (weeks 1–2) — DONE

- [x] Godot 4.2+ project opens; scaffold scripts imported
- [x] `GameConstants` + `GestureInput` registered as autoload singletons
- **Milestone test:** project runs from the editor with no script errors. ✅

## Phase 1 — Gray-box fight loop (weeks 3–6) — IN PROGRESS

- [x] 1. `FightScene.tscn` with two placeholder rectangles
       (CharacterBody2D + CollisionShape2D + ColorRect)
- [x] 2. Wire GestureInput → InputRouter → both characters; keyboard attacks land
- [x] 3. Health bars + meter bars (ProgressBar) connected to existing signals
- [x] 4. ParrySystem + RoundManager integration; full best-of-3 loop with no art
- [ ] 5. Hand-test every gesture on a real phone (tap, all 4 swipes, ←→, ↓→,
       hold, 2-finger tap, 2-finger swipe) and tune the recognizer thresholds
       in GameConstants if anything feels off
- **Milestone test:** play a full best-of-3 on desktop keyboard AND on a phone,
  KO and time-out both end rounds, meter carries 50% between rounds.

## Phase 2 — Real hit detection (weeks 7–9) — IN PROGRESS

- [x] Hitbox/hurtbox Area2D pairs with per-attack frame timing
      (startup → active → recovery; the old distance check is gone)
- [~] Walk/dash movement + pushback on hit and block
      (walk: keyboard arrows for desktop testing; touch walk still TODO.
       dash: forward swipe when out of range. pushback: done, incl. block)
- [x] Debug overlay: green hurtboxes + red active hitboxes
      (toggle: `DEBUG_SHOW_HITBOXES` in GameConstants.gd)
- [ ] Touch movement design pass on a real phone (how should walking feel?)
- **Milestone test:** whiffing at max range visibly misses; hits connect only
  during active frames.

## Phase 3 — First two real fighters (weeks 10–14) — IN PROGRESS

- [x] Shared `ProjectileBase.gd` (velocity/gravity/lifetime/hit-once,
      cleared between rounds via the "projectiles" group)
- [x] SOL TIGRE — `TigerCompanion.tscn` assist: dashes across on Special A,
      6s cooldown, hits once
- [x] YELLOW DOG — `BrickProjectile.tscn` arcing Brick Toss (damage still
      FLAGGED OP in GameConstants — tune after playtest!), Smoke Cloud
      (fade + cloud, 3s), Deadpan Charge (hold = heavy, armor TODO)
- [x] `ChainProjectile.tscn` groundwork (no fighter fires it yet)
- [ ] Playtest the matchup and tune brick damage / tiger cooldown
- [ ] Real per-character frame data (both still share universal ATTACKS)
- **Milestone test:** mirror-less match Sol Tigre vs Yellow Dog with all
  specials functional, still placeholder art.

## Phase 4 — Sprites & animation (weeks 15–19) — PIPELINE STARTED

Art direction chosen: **puppet-rigged HD anime** (see ART_DIRECTION.md for
this and the alternative pipelines). Vertical slice underway on Sol Tigre.

- [x] Animation hookup proven: `scripts/visual/FighterVisual.gd` — a code-built
      placeholder puppet posing off FightState (idle / walk / punch / block /
      parry / KO), live on Sol Tigre. Real art swaps in at this layer.
- [ ] Draw Sol Tigre's body parts in Krita, export transparent PNGs
- [ ] Swap the Polygon2D limbs for Sprite2D parts; move poses into
      AnimationPlayer clips named to match the states
- [ ] Author clips to the existing GameConstants frame data (hit lands on the
      active frame)
- [x] Stage system: 4-layer parallax backdrop + fighting-game camera that
      tracks both fighters and pulls back as they separate. Procedural
      placeholder renders until real layer art lands (`assets/stages/`).
- [ ] Real MIAMI DUSK layer art (see Prompt D in prompts/ART_PROMPTS.md)

- [ ] Sprite pipeline per bible §06: 180px base @1x, authored 3x,
      32+ frames per fighter, portraits 512×512
- [ ] AnimationPlayer/AnimatedSprite2D driven by FightState
- [x] Stage system: 4-layer parallax backdrop + fighting-game camera that
      tracks both fighters and pulls back as they separate. Procedural
      placeholder renders until real layer art lands (`assets/stages/`).
- [ ] Real MIAMI DUSK layer art (see Prompt D in prompts/ART_PROMPTS.md)
- **Milestone test:** both fighters fully animated (idle, walk, all attacks,
  block, parry, hit, KO) at stable 60fps on a mid-range phone.

## Phase 5 — Remaining 6 fighters, gray-box first (weeks 20–24) — GRAY-BOX DONE EARLY

- [x] Gray-box kits for Crown Saint (Crown Sign burst), The Architect
      (Cipher Orb / Coat Catch negate / Phase Step), Dotty (Dot Trap mines /
      Runway Rush / Scarf Snare), Fresh (command grab / Bucket Counter,
      NO projectiles), Cyborg Stitch (Circuit Slam / Chain Break),
      Purple Thread (Yarn Lash / Knot Trap / Thread Spin)
- [x] Character select screen (touch-first, roster generated from Roster.gd)
- [ ] Check every kit against bible §04 exact move descriptions and adjust
- [ ] Coat Catch: true projectile REFLECT (currently just negates)
- [ ] Per-fighter animation once Phase 4 pipeline exists
- **Milestone test:** full 8-fighter select, any matchup completes a match.

## Phase 6 — Alpha polish (weeks 25–26)

- [ ] Character select + main menu (touch-first UI)
- [ ] SFX/music pass, hitstop, screen shake
- [ ] iOS + Android export configs; on-device performance pass
- **Milestone test:** clean install on both platforms, full loop
  menu → fight → rematch with no crashes.

## Solo / demo support (added ahead of schedule)

- [x] CPU opponent (`scripts/ai/AIController.gd`) driving Player 2 through the
      normal gesture path, so one person can play/demo solo. Difficulties
      NORMAL / EASY / DUMMY in GameConstants.AI_DIFFICULTY.
- [x] Character-select toggle for CPU vs 2nd human.
- [ ] Web (HTML5) export for browser demos on iPhone/Android Safari
      (native iOS/Android app builds stay in Phase 6 — need a Mac for iOS).

Post-alpha (NOT before): backend (Firebase/Supabase), online, Game 2 roster.
