# The SORTEO screen — the cup DRAW (frame-exact, 2026-07-24)

Status: BUILT, incl. the ONE-BY-ONE REVEAL (2026-07-27, §"The reveal") — clubs land
on the hand's slip exactly as p0125→p0131 witness; the slip render reproduces p0127's
265 name pixels at 0 px. OURS, flagged: the reveal cadence, tap-to-skip, the list-form
extension. Open: the CONTINUE ball's lit/unlit rule, the shadow-pass driver.

The screen MANAGER.EXE raises when a knockout round is drawn. It replaces
`app/scenes/CupScreen.gd`, which was an invented marble-panel surface with no original
counterpart (APP_VS_SPEC_AUDIT B2). Scene: `app/scenes/CupDrawScreen.gd`.
Chrome: `tools/re/build_cupdraw_chrome_from_frames.py`.
Art: `tools/re/export_sorteo_art.py`. Render-diff: `tools/re/diff_cupdraw_parity.py`.

## Result

| shot | binding frame | differing pixels |
|------|---------------|------------------|
| `cupdraw_74.png` | `wine-captures-2026-07-18-goalscorers/74_after_wk4.png` | **0 / 307 200** |
| `cupdraw_10.png` | `promanager-career-2026-07-16/10_fa_cup_draw_round1.png` | **1** (see residuals) |

Reproduce:

```bash
python3 tools/re/export_sorteo_art.py                    # asserts the picture at 100.0000%
python3 tools/re/build_cupdraw_chrome_from_frames.py
~/godot462 --headless --path app --import
DISPLAY=:1 PM98_SHOT_DIR=<dir> PM98_CUPDRAW_SHOT=1 ~/godot462 --rendering-driver opengl3 --path app
python3 tools/re/diff_cupdraw_parity.py <dir>
~/godot462 --headless --path app -s tests/test_cupdraw_screen.gd
```

## The evidence

Three real MANAGER.EXE frames, two careers, two competitions:

* `74_after_wk4.png` — Bolton W, Manager League. **Coca-Cola Cup ROUND 2**, four ties
  drawn, the fourth still waiting for its away club (`Coventry -`).
* `75_scout_wk5.png` — the same draw seconds later: **nine** ties, the ninth waiting.
  Proves the list fills one club at a time and that the scrollbar does **not** move as it
  fills. (Its row 17 is white — a mouse-hover highlight, not draw state.)
* `10_fa_cup_draw_round1.png` — Brighton, 3rd Div., Promanager. **F.A. Cup ROUND 1**.
  Different competition strip, title, drum frame, tie count and bottom-left plates.

And MANAGER.EXE itself, which names every file this screen loads in one contiguous
string block at **0x255670-0x255aa4** — this is the art list, not a guess:

```
0x2559d0  img\sorteo\frames\fondo.bmp                188x144   drum + table backdrop
0x2558c0  img\sorteo\frames\Bombo00..11.bmp           92x92    the drum, 12 rotation frames
0x2557f2  img\sorteo\frames\Bola0..3.bmp              24x20    the drawn ball
0x255712  img\sorteo\frames\Mano0..7.bmp            <=185x76   the hand reaching in
0x255670  img\sorteo\flecha {azul,verde} {izda,dcha}.bmp        tie-detail arrows
0x255a94  img\stop0.bmp                              15x14     the FINISH button's STOP sign
0x2559ec  img\copas\ligacampeones sorteo.bmp          72x144    European Cup
0x255a10  img\copas\uefa sorteo.bmp                   72x144    U.E.F.A. Cup
0x255a2c  img\copas\recopa sorteo.bmp                 72x144    Cup Winners' Cup
0x255a48  img\premier\copas\cocacola sorteo.bmp       72x144    Coca-Cola Cup
0x255a70  img\premier\copas\facup sorteo.bmp          72x144    F.A. Cup
```

The screen's own string block sits at **0x2523e4-0x25253c**: `MATCHES`, `1ST LEG`,
`2ND LEG`, `REPLAY`, `MATCH RESULT`, `REPLAY RESULT`, `1ST LEG MATCH`, `2ND LEG MATCH`,
`AGGR.`, `RES.`, `STADIUM`, `Date`, and the round plates `FINAL` / `QTR FINALS` /
`ROUND 4` / `ROUND 3` / `ROUND 2` / `ROUND 1` / `SEMIFINAL 1` / `SEMIFINAL 2` /
`FINALIST 1` / `FINALIST 2`, plus `This championship hasn't started`. `FINISH` is at
0x255aa4, next to its `img\stop0.bmp`.

