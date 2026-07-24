# GROUND (ESTADIO) screen — RE findings + frame-true rebuild

Status: **REBUILT frame-true** (2026-07-13; **IMPROVEMENTS view added in-screen 2026-07-17**,
charter #8). Owns `app/scenes/StadiumScreen.gd`, `tools/re/build_stadium_chrome_from_frames.py`,
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
`tier = clamp(capacity * 11 / 130000, 0, 11)` (reversed `FUN_0051a6e0` @0x51a728, magic
division). 12 tiles `estadio0..11.png` (320×240, MANAGER.PAL). The frame's Old-Trafford
render = tier 4 (real capacity 55,300). The tile fills the picture box exactly and covers the
baked tile so no tier bleed is possible.

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
**Scope caveat:** tier 4 is the only tile with a real render to check against. The other 11 were
corrected by the same mapping on the strength of the shared seam signature (same column, same z
band) and are **not** independently render-verified — capture a GROUND screen for a club in
another capacity tier to close that. The residual 0.83% is fine dither noise; whether the live
render dithers at blit time is not reversed. The capture's frames 01-12 have pixel-identical
panels (0.0% between them), so the picture is static — no animation is being read as an offset.

## What is frame-true vs honest gap
- **Frame-true (baked or reversed):** the entire body chrome — both panels, all section/
  facility/column/button labels + icons, TOTAL IMPROVEMENTS, the green header, the table
  frame, the 2×2 grid, the tier picture box, all rects.
- **From real Career:** ground name = GameDB `club.stadium`; CAPACITY = `Career.stadium_capacity`;
  tier = from that capacity. (Only **15/476** clubs carry a real `capacity` in `game_db.json`;
  the rest — incl. Man Utd — fall back to `FinanceModel._CAP` per division, so the in-app
  capacity/tier can differ from the frame's real 55,300/tier-4. That is a DB-layer gap, not a
  screen bug.)
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
  BLANKED in the bake and redrawn from that lookup; **any other managed club shows an HONEST
  GAP (blank £ cell, no purchase)** rather than a fabricated price. Deriving a formula from two
  data points and applying it to 476 clubs would be invention — deferred until the cost fn is
  reversed. **Next RE step:** Ghidra the offer-cost function to unlock per-club prices.

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
**Still un-RE'd (flagged, not fabricated):** the per-club generalisation — only Man Utd is
captured, so the other 475 clubs fall back to the sparse witness default (CHANGING ROOMS +
MEDICAL) until each is captured OR the cost fn is reversed; and the exact upgrade COMMIT trigger
(preview-tap is observed; second-tap-to-buy is the app's inferred commit). The GROUND MATCH DAY
sub-screen (frame 06) is already built.

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
