# SELECT LEVEL OF THE GAME dialog (NIVELES) — reversed from MANAGER.EXE

Binding frames: `screenshots/original-walkthrough-2026-07-02/002-007_1543xx.png`.
**Frame 002 is a mid-zoom ANIMATION frame (dialog ~0.8 scale) — do NOT measure off it;
frames 003/004/007 show the settled dialog** (verified: diff(003,002) bbox = exactly
(93,32)-(546,447) = the reversed dialog rect).

Widget-creation function ~`0x54a580..0x54a9ed`, paint fn `0x54ac80+` (title strings
"SELECT LEVEL OF THE GAME"/TRAINER/MANAGER/ACCOUNTANT/TOTAL set at `0x54adca..0x54afaf`).
Decoded with the capstone walker (`tools/re/pe.py`), helpers: `FUN_00436fb0(y,x)` point
(LAST push = x; pt#1 = SIZE, pt#2 = POS), `FUN_00436fd0(pos,size)` rect,
`FUN_005c06d0` blit, `FUN_00437020(r,g,b)` colour (r = last push), `FUN_005beae0` font.

## Dialog

- Container widget id 1034: **POS (93,32), SIZE 453×415** → (93,32)-(546,447).
  Verified: frame-diff bbox x 93..545, y 32..446 ✓.
- Background art: `recursos\iconos\NIVELES\fondo.bmp` = **453×383 BM, palette
  MENU.PAL** (embedded palette is junk — force external; MANAGER/DBASE/VGA are wrong).
  Blitted at client (0,0). Provides: black title strip (client y 0..24), navy swirl
  interior, thin border. Its own baked silver bands (art y≈34..55 & 186..207, split at
  x≈339..346, gradient bright-at-right) are **covered at runtime** by the caption-band
  widgets below (frame bands are bright-at-left / mirrored) — do not draw the baked ones.
- Bottom strip client y 383..415 is NOT in the art — painted dark; the two footer
  buttons sit on it (paint fn draws rect client (2,383) 449×30).

## Widgets (client coords; screen = client + (93,32))

| widget | client pos | size | art / colour |
|---|---|---|---|
| Title "SELECT LEVEL OF THE GAME" | on title strip y 0..24 | — | ProMan10 white, centered |
| TRAINER band caption | (2,32) | ~198×21 | silver grad bright→dark L→R, text black |
| MANAGER band caption | (207,32) | ~244×21 | mirrored grad (bright at right) |
| ACCOUNTANT band caption | (2,184) | ~198×21 | as TRAINER |
| TOTAL band caption | (207,184) | ~244×21 | as MANAGER |
| Entrenador art (id 100) | (30,55) | 120×105 | `NIVELES\Entrenador0/1.bmp` |
| Manager art (id 101) | (279,56) | 149×104 | `NIVELES\Manager0/1.bmp` |
| Presidente art (id 102) | (28,209) | 132×124 | `PREMIER\ICONOS\NIVELES\Presidente0/1.bmp` |
| Total art (id 103) | (272,206) | 153×128 | `PREMIER\ICONOS\NIVELES\total0/1.bmp` |
| "Players age ?" checkbox (id 200) | (14,364) | 14×14 | `NIVELES\ok.bmp` = the tick, style 0x10800 |
| "Players age ?" caption | (34,364) | — | ProMan8, white |
| LOAD GAME button (id 916) | (6,385) | 132×25 | icon `recursos\iconos\carga.bmp` 24×18; text (255,223,0) green-gold |
| CANCEL button (id 902) | (143,385) | 103×25 | text (255,31,0) red |

Band y-rows measured off frame 003 (abs y 64..85 → client 32..53; band2 abs 216..237 →
client 184..205). Band x-split measured off frame 003: TRAINER ends ≈ client 199,
MANAGER starts ≈ client 207 (equal-ish halves; the art's 339-split is NOT visible).

- `*0.bmp` = normal, `*1.bmp` = selected/hover state (pairs blitted with state flag
  0/1 at `0x54a78c..0x54a95a`). All four panel BMPs: junk embedded palette →
  **force MENU.PAL**.
- Captions per level (strings verbatim in .rdata, drawn Micro8):
  - TRAINER: `- Automatic finances` + `- Automatic contract renewal` (two lines)
  - MANAGER: `- Automatic contract renewal` (one line)
  - ACCOUNTANT: `- Automatic tactics and squad`
  - TOTAL: `- Total control`
  (bullet rows sit just under each art; exact y tuned in render-verify vs frame 003)
- Related strings: `- Players aged` / `- Players not aged` and
  `... and "Players age" are not compatible.` (checkbox info/warning texts).

## LOAD GAME modal (frames 005/006)

Red-title "LOAD GAME" card over the dialog: GAME | PLAYER two-column header, 8 save
rows (dark blue), preview strip bottom-left, LOAD + CANCEL buttons right. Its widget
fn was not pinned in code (the 0x5618xx cluster with "Load Game"@(175,440) is a
different, full-screen picker — seleccion-style bottom row). Build the modal off the
frames; measure rects from 005.

## Zoom-in animation

The dialog OPENS with a zoom animation (frame 002 = dialog at ~0.8 scale anchored
~(130,94)). A short scale-in tween (0.8→1.0, <200ms) is faithful.

## Export (into the app)

`tools/re/export_icons.py` EXTRAS or ad-hoc: NIVELES fondo/Entrenador0/1/Manager0/1 +
PREMIER Presidente0/1 total0/1 + ok + carga → `app/art/screens/nivel_*.png` +
`app/art/icons/carga.png` (force MENU.PAL; PKF folder ids: NIVELES=18,
PREMIER-NIVELES=34, root ICONOS carga fid=2 — duplicate names across folders, so
select by folder id, not name).

## Pixel-parity pass (2026-07-03)

The dialog ships as the REAL frame-003 crop (`nivel/chrome.png`, 453x415 at the
reversed rect (93,32)) and the LOAD modal as frame 005's card
(`nivel/load_modal.png`, bbox via diff(005,003) = (140,102) 360x276, all 8 rows
empty = resting). Parity: **both pixel-exact** (dialog-rect ROI; the backdrop is
TitleScreen's own story). Frame truth adopted: LOAD GAME is solid and opens the
(empty) modal even with NO save (the walkthrough had none); bands, bullets,
buttons and checkbox are baked — only the *1.bmp pressed art, the ok.bmp tick,
press tints and the modal row-1 text draw dynamically.