## A prerequisite that had to be fixed first: the 1024-byte DIB misregistration

Every PCF5 image entry is a Windows DIB whose header still DECLARES a 256-colour palette
— `bfOffBits` = 1078 — while the archive **strips** those 1024 bytes: `bfSize` is
exactly 1024 more than the stored entry and the pixel rows start at offset **54**.
Pillow honours `bfOffBits`, so `tools/re/pkf_image.py` and `export_art.py` were reading
1024 bytes late and every image came out rotated by `1024 // stride` rows plus
`1024 % stride` columns.

It is invisible when the stride divides 1024 (a 32x32 crest wraps a whole 32 rows back
onto itself, which is why crests, kits and small icons always looked right) and glaring
otherwise — it is the `estadio<N>.png` seam that `fix_estadio_wrap.py` corrects
empirically at 320x240 (1024 = 3 rows + 64 columns). For the 72x144 SORTEO strip it is
14 rows + 16 columns, which is exactly the shape of the mismatch that first exposed it.

`pkf_image.dib_indices()` now parses the header and reads from offset 54, correct at
every size. `export_art.py --exact` routes through it. **Art exported before this fix
came from the wrapped path**; re-exporting any of it is safe but must be render-diffed
before it ships, and `fix_estadio_wrap.py` (which corrects already-exported PNGs) must
NOT be re-run on tiles re-exported the correct way.

## The picture layer — 100.0000% exact

Palette is **MANAGER.PAL** (the RIFF `PAL ` in DAT.PKF), not the shared VGA table.
Measured, not assumed: they differ at 20 indices and only MANAGER.PAL reproduces the
frame — under VGA, index 111 renders (24,24,16) where the game shows (10,15,0), 1232 of
the picture's pixels.

Layer order, all frame-absolute:

1. clear the window `(31,76) 260x144` to **black** — every pixel no layer covers is (0,0,0)
2. the competition's `<comp> SORTEO.BMP` (72x144) at **(31,76)**, index 0 transparent
3. `sorteo/frames/FONDO.BMP` (188x144) at **(103,76)**, index 0 transparent
4. one `BOMBO<nn>.BMP` (92x92) at **(136,76)**, drawn **OPAQUE** — its index-0 pixels
   land as black in the original. A transparent blit leaves 168 stray pixels; that count
   is what identified the rule.

Frame 74 holds **BOMBO08**, frame 10 holds **BOMBO07**, at the same spot — so the drum
is a 12-frame cycle. The RATE is ours (12 fps), flagged in the scene.

## Chrome and the dynamic layer

Static (identical across all three frames, kept byte-for-byte): the two bezelled panels,
the green MATCHES header and its checker rail, all 23 row separators, the scrollbar
arrows, FINISH, CONTINUE.

Cleared and redrawn:

| span | content | font / colour |
|------|---------|---------------|
| `(31,76) 260x144` | the picture, above | — |
| title plate `(44,34)-(288,58)` | competition name | ProMan14, `(255,255,255)` |
| ROUND plate `(44,232)-(288,254)` | round label | ProMan14, `(255,223,0)` |
| leg plates `(26,410)` / `(26,437)` | 1ST LEG / 2ND LEG, or MATCH / REPLAY | ProMan10, `(255,255,0)` |
| list `x334..605`, 23 rows | the drawn ties | ProMan10, `(80,100,120)` on `(200,220,240)` |
| trough `x606..623 y70..401` | the proportional thumb | — |

The plates are a `(44,44,44)`/`(80,80,80)` **dither**, so a flat refill would show. They
are cleared by union: a pixel comes from frame 74 unless 74 inks it, in which case it
comes from frame 10 — the same screen, so outside the ink the two frames are
pixel-identical and the recovered texture is the ORIGINAL's. Only where BOTH frames ink
(the centred titles overlap: 207 + 367 + 237 px) does the bake borrow the nearest
ink-free pixel on the same row of the same plate.

### Text metrics, solved from the frames

Every glyph offset in these banks is 0, so the pen origin IS the ink start.

