# STADIUM (ESTADIO) screen — RE findings + why it is DEFERRED

Status: **partially reversed, NOT rebuilt.** The buttons/labels are constant-coord,
but the stadium stand art is **capacity-driven geometry** computed at runtime, not
constant pixel coordinates. Rebuilding it faithfully (the project bar: exact coords
reversed, never guessed) needs the stand-layout maths reversed first — a separate,
larger job than the list/table/board screens. Documented here so the work isn't lost.

## Module map (reversed from MANAGER.EXE)
Top of the ESTADIO module: `FUN_0051a3e0` (dispatched from `FUN_0x4f9940`) →
`FUN_0051a5f0` (the screen object's construct/draw driver). The asset blits cluster
in `0x51a800…0x51e200`. Helper conventions are the proven family
(`FUN_00436fb0(x,y)` point, `FUN_00436fd0(pos,size)` rect, `FUN_005c06d0(this,bmp,
…,state,…)` PCF5 sprite, `FUN_00437020(r,g,b)` text colour).

Assets live in `recursos\iconos\estadio\*.bmp` (RECURSOS.PKF): `gradas` (stand),
`parking`, `entrada` (entrance), `balon` (pitch), `extras`, `equipam` (equipment),
`obras` (WORKS), `remodela` (IMPROVE), `diapartido` (MATCH DAY), `flechar`/`flechal`
(arrows), `parkingtotal`, `Enobras` (under-construction overlay). Facility vocabulary
(constant `.data` strings): CLUB SHOPS, SICKROOM, ACCESS, CHANG. ROOMS, HEATING,
TOILETS, CAFES, SCORE BOARD, UNDER-SOIL HEATING, FLOODLIGHTS, plus capacity readouts
SEATS / CAR PARK / CAPACITY / standing / spaces and the four corners SOUTH-WEST /
NORTH-WEST / SOUTH-EAST / NORTH-EAST.

## What IS constant-coord (reversible the normal way)
The three action buttons on the right, each `label(Point size, Point pos)` + a
`diapartido/remodela/obras` icon (`FUN_005c06d0` state 0x32), from `FUN_0051a8b0+`:
- **MATCH DAY** label pos(298,442) size(152,25), font ProMan8, colour ~(160,160,?)
- **IMPROVE**  label pos(298,407) size(152,25), colour (160,160,200)
- **WORKS**    label pos(298,~372) size(132,25), colour (160,160,200)

## What is NOT constant (why it's deferred)
The four stands + parking are drawn in a loop (`FUN_0051bf30+`, `cmp ebp,4`) where
each stand's `FUN_00436fb0` point args are **registers/members**, not immediates:
the stand rectangles are computed from the club's stadium capacity tier and stored
in per-stand widget objects (`[esi+0xbe8]`, `[esi+0x1000]`, …; stand count at
`[esi+0xbcc]`). The `gradas.bmp` is one asset scaled/placed per corner by that maths.
Each stand also draws a live "SEATS"/"CAR PARK" counter at a position relative to its
computed rect. So there is no constant `(x,y,w,h)` to reverse — the isometric stadium
builder (capacity → four stand rects) must be reversed first.

## To rebuild faithfully later (the actual next step)
1. Reverse the stand-rect computation: find the OnSize/layout handler that writes the
   four stand widget rects from capacity (search stores to `[esi+0xbe8/0x1000/0x1418/
   0x1830]`), recover the tier→rect table or formula.
2. The default new-save stadium is a known fixed tier, so the STARTING layout is a
   single concrete instance worth rendering even before the full formula is decoded.
3. Then place gradas/parking/entrada/balon at the recovered rects + the constant
   WORKS/IMPROVE/MATCH DAY buttons above, same pipeline as the other screens.

Until then, MENUPRINCIPAL's `stadium` action keeps its toast (DIRECTIVA's `board`
action was the tractable, fully-constant-coord sibling and was built instead).
