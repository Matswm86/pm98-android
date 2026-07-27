# TACTICS (TACTICAS) screen — reversed from MANAGER.EXE

The full TACTICS board, reached from the LINE-UP screen's `TACTICS` button
(frame `013_162412` → `014_162413`). Distinct from the **TEAM TACTICS** modal
(`TeamTacticsScreen.gd` = the ATTACK|DEFENCE panel, frame-baked from parity-run orig/25): this is the outer screen
titled just `TACTICS %s` (club name) that shows the XI with ROLE/POS columns, a
skill-emphasis grid, and the big pitch with the formation's two-phase markers.

Binding frame: `screenshots/original-walkthrough-2026-07-02/014_162413.png`
(Man Utd, 3-5-2, RATING view). Witness frame for the star rule:
`015_162415.png` (VIEW RIVAL shares the row star strip). Builder: `FUN_00568800`
(entry `0x568800`; the auto-analyzer mis-splits it as `FUN_00568a3d`). Predef
overlay: `FUN_0056f4c0`. Predef repaint: `FUN_0056ac90`. Team-tactics modal
spawn: `FUN_0056ea15`. Row-tint picker: `FUN_004fe2d0` (decompiled 2026-07-03).
All coords 640x480 px.

**PIXEL PARITY (2026-07-03): `tactics_014` vs frame 014 = 0px — pixel-exact,
FULL FRAME** (`tests/shot_entry_parity.gd` + `tools/re/diff_entry_parity.py`;
no ROI since the same-day barra/header pass — the shared band above y62 is
baked + decoded in `docs/re/match_header_re.md`). NO exclusions; the AV values
are injected frame-true in the shot because the AV formula is un-RE'd (see
"Honest gaps").

## Widget rectangles (VERIFIED via push-tracking disasm of FUN_00568800)
| element | string / bmp @VA | pos (x,y) | size (w,h) | rect |
|---|---|---|---|---|
| title | `TACTICS %s` @0x66164c | (150,16) | (297,27) | shared chrome title bar |
| PREDEF. TACTICS | `PREDEF. TACTICS.` @0x66151c + `predef.bmp` | (7,373) | (156,29) | 7..163, 373..402 |
| LOAD TACTICS | `LOAD TACTICS` @0x6614e8 + `carga.bmp` | (7,407) | (156,29) | 7..163, 407..436 |
| SAVE TACTICS | `SAVE TACTICS` @0x6614d8 + `grabar.bmp` | (7,443) | (156,29) | 7..163, 443..472 |
| PARAM. | `PARAM.` @0x65f7b4 | (478,286) | (72,23) | 478..550, 286..309 |
| RATING | `RATING` @0x654fa8 | (558,286) | (72,23) | 558..630, 286..309 |
| TEAM TACTICS | `TEAM TACTICS` @0x6614a4 + `equipo.bmp` | (478,330) | (152,25) | 478..630, 330..355 |
| VIEW RIVAL | `VIEW RIVAL` @0x661498 + `verrival.bmp` | (478,365) | (152,25) | 478..630, 365..390 |
| LINE-UP | `LINE-UP` @0x656334 + `ali.bmp` | (478,400) | (152,25) | 478..630, 400..425 |
| RETURN | `RETURN` @0x6549e4 | (498,440) | (112,25) | 498..610, 440..465 |
| skill grid | HANDLING..SHOOTING | (7,275) | (156,91) | 7..163, 275..366 |
| pitch title bar (`TACTICS 3-5-2`) | (dynamic) | (177,275) | (278,30) | 177..455, 275..305 |
| CAMPO pitch | `tacticas\campo.bmp` (278x167, 1:1) | (177,305) | (278,167) | 177..455, 305..472 |
| marker layer (child of pitch) | — | rel (10,5) | (258,154) | abs origin (187,310) |

## XI table (frame-measured, pixel-exact)
Panel border x7-8 / x631-632, y67-68; column-header band y69..86 (STATIC chrome).
11 row strips **14px tall at 16px pitch**, tops `y = 87 + 16*i`, x8..631 (the
grey "+"-card icon at x8..25 is identical on every row — row furniture, NOT a
crest). Columns: `N. | PLAYER | EN SP ST AG QU FI MO | AV | ROLE | POS`; unlike
LINE-UP the ROLE column shows the **full fine-role name** (the LONG table at
`0x662db0`, indexed by `posFine`, see positions_re.md) and a left `flecha.bmp`
arrow before the broad `POS` code. Only the 11 starters are listed.

