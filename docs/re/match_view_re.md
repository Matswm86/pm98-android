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

### Honest scope (what is NOT a 1:1 port)
- The original DATSIM is a **horizontally-scrolling 3/4 tile-scroll camera** that follows
  the ball, composed from the `HIERBA` stadium tile atlas. The rebuild uses a clean fixed
  broadcast pitch (drawn vectorially) instead of reversing that tile-projection/scroll
  engine — the same pragmatic call made for the STADIUM pre-render. Reversing the scroll
  camera + tile layout is the next refinement.
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