* **Title** — pen = `(325 - advance) / 2`. Gives 96 for `Coca-Cola Cup` (adv 133) and
  121 for `F.A. Cup` (adv 83); both frames put them exactly there. Pen top **39**
  (one less than the ink row: the BMFont cells carry an empty first row).
* **ROUND** — pen = `(320 - advance) / 2`, floored: 113 for `ROUND 2` (93), 116 for
  `ROUND 1` (88). Pen top **236**.
* **Leg plates** — pen = `(116 - advance) / 2`: 30 / 27 / 33 / 30 for
  `1ST LEG` / `2ND LEG` / `MATCH` / `REPLAY`. Pen tops **413** and **440**.
* **List rows** — row *k* spans `y = 51 + 16k .. +14`, separator on the 16th row; pen top
  is `+2`. The home club is **right-aligned so its pen ENDS at 465**, the `-` is a fixed
  glyph at **467**, and the away club's pen starts at **475**. All three hold on eight
  witnessed rows across the two careers. A tie whose away club has not been drawn yet
  renders as home + dash alone, which is what frames 74 and 75 both catch mid-draw.

### The scrollbar

Trough interior `y 70..401` (331 rows), box `x 606..623` (18 px — 606 and 622-623 are the
**thumb's own** black edges and show trough colour where there is no thumb).
Thumb height = `round(331 * 23 / ties)`, which solves both witnesses exactly: **305** for
the 25-tie Coca-Cola round 2 and **190** for the 40-tie F.A. Cup round 1 — the measured
values. (25 and 40 are the real 1997-98 field sizes for those rounds.) The body is a
two-row alternating band keyed on absolute y; both frames start their thumb at y 70, so
that parity choice is not independently distinguished.

## The SECOND panel form, and the tie-detail card — BUILT 2026-07-25 (REFRUN R8)

The MATCHES panel has **two forms**, and the switch is **list length**:

| ties in the round | form |
|---|---|
| **> 16** | one centred `Home - Away` line per tie, 23 rows, scrollbar (the form above) |
| **<= 16** | a **16-row GRID** of four columns — home kit, home club, away club, away kit — and **no scrollbar at all** |

Witnessed on four frames of the reference run: the Coca-Cola Cup ROUND 3 and the F.A. Cup
ROUND 4 (16 ties -> grid) against the F.A. Cup ROUND 3 and the Coca-Cola ROUND 2 (32 and
25 -> list). The grid's sixteen bands are painted **before any club lands in them**
(`p0125`, `p0445` are empty grids), so the switch is the FULL round's tie count, not how
many have been drawn.

Grid geometry, off the frames' own black borders: column borders at x332-333 / 355 /
477-478 / 600 / 622-623; row separators every 23px from y49-50 to y418-419, so 16 rows of
22 starting at y51.

| cell | span | content |
|---|---|---|
| home kit | x334..354 | the club's kit |
| home club | x356..476 | centred on `356 + 476`, proman10, pen top +6 |
| away club | x479..599 | centred on `479 + 599`, same |
| away kit | x601..621 | the club's kit |

Row states, all four witnessed:

| state | name-cell ground | kit-cell ground | ink |
|---|---|---|---|
| even band | `(200,220,240)` | `(180,200,220)` | `(100,120,140)` |
| odd band | `(160,180,200)` | `(140,160,180)` | `(60,80,100)` |
| **the manager's own tie** | `(60,60,100)` | `(40,40,80)` | `(100,120,140)`, and **his club** in `(255,255,85)` |
| highlighted | `(255,255,255)` | `(255,255,255)` | `(60,80,100)` |

The highlighted row is a **mouse-hover** state (the same one the list form's row 17
shows). A touch app has no hover, so it is bound to the TAPPED row instead — the state is
the original's own even though the trigger cannot be.

### The tie-detail card

The bottom-left panel's "two long value cells" are a **per-tie detail card**, populated
when a row is taken: each club's name over its manager's, and the two legs' GROUNDS
beside the MATCH / REPLAY (or 1ST LEG / 2ND LEG) plates. Every line was solved with
`tools/re/probe_text_anchor.py` at ZERO differing pixels against BOTH populated frames
(`p0131` Bradford City / Jewell v Manchester Utd. / MWM, `p0747` F.C. Barcelona /
Van Gaal v Karlsruher):

| line | font | centre (field sum) | pen tops | ink |
|---|---|---|---|---|
| club | proman10 | 325 | 323 / 361 | `(255,223,0)` |
| manager | calend12 | 325 | 335 / 373 | `(166,202,240)` |
| ground | proman10 | 398 | 411 / 438 | `(42,191,255)` |

**The MANAGER'S OWN name renders GREEN `(42,191,85)`** where another manager's is pale
blue — witnessed on `MWM`.

The two kit panels (x33..109 y325..380 and x236..286 y329..384) use the app's own kit art
scaled in, the same documented approximation `CompResultScreen` and `CharityShieldScreen`
carry, because the original's hi-res panel kit bank is un-extracted.

### Render-diff

`tools/re/diff_cupdraw_parity.py` now covers **both forms, four frames**:

| shot | frame | differing px after exclusions |
|---|---|---|
| `cupdraw_74` | Coca-Cola ROUND 2 (list) | **0** |
| `cupdraw_10` | F.A. Cup ROUND 1 (list) | **1** |
| `cupdraw_133` | Coca-Cola ROUND 3 (grid, own tie marked) | **0** |
| `cupdraw_747` | U.E.F.A. 1/16 (grid, card filled) | **2** |

The grid shots exclude the kit cells and the card's two kit panels (the harness feeds
club NAMES only, so no kit is drawn) and the drum — see below.

