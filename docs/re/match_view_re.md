# PM98 2D MATCH VIEW (DATSIM) — reverse-engineering + rebuild (A1)

Status: **PGF sprite format CRACKED; all DATSIM match art decoded; a real-sprite
2D match view (`app/scenes/MatchScreen.gd`) built and driven by the reverse-engineered
match engine.** This closes the long-standing "A1 — the iconic DATSIM, NOT CRACKED"
blocker from the screen-rollout handoffs.

The match SCORELINE + the minute-by-minute event stream were already reversed
(`docs/re/match_engine_re.md`: the per-shot model, the MSVC LCG, the verified event
enum) and live in `app/scripts/{MatchEngine,MatchCommentary}.gd`. This document covers
the missing half: the **visuals** — the DATSIM sprite archive and how the rebuilt view
uses them.

## The asset archive — DATSIM.PKF

`DATSIM.PKF` (5.7 MB, 1704 entries) is the PC Fútbol 5 match-graphics pack. It uses
the same PCF5 `.PKF` container as the rest of the game (cracked in `pkf_format.md`);
extract with `tools/re/pkf_unpack.py --extract /tmp/datsim_out DATSIM.PKF`. Contents:

| asset(s) | what it is |
|---|---|
| `JUG.PGF` (3.7 MB, **4211 frames**) | the player sprite sheet (jugador) — directional run/idle cells |
| `CO*.PGF` | match overlays: `COFLECHA` selection arrow (8 angles), `COROJA`/`COAMARI`/`COAMAROJ` red/yellow cards, `CORELOJ` clock, `COBAL*` ball-burst, `COBANDER` flag |
| `BALON.RAW` (256×256) | ball atlas: the ball at many sizes (= height off the ground) × spin frames; bg/transparent index = the byte at offset 0 (41) |
| `HIERBA.RAW` / `HIE*.RAW` / `CAMPINA.RAW` (256×256) | the stadium **tile atlas**: grass strips, crowd stands, ad-boards (`PC FUTBOL 5.0`, `LFP`, `dinamic multimedia`), plus the outside-ground horizon (trees/buildings) |
| `CIELO1.BMP` (640×480) | the sky backdrop (clouds top, solid blue below the stands) |
| `RED.BMP` / `REDHW.BMP` (256×256) | the goal net |
| `PALETA.ACT` | the 256-colour match palette (Adobe colour table, raw 256×3 RGB) |
| `PALPOR*/PALARB*/PALLIN*.DAT` (256 B each) | **palette-remap LUTs** (index→index) for goalkeeper / referee / linesman kits — the original's recolour mechanism |
| `P96A*/P96B*.DAT` (~1658 files, 192 B each) | pre-recorded player/ball **motion scripts** (set-piece "jugadas"). NOT used by the rebuild — we drive motion from our own engine events instead. |
| `JUGCAM.IND` (256×216) | per-shirt index map (the kit-number/colour selector) |

## The `.PGF` sprite format — CRACKED

Reversed by structural analysis + a from-scratch decoder that walks all 4211 JUG.PGF
frames and lands **exactly** on EOF (the proof). Decoder: `tools/re/pgf_decode.py`.

```
file header:   char[4] "LFGP"  +  u32 frameCount
per frame:     char[4] "-FGP"  +  i32[6] header  +  W*H raw indexed bytes
```

The 4-char tags are "PGF" + a type byte (`L` = library/list header, `-` = frame).
The 6 i32 header fields, verified against COFLECHA / COROJA / JUG:

| field | meaning |
|---|---|
| `[0]` | a logical/visible width (≤ W) — role still loose |
| `[1]` | **H**, bitmap height |
| `[2]` | **anchorX**, signed hotspot X offset |
| `[3]` | anchorY-ish / reference height |
| `[4]` | **W**, bitmap width |
| `[5]` | a per-frame tag (0..71, mostly 0); not load-bearing for the blit |

Pixels are **raw, uncompressed, 1 byte/pixel** palette indices (datalen == W*H exactly,
which is what rules out RLE). **Index 0 = transparent** (the ubiquitous 0x00 padding).
Colour = `PALETA.ACT[index]`. Per-team kits are produced in the original by running the
indices through a `PAL*.DAT` LUT before the palette lookup.