### Row tint = the FORMATION SLOT's band, not the player's POS (FUN_004fe2d0)
Decompiled 2026-07-03 — the recurring "why is Pallister lavender" mystery:
```
row 0                     -> 0xadffff  yellow  (GK row)
slot mk1.x_raw < 0x41(65) -> 0xd6fbde  green   (DEF band)
elif mk2.x_raw < 0x104    -> 0xffcfce  lavender(MID band)
else                      -> 0xadbeff  salmon  (FWD band)
```
The thresholds test the SLOT the player occupies, not his position: in frame 014
Pallister (POS DEF) and Sheringham (POS FOR) sit in MID slots → lavender. In
`formations.json`'s pre-scaled 258x154 space the thresholds become
`mk1.x < 52` / `mk2.x >= 211`. Palette-snapped fills measured off the frame:
gk (255,255,170) · def (220,250,210) · mid (204,204,255) · fwd (255,191,170).

### Faces, inks and the GDI cell centring (all frame-fit to 0px)
| element | face | ink | placement |
|---|---|---|---|
| shirt N. | ProMan8 @11 | navy (0,0,128) | cell x33 w17 |
| player name | ProMan8 @11 | black | left x67 (Title-cased) |
| star strip | STARJUGON.BMP 14x12 | — | x172+14j, row+2 |
| AV | ProMan8 @11 | red (210,0,0) | cell x351 w22 |
| camrol | camrolNN 25x14 | — | (375, row+0), black backing |
| ROLE name | **EURO8** @11 (WINFONTS/EURO8.FNT) | (60,80,100) | cell x402 w166 |
| POS word | ProMan8 @11 | black | cell x590 w30 |
| pitch title | ProMan12 @13 | white | centred in bar, y_top 284 |

Centred cells use the GDI rule `px = x0 + (cell_w - advance_w) div 2` (integer
floor). EURO8 was identified by per-letter painted-width match (G6 O6 A7 L4 K6
E5 P6 R6, 8px caps) — ProMan8/10 and Calend8/12 all mismatch; exported via
`fnt_to_bmfont.py` to `app/art/fonts/euro8.fnt`.

### Star strip (RATING view) — STARJUGON, halves = (AV+1) div 10
The row stars are `STARJUGON.BMP` / `STARJUGON-OFF.BMP` (14x12) — NOT the 10px
STARPARON pair (which cannot produce the measured 12px gold runs; STARPARON is
the star used by other widgets). Rule fitting all 22 observations across frames
014+015: `halves = (AV+1) div 10`; draw `halves/2` full stars at x172+14j; an
odd half renders as **STARJUGON-OFF — the dimmed star — at the next cell**, not
a clipped half glyph (015 rows with AV 89/90/91 show it; rows with AV<=88 show
nothing at cell 5). AV<=88 → exactly 4 full stars in both frames.

## PARAM. / RATING toggle (bit `0x8` of `+0x144`)
Frame 014 bakes RATING-active (red glow, yellow label) / PARAM.-inactive. The
flipped state is UN-WALKED: the app overlays the frame's own buttons with the
labels inpainted out (`plate_active/inactive.png`) + redrawn labels — documented
extrapolation.

## The pitch — ERRATUM 2026-07-03 (supersedes the stretch claim)
`recursos\iconos\tacticas\CAMPO.BMP` is a **dedicated 278x167 bitmap** blitted
**1:1 at (177,305)** — the earlier "152x92 campo stretched into the 278x167
control" claim was WRONG (the 152x92 CAMPO.BMP is the LINE-UP mini-pitch; the
two live in different PKF dirs under the same name). Verified: the decoded
278x167 art matches the frame everywhere outside the 21 marker boxes (0 stray
px, asserted in the bake).

### Markers (VERIFIED, 0px)
Marker sprites are the TACTICAS-dir **16x16** set: `DVERDE.BMP` disc (primary /
defensive, fields [4],[5]) + `AVERDE.BMP` horizontal movement arrow (secondary /
attacking, fields [6],[7]); `DROJA/AROJA` are the red (rival) variants and
`fleul/fleur/fledl/fledr` (10x10) exist for un-walked states — **every arrow in
frame 014 is the horizontal AVERDE**. Sprites draw **top-left at
`(187 + mk.x, 310 + mk.y)` 1:1** — `formations.json` mk values are already
pre-scaled into the 258x154 layer space by `export_formations.py`
(`raw*258/318, raw*154/198`); the board applies NO second scaling. GK slot
(`gk_slot`=10) parks at (0,68) and draws no arrow (mk1 == mk2).

Shirt digits: ProMan8, glyph-cell top at sprite row 2 (paints y+4..y+10), ink
**dark-green (17,90,34) on discs, black on arrows**, `x = (win - advance_w)/2`
truncated toward zero, and **RECT-CLIPPED to a digit window** of `win` px from
the sprite's left edge: **16 (disc) / 13 (arrow)** — digits DO paint over grass
at the disc's transparent corners (slot9 "20") but never beyond the window (the
arrow "20"s lose their overhanging columns). Frame 014 slot→shirt: slots 0..9 =
2,3,21,6,8,7,10,9,11,20; GK 1.

