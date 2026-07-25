# The SORTEO screen — the cup DRAW (frame-exact, 2026-07-24)

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

## Wiring

`Main._show_cup_screen(bracket, key, title)` mounts it for **every knockout round** of the
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

* **The two long value cells** in the bottom-left panel are empty in all three frames.
  Their populated state is unknown, so they stay empty. The `flecha azul/verde` arrows
  the EXE loads are presumably theirs; exported, unused.
* **MANO0..7 and BOLA0..3** — the hand and ball the EXE loads for this screen appear in
  no captured frame. Exported, unused.

  **2026-07-25 hunt, negative result — recorded so it is not repeated.** A live Coca-Cola
  Cup ROUND 2 draw was reached twice on a driven career and filmed at 25 fps
  (`tools/re/wine/film.sh`). What was ruled out:

  * **The screen does not animate on open.** 20 s of film from ~1 s after the screen
    appeared: the ONLY changing pixels in the whole 640x480 frame are x503..528 y442..462
    — the CONTINUE button's spinning football. The drum is a still.
  * **CONTINUE does not run the draw.** Clicking it (551, 451) cross-fades straight out to
    the hub. In 350 filmed frames the only non-spinner change is that 5-frame wipe.
  * The tie panel bottom-left has TWO states: **empty** (this draw, ties already listed in
    MATCHES) and **populated** with kits, club names and 1ST/2ND LEG stadiums (a week-1
    draw). So the panel is a per-tie detail view, not the drum's output.

  Still untried, in order of likelihood: the red **FINISH** button (405, 451), a click on
  the drum art itself, and selecting a MATCHES row. Also possible the animation runs only
  the first time a competition's draw is raised in a career, i.e. it must be caught on the
  very first CONTINUE that opens it. The harness is ready either way — `cup_draw` is
  parked out of `screens.json` into `screens_parked.json`, so a draw reads as UNKNOWN and
  `autodrive.py` films it at 25 fps automatically.
* **The CONTINUE ball's lit/unlit rule.** Frame 74 is dark, frame 75 is green, frame 10
  differs again; the trigger is unknown, so the chrome bakes frame 74's phase and the
  differ excludes that rect. This is the only exclusion.
* **The drum's frame rate** (12 fps is ours) and **which BOMBO frame a draw starts on**.
* **The European GROUP phase.** It is not a knockout draw. It has its own screen — RESULTS
  → **EURO. LEAGUE** — now captured and fully specified in
  [`euro_league_screen_re.md`](euro_league_screen_re.md); until it is built,
  `Main._show_cup_group_placeholder` keeps the old placeholder.
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
