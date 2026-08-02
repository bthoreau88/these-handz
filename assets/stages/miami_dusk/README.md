# MIAMI DUSK — stage layers

Drop parallax layer PNGs here. Every file is OPTIONAL: any layer that is
missing falls back to a procedural placeholder, so the stage always renders
and real art can land one layer at a time.

| File      | Scroll | What it is                                  |
|-----------|--------|---------------------------------------------|
| `sky.png` | 0.02   | Sky / horizon. Barely moves.                 |
| `far.png` | 0.20   | Distant skyline.                             |
| `mid.png` | 0.45   | Mid buildings, palms, signage.               |
| `near.png`| 0.75   | Foreground detail just behind the fighters.  |

Author them **wide, not tall** — each layer is scaled to the stage's playable
width (`GameConstants.STAGE_PLAY_WIDTH`, currently 1920) and its bottom edge
is aligned to the ground line. Transparent PNG for everything except `sky`.

Nearer layers need more horizontal length than farther ones, because they
travel further as the camera pans. Give `near.png` roughly 2x the stage width.

Keep the fighters readable: this is a fighting game, so the near layer must
never out-contrast the characters. Darker and lower-saturation than the
fighters is the rule.

Scroll rates live in `GameConstants.STAGE_LAYERS`; colors for the placeholder
in `GameConstants.STAGES`.