### A NEW drum finding, for the parked hunt

`p0133` and `p0747` hold a drum image that is **byte-identical to each other** and
matches **none of the twelve exported BOMBO frames** (nearest is BOMBO00 at 2709 px),
while `p0125` is BOMBO03 and `p0445` is BOMBO06 at **zero**. So the drum has at least one
state beyond the twelve stills — the first positive evidence in that direction, and a
lead worth taking when the drum hunt resumes. Candidates: BOLA or MANO composited over a
BOMBO frame, or a lit variant.

#### RESOLVED 2026-07-25 — there is no thirteenth drum. It is the SHADOW.

Every candidate above was tested and killed, and the answer turned out to be a lighting
pass, not missing art:

* **There is no thirteenth bitmap to find.** `IMG.PKF`'s directory holds exactly
  `BOMBO00.BMP` .. `BOMBO11.BMP`, four `BOLA?.BMP`, eight `MANO?.BMP` and the per-cup
  `* SORTEO.BMP` plates. `SORTEO.BMP` itself is a **31x31 icon**, not a scene.
* **Not a palette variant** — rendering the twelve under the VGA table and all three RIFF
  palettes (MANAGER / MENU / DBASE) gives pixel-identical results, so the same two
  nearest neighbours and the same 2551-px residual.
* **Not an offset** — a +-8 px search around the (136,76) anchor makes every frame worse.
* **Not a mid-blit tear** — a row-by-row best-match walk picks BOMBO00 for 88 of the 92
  rows with a residual on every one of them, so there is no clean split between two
  frames.
* **Not a per-colour LUT dim** — 8115 of 8203 pixels sit on source colours that map to
  more than one destination colour, so whatever changes them is SPATIAL, not palettal.

What it is: **the drum's cast shadow, colour `(10,15,0)`.** That exact colour is present
in every cup-draw frame — 1206 px in `p0445`, 1243 px in `p0125`, where it draws the
shadow the drum throws down-left onto the table — and in `p0133` / `p0747` it covers
**2761 px**, because there it also lies across the cage's own interior. Mask the frame to
that one colour and the picture is unmistakable: the drum's silhouette plus its shadow.
Correspondingly the whole 2551-px residual sits on the three DARK BLUES of the drum art
(`(0,0,50)` idx 22, `(20,0,90)` idx 167, `(0,0,128)` idx 4) and on the metal edges beside
them; the white/grey cage and the gold balls are untouched.

So `p0133` / `p0747` are **BOMBO00 under the shadow pass**, and the twelve stills are the
complete set. The open question is no longer "where is the thirteenth frame" but "what
drives the shadow" — it is the same class of engine pass as the NANOESC kit shadow and
the PMAlert LUT dim, both already documented in this port.

## Wiring

**The live route exists (REFRUN R4, 2026-07-25).** `Career._queue_cup_draw` banks one
entry per knockout round it resolves — both domestic cups and all three European
competitions — into `Career.pending_cup_draws`, and `Main._pop_cup_draw` raises it at the
head of the post-week card chain, over the hub, unprompted, exactly as the original does.
FINISH and CONTINUE both dismiss; more than one competition in a week raises one card
each. The plate label, the leg plates and the trophy strip all come from
`Cup.draw_round_plate` / `draw_leg_plates` / `draw_art_key`, so the hub route and the
live route cannot drift apart.

