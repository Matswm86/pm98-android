# GROUND (ESTADIO) screen — RE findings + frame-true rebuild

Status: **REBUILT frame-true** (2026-07-13; **IMPROVEMENTS view added in-screen 2026-07-17**,
charter #8; **cost function reversed 2026-07-26** — every club priced from `FUN_0057ddd0`,
24/24 witnesses exact, see §"The cost function"). Owns `app/scenes/StadiumScreen.gd`,
`app/scripts/GroundCost.gd`, `tools/re/extract_ground_prices.py`,
`app/data/ground_cost_table.json`, `app/tests/test_ground_cost.gd`,
`tools/re/build_stadium_chrome_from_frames.py`,
`tools/re/build_improvements_chrome_from_frames.py`, `app/art/screens/stadium/chrome.png`,
`app/art/screens/stadium/improvements.png`, `app/tests/test_stadium_screen.gd`,
`app/tests/test_stadium_works.gd`, `app/tests/shot_improvements_verify.gd`.

## Why the previous build was rejected (de-invention record)
The prior StadiumScreen ("two-column recompose (ma_15)", commit `e03da33`) was **invented**.
It drew a white **MATCH DAY card with a TICKET PRICE stepper** and a **SPONSOR BOARDS price
slider** on the left, and a **CAPACITY / CAR PARK / PITCH = "NORMAL"** readout on the right.
**None of that is on the GROUND overview.** The reference "ma_15" **does not exist** in the
repo (no such file) — the commit's "verified vs ma_15" claim was unfounded, and the audit's
`| stadium … | TRUE |` row was stale. Ticket price + sponsor boards belong to the *separate*
**GROUND MATCH DAY** sub-screen (run-3 capture), not here. `SPEC_BINDING.md §6` already flagged
the earlier "SEATS/STAND/TIER" readouts as removed-invented; this pass removes the second wave.

## The binding frames (source of truth)
`screenshots/original-walkthrough-2026-07-02/172_154930.png` — the real MANAGER.EXE GROUND
overview, default **"WORK IN PROGRESS"** state (Man Utd / Old Trafford). `173_154935` — the
same overview after pressing **IMPROVE**: the LEFT panel becomes the **IMPROVEMENTS** picker
(category grid SEATS/CAR PARK/FACILITIES/SERVICES + SEATS "INCREASE THE CAPACITY" offer
cards), the RIGHT panel + green header + 2×2 action grid unchanged. `175_154941` shows a
ticked card (red X in the box). Neighbour `170_154926` = hub (GROUND button under FINANCES).
**IMPROVE is an IN-SCREEN toggle of the same window, not a separate overlay** — witnessed by
the shared right panel + action grid across 172↔173. The Bolton W parity capture
(`screenshots/parity-run-2026-07-16/orig/21_ground_improve.png`) is the second witnessed club.

## Real layout (frame 172, all rects pixel-measured off the frame grid)
Two panels on the shared BARRA header + marble background (`PMChrome.draw_header` /
`PMChrome.draw_bg`, same as every career screen — NOT baked here).

**LEFT — "WORK IN PROGRESS" panel** (`x12..282, y68..466`), road-works triangle title, four
sections each with a black title bar (coloured section icon) + **TO BE PAID** / **WEEK**
column heads + framed value rows, then **TOTAL IMPROVEMENTS … £0** on the grey footer:
- **SEATS** (blue), **CAR PARK** (blue, "P" icon) — one value row each
- **FACILITIES** (green): FLOODLIGHTS / HEATING / CHANG. ROOMS / SCORE BOARD / ACCESS
- **SERVICES** (orange): SICKROOM / CLUB SHOPS / CAFES / TOILETS
These section + facility labels are the game's own fixed labels (frame-baked, not invented).

**RIGHT — ground panel** (`x296..620`):
- green header `y71..91` — the **ground name** (white, centred)
- 3-row table (label cell light `200,220,240` | value cell gradient `100/80/60,…`):
  **CAPACITY** `y94..108` → "55,300 seats", **CAR PARK** `y111..125` → "2,000 spaces",
  **PITCH** `y128..142` → "GOOD"
- **ESTADIO<tier> picture** `Rect2(299,148,320,240)` — the 320×240 tile drawn 1:1.

**Bottom 2×2 action grid** (reversed rects from `FUN_0051a6e0`, baked icons/labels):
IMPROVE `(298,407,152,25)` · WORKS `(484,407,132,25)` · MATCH DAY `(298,442,152,25)`
(disabled/washed in the frame) · RETURN `(488,442,124,25)`.

## Tier picture
`tier = clamp((capacity + headroom) * 11 / 130000, 0, 11)` (reversed `FUN_0051a6e0`
@0x51a728, magic division). 12 tiles `estadio0..11.png` (320×240, MANAGER.PAL). The
frame's Old-Trafford render = tier 4 (real capacity 55,300, headroom 0). The tile fills
the picture box exactly and covers the baked tile so no tier bleed is possible.

