# PM98 MATCH SCREEN — reverse-engineering + rebuild

Status: **PM98 ships TWO real match presentations and an in-match picker to choose between
them.** (1) the 2D results / commentary screen (`app/scenes/MatchScreen.gd`, built) and
(2) the 2D **GRAFICO / SIMULADOR** pitch (the PC-Fútbol sprite simulator). A `MATCH OPTIONS`
panel switches view/camera. **Correction (2026-06-30, from the CD ISO):** an earlier note
called the sprite pitch "not PM98's match screen / out of scope". That was WRONG for the 2D
simulador — it is a genuine PM98 view and its data IS in the source. Only the *3D ENGINE
`.p3d`* layer is genuinely absent (see below). Verified against MANAGER.EXE + the full CD
image `~/backup/Div/premier manager 98.iso` (the `.rar` is a HD-install subset; the ISO has
the simulador data the `.rar` lacked).

## The MATCH OPTIONS picker — reversed (fn 0x4e2630 controller)

The in-match presentation controller is **`FUN_004e2630`**. It dispatches on a view-state
index `*(this+0x494)` (range 0..5) through a 6-entry jump table at **`0x4e513c`**:

    state 0 -> 0x4e29da    state 1 -> 0x4e2663    state 2 -> 0x4e29da
    state 3 -> 0x4e26ec    state 4 -> 0x4e27f3    state 5 -> 0x4e293c

(Handler ENTRY addresses are verified; the per-state *semantics* are not yet fully reversed —
do not assume which state is which mode without confirming.)

The `MATCH OPTIONS` panel title (`"MATCH OPTIONS"` @ `.data 0x657974`) is drawn by a method at
`~0x4e6be0` via the label helper `FUN_005da180`, rect `(2,2)..(437,30)`. The option buttons are
the adjacent `.data` string cluster (the in-match camera/presentation choices):

| string (.data) | VA | role |
|---|---|---|
| `CANCEL` | 0x6578f8 | dismiss |
| `STATIC CAMERAS` | 0x657900 | camera mode |
| `BRIEF` | 0x657960 | brief/summary |
| `HIGHLIGHTS` | 0x657968 | highlights |
| `MATCH OPTIONS` | 0x657974 | panel title |

Icons `img\opciones\ico_highlights.bmp` (0x657940) + `img\premier\opciones\ico_HighlightsResumen.bmp`
(0x657910). The `HIGHLIGHTS` button is laid at pos `(98,25)` size `(109,100)` inside `FUN_004e2630`
(@ `0x4e2aee`, via the proven point/rect helpers `FUN_00436fb0`/`FUN_00436fd0`).

NOTE: the `SIMULADOR` / `NARRACION SIMULADOR` / `3D ENGINE` / `GRAFICOS` strings at
`0x659e5c..0x65a160` are the **credits screen** category headers, NOT match-picker options —
don't mistake them for the picker (they have no push-imm xref from the match controller).

## The two presentations

1. **The 2D results / commentary screen** (`MatchScreen.gd`, built). Verified against the real
   game + reversed EXE strings. Over the blue stadium background (`RECURSOS.PKF` `FONDO.BMP`):
   a digital clock + half indicator (`FIRST HALF`/`SECOND HALF`/`HALF TIME`/`FULL TIME`/
   `… EXTRA TIME` in EXE); the two clubs' shirt escudos + score; a `POSSESSION PERCENTAGE` bar;
   the minute-by-minute `EVENTS` table + `COMMENTS` feed, newest highlighted; `REPLAY` /
   `CONTINUE` / `EXIT`.

