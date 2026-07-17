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
render = tier 4 (real capacity 55,300). The tile matches the frame's scene (a small internal
crop/palette offset vs the live render is an export artefact, not a placement error); it fills
the picture box exactly and covers the baked tile so no tier bleed is possible.

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
(now showing the WORK IN PROGRESS state). CAR PARK / FACILITIES / SERVICES tabs are **inert**
(their offer lists are un-witnessed → not fabricated). Tests: `test_stadium_screen`
(view toggle, card hit-test, witnessed vs honest-gap price), `test_stadium_works`, `test_wiring_pass`.

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