**The tier input is a TWO-FIELD SUM — closed 2026-07-27 (new disassembly).**
`FUN_0051a6e0` @0x51a728-0x51a74c reads the ground object and computes
`([ground+4] + [ground+8]) * 11 / 130000` (`mov eax,[ecx+8]; mov ebx,[ecx+4];
add eax,ebx` before the 0x810E35C1 magic division — emulated exact = `n*11//130000`
for all n ≤ 141,818). The ctor `FUN_0057d780` maps `ground+4 = club+0x18` (the
capacity the port ships) and `ground+8 = club+0x1c` = **EQUIPOS `param_1[7]`, the
expansion HEADROOM the extractor used to discard**. The loader (`fn_00579c70`
L103-111) quantises it to the nearest multiple of 4000 (remainder > 1999 up, a
non-zero value under 4000 up, zero stays zero; 4000 = the SEATS build unit
`FUN_0057e3f0` = `(card+1)*4000`). The weekly tick `FUN_0057da50` @0x57db44-0x57db84
decrements headroom on completion ONLY for category-2 seats (the unused second
table); the English category-1 cards grow the sum by the seats built. 91 of 476
clubs ship non-zero headroom (~30 English — Port Vale, Cardiff, Barnsley, Burnley,
Luton …); every render-witnessed club ships 0, which is why this never showed in a
parity diff. Port: `capacityHeadroom` in game_db (extractor applies the loader
quantisation verbatim), `Career.stadium_headroom` (static), tier input =
capacity + headroom (`StadiumScreen._load_scene`).

Both neighbouring findings are now CLOSED — 2026-07-28, from the binary.

**1. The SEATS ceiling is 150,000, and the addend is the capacity SUM.** The 07-27
note ("the addend register wants one more trace") is discharged. The card builder is
`FUN_0051c2e0` (the GROUND IMPROVEMENTS screen), and its frame is pinned by three
reads that agree at one site:

```
0051c319  mov [esp+0x14], ecx       ; B+0x14 = the ground object   (read back @0x51c8a9 as [ebx+0x33])
0051c32b  mov [esp+0x30], edx       ; B+0x2c = ground+0x34         (read back @0x51c8c8)
0051c336  mov eax,[ecx+8]           ; headroom
0051c339  mov ecx,[ecx+4]           ; capacity
0051c33c  add ecx, eax
0051c340  mov [esp+0x24], ecx       ; B+0x20 = capacity + headroom
...
0051c8d0  push edi / push 1 / call FUN_0057e3f0   ; seats = (card+1)*4000  (0x57e3f0: +1, x125, <<5)
0051c8df  add eax, [esp+0x28]       ; = B+0x20, the sum above
0051c8e1  cmp eax, 0x249f0          ; 150,000
0051c8e6  jb keep                   ; else FUN_005bf8c0 -> the card is DISABLED
```

So the ceiling applies to **capacity + headroom** (the same sum the tier picture
divides), it is tested **per card at build time** — the card greys out rather than the
capacity clamping — and the comparison is `jb`, so a build landing exactly on 150,000
is already refused. 130,000 was only ever the tier-11 picture threshold. Port:
`Career.MAX_STADIUM = 150000` + the `>=` guard in `begin_work`,
`StadiumScreen.BUILD_CEILING` split out from `MAX_CAPACITY` (still 130,000, still the
tier divisor), pinned by `test_stadium_works`.

**2. `remodela.bmp` is the IMPROVE BUTTON's icon — the "per-section marker" reading was
WRONG.** The `.data` block at 0x65b1a4..0x65b228 is three (path, label) pairs, and
`FUN_0051a6e0` builds one button from each, in this shape:
`push id / push 0 / push <label> / push h / push w / ... / push y / push x / ... /
push <bmp> / call FUN_005c06d0`:

| id | label VA | bmp VA | w x h | x, y | = the reversed rect |
|---|---|---|---|---|---|
| 0x66 | 0x65b228 `MATCH DAY` | 0x65b200 `diapartido.bmp` | 0x98 x 0x19 | 0x12a, 0x1ba | (298,442,152,25) |
| 0x64 | 0x65b1f8 `IMPROVE` | **0x65b1d0 `remodela.bmp`** | 0x98 x 0x19 | 0x12a, 0x197 | (298,407,152,25) |
| 0x65 | 0x65b1c8 `WORKS` | 0x65b1a4 `obras.bmp` | 0x84 x 0x19 | 0x1e4, 0x197 | (484,407,132,25) |

