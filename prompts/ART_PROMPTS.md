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

## Prompt B — Part-out sheet (what the rig consumes)

This is the important one. Its output feeds `tools/slice_parts.py` directly.

```
[STYLE LOCK]

SUBJECT: [NAME] — [age, height, build]. [Wardrobe and identity markers].
[Personality in three words].

TASK: Produce a CHARACTER PART-OUT SHEET for 2D skeletal rigging.

Draw the character ONCE in a relaxed neutral side-facing 3/4 stance, then
present each body part SEPARATED and spaced apart on the same sheet, laid
out flat with clear gaps between pieces, like disassembled paper-doll parts:

  1. head + neck stub        2. torso
  3. upper arm — FRONT       4. forearm + hand — FRONT (relaxed fist)
  5. upper arm — BACK        6. forearm + hand — BACK (relaxed fist)
  7. thigh — FRONT           8. shin + foot — FRONT
  9. thigh — BACK           10. shin + foot — BACK

RULES:
- Every part drawn from the SAME side-facing 3/4 angle, same light, same scale
- Each part must OVERLAP generously at the joint end (rounded caps, extra
  material at shoulder/elbow/hip/knee) so limbs don't gap when rotated
- Parts NOT touching each other — clear space between every piece
- Pure white background, no drop shadows under parts
- Assembled reference figure on the far left, 540 pixels tall
- Label each part with small plain text beneath it
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

## Known cleanup step

The generated parts carry flat rounded **joint caps** on their overlap ends.
The rig tucks most of them under the neighbouring part, but some peek out at
knees and wrists. Fix in Krita: soften or erase the flat cap so the limb ends
in drawn anatomy instead of a disc. One pass per fighter, ~20 minutes.

## Roster status

| # | Fighter | Reference sheet | Part-out | Rigged |
|---|---------|-----------------|----------|--------|
| 01 | Sol Tigre | ✅ | ✅ | ✅ |
| 02 | Crown Saint | — | ✅ | ✅ |
| 03 | The Architect | — | — | — |
| 04 | Dotty | — | — | — |
| 05 | Fresh | — | — | — |
| 06 | Cyborg Stitch | — | — | — |
| 07 | Purple Thread | — | — | — |
| 08 | Yellow Dog | — | — | — |

Two additional part-out sheets are sliced and waiting in
`assets/sprites/fighters/fighter_denim/` and `fighter_tattoo/` — rename them to
their roster fighter once identified.
