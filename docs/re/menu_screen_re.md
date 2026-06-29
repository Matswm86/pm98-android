# MAIN MENU (MENUPRINCIPAL) screen — reversed layout from MANAGER.EXE

640×480 px, lifted from `FUN_005469c0` (entry found by the `sub esp,0x230` prologue
at `0x5469c0`, immediately before the first menuprincipal asset xref `0x546a7a`).
Decompile: `docs/re/menu/fn_005469c0_FUN_005469c0.c`. Anchored on the
`recursos\iconos\menuprincipal\*.bmp` asset strings (file off 2474184…2476076 →
`.data` VA 0x65dac8…). Immediates read straight from capstone, not the lossy
decompile (the decompiler hides the `push`-arg order).

The in-game management hub: 12 picture icons in two vertical bands of three rows per
side, around a central club panel + a four-button control bar.

Geometry helpers (same family proven on finance/squad/lineup/transfer):
- `FUN_00436fb0(x,y)` → a point. **thiscall**: `push y; push x; lea ecx,out; call`;
  the LAST push is `x`. Verified against every icon (pt#1 `x`/`y` == the extracted
  BMP's w/h, e.g. MARCAOFF is 86×60 and pt#1 = (86,60)).
- Each icon emits TWO `FUN_00436fb0`: pt#1 = **size** (w,h), pt#2 = **pos** (x,y);
  `FUN_00436fd0(pos,size)` → `Rect(x,y,x+w,y+h)`.
- `FUN_00436240` = `CRect::CRect(l,t,r,b)` → the caption (label) rect, `l` = last push.
- `FUN_00437020(r,g,b)` set caption colour (`r` = last push; stores bytes [r,g,b,0]).
- `FUN_005c06d0(this,"...bmp",…)` blits an icon bitmap state.

## Assets (all in RECURSOS.PKF, OS/2-core 8-bpp BMP, NO embedded palette)
Render with the **shared VGA palette** (`DAT.PKF+0x5ca`, R,G,B order), index 0
transparent — NOT MANAGER.PAL/MENU.PAL (those scramble these icons). Each menu item
has `*off` (active), `*on` (hover) and/or `*gris` (disabled) states; we bundle the
`off` (active) state.

| icon  | RECURSOS entry | size  | action  | caption        |
|-------|----------------|-------|---------|----------------|
| MARCA | MARCAOFF.BMP   | 86×60 | results | RESULTS        |
| CLASI | CLASIOFF.BMP   | 87×72 | table   | LEAGUE TABLE   |
| CALEN | CALENOFF.BMP   | 77×66 | fixtures| FIXTURES ✓     |
| ALINE | ALINEOFF.BMP   | 93×61 | lineup  | LINE-UP        |
| TACTI | TACTIOFF.BMP   | 93×63 | tactics | TACTICS        |
| RIVAL | RIVALOFF.BMP   | 85×60 | opponent| OPPONENT ✓     |
| FICHA | FICHAOFF.BMP   | 85×76 | buy     | SIGN PLAYER    |
| VENDE | VENDEOFF.BMP   |101×78 | sell    | SELL PLAYER    |
| EMPLE | EMPLEOFF.BMP   | 72×62 | staff   | STAFF ✓        |
| CAJA  | CAJAOFF.BMP    | 78×80 | finance | FINANCE ✓      |
| DECIS | DECISOFF.BMP   | 86×61 | board   | BOARD ROOM ✓   |
| ESTAD | ESTADOFF.BMP   | 95×61 | stadium | STADIUM        |

`✓` = caption is the EXE's own inline `.data` string sitting right after that icon's
`off.bmp` path (FIXTURES/OPPONENT/STAFF/FINANCE/BOARD ROOM). The other six carry no
inline string (their widget text is resource-ID driven, ID table not reversed); they
use the game's own English vocabulary present elsewhere in MANAGER.EXE (LEAGUE TABLES,
LINE-UP, TACTICS, SIGN PLAYER, STADIUM) + RESULTS for the marcador/scoreboard icon.