which reproduces the action grid measured off the frame, exactly. `remodela.bmp` has
**one** code reference in the whole binary (0x51a989, that push); `obras.bmp` has three
(0x51aa0c here, plus 0x51dd3a / 0x51e1da — the in-progress markers the port already
draws and render-diffed). So there is nothing left to draw: the IMPROVE button's icon is
inside the baked action grid, and `remodela.png` being "loaded by nothing" is correct —
it is baked, not blitted. The four works flags copied to screen fields
`+0x192c..+0x1938` (@0x51a7cc-0x51a80a) feed the screen's own per-category state, not a
marker blit.

**The "small internal crop/palette offset … not a placement error" note was WRONG — FIXED
2026-07-24 (s55).** It was a 256-column wrap, and it made the whole picture panel render at
**4.1% pixel-exact**. Every tile carried a hard vertical seam at column 255→256 — the maximum
per-column |RGB gap| in all 12 at z = 13.1…15.3σ, where the real panel's worst column is only
z = 3.4 and not there. The same seam is in the source `RECURSOS.PKF ESTADIO<N>.BMP`, so it is a
PCF5 DIB decode artefact, not our crop. Solved against the owner's real 1:1 GROUND capture
(`screenshots/user-captures-2026-07-23-ground-squad-transfer/01_07-52-40.png`, client area at
(641,196)): 12 template patches spread over the panel all located at **zero** differing pixels
and agree on one mapping,

```
panel(bx, by)  <-  tile[(by + (2 if bx < 64 else 1)) % 240][(bx + 256) % 320]
```

— columns rotated by 256 with the row offset stepping by one across the wrap, i.e. a flat-buffer
misregistration, not a clean column roll (a plain roll fixes columns 64…319 and leaves 0…63 at
80% differing). **And the tile is drawn at y = 146, not the 148 read off frame 172**, so
`SCENE_BOX` is now `Rect2(299, 146, 320, 240)`. Result on the live app render: picture panel
**98.15% pixel-exact / 0.83% >8**, whole GROUND screen 54.5% → 78.0% exact.

Tool: `tools/re/fix_estadio_wrap.py` (`--apply` rewrites the tiles, `--verify` re-measures).
**Scope caveat (narrowed 2026-07-26 evening):** tier 4 was the only tile with a real render to
check against; **tier 3 is now verified too** — Aston Villa's own GROUND capture
(`screenshots/wine-captures-2026-07-23-renew-ground-villa/31_ground.png`, 39,339 seats → tier 3)
diffs against `estadio3.png` at the (299,146) box at **1.64% differing (98.36% exact)**, the
same fine-dither residual class as the tier-4 witness (0.83%), and 81% differing at the retired
y=148 anchor — confirming both the tile and the s55 y-anchor on a second tier. The other 10
tiles have no real render to diff against, but they are no longer *unchecked*: **NARROWED
2026-07-28 (s76).** `fix_estadio_wrap.py --verify` measures the strongest vertical seam in each
tile as a z-score, and across **all twelve** shipped tiles it reads **z = 3.0..3.9** — no hard
seam — while re-applying the wrap to any of them puts a seam back at x=63 at **z = 13.1..14.8**.
So the **+256 column wrap is validated on 12 of 12 tiles as a property of the data itself**,
independent of any render.

**✅ And so is the ROW OFFSET, since 2026-07-28 (s78) — 12 of 12, also from the data alone.**
The claim this section used to carry, that "a one- or two-row error would not move the seam
statistic", is true of the ±256 seam statistic and false of the right one. The row offset is a
RELATIVE shift between two blocks of the SAME picture that meet at `x = 63|64`, so a wrong
offset leaves a one-row vertical discontinuity exactly there, and the picture's own horizontal
continuity measures it with no render involved.
`tools/re/verify_estadio_rowoffset.py` scores that boundary column pair under five candidate
shifts of the left block (−2…+2) on every shipped tile: **the shipped offset is the minimum on
all twelve.** The margins are small (1.5–4.5 mean-|Δ| units) because the two sides of the join
are different stand geometry and it is never smooth — the test does not claim a seamless
boundary, it says which shift is LEAST bad, and it is the shipped one twelve times out of
twelve with five candidates each. So the ten tiles without a render witness are no longer
unconfirmed on the row offset either. The residual is fine
dither noise; whether the live render dithers at blit time is not reversed. The capture's frames
01-12 have pixel-identical panels (0.0% between them), so the picture is static — no animation
is being read as an offset.

## What is frame-true vs honest gap
- **Frame-true (baked or reversed):** the entire body chrome — both panels, all section/
  facility/column/button labels + icons, TOTAL IMPROVEMENTS, the green header, the table
  frame, the 2×2 grid, the tier picture box, all rects.
