# THESE HANDZ — Art Generation Prompts

Reusable prompts for generating fighter art that drops straight into the game.
Paste the **Style Lock** at the top of every generation so all 8 fighters read
as one artist and one game.

**Hard rule:** no real-world brands, logos, or trademarks, ever — bible §02b.
Use the OVS "ST" crown monogram and each fighter's own emblem instead.

---

## Style Lock (prepend to everything)

```
STYLE LOCK — OVS "THESE HANDZ" character art. Match exactly:

Premium pixel-art illustration, high resolution, clean readable silhouette,
arcade-fighter readability. Grounded athletic proportions (realistic 7-head
build, NOT chibi, NOT superhero-exaggerated). Confident restrained posture.
Soft directional key light from upper left, subtle ambient fill, no harsh
rim lighting. Flat cel-style shading with limited bands, crisp edges.
Neutral off-white background unless stated. No text, no watermarks, no
signature, no logo unless specified.

PALETTE: mustard gold (#E8A317), deep navy (#1B2A4A), forest green (#1F4735),
warm brown skin tones, off-white, gold accents.

CRITICAL: all real-world brand logos and trademarks are FORBIDDEN. Generic
unbranded clothing and footwear only. Character emblems must be original OVS
marks.
```

---

## ⚠️ Trademark check — do this EVERY time

Before a sheet goes in the repo, zoom in on the chest, hips, and shoes.
Generated wardrobe keeps drifting back toward real brands (Ralph Lauren pony,
Nike swoosh, Air Force 1 silhouettes). Any sheet carrying a real mark cannot
ship — regenerate it with the brand ban restated. Sheets on hold are prefixed
`_HOLD_..._TRADEMARKS.png` in `assets/source_sheets/`.

## Prompt A — A-pose rig master (recommended starting point)

One clean, consistent, high-detail figure. Cut it into parts yourself for
guaranteed-matching pieces.

```
[STYLE LOCK]

SUBJECT: [NAME] — [age, height, build]. [Wardrobe and identity markers].

TASK: A single full-body RIG MASTER illustration for 2D skeletal animation.

POSE — follow exactly:
- True side-facing 3/4 view, character facing RIGHT
- Relaxed A-pose: arms hanging straight down, angled ~25 degrees away from
  the body so NO limb overlaps the torso or any other limb
- Legs straight, feet flat, stance shoulder-width, feet NOT touching
- Head upright, neutral expression

DRAWING REQUIREMENTS:
- Limbs STRAIGHT and at FULL LENGTH, no foreshortening
- Completely flat even shadowless lighting, no baked-in shadow direction
- Full crisp anatomy at shoulders, elbows, wrists, hips, knees, ankles
- Pure white background, NO drop or contact shadow
- 1400 pixels tall minimum, full figure only, no text or callouts
```

## Prompt B — 16-part part-out sheet (what the rig consumes)

Its output feeds `tools/slice_parts.py` directly. The **forbidden** block is
the important part — without it the model draws amputated cylinder ends.

```
[STYLE LOCK]

SUBJECT: [NAME] — [age, height, build]. [Wardrobe and identity markers].
[Personality in three words].

TASK: A CHARACTER PART-OUT SHEET for 2D skeletal rigging — separated body
parts, laid out flat with clear gaps, on pure white.

PARTS (16, each drawn separately and clearly numbered):
  1  head + neck        2  chest / upper torso    3  pelvis / hips
  4  upper arm FRONT    5  forearm FRONT          6  hand FRONT
  7  upper arm BACK     8  forearm BACK           9  hand BACK
  10 thigh FRONT        11 shin FRONT             12 foot FRONT
  13 thigh BACK         14 shin BACK              15 foot BACK
  16 assembled reference figure, full body, on the far left

This exact order matters — the slicer names files by it.

ABSOLUTELY FORBIDDEN — these ruin the rig:
- NO cut-off, capped, hollow, or sliced-tube limb ends
- NO visible cross-sections, flat discs, or circular caps at any joint
- NO amputated or "detached mannequin part" look
- NO robot ball-and-socket or segmented-armor joints
- NO drop shadows under any part
- NO foreshortening — every limb at full length, side-on to camera

INSTEAD, at every joint:
- Draw COMPLETE natural anatomy that continues past where the joint will be —
  the upper arm includes the whole rounded shoulder and deltoid, the forearm
  includes the full elbow, the thigh includes the full hip and buttock curve,
  the shin includes the whole knee and kneecap
- Pieces should look like they NEST or overlap like layered clothing plates,
  not like severed segments
- Every part ends in finished, drawn anatomy or fabric — never a blunt edge

CONSISTENCY (critical):
- Every single part drawn from the IDENTICAL camera angle
- Identical flat shadowless lighting on every part
- Identical line weight, color, and detail level on every part
- All parts at the same scale, matching the assembled reference exactly
- Limbs drawn STRAIGHT and relaxed, not bent or posed
```

