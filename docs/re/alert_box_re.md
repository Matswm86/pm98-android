# The hub "PREMIER MANAGER 98" alert box — reversed from MANAGER.EXE + frames

The original's modal message box over the MANAGER MENU hub: transfer signings
("McClair has been signed by Liverpool.", frame `093_164659`), offer rejections
(two-line, `149_164911`), and every other `_toast`-class notice. Also observed
in frames `080/154/205/231` (+ `094` mid-zoom, `182/205/231` other runs) — six
distinct box widths, which is what pinned the generative caption rule.

Build artefacts: `tools/re/build_alert_chrome_from_frames.py` (bake + kill
tests) → `app/art/screens/alert/`; renderer `app/scripts/PMAlert.gd`; host
`MenuScreen.alert()` (queue + modal input + zoom). Parity pairs `alert_093` /
`alert_149` in `shot_entry_parity.gd` / `diff_entry_parity.py`.

## EXE anchors

- `FUN_005e5050` — public raise-message-box entry (≈50 call sites). Args
  `(mgr, title, msg, buttons, 0, 0)`; brackets `FUN_005c52b0` (base ctor,
  vtable `0x639888`) / `FUN_005c5410` (dtor). The title arg is the global
  `DAT_00662da0` → "PREMIER MANAGER 98" (`0x6630a8`).
- `FUN_005f9070` — measure + layout ctor: measures the TITLE with **Indust18**
  and the MESSAGE with **Proman10** (`FUN_005e3c30`), content width =
  `max(title, msg)`, floored at **0xA0 = 160**; centres on the parent rect;
  loads the icon `dat\icoexcl.bmp` (`FUN_005c06d0`); creates the button from
  the per-language table at `0x6669a0` (`Aceptar/ OK / Yes / No / Retry/
  Ignore/Cancel`, flag bits 1/2/4/8/16/32 — the alert passes 1 = OK only) and
  anchors it at `[w-6, h-6]` (bottom-right, exclusive); sets the caption text
  per language (`0x63a418 + lang*0x38`).
- `FUN_005c5fd0` — dialog transition engine; **case 5/6 = the zoom**: the box
  grows from its centre in steps of `max(1, (h/2)/15)` px, one step per ≥16ms
  tick (`timeGetTime` pacing) — the finished dialog is blitted scaled
  (StretchBlt model). Frame `094` catches a replacement alert mid-grow.
- Message strings live in `.data` with **explicit `\n`** line breaks (e.g.
  `"%s, player %s%s,\nhas rejected your offer."`) — there is NO auto-wrap.
  The signing message is `"%s has been signed by %s%s."` (no fee).

## Geometry (frame-verified on all six boxes)

Every box centres on **(317, 237)** (641px-frame coords; our design space uses
the same values). `w = msg_ink + 31` rounded UP to even, where `msg_ink` = the
longest line's ink extent (last glyph's last ink column + the 3px shadow
overhang) — NOT the advance sum; content floor 160 (`Game saved` → w 192).
`h = 72 + 10·lines`. Confirmed: 093 ink 257 → 288×82 at (173,196); 149 ink
188 → 220×92 at (207,191).

```
2px black border all round
caption interior 24 rows:
  icon ICOEXCL.BMP 24x24 at inner-left, full height; 2px black separator
  field light-blue (42,63,170); dark tiles (0,0,128) rows 5..18 (14 rows)
  title strip 127px wide, left = box_x + w/2 - 50  (centred AFTER the icon:
    icon 26px at left ⇒ title centre = box centre + 13)
2px black divider
body white; 4 gradient rows under the divider:
  row0 (100,100,100)/(114,114,114)  ← (x+y)-parity dither, SCREEN-anchored
  row1 (144,144,144)
  row2 (192,192,192)/(170,191,170)  ← parity dither
  row3 (220,220,220)
OK button 39x16 at (w-45, h-22)   [= the EXE's w-6/h-6 exclusive anchor]
2px black bottom border
```

## Caption checker rails (fitted rule, 12/12 rails pixel-exact)

From EACH box edge toward the title field: tiles of width `W0, W0-step, …`
separated by gaps `1, 2, 3, …`, clipped mid-tile where the field begins.

```
W0   = round(R / 10.5 + 6.2)        R = rail width in px
step = 2 if W0 >= 16 else 1
```