## The pitch title bar ("TACTICS %s")
An engine-drawn, mirror-symmetric **dithered gradient** (only 3 distinct column
types; no clean horizontal period; no source bitmap — the IMG.PKF
`DEGRADADO_MASK_*` entries are unrelated noise dithers). The chrome bakes the
frame's bar with ONLY the white glyph pixels of "TACTICS 3-5-2" cleared (the
screen repaints the identical text — parity verifies the text draw); for OTHER
formations the screen first blits `title_bar.png`, a mirror-reconstruction of
the bar whose centre columns are a documented approximation (un-walked titles).

## PREDEF overlay (FUN_0056f4c0) — the 10-formation picker
Tapping PREDEF opens a centred child window (`0x1c3 x 0xfa` = 451x250 body)
holding a **5-col x 2-row** grid of the 10 formation thumbnails + a `CANCEL`
button (`0x6578f8`, rel (0xaa,0xda) size (0x6e,0x19)). Thumbnail k at
`x=(k%5)*0x50+0x18, y=(k>4)*0x64+0x23`. Names from the pointer table `0x6601f8`:
**3-4-3, 3-5-2, 4-3-3, 4-4-2, 5-3-2, 5-4-1, 4-2-4, 5-2-3, 4-5-1, 3-3-3-1**.
`PREDEFWINCAMPO.BMP` (80x75) is the thumbnail pitch art (not yet baked — the
picker is un-walked and keeps the PMChrome-primitive look).

## Baked assets (parity pass 2026-07-03)
- `tools/re/build_tactics_chrome_from_frames.py` → `app/art/screens/tacticas/`:
  `chrome.png` (640x418 body, rows cleared to panel white, clean campo, title
  glyphs cleared), `row_{gk,def,mid,fwd}.png` (624x14 templates, all four
  furniture-identical modulo tint — asserted), `star_full/star_off.png`
  (STARJUGON pair), `campo.png` (278x167), `title_bar.png`,
  `plate_active/inactive.png`, + `app/art/icons/tacticas/
  {dverde,averde,droja,aroja,fleul,fleur,fledl,fledr}.png` and
  `tactics_chrome_samples.json` (specs + app/data mirrors).
- `tools/re/export_formations.py` → `app/data/formations.json` (unchanged).
- `fnt_to_bmfont.py` → `app/art/fonts/euro8.fnt` + `calend12.fnt` (Calend12 was
  a candidate for the ROLE face — kept exported, unused).
- The pre-parity 10x10 `mk_disc/mk_arrow/star_on/star_off` icon exports were the
  LINE-UP-dir variants — superseded for this screen.

## App mapping (→ `app/scenes/TacticsBoardScreen.gd`)
Native 640x480, scales to fit. Chrome blitted at (0,62) under the frame-baked
match header (`PMChrome.draw_match_header`, spec in match_header_re.md;
pixel-exact since 2026-07-03). Rows = template blit by
slot band + dynamic text/stars/camrol; markers = cached ImageTexture composites
(sprite + rect-clipped digits). Buttons are baked chrome with live hit-rects.
PREDEF → picker overlay; LOAD/SAVE → `_load_tactics`/`_save_tactics`;
TEAM TACTICS → `TeamTacticsScreen` modal; VIEW RIVAL → `RivalScreen`; LINE-UP →
`LineupScreen`; RETURN → hub. PARAM./RATING toggles the stat columns.

## Honest gaps (documented, not faked)
- **The AV formula is CLOSED (2026-07-06 — morale_re.md).** AV =
  `FUN_00581e60` = (VE+RE+AG+CA + FITNESS + displayed-MO)/6, confirmed from
  the paint side: the squad-table row painter `FUN_004f5260` draws that
  function's value into the walked AV cell (rel 0x142..0x15a = screen
  353..377) and feeds the same value to the RATING-mode star strip
  ((AV+1)/10 halves). The 10-attr weighted-mean search recorded here failed
  because FI/MO are DYNAMIC bytes, not EQUIPOS attrs — Giovanni 91 vs
  Rivaldo 90 on equal core4 352 is FI/MO variation; the walked preseason
  frames need FI ≈ 95-99 (the halfway-to-40 fitness event lands at season
  kickoff). The screen renders `p["av"]` when present (parity shots inject
  the frame values — the frame's exact FI/MO are not reproducible live) else
  `Morale.av6` when the squad carries form, else the attrs-mean fallback.
- **Per-slot ROLE-reassign arrow is drawn (baked) but read-only** — the app has
  no role-override model (the match engine reads `posFine` from the DB).
- **PARAM. (numeric) view is un-walked on this screen** — the numeric column
  layout mirrors the header columns; no frame binds it.
- **LOAD TACTICS** applies the last user-saved preset; the saved-list picker
  overlay is deferred. **Skill-emphasis grid** = baked chrome, display-only.
- Title-bar centre columns + flipped-toggle plates are reconstructions
  (un-walked states), per above.