## Reversed coordinates (pos = top-left, size = w×h)
- Picture rects (the hit areas, all non-overlapping):
  MARCA(7,71) CLASI(206,93) CALEN(10,147) ALINE(535,70) TACTI(345,101) RIVAL(536,151)
  FICHA(7,327) VENDE(184,353) EMPLE(6,403) CAJA(559,328) DECIS(361,370) ESTAD(543,415).
  (FICHA's pos.x is a register; its left-column siblings are x=6/7/10 → 7.)
- Caption rects sit beside each icon (left column: label right of icon; right column:
  label left of icon) and line up with the grey label slots of `trozo_fondo`.
- Caption colours by group: top-left RESULTS/LEAGUE/FIXTURES = (200,230,60) lime;
  top-right LINE-UP/TACTICS/OPPONENT = (127,191,255) cornflower; bottom-left
  SIGN/SELL/STAFF = (255,191,170) peach; bottom-right FINANCE/BOARD/STADIUM =
  (255,223,85) gold.
- Control bar (y=255): EXIT(6,255,79×27) SAVE GAME(92,255,114×27) NEWS(437,255,95×27)
  CONTINUE(540,255,95×27). Strings confirmed inline ("EXIT" 0x65ccb0, "SAVE GAME"
  0x65dc08, "NEWS" 0x65dba8, "CONTINUE" 0x652f54). The centre gap (x214-426) holds
  the live club panel.
- Background: `trozo_fondo.bmp` (640×158) blitted per band at y=63 and y=321; the menu
  is left-right symmetric, so a horizontally-mirrored copy supplies the right-column
  grey slots (trozo's left slot at x63-207 mirrors to x433-577 = the reversed right
  caption x-range). Friendly-match mode swaps in `fondo_amistoso.bmp` (not used here).
  **Bake gotcha (fixed 2026-06-25):** the mirror is opaque across most of its width, so
  it must be CLIPPED to the right half (x≥320) before compositing — pasting the whole
  mirror over trozo overwrites trozo's own left-column slots (mirror's left half ==
  trozo's right half = marble), leaving the six left captions floating on bare marble.
  Verify: every caption centre must sample grey (80,80,80), not marble blue.

## Build mapping (→ `app/scenes/MenuScreen.gd`) — 2026-06-29 rebuild
The menu hub's full look is engine-COMPOSITED (slanted colour caption bars per group +
the INFORMATION / MANAGER / TRANSFER MARKET / FINANCES section labels + the central club
CIRCLE), none of which exists as a single extractable PKF asset — only the composited
output does. The earlier `preview_menu.py --bake` (trozo bands + mirror) was an
approximation: it left grey trozo slots showing as empty centre BLOBS and never drew the
colour bars / section labels / circle, so it did not match the real screen (compare
`data/pm98-refs/real-gallery/ma_6.png`).
- **Static chrome = the real frame.** `app/art/screens/menu_bg.png` is the real game's
  640×480 MENUPRINCIPAL (ma_6) with ONLY the club-specific data cleared (top header band
  + the two circle crests), produced + reproducible via
  `tools/re/build_menu_bg_from_ref.py` (ref kept at `tools/re/refs/menuprincipal_ma_6.png`).
  This keeps the colour bars / 12 icons / section labels / control bar / circle frame +
  slot boxes / marble + BARRA as REAL pixels.
- `MenuScreen.gd` blits menu_bg, then draws the DYNAMIC layer: the shared
  `PMChrome.draw_header` plaque row over the cleared top band, and the central circle's
  live slots (league position "PL n" / manager / managed club + crest / next opponent +
  crest / opponent-manager-or-venue / CPU) over the real circle frame. INTERACTIVE:
  `_hit()` maps a tap to an action via the reversed icon picture rects (`ICON_HITS`), the
  measured caption-bar rects (`BAR_HITS`, added so the visible label is also a target) and
  the control rects (`CTRL_HITS`); emits `action_selected`. Native 640×480, scales (NEAREST).
- Captions are the real game's: TRANSFERS / PLAYERS / GROUND map to the `buy` / `sell` /
  `stadium` actions respectively (the icon entry names FICHA/VENDE/ESTAD are unchanged).
- `Main.gd` mounts it as a full-screen overlay from the career hub and routes actions:
  table→league screen, lineup→line-up screen, finance→finances, buy→transfer market,
  tactics/sell/results→text views, continue→advance week,
  save/news/staff/stadium/board/opponent→toast, exit→dismiss.
- `preview_menu.py` is RETAINED (it documents the reversed per-icon/caption rects) but is
  no longer the source of menu_bg.png.
