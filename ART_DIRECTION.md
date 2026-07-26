# THESE HANDZ — Art Direction & Animation Pipelines

Reference doc for how the fighters get their look and motion. The **chosen**
path is #1; the rest are documented so a future pivot is an informed one, not
a restart. Every pipeline plugs into the SAME thing: the `FightState` machine
in `CharacterBase.gd` and the frame data already in `GameConstants.ATTACKS`
(startup / active / recovery). Whatever we draw, the animation just has to hit
its key poses on those frames. The art is skin over a skeleton that already
fights.

Reference games sort into two families:
- **2D sprites** (hand-drawn each frame): BlazBlue, Marvel vs Capcom 2, Street
  Fighter III. Beautiful, brutally labor-intensive.
- **3D cel-shaded** (3D models shaded to look 2D): Guilty Gear Xrd/Strive,
  Street Fighter 6, MvC3. Modern-AAA look, heavy technical + 3D skill cost.

---

## 1. Puppet-rigged HD anime  ✅ CHOSEN

**The BlazBlue/Guilty Gear look, made solo-affordable.** Draw each fighter
ONCE, in separated body parts; assemble the parts into a jointed "puppet";
animate by rotating joints instead of redrawing frames.

- **Draw in:** Krita (free) or Clip Studio Paint (paid, anime-industry favorite).
  Each body part on its own layer → export transparent PNGs.
- **Rig + animate in:** Godot itself — Skeleton2D + Bone2D + Polygon2D, posed
  with AnimationPlayer. (Alternatives: DragonBones, free; Spine, paid pro.)
- **Pros:** one drawing → unlimited poses; mobile-friendly; stays in-engine;
  the look Brandon actually wants.
- **Cons:** joints can look "papery" if over-rotated; needs clean part art with
  overlap where limbs bend.
- **Status:** RIG PROVEN. `scripts/visual/FighterVisual.gd` is a placeholder
  puppet (Polygon2D limbs) already posing off FightState on Sol Tigre —
  idle bob, walk stride, punch wind-up/thrust/recover, block, parry, KO topple.
- **To go real:** draw Sol Tigre's parts in Krita → in `SolTigre.tscn` swap each
  `Polygon2D` for a `Sprite2D` of the matching part, keep the posing code →
  graduate the poses into named AnimationPlayer clips → clone across the roster.

## 2. Crisp pixel-art

**Hand-animated pixel sprites** (KOF / SF3 energy, your own style).

- **Make in:** Aseprite (~$20, the sprite-animation standard). Frame-by-frame,
  but each frame is fast at low resolution.
- **Wire-in:** `AnimatedSprite2D` + a `SpriteFrames` resource per fighter, clip
  names matching the states. Same state hookup as today.
- **Pros:** most ACHIEVABLE solo; tiny files; crisp on mobile; forgiving.
- **Cons:** retro aesthetic, not the slick-HD BlazBlue vibe; smooth motion still
  needs many frames.

## 3. True 3D-cel (Guilty Gear Xrd)

**Model + rig + animate in 3D, cel-shade to look 2D.**

- **Make in:** Blender (free) for model/rig/animation; a toon/cel shader in
  Godot (Godot supports 3D + custom shaders, so it can stay in-engine).
- **Pros:** highest ceiling; closest to the exact Guilty Gear look; once rigged,
  new animations are "cheap."
- **Cons:** the hardest path by far — real 3D modeling, rigging, and shading
  skill; Xrd-tier results took a pro studio years. A long-term goal, not a
  first solo build. Would also move fighters from 2D nodes to 3D scenes.

## 4. 3D-render to 2D sprites

**Middle path:** model/rig/animate once in Blender, then render each frame to a
flat 2D sprite sheet from a fixed camera (how Donkey Kong Country was made).

- **Make in:** Blender → PNG sprite sheets → `AnimatedSprite2D` in Godot (same
  wire-in as pixel-art).
- **Pros:** a "3D-ish 2D" look without a live 3D engine; consistent lighting;
  new animations cheap once the model is rigged; stays 2D in-game.
- **Cons:** heavy upfront Blender setup; re-rendering for tweaks; large sprite
  sheets if high-res.

---

## Where AI fits (any pipeline)

Brandon already works with AI image tools. Good uses: **512×512 character
portraits** (bible §06), concept exploration, key art, UI. NOT reliable yet for
consistent frame-to-frame FIGHT animation — the moving fighters need real
sprites/rigs. Use AI for the stills around the action, not the action itself.

## The one rule that outlives the choice

Whatever pipeline wins, fighters are driven by `FightState` and the frame data
in `GameConstants`. Art swaps in at the visual layer only. Nail the gray-box
feel first; skin second; never animate all 8 before one is proven end-to-end.
