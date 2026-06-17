# PM98 MATCH SCREEN — reverse-engineering + rebuild

Status: **the real PM98 "watch a match" view is the 2D results / commentary screen,
rebuilt faithfully in `app/scenes/MatchScreen.gd` and driven by the reverse-engineered
match engine.** Corrects an earlier build that drew a 3/4 *sprite pitch* from the
`DATSIM.PKF` art — that pitch is not how Premier Manager 98 shows a match.

## What the real match screen is

Premier Manager 98 (Gremlin, 1998; developed by Dinamic) has two match presentations:

1. **The 2D results / commentary screen** (this rebuild). Verified against the real game
   (myabandonware / old-games screenshots) and the reversed EXE strings. It shows, over the
   blue stadium background (`RECURSOS.PKF` `FONDO.BMP`):
   - a digital clock + half indicator — strings `FIRST HALF` / `SECOND HALF` / `HALF TIME` /
     `FULL TIME` / `… EXTRA TIME` are in `MANAGER.EXE`;
   - the two clubs' shirt escudos + the score;
   - a `POSSESSION PERCENTAGE` bar (string in EXE; red home / green away);
   - the minute-by-minute **EVENTS** table (`MIN | COMMENT`), the `COMMENTS` /
     `NARRACION SIMULADOR` feed, newest line highlighted;
   - `REPLAY` / `CONTINUE` / `EXIT` buttons.
2. **The premium 3D "highlights"** — the Actua-engine 3D match (strings `3D ENGINE`,
   `HIGHLIGHTS`; models `Modelos\estadios\0011\estadio.p3d`, `cesped.p3d`, `balon.p3d`,
   `vallas.p3d`). **The `.p3d` model data is CD-streamed and is NOT in the hard-drive
   archive** (`Premier_Manager_98.rar`, 0 `.p3d` entries). So the 3D highlights cannot be
   ported from these files; `REPLAY` here just re-runs the text. Out of scope by design.

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

## What was wrong before (DATSIM sprite pitch)

`DATSIM.PKF` is the **PC Fútbol** 2D *simulador* art (its ad-boards read `LFP` /
`PC FUTBOL 5.0` / `dinamic multimedia`; the Premier skin is `HIERPREM.RAW`, boards
`PREMIER MANAGER 98` / `actua SPORTS`). An earlier session composed a 3/4 broadcast pitch
from `JUG.PGF` player sprites + the `HIERBA` stadium atlas. That look is not PM98's match
screen — the game's 2D match is the results/commentary screen above. The sprite/atlas
decoders (`tools/re/pgf_decode.py`, `export_match_art.py`) remain for reference but their
output (`app/art/match/player_*.png`, `ball.png`, `arrow.png`) is no longer used by the view.