**DIVERGENCE, flagged:** the original draws a round and plays it later, so its SORTEO
shows the ties before they are played. `Cup.play_round` pairs AND plays in one step, so
the card is raised immediately AFTER. Nothing on the screen differs — the SORTEO carries
no scores — but the ordering against the week's result news is ours until the model
separates the two steps.

`Main._show_cup_screen(bracket, key, title)` also mounts it for **every knockout round** of the
F.A. Cup, Coca-Cola Cup, European Cup, U.E.F.A. Cup and Cup Winners' Cup, from the hub
COMPETITIONS chooser and from the devshot walk. `Main._cup_draw_view` builds the payload
from the bracket's LATEST round:

* the plate label is Cup.gd's own label uppercased, with the per-leg suffix (`- 1st`)
  dropped — the original carries the leg on the bottom-left plates — and `QTR. FINALS`
  normalised to the EXE's plate spelling `QTR FINALS`. A label the plate block does not
  carry (`ROUND 5`, `SEMIFINALS`) is uppercased as-is rather than invented into one of
  the `SEMIFINAL 1` / `SEMIFINAL 2` plates, whose selection rule is not reversed.
* the leg plates follow THIS round, not the competition: the League Cup is two-legged
  throughout but its final is a single match, so that round shows MATCH / REPLAY.

## Un-witnessed, and therefore NOT built

* ~~**The two long value cells** in the bottom-left panel~~ — **CLOSED 2026-07-25.** They
  are the tie-detail card, populated and specified above (REFRUN R8). The `flecha
  azul/verde` arrows the EXE loads are still exported and unused.