### Turning a sheet into game assets

```bash
python3 tools/slice_parts.py assets/source_sheets/<name>_parts.png \
    assets/sprites/fighters/<name>
python3 tools/preview_rig.py assets/sprites/fighters/<name> preview.png
```

Then set `parts_dir` on the fighter scene's `FighterVisual` node to
`res://assets/sprites/fighters/<name>`. No code changes needed.

---

## Prompt C — Identity / reference sheet

```
[STYLE LOCK]

Produce an OVS CHARACTER REFERENCE SHEET in the exact layout and typographic
style of the SOL TIGRE sheet: title bar, front / 3-4 / side profile identity
lock row, full figure, wardrobe detail call-outs, identity markers list,
expression language, visual DNA, color palette swatches.

CHARACTER: [NAME] — [ARCHETYPE]. [DESCRIPTION].

Same world, same rendering, same palette discipline, same grounded athletic
proportions. Must read as the same artist and the same game as SOL TIGRE.
```

---

## What went wrong the first time (and the fix)

v1 of Prompt B asked for "rounded caps, extra material at the joint". The
model read that as literal **cut cylinder ends**, so every limb came back
looking amputated and the assembled rigs read as segmented mannequins. The
FORBIDDEN block above is the fix — it bans cross-sections outright and asks
for anatomy that continues past the joint instead.

Second lesson: ten separately-drawn parts don't agree with each other. The
16-part sheets are better, but Prompt A (one master figure, cut afterwards)
remains the most consistent route.

## Prompt D — Parallax stage layers

Stages are four layers, back to front. Generate each SEPARATELY at the same
camera height so they line up. (The `image-extender` tool's Parallax Studio
mode does this natively — it is a good fit for stages, unlike for fighters.)

```
[STYLE LOCK — but note the overrides below]

STAGE: [NAME] — [setting, time of day, mood].

Produce the [sky / far / mid / near] layer of a four-layer parallax
background for a 2D fighting game stage.

LAYER BRIEF:
- sky : sky, clouds, horizon glow. Fully opaque. No structures.
- far : distant skyline silhouettes, low contrast, hazy, atmospheric.
- mid : recognisable buildings, palms, signage. Moderate detail.
- near: foreground detail sitting just behind the fighters. Darkest layer.

RULES:
- Wide format, roughly 3:1 — the camera pans horizontally across it
- Horizon line at the SAME height in every layer so they register
- Transparent background on far / mid / near; only `sky` is opaque
- Each layer progressively DARKER and LOWER CONTRAST than the fighters —
  this is a fighting game and the characters must stay readable at all times
- No characters, no people, no foreground objects the fighters would clip into
- No text, no signage with real brand names
- Flat even lighting, no dramatic shadows crossing the layer
```

Save as `sky.png` / `far.png` / `mid.png` / `near.png` in
`assets/stages/<stage_id>/`. They load automatically — no code changes.

## Roster status

| # | Fighter | Reference sheet | Part-out | Rigged |
|---|---------|-----------------|----------|--------|
| 01 | Sol Tigre | ✅ | ⚠️ 10-part; 16-part ON HOLD (trademarks) | ✅ (old rig) |
| 02 | Crown Saint | ✅ | ✅ 16-part | ✅ |
| 03 | The Architect | — | — | — |
| 04 | Dotty | — | — | — |
| 05 | Fresh | — | — | — |
| 06 | Cyborg Stitch | — | — | — |
| 07 | Purple Thread | — | — | — |
| 08 | Yellow Dog | — | — | — |

Two additional part-out sheets are sliced and waiting in
`assets/sprites/fighters/fighter_denim/` and `fighter_tattoo/` — rename them to
their roster fighter once identified.