Verified visually (the project's no-display fidelity gate): COFLECHA decodes to the
rotating red selection arrow, COROJA to the spinning red card, JUG to thousands of
recognisable footballer run/idle cells. The JUG layout is grouped in **8s = 8 compass
facings** (the per-group width pattern 20,16,12,12,12,16,20,20 — side views widest,
front/back narrowest — is the tell), with successive groups stepping the run cycle.

## The rebuild — `app/scenes/MatchScreen.gd` (A1)

`tools/re/export_match_art.py` bakes the needed sprites into `app/art/match/`:
`player_home.png` / `player_away.png` (a [3 anim × 8 direction] run sheet, kit
recoloured red/blue by a luma-preserving hue shift of the green placeholder kit ramp),
`ball.png` (a clean on-ground football), `arrow.png` (the COFLECHA marker).

`MatchScreen.gd` renders a **3/4 broadcast pitch** (perspective trapezoid: length L↔R,
width far/top↔near/bottom; mowing stripes, centre circle, penalty boxes, goals, sky
band) and places the 22 real DATSIM player sprites + the ball on it, **driven by the
engine's `MatchCommentary` timeline**. The whole on-pitch layout is a **pure function
of the match minute**: the ball interpolates an event-keyframe path (goals drive it to
the scoring side's goal; corners/fouls pull it into that third), the 22 players hold a
4-4-2 that slides to compact around the ball, the nearest attacker carries it (marked by
the arrow). Sprites depth-scale + depth-sort. `_process` just advances the clock; `seek()`
jumps it (for tests / screenshots). Verified by `app/tests/test_match_screen.gd` (layout
stays on-pitch every minute, scoreboard counts goals, ticker tracks lines) and by the
`PM98_MATCH_SHOT` real-render path in `screenshot.yml` (Xvfb + software GL).

### Scroll camera (T1 #4) — DONE
The view is now a **horizontally-scrolling 3/4 camera that follows the ball**, like the
original DATSIM (it was a fixed whole-pitch shot before). `_project(l,w)` windows the
length axis around a camera focus `_cam_l`: `x = CENTER_X + (l - _cam_l)/VIEW_HALF * half`,
so the visible window `_cam_l ± VIEW_HALF` (VIEW_HALF=0.34, ~1.5x zoom) fills the screen and
both touchlines stay visible. `_cam_at(ball) = clamp(ball.l, VIEW_HALF, 1-VIEW_HALF)` pans
the focus to track the ball, clamped so the view never scrolls past either goal (the goal
line then sits at the screen edge). It is a **pure function of the minute** (it reads the
already-eased `_ball_at` path), so `seek()` / the screenshot tests stay reproducible. The
grass is now length-direction **mowing stripes drawn through the camera**, so they scroll
with it (the visible cue that the camera is panning). Verified by `test_match_screen`
(camera pans both ways 0.34 < 0.50 < 0.66; ball always on-screen; layout pure) and three
`PM98_MATCH_SHOT` GL captures (left goal at kick-off, right goal at the goal minute).

### Honest scope (what is still NOT a 1:1 port)
- The pitch is still **drawn vectorially** (trapezoid + mowing stripes + line markings),
  NOT composed from the real `HIERBA`/`CAMPINA` stadium **tile atlas** (decoded — grass
  strips, crowd stands, `PC FUTBOL 5.0`/`LFP` ad-boards, plus a `HIERPREM.RAW` Premier
  variant — see `tools/re/` and a render in the session notes). Skinning the pitch + a
  crowd-stand / ad-board backdrop from that atlas (and the `CIELO1` sky) is the remaining
  refinement; the exact tile-projection math in MANAGER.EXE is not yet reversed, so doing
  it faithfully (not by guessing the layout) is the open piece.
- Player **kit colour** is now REAL per-club: the sprite is split into a true-colour base
  layer (skin/boots/detail) + a kit-luma layer that MatchScreen tints to each club's actual
  kit colour, derived from the game's own kit art `app/art/kits/<club-id>.png` (the dominant
  saturated colour of the home/away shirt half). Clashing fixtures fall back to a contrasting
  colour. Still a refinement: pulling a club's SECONDARY colour for a better clash fallback,
  shirt-vs-shorts as two colours, and the original `PAL*.DAT` LUT / `JUGCAM.IND` shirt path.
- The 8-direction facing uses the JUG group-of-8 layout with a tunable `DIR_ANGLE` map;
  fine-tune the column→angle mapping against the real CI render.
- Player **leg animation** cycles the 3 exported anim rows; the full JUG animation
  taxonomy (run vs walk vs tackle vs shoot, per direction) is left as a refinement — the
  motion is driven by our engine, not the original `P96*.DAT` motion scripts.

## Tooling added this session
- `tools/re/pgf_decode.py` — PGF format decoder (`info` / `sheet` / `frames`).
- `tools/re/export_match_art.py` — bakes the match atlases into `app/art/match/`.
- `tools/re/preview_match.py` — PIL mirror of MatchScreen for no-display layout checks.