Fitted on 9 observed rails (R = 30..132, W0 = 9..19; the R=132/131 pair is the
only step-2 case). The EXE's painter fn is NOT yet located — outside R∈[30,132]
this is extrapolation. Kill test: `build_alert_chrome_from_frames.py` asserts
byte-exact reproduction of all six captions (both rails each) on every bake.

## Title strip noise

The 127×24 title strip (light field + white Indust18 "PREMIER MANAGER 98") has
constant glyphs but the field behind them speckles RANDOMLY per draw between
four blues {(42,63,170),(30,52,98),(20,0,90),(0,0,128)} — different even
between same-position instances, 6–26% of strip pixels. Baked as the per-pixel
majority of the six instances (`alert/title.png`); the parity diff tolerates
blue↔blue mismatches inside the strip only (`NOISE_ZONES`).

## Message text

Proman10 (bold double-strike is baked into our extracted glyphs — both frames'
ink matches our font 1:1 at the pen). Left-aligned block, all lines at the same
pen; `pen_x = 320 - ink//2 - (1 if ink even else 0)`; first line's glyph-cell
top = body_top + 6; line pitch 10.

**Shadow (the one un-reversed detail):** a soft down-right halo dithered
through the grey ramp {144/160·checker, 192, (192,220,192), 220, (215,190,220),
240, (255,251,240)}. Offset histograms resolve ~2×2-spread diagonal layers but
no pointwise offset→colour model survives all pixels (462/1950 violations —
likely a smeared/sequential stencil). The app approximates: three layers at
(+k,+k)+(+k,+k+1), k=3(220)→2(192)→1(144/160 screen-parity checker), ink last.
Result: message INK pixel-exact; the halo differs on ~730–980 px/box, all
within the ramp. The parity diff tolerates halo↔halo pairs inside the body
text zone only, capped (`HALO_ZONES`, cap 1500) so a missing shadow still fails.

## OK button

39×16 framework button; `alert/ok.png` = 093's NORMAL state (black " OK "),
`alert/ok_hot.png` = 149's HOT/pressed state (white label). The face dither is
(x+y)-parity anchored: each sprite is phase-exact at its source parity (093
even, 149 odd); the opposite parity drifts one dither step — sub-pixel-class,
undocumented in any frame pair we can stage, accepted.

## Modal dim + drop shadow

While the alert is up the whole hub is palette-remapped darker. The clean/dim
frame pair 095/093 gives an **exact 1:1 RGB LUT (215 colours, zero ambiguity)**
→ `alert/dim_lut.json`; `menu_bg_dim.png` is menu_bg pre-baked through it
(nearest-key fallback for colours outside the pair's coverage). Dynamic hub
draws route through `PMAlert.dim_color` / `dim_texture` (PMChrome.set_dim);
non-palette colours fall back to ×(0.63, 0.63, 0.65).

The box casts a +5,+5 drop shadow (an L-band right + below). Its remap is
**per palette INDEX**: keyed by RGB it stays ambiguous (22/57 colours, e.g.
white → 114 or 100 ≈55/45), so it is UNRECOVERABLE from RGB frames alone. The
app approximates the band with a 45% black overlay (matches the observed mean
attenuation); the parity ROI excludes the band. `alert/shadow_lut.json` keeps
the observed most-common map for a future exact pass (needs the palette-index
framebuffer, i.e. the EXE painter).

## In-app wiring

- `MenuScreen.alert(msg)` queues; OK (modal-only input) pops the next message,
  each growing in over ~0.25s (15 steps); the 094 replacement-zoom reproduced.
- Main: hub SAVE → "Game saved"; bye-week OPPONENT → "No match this week
  (bye)"; TEAM OFFER accepts → the EXE signing message (title-cased names,
  `PMChrome.title_case_name` — now with the Mc-fix: "McClair").
- `Main._toast` (green-screen footer) remains for non-hub screens only.

## Open items

- The caption tile painter + shadow stencil in the EXE (would replace the two
  fitted/approximated pieces above with exact code).
- Alert triggers beyond signings/rejections (news-class events on CONTINUE)
  as they get RE'd; the 149-class rejection alert on returning to the hub
  after a MAKE OFFER is not yet wired (offer resolution timing differs).
- Dismissal animation un-evidenced (no frame shows a shrink-out; the app
  closes instantly).