2. **The 2D GRAFICO / SIMULADOR pitch** (the PC-Fútbol sprite simulator — NOT yet rebuilt, but
   FULLY SOURCED). Data pipeline, all addresses verified:
   - `PCF5DAT.PKF` (314 MB) loaded by **`FUN_004f80a0`** (string @ 0x658a60, ref @ 0x4f82ed).
   - `simulador.pgf` loaded by **`FUN_005923f0`** (string @ 0x664bb8, ref @ 0x59342c).
   - Sprite set lives in `DATSIM.PKF` (1706 entries; already extracted): `BALON.RAW` (ball),
     `CAMPINA.RAW` (pitch), `CIELO1.BMP` (sky), `COBAL1.PGF`/`COBAL2.PGF`, `COFLECHA.PGF` (arrow),
     `COBANDER.PGF` (banner), `COPITO.PGF`, `COAMARI.PGF`… — decode via `tools/re/pgf_decode.py`.
   - Simulador commentary: WAV templates @ `0x657984..0x657a3c` (`UK\JugParad`→`PAR%05d.WAV`,
     `JugPorte`→`POR…`, `JugChut`→`CHU…`, `Marcador`→`MarV%04d.WAV`, `Golde`→`Gola%04d.WAV`) in
     `SFX/COMENT.PKF` (45 MB, on the ISO).
   - **Source availability:** `PCF5DAT.PKF` + `DATSIM.PKF` + `SFX/COMENT.PKF` are all on
     `premier manager 98.iso`; `DATSIM.PKF` is also in the extracted `.rar`. The previously
     decoded sprites (`app/art/match/player_*.png`, `ball.png`, `arrow.png`) are THIS art — they
     were prematurely abandoned and should be restored under the GRAFICO view.

3. **The 3D ENGINE highlights** (`3D ENGINE`/`HIGHLIGHTS` strings; models
   `Modelos\estadios\0011\estadio.p3d`, `cesped.p3d`, `balon.p3d`, `vallas.p3d`). **The `.p3d`
   model data is absent from BOTH the `.rar` AND the CD ISO** — verified: 0 `.p3d` entries and no
   `Modelos\` folder on `premier manager 98.iso` (CD top-level = CURSORES/DBDAT/DIRECTX/SFX/
   SONIDOS/WINFONTS only). So the 3D layer cannot be ported from the available source; the 2D
   GRAFICO view above is the faithful substitute for the graphic match. This is the ONLY part
   that is genuinely out of reach with the source on hand.

## The rebuild — `app/scenes/MatchScreen.gd`

A pure function of the match minute over the `MatchCommentary` timeline (the per-shot model
lifted from `MANAGER.EXE`; `docs/re/match_engine_re.md`):
- `_score_at(m)` counts goals already played; `_events_upto(m)` is the timeline up to the
  clock (newest highlighted); `_possession_at(m)` eases 50/50 → the full-match event split;
  `_half_label(m)` flips the half; `seek(m)` jumps the clock for tests / screenshots.
- Real assets, baked from the archive: blue background `FONDO.BMP`
  (`tools/re/pkf_image.py`, DM→BM + the shared VGA palette), the per-club shirt escudos.
- Verified by `app/tests/test_match_screen.gd` (score, events, possession, half label,
  seek, button signals) and the `PM98_MATCH_SHOT` real-render (Xvfb / `DISPLAY=:1` GL).

## On the DATSIM sprite pitch (earlier "out of scope" — RETRACTED)

`DATSIM.PKF` IS the **PC-Fútbol 5.0 2D simulador** art that PM98 reskins (boards carry both
`PC FUTBOL 5.0` / `dinamic multimedia` AND the Premier skin `HIERPREM.RAW`, boards
`PREMIER MANAGER 98` / `actua SPORTS`). An earlier session composed a 3/4 broadcast pitch from
`JUG.PGF` sprites + the `HIERBA` atlas, then dismissed it as "not PM98's match screen". That
dismissal is now RETRACTED: the EXE proves PM98 loads `PCF5DAT.PKF`/`simulador.pgf` and offers a
`MATCH OPTIONS` view picker (above), so the 2D simulador IS one of PM98's real match views. The
decoders (`tools/re/pgf_decode.py`, `export_match_art.py`) and their output
(`app/art/match/player_*.png`, `ball.png`, `arrow.png`) are the foundation for the GRAFICO view,
not dead reference.

## Build plan (faithful, source-only)

1. **MATCH OPTIONS picker** — small overlay offering the reversed options (BRIEF / HIGHLIGHTS /
   STATIC CAMERAS / CANCEL + the NARRACION text screen). Recover each button's exact rect from
   `FUN_004e2630` (the HIGHLIGHTS rect is known; trace the siblings) before drawing — do NOT
   invent coordinates.
2. **NARRACION** → the existing `MatchScreen.gd` (built).
3. **GRAFICO / SIMULADOR** → restore the 2D sprite pitch from `DATSIM.PKF`/`PCF5DAT.PKF`, driven
   by the reversed match engine's per-minute event timeline (positions interpolated from the same
   `MatchCommentary` model the text view uses, so both views agree on the scoreline).
4. **HIGHLIGHTS 3D** → honest stub (`.p3d` not in source); `REPLAY` re-runs the chosen view.