- **From real Career:** ground name = GameDB `club.stadium`; CAPACITY = `Career.stadium_capacity`;
  tier = from that capacity. (STALE NOTE CORRECTED 2026-07-26: **476/476** clubs carry a real
  `capacity` in `game_db.json` since the EQUIPOS byte-exact decode — the old "15/476 …
  FinanceModel._CAP fallback" line described the pre-decode DB; `_CAP` is dead fallback now.)
- **HONEST GAPS (blank, never fabricated):** **CAR PARK spaces** and **PITCH quality** are in
  no `game_db.json` field. The prior build's parking = `capacity/27` and pitch = "NORMAL" were
  fabrications; both value cells are now left blank. **TOTAL IMPROVEMENTS** money = £0 (an
  in-progress expansion's £cost is not threaded to this screen — see WIRING).

## The chrome bake
`tools/re/build_stadium_chrome_from_frames.py` cuts the two panels + four buttons opaque from
frame 172 into `app/art/screens/stadium/chrome.png` (RGBA 640×480, transparent elsewhere) and
BLANKS the dynamic cells (ground name, 3 value cells, £-total) with their frame-sampled flat
backgrounds. StadiumScreen draws: `draw_bg` → `draw_header` → chrome → estadio<tier> →
ground-name / capacity / £-total text → press tints. Parity vs frame 172 outside the tile:
mean abs diff **3.96** (chrome is the frame's own pixels; residual = text-glyph rendering).

## IMPROVEMENTS view (frame 173) — IN-SCREEN, rebuilt frame-true (2026-07-17)
Pressing **IMPROVE** toggles `StadiumScreen._view` to `"improve"`; **WORKS** toggles back.
The IMPROVE view draws `art/screens/stadium/improvements.png` (baked from frame 173 by
`tools/re/build_improvements_chrome_from_frames.py`) over the WORK IN PROGRESS left panel;
the shared right panel + header + 2×2 grid stay put. This **replaces the prior invented blue
"GROUND WORKS" text browse** (`Main._show_stadium_works` + the `STADIUM_WORKS` table of
fabricated +2,000/+5,000/+10,000-seat offers at invented £/weeks — all removed).

The three SEATS offer cards carry:
- **Seat increment +4,000 / +8,000 / +12,000** and **build time 20 / 35 / 50 weeks** — these
  are witnessed **IDENTICAL** for Man Utd (frame 173) and Bolton W (parity/21), so they are
  game constants and stay BAKED (`StadiumScreen.OFFER_SEATS` / `OFFER_WEEKS`).
- **GBP price** — club-specific and **un-RE'd** for the general case (the price-compute fn is
  NOT in the extracted disassembly; `FUN_0051bd80` is the draw fn only). Only two clubs are
  witnessed exactly: Man Utd `£4,250,000 / £7,437,500 / £10,624,999`, Bolton W
  `£2,750,000 / £4,812,499 / £6,875,000` (`StadiumScreen.OFFER_PRICES`). The three £ cells are
  BLANKED in the bake and redrawn from that lookup. **SUPERSEDED 2026-07-26:** the cost
  function IS reversed now (§"The cost function" below) and every club is priced from the
  binary, so the honest gap is closed; `OFFER_PRICES` / `TIER_PRICES` survive only as the
  fallback for callers that pass no stature band.

Ticking a witnessed card emits `improve_selected(added, cost, weeks)`; `Main._on_stadium_improve`
runs `Career.start_works` (authoritative cash + ceiling gates), saves, and re-mounts the screen
(now showing the WORK IN PROGRESS state). Tests: `test_stadium_screen`
(view toggle, card hit-test, witnessed vs honest-gap price), `test_stadium_works`, `test_wiring_pass`.

## CAR PARK / FACILITIES / SERVICES tabs — IMPLEMENTED (2026-07-23, owner capture)
The owner captured the three previously-un-witnessed tabs (native-640x480 frames at desktop
offset 641,196, scale 1.0; screenshots/user-captures-2026-07-23-ground-squad-transfer/).
Frames 02/09 = CAR PARK, 03/10 = FACILITIES, 04/12 = SERVICES(title "EXTRAS"), 05/07 = the
concurrent WORK IN PROGRESS ledger. Tab hit rects: SEATS(18,113) CAR PARK(148,113)
FACILITIES(18,138) SERVICES(148,138), each 124x18; active tab drawn with a red outline.

- **CAR PARK** — 4 quadrant cells NE/NW/SE/SW, each level 1..4 (base 1 = 2,000 spaces, +500
  /level). Baked chrome `carpark.png` (build_carpark_chrome_from_frames.py) keeps the quadrant
  art + Level/1-2-3-4 labels + PER LEVEL panel; the 16 level boxes + works triangle are blanked
  and redrawn from `Career.car_park_levels` (owned=blue, building=red + obras triangle). PER
  LEVEL = 500 spaces / £2,975,000 / 7 weeks; spaces+weeks are treated as constants, the £ is
  WITNESSED ONLY for Man Utd (the cost fn is un-RE'd; SEATS proved these prices ARE club-tiered,
  so any other club = HONEST GAP: the price cell is blanked + taps inert).
- **FACILITIES** — 5 item bars over a detail panel (icon+name header, PRICE/WEEKS, grade rows).
- **SERVICES (EXTRAS)** — 4 item bars over the same detail panel.

## FACILITIES / SERVICES — ALL ITEMS NOW LIVE with real data (2026-07-23, wine capture)
Every item was mined by DRIVING the original MANAGER.EXE under wine (TOTAL control, Manchester
Utd. / Old Trafford, 97-98 wk 1: MANAGER LEAGUE → TOTAL → Man Utd → hub → GROUND → IMPROVE →
each tab/item; scratchpad `wine/28..35`). Each item's grade ladder, starting grade, and next
upgrade PRICE/WEEKS were read off the real detail panel. Two cross-checks reproduced the prior
witnesses exactly (CHANGING ROOMS MEDIUM→COMPLETE £225k/3wk, MEDICAL COMPLETE→I.C.U. £150k/2wk),
and SEATS (Champion 4.25M/7.4375M/10.625M) + CAR PARK (£2,975,000/level) also reproduced.
Table stored in **`app/data/ground_prices.json`** (keyed by club); `Main._ground_items` feeds it
to `StadiumScreen.set_ground_items`. Man Utd captured (grades / **current** / next £/wk):
- FLOODLIGHTS: NONE / 500.000 K.W. / **1.000.000 K.W.** / 1.500.000 K.W. → £500,000 / 4wk
- UNDER-SOIL HEATING: **NO** / YES → £1,200,000 / 8wk
- CHANGING ROOMS: BASIC / **MEDIUM** / COMPLETE → £225,000 / 3wk
- SCORE BOARD: MANUAL / ELECTRONIC / **VIDEO-WALL** (max, no upgrade)
- ACCESS TO THE STADIUM: BASIC / **MEDIUM** / WIDE → £900,000 / 6wk
- MEDICAL EQUIPMENT: BASIC / **COMPLETE** / I.C.U. → £150,000 / 2wk (ledger "SICKROOM")
- CLUB SHOP: **NONE** / SMALL / MEDIUM / LARGE → £25,000 / 1wk (ledger "CLUB SHOPS")
- CAFES: SMALL / MEDIUM / **LARGE** / VERY LARGE → £500,000 / 20wk
- TOILETS: 10 W.C. / 20 W.C. / **40 W.C.** / 80 W.C. → £50,000 / 1wk

Detail behaviour matched to the original: idle shows PRICE **£0** / 0 weeks; the real upgrade
cost + a red box on the next grade appear when it is **previewed** (tapped once); a second tap
commits (the works triangle then shows only while building — owner frame 10). Item icons cut
from the captures (`svc_<key>.png`, 9 total). Per-item detail panel now has the original's outer
**black border** (measured off frame 10: x15..276 / y281..431, divider y309).
- **WORK IN PROGRESS ledger (frame 07)** — several works run at once. `Career.works` is now a
  LIST {cat,key,label,cost,weeks_left,effect}; `_tick_works` applies each on completion
  (capacity / car_park_levels / ground_grades). The ledger draws each live work in its section
  row (value / TO BE PAID / WEEK + triangle); TOTAL IMPROVEMENTS = `works_total()`. Verified
  in-app: the frame-07 mix (SEATS 8k + CAR PARK 500 + CHANG.ROOMS + SICKROOM) totals £10,787,500.

A ticked quadrant/grade emits `works_requested(cat,key,label,cost,weeks,effect)`;
`Main._on_stadium_works` runs `Career.begin_work` (cash + no-duplicate guards), saves, re-mounts.
Render-diffed app-vs-original (wine idle captures): FACILITIES/SERVICES panels now match the
original's idle (£0) and preview (£cost + red box) states pixel-close; the CAR PARK works
triangle is the clean red/yellow ⚠ cut from frame 09 (`obras.png` re-sourced 33x30 — the old
16x15 was a garbled blob; REMEMBER to `godot --import` after replacing it or the stale .ctex
renders); TOTAL IMPROVEMENTS no longer garbles (the baked "£0" cell is covered before the live
sum draws). Tests: `test_ground_improvements`, `test_stadium_screen`, `test_stadium_works`,
`test_wiring_pass` all PASS; in-app `PM98_GROUNDACT_SHOT`.
**Render fixes shipped 2026-07-23:** garbled TOTAL (cover cell), obras blob (re-sourced ⚠),
missing detail border (added), all items live (ground_prices.json).
**Still un-RE'd (flagged, not fabricated):** the per-club STARTING GRADES — only Man Utd is
captured, so the other 475 clubs fall back to the sparse witness default (CHANGING ROOMS +
MEDICAL) until each is captured OR `club+0x50` (the preset selector) is reversed. The per-club
PRICES are no longer a gap — see §"The cost function". Also open: the exact upgrade COMMIT trigger
(preview-tap is observed; second-tap-to-buy is the app's inferred commit). The GROUND MATCH DAY
sub-screen (frame 06) is already built.

## The cost function — REVERSED 2026-07-26 (`FUN_0057ddd0`), the per-club gap is CLOSED
The "Next RE step: Ghidra the offer-cost function to unlock per-club prices" above is DONE.
Every improvement price in the game comes out of one function:

```
void __cdecl FUN_0057ddd0(int tier, int category, int index, float *price, uint *weeks)
```

`@0x0057ddd0`. Body = one 15-way jump table on `category` (`JMP [ECX*4+0x57e224]`, 1-based)
over per-category 9-way jump tables on `tier`, each arm a single `MOV dword ptr [EAX],<f32>`
optionally followed by `FMUL float ptr [0x00638dc4]` (= **0.5**, SEATS only). Epilogue
`@0x0057e201`:

```
FILD qword [weeks] ; FMUL double [0x00638dc8] (= 1e6) ; FMUL float [price] ; FSTP float
```

and the money **display path divides by 200** — the game-wide convention already reversed for
transfer fees (`transfer_value_re.md` §"Multiplier": the same `FILD/FMUL 1e6` then `/200`,
net ×5000). So

```
GBP = trunc( float32(weeks * 1e6 * P) / 200 )        i.e. weeks * 5000 * P before rounding
```

The `FSTP float` is what produces the original's own off-by-one dirt (£10,624,999 for the
+12,000-seat card, £4,812,499 for Bolton's +8,000) — the f32 store is REPRODUCED, not
rounded away, and both dirty values fall straight out of the model.

**The `tier` argument is the club's STATURE band, not the board objective.** `FUN_0057ed09`
loads `club+0x58` and passes it as arg4 of `FUN_0057d780`, which stores it at `ground+0x24`;
`FUN_0057ddd0`'s callers read `[club_ground+0x24]` back out (e.g. `0x51d473`). `club+0x58` is
the same stature 0-12 the fee/wage tables use (`transfer_value_re.md`, `FUN_0057a180`), which
the app already computes as `TransferMarket.stature_of(squad, division tier)`. The earlier
"the board-objective label drives the seat-price tier" note was a **correlation** — in the
witnessed clubs Champion/U.E.F.A./Mid Table/Avoid Relegation/Promotion happen to sit on
stature 0/1/2/3/4 — not the mechanism.

Category map (the ids the callers pass, which are exactly the GROUND ledger's own order):

| cat | item | weeks | price coefficient by stature 0..8, default |
|---|---|---|---|
| 1 | SEATS (3 offer cards) | 20 / 35 / 50 by card | 42.5 37.5 32.5 27.5 22.5 20 17.5 15 12.5, **10** |
| 2 | (second seats table, unused on the English 97-98 grounds) | 20 / 35 / 50 | 40 35 30 25 20 17.5 15 12.5 10, **7.5** |
| 3-6 | CAR PARK NE / NW / SE / SW | 7 | 85 75 65 55 45 40 35 30 25, **20** |
| 7 | FLOODLIGHTS | 4 | 25 20 20 15 15 10 10 5 5, **5** |
| 8 | UNDER-SOIL HEATING | 8 | 30 30 25 20 20 15 15 10 10, **10** |
| 9 | CHANGING ROOMS | 3 | 15 15 15 10 10 5 5 3 3, **3** |
| 10 | SCORE BOARD | 1 | by GRADE, not club: 0 / 20 / 80 |
| 11 | ACCESS TO THE STADIUM | 6 | 30 30 25 25 20 20 15 15 10, **10** |
| 12 | MEDICAL EQUIPMENT | 2 | 15 15 10 10 10 10 10 5 5, **5** |
| 13 | CLUB SHOP | 0 / 1 / 5 / 10 by grade | 5 5 5 4 4 4 3 3 2, **2** |
| 14 | CAFES | 1 / 5 / 10 / 20 by grade | 5 5 5 4 4 4 3 3 2, **2** |
| 15 | TOILETS | 1 | flat 10 |

`index` is the TARGET grade for 10/13/14 and the offer card for 1/2; the rest ignore it.
Companions: `FUN_0057e3f0(_, i) = (i+1)*4000` (the +4,000/+8,000/+12,000 seat increments) and
`FUN_0057e410() = 500` (car-park spaces per level) — both already witnessed on screen.

**Port + validation.** `tools/re/extract_ground_prices.py` WALKS those jump tables in the real
`MANAGER.EXE` (nothing transcribed by hand) into `app/data/ground_cost_table.json`; it refuses
to write unless all **24/24** witnessed prices reproduce exactly — the five live-witnessed
SEATS ladders (Arsenal/Man Utd, Aston Villa, Wimbledon, Bolton W, Manchester C), Man Utd's
CAR PARK per level, and all nine FACILITIES/SERVICES items. `app/scripts/GroundCost.gd` is the
runtime model (`PackedFloat32Array` for the f32 store); `app/tests/test_ground_cost.gd` pins
the same 24 witnesses plus the default-arm and grade-ladder behaviour. `StadiumScreen` takes
the band via `set_improve_state(..., cost_tier)` and `Main` feeds `Career.my_band()`, so
**all 476 clubs are priced from the binary** — the `OFFER_PRICES` / `TIER_PRICES` /
`_carpark_price` two-club lookups are now fallbacks for callers that pass no band.

**End-to-end check (the one that matters).** Running the app's OWN `game_db.json` squads
through `TransferMarket.stature_of`'s thresholds and into the extracted table reproduces every
witnessed board tier without being told what they were:

| club | squad avg AV | stature | SEATS ladder | witnessed board |
|---|---|---|---|---|
| Manchester Utd. / Arsenal | 81 / 80 | 0 | 4,250,000 / 7,437,500 / 10,624,999 | Champion |
| Aston Villa | 78 | 1 | 3,750,000 / 6,562,499 / 9,375,000 | U.E.F.A. |
| Wimbledon | 72 | 2 | 3,250,000 / 5,687,500 / 8,124,999 | Mid Table |
| Bolton W | 71 | 3 | 2,750,000 / 4,812,499 / 6,875,000 | Avoid Relegation |
| Manchester C (Div 1) | 69 | 4 | 2,250,000 / 3,937,500 / 5,624,999 | Promotion |

The stature model was built for transfer fees and never touched ground prices; it lands on
the right tier for all five clubs independently. That is why the objective LOOKS like the
driver and is not.

### `club+0x50` — REVERSED 2026-07-28: it is the club's COMPETITION INDEX

The preset selector is not a stored data byte at all, which is why the EQUIPOS parser could
never find it: **`FUN_00579c70` does not write `club+0x50`**. Checked mechanically — the club
loader writes 0x4, 0x8, 0xc, 0x14, 0x18, 0x1c, 0x20, 0x24, 0x28, 0x34, 0x36, 0x38, 0x3a,
0x1d9..0x1df, 0x1e8, 0x1ec, 0x278, 0x27a, and nothing else.

It is COMPUTED, by **`FUN_0057a180`** (`docs/re/groundpreset/fn_0057a180_FUN_0057a180.c`,
found by scanning `.text` for stores to `[reg+0x50]` and filtering to the club module):

```
FUN_0057a180(club):
    id = club+0x10
    if id in (0x26e4, 0x26de):  i, cap = 0xd, 0xc          # the parser's own special ids
    elif id == 0x26ae:          club+0x50 = 0xd; club+0x58 = 0; return
    else:
        i = 0
        for p in DAT_0066b190 .. DAT_0066b1a0:              # entries 0..3
            if p->vtbl[0x48](id) != 0: break                # "is this club in me?"
            i += 1
        if i > 3:
            i = 7
            for p in DAT_0066b1ac .. DAT_0066b1c4:          # entries 7..12
                if p->vtbl[0x48](id) != 0: break
                i += 1
        cap = min(DAT_0066b190[i]->vtbl[0x78](FUN_0057a340()), 0xc)
    club+0x50 = i
    club+0x58 = cap
```

So **`club+0x50` is the index of the first competition in the table at `DAT_0066b190` that
CONTAINS the club** — the same competition-pointer table the finance euro-income label decode
reads (`DAT_0066B1B0` is entry 8 of it). Entries 0..3 are scanned first and 7..12 second, and
`club+0x58` — the other argument `FUN_0057d780` takes — is that competition's own
`vtbl[0x78]` value clamped to 0xc.

**Proven:** entry 0 is the Premier League. Preset 0 is exactly Man Utd's witnessed starting
grades, and Man Utd is a Premier club, so the club that selects preset 0 is a Premier club.

### BOUND 2026-07-28: the divisions are entries 0 / 1 / 2 / 3, and it is witnessed

The missing capture was taken. Two careers were driven from the title screen under wine
(`tools/re/refs/lowdiv-2026-07-28/`, TOTAL control):

| club | division | witnessed grades | preset |
|---|---|---|---|
| Birmingham C (St. Andrews) | First | FLOODLIGHTS **500.000 K.W.** (1), CHANGING ROOMS BASIC (0), SCORE BOARD **ELECTRONIC** (1), MEDICAL BASIC (0), CAFES **MEDIUM** (1), TOILETS **20 W.C.** (1) | **1** |
| Barnet (Underhill Stadium) | Third | FLOODLIGHTS NONE (0), CHANGING ROOMS BASIC (0), SCORE BOARD MANUAL (0) | **2/3** |

Six of the nine grades were re-witnessed on the First Division club and every one matches
preset 1 (`1 0 0 1 0 0 0 1 1`) exactly; the Third Division club sits at zero on all three
of the items that separate the presets. Since entry 0 is Man Utd's Premier preset, the scan
order **0 = Premier, 1 = First, 2 = Second, 3 = Third** is now witnessed rather than read off
the monotone degradation. Second vs Third is not observable and does not need to be:
**0x57d834's jump table sends indices 2 and 3 to the SAME arm** (`0057d80b`), so they seed
identically, and anything above 3 — the 384 directory-only foreign clubs, which
`FUN_0057a180` numbers 7..12 — is a bare `ja 0057d830` to `ret`, so those clubs keep the
ctor's zeros. Ported: `app/scripts/GroundPreset.gd`, gate `app/tests/test_ground_preset.gd`.

**Two NEW price witnesses came out of the same drive — the first ground prices ever seen
away from Man Utd, and both fall out of `FUN_0057ddd0` unchanged:**
* Birmingham C, FLOODLIGHTS 500.000 → 1.000.000 K.W.: **£200,000 / 4 weeks** = coefficient
  10.0 = the floodlights arm at band 5 or 6 (a First Division club's band is 4/5/6).
* Barnet, the three SEATS cards: **£1,000,000 / £1,750,000 / £2,500,000 at 20 / 35 / 50
  weeks** = coefficient 10.0 = the seats arm's `price_default`, i.e. band ≥ 9 (a Third
  Division club's band is 10/11/12).
Both are pinned in `test_ground_preset.gd`. Until this drive the whole cost model rested on
one club; it now reproduces three clubs across three divisions.

### Still open here
`FUN_0057d780`'s arg3 (`club+0x50`) picks one of **four starting-grade presets** for the nine
facility/service items and the four car-park quadrants:

| preset | car park NE-SW | the nine grades (+0x29..+0x31) | +0x3e |
|---|---|---|---|
| 0 | 1 1 1 1 | 2 0 1 2 1 1 0 2 2 | 0x32 |
| 1 | 0 0 0 0 | 1 0 0 1 0 0 0 1 1 | 0x19 |
| 2, 3 | 0 0 0 0 | 0 0 0 0 0 0 0 0 0 | 0x19 |

Preset 0 is **exactly** Man Utd's witnessed starting grades (FLOODLIGHTS 2 / HEATING 0 /
CHANGING ROOMS 1 / SCORE BOARD 2 / ACCESS 1 / MEDICAL 1 / CLUB SHOP 0 / CAFES 2 / TOILETS 2),
which confirms the field order. ~~What is NOT yet reversed is where `club+0x50` comes from~~ —
**reversed 2026-07-28: it is the club's competition index.** ~~What is left is ONE capture of
a lower-division club's IMPROVE panel~~ — **TAKEN 2026-07-28 (Birmingham C + Barnet), so the
binding is witnessed and CLOSED.** All 476 clubs are now seeded from the preset by
`GroundPreset.items()`; `app/data/ground_prices.json` is retained only as the captured Man Utd
reference the generator is gated against.

## WIRING (Main.gd)
`Main._show_stadium_screen()` calls `scr.setup(club, manager, season, ground, cap,
seated, standing, parking, works_status, ticket, board, week, league)` (signature unchanged;
**`seated / standing / parking / ticket / board` are ignored** — they fed removed invented
readouts) and connects `scr.improve_selected → _on_stadium_improve` + `scr.back_pressed`.
Remaining follow-ups, both Main-side:
1. Pass **structured `Career.works` (added/cost/weeks_left)** instead of only a status string,
   so the WORK IN PROGRESS ledger can fill the exact TO BE PAID (£) / WEEK cells + TOTAL. Today
   a non-empty `works` string shows on the SEATS row and the money total stays £0.
2. Optionally pass the managed `club_id` to `draw_header` for the barra crest (currently −1).
**GROUND MATCH DAY** (ticket price) + **CAR PARK grid** sub-screens remain future work.

## Module map (MANAGER.EXE, unchanged)
- `FUN_0051a3e0` ctor · `FUN_004fa840` window base `CRect(0,0,640,480)` · **`FUN_0051a6e0` =
  OnDraw** (loads `recursos\iconos\estadio\estadio%d.bmp`, draws title/panels/2×2 grid) ·
  `FUN_0051bd80` = the IMPROVE/works construction sub-view.
Helpers: `FUN_00436fb0`/`FUN_00436fd0` point/rect, `FUN_00437020` text colour, `FUN_005c06d0`
icon blit. Palette MANAGER.PAL (RIFF, DAT.PKF); scenes omit palette → export with `--force-pal`.