* ~~**MANO0..7 and BOLA0..3** — the hand and ball the EXE loads for this screen appear in
  no captured frame.~~ — **FALSIFIED and CLOSED 2026-07-27.**
  `refrun-manutd-1997-98/named/p0127_cup_draw.png` shows **MANO7 byte-exact at
  (106,144)** (5.4 mean|d| best match on the earlier sweep; re-verified here at 0
  differing pixels over the sprite's whole alpha once the slip name is inked). See
  §"The reveal" below. BOLA0..3 remain unwitnessed — exported, unused.

  **The 2026-07-25 "does not animate" film — EXPLAINED, not contradicted.** That film
  had captured an ALREADY-FINISHED draw: BOMBO-frame forensics across every capture show
  each mid-draw frame on a DIFFERENT drum frame (p0125 = BOMBO03, p0126 = BOMBO08) while
  every finished-draw frame is parked on **BOMBO00** (p0131, and p0133/p0747 = BOMBO00
  under the shadow pass). A parked draw is a still — which is exactly what was filmed.
  What that film DID establish and still stands: CONTINUE on a finished draw
  cross-fades straight out, and the bottom-left panel is a per-tie detail card.

## The reveal (witnessed 2026-07-27; built the same day)

The witnessed sequence, Coca-Cola ROUND 3: `p0125` EMPTY grid, drum spinning (BOMBO03)
→ `p0126` ONE tie landed (BOMBO08) → `p0127` the HAND out of the drum — MANO7 at
(106,144) — holding the slip with the NEXT club's name, **"Bradford City" = tie 2's
HOME side, not yet in the grid** (so the unit of reveal is the CLUB, home before away)
→ `p0131` the full grid, drum parked on BOMBO00.

The slip name (all 265 ink pixels of p0127 reproduce at ZERO differing pixels,
rendered from the rule, not sampled): **calend12**, pen centred on **field-sum 380**,
pen top **152**, inked through the slip's own paper tones —
`(192)→114` flat, `(240)→144` flat, `(220)→` a **144/128 checkerboard by (x+y)
parity** (even → 144). Ink lands only on the paper (greyscale slip pixels).

Built: `CupDrawScreen.reveal()` — grid empty, drum cycling; per club: MANO0..7 rise,
the slip name at MANO7, the club lands in MATCHES; park on BOMBO00 + CONTINUE when
done. `Main._pop_cup_draw` (the live, unprompted card) calls it; hub re-views of an
already-drawn round stay parked, and the idle screen no longer spins (the old
always-spinning idle was the port's own invention — the finished state is parked).
OURS, flagged: the cadence (`REVEAL_RISE/HOLD/GAP`, no two stills are a known time
apart), the MANO0..6 rising rate, extending the reveal to the LIST form (witnessed on
the grid only), tap-to-skip (any tap completes the draw; the buttons return after).
BOLA frames stay unused.
* **The CONTINUE ball's lit/unlit rule.** Frame 74 is dark, frame 75 is green, frame 10
  differs again; the trigger is unknown, so the chrome bakes frame 74's phase and the
  differ excludes that rect. This is the only exclusion.
* **The drum's frame rate** (12 fps is ours) and **which BOMBO frame a draw starts on**.
* ~~**The European GROUP phase.**~~ — **CLOSED 2026-07-26.** It is not a knockout draw; it
  has its own screen — RESULTS → **EURO. LEAGUE** — now BUILT as `EuroGroupScreen` and
  render-diffed against all six witnessed group frames
  ([`euro_league_screen_re.md`](euro_league_screen_re.md)). The old
  `Main._show_cup_group_placeholder` is deleted.
* ~~**The Intercontinental Cup**~~ — **CLOSED 2026-07-25.** It has no `SORTEO` strip
  because it is not a draw: it is a single match on the CHARITY SHIELD screen, which
  MANAGER.EXE proves byte-for-byte (`FUN_0048daf0` == `FUN_004717a0` bar the title string
  and the trophy bitmap). Built as `CompResultScreen` —
  [`comp_result_screen_re.md`](comp_result_screen_re.md).

## Residuals

* `cupdraw_10.png`: **one** pixel, at (167,147) inside the drum art — `(192,227,192)` vs
  the frame's `(192,220,192)`. Present in the raw art comparison too, before any of our
  compositing; the two careers were captured on different wine sessions.
* The CONTINUE rect `(489,436)-(614,470)` is excluded, per above.

## The THIRD panel form — the EUROPEAN CUP GROUP DRAW (built 2026-08-02, s88)

Status: **BUILT, 1 differing pixel** against its binding frame outside the CONTINUE ball and
the eight kit/flag sprites that carry the un-reversed on-sprite edge pass. Open, and named:
the round plate the port puts on this card, and the edge pass itself.

`Evidence:` `tools/re/refs/cupdraw-rounds-2026-08-01/manutd_s1_eurocup_groups_1_8_final.png`,
`tools/re/build_groupdraw_chrome_from_frame.py`, `tools/re/probe_groupdraw_frame.py`,
`tools/re/probe_cupdraw_labels.py`, `app/scenes/CupDrawScreen.gd`,
`app/tests/test_cupdraw_screen.gd`, `extracted/Premier Manager 98/MANAGER.EXE` @0x652ab0.

### What it is

The panel had two forms (the >16-tie LIST and the <=16-tie GRID). The European Cup's GROUP
phase draws a third: the header plate reads **GROUPS** in black on flat white where the other
two read MATCHES, and under it sit **six boxes in a 2x3 grid**, each a green `GROUP <letter>`
header over four `kit | club | flag` rows. The bottom-left tie card is **entirely blank, leg
plates included**, so this form draws neither.

### Why one frame was enough

The widget repeats six times and the witness catches the draw MID-REVEAL — group A holds its
four clubs and B..F are empty. Measured, not assumed:

* the five empty boxes' ROW BANDS are **pixel-identical to each other (0 px)**, so group C's
  band IS the empty-row widget and is what group A's populated band is cleared with;
* their headers differ from each other **only in the letter glyph**, so the plate under a
  letter is whatever box does not ink that pixel (37 px of the 22x14 cell are inked by all
  six and borrow in-row from the same plate row instead);
* the frame agrees with the already-baked `chrome_grid.png` at **0 px** over the whole left
  panel outside the picture window, the two text plates and the leg plates — which is what
  makes taking the title/ROUND plate texture from that bake legitimate, and it is taken by
  UNION (this frame's pixels everywhere it does not ink) rather than wholesale.

### The geometry, all off the frame

| | |
|---|---|
| GROUPS plate | white interior (334,23)-(622,49); proman12 BLACK, field sum **955**, pen top 30 |
| boxes | x **326 / 483**, y **55 / 180 / 305**, each **149 x 121**, 2-px black border |
| header | the word `GROUP` is CHROME (it never changes); the letter is proman12 WHITE at box-local **(119, 4)** |
| rows | four, box-local y **20**, pitch **25**, height **24** |
| kit | **RIDIESC 17x20** at box-local (7, row+2) — `app/art/kits/ridi/<club>.png` |
| club | proman10, centred on box-local field sum **177**, pen top row+1; ink alternates (100,120,140) / (60,80,100) with the band, exactly as the GRID form's does |
| flag | **MINIBAND 14x10** at box-local (80, row+14) — and only its **rows 1..9** are drawn |

Club and country identified by matching the sprites, not by reading the names: group A is
Sporting Port. (1076/PORTUGAL 47), Real Madrid C.F. (1003/SPAIN 22), Anorthosis
(1223/CYPRUS 15), W.Lodz (1147/POLAND 46), each the port's own exported RIDI kit at 33-34
mismatched px of 221 opaque — every one of them on the sprite's own edge.

### Two things measured and NOT explained away

* **The flag's top row is not drawn.** At (box+80, row+13) the frame carries flat row
  background across all fourteen columns on all four of group A's rows, while rows 1..9 sit
  at (box+80, row+14) and reproduce `art/flags/mini_%03d.png` to 8..11 px of 140. The port
  blits `Rect2(0, 1, 14, 9)` because that is what the frame shows. Why the bank is 14x10 and
  the blit nine rows is not reversed.
* **The kits' and flags' remaining residual is the 1-px on-sprite EDGE pass** — the same open
  item s62..s87 carry. It is the same signature here: where the port paints the sprite's own
  (22,22,22) outline, the frame carries the DESTINATION taken darker, and WHICH darker
  depends on the row band ((44,44,44)/(80,80,80) on the light row, (40,60,80)/(60,80,100) on
  the dark one). Excluded by named rect in `diff_cupdraw_parity.py`, not painted over.

### The round plate is the one thing this card cannot take from the witness

The frame's plate reads **`1/8 FINAL`** — a round of sixteen — while this port's European Cup
sends **eight** clubs into the knockout (six group winners plus the two best runners-up,
which `docs/re/euro_league_screen_re.md` witnessed off the QTR FINALS view) and therefore
names its first knockout round `QTR. FINALS`. That is a statement about the competition's
FIELD SIZE, not about this screen, and nothing in the corpus pins the field, so
`Cup.first_knockout_plate` derives the label from the port's own bracket and the discrepancy
is recorded here rather than hardcoded away. Note the EXE carries `1/8 FINAL` at VA 0x652ac8,
next to `SEMIFINALS` and `QTR. FINALS` — the shared uppercase plate set.

### Wiring

`Cup._draw_groups` arms `group_stage.pending_group_draw` when it seeds the groups;
`Cup.take_group_draw` hands the six boxes over exactly once; `Career._queue_group_draw` puts
it on the same hub-interrupt queue the knockout card uses, gated on the manager's club being
in the competition; `Main._pop_cup_draw` resolves each club's PAISES code and mounts the
form. It plays no reveal: the one-by-one cadence is witnessed only on the knockout grid, so
the group card shows the finished draw rather than inventing an animation for it.

## A SHIPPED STRING CORRECTED — `QTR. FINALS` keeps its full stop (s88)

`draw_round_plate` normalised `QTR. FINALS` to `QTR FINALS`, citing the EXE block at VA
0x652ffc. That block is the **COCA-COLA CUP's own** (it starts `COCA-COLA CUP` at 0x652fe4),
and the Coca-Cola Cup's own witnessed quarter-final draw renders the plate WITH the dot
(`keep_0111_cup_draw.png`, proman14, 0 px), as does the European Cup's
(`manutd_s1_eurocup_qtr_finals.png`). The plate is drawn from the SHARED uppercase set at
0x652ab0. So the port printed a wrong string on every quarter-final card it ever raised.
Fixed, with `Career`'s European `qtr_label` moved from "Quarter Finals" to "Qtr. Finals";
gates `test_cup_draw_then_play`, `test_refrun_findings`, `test_europe`.

Recorded with it: the U.E.F.A. Cup has **two** witnessed title spellings on this screen —
`U.E.F.A. CUP` on `p0747` (1/16 FINAL) and `UEFA CUP` on `manutd_s2_uefa_1_32_finals.png`
(1/32 FINALS), both at 0 px, both strings present in the EXE. What selects between them is
not reversed.
