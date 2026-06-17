# GROUND (ESTADIO) screen — RE findings + rebuild

Status: **BUILT** (`app/scenes/StadiumScreen.gd`, `tools/re/preview_stadium.py`,
`app/tests/test_stadium_screen.gd`). The previous note deferred this as "capacity-driven
isometric geometry that must be reversed first" — **that premise was wrong**. There is no
runtime isometric stand builder: the stadium is one of **12 pre-rendered scenes**, picked
by a single capacity→tier division. Everything is reversible the normal way.

## The real mechanism
The drawn stadium is `ESTADIO<tier>.BMP` (RECURSOS.PKF), tier `0..11` — 12 full scenes,
each **320×240, 8bpp, no embedded palette** (BM core header, `bfOffBits=26`). They are the
half-res backdrop, blitted across the reversed client rect `CRect(0,0,640,480)` (set in the
window base `FUN_004fa840`) at 2×. tier 0 = open pitch, tier 11 = covered mega-stadium.

**Palette:** MANAGER.PAL (RIFF, in DAT.PKF). The scenes omit their palette, so PIL
synthesises a junk one — render with `export_art.py one RECURSOS.PKF "ESTADIO<n>.BMP" out.png
--pal MANAGER.PAL --force-pal` (the `--force-pal` is required; without it you get colour
noise). MENU/DBASE/INFOSURF are byte-identical for these indices; the SIMUL*.PAL are wrong
(red match-sim palette).

**Tier formula** (reversed from the OnDraw `FUN_0051a6e0` @0x51a728, magic-division
`(total*11) * 0x810e35c1 >> 48`, clamped):
```
tier = clamp( capacity * 11 / 130000 , 0 , 11 )      # 130000/11 ≈ 11818 per tier
```
where `capacity = stadium.field4 + stadium.field8` (seated + standing totals). We feed the
SAME capacity the finance screen uses (`FinanceModel.summary`), so tier and finance agree.

## Module map (MANAGER.EXE)
- `FUN_0051a3e0` ctor (`operator_new(0x3a94)`); builds the picture surface at `+0x193c`.
- `FUN_004fa840` window base — `CRect(0,0,0x280,0x1e0)` = 640×480, takes bg id `0x3a3`.
- **`FUN_0051a6e0` = OnDraw** (the main overview). Loads `estadio<tier>.bmp` into the
  surface (`FUN_005c9f60`, asset prefix `recursos\iconos\estadio\estadio` @0x65b234 +
  `%d` + `.bmp`), then draws the title, info panel and 2×2 button grid.
- `FUN_0051bd80` = the **WORKS / construction sub-view** (facility counters SEATS / CAR PARK
  / FACILITIES / SERVICES at x6–140 + `gradas`/`parking`/`equipam`/`extras` + `Enobras`
  under-construction overlays). **WORKS is now a live spending lever (T2 #5):** the button
  emits `works_pressed`; `Main._show_stadium_works()` offers expansion options (+2k/+5k/+10k
  capacity, £cost, build weeks), `Career.start_works()` pays up front, `Career._tick_works()`
  advances it each played week, and on completion `stadium_capacity` rises and
  `_recompute_weekly_net()` feeds the bigger gate into the books (the stadium TIER picture
  also steps up, since it reads the same capacity). The original's exact facility-counter
  sub-layout (4 separate gradas/parking/equipam/extras counters) is NOT reproduced — we
  model one combined capacity lever; the in-progress state shows as a gold banner on the
  overview. IMPROVE / MATCH DAY stay inert.
Helper conventions (proven family): `FUN_00436fb0(x,y)` point (x = last push), first point
made = SIZE, second = POS; `FUN_00436fd0(pos,size)` = Rect(pos, pos+size); `FUN_00437020`
text colour; `FUN_005c06d0(...,0x32,...)` icon blit.

## Reversed overlay rects (exact, from FUN_0051a6e0) — pos(left,top) size(w,h)
- **TITLE "GROUND"** (string @0x65b19c) pos(150,16) size(297,27), ProMan14, in the BARRA.
- **Info panel** pos(299,73) size(320,73) → (299,73,619,146), ProMan10 (ground name +
  capacity readout).
- **2×2 action grid**, each a button widget + its icon (`FUN_005c06d0` state 0x32),
  label colour `(0xa0,0xa0,0xc8)` = (160,160,200):
  - IMPROVE  (@0x65b1f8) pos(298,407) size(152,25) + `remodela.bmp`
  - WORKS    (@0x65b1c8) pos(484,407) size(132,25) + `obras.bmp`
  - MATCH DAY(@0x65b228) pos(298,442) size(152,25) + `diapartido.bmp`
  - RETURN   (@0x6549e4) pos(488,442) size(124,25)
  (The earlier note's single-column WORKS/IMPROVE/MATCH DAY at x298 y372/407/442 was a
  mis-read — the real layout is this 2-column, 2-row grid.)

## What is derived, not reversed
GameDB stores only **total** capacity, so the seated/standing/parking split shown in the
info panel is display-derived (`~62%` seated, rest terraces, parking ≈ capacity/27). The
**tier** depends only on total capacity (the exact reversed formula), so the picture is
always faithful; only the sub-split labels are estimates (flagged in `Main._show_stadium_screen`).

## Assets produced
`app/art/screens/stadium/estadio0..11.png` (12 tiers, MANAGER.PAL) +
`obras.png`/`remodela.png`/`diapartido.png` (button icons, idx0 transparent). The icons are
BM-with-no-palette; the export_art `--transparent` BM path drops them, so they were extracted
with the proven `riff_palette` + idx0→alpha directly (see git history / preview_stadium).

## Wiring
`MENUPRINCIPAL` `stadium` action → `Main._show_stadium_screen()` (was a toast), tap-to-dismiss
overlay, native 640×480 self-scaling + marble bezel like the other screens.
