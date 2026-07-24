# MONTHLY AWARDS — MANAGERS / PLAYERS OF THE MONTH (frame RE)

The two sheets the original raises during the CONTINUE chain at the end of a
calendar month. Built 2026-07-24 after the owner reported "the monthly awards
screens are not showing" — they had never been ported.

## Binding frames

Both from the real `MANAGER.EXE` under wine, Bolton W career, end of August 1997
(`screenshots/wine-captures-2026-07-18-goalscorers/`):

| frame | state |
|---|---|
| `76_after_drawcont.png` | **MANAGERS OF THE MONTH (AUGUST)** — four division cards, each `kit | division header | manager | club`, + OK |
| `77_after_motm.png` | **PLAYERS OF THE MONTH (AUGUST)** — PREMIER LEAGUE selected, 20 clubs in two `TEAM | PLAYER` columns, division tabs + OK |
| `78_after_potm.png` | the hub straight after: the sequence is week-4 CONTINUE → the Coca-Cola Cup draw → 76 → 77 → hub |

Bake: `tools/re/build_awards_chrome_from_frames.py` →
`app/art/screens/awards/{managers,players,tab_*}.png` +
`tools/re/specs/awards_chrome_samples.json`.
Screens: `app/scenes/ManagersMonthScreen.gd`, `app/scenes/PlayersMonthScreen.gd`.

## The shared green caption bar

Both captions carry the MONTH, so the bar is redrawn rather than baked. Its
checker rail is a **fixed tile ladder**: reading OUTWARD from the title field the
tiles run `2, 4, 9, 11, 15` with gaps `5, 4, 3, 2, 1`, then a solid block to the
panel edge. That ladder is byte-identical in both frames — 77's caption is 10px
narrower and **every tile shifts by exactly 10** — so it is anchored to the
caption's own edge, not to the panel. Measured runs (left rail, frame-absolute):

| frame | tiles (outer → inner) |
|---|---|
| 76 | 14-35, 37-51, 54-64, 68-76, 81-84, 90-91 |
| 77 | 14-45, 47-61, 64-74, 78-86, 91-94, 100-101 |

Rail inner end = caption ink x − 35 (76: 127−92; 77: 136−102, so ±1).
Tile `(0,63,0)` on field `(17,127,43)`, rows y0+3 … y1−4.
Caption face = **ProMan14** (advance sums 386 / 367 against the frames' ink
extents 384 / 365; no other bank font is within 50px), white, centred on x=318.

## MANAGERS panel (frame 76)

Panel `(14,124)-(626,276)`. Caption band y126..146.

| card | kit | header | value row | manager cell | club cell |
|---|---|---|---|---|---|
| PREMIER | (18,160) 28x32 | y162..177 | y179..190 | x46..175 | x177..313 |
| FIRST | (321,160) | y162..177 | y179..190 | x349..478 | x480..616 |
| SECOND | (18,205) | y207..222 | y224..235 | x46..175 | x177..313 |
| THIRD | (321,205) | y207..222 | y224..235 | x349..478 | x480..616 |

Frame-sampled inks: the manager's surname is **white**; the club name is a
per-division **dark tint** — PREMIER `(135,73,22)`, FIRST `(0,95,0)`,
SECOND `(60,80,100)`, THIRD `(85,0,0)`. OK at `(536,243)-(614,271)`.

## PLAYERS panel (frame 77)

Panel `(24,92)-(615,382)`. Caption y94..114, division sub-header y117..136,
column headers baked. Ten rows per column, `y = 153 + 16i`, height 12:

| column | TEAM cell | PLAYER cell |
|---|---|---|
| left | x33..179 (right-aligned, black) | x181..310 (left-aligned, white) |
| right | x329..475 | x477..606 |

Rows alternate two shades per cell (baked). Clubs run alphabetically down column
one then column two — the frame's own order (Arsenal … Everton | Leeds Utd …
Wimbledon). Division tabs y350..372 at x33/152/271/391, OK at x511..606.

## What is NOT reversed (ours, and says so in the code)

* **Who wins.** The binary's selection rule was not reversed. `Career` picks:
  * MANAGER OF THE MONTH = the division's best record over the month (points
    won, then goal difference, then goals for), from a table snapshot taken at
    the month's first round — this career's own played results, nothing invented.
  * PLAYER OF THE MONTH = each club's top league scorer over the same window,
    off the scorer log the GOAL SCORERS chart already keeps. A club that did not
    score prints no name; the original always names one, but inventing a name
    would be worse. Frame 77 confirms the original is NOT purely goals-based
    (Lundekvam, Matteo and De Zeeuw are defenders), so this is an approximation
    and is flagged as one.
* **The selected face of FIRST / SECOND / THIRD.** Only PREMIER is witnessed
  selected (77). A tab swap reuses PREMIER's glow with the tab's own label.

## Verification

* `app/tests/test_month_awards.gd` — the model closes AUGUST inside the first 8
  rounds, names a winner per division and one row per club, both screens mount,
  populate and answer OK, and a pending sheet survives save/load.
* `app/tests/shot_month_awards.gd` renders both sheets with the frames' own
  winners. Against frame 76 the caption rails are **pixel-identical outside
  x100..550** and the whole panel differs 7.6%, all of it the bold glyph raster
  (the award faces are not in the extracted `.fnt` bank — the same residual class
  as the goalscorers bold names) plus the kit blocks, which the shot feeds with
  no club id.
