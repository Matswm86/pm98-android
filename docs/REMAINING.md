# PM98 Android — remaining-work inventory (refreshed 2026-08-02)

## 0a-s90. Closed 2026-08-02 (session s90) — THE 0x20 EDGE PASS SHIPS AT 0 px, AND IT WAS SITTING ON A PALETTE BUG

### 1. ⭐ THE 1-px ON-SPRITE KIT EDGE — CLOSED, and the group draw with it

s89 left one instruction: *score the pass against the PORT's own render of that screen,
with the club ids it actually feeds, before drawing any conclusion.* Done. The conclusion
is a close, and the route to it went through a defect that had nothing to do with the pass.

**The sprite identification was never wrong.** `Main.gd`'s CUPDRAW shot already feeds group
A as 1076 / 1003 / 1223 / 1147 — Sporting Port., Real Madrid C.F., Anorthosis, W.Lodz, the
four names printed on the frame — and scoring against those four files reproduces s89's
own 396 px exactly. The best-match search had been picking the right sprites all along; what
s89 read as "no sprite gets under 74 px" was two other faults stacked.

**Split by the sprite's own alpha, they come apart:**

| | on-sprite | off-sprite |
|---|---|---|
| Sporting Port. (1076) | **82** of 221 | 53 of 119 |
| the other three | 33 / 33 / 34 | 54 / 53 / 54 |

* the ~54 px OUTSIDE each silhouette are a dithered drop shadow the port did not draw at
  all — `0x5c0688` is a `0x20` site and `FUN_005cbea0` runs the `FUN_005d6590` spread
  AFTER the edge whenever `thr != 0`, so this widget paints BOTH passes;
* Sporting's extra 49 are a **PALETTE bug**: `ridi/1076.png` renders `(66,104,44)` where
  the frame shows `(17,127,43)`, and those are palette **index 120 in two different
  tables**. The RIDIESC DIBs carry no colour table, so
  `build_match_header_from_frames.py` decoding them through the shared VGA table at
  `DAT.PKF +0x5CA` was the identical mistake `export_flags.flag_palette` had already
  documented and fixed for the MINIBAND flags. **21 of 256 entries differ; 91 of the 476
  kits use one of the 21.** Re-baked through `flag_palette()`: Sporting 82 -> 31, the other
  three unmoved, knockout kit lists 68 -> 56 and 64 -> 56, EURO LEAGUE groups B/C/F
  107 -> 104 / 132 -> 114 / 117 -> 116, and nothing anywhere regressed.

**Then the pass, scored on the port's own render** (`probe_groupdraw_edge_render.py`):
345 plain -> 256 edge-only (on-sprite 131 -> 42) -> **0 px at edge + spread(thr 0x20,
cap 0x80)**, on all four kits, 884 sprite px and 476 background px. `thr`/`cap` are pushed
as REGISTERS at this site so they cannot be read off the call; the sweep is over byte values
the other sites attest and the frame picks by a wide margin (0 against 10 for the nearest
neighbour on either axis, 250+ two steps away). The ORDER is the decompile's — edge first,
spread reading the edge's own output — and running it any other way scores 102 at best.

**Shipped:** `PMShadow.edge_mask` / `edge_blit` / `edge_texture`, `app/data/aliasing.bin`
(sha256 `401e3411…0636`), `CupDrawScreen._group_kit` / `._group_flag`. The MINIBAND flags
take the same pass, 37 -> 4 px. `diff_cupdraw_parity.py` loses its four KIT exclusion rects
and the whole 640x480 group-draw frame is **5 raw px**, against 434. All 45 CI tests pass.

### 2. THE M5 GOAL-2 CAPTURE — the run-up bug is fixed and the window is streaming

s89's run died on the watchpoint REMOVE; that is gone, and the run-up reproduced its 17,298
stops to clk 2836 exactly. Two pieces of tooling the window needed and did not have:

* **`PM98_CLK_TRACE=1`** (`m5_rsp_capture.py`): stay on the CLOCK watchpoint for the whole
  window and bank one cheap row per write instead of 22 player rows. The full-row rate s59
  measured puts 2837..8469 at over half a day; this is hours, and it carries the SCORE, so
  it answers "at which clock did the reference score goal 2" without the expensive capture.
* **`resume_watchdog.py`**: `autoresume.py` reads `/proc/<lpid>/mem`, which is Yama-blocked
  here, and the RSP stub takes ONE connection which the capture holds — so a WATCH segment
  pause during a capture had no driver at all (s59 stalled at clk 2837 for exactly this and
  was stopped by hand). The watchdog watches the capture's own progress LOG and clicks KICK
  OFF when it goes idle. Point it at the log, not the jsonl: the run-up banks no rows.

**Measured, and it corrects a tempting shortcut**: `m5_clktrace_diff.py` states plainly that
per-tick seed equality is NOT a divergence test — the clock is written 6 times per tick and
the tick carries ~33 rand() draws, so the trace samples under a fifth of the stream. What
the trace does show is structural and real: at clk 2837 the original writes the clock 65
times where the port takes 433 outer steps, and the goal-1 seed `0x40877acf` is in the
intersection. The two agree at the goal and pace the post-goal restart completely
differently.

## 0a-s89. Closed 2026-08-02 (session s89) — THE CUP-DRAW GATE IS THE ORIGINAL'S OWN, AND THE EDGE-PASS TABLE IS OUT OF THE RUNNING GAME

### 1. ⭐ THE CUP DRAW'S PARTICIPATION GATE — READ, not declared

s88 wrote "⚠ do not plan a sixth drive before reading the binary", because five career
drives had been planned around a rule that was the PORT's own: `Career._queue_cup_draw`'s
comment said *"DECLARED OURS: no frame shows what the original does for a non-participant"*
and the refs README restated it as fact. **It is read now, and the port is right.**

The screen is `FUN_004d9a00` (`0x4d9a00..0x4dc31b`, `ret 0x1c`), found by recursive descent
(`tools/re/funcs.py`) rather than by a call scan — s87's range `0x4da000..0x4db000` is the
MIDDLE of one 3,038-instruction function, and the only route to the `GROUPS` xref is the
six-arm switch at `0x4d9aca`. The identification is a string list, not an inference: FINISH,
CONTINUE, GROUPS, MATCHES, 1ST LEG / 2ND LEG / MATCH / REPLAY, SEMIFINAL 1 / SEMIFINAL 2 and
every `img\sorteo\frames\*.bmp`.

Before it draws anything it scans the draw. Two arms — the knockout one walks the round's
TIE array (stride `0xbc`, club ids at `+0x38`/`+0x3a`), the group one walks a flat club-id
WORD array — and each resolves every club and tests **`club + 0x5c != 0xffff`**, the same
human-managed predicate `FUN_0057d2d0` gates club news on. Then:

    0x4d9b24  test ebx, ebx / jne 0x4d9b2f      ; a managed club is in this draw -> draw it
    0x4d9b28  xor eax, eax / jmp 0x4dc2fe       ; otherwise return 0 and paint NOTHING

The port tests `pd.players.has(club_id)` — the drawn round's own player list — which is the
same test on the same data. **So a SEMIFINAL or FINAL draw genuinely cannot be captured by
driving any career to April: the manager's club has to BE in that semifinal.** The five
drives were not mis-framed, only unlucky. Probe `tools/re/probe_cupdraw_raise_site.py`,
record `docs/re/cupdraw_screen_re.md` §"THE PARTICIPATION GATE".

Read with it, and NOT built: `SEMIFINAL 1` / `SEMIFINAL 2` are drawn at `0x4dbee5` /
`0x4dbf49` in Proman12, guarded by "the round has exactly two ties". The labels and their
sites are now known; there is still no witness frame to render-diff, so they stay unbuilt.

### 2. ⭐ THE 0x20 EDGE PASS — the table is IN HAND, out of the running original

s88 left it "one runtime-built table away". Two of its numbers are corrected and the table
is extracted.

* **The code is 13 bits and the table is 8,192 entries**, not 12 and 4,096: `FUN_005d60a0`
  makes twelve comparisons and then `stc; rcl ebx,1`, hardwiring bit 0 to 1.
* **`FUN_005cbea0`'s arguments are not (flags, thr, cap).** `arg1` is the SPREAD's threshold
  and gates whether the spread runs at all, `arg2` its cap, and the alpha is a much later
  argument. A `0x20` site with `arg1 != 0` runs BOTH passes, edge first.
* **`letras.bmp` — the generator's input — ships in NEITHER source.** Not loose, not in any
  of the six PKFs, not on `pm98.iso` (its two `letras` hits are the EXE's own literal), not
  in the RAR; and no `dat/aliasing.dat` in either. The running game does not write the cache
  either: after a full boot + career + match nav, `dat/` is still empty.
* **So it was read out of the process.** `m5_rsp_capture.py` now dumps `0x6b5890..+0x2000`
  and the run-once guard on the RSP connection it already holds. Guard 1; 3,921 of 8,192
  non-zero; 223 distinct. Bytes + argument: `tools/re/refs/aliasing-2026-08-02/`.
* **It is provably the generator's own output**, against three predictions of the
  transcription (`tools/re/build_aliasing_table.py`): rotation invariance at **0 violations
  in 8,192**; the `count = 1` init showing up as 616 complementary pairs summing to exactly
  127 (`255//2` and `0//2`); and monotonicity in popcount from 1.0 to **253 at thirteen bits**.
* **253, not 255, is the finding**: every fully-enclosed pixel is nudged 2/256 toward the
  destination — the one thing a spread cannot do, exactly where s84 measured 415 of 449
  residual px, and exactly the magnitude that flips a pixel through the dither.

**Scored, and NOT closed.** `tools/re/probe_groupdraw_kit_edge.py` runs the pass against the
only kit oracle with a WITNESSED destination (the group draw — five of six boxes are empty
and pixel-identical, so what is under group A's kits is readable off group C's) and with no
free parameter takes the four kits from **396 wrong pixels to 349**. Directionally right.
Record: `docs/re/shadow_blit_re.md` §"The 0x20 arm, RUN".

### 3. NOT done in s89, said plainly

* **The edge pass is not shipped.** `PMShadow` still implements only the `0x10` spread.
  Determinism was the gate and it is CLEARED — three independent boots, one of them fully
  isolated, all dump the same 8,192 bytes — so what remains is the render-diff: the probe scores against a
  best-match sprite rather than the port's own render of that screen, and no sprite in
  `app/art/kits/ridi` gets those cells under 74 px even with the model applied.
* **The M5 goal-2 capture RAN but did not finish.** The prerequisite s87 named is no longer
  missing tooling: `m5_rsp_capture.py` gained a clock-watchpoint RUN-UP (the seed watchpoint
  traps ~33 times a tick, so reaching clk 2837 cost ~94,000 stops of pure fast-forward and
  is why this had never been attempted) and its silent 40,000-stop cap is now
  `PM98_MAX_STOPS`. What it captured is a PREFIX of 2837..8469, not the whole window.
* **A SEMIFINAL / FINAL cup draw** — still a capture, and now known to require a surviving
  club (§1). No sixth drive was run.
* **The real-device pass** — still needs Mats and a phone.

## 0a-s88. Closed 2026-08-02 (session s88) — THE GROUP DRAW IS BUILT, THE KIT-EDGE PASS IS IDENTIFIED, AND THREE BANKED FRAMES WERE FILED UNDER THE WRONG NAMES

### 1. ⭐ THE EUROPEAN CUP **GROUP DRAW** — the biggest carried BUILD item, BUILT at 1 px

s87's newest open item was a screen FORM the port did not have. It is built, wired and gated,
and it reproduces its binding frame at **1 differing pixel** outside the CONTINUE ball and
the eight kit/flag sprites that carry the un-reversed edge pass (434 raw px, 1 net).

One frame was enough because the widget repeats six times and five of the six are EMPTY:
measured, the five empty boxes' ROW BANDS are **pixel-identical to each other (0 px)**, so
group C's band IS the empty-row widget and is what group A's populated band was cleared with;
their headers differ **only in the letter glyph**, so the plate under a letter is whatever box
does not ink that pixel. And the frame agrees with the already-baked `chrome_grid.png` at
**0 px** across the whole left panel outside the picture, the two text plates and the leg
plates, which is what makes taking the plate texture from that bake legitimate.

Geometry, all measured: boxes at x 326/483 and y 55/180/305, 149x121; four rows on a 25-px
pitch; the kit is **RIDIESC 17x20** at box-local (7, row+2); the club name is **proman10**
centred on box-local field sum **177**, ink alternating with the band exactly as the GRID
form's does; the letter is proman12 white at box-local (119,4); the GROUPS plate is proman12
BLACK centred on 955. Chrome `tools/re/build_groupdraw_chrome_from_frame.py`, geometry
`tools/re/probe_groupdraw_frame.py`, gate `test_cupdraw_screen.gd` §7 + `test_europe.gd`.

Wired, not just drawn: `Cup._draw_groups` arms the card when it seeds the groups,
`Cup.take_group_draw` hands it over exactly once, `Career._queue_group_draw` puts it on the
same hub-interrupt queue the knockout card uses (gated on the manager's club being in the
competition) and `Main._pop_cup_draw` mounts it. It plays no reveal — that cadence is
witnessed only on the knockout grid.

**Two measurements recorded and NOT explained away:** the MINIBAND flag is blitted from its
**row 1, nine rows** (at row+13 the frame is flat background across all fourteen columns on
all four rows), and the frame's round plate reads `1/8 FINAL` — a round of sixteen — against
this port's eight-club knockout, which is a statement about the competition's FIELD SIZE and
is left as a discrepancy rather than hardcoded away.

### 2. ⭐ THE 1-px ON-SPRITE KIT EDGE — IDENTIFIED. It is the OTHER arm of the blit

Six sessions called it unlocated and attacked it by fitting models to pixels; s87 located the
call site. s88 reads what that call site actually *does*, and the answer is that
`PMShadow` implements the wrong arm.

`FUN_005cbea0` branches on `param_1`: `& 0x10` runs `FUN_005d6590`, the IIR SPREAD the port
models. `& 0x20` runs **`FUN_005d60a0`**, which is not a spread at all — it walks the mask
and, for every non-zero byte, builds a **12-bit neighbourhood code** from twelve comparisons
of `alpha >> 8` against its neighbours and replaces the byte with
**`DAT_006b5890[code] * 2 + 1`**. That is an EDGE classifier producing partial alpha ON the
sprite, blending it toward the DESTINATION — which is exactly the residual's shape, and the
one thing a spread (outside the silhouette only, toward black only) can never be.

And the kit widget is a 0x20 site, read rather than inferred: `0x5c0607` reloads the flags
word from record `+0x90`, which is the `0x20` that `FUN_005c0d50(bank, list, 0x20, 0x32,
item)` stored on all 90 RIDIESC fetches. The same reading names s87's `+0x64` / `+0x66`: they
are the widget's own **thr and cap**.

**What is left is one table, and it has a NAME.** `DAT_006b5890` is above `.data`'s raw end,
so it is built at runtime — by the graphics-init at `0x5c9760..0x5c9a02`, which looks for
**`dat\aliasing.dat`**, reads 8192 bytes straight into it if present, and otherwise COMPUTES
those 8192 bytes (`sum / count` per 13-bit code, out of accumulators fed with `0xff - d`) and
**writes the file back out as a cache**. That file ships in neither `pm98.iso` nor the RAR,
because it is generated. So the next step is either to let the original write it (create
`dat/` in the wineprefix — done — and drive far enough for this init to run; the title screen
is not far enough, tried) or to transcribe the generator at `0x5c98e9..0x5c99ad`. The
group-draw kits (33 px of 221) and flags (8..11 of 140) are the ready-made oracle.
Record: `docs/re/shadow_blit_re.md` §"Every call site, read — and the 0x20 arm".

### 3. ⭐ `PMShadow.THR` — s87 corrected the note, s88 closed it with all 74 sites

`tools/re/probe_shadow_sites.py` byte-scans for the 74 call sites and decodes each caller
forwards with capstone (a backwards byte walk cannot do it — the instruction before the call
is a `mov ecx`, and this image's linear sweep desynchronises). **65 of 74 push all three
leading arguments as immediates, in SEVENTEEN distinct (flags, thr, cap) triples.** The modal
one is `(0x10, 0x40, 0xff)` x23; `thr = 0x21` belongs to exactly the two sites this leaf was
reversed from (`0x50f9e3`, `0x50fba1`) and to no other. **Sixteen sites are `flags = 0x20`**,
i.e. the edge arm above.

### 4. ⭐ THREE BANKED FRAMES WERE FILED UNDER THE WRONG NAMES — and now a tool reads them

`tools/re/probe_cupdraw_labels.py` crops each SORTEO plate's ink mask and XORs it against the
port's own BMFont render, so a label is a 0-px match or it is reported unresolved. Run over
the s87 corpus it found **three of the six s1 frames misfiled**: the file called
`manutd_s1_eurocup_qtr_finals.png` is an **F.A. Cup ROUND 4** draw, `manutd_s1_facup_round3.png`
is the **European Cup QTR. FINALS**, and `..._facup_round4.png` is F.A. Cup ROUND 3. Renamed;
the s87 FINDINGS survive (every witnessed European round is still two-legged) but the table
pointed at the wrong files, which is how the next session measures the wrong pixels.

**And it caught a shipped defect.** `Cup.draw_round_plate` normalised `QTR. FINALS` to
`QTR FINALS`, citing the EXE block at VA 0x653dfc. That block is the **COCA-COLA CUP's own**
(it starts `COCA-COLA CUP` at 0x653de4) — and the Coca-Cola Cup's own quarter-final draw
renders the plate **with** the dot, as does the European Cup's. The plate comes from the
SHARED uppercase set at 0x6538b0 (`SEMIFINALS` / `QTR. FINALS` / `1/8 FINAL` / `1/16 FINAL`),
so the port printed a wrong string on every quarter-final card it ever raised. Fixed, with
`Career`'s European `qtr_label` moved from "Quarter Finals" to "Qtr. Finals".

Recorded with it: the U.E.F.A. Cup has **two** witnessed title spellings on this screen —
`U.E.F.A. CUP` on `p0747` and `UEFA CUP` on `manutd_s2_uefa_1_32_finals.png`, both at 0 px,
both strings in the EXE. What selects between them is not reversed.

### 5. NOT done in s88, said plainly

* **A SEMIFINAL / FINAL cup draw** — a FIFTH drive failed. The s87 career was resumed at
  30 January 1999 (Premier week 26, season 2) and Manchester Utd went out of the F.A. Cup
  again; the career rolled into a 1999/2000 preseason on a PRESEASON board variant the
  driver had never seen (taught as `preseason_rivals`), and the drive's own preseason rule
  then dismissed it to the title screen. The frames it did bank are the ones above.
* **The M5 goal-2 divergence** — untouched, and for the reason s87 named: it needs the wine
  box to itself and the box was holding the cup-draw drive. Still the largest carried RE item
  and the command is still in `docs/re/M5_S85_WATCH_PLAYSTATE_FULLTIME.md`.
* **The 0x20 edge pass itself** — identified, not implemented. One runtime-built table away.
* **The real-device pass** — still needs Mats and a phone.

## 0a-s87. Closed 2026-08-01 (session s87) — B9 CLOSES, THE CAPABILITY LADDER IS READ OFF THE BINARY, AND TWO CARRIED ITEMS TURN OUT NOT TO BE CAPTURE PROBLEMS

The theme: three of the carried items were filed as "needs another career" or "deferred
again", and none of them was. Two came out of `MANAGER.EXE` and one came out of a document
that was already in the repo.

### 1. ⭐ B9's ROSTER ROW — 1,816 px REPORTED → 0 px GATED, and it took five defects with it

`diff_youth_parity` now GATES the `youth_b9roster` pair, so all SEVEN youth pairs are at
0 px. Each defect was measured off the s86 witness rather than argued:

* the row's PLATE and per-cell GRID are the frame's own pixels — two rules, nine dividers,
  the black-bordered ROL box, and a LEFT CHIP that differs from the empty row's by **162 px
  in that same frame** (`tools/re/build_youth_rowgrid_from_frame.py`);
* **AV is the four-attribute AVERAGE, not CA** — the row reads 20/19/20/21 with AV 20;
* the row's text baseline is **+3** inside the plate, not +2;
* NAME starts at x62 (not 59), WAGE centres on 359 (not 358), ST on 212 (not 211);
* the ROL icon is **`camrol01`**, matched at 0 mismatched pixels against all eighteen.

### 2. ⭐ AND IT SETTLED THREE THINGS THE PANEL ABOVE IT HAD LEFT OPEN

* **The PLAYERS FOUND cell grid belongs to the POPULATED ROW, not the slot.** The roster
  witness is the second frame that was missing — the same career with the panel EMPTY. The
  two differ inside the list rect by **1,270 px, ALL in slot 0's grid band**, and all six of
  the idle frame's plates are flat. So `found_list.png` is the idle widget cut verbatim and
  every populated row stamps its own grid, slot 0 included.
* **The panel's IDLE state is the widget, not nothing.** The port drew the list only when a
  prospect was on it, so a scout who had already delivered left a bare black box where the
  original shows the header row, six plates and the scrollbar.
* **The half star has TWO parities.** The bar alternates two sprites and the half glyph takes
  the parity of the cell it lands on; the port carried one per colour and drew it at both.
  Four glyphs now, each with its own named witness.
* **An UNAVAILABLE LED keeps the baked pink-hatched chip** — the port stamped the dark-maroon
  "available" sprite over all six the moment a scout existed.

### 3. ⭐ THE SEARCH CAPABILITY LADDER IS READ, NOT FITTED — no more careers needed

s86 left the rungs between 1.5★ and 4.5★ as "a career at 2.0 / 3.0 / 3.5 is the capture that
fills them". They needed no capture. It is an eight-entry **jump table at `0x53d520`**,
dispatched on the scout's 1..10 quality byte at the tail of the YOUTH TEAM screen's
constructor, with q ≥ 9 disabling nothing and every arm falling through the ones below it:

    q 1-2 HANDLING | q 3 +TACKLING | q 4-5 +PASSING | q 6 +DRIBBLING
    q 7-8 +HEADING | q 9-10 +SHOOTING (all six)

which reproduces all five witnessed scouts exactly. The same read names the six widgets (a
`0x418`-stride array from `[esi+0xa68]`, identified by the coordinates their own constructors
push), proves `FUN_005bf8c0(0, 1)` is the DISABLE call against frame 087, and shows the
YES/NO value cell is bit 7 of the widget's `+0xac` — availability, never selection.

s85's other half is answered too: `operator_new(0x28)` + vtable `0x632fc8` happens at exactly
two sites and **NEITHER is a hire** — `0x53cd8f` is the screen's own constructor and
`0x57c7f6` is the SAVEGAME LOAD path. The flags are selection, they start at zero, and only
an LED tap sets them. Gate: `test_youth_caps.gd`, 61 checks.

### 4. ⭐ SIX MORE CUP DRAWS — and the leg plates are a COMPETITION axis too

A Manchester Utd career driven from scratch banked six frames, two of them new kinds. s86's
"ROUND 2 is two-legged, the rest are not" is right about the **Coca-Cola Cup** and does not
generalise: the **EUROPEAN CUP's `QTR. FINALS` reads 1ST LEG / 2ND LEG**. The port already
builds European brackets with `legs: 2`, so this CONFIRMS it — but the corpus note said
otherwise and would have led the next session to "fix" it the wrong way.

Season 2 of the same drive added **European Cup `ROUND 2`** and **U.E.F.A. `1/32 FINALS`**,
both 1ST LEG / 2ND LEG — so EVERY witnessed European round is two-legged. Note also that
season 2's European Cup raised a `ROUND 2` draw and not the group form, so the group phase is
not every season's entry route.

🆕 **NEW OPEN ITEM — the European Cup GROUP DRAW is a screen FORM the port does not have.**
`manutd_s1_eurocup_groups_1_8_final.png`: the header plate reads **GROUPS** in black on
white, under it six group boxes in a 2×3 grid each with a green `GROUP <letter>` header and
four `kit | club | flag` rows, the bottom-left tie card **entirely blank** (leg plates
included), round plate `1/8 FINAL`. The port raises no draw at all while the group phase is
live (`Cup.draw_next_round` is a deliberate no-op). Frame banked; not built.

### 5. `KnockoutScreen` → `PMShadow` — KILLED, not deferred an eighth time

The proposal is WRONG and both documents that kill it were already in the repo. `PMShadow`'s
own header, derived from `FUN_005cbea0`: the mask is only ever partial OUTSIDE the silhouette
and every shadow pixel is the destination blended toward BLACK. s62 + s85: what is left on
the bracket kits is a highlight on the sprite's own TOP/LEFT edge taking LIGHT palette
entries, **415 of 449 px INSIDE the sprite's opaque mask**. An on-sprite LIGHTENING pass is
the one thing that blit cannot be. What would revive it is named: locate the knockout view's
code — its whole RE is frame-derived and cites no VA — among the thunk's **57 call sites**,
now enumerated by byte scan.

### 6. `PCF5DAT.PKF` — the s86 handoff re-opened a CLOSED item

§7f carried "never enumerated ... may unblock the whole 3D match view". Re-measured from
scratch: exactly ONE xref in the image (VA `0x4f82ed`), `D.G.C.` present at `0xecbf` read
straight off the ISO extent, and the enumerator still finds no directory-like chain in
314,854,588 bytes. It is a CD-presence check. The 3D path's real blocker is unchanged and is
a DATA gap: the `.p3d` models are absent from both sources.

### 7. One FLAKY GATE fixed

`test_relegation_clause` failed about 1 run in 6 — **on HEAD too**, so it was not a
regression. The cause is a real engine rung on an under-specified fixture: the binary's
13-man floor sits AHEAD of the relegation rung, so a season with enough expiries renewed the
second clause-holder instead of releasing him. The fixture pads the squad with multi-year
men. 10/10 green.

### 8. NOT done in s87, said plainly

* **The M5 goal-2 divergence** (26' against 24', right team, `2837 < clk < 8469`) —
  **BLOCKED, and the blocker is the finding.** It is not a diffing job on data in hand: the
  banked oracle STOPS at clk 2837 (`oracle_dartwatch_s59_1020_2837.jsonl`), and
  `timeline.jsonl` is the `m4_poll` STRUCT poll, which can say goal 2 landed at 24' and
  cannot name a first-disagreeing frame. It needs a fresh **~5,632-frame** `m5_rsp_capture`
  over 2837..8469 on a box with **no other wine load** (the RSP stub takes ONE connection, a
  client disconnect kills the game, a concurrent `wdbg_pid.sh` fails the attach with error
  87). The exact command is in `docs/re/M5_S85_WATCH_PLAYSTATE_FULLTIME.md`. Still the
  largest carried RE item.
* **The 1-px on-sprite kit-edge pass** — **LOCATED, not closed** (§0a-s87.9 below). The rule
  is still open; what changed is that the next step is a reading rather than a fit.
* **A SEMIFINAL / FINAL cup draw** — **four** drives have now tried. s87's two seasons got as
  far as F.A. Cup `ROUND 5`.
* **The European Cup GROUP DRAW form** — newly witnessed this session, §4, not built. This
  is the biggest single new BUILD item in the repo and it has a clean witness.
* **The real-device pass** — still needs Mats and a phone.

### 9. ⭐ AND THE KIT-EDGE PASS WAS LOCATED AFTER §8 WAS WRITTEN

Five sessions called it "unlocated" and attacked it by fitting models to pixels. Three
measurements, all from the binary:

* **the knockout view's code is at `0x466000..0x4a1000`**, found from its own plate strings
  (`AGGR.` `0x653f0c`, `1ST LEG` `0x653f1c`, `2ND LEG` `0x653f14`, `REPLAY` `0x653f24`). The
  CUP DRAW screen is separate at **`0x4da000..0x4db000`** — `GROUPS` (`0x6570f8`) has exactly
  ONE xref, `0x4da6a4`. The whole knockout RE was frame-derived and cited no VA;
* **neither range calls the shadow blit.** A byte scan for `E8 rel32` targeting the thunk
  `0x4b7f60` or the core `0x5cbea0` gives **74 call sites, lowest `0x4b29c0`** — above the
  entire knockout family. Zero in either range;
* **because the knockout kit is a WIDGET.** All 90 `RIDIESC`-bank fetches end in
  `FUN_005c0d50(bank, 0, 0x20, 0x32, 0)`, and that function's neighbour **`0x5c0688` IS one
  of the 74 shadow sites** — arguments from a per-item table (`[edx + eax*4 + 0x90]`) and the
  widget's own **`+0x64` / `+0x66`**.

**Next step:** decompile `FUN_005c0d50` and the paint around `0x5c0688`, recover what
`+0x64` / `+0x66` and the `0x90` table hold, feed them into `PMShadow` with the site's own
THR/cap. s85's LUT inversion says the answer must hit **(56, 52, 64..72)** where the port
paints `(44,44,44)`.

**A shipped constant is corrected:** `PMShadow.THR = 0x21` was documented as "the same at
every witnessed site". It was, because only two sites had been enumerated. `0x4f4ee7` — a
RIDI kit blit — pushes `0x10`, **`0x40`**, **`0xff`**. THR is the spread's per-step decay, so
a different THR is a different ramp.

This also upgrades §5: `KnockoutScreen` → `PMShadow` is killed on the **call graph**, not
only on the reasoning that the blit cannot write inside a silhouette.

## 0b. Closed 2026-08-01 (session s86) — THE WATCH MATCH PLAYS AT SPEED, THE CUP DRAW'S AXIS IS FOUND, AND TWO EARLIER READINGS ARE CORRECTED

The theme is that three of the carried items were answerable from measurement, and two of
them had been closed WRONGLY because a number was read by eye instead of by pixel.

### 1. ⭐ THE POSITIONAL ENGINE NOW PLAYS AT REAL TIME — 0.58x → 0.99x, with no fidelity change

The largest carried item read *"the M5 3D / positional engine is not wired into
`MatchSim`"*. **It is wired, and has been since the M5 wire-in** — `Main` builds a
`Pm98LiveMatch` for a WATCHED fixture and `MatchSimulador.set_live` renders it, while every
unwatched fixture runs `Pm98StatMatch`, which is the routing `FUN_0044ee70` itself does on
the play-state. Wiring the positional engine into `MatchSim.simulate` would make the port
LESS faithful, and `Pm98LiveMatch`'s own header has argued that for sessions.

What was real is THROUGHPUT, and it had never been measured — "~9 min per match" is a total,
and a total cannot say whether the match plays at the right SPEED. It could not:
`MatchSimulador` needs **60 outer frames a second** and the engine sustained **34.5**.

`bench_live_match.gd` + `PM98_TICK_PROF` (new, off by default) attribute the tick, and two
passes were doing work they discarded:

* **the off-ball "lean" built a 16-row rotated grid before the guards that abort it.** The
  binary computes it at L189-220 and reaches the ball guards at L222-227; while the ball is
  carried those guards abort EVERY off-ball player, so up to 21 of 22 a frame were rotating
  sixteen 3-vectors and throwing them away. Both builders are pure, so deferring them is
  observably identical. **6,686 → 1,138 us/tick.**
* **the marker scan recomputed per-opponent constants per defender.** 11 x 11 a team, with
  the matrix column, the z, the team and both arms of the q-metric hoisted out.

**34.5 → 59.2 outer-fps**, i.e. 0.99x real time on this box. No draw order, no RNG, no
arithmetic moved; `test_9490*`, `test_assignmarker`, `test_marktarget`, `test_relmatrix` and
`test_live_match` are the gates. Record: `docs/re/M5_S86_ENGINE_THROUGHPUT.md`.

### 2. ⭐ STOPPAGE TIME WAS NEVER MISSING — it is the period-end rung, now pinned

Filed as "unrun" since s85. It is `Pm98Driver._buildup_branch`'s second half, a straight
transcription of `fn_00598740` L595-606, and the rule is the original's own: the period does
NOT end on the whistle. It ends at the first evaluation after it at which EITHER the ball has
left the 0x1e0000 (30 m) band in front of a goal OR `half/9` ticks have run out — **five
minutes** at the shipped 45-minute period, and extra time keeps that same cap against a
period a third as long. `app/tests/test_stoppage_time.gd` pins all four rungs (14 checks).

### 3. ⭐ THE CUP DRAW'S PER-ROUND AXIS — found, and the port was playing a round wrongly

`tools/re/probe_cupdraw_per_round.py` measures the animated region off three frames of ONE
round rather than guessing it, masks that plus the round plate, the MATCHES panel and the
picture box, and scores all six pairs of s85's four same-competition frames:
**ROUND 2 differs from the other three by 397 px, all of it on the LEG PLATES, and by 0 px
everywhere else.** ROUND 2 reads `1ST LEG / 2ND LEG`; ROUND 3, ROUND 4 and QTR. FINALS read
`MATCH / REPLAY`. A second career banked this session says the same.

That is not decoration — it says how the tie is PLAYED, and the port had the Coca-Cola Cup
on one competition-wide `legs: 1`, so it resolved a two-legged second round on a single
result. `Career.LEAGUE_CUP_OPTS.round_legs_by_round = {2: 2}` — the witnessed round and no
other; ROUND 1 is unwitnessed and stays unpinned. Gate `app/tests/test_cup_round_legs.gd`.

### 4. ⭐ THE SEARCH CAPABILITY MASK IS A STAR LADDER AFTER ALL — s85's reading was a miscount

s85 killed the ladder hypothesis on "two 2★ scouts, two different masks".
`tools/re/probe_youth_cap_mask.py` measures the star bar by GOLD AREA (a full glyph is a
13-px diamond, a half glyph 8 — run WIDTH cannot separate them, 4 columns against 5) and the
value cells by ink. **All three scouts previously read as "2★" measure 1.5★, and all three
carry the identical {HANDLING, TACKLING}.** There are no two same-rating scouts with
different masks.

`YouthScreen.CAP_BY_STARS` carries the two witnessed ends — 1.5★ → two capabilities,
4.5★/5.0★ → all six — and an unwitnessed rating returns `[]`, which renders exactly as the
port always did, so frame 047 stays at 0 px. Taps on an unavailable LED are refused, as
`b9_02_leds_armed.png` witnesses. The rungs between 1.5 and 4.5 are NOT invented. Gate
`app/tests/test_youth_caps.gd` (24 checks), which fails if a rung is added without a frame.

### 5. B9's LAST GAP HAS ITS WITNESS — the row's inks and columns are closed, the plate is not

The `season_youth_b9_sign` drive s84 wrote finally reached a SIGNED prospect
(`tools/re/refs/youth-roster-2026-08-01/`, Bolton W, 3 October 1998,
`Burgess 20 19 20 21 20 [ROL] £5,000 3 3`; two frames 14 months apart differ only in the
header date plaque, so one cut is enough). Three defects fall straight out of it and are
fixed: the name is **not** upper-cased, the five parameter cells are the AV column's
**(212,63,0)** (NOT their own headers' slate — the s84 "value carries its header's ink" rule
does not hold here), the money is (150,0,0) and there are **TWO** figures under the single
YEARS header, at cx **406** and **432**, where the port drew one at 418.

**Still open, and named:** the row PLATE and its per-cell GRID are still the port's own.
`diff_youth_parity.py` REPORTS the new `youth_b9roster` pair at 1,816 px over the row band
and does not gate on it — the same bake `build_youth_found_list_from_frames.py` did for the
PLAYERS FOUND widget, against this frame.

### 6. ⭐ THE CROSS-SEED SWEEP RAN — and the reason it never had is one line

`tools/re/run_match_sweep.sh` has been in the repo since s55 and every session since listed
the sweep as "unrun". It defaults to `$HOME/godot462`, which is not this box's binary
(`tools/run_tests.sh` has always used `godot4`), so it could not start. It falls back now.

**16 seeds, first 4 run twice: 16/16 reached FULL TIME on dispatch 10, 4/4 digest-identical
across two runs, 0 failures**, scorelines 0-0 to 4-2. That certifies exactly what the
harness's header says — the engine plays 90 minutes from real squads on an arbitrary seed
without stalling, and it is deterministic. It is NOT silicon parity, and the one seed that
IS compared still diverges at goal 2.

### 7. AND A NUMBER IN THE s85 RECORD IS CORRECTED

s85 reported the full-time run as "37,059 outer steps". It is **34,198** — and 34,198 on
s85's own code too, checked by restoring `Pm98Movement` / `Pm98Driver` / `Pm98Action` from
`HEAD` into a scratch copy and running both to full time. Everything else s85 recorded (both
goals, the full-time state, the 2679052131 RNG) is exact, and that A/B is also what proves
§1 changed nothing: the two runs are identical bit for bit over all 34,198 frames.

### 8. NOT done in s86, said plainly

* **The M5 goal-2 divergence** (26' against the reference's 24', right team) is untouched.
  It is a normal frontier-localisation job in 2837 < clk < 8469 and it wants a quiet box.
* **A SEMIFINAL / FINAL cup draw.** Two drives tried this session; neither reached one. The
  draw only appears for a round the manager's own club is still IN, so it is a matter of
  surviving to April, not of driving longer.
* ~~**`KnockoutScreen` → `PMShadow`**~~ — **KILLED s87** (§0a-s87.5): the blit provably
  cannot write inside the silhouette, and the residual is on-sprite. The **1-px on-sprite
  kit-edge pass** itself is still open.
* **The youth-scout HIRE-path seed.** The mask is now known to follow the rating, so the RE
  question s85 posed (where the hire seeds `+0x10..+0x24`) is no longer load-bearing for the
  render; it would settle the rungs between 1.5★ and 4.5★ without four more careers.
* **The real-device pass** — still needs Mats and a phone.

## 0aaaaaaaaaaaaaaaaa. Closed 2026-08-01 (session s85) — THE WATCH MATCH RUNS TO FULL TIME, THE CLAUSE FINDS ITS CONSUMER, AND TWO "CAPTURE" ITEMS TURN OUT NOT TO BE

### 1. ⭐ THE M5 WATCH HARNESS REACHES FULL TIME — the blocker was the PLAY-STATE

s84 filed goals 2-7 and full time as "a RUN of the harness, not a fix to it". They were
not: **the harness could not reach them.** Run once, it reported goal 1 and then breached
`WAIT_LOOP_GUARD`. Instrumented (new `PM98_WAIT_PROBE`), the picture is exact: after the
clk-2837 goal the match restarted correctly, played on to **clk 3885**, raised **dispatch
code 3** — a set-piece restart — and spun all 40,000 guard frames with the clock frozen.

Two reasons, both read out of the binary:

* the pause branch's wait loop breaks on `+0x1a19` / viewing / `+0x1a2c`-with-a-code /
  `code == 10` / `+0x1a1f`, and **its code test explicitly excludes codes 3 and 4**;
* nothing in that branch arms `+0x1a1e` either. `FUN_00593ab0` discards its driver tick's
  return and reaches the arm ONLY via the nonzero-pump skip path (@0x593b3a `test eax,eax /
  je` returns with no arm when the pump is 0).

**So a faithful play-state-4 frame with no user input genuinely cannot leave a set-piece —
which means the real game is not in play-state 4 there.** 4 is the EVENT BOARD, the state
the frame-0 dump was taken in, before the user has clicked KICK OFF. A WATCH match in
progress is play-state **2** (`FUN_005943f0`, viewing) — the state whose per-frame break IS
the WATCH pacing and the state `Pm98Outer._replay_cut` is gated on, i.e. the very draws the
s59 handoff says the WATCH path consumes and the raw loop does not.

The harness's KICK OFF click is the click that DISMISSES that board, so it now drops
`+0xfa0` to 2 on the same click. Result, for the first time:

| | port | reference |
|---|---|---|
| goal 1 | **8' Aston Villa, clk 2837, rng 1082620623** | **8' Aston Villa, clk 2837** |
| goal 2 | 26' Bolton W, clk 8469 | 24' Bolton W |
| full time | **dispatch 10, 14400 + 14400, half 1** | full time |

Goal 1 is unchanged bit for bit, so nothing here touched the window the nine oracle captures
pin — cross-checked with `PM98_FORCE_PS=2` from frame 0, which gives the identical goal and
the identical full time. **Goals 2-7 are now a RUN**, and goal 2 is the new frontier: right
team, two minutes late, i.e. a divergence to localise in 2837 < clk < 8469. Record:
`docs/re/M5_S85_WATCH_PLAYSTATE_FULLTIME.md`.

Also fixed on the way: the stall guard's flat 3-step threshold fired on a healthy
play-state-2 match at clk 0, because under the live branch one step is ONE FRAME and the
clock legally stands still for every frame that is not phase 0 (`STALL_STEPS_LIVE`).

### 2. ⭐ "FREE IF RELEGATED" — the consumer found, and it is the ONLY one

Carried since 2026-07-24 as "the clause is settled as `rec+0x10` with a 0-px checkbox render;
what it DOES on relegation is still not found". The earlier search followed the OFFER-COMMIT
path (`FUN_005889c0`) and found nothing, which is true — **the consumer is on the SEASON
ROLLOVER**: rung 3 of `FUN_0058AC90`'s release ladder @0x58ae5e. It zeroes the record's YEARS
(`+0x84`) and LEFT (`+0x85`), posts `.data` 0x662d80 -> 0x663254 to the club's news (gated by
`FUN_0057d2d0` on `club+0x5c != 0xffff`, so only a human-managed club sees it) and drops him
to the LEAVES tail, where `FUN_0058A0C0` mints him a fresh offer record — the free-agent
market.

**"Only" is a measurement.** A restarting sweep of the whole `.text` finds nine `[reg+0x7c]`
flag-test sites: this one, four word-sized tests on an unrelated class and four C-runtime
sites. And because the record is also reachable as a pointer (`rec+0x10`), the same sweep ran
on displacement `0x10` over 0x520000..0x5a0000: 23 sites, every one a list-node test or a
club-id compare against the 0x26ae/0x26de/0x26e4 sentinels. No consumer reads it either way.

So the clause is **not** an instant release on the day of relegation: it is a rung in the
CONTRACT-EXPIRY ladder that guarantees the release once the season turns over — and it sits
BEFORE the matches-to-renew rung, so a man who has met his renewal clause still walks.

**One ordering defect closed with it.** The port tested matches-to-renew before the 13-man
floor; the binary tests the floor first (0x58ae55) and the renewal clause last (0x58aebd).
Harmless while both rungs KEEP — not harmless the moment a rung between them RELEASES.
`Retirement.RELEGATION_CLAUSE_MSG` + `released_by_relegation_clause`,
`Career._manager_relegated()`, gate `app/tests/test_relegation_clause.gd` (in CI), record
`docs/re/retirement_re.md` §6. Declared: the manager's club only, the same scope as the rest
of the unmanaged-club ladder.

### 3. ⭐ THE "SEARCH CAPABILITY STAR LADDER" IS NOT A LADDER — and it is not a capture item

s84 filed it as needing "several careers at several scout ratings, the way
`ScoutScreen.REGION_STARS` was settled". Two frames put side by side kill that:

* `screenshots/original-walkthrough-2026-07-02/047_164509.png` — P. Mitchell **5.0★**: all
  six values YES, while only THREE LEDs are bright-with-a-ring and the other three are dark
  maroon. So the value is not the selection;
* `tools/re/refs/youth-caps-2026-08-01/b9_01_youth_before.png` (this session's own drive) —
  J. Casson **2★**, the first time the screen opens and **before any click**: HANDLING and
  TACKLING YES, the other four NO, and exactly those two LEDs are dark maroon while the other
  four are the PINK HATCHED art. After six taps only those two go bright — **the other four
  taps are refused**.

So the LED has THREE states — pink hatched = UNAVAILABLE, dark maroon = available and
unselected, bright + ring = selected — and the value cell is YES iff the capability is
AVAILABLE. And it is **per scout, not per rating**: J. Casson (2★) has {HANDLING, TACKLING}
and s84's C. Dewhurst (2.0★) has {HANDLING, DRIBBLING, TACKLING}. Two scouts, same rating,
different masks. Four careers at four ratings cannot answer a per-scout question.

The next step is named instead: the mask is seeded somewhere in the HIRE path onto the same
object the search builds (youth vtable `0x632fc8`, `operator_new(0x28)`, `+4` club, `+6`
quality, `+7` weeks, `+0x10..+0x24` the six flags `FUN_00575d90` ORs over). Until that seed
is reversed the port keeps the 047 rendering — which is the witnessed behaviour for every
all-available scout and is what `diff_youth_parity` pins at 0 px. A value that tracked the
LED was tried this session and **reverted**: it fails 047 by 345 px.

### 4. THE 1-px KIT RIM — a fourth model killed, and the original's own colour recovered

`tools/re/probe_kit_rim_invert.py`, two results that do not need the pass to be known:

* **the LUT is invertible.** `DAT_00675398` is indexed by `RGB565 | (parity << 16)`, so a run
  showing palette entry A at parity 0 and B at parity 1 was written as ONE colour. Group A's
  cell row y=2, x=9..12 — port a flat `(44,44,44)`, frame alternating `(70,40,80)` /
  `(46,69,82)` — inverts to a **2-cell intersection: the original wrote (56, 52, 64..72)**.
  That is a measurement of the ORIGINAL, and it is the number any future model has to hit;
* **the MINIESC downscale is KILLED.** `MINIESC.PKF`'s entries are 3100 bytes against
  `NANOESC.PKF`'s 796, same 28-byte header, so the payloads are 3072 = **48x64** and 768 =
  **24x32** — MINIESC *is* the 48x64 bank, and a 2:1 box downscale of it lands exactly on this
  cell. Scored over all 476 entries: best **521 differing px of 768**, against the port's
  plain NANOESC blit at **66**.

Also recorded: `toward-chrome`'s 179/449 was scored against a chrome whose pixels under the
kit's own silhouette are a wall paste, i.e. a guess exactly where the rim lives. Re-scored on
the WITNESSED backdrop only 39 of the 449 px have a witnessed destination at all; 35 fit an
edge alpha but at weights scattered across 0..256, which is a free parameter absorbing noise.
Reported, not claimed.

**And it collapses three open items into one.** `OffersScreen's panel` is already 0 px
outside the kit sprites (s69) and what is left inside its cells is this same on-sprite kit
edge; the `48x64 on-sprite EDGE BEVEL` is the same family. There is ONE open pass here, not
three.


## 0aaaaaaaaaaaaaaaa. Closed 2026-08-01 (session s84) — B9's FILLED PANEL, THE RIM'S THREE DEAD MODELS, AND A DELEGATION THAT POINTED AT NOTHING

### 1. ⭐ B9's FILLED "PLAYERS FOUND" PANEL — CLOSED AT 0 px, AND THE FRAMES WERE ALREADY BANKED

s83 left B9 as "driving time": the port had never seen the youth scout's report un-occluded,
so the panel's list was drawn from refrun `p0759_UNKNOWN.png` — a frame with the
contract-offer card **on top of it**. The card DIMS what it covers, so the inks read off it
(AV `(132,26,26)`, WAGE `(100,0,0)`, AGE `(30,52,98)`) were the dimmed values, and the row
plate, the cell grid and the scrollbar were not in evidence at all.

**They did not need another drive.** s83's own run had already banked them: probes
`0248`..`0597` of `season_youth_b9` are the YOUTH TEAM screen of a TOTAL-level Bolton W
career with the scout's first report on it — `Chapman  41  [ROL]  £5,000  19` — and nothing
over it. Two of them, 14 months apart, differ by 494 px and **every one of those is in the
header date plaque**: the list rect is identical, so the widget is stable and one cut is
enough. Both are now in the repo, TRACKED, at `tools/re/refs/b9-players-found-2026-08-01/`
(`screenshots/` is gitignored, so anything a GATE depends on belongs in `refs/`),
because the previous builder had been reading a session scratchpad that does not survive a
reboot — the same lesson s80 learned about the youth arrow.

`tools/re/build_youth_found_list_from_frames.py` cuts the widget verbatim into
`found_list.png` + `found_rowgrid.png` and re-measures the frame's own invariants first
(six plates on a 16-px pitch, the grid's four dividers, the two rules). Four things the
render-diff then forced, each of them a measurement:

* **the ROL cell is a 25x14 BLACK backing** — that is what the frame carries at every one
  of the 82 px `camrol10` leaves transparent, and it is the same backing
  `build_lineup_chrome_from_frames.py` already bakes under the LINE-UP camrol column. The
  icon itself is the port's own sprite, matched at **0 of 268 opaque px**;
* **each column's VALUE carries its own HEADER's ink** — AV `(212,63,0)`, WAGE `(150,0,0)`,
  AGE `(42,95,170)`, name black, and the name is NOT upper-cased;
* **the money column is the `euro8` face at 11**, not the bold list face. Identified by
  SHAPE and reproducibly (`app/tests/shot_face_probe.gd` + `tools/re/probe_text_face.py`):
  "£5,000" rendered in all eight extracted faces at 8/10/11/12 and XOR'd against the
  witness cell's own 94-px ink mask — **euro8@11 is the only pair that scores 0**, and the
  other 31 do not even share its bounding box;
* **the scout bar's half star had no purple sprite.** `_stars` was called with `null` for
  that row because no frame had ever shown a youth scout on a .5 rating; B9 hired
  **C. Stump, 4.5**. Cut by `build_youth_star_half_purple_from_frame.py`, whose alpha comes
  from the port's own render of the same screen without it.

**`diff_youth_parity` is 6 of 6 at 0 px body**, the sixth being the new
`youth_b9found` pair. `test_fines`, `test_youth`, `test_youth_screen`,
`test_youth_offer_route` and `test_manager_panel` are added to the CI gate list.

What is left of B9 is ONE gap and it is named: a filled YOUTH TEAM **roster** row, which
needs the prospect SIGNED — the row tap raises the contract card and only OFFER puts him in
the roster. `plans/season_youth_b9_sign.json` drives exactly that (row tap at (450,126), then
OFFER by TEMPLATE match so it is a no-op on every probe with no card up).

### 2. THE 1-px KIT RIM — TWO FACTS ESTABLISHED, THREE MODELS KILLED

Still unlocated, but no longer merely untried. `tools/re/probe_kit_rim_models.py` measures
the EURO GROUP leader cell over all six frames (449 residual px) and settles:

* **the rim is ON the sprite** — 415 of 449 px are inside the exported NANOESC sprite's own
  opaque mask. It is not a drop shadow, an outline or a halo, which is why every search for
  a pass drawn *under* the kit was looking in the wrong place;
* **it comes out of the shadow blit's own quantiser** — the rim colours are each other's
  LUT **dither PARTNERS** (palette 13 `(59,85,130)` / palette 10 `(42,63,170)` share 27
  RGB565 cells) and both appear in one sprite's rim at different screen parities. So it is
  **not** a palette error, a wrong kit bank, or an export bug — three explanations that can
  stop being carried.

Killed, each scored as "does SOME weight reproduce the original, given the port's colour,
the destination chrome and the parity": blended toward the chrome **179/449**, toward black
**264/449**, toward white **58/449**. The last is the arithmetic behind s83's correction of
the old "consistently LIGHTER" note.

### 3. THE `Status:` DELEGATION POINTED AT NOTHING FOR 114 DOCS — REPOINTED, AND CI-GUARDED

`REMAINING.md` delegated per-screen truth to "the `Status:` line at the top of each
`docs/re/<screen>_re.md`", and only **21 of 135** docs carry one. Writing the other 114
would be prose about prose and every sentence a guess. The delegation now points at
`docs/re/STATUS_INDEX.md`, which DERIVES each doc's standing from its gate, suite, scene,
EXE addresses and `Evidence:` paths — **0 of the 135 have no evidence link** (37 gated, 67
with a headless suite, 93 binary-anchored, 28 with an explicit `Evidence:` line).

The builder had been unrunnable: its `Evidence:` parser comma-split raw text, so any doc
that annotated a path failed the whole script (`camera_motion_re.md`'s "…`MANAGER.EXE`
(capstone, …)"), and its regex swallowed sibling `Raw:` / `Port:` lines whose paths are
deliberately outside the repo. It now scans line by line, takes backticked spans, and
verifies only tokens carrying a `/`. A **new CI step** regenerates the index and fails the
build if it differs from the tracked one — so a rotted `Evidence:` path breaks the build
instead of quietly making the delegation false again.

### 4. THE M5 "WATCH-HARNESS SPIN" ENTRY WAS STALE — CORRECTED IN PLACE

`M5_S59_FRONTIER_2836.md` still listed the harness spin as open item 1. It was closed
2026-07-28 by `5b25acd`: it is the BOARD PAUSE, not the goal latch, and both missing pieces
(`+0x1a1f` from the global pause byte, and the KICK OFF click as a nonzero pump result) are
modelled by `Pm98Outer.next_pump_result`, which `run_match_from_struct.gd` raises on the
frame after a pause-branch break. Two probes killed the `restart_handler` hypothesis rather
than leaving it hanging, and a stall guard replaced the silent multi-hour hang. Goals 2-7
attribution is now a RUN of that harness, not a fix to it.

### 5. 🆕 OPEN — THE "SEARCH CAPABILITY" YES/NO BLOCK IS NOT ALWAYS ALL-YES

`YouthScreen` draws the six SEARCH CAPABILITY values as **"the witnessed NO (no scout) /
YES (scout) pair"** — all six YES the moment a youth scout exists. The s84 drive's own
career contradicts that: with **C. Dewhurst (2.0★)** hired, the block reads
**HANDLING / DRIBBLING / TACKLING = YES** and **PASSING / HEADING / SHOOTING = NO**, while
s83's **C. Stump (4.5★)** career reads all six YES. Frame banked at
`screenshots/wine-captures-2026-08-01-b9-sign-drive/probe_0028_04_youth_after.png`
(and the same career's youth manager **S. Saxon 1.0★** reads "1 PLAYERS", which is
`FUN_00578b80` case 10's q<3 band — an independent confirmation that the frame is sane).

**Deliberately NOT fixed this session.** Two samples cannot fix a six-step ladder, and the
2★ split is confounded: the three YES cells are exactly the LEFT COLUMN, so "the first
three in `cap_order`" and "the left column" and "three unlocked by rating" are all
consistent with it. `FUN_00578b80` is not the source — its YOUTH TEAM SCOUT arm is
`0xffff` (no cap) in all five bands. The precedent for how to settle it is
`ScoutScreen.REGION_STARS`: four careers at four ratings plus one bracketed step. That is
what this needs, and inventing four thresholds from one frame is exactly what this project
does not do.

### 6. THE WINE DRIVER LOST A RUN TO A REPAINT, AND NO LONGER CAN

The B9 drive stopped at step 56 on an UNKNOWN frame that was a real HALF TIME board
carrying the TITLE SCREEN's logo strip in its top band — and every screen signature's ROI is
`[136,16,284,28]`, inside that band. It was not a transition: 45 re-grabs over 54 s saw it,
and so did a snapshot minutes later. `autodrive.repaint_nudge` now moves the pointer inside
the window on the third failed attempt — inert on every driven screen, where a click would
not be: a click would have advanced past exactly the board that needed photographing.

**And the driver must never pull the game window in front of the person using this box.**
Mats works on this machine while a drive runs, and a `windowraise` on every synthetic click
makes it unusable. `PM98_NO_RAISE=1` is the switch — `click.sh`, `autodrive.click` and
`autodrive.repaint_nudge` all honour it — and **`arm_b9.sh` now exports it by default**, so
a drive started the normal way never raises. Export it yourself if you invoke `autodrive.py`
/ `boot.sh` / `nav_career.sh` directly.

## STILL OPEN AFTER s90 — THE WHOLE CARRIED SET, IN ONE PLACE

> **REWRITTEN 2026-08-02 (s90).** The kit-edge item is CLOSED at 0 px and off this list; the
> two capture items are unchanged in kind but no longer blocked on tooling. One NEW item is
> here, and it is here because closing the kit edge found it: three sprite banks were baked
> against the wrong palette, and the rule that produced them is still in place for the rest.

**Open — CAPTURE / driving time**

* **A SEMIFINAL / FINAL cup draw.** `FUN_004d9a00` returns 0 without painting unless a
  human-managed club is in the drawn round's own tie/club array (`club+0x5c != 0xffff`,
  read s89), so the manager's club must BE in that semifinal. s90 adds the arithmetic that
  was missing, from two runs. The drive never manages the squad, and what that costs depends
  on where the club finishes: **run 1 was RELEGATED** in season 1 and the start of season 2
  came with the Directors terminating the contract ("your squad does not have the minimum
  number of players needed to play in any championship"), which drops to the title screen and
  stops the drive; **run 2 stayed up** (Premier, week 41) and rolled into season 2. So a run
  is at least one season-1 roll — three competitions, a real squad, ~1.5 h — and more only if
  the club survives. **Neither run reached a semifinal**: run 1 went out by the 3rd round,
  run 2 reached the F.A. Cup 4th round (the draw PAINTED, so Man Utd were in it) and no
  further draw followed. `tools/re/wine/nav_manutd_career.sh` sets a run up.
* **The M5 goal-2 divergence** (port clk 8469, reference two minutes earlier, right team).
  Tooling no longer gates it: `m5_rsp_capture.py` has the clock-watchpoint RUN-UP (s89), a
  raisable `PM98_MAX_STOPS`, `PM98_CLK_TRACE=1` for the cheap whole-window pass, and
  `resume_watchdog.py` to click KICK OFF at the WATCH segment pauses a capture could never
  answer before. What is left is wall clock: the cheap trace runs at ~15-30 clk/min under
  load, so 2837..8469 is several hours, and the expensive per-frame capture that actually
  LOCALISES the divergence is a narrow window after it. `m5_clktrace_diff.py` records what
  the cheap trace can and cannot decide — the reference's goal CLOCK yes, per-tick seed
  equality no.

**Open — RE (NEW, s90)**

* **The realised-palette sweep.** `docs/re/realised_palette_re.md`. Every frame MANAGER.EXE
  paints is entirely MANAGER.PAL + the Windows statics, and 25 of 25 sampled walkthrough
  frames carry colours the shared VGA table at `DAT.PKF +0x5CA` does not contain. Three
  banks have been found wrong this way and fixed against their own witnesses (MINIBAND
  flags 07-26, RIDIESC kits s90, the face banks s90), but `export_art.render` still picks
  `vga_palette()` for every `DM` sprite and every `force_vga` caller. Flipping that rule
  blind would be a guess: each bank needs its own witness, and two cases must NOT be swept
  up (`faces/dbcard/` is Dbasewin's own correct rendering; `_generic.png` uses no affected
  index).

**Needs Mats**

* **The real-device pass.** There is no Android device on this box.

**Closed as far as it can be — DO NOT REOPEN**

* **HIGHLIGHTS / the 3D match view's models** — a hard DATA gap: the `.p3d` files are absent
  from BOTH `pm98.iso` and `Premier_Manager_98.rar`. `PCF5DAT.PKF` was re-measured from
  scratch in s87 and is a CD-presence check, not a container.
* **The unmanaged-club release ladder** (`FUN_0057b6b0`) — fully reversed in s78 and
  deliberately NOT ported: the port has no league-membership model to hang it on.

## SUPERSEDED — the pre-s88 carried set, kept for its evidence trail


The list below had drifted to "STILL OPEN AFTER s81" three sessions back while the real
carried items sat scattered through the per-session sections underneath. This is the
complete set as of 2026-08-01, and each line says what KIND of blocker it is, because that
is what decides who can move it.

**Blocked on PERFORMANCE — the largest remaining functional gap**

* The **M5 3D / positional engine is not wired into `MatchSim`**. It is in the repo and
  ships in the APK, byte-exact over clk 1-2836 plus the first goal against nine banked
  captures, and it runs **~9 minutes per match in GDScript**.
  `handoff-pm98-m5-s59-frontier-2836` step 5 is the wiring step and it is blocked on speed,
  not on correctness. Note the scope: every match the app PLAYS already runs on
  `MatchSim.simulate`, which since s74 is the original's own stat engine — so this is the
  fidelity of the match VIEW, not of results.

**Blocked on CAPTURE / driving time**

> **Four lines in this block were superseded on 2026-08-01 by s85
> (§0aaaaaaaaaaaaaaaaa at the top). They are struck rather than deleted, because WHY each
> was wrong is itself the finding.**

* ~~The **M5 set-piece leaves** — attribution is now a RUN.~~ **s85: it was not a run. The
  harness deadlocked on the first set-piece restart after goal 1 (dispatch code 3 at clk
  3885) because the wait loop's break set excludes codes 3 and 4 and the pause branch never
  arms `+0x1a1e`. Fixed by modelling the board dismissal. FULL TIME is attributed and goals
  2-7 ARE now a run — goal 2 is the frontier at 26' against the reference's 24', right
  team.** Stoppage time and the cross-seed `PM98_SEED` sweep are still unrun.
* ~~**B9's filled YOUTH TEAM roster row**~~ — **CLOSED s87 at 0 px** (§0a-s87.1).
* **The per-round cup-draw chrome** — **advanced, s85.** The corpus had twelve SORTEO frames
  and four round labels across three competitions, so the per-round axis was unanswerable.
  This session's drive banked five more (`tools/re/refs/cupdraw-rounds-2026-08-01/`),
  including **three new labels and a knockout-stage draw**: Coca-Cola `ROUND 2`, `ROUND 3`,
  `ROUND 4` and **`QTR. FINALS`** — four rounds of the SAME competition from the SAME career,
  which is exactly the comparison that was missing. Not yet analysed: a masked diff leaves
  ~5,000 px, but the box contains the ANIMATED sorteo drum, so the drum has to be masked or
  filmed before any of it counts. A **semifinal and a final** draw are still missing.
* ~~**The SEARCH CAPABILITY star ladder.**~~ **s85: not a ladder, and not a capture item.
  The value cell is per-capability AVAILABILITY (frame 047 reads all six YES with only three
  LEDs selected) and the mask is PER SCOUT — two 2★ scouts, two different masks. It is an RE
  item now, listed below.**

**Blocked on RE — un-reversed, and said so rather than approximated**

* **The 1-px kit rim pass.** §2 above plus s85 §4: it is ON the sprite, it goes through the
  shadow blit's quantiser, **four** models are dead (toward-chrome / black / white and the
  MINIESC 2:1 downscale), and the original's own 24-bit colour is now recoverable per pixel
  by inverting the parity LUT. The pass is unlocated.
* ~~**The 48x64 on-sprite EDGE BEVEL** and **OffersScreen's panel**.~~ **s85: both are the
  same on-sprite kit-edge pass as the line above — OffersScreen's panel is already 0 px
  outside the kit sprites. ONE open item, not three.**
* ~~**The YOUTH SCOUT capability mask**~~ — **CLOSED s87 from the binary** (§0a-s87.3).
  There is no hire-path seed: the flags are SELECTION, zeroed by the criteria ctor, and the
  availability ladder is the jump table at `0x53d520`.
* ~~**What "Free if relegated" DOES.**~~ **CLOSED s85** — `FUN_0058AC90` @0x58ae5e, the only
  consumer in the image. `docs/re/retirement_re.md` §6.
* ~~**`KnockoutScreen` → `PMShadow`**~~ — **KILLED s87**, with the reason measured rather
  than suspected: the blit only ever writes OUTSIDE the silhouette and only ever toward
  BLACK, and the residual is an on-sprite HIGHLIGHT (415 of 449 px inside the opaque
  mask). See `knockout_views_re.md`.

**Closed as far as it can be — do not reopen**

* **HIGHLIGHTS / the 3D match view's models** — a hard DATA gap. The `.p3d` files are absent
  from BOTH `pm98.iso` and `Premier_Manager_98.rar`.
* **The unmanaged-club release ladder** (`FUN_0057b6b0`) — fully reversed in s78 and
  deliberately NOT ported: the port has no league-membership model to hang it on.

**Needs Mats**

* **The real-device pass.** There is no Android device on this box.

## 0aaaaaaaaaaaaaaa. Closed 2026-08-01 (session s83) — THE BARRA PANEL, THE BAND'S SLANT, AND WHO ACTUALLY GETS PAID

Three of s82's carried items closed, each against a measurement rather than a theory, and
two long-standing "un-closable" notes turned out to be wrong about their own evidence.

### 1. ⭐ THE BARRA MANAGER PANEL — the port's single biggest parity bucket, 649 → 14 px

Every screen that shows the manager-mode barra drew **Manchester Utd's whole captured
panel** for club 40 and a **bare NANOESC kit with no furniture** for every other club. That
cost **649 px per frame** on the EURO GROUP gate and on all **fourteen** knockout cases —
more than the rest of those gates put together — and it had been filed as un-closable
because "no frame in the corpus shows that panel with any other club's kit".

It does. The six EURO GROUP frames are a **BOLTON W** career in the same manager mode, and
`kits/header/40.png` was cut from a **Manchester Utd.** career. Two careers occlude
*different* pixels of the same panel, so between them they witness all but the 417 px both
kits cover. Two measurements make the rebuild a derivation:

* the panel's kit half **is** the club's own NANOESC sprite at the panel-local anchor
  `(6,7)` = screen `(114,15)` — the anchor the port already carried as its fallback:
  Man Utd's exported `art/kits/nano/40.png` reproduces his panel's kit region at
  **0 of 419 opaque px**;
* furniture + the club's own kit reproduces **Man Utd's panel at 0 px** and **Bolton's at
  14** — and those 14 are pixels neither exported sprite covers, i.e. the un-reversed 1-px
  kit rim. Declared, not painted.

`tools/re/build_manager_panel_from_frames.py` → `app/art/kits/header/panel.png`;
`PMChrome.draw_manager_panel` is the single draw path now (`draw_header`, `ResultsScreen`,
`KnockoutScreen` and `EuroGroupScreen` each carried their own club-40-only copy);
gate `app/tests/test_manager_panel.gd`, added to the CI list. `40.png` stays as the witness
the rebuild is gated against.

### 2. ⭐ THE EURO GROUP LEADER KIT — the "solid block" was a BAKE gap, 196 → 66 px

Not a blit pass. The leader kit sits on the **left end of the black GROUP header band**, and
that end is **slanted** — measured, the band's left edge walks from x97 at y186 to x79 by
y198. The chrome baker pasted the empty-body desktop over the whole kit rect and deleted the
part of the slant the kit does not cover.

Recovered with the same two-witness logic, six ways over: the six frames have six different
leaders, so a position one leader's kit covers another's leaves bare. Over the 24x32 cell
that is **356 witnessed, 6 split (kept on the wall paste), 406 never bare** — and the 406 are
the silhouette every NANOESC kit shares, which the port draws a kit over exactly as the
original does. `_recover_leader_backdrop` in `build_euroleague_chrome_from_frames.py`.

**The EURO GROUP gate now reads 99 / 107 / 132 / 110 / 103 / 117 px** (was 864 / 873 / 896 /
876 / 875 / 881). All fourteen knockout cases keep their 0-outside verdict with the barra
bucket at 14.

### 3. ⭐ WHO GETS PAID IN EUROPE — the port was paying three competitions, the original pays one

s82 left this open ("the U.E.F.A. / C.W.C. prize money is unchanged pending a proper
per-function scan of their blocks"). Scanned, and the answer is decisive:

* the four "receives … from UEFA" strings exist **only** in the CEURO block
  (0x653518..0x6536db). The CUEFA block (0x653878..0x6539a4) and the RECOPA block
  (0x6539b0..0x653a10) carry none;
* all six figures — £1m / £1.5m / £1.625m / £2m / £510k / £255k as float32 in the internal
  ×200 unit — occur **only** inside `FUN_00454b00`;
* `FUN_00454b00` has **no direct caller** and exactly **one** reference in the whole image:
  vtable slot `0x6273a4`, index 41 of the **European Cup** vtable at `0x627300`, whose index
  40 is `0x453eb0`, the function that names `%c:ACTLIGA\CEURO%03u.CPT`;
* the Cup Winners' Cup's same-index method (`0x461610`, vtable base `0x627568`, index 40 =
  `0x4612d0` = the RECOP template fn) contains no money at all, and the U.E.F.A. Cup's class
  carries the empty base stub `0x404fa0` (`xor eax,eax; ret 4`).

So **the U.E.F.A. Cup and the Cup Winners' Cup pay nothing** — no entry fee, no per-tie
money, no milestones. `Career.EURO_PRIZE_COMPETITION` gates both the entry fee and the
round payments; entering the other two raises news, not money.

### 4. And one wrong lead closed for good

The 48x64 knockout kit ring is **not** the `FUN_004b7f60` shadow pass. `FindRefsTo` lists
all 53 call sites of that thunk and **none** is in the knockout drawers' range (the
`AGGR.` / `FINALIST` drawers sit at 0x46cd3f / 0x46f521 / 0x490a6c; the nearest shadow-blit
sites are 0x4b29c0 and 0x4fe616). That is the same negative result the s78 EuroGroupScreen
experiment got empirically, now with the call graph behind it. The pass is still unlocated;
the position-constant bake stays and the club-dependent remainder stays a declared bucket.

### 5. Two entries below are STALE — read this first

* §3's "still to build: the bracket / the semifinal cards / the final / the kit list" and
  §5's per-club ground-grade note are both **closed** and kept only for their evidence
  trail. `diff_knockout_parity.py` runs **14 cases, all "0 outside"**, and `club+0x50` was
  reversed 2026-07-28 (it is the club's COMPETITION INDEX, computed by `FUN_0057a180`, not a
  stored byte — `GroundPreset.gd`, gate `test_ground_preset.gd`, all 476 clubs seeded).
  `stadium_screen_re.md`'s "WIRING follow-ups" are stale too: `works_ledger()` /
  `works_total()` are passed and GROUND MATCH DAY is built.

## 0aaaaaaaaaaaaaa. Closed 2026-08-01 (session s82) — THE EIGHT COUNTERPART-LESS SCREENS

The whole §B2 list of "original screens with NO app counterpart" is resolved, and it
resolved to **one** real missing screen. Record: `docs/re/fines_re.md`.

### 1. ⭐ THE FINES (MULTAS) — the one screen that really was missing, BUILT

The board fines the club when its GROUND is below the standard the competition it has just
played in demands, and says so on its own card. The port had the **FINES expense line** in
the finance screen since the ledger was reversed and nothing that ever wrote to it.

* **The levy** is `FUN_0057a980` @0x57ab85..0x57ad6a, the club's POST-MATCH pass —
  `FUN_00448b60` calls it on BOTH clubs of a finished fixture, so a fine is levied per match
  played, **home or away**, against the competition that match belonged to. Three arms on
  `DAT_0066b1dc`: **PREMIER** (floodlights ≥2 / changing rooms, score board, access, medical
  ≥1 → £25,000 x3 + £50,000 x2), **F.A. CUP** (floodlights ≥1 → £15,000) and one shared
  **EUROPE** arm for indices 7..11 (→ £50,000 x3 + £75,000 x2). The three lower divisions,
  the Coca-Cola Cup and the Charity Shield fine nothing, and that is a RESULT of the binary's
  own `jb`/`ja` bounds, not an omission. Each float32 debit equals the integer it banks, and
  £ = internal / 200.
* **The competition index** is mapped in full for the first time (0 Premier … 11
  Intercontinental) from each class ctor's own index argument in `FUN_00441ea0` matched to
  the class block owning its `ACTLIGA\<TAG>` template. Two independent confirmations: the
  FACUP ctor allocates 8 round slots and the CCCUP ctor 7 — the exact ladder lengths s81 had
  to pin the cup calendar against.
* **The card** is `FUN_00549d40`, raised by the weekly hub run @0x546164 — BEFORE the
  channelTV card @0x546226, which is the order the post-week chain now uses.
* **The art needs no bake.** Every pixel is a whole `RECURSOS.PKF` entry blitted at a literal
  coordinate, exported 1:1 by `tools/re/build_fines_card_from_pkf.py`. The archive and the
  disassembly agree three times without either being consulted for the other: the MULTAS
  panel is **418x316** and so is the binary's panel `CRect`; the ESTADIO equipment icons are
  **40x26** and so is its icon `CRect`; `MULTA.GIF` is **54x58** and so is the empty-string
  `CRect` it is blitted into.
* Gate `app/tests/test_fines.gd` (73 checks); the card was **rendered and looked at** under
  Xvfb + GL (`app/tests/shot_fines.gd`), not just asserted.
* Declared: the OK plate's hit rect (grown 2 px, the border `ChannelTvScreen`'s witnessed
  plate has), and the outer gate `club+0x54 > club+0x50`, which is NOT reversed — `+0x54` is
  simply the byte the record reader stores next to the competition index. Said, not guessed.

### 2. THE OTHER SEVEN WERE NEVER SCREENS

Six of the eight names came off RECURSOS **folder names** and belong to screens already
shipping at 0 px: **TV** = the channelTV card (s78); **EMPAREJAMIENTOS** = MAN-TO-MAN
MARKINGS (`FUN_0050e980`, the function `mantoman_screen_re.md` is about — "emparejamientos"
is *markings*, not the cup draw); **SININFO** = the TITLE SCREEN's own art group;
**SECRETARIO** = the SEARCH button art of the SCOUT and YOUTH search panels;
**SELECCIONPRO** = the OFFERS SELECTION screen's arrows and info plate. **CREDITOS** has
**zero references in either executable** — dead PC Fútbol 5 inheritance, so building one
would be inventing a screen PM98 does not have. **HIGHLIGHTS** stays the unchanged hard data
gap **as of s84 — CORRECTED s85: the models are UNOPENED, not absent.** The ISO's
`PCF5DAT.PKF` (314 MB, ISO-only, `SOURCE_INVENTORY` GAP#1) has never been enumerated, and
PKF member names are obfuscated so a byte search cannot see into it. See
`docs/re/match_view_re.md` §3.

### 3. THE EUROPEAN ENTRY ALERT — raised, and one figure corrected from its own string

The port credited all four UEFA payments silently. All four alerts are raised now with
MANAGER.EXE's own text. Reading them corrected a figure: the £2,000,000 was paid as a
trophy-lift bonus, and its string (@0x65369c) says *"your qualification\nto the final"* — so
it is the milestone for winning the semifinal, and there is no reversed lift bonus at all.
Declared: the alerts fire for the **European Cup only**, because all four strings live in
that class's block.

### 4. B9's WINE DRIVE — the blocker was the CAREER LEVEL, not a coordinate

s80 filed B9 as "the plan's hub click (234,390) does not reach SQUAD MANAGEMENT". Walked
live against the window this session: **(234,390) is correct** — it is the PLAYERS icon —
but at **TRAINER** level it answers with the modal *"This option is automatic in Trainer
level."*, because at Trainer level the whole TRANSFER MARKET quarter is automatic (the hub
draws those six icons GREY, and in colour at TOTAL). Every career the driver has ever built
was a Trainer career. `nav_career.sh` now takes `PM98_LEVEL` (trainer | manager | accountant
| **total**), and with `total` the entire B9 path was walked and photographed step by step:
SQUAD MANAGEMENT → YOUTH TEAM → CLUB PERSONNEL → **C. Stump 4.5★ hired as YOUTH TEAM SCOUT**
→ **P. Klachinsky 5★ as YOUTH MANAGER** → six LEDs armed → SEARCH answers *"The scout is now
searching for players with selected capabilities."* B9 is no longer blocked on an unknown;
it is driving time. Full step list in `plans/season_youth_b9.json`'s own note.

### 5. NOT done in s82, said plainly

The **M5 set-piece leaves** (and with them goals 2-7, full time, stoppage time and the
cross-seed sweep), the **four visual residuals** (48x64 on-sprite bevel, EuroGroupScreen's
group kit cells, OffersScreen's panel, the barra manager-kit CAPTURE gap) and the
**real-device pass** are all untouched. The first is a multi-session exact-port job; the
second is un-reversed or un-captured rather than un-built; the third needs Mats and a phone.

## 0aaaaaaaaaaaaa. Closed 2026-08-01 (session s81) — THE OWNER'S PLAYTHROUGH LIST

Ten reports off a live playthrough, each traced to code before anything was changed.

### 1. THE YOUTH "READY TO BE PROMOTED" BOX TRAPPED THE GAME

`MANAGER.EXE` @0x261ab8 carries the string with an explicit `\n` after "that". The port
had flattened it to one line; PMAlert measures `w = ink + 31` and centres on (317,237), so
a one-line box is ~700px wide and the OK button (anchored at `w-6, h-6`) landed off the
640x480 surface — an undismissable modal. The string is restored to the EXE's own two
lines, and `PMAlert._fit` is a **fail-safe** (not faithful behaviour: the original has no
auto-wrap) that wraps any over-wide line and `push_warning`s, so a future missing `\n`
shows up in the log instead of halting a career.

### 2. EUROPEAN (AND CUP) TIES ARE PLAYED, NOT SKIPPED

`advance_week` resolved the whole week in one call and returned only the LEAGUE fixture, so
every F.A. Cup / Coca-Cola / European tie the manager's club played was simulated silently
and surfaced only as a RESULTS line. `Career._cup_report_sink` now also queues each of his
own matches into `pending_matches` (comp + round label, both XIs, the stat report, the
possession split), `take_pending_matches` drains it, and `Main._present_tie_chain` presents
each one through the same LINE-UPS -> BRIEF -> FULL TIME flow as a league Saturday, with the
read-out's phase chip naming the competition and round. A two-legged tie presents BOTH legs
and not its extra-time fold. Guard: `app/tests/test_playable_cup_ties.gd`.

### 3. THE RESULTS SCREEN HAD EIGHT BLANK PLATES AND DEAD DIVISION CHIPS

`Career.results` is a manager-only ledger, so `_score_for` could answer for exactly one
fixture a round. `Career.round_scores` (and `divisions[t].scores`) now bank every fixture's
score, keyed by the 1-based round, and both round-trip through the save. The four bottom
DIVISION chips — measured off frame 038 at x 14/134/254/374, y 435..459 by scanning the
plaques' black border columns — switch the table between the four divisions, keeping the
same round where the schedule has one. The chrome bake lights the manager's own division
permanently, so the SELECTED state for the other three is a declared port-side ring.

### 4. THE GOAL SCORERS CHART CARRIED SEASON ONE INTO SEASON TWO

`divisions[t].scorers` were rebuilt at the rollover but `scorer_log` — the manager's own
tier — never was. Cleared alongside `results`/`season_stats`, with `_month_goal_mark`.
Training focus is a `pid -> row` map and the original's mode byte survives season init
(`FUN_005825c0` touches morale/condition only), so retained players keep their assignment;
entries for players who retired or left are pruned, because they were still eating the
coaches' TP caps, which is what made training look like it never reset.

### 5. THREE UP FRONT ARMED FOR THE OPPONENT

`_att_count` was evaluated per side, so any AI club fielding three natural forwards
collected the cave's buff. Every trigger is now gated on `cheat_manager_side`, resolved by
MatchSim from an `is_manager` marker `Career._ratings_for` stamps on the manager's club
alone; an AI-vs-AI fixture arms nothing. The per-half chance floor moved from the cave's 3
to **2** (`Pm98StatMatch.cheat_chance_floor`, owner request) — the ONE deliberate
divergence from MANAGER_HACK.EXE, and `test_three_up_front` still proves byte-parity with
the patch by putting `CAVE_CHANCE_FLOOR` back for the oracle run.

### 6. CONTRACT RENEWAL: THE DEMAND, THE TERM AND THE CLAUSES

Three separate defects behind "renewal is so much harder / clauses don't work":
* `Contract.demanded_weekly` multiplied the market wage by an invented age+CA "ambition"
  ladder (1.40 at 21 down to 0.98 past 31), so almost every renewal opened 18-52% above
  what the man was already on — while the OFFER form opens at his CURRENT yearly wage. The
  one witnessed renewal transaction contradicts it outright ("offering his exact current
  terms accepted silently", `renew_negotiation_re.md` frame 28_offerresult). The ladder is
  gone; the demand is his current terms, floored at his market rate. A genuine lowball
  under the soft floor is still refused.
* `Career.renew` stamped `NEW_TERM_YEARS` on every renewal and threw the form's YEARS
  stepper away. It now honours the offered 1..5 term.
* The OFFER panel's four clause boxes were a read-only mirror of the CONTRACT panel. They
  are editable, ride the offer, and are stamped on the player — with the engine's own rule
  that a term above one year clears MATCHES TO RENEW (@0x529e40).

### 7. THE SCOUT'S CRITERIA SURVIVE HIS REPORT

`scout_search` held them only while a mission was in flight, and a fresh ScoutScreen node
is built on every entry, so the panel came back blank next to the rows it had produced.
`Career.scout_criteria` persists the last search and `ScoutScreen.restore_criteria` re-arms
every widget before `setup()` re-applies the hired scout's own region reach.

### 8. THE DOMESTIC CUP CALENDAR

Both cups spread their rounds EVENLY across the league season, which put the F.A. Cup's
ROUND 3 — the round the Premier clubs enter — on 1 November and the Coca-Cola final in
mid-January. Both are pinned to the 1997-98 competition calendar through the port's own
week->date grammar: F.A. Cup R1 wk15 (15 Nov) ... **R3 wk22 (3 January)** ... FINAL at the
season's last week; Coca-Cola R1 wk1 ... FINAL wk34 (28 Mar). The port's bracket resolves
to eight rounds, which is exactly the F.A. Cup's own R1..FINAL, so that pin is one-to-one;
the Coca-Cola's real ladder is seven, so ONE port-side round takes the only slot with room
(wk19) and is declared rather than silently shifting a real one. DECLARED SOURCE: the
1997-98 competition calendar plus the owner's report — the per-round week table lives in
PCF5DAT.PKF, which is not enumerable (SOURCE_INVENTORY §5 GAP#1), so this is the same class
of evidence as `EURO_TAIL_FRACS` and is pinned the same way.

### 9. STADIUM EXPANSION — INVESTIGATED, NOT REPRODUCED

The report was "the expansion works but doesn't affect ticket income, and the ground image
never changes". Traced end to end and the chain is intact at every link: `_complete_work`
raises `stadium_capacity`, `_recompute_weekly_net` follows, `_mgr_club` overrides the
static GameDB figure, `FinanceModel.summary` scales attendance and `match_gate` with
capacity, `_post_home_match` books that gate into `week_ledgers`, and
`StadiumScreen.tier_for(capacity + headroom)` picks one of the twelve ESTADIO tiles.
`test_stadium_works.gd` already pinned the picture and `weekly_net`; the one link it never
pinned — the TICKETS line the club actually banks — is now an assertion too: over the same
eight rounds on the same seed, a ground 20,000 seats bigger banks **£999,825 -> £1,637,325**.
Note the picture only moves on a BAND cross: twelve tiles over 130,000 seats is ~11,800
seats a band, so a +4,000 expansion legitimately leaves the tile alone unless it happens to
straddle an edge.

### 10. THE CUP-DRAW CHROME — WHAT ALREADY VARIES

`CupDrawScreen` already switches on two axes the reference run witnessed: the competition
(seven `sorteo_*` strips) and the LIST vs GRID panel form by tie count (REFRUN R8, >16 ties
-> scrollable one-line list, <=16 -> the four-column grid), plus the EXE's own uppercase
round plate. A third per-round axis is not in evidence and is NOT invented here. If the
original varies further, the next step is a wine capture of a semifinal / final draw.

**Counted 2026-08-01 (s84), because "only four draw frames exist in the RE corpus" was
wrong — four are what the GATE uses, twelve are what exists.** Every SORTEO frame in the
reference run, with its own round plate read off the frame:

| frames | competition | round plate |
|---|---|---|
| p0125, p0126, p0127, p0131, p0132, p0133 | Coca-Cola Cup | `ROUND 3` |
| p0380, p0381 | F.A. Cup | `ROUND 3` |
| p0445, p0446 | F.A. Cup | `ROUND 4` |
| p0744, p0747 | U.E.F.A. Cup | `1/16 FINAL` |

So the corpus carries **four distinct round labels across three competitions and both panel
forms, and no semifinal or final draw at all** — which is exactly the shape of evidence
that cannot answer the per-round question either way. The item stays open on a capture, and
it is now open on a *counted* corpus rather than a remembered one.

## (superseded — see "STILL OPEN AFTER s84" at the top) STILL OPEN AFTER s81

* The **3D / positional match engine (M5)** is in the repo and ships in the APK, but is not
  wired into `MatchSim`: it is byte-exact only to clk 2836 + the first goal, and runs ~9
  minutes per match in GDScript. `handoff-pm98-m5-s59-frontier-2836` step 5 is the wiring
  step and it is blocked on performance, not on correctness.
* Everything else carried from s80 is unchanged — see below.

## 0aaaaaaaaaaaa. Closed 2026-08-01 (session s80) — THE YOUTH CONTRACT CARD AND THE ARROW

s80 resumed the youth work s79/E left mid-task (the box shut down with tasks 5-8 open).

### 1. THE PLAYERS FOUND ROW TAP NOW RAISES THE CONTRACT-OFFER CARD

`FUN_0053eaa0` -> `FUN_00527000`, the same card family as the senior scout's row tap. The
app used to sign a prospect silently on the tap and print a toast, which threw away the
whole negotiation. Witness `refrun p0759` (14 Oct 1998): CLUB OFFER **£0** / CLUB FEE
£75,000 / YEARLY WAGE £5,000 with steppers / YEARS 4 / the four clauses / CANCEL / OFFER —
and SPINDLE, the youngster it signed, carries YEARLY WAGE £15,000 on his own card, so the
wage is negotiated UP from the £5,000 the form opens at.

`MakeOfferScreen` gained a `no_club` mode (CLUB OFFER pinned to £0, its ◄► inert — there is
nobody to bid to); `Career.offer_youth_contract` resolves it, with the refusal roll bought
down by the wage and the negotiated terms stamped on the youngster, so the YOUTH TEAM
roster's WAGE / YEARS columns finally fill. `sign_youth_prospect` survives as that call at
the card's opening terms, so the automated paths are unchanged. New
`test_youth_offer_route` drives the real Main UI end to end.

### 2. ⭐ THE PARAMETERS/RATING ARROW — AND WHAT IT IS NOT

s79 un-baked the arrow and drove it off `_mode`. The parity shots caught that: frame 047
carries the RATING plaque pair (0px against the live RATING witness over both plaque rects)
while its arrow sits at the PARAMETERS slot. The plaques and the arrow are **separate
axes** — LINE-UP shows the same thing with the RATING view actually displayed. The arrow
has its own hit rects (exactly the two the handlers invalidate) and defaults to PARAMETERS,
which is what every witnessed frame but the live RATING tap shows. What else it selects is
un-RE'd and flagged as such.

Two further defects in the s79 cut: the ink was taken from a hand-listed pair of colours and
silently dropped **22 of the 81 px** (the sprite is dithered and carries eight colours), and
one sprite stamped at both slots is 11px wrong because the dither is against a different
background band per slot. Now cut per slot by pixel-difference of the two witnesses, whose
frames moved **into the repo** (`screenshots/wine-captures-2026-08-01-youth-arrow/`) — the
builder had been reading a session scratchpad that does not survive a reboot.

All five YOUTH parity shots: **0px body**.

### 3. THE TEST SWEEP WAS LYING — 22 GREEN TESTS REPORTED AS FAILURES

The ad-hoc sweep grepped stdout for `ALL PASS`. The suite has at least five green footers
(`ALL PASS`, `<name>: PASS`, `ALL GREEN`, `ALL OK`, `MAKE-OFFER: ALL GREEN`), so 22 healthy
tests read as failures. `tools/run_tests.sh` now gates on the **exit code**, which is what
CI has always used.

### 4. AND UNDER THE FALSE ALARMS, TWO REAL REGRESSIONS FROM s79

Both were invisible while the harness was crying wolf on 22 green tests.

* **`Staff.physio_capacity` returned 0 for every physio.** s79 generalised the case-6
  ladder into the whole `FUN_00578b80` table keyed by `member.role`, but the physio's
  callers hand in a bare `{"stars": 4.5}` — no role key — so the lookup missed and the
  INJURIES band's "N PLAYERS" silently became nobody. `capacity_of` now takes an explicit
  role override and each per-role entry point passes its own.
* **`test_refrun_findings` R17's odd-gap trap stopped being reachable.** Its fixture
  youngster is not in the training programme, and s79 correctly gated growth on the 0x20
  mode byte, so he never grew and never reported ready. Fixture given `in_training`.

### STILL OPEN from s79's list

**B9 did not fail on the sim — it failed on navigation.** Its drive ran 207 steps (15
probes, into January 1998), but every probe frame it banked is **LINE-UP**, not YOUTH: the
plan's hub click at (234,390) does not reach SQUAD MANAGEMENT. Fix that coordinate live
against the window before re-running, or it burns another 200 steps for seven more LINE-UP
frames. The wine career has no save (`drive_c/PM98/ACTLIGA` is empty), so it restarts from
a new career. Details in `docs/re/youth_re.md`.

---

# (previous inventory, refreshed 2026-07-29)

## 0aaaaaaaaaaa. Closed 2026-07-29 (session s79) — FIVE OWNER-REPORTED DEFECTS

Mats reported four regressions plus a scheduling bug and asked for them ahead of everything
else in the s78 carried list. All five are closed, each against the thing that caused it.

### 1. ⭐ THE GREY STRIPE ACROSS THE TOP OF THE HUB — the s77 bake deleted the header

`build_menu_bg_from_ref.py` ends with `px[:TOP_BAND_H] = marble`, which flattens the whole
header BARRA (y0..55) to flat grey. That line predates s77; what changed in s77 (`4ec77a4`)
is that the baker was RE-RUN, and the shipped `menu_bg.png` had been carrying a
hand-composed header band that the baker could not reproduce — the s77 docstring says so
itself ("the shipped `menu_bg.png` stopped being reproducible from its own baker"). The
rebuild replaced the band with marble, and `MenuScreen` draws only the header TEXTS over
this bake (`PMChrome.draw_ident_texts` / `draw_sheet_band_texts`), never `draw_header`'s
sprites. So there was no one left to draw the chrome. Manager name, club, MANAGER MENU, the
calendar sheet and the Premier/Week plaque were all painting onto bare grey.

**Fix:** the baker now KEEPS the reference frame's own header band and clears only the four
LIVE things out of it — the two identity captions and the kit box (by blitting the project's
own already-cleared `hub/ident_block.png`), the calendar date stack (`header/cal_sheet.png`),
and the two plaque captions (repainted with each caption row's own dominant colour, which is
the plate the engine filled it with). 2,267 px cleared; every other pixel in the band is a
pixel the real game put on screen. `menu_bg.png` is still 100 % reproducible from the baker.
Verified in the REAL app under Xvfb + GL (`PM98_HUB_SHOT`), not just in the asset.

### 2. THE OFFERS CARD OPENED AT £5,000 AGAIN — a deviation reverted by a parity fix

`4583ab0` (2026-07-27) changed `MakeOfferScreen.setup`'s no-seed default from the club FEE
back to the £5,000 FLOOR, to close a 294 px `diff_entry_parity` failure on frame
`101_164714`. The frame is right — the original DOES open the cold card at £5,000 — but the
port's opening bid is an owner decision from 2026-07-24 (the £5,000/£10,000/£25,000 stepper
costs ~640 taps to reach a £16M asking price), and reverting it undid that.

**Fix:** the default is the fee again, and the parity pair no longer depends on it —
`shot_entry_parity` passes `{"offer": FLOOR}` in explicitly for the frame-101 capture, so
that pair proves the CHROME and every other cell while the opening default is pinned by
`test_make_offer_seed` instead. `diff_entry_parity`: 18 of 18 pairs, makeoffer_101 **0 px**.

### 3. ⭐ THREE UP FRONT DID NOTHING — the trigger was not the one a manager can see

Every seam and live test was green and the cheat still did nothing in play, twice reported.
The tests field three NATURAL forwards. The game does not have to:
`Tactics.set_formation("4-3-3")` fills the front line with the best available players by
line, and a squad with two natural forwards puts a midfielder in the third slot.
`_fill_participant` writes `ROLE` from the player's own `pos`, so that XI carries TWO
`ROLE == 3` records and the cave's `att3` never reaches three. Board says 4-3-3, switch says
ON, match plays stock.

**Fix:** a third trigger, declared OURS — the CHOSEN SHAPE's forward-slot count.
`Career._ratings_for` publishes `front_three`; `MatchSim` folds it into
`Pm98StatMatch.cheat_manager_side` (renamed from `cheat_mixed_play_side`, which now carries
two triggers). The MANAGER_HACK.EXE trigger is untouched, so the PCode oracle table still
describes the patched binary exactly, and OFF is still bit-identical to stock.
`test_cheats_live` case A2 drives **all twenty Premier clubs** on an attacking 4-3-3 and
every one scores at least six (worst: Blackburn R., exactly 6).

The OPTIONS row now prints **ARMED** / **IDLE** from the same three triggers the engine
reads, so it cannot claim armed while the match plays stock. The old "N FW" readout answered
a question about only one of the three, which is what made the cheat look dead.

### 4. UNSACKABLE — already shipped, and verified end to end rather than relayed

Reported as "not implemented". It is: `Career.cheat_unsackable` (one early return at the
head of `sack_message()`, the port of the EXE patch's three unconditional jumps),
`AudioManager.set_unsackable` mirroring it, the OPTIONS row, the persisted `cheats` block.
Verified in the REAL app this session, not from the tests: `PM98_OPTIONS_SHOT` mounts the
hub, walks the dropdown to the panel, taps the ON box through the panel's own input handler
and reports `unsackable=true career=true`, and the rendered modal shows the row ticked. The
only live dismissal path in the port is `sack_message()` at the hub mount (`Main.gd:2140`);
`Main.gd:5691` is a screenshot harness. Nothing to fix — see the README for where it lives.

### 5. EUROPEAN QUARTER-FINALS IN NOVEMBER — the European calendar has a break

`Cup._schedule` spreads a competition's rounds EVENLY across the season. The real European
calendar does not: the early rounds run Sep..Dec and the quarter-finals onward are
Mar..May. With 39 league weeks from Sat 9 Aug 1997 the even spread put the Cup Winners' Cup
quarter-final at week ~16 (mid-November) and the U.E.F.A. Cup's at ~20.

Witnesses (`knockout_views_re.md`, the reference run's own probe log): euro QTR FINALS drawn
unplayed **January 1998**, 1st legs played **Sat 14 Mar 1998** (week 32); 1998-99 the same,
1st legs Sat 13 Mar 1999 and the SEMIFINALS Sat 27 Mar (+2 weeks); the FINAL still undecided
at week 38 in both seasons. Group phase from the hub badge: 1 Oct, 5 Nov, 26 Nov 1997.

**Fix:** `Cup._schedule` takes `tail_fracs`, which PINS the last N rounds and spreads only
the rounds before them. `Career.EURO_TAIL_FRACS = [0.82, 0.87, 1.0]` and
`EURO_HEAD_SPAN = [0.15, 0.54]`. Result on a 39-week season:

| competition | round weeks |
|---|---|
| European Cup | 8, 10, 12, 15, 17, 19 (six group matchdays) then **32, 34, 39** |
| U.E.F.A. Cup | 11, 16 then **32, 34, 39** |
| Cup Winners' Cup | 13 then **32, 34, 39** |

DECLARED OURS: the three fractions are fitted to those four dates; MANAGER.EXE's own
round-week table has never been located. What is witnessed is that the quarter-finals are a
MARCH event. `test_europe` still resolves every competition to a champion inside the season.

**And the SORTEO no longer interrupts you for a cup you are not in.** `_queue_cup_draw`
tests the drawn round's own player list for the manager's club — the drawn round, not
`Cup.still_in`, because the domestic cups hold the Premier clubs out until Round 3 and a
survivors test would suppress the very draw the reference run witnesses being raised. Also
DECLARED OURS: no frame shows what the original does for a non-participant (the reference
run's club was in the European Cup and both domestic cups all season). The bracket is
unchanged and every round stays readable on the KNOCKOUT screen.

### 6. TWO CARRIED ITEMS WERE ALREADY CLOSED — the s78 §7 list was wrong about both

Re-checked against the code rather than relayed, which is how the other three in that
section turned out to be closed too:

**S5 — "European ties run on the LEGACY engine ... verified still live in `MatchSim.gd`".
FALSE.** What is still live is the fallback CODE PATH, not its use. The only
`[MATCHSIM_FALLBACK]` lines anyone sees come from `test_europe.gd`'s own rig, which invents
opponents at ids 90000+ that have no `club_tactics.json` entry and therefore cannot be in
the true-XI index — a property of the test fixture, not of the game. Driven on the REAL
data (the true-XI index `Main._true_xi_index` builds, the real foreign pool
`Main._euro_pool` builds), a whole European season runs with **zero** fallbacks and all
three competitions reach a champion. All 96 pool clubs are indexed, out of 475 in the whole
index. Pinned so it cannot silently regress: **`app/tests/test_euro_stat_engine.gd`**.

**"The three `+0x43c` null sentinels — absent / 0 / -1, behaviour-affecting, not
unified". FALSE, and by a commit that predates the claim.** `f5ab46c` (s59) unified them to
the binary's own model — null = int 0, non-null = the player Dictionary. Every read is
`m.get(0x43c, 0)` and every clear is `m[0x43c] = 0`; there is no `-1` sentinel left in
`Pm98Driver` or `Pm98Dispatch`, and `Pm98LiveMatch` documents the int-when-unset contract
at its own read site.

### 7. ⭐ O1 — the board objective was a POSITION from season two on, and it broke the band

The audit's O1 ("the board objective is the wrong kind of thing": the original states
`Avoid Relegation`, the port stated `Finish 13 or higher`) was half closed already —
`club_economy.json` carries the witnessed START OF SEASON label for 92 of the 94 English
records and `_set_objective` uses it. But only in season ONE. Every rollover calls
`_set_objective({}, ...)` with an EMPTY club, because a season-2+ board is un-witnessed, so
it fell through to `objective_for`, which writes its own prose.

Driven for four seasons with Bolton W — the audit's own example — the port read:

| season | objective | band |
|---|---|---|
| 1 | `Avoid Relegation` | 3 |
| 2, 3, 4 | `Avoid relegation` (small r, the fallback's own string) | **-1** |

**And the -1 is the real damage.** No fallback string is a key of `BOARD_BAND_OF_LABEL`, so
from season two onward `expectation_band()` answered -1 for the rest of the career and the
board review, the sack ladder and the improvement test all silently took the -1 arm.

**Fix:** Main's own position→category map (`_objective_label`, which until now only the
OFFERS SELECTION preview could reach) moved to `Career.objective_label`, and the fallback
uses it — so the RANK stays the app's strength-ranked rule (the original's assignment rule
is un-RE'd and still declared ours) while the LABEL is always one of the game's own five
categories. `objective_pos` is then re-derived from the label, so the position and the
category can no longer disagree. The OFFERS SELECTION OBJECTIVE cell was printing the raw
prose too and now prefers the club's own witnessed label. All four seasons read
`Avoid Relegation` / band 3. Pinned by **`app/tests/test_board_objective.gd`**.

### 8. Gates

`run_full_sweep.sh` **245 of 245 PASS, 0 FAIL** on an undisturbed box, including the two new
suites. `diff_entry_parity` 18/18 with `makeoffer_101` at 0 px. `diff_options_parity` PASS.
The hub header and the OPTIONS cheat rows were confirmed by LOOKING at real-app renders
(`PM98_HUB_SHOT`, `PM98_OPTIONS_SHOT`), not inferred.

Two instrument notes, because both cost time this session: the sweep's 400 s per-suite
timeout means any other Godot job running alongside it makes the M5 oracles time out and
report FAIL (each passed instantly when re-run alone) — run it on an idle box. And `~/godot4`
(4.3) and `~/godot462` (4.6.2, what CI uses) fight over the same `.godot` import cache, so
after the other one has touched it every suite dies on a `class_name` parse error; re-run
`--headless --import` for whichever binary you are about to use.

### 9. M5 s59 IS in the shipped build

Asked directly. `f5ab46c` and `8b73433` — the +0x43c unification and the four engine bugs
the 7-hour capture falsified (byte-exact clk 1-2836, 1,072,592 words, 0 mismatches) — are
both ancestors of HEAD, so they are in `pm98-d9d470d.apk` and in every build since s59.

## 0aaaaaaaaaa. Closed 2026-07-28 (session s78) — THE CUP TV FEE, THE CAMERA MOTION, THE KIT RESIDUAL

Mats's brief was the whole s77 carried list, "get the game done now". Six items moved. Three
did not, and they are named at the end with the reason.

### ⭐ THE CUP channelTV FEE — CLOSED, and the search that had failed was the fault

`finance_screen_re.md` concluded "there is no `mov [reg+0x290], <value>` anywhere in `.text`
… so the producer must reach the field through an aliased base". **Both halves were wrong.**
The earlier scan was a LINEAR sweep, and this image has data interleaved in `.text`, so it
desynchronised and walked past whole functions. Decoding **per function entry** finds 80
`disp == 0x290` operands where that sweep reported 40 — and twenty-four of them are the
producers. The aliased-base theory is not merely unproven but refuted:
`tools/re/scan_alias_writes.py` does that search properly (a forward abstract interpretation
tracking `(root, offset)` per register) and finds nothing.

Each competition class writes the fee itself as an imm32, gated on `club+0x5c != 0xffff` (the
managed club). At 200 internal = £1 the whole table falls out, and both previously unsourced
captured cards are explained:

| competition | writer | £ |
|---|---|---|
| Premier / First / **Second and Third (ONE shared jump-table arm)** | `FUN_00417240`, table @`0x417570` | 90,000 / 45,000 / **35,000 / 35,000** |
| European Cup · U.E.F.A. Cup · Cup Winners' Cup · European Supercup | `0x454cfd` · `0x45c8e8` · `0x461f77` · `0x463dc0` | **375,000** each |
| Charity Shield · Intercontinental Cup | `0x405b18` · `0x43275d` | **187,500** each |
| **F.A. Cup · Coca-Cola Cup** | **none** | **0** |

**And that last row is a RESULT, not a gap.** Neither the `FACUP` nor the `CCCUP` class block
contains a single write to `club+0x290`, by displacement or through any alias chain. Five
driven careers never saw a domestic-cup channelTV card because **the game never raises one**.
The port's long-standing "cup ties pay £0 and say so" was already correct; it stops being a
flagged gap. A sixth four-hour drive was not needed and is not needed.

Record: `docs/re/channeltv_fee_re.md`. Reproduce every row from the bytes:
`python tools/re/dump_tv_fee_table.py`. Ported as `FinanceModel.TV_FEE_INTERNAL` (the raw
imm32s) + `TV_FEE` (the same in £) + `tv_fee()`; the Supercup and Intercontinental now book
their TELEVISION line the way the Charity Shield already did. Gate:
`test_channeltv_screen.gd`, which pins every row, the ×200 relation and both proved zeros.

### THE CAMERA MOTION — `camera_re.md` §7 CLOSED, ported, and rendering

All three prerequisites §7 listed are read out of the image (`docs/re/camera_motion_re.md`),
and **two things `camera_re.md` itself asserted turned out to be wrong**:

* **"eight arms, one per mode"** — the guard is `cmp eax, 0xa / ja` and the jump table at
  `0x59830c` has **ELEVEN** entries. The eight are the compass ring around the ground; modes
  8 and 9 are two low goal-line angles and mode 10 is a free camera.
* **"`eye = lookAt - dir*distance`"** — `+0x48` is an ANCHOR POINT, not a unit direction.
  The binary normalises `lookAt - anchor` first (`FUN_005ee200`) and `+0x78` is the eye's
  distance **from the look-at**. Read literally, that formula would put the eye kilometres
  away.

Also newly read: the rate is `ftol(dt_ms * 0.003 * 65536)` — a 4.8 %-per-frame ease, not a
speed; the anchor's far path is an **ARC**, a polar lerp about the look-at with the angle
delta sign-extended to 16 bits first (which is what makes it take the short way round); the
look-at box is inset 2 m in X/Y before its clamp; and the restart cut sets a **distance**
(9 m, or 5.5 m on a goal) as well as a height.

`app/scripts/Pm98CamCtrl.gd` is that controller in integer 16.16 on `Pm98Trig`'s own LUTs,
fed by `Pm98LiveMatch.camera_state()` off the live `matchctx` and run once per display frame
by `MatchSimulador`. **Verified three ways:** 70 arithmetic identities
(`app/tests/test_cam_ctrl.gd`); a run on the byte-exact engine (the camera moves, and the eye
never leaves the box the driver rebuilds each frame); and **the REAL APP under Xvfb + GL**
(`tools/re/refs/cammotion-2026-07-28/`), where the grass/hoarding seam lands at rows
**77 / 79 / 80** against the original's own five captures at **82 / 65 / 90 / 82**. Same band,
moving frame to frame — corroboration, not a pixel match, and the strongest check five
unknown instants of a live match can support.

Declared divergences are in `camera_motion_re.md` §6: the rotation is applied as a DELTA to
the fitted pose rather than absolutely (the app's projection is the axis-aligned reduction the
fit was solved against, and nothing can re-fit a moving one); the camera MODE is a choice
(mode 6, the only arm that puts the eye on -Y as the capture shows) because `session+0xfe0`
is not modelled; the ball-anchor look-at falls back to the ball itself; and the scripted shot
paths are not modelled at all.

### ⭐ THE "48x64 MINIESC" RESIDUAL — CLOSED, and it was never the kit bank

The MAN-TO-MAN kit rect now diffs at **0 px on both careers**. The cause was **one column of
a bake**: the vertical club plate is NINETEEN columns of black (`x243..x261`), not the twenty
its panel-relative box suggests, and `build_mantoman_chrome_from_frames.py` filled `x262`
black too. `x262` is kit-local `x = 33` — the exact column of the residual.

| bucket | before | after |
|---|---|---|
| kit rect, both careers | 15 px | **0 px** |
| shadow-pass bucket | 50 / 51 px | **36 px** (the D and M letter glyphs, unchanged) |
| plate bucket | 122 / 123 px | **19 px** |

Two carried claims die with it: "the 48x64 MINIESC bank is missing content" (the bank is
correct — the PNGs are already transparent there) and "the original paints pure black and the
port has transparent" (the reverse — the port's baked body was black and the original's panel
is white). Measured on both witnesses at `y = 430`, a plain plate row well clear of the kit.

### THE STADIUM TILES' ROW OFFSET — validated on 12 of 12, from the data alone

`stadium_screen_re.md` had the ±256 column wrap validated on all twelve tiles but the ROW
offset (`+2` for `bx < 64`, `+1` otherwise) confirmed only on tiers 3 and 4, where a real
GROUND capture exists, "because a one- or two-row error would not move the seam statistic".
True of that statistic, false of the right one: the row offset is a RELATIVE shift between two
blocks of the SAME picture meeting at `x = 63|64`, so a wrong offset leaves a one-row vertical
discontinuity exactly there. `tools/re/verify_estadio_rowoffset.py` scores that boundary under
five candidate shifts on every shipped tile — **the shipped offset is the minimum on all
twelve**. Margins are small (1.5–4.5 mean-|Δ|) because the two sides are different stand
geometry and the join is never smooth; what the test settles is WHICH shift is least bad, and
it is the shipped one twelve times out of twelve.

### ⛔ THE EURO-GROUP KIT SHADOW PORT — TESTED AND WITHDRAWN

This list carried "port the s73 shadow bake to EuroGroupScreen's 24 group kit cells (~1260
px/frame)" on the assumption that those blits are the same `FUN_004b7f60` class the MAN-TO-MAN
screen's are. **That assumption was never tested, and it is wrong.** `PMShadow` was wired under
the group leader's NANOESC kit and the four RIDIESC kits against this screen's own chrome; the
gate got WORSE: 864/873/896/876/875/881 → 1048/1059/1078/1060/1058/1063, and the leader cell
alone 1236 → 1269 over six frames. The wiring is reverted and the entry is withdrawn rather
than left open against a wrong theory.

What the residual actually is, measured on group A's leader cell (202 of 768 px): a one-pixel
rim following the silhouette where the original is consistently **LIGHTER** than the port
(`(59,85,130)` vs `(20,0,90)`) — the opposite direction to a drop shadow, which only blends
toward black — plus a solid block over the sprite's right half. Two different causes, neither
reversed. Recorded in `euro_league_screen_re.md`.

And the arithmetic of that gate is worth stating: the four RIDIESC cells are already at
16 / 0 / 5 / 0 px per frame, and **649 of the ~880 per frame is the barra manager kit**, which
is not a rendering gap at all but a CAPTURE gap — `art/kits/header/40.png` is a verbatim cut of
Man Utd's manager-mode panel, kit and furniture together, and no frame in the corpus shows that
panel with any other club's kit, so the background behind it has never been seen unoccluded.

### THE UNMANAGED-CLUB RELEASE LADDER — read in full

`FUN_0057b6b0` is no longer "not reversed". It skips foreign clubs (`club+0x10 > 0x26ae`),
runs only for the hot seat and only in season-advance MODE 1 (`DAT_0066b1e4`, set by
`FUN_004f80a0`'s `0x4e35`/`0x4e36` dispatch), and detaches the manager exactly when
`FUN_0057a570` says his club is **no longer a member of the league it was hired into**
(`club+0x50` indexes `DAT_0066b190`; `vtbl[0xc8]` is the membership test; index ≥ 4 counts as
"still in"). Single caller: `FUN_005865b0`, itself called once from the season driver
`FUN_004f8a00 @0x4f8dd6`. **Not ported** — the port has no league-membership model to hang it
on, and that is said rather than approximated. Record: `sack_path_re.md`.

### NOT done in s78, said plainly

* **The three M5 set-piece leaves** (the IF-B same-team set-piece runner, b1420's b1500/b1c80
  role sub-leaves, ps-9 chase geometry) — untouched. Still the live-confirmed M5 blocker at
  dispatch 3, and still the gate on goals 2-7 and full time. This is a multi-session
  exact-port job and the budget went to the six items above.
* **"Free if relegated"** — the clause is fully settled as offer-record `rec+0x10` with a 0-px
  checkbox render, but what it DOES on relegation is STILL not found. The offer-COMMIT path was
  followed to `FUN_005889c0` (the accept test reads only the asking price and the player's own
  `+0x70`/`+0x98`/`+0x9a`) and carries no consumer of the clause.
* **`KnockoutScreen` → `PMShadow`** — deferred a fourth time, same reason, and the euro-group
  measurement above makes it weaker still: `PMShadow` is demonstrably not the universal answer
  for kit blits, so a refactor onto it is not obviously even correct.
* **B9** — needs a driven career with a COMPLETED youth search (30-55 weeks), which has never
  been driven.
* **The 48x64 on-sprite EDGE BEVEL** and **OffersScreen's panel** — un-reversed.
* **HIGHLIGHTS** — DATA gap. **s85: "absent" was wrong — UNOPENED.** `PCF5DAT.PKF` (314 MB,
  ISO-only) has never been enumerated.
* **The real-device pass** — there is no Android device on this box. **This one needs Mats.**


## 0aaaaaaaaa. Closed 2026-07-28 (session s77) — UNSACKABLE, and the HUB CIRCLE

Mats's brief was: a new UNSACKABLE cheat on the hub dropdown first, then the s76 carried
list. What closed, what moved, and what did not, said plainly.

### UNSACKABLE — BUILT, and it is three bytes

`FUN_00545fd0` IS the weekly hub screen's own `run()`. Before it draws the menu it tests
three dismissal conditions and on ANY of them raises one modal, calls
`FUN_0057a500(club, 0xffff)` and ends the career. Every "keep him" branch is a **2-byte
short jump whose target is exactly the next test**, so the whole cheat is flipping three
opcodes to `JMP rel8` with their displacements untouched:

| site | VA | stock | patched | target (unchanged) |
|---|---|---|---|---|
| finance | `0x546019` | `0x76` `jbe` | `0xEB` | `0x54603a` |
| results | `0x546044` | `0x74` `je` | `0xEB` | `0x546063` |
| squad | `0x546067` | `0x73` `jae` | `0xEB` | `0x5460a8` |

No cave, no relocation, no displaced instruction. `build_hack_exe.py` gained `--cheats=`
and asserts both the stock opcode AND the decoded target before writing; a
`--cheats=unsackable` build differs from `MANAGER.EXE` at **exactly three file offsets**.

**Proof is CFG reachability on the real bytes** (`tools/hack/verify_unsackable.py`): all
three message arms and the shared modal+detach block are reachable from the function entry
in `MANAGER.EXE` and **unreachable** in `MANAGER_HACK.EXE`. The stock rows are the load-
bearing ones — they show the walk really does reach all three arms.

Port: `Career.cheat_unsackable`, one early return at the head of `sack_message()` /
`sack_message_reason()` (which ARE those three tests, in the binary's order). Switch is
`AudioManager.set_unsackable`, persisted in the same `[cheats]` block; UI is a second
OPTIONS row above THREE UP FRONT. Gate `app/tests/test_unsackable.gd`, 31 checks — a
39-week driven season with all three conditions **re-armed after every week** raises zero
dismissals, while the identical state with the cheat off does dismiss.

**Found doing it, and it was a real defect in the standard:** the OPTIONS band's emptiness
test only looked for label-gold and OK-plate red, so it MISSED the modal's own **white**
ON/OFF captions at rows 308..314 and the first two-row layout drew straight through them.
Re-measured over gold + red + white the free band is `(138,315,288,29)`.
`diff_options_parity.py` now tests white too **and diffs the LIVE Godot render** as well as
the baked chrome — **0 px vs the MANAGER.EXE capture outside the band**, which that file's
own docstring had said was never built.

**NOT covered, said plainly:** `FUN_0057b6b0` @`0x57b6e5` is a SECOND
`push 0xffff / call FUN_0057a500`, swept over a club list by `FUN_005865b0`, gated on the
Promanager flag `DAT_0066b1e4` and on `FUN_0057a570` (`club+0x50` -> the competition's
`vtbl[0xc8]`). It is not one of the board's three dismissals, it is **not reversed**, and
neither the patch nor the port touches it. It is the same thread as "free if relegated"
and "the unmanaged-club release ladder" below.

### THE HUB CIRCLE — REBUILT from the game's own pixels (s76 items 12 + 13, both closed)

The shipped `menu_bg.png` had one career's six bars baked in plus two flat
`(108,120,150)` blocks, and a hand-cut `circle_home.png` repainted it for the other
arrangement. Nothing about the circle is hand-cut any more:

* **`RECURSOS.PKF` `FONDO3.BMP` IS the hub background**, circle, white rim and inner
  marble included — pixel-identical to the real MENUPRINCIPAL frame everywhere except the
  six bars and the two kits. `menu_bg.png`'s circle interior is now exactly those pixels
  (gate: **0 px**).
* **The bars are `FUN_00549240`'s own literal rects** (six `FUN_0043ce50` fills, six 1 px
  `FUN_00468c90` frames) at the widget rect `(220,173) 205x173` (`FUN_00436fb0` operands
  @0x547cad). Frames are pure white on the player's side, pure black on the other,
  measured on all twelve borders.
* **The fill is a DITHER, not an alpha blend.** `FUN_0043ce50`'s 100/256 does not
  reproduce in RGB: the best-fit alpha is 96..106 and still only ~50 % of non-ink pixels
  come out right after snapping to MANAGER.PAL. Measured, the result is an exact function
  of **(destination FONDO3 palette INDEX, `(x+y)&1`)** — the same absolute-screen-parity
  checkerboard `shadow_blit_re.md` found in `FUN_005d5220`. The baker learns that table off
  **179 hub frames** discovered in the corpus and repaints both schemes; exactly one cell
  no frame covers is derived from its parity partner and printed.
  **Result: chip and manager bars 0 px on BOTH arrangements**; the two club bars keep a
  small residual that is the proman12 club name's own drop shadow, capped and named.
* **The hub kit is the 24x32 NANOESC sprite**, not the "~50x65 two-shirt group" the doc
  carried: `FUN_00579710` caches `club+0x18` from `DBDAT\NANOESC\eq96%04u.bmp`, blitted at
  widget `(2,48)`/`(178,94)` -> screen `(222,221)`/`(398,267)`. The 45x57 stand-in is gone.
* **The NATION FLAGS are BUILT.** `BANDERAS.PKF`'s 127 entries all decode **30x20**, and
  the port's own `flag_022` (Spain) / `flag_030` (England) reproduce walkthrough
  `001_160008` at **0 px** at `(308,143)` and `(308,355)`. The old "~55x35 at ~(295,138)"
  estimate is superseded.

New gate `tools/re/diff_hub_circle_parity.py`; `hub/circle_home.png` retired.

### THE M5 HARNESS SPIN — the outer-loop half is FIXED, and the rest is now LOCALISED

s76 item 11(a) carried this as "fix the `run_match_from_struct.gd` WATCH-harness spin
(>5 h post-goal; Outer wait-loop / +0x1a2c goal-latch interplay)". Measured, it is two
different things and only one of them was the outer loop:

* **The outer-loop half is closed.** Under the dump's play-state 4 the wait loop breaks on
  the goal's `+0x1a2c` and then `_dequeue_flush` CLEARS it, so the next step has nothing
  left to break on and spins its whole 40,000-frame guard with the clock frozen. Two
  things were missing, both modelled now: `+0x1a1f`, which `_live_branch` sets from the
  GLOBAL PAUSE byte `DAT_00674cb3` (0 headless) and which is exactly what is set while an
  events board is up; and the KICK OFF click itself, which reaches `FUN_00593ab0` as a
  nonzero pump result whose skip path arms `+0x1a1e`. `Pm98Outer.next_pump_result` is the
  injection point; the reference capture was itself driven with one KICK OFF click per
  board pause, so this reproduces how the reference was made. **Verified: the clock and the
  RNG move again and `+0x1a1e` arms in two steps instead of never.**
* **What is left is the RESTART, and it is the deferred leaves.** With `PM98_TICK_PROBE`
  the driver was called directly 3,000 times straight after the goal: it returns 1 for
  **eight** ticks and then **0 forever**, with `clk` / phase(`+0x448`=8) / dispatch
  (`+0x1a38`=6) all frozen. So the engine IS reporting "segment over" and it is the
  restart ladder — `Pm98Driver.restart_handler`, reached through the `+0x1a1e` one-shot
  gate — that does not complete. That is precisely where the three still-deferred leaves
  live. **So road step (a) is not independent of step (c): goals 2-7 are blocked on the
  leaves, not on the harness.** Recorded here rather than buried.
* A **stall guard** was added so this reports instead of hanging: the harness watches
  `clk + banked` and gives up with a state line after 3 frozen steps.
* **RESULT: the match now plays ON past the goal, and where it stops next is a SET PIECE.**
  The full run reads:

  | step | clk | phase | dispatch | +0x1a1e | kickoffs |
  |---|---|---|---|---|---|
  | 1 | 2837 | 8 | 6 (GOAL) | 0 | 1 |
  | 2 | 2837 | 8 | 6 | **1** (armed) | 1 |
  | 3 | **3885** | 8 | **3** | 0 | 2 |
  | 4 | 3885 | 8 | 3 | **1** (armed) | 2 |
  | 5 | — | — | — | — | wait-loop guard breached |

  Step 3 is the proof: play resumed after the goal and ran **another 1,048 clks** to the
  next event on its own. The board-pause model is therefore right, and the ">5 h post-goal
  spin" is closed.

  What stops it now is **dispatch 3** — a set piece — and it stops with the wait loop's own
  pre-existing message: *"set-piece never resolves; +0x1a20 latch caveat"*. That is exactly
  the three still-deferred leaves (the IF-B same-team set-piece runner, b1420's b1500/b1c80
  role sub-leaves, ps-9 chase geometry), all of which are set-piece machinery. So this is a
  LIVE confirmation, not an inference, that road step (c) is the next blocker and that
  goals 2-7 come after it, not before. **Goals 2-7 and full time were NOT reached this
  session** and are not claimed.

### The 48x64 MINIESC "56 px" entry is STALE

Re-measured this session against the same witness (`058_162622`, Man Utd vs F.C.
Barcelona): the kit rect's residual is **15 px**, not 56, and they are a single 1 px column
at kit-local x=33, rows 30..63, where the port paints black and the original paints
panel/shadow. The two crops are visually identical. It is a real residual and it stays
open, but at a twentieth of the size the list claimed, and the doc's "the original paints
pure black and the port has transparent" description is the wrong way round.

### NOT touched in s77, said plainly

The **camera-motion port**, **B9**, the **cup channelTV fee** (a fifth career was driven
this session and is recorded below), the **48x64 kit on-sprite EDGE BEVEL and the port of
the s73 shadow bake to EuroGroupScreen's 24 group cells + OffersScreen's panel**, the
**MINIESC residual** (now measured at 15 px, see above), the **stadium tiles' row offset**,
**"free if relegated"**, the **unmanaged-club release ladder**, the **`KnockoutScreen` ->
`PMShadow` refactor** (same reason s74 and s76 gave: it renders correctly today, its gates
are green, and it is a pure refactor with regression risk and no visible change),
**HIGHLIGHTS** (an unchanged DATA gap — the `.p3d` models are absent) and the **real-device
pass** (there is no Android device on this box and it cannot run the built APK; the desktop
number is 63.6 engine frames/s and the phone is still unmeasured — this one needs Mats).

And on the M5 road, past the set piece §11 above stops at: **goals 2-7 + full time**,
**stoppage-time handling** (reference `ft_clk` 14599 vs the port's raw-loop 14400, an
unverified engine area), the **H1-remainder + H2 capture loop**, the **cross-seed sweep**
(`PM98_SEED`, plumbed s55, still unrun — the only thing that proves the engine exact as a
FUNCTION rather than on one trajectory) and **unifying the three `+0x43c` null sentinels**
(absent / 0 / -1, behaviour-affecting).

One lead worth carrying on the cup fee rather than a sixth drive: `club+0x290`'s PRODUCER
was never found by a disp32 xref sweep, and s76 proved that class of miss is real
(`FUN_005f5850` writes through a REGISTER pointer, which a disp32 sweep cannot see). A
register-base search may beat another four hours of driving.

## 0aaaaaaaa. Closed 2026-07-28 (session s76) — THE KIT RECOLOUR, THE CAMERA OBJECT, THE MARKINGS

Mats's list was s75 §6 and §7 plus the data/doc tail. What closed, and what did not, said
plainly at the end.

### THE PER-CLUB KIT RAMPS — CLOSED. This was "the biggest remaining visual gap".

**The original never bakes a coloured player.** `JUG.PGF` stays 8-bit PALETTE INDICES and
`FUN_005d34a0` remaps every pixel through a 256-byte LUT immediately before the blit. The whole
chain that builds that LUT is reversed and ported (**`docs/re/kit_palette_re.md`**):

* `FUN_005b63e0` — `DatSim\paletas\P96A<key>.DAT` is 192 bytes: `[0..127]` the **16x8 shirt
  pattern grid** (each cell a palette RAMP BASE), `[128..175]` the 48 LUT entries that land on
  palette slots **9..56**, `[176]` the kit CLASS colour. The away side falls to **P96B — its
  CHANGE STRIP** — exactly when its class equals the home side's, and `matchctx+0x742` IS team
  0's own `+0x2d6` (`0x46c + 0x2d6 == 0x742`). The number ink is `0x67` or `0x7f` on the GREEN
  byte of the match palette's entry for that class.
* `FUN_005a2830` — the player's own copy of the pattern with his **SHIRT NUMBER** stamped into
  its right half out of `NumCam.bmp`'s sixty 8x8 glyphs, plus his SKIN and HAIR ramps.
  **`.DBC +0x16` and `+0x17` — both carried as "semantics un-RE'd" — ARE skin tone and hair
  colour**: the 9,547-player database uses `{1,2,3}` and `{1..6}`, exactly the three skin ramps
  and the six non-redirect hair rows, and hair index 1 is the BALD redirect to `skin + 6`.
* `FUN_005a5460` — skin to LUT[1..8], hair to LUT[0x15..0x18], then the pattern painted through
  JUGCAM for this frame's map.

**`JUGCAM.IND` is CLOSED and it is not a camera table** — the name misled the old spec. Its one
consumer gives the layout with no ambiguity: **72 maps x 16 cols x 8 rows x 6 shades = 55,296
bytes, the file's EXACT size**. The `.PGF` header word **`h5`**, listed as an open GAP, is that
map index and spans exactly 0..71. And **`h0`, not `h4`, is a frame's visible width** (`h0 <=
h4` in all 4211 frames and the columns past `h0` are blank in all of them) — the old bake made
every padded frame slightly too wide.

Proven in the REAL APP under Xvfb + GL: `tools/re/refs/kit-2026-07-28/` shows United in red
shirts and white shorts, Liverpool in their CHANGE strip, per-player skin and hair, numbered
backs. Gate `test_jug_render` +22 assertions.
**One declared divergence**: the keeper strip's re-roll RULE is the binary's, but its draw comes
from the display LCG, a stream this port does not reproduce, so the seed is the fixture's clubs.

### THE CAMERA OBJECT — REVERSED, and it corrects two s75 "NOT reversed" rows

`docs/re/camera_re.md`. The controller is `matchctx + 0x27f0`, fixed by `FUN_00598141`'s two
clamp boxes. With that base:

* **THE EYE.** s75 recorded "`camctrl+0x3c` is zeroed by its ctor and a sweep finds no other
  writer — yet `FUN_005f6230` passes that very address to `SetCamera`." The writer is
  `FUN_005f5850`, and it writes **through a register pointer**, which a disp32 sweep cannot see.
  `eye = lookAt - dir*distance`, then clamped.
* **THE ORIENTATION.** Same story — `yaw` and `pitch` are recomputed every frame from the
  eye->look-at vector. `jug_render_spec.md` §5's "constant-0 words, therefore a pure
  translation" is now refuted from the CODE as well as from the capture. Only **roll** is
  genuinely never written.
* Also read: both clamp boxes exactly, the eight-arm camera MODE switch driven by
  `session+0xfe0` (a MATCH OPTIONS setting), and the **RESTART CUT** — on `matchctx+0x448` in
  {3,4,5,6,7} the eye jumps 50 m behind the tracked actor at 6 m, or 5 m on a GOAL.
* And it is **measured**, not asserted, that the original's camera moves: the grass/hoarding
  seam sits at screen row **82 / 65 / 90 / 82 / 0** across the five banked WATCH frames.

**The PORT of the motion is still open** and §7 of that doc lists exactly the three things it
needs. The app still holds the s75 fitted pose, which is `watch_02`'s instant.

### THE PITCH MARKINGS — SOURCE-READ (they were "declared, not source-read")

`docs/re/pitch_markings_re.md`. `FUN_0059a8c0` builds the whole set from `matchctx+0x1820` /
`+0x1824` with every other figure a literal operand. Two things the port had wrong: the **D's
half-angle is the binary's own `0x2640` = 53.79 deg**, not the derived
`acos((16.5-11)/9.15)` = 53.06 deg; and the centre and penalty marks are **0.4 x 0.2 quads**,
not dots. The touchlines / goal lines / halfway line now come out of the engine's own two loops.
Still not source-read, and said so: the grass shading.

### ⚠ FOUND 2026-07-28 FROM MATS'S OWN REPORT — the MANAGER MENU hub circle is broken

A shipped, user-visible defect on the game's MAIN screen, not previously on any list.

* **`app/art/screens/menu_bg.png` is not reproducible from its own baker.** Re-running
  `tools/re/build_menu_bg_from_ref.py` against `tools/re/refs/menuprincipal_ma_6.png` changes
  **26,888 px below the header band** — so the shipped asset is stale or hand-edited.
* **In the shipped asset the circle's white rim is BROKEN and the club bars run OUTSIDE the
  ring.** The reference frame's ring is complete and its bars are inset. Re-baking fixes that
  much.
* **But re-baking alone is not the fix.** The baker's `CREST_SPOTS =
  [(222,208,258,258), (394,256,426,306)]` are 36x50 / 32x50 filled with a FLAT `(108,120,150)`,
  and they land on the bar frames and the rim. The hub's kit is the **24x32 NANOESC** art
  (verified: `NANOESC.PKF` entries decode 24x32, a shirt+shorts pair; the 48x64 MINIESC pair is
  what the match view uses) over a fine DITHERED marble — so the blocks are both oversized and
  the wrong texture. Fixing it needs the widget's SCREEN ORIGIN read out of the binary so
  `hub_circle_re.md`'s own anchors (widget `(2,48)` top, `(178,94)` bottom) resolve to exact
  rects. **Deliberately not guessed**, and the shipped asset was left untouched rather than
  replaced with a differently-wrong one.
* **The nation FLAGS are absent.** When the clubs' nations differ the original draws one above
  and one below the ring — `001_160008.png` (Man Utd vs F.C. Barcelona) has the Spanish flag at
  ~(295,138) and the English at ~(295,348), ~55x35 each. `hub_circle_re.md` lists the flag
  sibling widget as un-chased; the port draws neither.

### The full suite sweep — RUN, and clean

The "232-file manual pre-release step" was run end to end: **all 241 `test_*.gd` files**,
headless, 400 s timeout each. **241 of 241 clean, zero failures.** (CI's curated gate is 32 of
them; the rest are the M5 engine-leaf oracles and the per-screen suites.)

### The two carried "opens" that turned out not to be

* **`shot_squad_card_tapthrough` DOES NOT REPRODUCE.** Open since s70 as "2 of 10". Run three
  ways on this box: headless (the harness self-skips — it needs a rendering driver), Xvfb
  800x600 + GL **10/10**, Xvfb 1280x960 + GL **10/10**. It was that one run's display.
* **The `.bin` assets were not in the Android export filter.** `export_filter=all_resources`
  with an empty `include_filter` does not carry plain binaries, and the match bank is now
  3.9 MB of them (and `data/shadow_lut.bin` was already one). `include_filter="*.bin"`.

### NOT touched in s76, said plainly

The **camera-motion port**, **B9**, the **cup channelTV fee** (a lower-division career was
driven for it this session and is recorded below), the **P2 data tail** (~876 directory-only
foreign teams, the LZ-packed rating tables, the MINIESC 56 px, the 10 stadium tiles, "free if
relegated", the unmanaged-club release ladder) and the **`KnockoutScreen` -> `PMShadow`
refactor** — the last deliberately, for the same reason s74 gave: those render correctly today
and their parity gates are green on the baked art, so it is a pure refactor with regression
risk and no visible change.

**"Free if relegated" got one step, not a close**: the string's only code reference is
`0x52bfc0`, where **bit 3 of the offer flags at `screen+0x144`** picks between a checked and an
unchecked checkbox draw at (230, 420). So it is a contract-offer CHECKBOX and its flag bit is
known; what the flag DOES on relegation is not found, and is not guessed.

## 0aaaaaaa. Closed 2026-07-28 (session s75) — THE MATCH PRESENTATION

Mats's brief was the match-engine graphics: *"APP_VS_SPEC_AUDIT A6/A7/A8 — the engine renders
a pseudo-3D two-billboard sprite under a fixed 3/4 camera, it has no side-on 2D view at all;
`_facing()`'s 45-degree compass is an invention; the sprite sheet is the transpose of the real
JUG layout"*, with **PCF5DAT.PKF named as the one hard gap**. All three audit rows are closed
and the "hard gap" turned out not to exist.

### PCF5DAT.PKF is NOT the pitch background — it is a CD check

The carried claim was never checked against the binary. `PCF5DAT.PKF` has **exactly one xref**
in `MANAGER.EXE` (@`0x4f82ed`): the function at `0x4f82e0` opens it, `_llseek`s to **`0xecbf`**,
`_lread`s **six bytes** and compares them to the literal **`D.G.C.`** — which the file really
does carry at that offset. That is a CD-presence check on a 314,854,588-byte PC Futbol 5 data
pack, nothing more; `enum_pcf5dat.py` independently reports it does not follow the PM98 PKF
directory grammar at all. **The simulador's art is DATSIM's own throughout** (`campina.raw`
@0x59311f, `hierprem.raw` @0x59302c, `hierba`/`hierarg`/`hiebarsa`/`hiercal`/`hiercale`/
`hieprees`, `cielo1.bmp`, `red.bmp`, `balon.raw`, `jug.pgf`, `NumCam.bmp`). Full record:
**`docs/re/pcf5dat_re.md`**.

### The real WATCH view was CAPTURED, and it corrected the reversed camera

There was no capture of the original's WATCH view anywhere in the corpus, so one was driven:
wine at TOTAL control, title -> career -> MATCH OPTIONS -> **WATCH** -> KICK OFF. Frames are in
**`tools/re/refs/watch-2026-07-28/`**. They refute `jug_render_spec.md` §5's static conclusion
that *"yaw/pitch/roll are the constant-0 words `camctrl+0x8c/0x8e/0x90`, so the view matrix is
pure translation"*: the hoardings run flat across the top as the **far touchline** and the
halfway line **recedes**, so depth is world **Y** (the width), which a rotation-free matrix
cannot produce. Recorded as a correction in `jug_render_spec.md` §3b.

* **What IS reversed, exactly**: the projection. `FUN_005eec60` is
  `sx = ox + u/z`, `sy = oy + v/z`, `z = -(d>>8)`; `SetCamera` composes the diagonal scale
  `FUN_005eea50(0x10000,k,k)` with `k = ftol(width * 0.00390625 * 65536.0) * camctrl+0x88 >> 16`,
  and `0.00390625 * 65536 = 256`, so **focal length = the viewport width in pixels**.
* **What is NOT reversed, and is said so**: the eye (`camctrl+0x3c` — zeroed by its ctor
  `FUN_005f56a0` @`0x5f56d2`, no other writer in `0x5d7000..0x5f9000`) and the orientation.
  The POSE is therefore **fitted** to the capture on three exact pitch landmarks (the
  grass/hoarding seam at world Y=+38 m and the centre circle's two arcs at +/-9.15 m):
  eye (-6.08, -36.02, 18.65) m, origin (320.4, -72.2), **vertical residuals ~1e-12 px**.
  Re-run it: `tools/re/fit_watch_camera.py`. Ported: `app/scripts/Pm98Camera.gd`.

### The JUG bank is now indexed the engine's way (A7/A8)

* **`tools/re/export_jug_bank.py`** bakes **all 4211 frames of all 74 kinds** in the real
  `[direction][phase]` layout with each frame's own `.PGF` anchor, and hard-fails unless the
  `base[]` total rebuilt by `FUN_005a2830`'s algorithm is exactly 4211. The old
  `player_base/player_kit` pair — 24 frames in the `[3 phase x 8 dir]` TRANSPOSE — is deleted.
* **`app/scripts/JugRender.gd`** ports `FUN_005a5460`: `base[kind] + fpd[kind]*dir + phase`,
  the non-uniform `DAT_006653e0` bucketing, the mode-gated mirror (mode 8 stores all eight and
  never mirrors; mode 5 stores 0..4 and flips the rest; mode 1 ignores facing; negative mode is
  a mirror twin on its positive twin's base), the mirrored-14-phase half-cycle shift, and
  `FUN_005a50c0`'s phase advance with its next-state hand-off.
* **`CAMERA_YAW` is a quarter turn, derived not assumed**: the billboard axis
  `sVar23 = cameraYaw - 0x4000` must be perpendicular to a view along +Y, and that choice also
  puts a player running toward the camera on bank direction 0 — the front-facing frame the
  bank actually holds.
* **The `kind` byte was never missing.** `Pm98Movement.set_position_code` IS `FUN_005a5430`,
  and the `POS_REMAP_LUT` it tests against is literally the next-state table `DAT_00665208`.
  It was only mislabelled. `Pm98LiveMatch.player_positions()` now exposes `x`/`y`/`z` in raw
  16.16, plus `facing` (`+0x34`), `kind` (`+0x40`) and `phase` (`+0x2c`).
* **Axes measured, not inferred** (`app/tests/diag_watch_axes.gd`): world **X = pitch LENGTH**
  (`+0x1820`, +/-58 m at Old Trafford), **Y = WIDTH** (`+0x1824`, +/-38 m), **Z = height**.

### The view itself

`MatchSimulador` draws a 3/4 perspective pitch: mown bands along the depth axis in the two
greens sampled from the capture, the markings and both goals as projected world geometry with
near-plane clipping, the hoarding + terrace band from DATSIM's own HIERPREM tiles at their
measured heights, 22 JUG billboards sized from each frame's own anchor and the `0x1b333/0x30`
world scale (a standing frame is 1.63 m), drop shadows, and the original's slim top-left score
line plus the ball carrier's shirt number and name bottom-right.

Proven in the REAL APP under Xvfb + GL (`PM98_LIVEWATCH_SHOT=1`), not only headless. Gate
**`app/tests/test_jug_render.gd`** (29 assertions) + the reworked `test_match_simulador`, both
added to the CI gate (30 -> 32 tests); the representative slice re-run green here.

### Still open on the match view, stated plainly

1. **The per-club kit ramps.** `DatSim\paletas\P96A####.DAT` / `P96B####.DAT` (829 of each,
   192 bytes = 64 RGB entries, plus one 256-byte `P96A0000.DAT` index remap) are decoded, but
   **which palette slots they write is NOT reversed**. The kit is therefore a two-colour
   stand-in — tinted shirt + neutral shorts/socks — split on the art's own per-band histogram,
   not on the loader. Reversing `FUN_005b645d` / `FUN_005b6771`'s target slots closes it.
2. **The camera does not move.** The original's does: `FUN_005f5850` runs a shot-transition
   system (eye `+0x48`/`+0x54`, look-at `+0x60`/`+0x6c`, zoom `+0x80`/`+0x84`, lerped per
   frame), and the capture shows it cutting to a close, low angle on a goal. Not ported.
3. **The pitch marking geometry is the laws of the game**, scaled to the session's own length
   and width, because PM98 stores only those two figures. Declared, not source-read.
4. **`JUGCAM.IND`'s record layout** and its consumer are still a gap (unchanged from §5 of
   `jug_render_spec.md`).
5. **HIGHLIGHTS (`3D ENGINE`) still cannot be built** — its `.p3d` models are absent from the
   shipped files. Unchanged: a DATA gap, not a work gap.
6. **The real-device pass** is still the missing half of the performance answer (desktop does
   63.6 engine frames/s; the phone is unmeasured).

### NOT touched this session, said plainly

**B9** (the youth loop's three visual gaps), the **cup channelTV fee**, the whole **P2 data
tail** (~876 directory-only foreign teams, the LZ-packed `DAT.PKF`/`DATSIM.PKF` rating tables,
the 48x64 MINIESC bank's missing 56 px, the 10 corrected-by-mapping stadium tiles, "free if
relegated", the unmanaged-club release ladder), the **`KnockoutScreen` -> `PMShadow` refactor**
and the **doc-hygiene tail**. All stay exactly as written below.

## 0aaaaaa. Closed 2026-07-28 (session s74) — THE M5 WIRE-IN, and the lower-division drive

### The M5 wire-in — DONE, and the framing it was carrying was WRONG

**The carried plan said "wire the exact engine into the app (replace `MatchSim.simulate`)"
and worried that "~9 min/match is too slow for instant fixture results … open question
whether MANAGER.EXE even has a quick-sim path". Both halves are wrong, and the binary says
so.** `FUN_0044ee70` L128 is `if (local_1c[1000] != 5)` — `local_1c` is the session and
index 1000 is byte offset `0xfa0`, the play-state — so ONE function holds BOTH engines:

| play-state | branch | engine |
|---|---|---|
| `!= 5` | L51-333, ends `goto LAB_0044f520` | the POSITIONAL sim (22 players, ball physics, the `FUN_00598740` tick driver) — a WATCHED match |
| `== 5` | L357-792 | the STATISTICAL instant-result sim, pure `rand()` + integer arithmetic — every match the manager does NOT watch |

So the app's played path was **already the original's own engine**: `MatchSim.simulate`
routes to `Pm98StatMatch`, the byte-exact port of that `PS == 5` branch. Replacing it with
the positional engine would have made the port LESS faithful, and the performance worry is
moot — the original never uses the positional engine for instant results either.

What WAS missing is the engine the original runs when you watch, and that is now wired:

* **`app/scripts/Pm98LiveMatch.gd`** — builds a fixture from live career data through
  `Pm98LineupFeeder` (carrying the manager's own TEAM TACTICS levers and MAN-TO-MAN table
  through its override hooks), steps `Pm98Outer.step` frame by frame, harvests goals off
  the event queue, and exposes per-frame player/ball coordinates.
* **Coordinate space, MEASURED not assumed** (`app/tests/diag_live_coords.gd`): positions
  are 16.16 fixed point about the centre spot; `match+0x1820` is half the pitch length and
  `match+0x1824` half its width (Old Trafford 116x76 → 3801088 / 2490368), and ball `+0xc`
  is height, reaching ~321000 (≈4.9 m) on a lofted ball.
* **`MatchSimulador` (the WATCH view) renders it.** `set_live()` swaps the old
  interpolated-timeline motion for the engine's own 22 players and ball, the binary's own
  clock `(banked + clk) * 0x2d / scale`, its `+0x19a0` half counter, its dispatch-10 full
  time, and its designated carrier (`match+0x440`) for the active arrow. `Main` raises it
  on the MATCH OPTIONS **WATCH** tap.
* **Proven in the REAL APP, not just headless** — `PM98_LIVEWATCH_SHOT=1` renders it under
  Xvfb + GL: `tools/re/refs/m5-livewatch-2026-07-28/` shows 22 players spread in real match
  shape, both keepers on their lines, the ball in play, clock 19:00, score 1-0.
* **Gate `app/tests/test_live_match.gd`** — build, in-pitch coordinates at kickoff and after
  400 frames, the ball on the centre spot, the roster actually moving, then (opt-in
  `PM98_LIVE_FULL=1`) full time at dispatch 10, minute 90, the goal list agreeing with the
  scoreline, and the same seed replaying the same match. **Ran green: 3-0 in 18,458 frames.**

**The ~9 min/match question, answered with a measurement.** A full 90 minutes is **18,458
outer frames** and takes **4 m 50 s of CPU** on this desktop = **63.6 engine frames/s**. A
watched match wants ~1 engine frame per display frame, so the desktop has headroom. The
view therefore steps `round(delta * 60)` frames capped at 12 per `_process`, so a slower
device falls behind in match time instead of stalling the render loop. **What is still
open is the on-device number** — that is the real-device pass, not an engine question.

### The lower-division wine drive — two of its four items CLOSED

Two careers driven from the title screen at TOTAL control (`tools/re/refs/lowdiv-2026-07-28/`):
Birmingham C (First Division) and Barnet (Third Division).

* **`club+0x50` — BOUND AND SHIPPED.** Six of the nine starting grades re-witnessed on the
  First Division club match preset 1 exactly; the Third Division club is at zero on all
  three of the items that separate the presets. With Man Utd's Premier preset 0 already
  proven, the scan order **0 Premier / 1 First / 2 Second / 3 Third** is witnessed. The
  jump table at 0x57d834 sends indices 2 and 3 to the SAME arm and anything above 3 (the
  384 foreign clubs) to a bare `ret`, so **all 476 clubs now seed** —
  `app/scripts/GroundPreset.gd`, gate `app/tests/test_ground_preset.gd`, which also
  reproduces every one of the nine captured Man Utd rows.
* **Two NEW ground-price witnesses, the first ever away from Man Utd**, both falling out of
  `FUN_0057ddd0` unchanged: Birmingham C's floodlight upgrade £200,000 / 4 weeks, and
  Barnet's three SEATS cards £1,000,000 / £1,750,000 / £2,500,000 at 20 / 35 / 50 weeks.
* **The England non-Premier offers panel — WITNESSED, and the answer is a null result.**
  All three non-Premier panels are banked; the picked club is marked EXACTLY as in the
  Premier panel (gold cell behind the kit + the name centred below the grid). No
  division-specific marking exists. `offers_map_re.md` §"Still open" is closed.
* **The channelTV LEAGUE fee — a REAL finding, and the port was wrong.** It is not the
  constant £90,000 the port shipped to every club. Three driven careers give all four
  English divisions: **Premier £90,000 · First £45,000 · Second £35,000 · Third £35,000**.
  The ladder is NOT proportional (90→45 halves, 45→35 does not), and Second and Third share
  one figure — the same shared-arm shape `FUN_0057d780` has for competition indices 2/3.
  Ported as `FinanceModel.LEAGUE_TV_FEE` + `league_tv_fee()`, gated in
  `test_channeltv_screen.gd`. Full record: `finance_screen_re.md`.
* **B9 and the CUP fee stay OPEN** — said plainly. Ten channelTV cards were banked across
  the three drives and **not one was a cup tie**; the Birmingham career reached week 24
  before stalling on an injured-XI modal, and no youth search completed in the driven
  weeks. Both need a longer driven career, not a new idea.
* **NOT attempted, deliberately:** moving `KnockoutScreen`'s baked `kitwell_*`/`icon_*`
  rings and `PMChrome.panel_kit` onto `PMShadow`. Those render correctly today and their
  parity gates are green on the baked art, so it is a pure refactor with regression risk
  and no visible change — the session spent the time on the evidence gaps instead.

### ⛔ CORRECTION, same day: the WATCH VIEW is still an app invention

The wire-in gives the view the engine's real COORDINATES. It does **not** make the
presentation faithful, and the s74 write-up did not say that loudly enough. §A6/A7/A8 of
`APP_VS_SPEC_AUDIT.md` stand unchanged and are the authority:

* **The original has no side-on 2D view at all** — it draws a pseudo-3D two-billboard
  sprite under a **fixed 3/4 camera**. Ours is side-on.
* **`_facing()`'s uniform-45° atan2 is an invention**; the engine buckets direction on the
  non-uniform thresholds `DAT_006653e0`, stores 5 directions and mirrors the rest.
* **The baked sprite sheet is the transpose of the real JUG layout** — `[direction][phase]`
  across 74 kinds in the engine, `[3 phase × 8 dir]` in `export_match_art.py`.
* **`3D ENGINE` = HIGHLIGHTS, and it cannot be built**: its `.p3d` models are absent from
  the shipped game files. A data gap, not a work gap.

**Four of the five pieces needed for a faithful render are ALREADY reversed** in
`jug_render_spec.md`: the JUG bank layout (74 kinds, validated to exactly 4211 frames), the
direction thresholds + 5-dir-and-mirror rule, the camera orientation (yaw/pitch/roll are
constant 0, so the view matrix is pure translation — **not** a tilted camera), and the
camera position (eye = the ball anchor `matchctx+0x1614` + `0x500000`, look-at on the
tracked actor). **The one hard gap is `PCF5DAT.PKF`, the 3/4 tile-scroll pitch background.**

On importing another Android football engine (GFootball `Apache-2.0`, GameplayFootball
`Unlicense`, both verified via the GitHub API 2026-07-28; asset licensing NOT verified —
check before use): **not recommended.** The players are PM98's own `JUG.PGF` and are
already decoded; a donor renderer would make the match look like that game, not like PM98.
The only piece a donor could supply is the pitch background, and the game's own `HIERPREM`
grass tiles already cover that as a declared substitute.

## 0aaaaa. Closed 2026-07-28 (session s73) — the shadow pass and the F.A. Cup semis card

* **The shadowed bitmap blit is REVERSED AND PORTED.** `FUN_004b7f60` is not an outline
  pass and not a bevel — it is a soft DROP SHADOW, and it is ONE pass. `FUN_005d66f0`
  builds a 0/255 silhouette over the whole padded buffer; `FUN_005d6590` spreads it with
  an IIR filter that walks the buffer LINEARLY from `stride + 1` (so a silhouette at a
  row's right edge tails into the row below), decaying by `0x21` a step and clamped at a
  per-call-site `cap`; `FUN_005d5220` composites it and re-quantises through a **two-table**
  RGB565 lookup picked by an ordered-dither bit on **absolute screen parity**. That last
  bit is the CAUSE of the rule the kit-list bake found empirically the same day —
  `parity(X, Y) = (X + Y + 1) & 1`. Both call sites were disassembled, so the caps are read
  and not guessed: `FUN_0050f970` pushes `0x63` (the marking markers), `FUN_0050fae0`
  pushes `0x84` (the 48x64 kit). Full record: **`docs/re/shadow_blit_re.md`**; port:
  `app/scripts/PMShadow.gd`; tables: `tools/re/build_shadow_lut.py`.
  - The two 64K tables are built at startup and are not constants in the image, so they are
    RECONSTRUCTED (nearest palette entry to the 565 cell CENTRE, ties high; the partner is
    the entry that puts the pair's mean on that centre) and **validated at 751/751** on
    every shadow pixel of the two MAN-TO-MAN markers. Ties broken low scores 750/751;
    plain nearest-with-no-dither scores 428/751.
  - Two byte wraps in the composite are load-bearing and are NOT clamps (the product
    truncates to 16 bits before the shift; the sum lands in a byte, so `255 + 123` is 122).
  - `diff_mantoman_parity`, three cases over two careers: the shadow bucket **944 -> 92 px**.
    The markers are EXACT. What is left is the D/M letters the original draws as text
    (36 px) and 56 px where the original paints black and the port's 48x64 MINIESC bank has
    transparency — a KIT-ART gap, identical on both careers, still open below.
  - Still open: moving `KnockoutScreen`'s baked `kitwell_*`/`icon_*` rings and
    `PMChrome.panel_kit`'s per-screen banks onto this module, one gate at a time.
* **The F.A. Cup SINGLE-LEG semifinal card — BUILT, 0 px.** One block whose bar reads
  `RESULT`, the neutral ground as its first row, the panel ending after it. Proven rather
  than assumed: blanking BOTH witnesses with the same content rects leaves exactly the bar
  label (y178..184) and the second block (y263..344). New `cards_body_single.png` + the
  F.A. Cup's own cards band; gate case `knockout_facup_semis`. The neutral ground is
  modelled with the FINAL's own declared-OURS draw (`Cup._pair_round` -> `tie_venue_ids`),
  with the divergence stated: it names the venue, it does not move the match.
  `app/tests/test_cup_semis_neutral.gd`.
* **Corrected while in there:** the Coca-Cola two-legged semifinals were ALREADY built and
  gated at 0 px (`knockout_cocacola_semis_done`) — the carried list called them unbuilt.

* **The DOMESTIC (Coca-Cola) FINAL body — BUILT, 0 px.** A different card from the euro
  one: `MATCH RESULT` over `STADIUM`, two club bars each carrying a 17x20 `ridi` icon
  instead of the euro's 48x60 kit + flag row, and an empty `REPLAY RESULT` panel. The
  `WINNER` band and the laurel are the euro final's, and the bake restores them by pasting
  the euro frame's own pixels (the whole y340..429 band differs only at the name and the
  wreath). Gate case `knockout_cocacola_final`. Two faces the witness settles the PEN of
  but not the glyphs are named buckets with their measurements, not shrugs: the score
  digits (proman12, 193 px against the GDI's 244) and the WINNER band's champion (13 ink
  rows where proman12 gives 9; no extracted bank matches). **All 14 knockout gate cases
  pass.**

* **`club+0x50`, the per-club ground-grade PRESET SELECTOR — REVERSED.** It is not a stored
  data byte, which is why the EQUIPOS parser could never find it: `FUN_00579c70` never writes
  `club+0x50` (checked mechanically against every offset it does write). **`FUN_0057a180`
  COMPUTES it**: it is the index of the first competition in the table at `DAT_0066b190` that
  contains the club (entries 0..3 scanned first, then 7..12), and `club+0x58` is that
  competition's `vtbl[0x78]` value clamped to 0xc. Entry 0 is PROVEN to be the Premier League
  (preset 0 is exactly Man Utd's witnessed grades). What is left before 476 clubs can be
  seeded off it is ONE capture of a lower-division club's IMPROVE panel, to bind indices
  1/2/3 to the First / Second / Third Divisions — the natural reading of the monotonically
  degrading presets, but not yet witnessed, so not yet shipped.
  Record: `docs/re/stadium_screen_re.md` §"`club+0x50` — REVERSED", decompile in
  `docs/re/groundpreset/`. **This folds into the B9 / offers-panel wine drive**: the same
  driven lower-division career answers all three.

### NOT done in s73, stated plainly

**B9**, the **England non-Premier offers panel**, the **cup channelTV fee**, the
**M5 wire-in** (and the ~9 min/match question), the **2D/JUG view**, and the whole data /
device tail (~876 directory-only teams, the LZ-packed `DAT.PKF`/`DATSIM.PKF` rating tables,
the real-device pass, the unmanaged-club release ladder, the "Free if relegated" clause,
the per-club STARTING ground grades and the 10 corrected-by-mapping stadium tiles) are
untouched and stay exactly as written below.

## 0aaaa. Closed 2026-07-28 (session s72) — MAN-TO-MAN MARKINGS

* **MAN-TO-MAN MARKINGS — BUILT, and it was the last dead in-match door.**
  `app/scenes/ManToManScreen.gd`, raised by the BRIEF's own MAN-TO-MAN button
  (`MatchScreen.mtm_pressed` -> `Main._show_man_to_man`), which is the door the
  walkthrough itself walks: `057_162619` (the board, the button lit) ->
  `058_162622` (the screen). Layout, cells, colours and model all come out of
  `MANAGER.EXE` — `FUN_0050e980` (the init) plus the four draw overrides
  `FUN_005100a0` / `FUN_0050fc40` / `FUN_005103c0` / `FUN_0050fee0`. Full record:
  **`docs/re/mantoman_screen_re.md`**. Gate `tools/re/diff_mantoman_parity.py`:
  **three cases, two careers, 0 differing px** across the whole body band
  (Bolton W. vs Aston Villa idle, Manchester Utd. vs F.C. Barcelona idle, and the
  same career after two commits). `app/tests/test_mantoman.gd` pins the model and
  is in the CI gate (25 -> 26 tests).
  - The **assignment table is the original's own** `team+0x234 + 4*i` (0 = unmarked,
    2..11 = the marked opponent's lineup slot); it persists on `Career.man_marking`
    and reaches the positional engine through `Pm98LineupFeeder` as
    `rec+0x28 = entry - 1`, the binding `session_lineup_re.md` already recorded.
  - The **two marking lines** are `club+0x25c` / `club+0x260` scaled `*148/318`
    (ctor defaults 79/198 -> panel x 36/92, exactly where both witnesses put them),
    persisted on `Career.marking_lines` and fed to the engine's lineup header.
    Their tracks bound each other, so D can never pass M.
  - Three sprites are the game's own: `linead.bmp` / `lineam.bmp` / `flechas.bmp`
    from `RECURSOS.PKF` under `MANAGER.PAL` (FLECHAS reproduces witness
    `061_162628` at **0 px**; the markers at 0 px outside their D/M letter box,
    which the original draws as text over the sprite). The pitch under the markers
    is the game's own `campo.bmp`, so a dragged line uncovers original pixels.
* **The un-reversed "bevel"/outline pass is IDENTIFIED — it is one pass, not three.**
  The markers and the 48x64 kit go through `FUN_004b7f60` ->
  `FUN_005cbea0(0x10, 0x21, …)` -> `FUN_005d66f0` (silhouette) / `FUN_005d6590`
  (tint) / `FUN_005d5220` (composite). Measured on these frames it is a
  **palette-darkening stamp offset right of the silhouette, applied once per
  overlapping stamp** (index 85 -> 116 -> 115 -> 114; 255 -> 7 -> 247 -> 134) —
  NOT the dilation model rejected earlier the same day. Porting those two leaves
  closes the bucket here AND in `diff_knockout_parity.py` and `OffersScreen`.
  Still open: the port itself.

### NOT done in s72, stated plainly

The rest of the carried list is untouched and stays open exactly as written below:
**B9**, the **England non-Premier offers panel**, the **F.A. Cup single-leg
semifinal card + the Coca-Cola FINAL body**, the **M5 wire-in** (and the
~9 min/match performance question), the **2D/JUG view**, and the data/device tail.

## 0aaa. Closed 2026-07-28 (session s71) — the carried named list

Mats's list was: *the cup TV fee, the 5-8 tie kit list, MAN-TO-MAN, B9, the 48x64 bevel,
the ±N K. axis, the England non-Premier offers panel, the pre-existing tap-through failure
and the sweep's 234/1 result.* Five closed, three did not, one was already closed — said
plainly at the end.

* **The 5-8 tie KIT LIST — BUILT, 0 px.** Layout 2 of the five (`knockout_views_re.md`
  §"The kit list, as built"): 22 px rows at pitch 30 in an `x6..493` panel, a 17x20 ridi
  kit each side at (+5,+1) in its 28x22 well, and the compact list's own cell-relative text
  anchors at pen top `row_top + 6`. Three witnesses, two competitions, two careers, BOTH
  column sets — the DOMESTIC one (`13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png`) was
  local-only and is now in the tracked reference tree. Gate:
  `diff_knockout_parity.py` cases `knockout_uefa_kitlist` / `knockout_cwc_kitlist` /
  `knockout_cocacola_kitlist`. `Main._show_cup_screen` raises it at 5-8 ties; 8 is the only
  size the port's own cup structure can produce, and it is the only size any of the 20
  kit-list frames in the corpus shows, so 5-7 is declared.
* **The outline pass is DITHERED ON ABSOLUTE SCREEN PARITY — the 07-27 "NOT
  position-constant" conclusion was WRONG.** The kit list proved it because it puts the
  same sprite bank in wells at two parities: `x15` and `x289` (both odd) agree pixel for
  pixel across all three witnesses, `x344` (even) disagrees at 222 of 616 positions.
  Voting the overlay per `(well_x + row_top) & 1` instead of per side cut the gate's kit
  residual **556/552/548 -> 68/64/28**. It is the same rule the paginator's disabled arrow
  already carried.
* **The ±N K. finance axis — CLOSED from the binary, and it exposed a render defect.**
  `FUN_00509760` accumulates the largest |week-on-week balance delta| and snaps to the
  smallest of three .data floats (0x659540/4/8 = 50M/100M/500M), printing it × 5e-06
  between "+"/"-" and " K." in **euro8**. So the original draws exactly ±250 / ±500 /
  ±2,500 K. The defect: the baker's plot-field blank ran `x60..634` where the field is
  `x76..604`, painting over both axis label plates — the shipped chrome read "+2,500" with
  the " K." wiped off. Fixed, and the labels are drawn live. New gate
  `tools/re/diff_finance_axis_parity.py`: **both witnessed states 0 px on both plates**.
* **The FILLED FINALIST plate — BUILT, and it deleted two port inferences.** The 07-28
  drive's two decided-semifinal frames show the plate carrying the club's 24x32 nano kit at
  `(plate_x0 + 2, 377)` and his name in proman10 at `(plate_x0 + 43, 380)` in that card's
  OWN ink — not the centred GDI string in the WINNER band's ink the port had declared as
  OURS. They also refute the port's yellow winner ink in this layout: both frames are
  played out and NOTHING is inked yellow. Gate case `knockout_cocacola_semis_done`.
* **The channelTV fee — the field is now traced end to end in MANAGER.EXE** and the search
  that does NOT work is written down (`finance_screen_re.md`). `club+0x290` is confirmed as
  the fee (raise test @0x546188, read @0x546214, cleared @0x54624a, booked by the weekly
  pass @0x57ab1d for the hot-seat club only, zeroed at build @0x5799d7, saved
  @0x57cb15/@0x57bed8). **Not found: the producer** — there is no write to `[reg+0x290]`
  anywhere in `.text` outside those sites, so it reaches the field through an aliased base;
  and the fee is not a constant, since 90,000 / 187,500 / 375,000 appear as neither u32 nor
  f32 nor f64 in the EXE nor in ANY shipped game file. Cup ties still pay £0 and still say
  so.
* **The "pre-existing tap-through failure" does NOT reproduce.** Both harnesses are green
  on this box with the documented command (`--rendering-driver opengl3`, Xvfb :1
  1280x960x24): `shot_squad_card_tapthrough` **10/10**, `shot_dbase_card_tapthrough`
  **23/23**. The 07-28 2-of-10 was that run's display, not the app.
* **The sweep's 234/1** was already closed in `527f4e9` (`test_living_league` now claims the
  drift over the LEAGUE, not one lottery club). Re-verified: the curated 25-test CI gate is
  green test by test, and so are `diff_knockout_parity` (12/12), the three finance parity
  gates and `diff_finance_axis_parity`.

### NOT done this session, stated plainly

1. **MAN-TO-MAN MARKINGS** (`APP_VS_SPEC_AUDIT` row 11, the last dead in-match door) —
   untouched. It is NOT blocked on evidence: `screenshots/parity-run-2026-07-16/orig/
   66_mantoman_match.png` is a full, clean witness of the screen (squad list with a DEF/MID/
   FOR column and a PLAYER N. column, the opponent XI panel with its kit and vertical club
   plate, the DEFENDING / MIDFIELDING MARKING LINE pitch widget, DELETE and RETURN). It is a
   whole screen build and wants its own session.
2. **B9** (the youth loop's three visual gaps) — untouched; it needs a driven career with a
   completed search at the binary's own 30-55-week cadence.
3. **The 48x64 MINIESC bevel is still NOT reversed.** The parity finding above does not
   reach it: all four bracket wells sit at one parity, so the residual there is
   club-varying silhouettes. A dilation model was measured on all 16 witnessed bracket
   cells and REJECTED — the union kernel `0<=dx,dy<=3` covers 4090 of 4098 outside-
   silhouette pixels but paints 1988 the original leaves white. It needs the pass's code.
4. **The England non-Premier offers panel** — still wants a witness, and this is a real
   evidence gap, not a shrug: `offers_map_re.md` §"Still open" records that the shot and
   frame 100 do not even reduce to a permutation (the panel is showing a different SET of
   clubs), so which division that frame is on cannot be inferred. No frame in the local
   corpus, including the 07-19 lower-division drive, shows it.
5. **The F.A. Cup single-leg semifinal card and the Coca-Cola FINAL** are still SORTEO
   fallbacks. Their frames are banked (`tools/re/refs/knockout-2026-07-28/`) and the
   FINALIST half of that family is now built, but both need their own chrome bake: the
   F.A. Cup semis are a different card shape (one `RESULT` block, not two legs) and the
   Coca-Cola final is a different body from the euro one (`MATCH RESULT` over `STADIUM`, an
   empty `REPLAY RESULT` panel, and the WINNER band bottom-left).

## 0aa. Closed 2026-07-28 (session s70) — the sacking screen, the ground ceiling, the decided bracket

* **The SACKING SCREEN — BUILT, and it is not a screen.** `FUN_00545fd0` IS the weekly hub
  screen's own run(): it tests three conditions BEFORE it draws the menu and, on any of
  them, raises one modal, detaches the manager and ends the career (`docs/re/sack_path_re.md`
  §"BUILT 2026-07-28"). The port now does the same, in the binary's own order
  (`Career.sack_message()`), with MANAGER.EXE's own message bytes, at the hub mount, and it
  exits to the TITLE screen — the surface `FUN_004f96c0`'s CGFXException 0x4e3e actually
  lands on. **The board's week-10/14/18/22/26/30/34 RESULTS REVIEW is ported too**
  (`FUN_0057a980` @0x57ad6a, disassembled this session; band gates, the position thresholds
  of `FUN_0057d3a0`, and the 7-point title arm). The port's invented end-of-season
  `SACK_GAP` verdict and its post-sack JOB OFFERS mount are DELETED. Two declared
  divergences, both written down. Gate: `app/tests/test_sacking.gd`.
* **The stadium 150,000 SEATS ceiling — CLOSED.** The 07-27 note "the addend register wants
  one more trace" is discharged: `FUN_0051c2e0` banks `[ground+4] + [ground+8]` (capacity +
  headroom) at @0x51c340 and per SEATS card tests `(card+1)*4000 + that >= 0x249f0`,
  disabling the card. `Career.MAX_STADIUM` 130,000 -> **150,000** on the SUM with `>=`;
  130,000 stays as `StadiumScreen.MAX_CAPACITY`, which is only the tier-picture divisor.
* **`remodela.png` — the "works marker" hypothesis was WRONG.** The `.data` block at
  0x65b1a4 is three (path, label) pairs and `FUN_0051a6e0` builds one button from each:
  `diapartido.bmp`+MATCH DAY, **`remodela.bmp`+IMPROVE**, `obras.bmp`+WORKS, at exactly the
  rects measured off the frame. `remodela.bmp` has ONE code reference in the whole binary.
  Nothing to draw: it is the IMPROVE button's icon, already inside the baked action grid.
* **The euro AGGR cell — WITNESSED AND BUILT, and it corrected three things.** The pageback
  drive finally reached the QF second legs; the frame
  (`screenshots/wine-captures-2026-07-28-knockout-decided/01_euro_qtr_finals_decided.png`)
  shows the winner's whole NAME PLATE repainted `(42,95,170)` with an inward chevron at each
  end, and the score ink AND the dash blend are PER BOX (the navy AGGR box prints
  `(180,180,220)` and its dash carries no blended pixel at all). All three were wrong in the
  port, all three are fixed, and `diff_knockout_parity.py` case `knockout_euro_qtr_done` is
  **0 px**. One declared band: the paginator plate is two rows taller on a paged-back frame.
* **The WEEKLY-ILLNESS path — BUILT.** `FUN_0057a980` @0x57a9f4-0x57aac8 ported gate for
  gate (the two squad guards, the 1-in-7 week roll, the 70/30 first-team window, five
  candidate draws, and the fitness-weighted replacement) plus `roll_A` @0x5850b0, which is
  the only ladder in the game that can produce a **virus or a cold** — 24 % of it, from two
  separate bands. News line is the EXE's own format string (0x663230). Runs for every club,
  as the original does. Gate: `app/tests/test_weekly_illness.gd`.
* **The insured-row DOCUMENT ICON — BUILT.** `FUN_00543960`'s insured branch is three
  pieces, not a centred digit: the sprite at row-x 459 / row-y 5, the group number centred
  in 0x1d5..0x1e0, and the **payout percentage** centred in 0x1e1..0x1ff. All three land
  exactly where the one witness puts them; the sprite is frame-cut by
  `tools/re/build_injuries_insured_icon.py`. The port had been drawing the digit alone.
* **The 16 evidence-less RE docs — CLOSED, and the index now enforces it.**
  `build_status_index.py` gained a fourth evidence class: an `Evidence:` line naming
  repo-relative artefacts, **every path of which the script checks exists** (a path that
  does not resolve is a hard failure — it caught one stale line on the first run). The 16
  now name a banked runner, a witness directory or an extraction tool. **0 docs have no
  evidence link.**
* **New reusable tool: `tools/re/wine/screenwatch.py`** — a passive second pair of eyes on a
  running drive. It grabs the same window on a timer, names the frame with `autodrive`'s own
  signatures and keeps the ones you asked for, without clicking, so screens the plan throws
  away (a cup channelTV card, a one-off board) can still be banked.

### One pre-existing failure found and NOT fixed

`shot_squad_card_tapthrough.gd` fails 2 of its 10 checks — "card RETURN dismisses the card"
and "squad RETURN exits" — and it **fails identically on a pristine checkout of HEAD**
(verified 2026-07-28 in a detached `git worktree`, so it is not this session's doing). The
07-27 note "10/10 + 23/23 green" was recorded on a different display; this run was on a
bare Xvfb with no window manager, so the emulated-touch RETURN release may simply not land
there. Either way it is a harness/environment question, not an app change, and it is left
open rather than papered over.

### Still open from this session, stated plainly

* **The Coca-Cola / F.A. Cup TV fee is STILL unmeasured.** Three more channelTV cards were
  banked by the watcher and all three are the LEAGUE £90,000 (now confirmed on a second
  club and a second season). The fee is not a constant in the binary — the card reads
  `club+0x290`, which the weekly pass books and clears — so it needs a captured CUP home
  tie, and the drive did not reach one.
* **The kit-list layout (5-8 ties)** was not captured either; no phase of that size came up.
* **MAN-TO-MAN, B9** untouched this session.
* **The 48x64 kit bevel is NOT reversed.** It still needs the pass's code; the 07-27
  measurements remain the starting point. Not attempted this session.
* **Three newly witnessed chromes are banked but NOT built**: the F.A. Cup semifinals band
  with filled FINALIST plates, the Coca-Cola semifinals in their two-legged form, and the
  Coca-Cola FINAL with its filled WINNER band. Frames are in
  `screenshots/wine-captures-2026-07-28-knockout-decided/`; building them is a chrome-bake
  pass of the same shape as the euro cards/final build.

## 0a. Closed 2026-07-27 (session s69) — the carried fix-first tail

* ~~**The PRE-EXISTING `diff_entry_parity` `rival_015` failure (440 px, untriaged).**~~ —
  **CLOSED.** Not a kit or palette issue at all: VIEW RIVAL's `COMPUTER` band is read
  from the HUMAN-PLAYER table, not from the club's manager. `FUN_005733d0` @0x573b0a
  takes `club+0x5c` (the hot-seat slot, `0xffff` = none) into `DAT_0066c178`, else the
  literal `COMPUTER` — so the 476-manager decode had started painting "Van Gaal" over
  frame 015. `RivalScreen.setup(..., human_manager)`. The whole 18-pair gate is 0 px.
* ~~**MAKE OFFER opened at the club fee.**~~ — **CLOSED**, found by the same gate run
  (294 px on `makeoffer_101`, never reported): the COLD route opens at the FLOOR, which
  is frame `101_164714` exactly (£5,000 against a £3,000,000 fee). Only the TRANSFERS
  route pre-fills, and it passes the terms in. Two tests corrected.
* ~~**The finance SUMMARY's euro-income label (rule decoded, build deferred).**~~ —
  **BUILT.** `FUN_0050812e` @0x5081B0..0x50838F is a three-arm ladder with U.E.F.A. as
  the FALL-THROUGH, which is why a non-European career reads it. Baked plate blanked,
  label drawn live from `Career.euro_income_comp()`, font/pen/ink READ off the frames
  (proman8, pen 34,147, ink 80,110,5). New gate `diff_finance_eurolabel_parity.py`:
  **both witnessed arms 0 px, from two different careers.** The `±N K.` axis scale is
  still open (§0 below).
* ~~**OffersScreen's kit panel.**~~ — **0 px outside the kit sprites.** Three real
  defects: foreign grids were sorted by name where the original uses the ARCHIVE's own
  record order (England keeps its sort — witness 44 costs 899 px without it), and both
  panel texts had the wrong font and pen (solved on four country witnesses). What is
  left inside the cells is the shadow pass — measured, see below.
* ~~**The never-completed full suite sweep.**~~ — **RUN END TO END: 232 files, 227
  clean, 5 failures, all five closed.** Every one was a test that had outlived a shipped
  model change (the two offer cards, `total_weeks` 38 -> 39 after the blank Saturday,
  "rivals age" after S8's rebirth, and five `test_manager` asserts resting on where the
  sim put one club — now fired through the board's table-independent FINANCIAL reason,
  the one the binary tests first).
* ~~**The audit's doc hygiene.**~~ — **CLOSED with generated indexes**, not 113
  hand-written sentences: `docs/re/STATUS_INDEX.md` (125 docs vs gate/suite/EXE
  addresses — 16 have no evidence link at all, and that is the real backlog) and
  `docs/re/WALKTHROUGH_MANIFEST.md` (every frame named by the auto-driver's own taught
  signatures; 182 of 636 frames cited by any doc, so 454 are captured and unread).
  `ChannelTvScreen` has a suite. See the truth table at the end.

**Still open on the 48x64 / nano kit bevel** (it needs the pass's CODE, and that is now
stated with numbers rather than as a shrug — `offers_map_re.md`): every differing pixel
is white in the port and grey in the original; a `dx=2, dy=2` shifted-silhouette stamp
explains 1670 of 1992 px; it is NOT the realised-palette bug; and it is NOT
position-constant (46 unanimous positions over 40 cells), so it cannot be baked the way
the MINIESC ring was.


Mats asked: "I want the game on Android as it was on PC in '98 — what's missing?"
This is the honest, full list. Nothing hidden.

> The 2026-06-20 edition of this file was five weeks stale — it still listed the collision
> builder, the match-tick driver, PKF sprite decompression and the season-end screens as
> open, and all four have since landed. **Per-screen truth is not this file** — it is
> `docs/re/STATUS_INDEX.md`, which derives each doc's standing from its gate, suite, scene,
> EXE addresses and `Evidence:` paths and fails loudly when one of those paths rots.
> This file is the map, the docs are the territory, and the index is the survey.
>
> That delegation used to point at "the `Status:` line at the top of each
> `docs/re/<screen>_re.md`" — and only **21 of 135** docs carry one, so for the other 114
> it pointed at nothing. Writing 114 status sentences would be prose about prose and every
> one of them would be a guess, which is exactly what this project does not do; the index
> is the same delegation made checkable instead. **0 of the 135 docs now have no evidence
> link at all** (37 gated, 67 with a headless suite, 93 binary-anchored, 28 with an
> explicit `Evidence:` line).
>
> The 2026-07-26 rewrite still carried one stale line of its own — "SAVE GAME is still a
> toast". It has not been a toast since 2026-07-18: `Main._menu_action` "save" opens the
> ten-slot `SaveGameDialog`, render-diffed 0 px against witnesses 51/52/53. Removed.
> **The habit that catches these: grep the code for the entry point before repeating a gap.**

## 0. Mats's live QA report, 2026-07-26 evening — fix FIRST, before new screens

Reported from play on the shipped build; every item verified in his hands, none is a
guess. One is already fixed (last bullet); the rest are open and OUTRANK the semifinal /
final build:

* ~~**The SCOUT "EXTRA SEARCH FILTERS" panel is invented graphics**~~ — **REDONE
  2026-07-26 evening**: the panel is now `ours_panel.png`, baked from real frames by
  `tools/re/build_scout_ours_from_frames.py` (the trainers dialog's plate + its six REAL
  HANDLING..SHOOTING button plates + the scout screen's own fields/arrows); the scene
  draws only live text in sampled inks. All six scout witnesses still 0 px.
  See `scout_screen_re.md` §"The OURS panel".
* ~~**Kit blits truncated / outside frames.**~~ — **RE-TUNED 2026-07-26 evening.** The
  wrapped-bank `Rect2(0,0,31,64)` crop is gone everywhere: the shared
  `PMChrome.KIT_SRC` (and its aspect-fit `draw_crest`, feeding EuroSupercup /
  CompResult / CharityShield / LeagueTable) plus the per-screen crops in
  `ChampionshipsScreen`, `ManagersMonthScreen`, `MatchResultScreen`,
  `EndOfSeasonScreen`, `CupDrawScreen` (grid + card), `MenuScreen` (45x57 1:1,
  re-centred in the witnessed 50x65 boxes) and `MatchScreen` (content top-left at the
  witnessed y89 band, fit 42x53) all use the exact-decode figure bbox
  `Rect2(1,3,45,57)`; `MatchSimulador._club_colour` samples the same bbox.
  **`RivalScreen` was a false positive** — it consumes the nano/ bank (never wrapped)
  and is pinned by `diff_entry_parity`'s full-frame 0 px case; untouched. Gates re-run
  green: seasonend-year, cupdraw, supercup (+ scout/knockout unaffected).
  `LineupRollScreen`/`FixturesScreen` draw the whole sheet (no truncation) — left as-is.
* ~~**Preseason is gone in season two** — no friendly setup reachable at the second
  season's start.~~ — **FIXED 2026-07-26** (`5f64638`, in HEAD). The rollover assumption
  "season 2+ has no re-pick UI (un-walked)" was refuted by the refrun (R15 step 8,
  `p0664`: "Preseason for Manchester Utd." opens 1998-99, friendlies 31 Jul + 3/5/7 Aug
  1998). `Main._next_season` -> `_show_preseason_rollover()` re-raises PreseasonScreen
  after `advance_season`, picks landing on the NEW season's own `Career.preseason_dates`.
  Covered by `test_friendly.gd`.
* ~~**No contract-renewal message toward season end**, which the original raises.~~ —
  **FIXED 2026-07-26** (`5f64638`, in HEAD): the 1-April contract warning is ported,
  `test_contract_warning.gd` (ALL PASS, incl. "1998-99 fires on its own late-March/
  early-April week").
* ~~**The finance INCOME and EXPENSE screens do nothing** when opened, although both are
  tracked in captures.~~ — **BUILT 2026-07-27.** The in-code claim "no captured frame"
  was FALSE (the RE doc's own binding table lists frames 006/008/011/012). All four
  detail chromes are baked/composited from the frames (`bake_details()`), the view tabs
  are wired, and the data layer fills what the port honestly can: per-competition
  TICKETS/TELEVISION (new `detail` sub-record on the week books), euro POINTS, the named
  `SALE <name>` row, wage/hospital sub-rows, staff, ground categories — the rest reads
  £0 exactly as the frames do for a fresh save. THREE frames render-diff at **0 px**
  (006/008/012, `diff_finance_detail_parity.py`). Bonus fixes the witnesses forced:
  the CURRENT WEEK tile + season totals now read the RUNNING week's record
  (`Career.live_week_book`, saved as `week_open`), and LAST WEEK / CASH is a STORED
  close figure (`cash_close`) — frame 006's £1 disagreement proves the original stores
  it. Recorded, not fixed: the SUMMARY chrome bakes `EUROPEAN CUP INCOME` + the
  `±2,500 K.` axis static, but `orig/51_finance_season.png` shows `U.E.F.A. CUP INCOME`
  + `±250 K.` — both DYNAMIC in the original, rule underdetermined by two witnesses
  (`finance_screen_re.md` §LATENT DEFECT). **The LABEL half is now settled from the
  binary (2026-07-27), without a third capture**: `.data` holds THREE labels
  (0x659B0C `EUROPEAN CUP INCOME`, 0x659AE0 `U.E.F.A. CUP INCOME`, 0x659AF4+0x659B00
  `CUP WINNERS CUP INCOME`) and one branch chain at 0x5081B0..0x50838F picks between
  them off a virtual predicate on the competition object at `DAT_0066B1B0`, so the row
  names **the European competition the club is in**. Building it needs the baker to
  blank the label box + a `diff_finance_perweek_parity.py` re-run, which belongs with the
  next finance capture — the `±N K.` axis scale is a separate blit and still has no rule.
* ~~**TEAM TACTICS does not match the tracked original**~~ — **REBUILT 2026-07-27, see §0b.** (`tactics_subscreens_re.md` holds
  the measurements).
* ~~**Neither cheat works in play**~~ — **BOTH LIVE-PROVEN 2026-07-27, see §0b.** Original entry: MIXED PLAY (blocked on the un-located club tactic
  byte, §3b) AND the shipped THREE UP FRONT hack — Mats reports no effect ("won't get me
  goals"). ~~THREE UP FRONT~~ — **FIXED 2026-07-26 evening.** The flag/persistence/
  routing were all sound; the TRIGGER side had three port bugs: (1) the default 4-4-2
  never arms it (pick 4-3-3 — 463/476 clubs auto-pick exactly 2 FW on 4-4-2, all 20
  Premier clubs field 3/3 on 4-3-3); (2) `Tactics.repaired()` replaced an injured
  striker with the best ANY-position player (its pool carried no `pos`), silently
  turning 4-3-3 into 4-4-2 — now same-position-first; (3) worst: `_ai_featured_xi`
  fielded "best ten by CA" with no shape, so 16/20 Premier clubs armed the cave AGAINST
  Mats while he never armed it — AI XIs now field position-aware 4-4-2 like the
  original's stored club tactics. Seam-tested end-to-end (`test_three_up_front_seam`:
  live chain arms at 4-3-3, opponent doesn't, ON = the cave's 6 goals, OFF differs on
  the same seed). **NOTE for play: the cheat needs 3 natural forwards in the fielded
  XI — pick 4-3-3 in PREDEF TACTICS.** MIXED PLAY remains blocked (§3b). Also found
  and recorded: the seven TEAM TACTICS levers reach only the legacy engine —
  `MatchSim`'s stat branch never reads `rh`/`ra` (fix belongs to the TEAM TACTICS
  rebuild session).
* ~~Debt alert at week 1 despite millions positive~~ — **FIXED 2026-07-26** (`2201ccf`):
  the at-a-loss trigger followed the week's P&L; it now follows the BANK BALANCE, the
  reading the refrun witnesses support (R16 correction in
  `REFRUN_manutd_1997-98_FINDINGS.md`).

* ~~**The league calendar ended in April + the divisions overview came too late**~~ —
  **FIXED 2026-07-27.** The port played 38 rounds in 38 straight weeks (final round
  25 Apr). Witness chain (R10 p0524 badge "Week 32" on 8 Mar — nothing skipped by
  March; R12 p0610 badge "Week 37" next on Sat 18 Apr; R12/R13 p0638 Third Div P=46
  dated 2/5 BEFORE the Premier's last match) forces 38 rounds over 39 weeks with ONE
  blank Saturday in weeks 33..37 and the final round on Sat 2 MAY. Week 35 (Sat 4 Apr,
  the F.A. Cup semi weekend) is the unique real-1998 fit → `Career.BLANK_LEAGUE_WEEK`,
  `_league_fixtures()`. `DEADLINE_TAIL` 4→5 (same witnessed week-34 deadline).
  Division pacing re-anchored to the ROUND count so both R12 witnesses reproduce
  (P=44 at the 18-Apr read, P=46 complete by week 38). AND the R13 sequence now
  exists: after the penultimate round the hub presents the finished divisions' final
  tables (blank club plate, division badge, lowest tier first) via
  `pending_division_finals` + `Main._pop_division_finals` — before the last round,
  exactly as witnessed. `test_league_calendar.gd` (11 asserts) pins all of it.

Four more, reported 2026-07-26 evening (second round, same play session):

* ~~**Season-2+ talents render wrong in lineups / squad management**~~ — **FIXED 2026-07-27** (`6e2cee8`, in HEAD).
  Original entry: — "they have stars,
  but no position or roles". New intake players must carry the same fields (position,
  posFine role, etc.) and draw exactly like the decoded squad.
* ~~**The cup-draw animation is not the original's** — today the spinning ball plays with
  every pairing already on screen; the original reveals the draw progressively.~~ —
  **BUILT 2026-07-27.** The RE doc's "MANO appears in no captured frame" was FALSIFIED:
  p0127 holds MANO7 byte-exact at (106,144) with the drawn club's name on the slip, and
  the p0125→p0131 chain witnesses the whole sequence (empty grid → clubs land one at a
  time, home first → park on BOMBO00; every mid-draw frame is on a different BOMBO =
  the drum spins DURING the draw, which also explains the 07-25 "does not animate" film
  — it filmed a finished, parked draw). `CupDrawScreen.reveal()` plays it on the live
  card; the slip name reproduces p0127's 265 ink pixels at 0 px (calend12, field-sum
  380, the 192→114 / 240→144 / 220→144·128-checkerboard paper-tone rule). OURS,
  flagged: cadence, tap-to-skip, the list-form extension. The idle screen now parks on
  BOMBO00 instead of the invented endless spin (`cupdraw_screen_re.md` §"The reveal").
* ~~**Youth recruitment and training does not work like the original at all**~~ —
  **LOOP FIXED 2026-07-27 (Session D, B1-B10** — `youth_re.md` §"THE LOOP"**).** The
  model was already byte-exact; the loop around it lost state and armed dead searches.
  B1 the six LED flags persist on Career; B2 a zero-LED search is refused with the
  EXE's own alert (THE "recruitment doesn't work" bug — it armed a search that could
  never match and sat dead 15-28 weeks); B3 the youth manager's READY report rides
  pending_alerts; B4 a READY row carries the declared-OURS "PROMOTE" cue; B5 ROL
  draws the CAMROL fine-position icon; B6 easter-egg arrivals no longer block or
  pollute the faithful loop (cap + exclude list count pool members only; a talent's
  BASE now sits at his potential so growth can reach it); B7 SQUAD_CAP declared OURS
  (no capacity string in the EXE); B8 the two youth randomize() sites fold into ONE
  persisted career RNG stream (first S3 step); B10 stale staff blurbs corrected.
  `test_youth_loop.gd` (13 asserts) + extended `test_youth_screen.gd`; all five
  youth witnesses re-run **0 px**; test_youth_loop added to the CI gate (19→20).
  **OPEN: B9** — one wine capture run closes the three visual gaps (filled PLAYERS
  FOUND, filled roster row, DRIBBLING/HEADING training chips); needs a driven career
  with a completed search at the binary's own 30-55-week cadence.
* ~~**The Ground screen's stadium image never grows**~~ — **ROOT-CAUSED + FIXED
  2026-07-27.** The s63 "band width means most expansions don't cross" defence was
  **empirically false** (its Arsenal example was the worst case, not the typical one:
  38% of English clubs cross a band on the +4k card, 74% on +8k, 100% on +12k — Man
  Utd crosses tier 4→5 on the CHEAPEST card). The real, byte-provable bug: the
  original's tier input is a TWO-FIELD SUM — `FUN_0051a6e0` adds `[ground+4]`
  (built capacity) **+ `[ground+8]` (expansion HEADROOM, EQUIPOS `param_1[7]`)**
  before the /130000 division, and the extractor DISCARDED the headroom field, so
  91 clubs (~30 English: Port Vale, Cardiff, Barnsley, Burnley, Luton …) rendered
  one-to-two tiers too small and needed far more seats to move. Fixed end-to-end:
  `capacityHeadroom` decoded with the loader's exact 4000-quantisation
  (equipos_parse → game_db, kill-tested: witnessed clubs 0, count == 91),
  `Career.stadium_headroom` seeded/persisted/healed-on-load, tier input =
  capacity + headroom. Also fixed while in there: the legacy-save landmine
  (capacity-0 saves collapsed to `0 + added` on works completion — healed from
  GameDB at load) and the season-2+ `weekly_net` projection ignoring every
  completed expansion (`club_view` carries no capacity). Tier-transition now
  test-pinned (`test_stadium_works`: a completed +4,000 across a band edge MUST
  change the picture) and both stadium suites are in the CI gate. Still open,
  doc-flagged (`stadium_screen_re.md`): ~~the EXE's 150,000 SEATS ceiling~~ —
  **CLOSED 2026-07-28 (§0aa), the addend is capacity + headroom;** ~~`remodela.png`
  works-marker draw position~~ — **the hypothesis was WRONG: it is the IMPROVE button's
  icon, already baked (§0aa).** ~~Still open: 10 tiles corrected-by-mapping only.~~ — **NARROWED 2026-07-28 (s76):**
`fix_estadio_wrap.py --verify` puts the strongest vertical seam of **all twelve** shipped tiles
at z = 3.0..3.9 (no seam) and at z = 13.1..14.8 if the wrap is re-applied, so the **+256 column
wrap is validated on 12 of 12 as a property of the data**. What only the two rendered tiers
(3 and 4) confirm is the ROW offset, which the seam statistic cannot see.

## 0b. Mats's live QA, 2026-07-27 morning — fix FIRST (next session = TEAM TACTICS)

* ~~**SCOUT name-search must be INSTANT**~~ — **BUILT 2026-07-27.** Every keystroke in
  the panel's NAME box runs `Career.instant_name_search`: a synchronous lookup over the
  whole decoded database (live division + all static GameDB clubs + free agents),
  matching surname OR full rendered name; hits land as NORMAL scout results with the
  standard tap-through to the offer card. No mission armed, no other filter needed;
  Enter drops the panel; SEARCH with name-only re-fires the lookup instead of the
  refusal alert. Zero new chrome (the panel already carried the NAME object) — all six
  witnesses + both bar gates re-run 0 px / PASS. The mission machinery is untouched
  for attribute searches. See `scout_screen_re.md` §OURS panel.
* ~~**TEAM TACTICS still broken end-to-end**~~ — **REBUILT 2026-07-27 (Session B).**
  The modal is frame-baked from parity-run `orig/25_team_tactics.png` at (57,95)
  526x303 (`teamtactics_chrome.png`, baker PART 3); EQWINX is the TICK (byte-proven
  by the 74-px `orig/26` diff); the exit is the real baked OK plate; the invented
  close-X, proportional PASSING bar, hand-drawn tick and reconstructed geometry are
  GONE; STEP is 5. The %s were wrong because the port used GLOBAL defaults — the
  original's are PER-CLUB `.DBC` lever bytes, and the byte→lever map is now CLOSED
  (Bolton witness; `club_tactics_re.md`): fresh careers seed from the club's own
  stream (Bolton starts 45/55, MIXED/MEDIUM/ZONAL/SHORT/OWN exactly as frame 25).
  Gate `diff_teamtactics_parity.py`: chrome 0 px vs BOTH frames (value plates =
  declared app-font bucket). Levers→engine: the LIVE modal levers now reach the
  positional engine's `team[0xc1..0xc7]` (`Pm98LineupFeeder.build lever_overrides`)
  — but the app PLAYS on the instant/stat runner, which reads NO levers in the
  ORIGINAL either (`hack_three_forwards.md` §1), so lever→result coupling on the
  played path honestly lands with the M5 wire-in (§1). The MIXED PLAY cheat is the
  exception and works NOW (below). The `MENTALITIES` order and legacy-fallback
  factors are unchanged.
* ~~**⚠ THREE UP FRONT still does not fire in play**~~ / ~~MIXED PLAY cheat dead~~ —
  **BOTH LIVE-PROVEN + MADE VISIBLE 2026-07-27.** `app/tests/test_cheats_live.gd`
  drives the REAL career chain (AudioManager switch → saved tactics dict →
  advance_week → repaired/_pad_xi → MatchSim): 4-3-3 arms the forwards trigger
  (≥6 manager goals every week), and the NEW MIXED PLAY variant arms on the
  manager's MIXED PLAY tick even on 4-4-2 (the club-tactic byte hunt is over —
  it is mentality `+0x1db==2`, so §3b's memory-diff plan is obsolete; manager-side
  only BY DESIGN, 178 clubs default to MIXED). Cheat OFF holds the stock cap.
  Visibility: the OPTIONS cheat row now prints the fielded XI's natural-FW count
  ("N FW", white when ≥3 = armed) — the seam the QA flagged (a 4-4-2 XI silently
  disarms the forwards trigger; MIXED PLAY is the reliable trigger now). Final
  confirmation in Mats's hands on the shipped APK remains the acceptance bar.

## 0c. Mats's orders, 2026-07-27 midday — NEXT SESSION, fix-first

* ~~**S5 promoted from backlog to fix-first: European ties must run on the byte-exact
  engine.**~~ — **CLOSED 2026-07-27.** Foreign entrants now field their own shipped
  TRUE XIs: `Main._true_xi_index()` resolves every club's `club_tactics.json` `xi`
  (the tactic slots' stored player ids) over its `game_db` attr squad — **475 clubs
  fully resolve, including all 383 foreign clubs** — and feeds `Career.euro_xis`
  (game data, never persisted, youth_pool pattern). `Career._xi_for`'s euro branch
  returns the TRUE XI instead of `[]`, so `MatchSim._usable` passes and the tie runs
  on `Pm98StatMatch`. Proven end-to-end: `test_career` now drives a season WITH the
  European competitions minted — 53 ties resolved, **fallback_count == 0** (was ~37
  `[MATCHSIM_FALLBACK]`/season). **S7 CONFIRMED shipped** while in there: 24 clubs /
  6 groups is `Career.EURO_FIELD`+`EURO_GROUPS` (witnessed field sizes,
  euro_league_screen_re.md); the original's TWO QUALIFYING ROUNDS are deliberately
  not modelled — a DECLARED divergence (Career.gd `EURO_FIELD` comment: the app's
  field enters at the group phase).
* ~~**EXIT from the career hub must go straight to the ORIGINAL start screen.**~~ —
  **BUILT 2026-07-27, witness-first.** The open question ("does the original
  interpose a confirm?") was answered by driving the real game: hub EXIT raises
  the SAME "Do you want to leave the championship ?" Yes/No box as the in-match
  EXIT, over the **LUT-dimmed** hub (pixel-checked: 255→160/160/164, 100→80 — the
  PMAlert dim family), and Yes lands on the **TITLE screen**. Three witness frames:
  `screenshots/wine-captures-2026-07-27-hubexit/` (hub_before_exit /
  hub_exit_confirm / hub_exit_yes_title). Wired: `MenuScreen.confirm_exit()`
  (modal Yes/No over the dimmed hub, LeaveConfirm's box + press feedback),
  `Main._leave_career_to_title()` (career SAVED first — nothing is mid-flight at
  the hub, unlike the in-match abandon), title mounted over the home browser
  exactly like boot. The old `_leave_career()` → DB-browser route is gone.
  `test_menu_screen.gd` +5 asserts (modal, No dismisses, Yes emits once).

The **manager game** — career, leagues, transfers, finance, tactics, cups, Europe, youth,
staff, training, contracts, board, screens, scouting, insurance, injuries, honours — is
built, reverse-engineered from `MANAGER.EXE` and its data files, and render-diffed against
real captured frames at 0 differing pixels on screen after screen. What is genuinely
under-built is **the match itself**: the byte-exact engine is not yet the engine the app
plays with, and the animated 2D match view does not exist.

## 1. The byte-exact match engine (M5) — THE critical path

The app plays every match on `MatchSim.simulate` (`Career.gd`, `Cup.gd`), which — corrected
2026-07-26, the old wording here understated what has shipped — routes to **`Pm98StatMatch`**,
the byte-exact port of the original's instant-result runner (`FUN_0044ee70` family,
oracle-anchored), whenever both XIs pass `_usable`. Only when an XI is unusable does it fall
back to the abstracted legacy `MatchEngine` (app-tuned constants, validated against
real-football aggregates, NOT against PM98 output) — since S5 closed (2026-07-27: foreign
clubs field their shipped TRUE XIs) a full EUROPEAN season runs at ZERO fallbacks. The
instruction-exact POSITIONAL engine (`Pm98Driver` / `Pm98Outer` / `Pm98Movement` /
`Pm98Action` / `Pm98Resolver` / `Pm98CollBuilder`) exists, is oracle-locked leaf by leaf
against a Ghidra PCode emulator, and is **not wired into gameplay**. Swapping it in is the
whole game's fidelity ceiling.

Where it actually stands, measured 2026-07-26 (`docs/re/M5_S58_FRONTIER_1032.md`):

> ⛔ **THIS SECTION IS STALE (flagged 2026-07-28, s76) — read the two sentences below first.**
> "Not wired into gameplay" is wrong since **s74**: `MatchSim.simulate` routes every fixture to
> one of the original's OWN two engines, and a WATCHED match runs the positional one.
> "Byte-exact over clk 1-1032" is wrong since **s59**: the verified window is **clk 1-2836**,
> 1,072,592 words across NINE captures, zero mismatches — minute ~8.9, 19.7 % of a half. The
> open road is steps (a)-(d) of `handoff-pm98-m5-s59-frontier-2836-2026-07-27` §Open, and it is
> the largest remaining item in the project. The rest of this section is kept for its history.

* Against the live silicon captures the port is **byte-exact over clk 1-1032** — 22 players
  x 16 fields, the ball x 10 fields, its 51-word predicted-trajectory tail, and the LCG
  state at every tick boundary. Across all **eight** banked captures: **319,335 words,
  zero mismatches, zero tolerance.**
* **clk 1032 is match minute 3.** `+0x450` is the open-play tick counter and the minute is
  `+0x450 * 0x2d / +0x19ac` with `+0x19ac = 14400`, so the verified window is the first
  ~3.2 minutes of one reference match — 7.2 % of a half.
* Therefore the frontier is a CAPTURE problem, not an engine problem. Extending
  `tools/re/wine/m5_rsp_capture.py` past clk 1032 is the only thing that can falsify the
  engine further, and it runs at ~1 clk/10 s in-window — roughly **90 minutes of wall
  clock per further minute of match time**, plus a fresh boot per attempt (a dead debug
  stub cannot be re-attached; see the s58 write-up). Reaching the kill-test divergence at
  clk ~3500 is ~7 hours of capture. That is a scheduling decision, not a research one.
* Also open: the `run_match_from_struct.gd` kill-test divergence (first goal 11' vs the
  reference 21', i.e. clk ~3500 vs ~6700 — far beyond any capture, so unattributable
  today); unifying the three `+0x43c` null sentinels (absent / 0 / -1, behaviour-affecting);
  the cross-seed sweep (`PM98_SEED` plumbing landed in s55, unrun).
* Full history: `docs/re/PLAN_byte_exact_match_engine.md`, `docs/re/EXACT_PORT_PLAN.md`
  §"Gaps to close" and §"Already decoded — cite, don't redo", `docs/re/M5_*.md` (s9→s57,
  newest last). **Cite these; do not re-derive.**

## 2. The animated 2D match view + sprite extraction

`docs/re/APP_VS_SPEC_AUDIT.md` §A8: the faithful JUG render is not built and the side-on
WATCH view is an approximation. Specs are in `docs/re/jug_render_spec.md` and
`docs/re/match_view_re.md`. **Deprioritised by Mats's own 2026-07-01 decision** recorded in
`PLAN_byte_exact_match_engine.md`; the results/commentary presentation (`MatchScreen.gd`)
is real and shipped, and PM98 ships two match presentations, so this is the second one.

## 3. The screen / model tail

* ~~**The knockout views** — NO LONGER BLOCKED ON EVIDENCE, still NOT BUILT.~~ — **STALE
  PROSE, corrected 2026-07-28.** All five layouts were built across s71 / s73, and
  `tools/re/diff_knockout_parity.py` is **14 of 14 cases at 0 differing pixels**. The
  paragraph below is kept for the evidence trail it records, not as a status. The old entry
  said "the frame is in hand"; one frame was, and every tie in it was unplayed, so leg
  scores, aggregates and the winner ink were unwitnessed. A scheduled-probe drive
  (`plans/season_euro_probe.json`) photographed the whole competition rail every second hub
  visit through 1997-98 and caught **five layouts, four never seen before**: compact list,
  kit list, the four-panel bracket, the two-card semifinal view with `FINALIST` plates, and
  the trophy+`WINNER` final. Geometry, column sets and the chrome/content split are measured
  in **`docs/re/knockout_views_re.md`**. One cell remains unwitnessed — a bracket `AGGR.` with a
  decided tie. The other, a filled `WINNER` band, turned out to be **already in the repo**:
  `09_comp_charity.png` carries it, and outside the name bar that band is pixel-identical to
  the European final's empty one. `tools/re/wine/knockoutwatch.py` finds either cell in a
  directory of frames.
  Two seasons were driven and both missed those two cells for a structural reason (the view
  auto-advances the moment the next phase is drawn), so a third season is the wrong move —
  page the phase paginator BACK from Semifinals instead. See `knockout_views_re.md`.
  **The LIST layout is BUILT and 0 px** (2026-07-26): `app/scenes/KnockoutScreen.gd`, baked
  by `tools/re/build_knockout_chrome_from_frames.py`, proven by
  `tools/re/diff_knockout_parity.py` against the European 15-tie frame and the domestic
  16-tie frame, and raised by `Main._show_cup_screen` for any phase of nine ties or more.
  Panel geometry is asserted by `app/tests/test_knockout_layout.gd`.
  **Still to build: the bracket (4 ties), the semifinal cards (2) and the final (1)** —
  all measured in `knockout_views_re.md`; a round that small still falls through to the
  SORTEO card. The `WINNER` band is witnessed.
  **The BRACKET is BUILT and 0 px (2026-07-26, s62).** `KnockoutScreen._draw_bracket`,
  raised by `Main._show_cup_screen` at exactly 4 ties, gated by `diff_knockout_parity.py`
  against both witnesses (euro leg-1-played, F.A. Cup unplayed) at **0 px outside three
  declared buckets** (barra kit; the eight kit columns = MINIESC sprite + the un-reversed
  outline pass; the euro case's career-state rail). Every anchor was solved off the frames
  — see `knockout_views_re.md` §"The bracket, as built". Verified live: `PM98_CUP_SHOT`'s
  real career raises the domestic bracket at its F.A. Cup QTR. What stays open: a decided
  `AGGR.` cell is still unwitnessed (the port applies the leg-1 grammar + the list's
  winner rule, declared as inference) — **WITNESSED AND CORRECTED 2026-07-28 (§0aa): the
  winner's whole plate is repainted with a chevron at each end, and the AGGR. box has
  its own score ink and no dash blend; gate case `knockout_euro_qtr_done` is 0 px.**
  **The SEMIFINAL CARDS and the FINAL are BUILT and 0 px (2026-07-27).**
  `KnockoutScreen._draw_cards` / `_draw_final`, raised at 2 / 1 ties, gated by
  `diff_knockout_parity.py` cases 5-7 against three witnesses (euro semis leg-1-played,
  euro semis drawn in a SECOND career, cocacola semis drawn; euro final undecided) at
  0 px outside the declared buckets (barra kit; euro career-state rail; the eight 17x20
  ridi icon rects = the un-reversed outline pass; the final's two 48x60 kit wells = the
  un-extracted hi-res panel kit bank). The cocacola witness FORCED a model fix — the
  original's Coca-Cola SEMIFINALS are two-legged (`Cup` `semi_legs`, LEAGUE_CUP_OPTS 2).
  The FINAL's neutral ground is a declared-OURS rng pick (Das Antas 1998 = one witness,
  no rule derivable). See `knockout_views_re.md` §"The semifinal cards and the final, as
  built". **Still open here: the kit list (5-8 ties) falls back to the list form.** The
  F.A. Cup semifinals band, the Coca-Cola semifinals (two-legged) and the Coca-Cola FINAL
  are **no longer unwitnessed** — frames banked 2026-07-28 in
  `screenshots/wine-captures-2026-07-28-knockout-decided/` — but they are **not built**, so
  those phases still fall back to the SORTEO. The U.E.F.A. and Cup Winner's 2/1-tie bands
  remain unwitnessed.
* ~~**Draw-then-play**~~ — **CLOSED 2026-07-26.** The separation is witnessed twice in two
  competitions (F.A. Cup R2 played 14 Dec → R3 drawn unplayed 20 Dec → played 10 Jan;
  Coca-Cola R4 played 1 Dec → Qtr Finals drawn unplayed 7 Dec), so the rule needed no
  inventing: the next round is drawn as soon as the previous one resolves and is played at
  its own scheduled week. `Cup.draw_next_round` + `b["pending_draw"]`,
  `app/tests/test_cup_draw_then_play.gd`.
* ~~**Per-club ground prices**~~ — **CLOSED 2026-07-26.** The cost function `FUN_0057ddd0` is
  reversed and every one of the 476 clubs is priced from the binary's own jump tables, keyed
  by the club's stature band (`GroundCost.gd`, 24/24 witnessed prices exact including the
  original's float32 dirt). See `docs/re/stadium_screen_re.md` §"The cost function". What
  remains there is the per-club STARTING grades — `club+0x50`, the preset selector, is not
  yet reversed, so only Man Utd's captured grades are used and nothing is interpolated.
* **The kit-outline blit pass** — **TWO of its THREE components CLOSED 2026-07-27**
  (`knockout_views_re.md` §"The outline pass, SOLVED in two of three parts"): the
  "unexplained interior" was the realised-palette bug (MINIESC exported under the shared
  VGA table; all 476 kits re-exported under MANAGER.PAL + Windows statics — the MINIBAND
  fix, third bank), and the ring is POSITION-CONSTANT (shared silhouette) and now baked
  verbatim (`kitwell_under_L/R.png`, `icon_under/over_sf1/sf2.png`). Bracket kit residual
  3868/3556 → 1659/1691; the semifinal cards' icons hit **0 px** on the cocacola witness.
  Still open: (a) the on-sprite edge bevel of the 48x64 kits (club-dependent, rule
  un-reversed, ~160-190 px/cell — the buckets stay), (b) porting the same bake to
  EuroGroupScreen's 24 group kit cells (~1260 px/frame) and OffersScreen's panel.
* ~~**MINIBAND dither** — 99 px across the six euro group frames.~~ **CLOSED 2026-07-26.**
  Not dither: the flags were decoded with the shared VGA palette instead of `MANAGER.PAL`
  plus the 20 Windows static system colours. Re-exported, **0 px** over all 24 flag cells
  (`euro_league_screen_re.md` §Parity).

## 3a. Reachability — WIRED 2026-07-26 (s62, same day it was found)

The complete-audit pass (`docs/re/AUDIT_COMPLETE_2026-07-26.md` §1) traced the call graph
and found every knockout/Europe view gameplay-unreachable: `_show_competitions()` had zero
callers and the RESULTS rail was baked, inert chrome. **Fixed the same day**: the rail is
the original's own door (every knockout/Europe frame in the RE corpus was captured by
clicking it), so `ResultsScreen` now hit-tests the eight competition chips and emits
`competition_selected`; `Main._open_rail_competition` routes a chip through the existing
`_open_competition` actions, ignoring chips whose competition the career is not in (as the
original's dimmed chips are); `KnockoutScreen`'s own rail is connected the same way, so
competition-to-competition hops work. Player path: hub → RESULTS → rail chip →
cup / Europe views. The play-off chips stay inert (no play-off view exists — honest gap).
Covered by `test_results_screen`. ~~Still open from the audit: the dead `CupScreen.gd` +
`_show_one_off_final()` and the interim `_show_training()` browse — a cleanup pass.~~ —
**CLEANED 2026-07-27**: `CupScreen.gd` deleted along with its whole orphan family
(`_show_one_off_final`, `_show_competitions` — the zero-caller browse the rail replaced —
`_cup_view`/`_cup_group_view` payload builders, the three `*_status_word` helpers, the
interim `_show_training` browse and its `PM98_TRAIN_SHOT` rig, `test_cup_screen.gd`).
The live routes (rail → `_open_competition` → `_show_cup_screen`, LINE-UP →
`_show_training_screen`) are untouched — parse check, `test_results_screen`,
`test_cupdraw_screen` and the cupdraw parity gate re-run green.

## 3b. THREE UP FRONT — the one place this port draws a pixel the original does not

SHIPPED 2026-07-26 and listed here so it is never a surprise: the MANAGER_HACK.EXE cheat
(`docs/re/hack_three_forwards.md`) is ported into `Pm98StatMatch` and switched by a row on
the OPTIONS modal. Default OFF, and OFF is bit-identical to stock — the eight banked
oracle fixtures reproduce draw-for-draw with the flag on and no forwards in the XI.
`tools/re/diff_options_parity.py` bounds it: the rest of that modal is still 0 px against
the MANAGER.EXE capture, the row's band overlaps none of the original's controls, and the
original draws nothing underneath it.

**The SECOND and last such site, 2026-07-26: the SCOUT door.** The EXTRA SEARCH FILTERS panel
(§`docs/SPEC_scout_attribute_search.md`) had been shipped and working since 07-25 behind a
bottom bar with no label of any kind — Mats: *"I don't see the new search objects."* The bar
now carries `EXTRA SEARCH FILTERS` / `TAP HERE`. While fixing it the bar turned out to be the
**original's own rollover readout** (three witnesses, now built at 0 px — see
`docs/re/scout_screen_re.md`), so the two uses are split by state: a row held → the original's
readout, nothing held → the label. `tools/re/diff_scout_bar_parity.py` bounds it from the
frames: all ten committed frames of that screen are either a readout or blank, and the two
segments overlap none of the 21 original controls. **No other screen carries invented pixels.**

~~**Still to do here — the MIXED PLAY variant.**~~ — **LANDED 2026-07-27.** The club
tactic byte hunt is over without a memory-diff: it is the MENTALITY lever
`club+0x1db` (2 = MIXED), pinned analytically by the frame-25 Bolton witness
(`club_tactics_re.md`). The same OPTIONS switch now arms EITHER trigger — three
natural forwards fielded, OR the manager's MIXED PLAY tick (manager-side only BY
DESIGN: 178/476 clubs default to MIXED, an any-side trigger would break the league).
OFF is still stock (oracle fixtures reproduce). `hack_three_forwards.md` §4b; live
proof `app/tests/test_cheats_live.gd`.

## 3c. Model-level divergences from the season audit — ALL CLOSED (heading corrected 2026-07-28)

From `docs/re/AUDIT_season_playthrough_2026-07-25.md` (previously /tmp-only, now in-repo);
verified still open at HEAD `4076800`:

* ~~**S3 — a career is not reproducible at a fixed seed.**~~ — **CLOSED 2026-07-27.**
  Every former per-call `randomize()` in `Career.gd` (10 remaining sites) and Main's
  five career paths (season-open chain, weekly advance, honours seed, free-agent
  signing, season rollover) now draws from the ONE persisted `Career.career_rng()`
  stream (B8's pattern, completed); assigning `career_rng_state` re-pins a live stream
  so the acceptance machinery can pin a career after create(). Proven:
  `test_career_seed.gd` (two same-seed careers identical after 12 weeks) — and
  `test_pyramid`'s flake is gone (3 consecutive green runs), so BOTH now sit in the CI
  gate (20 → 22 tests). Presentation randomness (commentary narration, the DB-browser
  sandbox sim) deliberately stays local. Cross-BOOT determinism still bounded by
  GameDB's load-time rolls (the original's own `time()` behaviour — not a gap).
* ~~**S5 — European ties run on the invented legacy engine.**~~ — **CLOSED 2026-07-27**
  (§0c above): foreign entrants field their shipped TRUE XIs via `Career.euro_xis`;
  `test_career` proves a European season at zero fallbacks (53 ties resolved).
* ~~**S8 — no player ever retires.**~~ — **CLOSED 2026-07-27**
  (`docs/re/retirement_re.md`, `app/scripts/Retirement.gd`, gate `test_retirement`, in CI).
  The three "blocking" functions were the wrong lead — `FUN_005865b0` is a list teardown,
  `FUN_005c1df0` is `SetCursor`, `FUN_00443180` is an unrelated UI dispatcher. The real
  entry point comes off the STRING: 0x663A58 sits in the message table at slot 0x662CE4,
  read once, from inside **`FUN_0058AC90`** — the original's retire/release/keep decision,
  called per player by the rollover pass `FUN_0057A730`. Ported byte-for-byte:
  **retirement age = 35 for a keeper, 33 for an outfielder** (`FUN_0058B020`:
  `0x23 - 2*(player+0x1c != 0)`, and `+0x1c` is the position band `equipos_parse.py`
  already decodes), fired **only on a contract that has run out** (`FUN_00584340 >= 1`
  returns early); the record is then **reborn** by `FUN_0058B030` — birth year advanced by
  `rand(3)+10` so he comes back 10-12 years younger, VE/RE/AG/EN restored from the shipped
  base block at +0xaa, a new name from the game's own NOMBRES.30/APELLIDO.30 pool, a new
  id. At a rival the reborn man **stays at his club**, so the population is conserved
  (measured: 441 rival players, unchanged over five seasons) and the "ages into a dead
  end" is gone; at YOUR club he lands in the free-agent pool (club 0x26de), exactly as the
  binary's 0x58AD9C overwrite does.
* ~~**The manager's squad melts across a season.**~~ — **ROOT-CAUSED + FIXED 2026-07-27**,
  and it was NOT the "sparse English squads" data gap it had been filed under (§5). Probe
  `app/tests/diag_bare_roster_probe.gd`: club 38 finished a season with **6-10 men on 15 of
  40 career seeds** while its static record holds 22 — every expiring contract left and
  nothing replaced them. `FUN_0058AC90` @0x58AE55 is `cmp ecx,0xd / jb keep`: **the
  original never releases anyone from a squad under thirteen** (the count is the running
  one, tested before the man in hand is dropped, so the resting point is twelve). With the
  floor: 0 bare rosters in 20 seeds. The matches-to-renew clause (`player+0x86`/`+0x87`,
  seeded since 07-24 and never fired) now renews the deal too.
* Smaller opens from the same audit + refrun: ~~the running-at-a-loss **sacking
  threshold**~~ — **MEASURED 2026-07-27**: `FUN_00545FD0` @0x546013 is
  `cmp [club+0x224],3 / jbe`, so the board acts on the **fourth** consecutive week in the
  red (`LOSS_SACK_WEEKS = 4`, which the port had guessed and flagged as ours), and a THIRD
  dismissal reason exists — **a squad under 16 men** (@0x546063). All three of the board's
  messages are now the binary's own strings verbatim, and the weekly pass's reputation
  move (-5 in the red, +1 back in the black) is wired. ~~Still open: the sacking SCREEN
  itself~~ — **BUILT 2026-07-28 (§0aa): it is the weekly hub run's own modal, and the port
  now raises it there and exits to the title.** Still open: the Coca-Cola Cup home TV fee
  (pays £0, flagged — three more channelTV captures on 07-28 were all the league £90,000);
  ~~the weekly-illness (virus/cold) insurance path~~ — **BUILT 2026-07-28**;
  ~~the insured-row document icon~~ — **BUILT 2026-07-28**;
  ~~**O1** board objective is a category~~ — **CLOSED 2026-07-27**: the START OF SEASON
  sheet now prints the game's OWN witnessed label (`club_economy.json`, 92 of the 94
  English records, merged by `GameDB._apply_club_economy`); the app's position-derived
  label survives only as the fallback for the two records without one;
  ~~**O3** the original names every club's manager on START OF SEASON~~ — **CLOSED
  2026-07-27, from source**: the manager IS in EQUIPOS.PKF. It is the **tag-2 side
  record's name** — the record `equipos_parse.py` had always walked and skipped as
  "un-identified". Found by searching the archive for the XOR-0x61 encoding of "Wenger";
  the hit lands on Arsenal's tag-2 string and **all 476 clubs carry exactly one**
  (Ferguson / Evans / Gregory / Vialli / Todd …). `game_db.json` rebuilt: 476 managers,
  up from a 44-row hand transcription, and 43 of those 44 agree exactly — the one that
  does not is Lincoln C. ("Westley" transcribed, **Beck** in the data, and Beck is the
  1997-98 man). The extractor's standing note "NO manager field exists in EQUIPOS" was
  simply wrong and is corrected in place; ~~**S7 remainder**~~ — **CONFIRMED 2026-07-27**: 24 clubs / 6 groups IS shipped
  (`Career.EURO_FIELD`/`EURO_GROUPS`, witnessed field sizes); the 2 qualifying rounds
  are a DECLARED divergence (the app's field enters at the group phase).

## 4. The SHOOTING appendix

**NO-GO, decided by Mats 2026-07-27.** Asked directly and answered "no-go for now": it
changes every result in the game, and the M5 engine wire-in is the next session and will
re-decide how shots resolve anyway, so building the appendix first would tune against an
engine that is about to be replaced. Not built, not started. Re-ask after the wire-in.

## 5. Data completeness

`app/data/game_db.json` carries the decoded database. Still partial:

* ~~English-league squads are sparse (the bio-interleaved record format is not fully
  cracked).~~ — **STALE, REMOVED 2026-07-27.** Measured against the shipped
  `app/data/game_db.json`: **9,547 players, every one with a full 10-attribute row and a
  position**; the 92 English clubs field 17-30 men each (avg 21.3, min Norwich C 17). The
  bio-interleaved format stopped mattering when `tools/extract_squads_exact.py` replaced
  `extract_english.py`'s anchor hunt with the byte-exact engine parser
  (`tools/re/equipos_parse.py` == `FUN_00579c70` + `FUN_005820f0`) on 2026-07-06 — this
  line simply outlived it. What the gap was actually being blamed for (a career squad
  melting to six men, and `test_pyramid`'s "every live-division club fields a squad after
  movement" flake) is the missing 13-man release floor, fixed in §3c.
* ~~~876 directory-only teams beyond the detailed records (separate format).~~ — **STALE,
  REMOVED 2026-07-28 (s76), and it is a measurement, not a judgement.** There is no such
  set. Every club archive in `DBDAT` holds **exactly 476 entries** — `EQUIPOS.PKF` 476
  `.DBC` payloads, `MINIESC`/`RIDIESC`/`NANOESC` 476 `.BMP` each (`BIGESC` 92, the English
  clubs only) — and `app/data/game_db.json` carries **476 clubs and 9,547 players**, every
  club populated but two, both of which are the game's OWN special records: id 1381 "Stars"
  (the all-star XI, 13 men) and id 1382 "Free players" (the free-agent pool, empty at season
  start). Nothing is missing and there is no second format to crack.
  - The number that DOES exceed 476 is the kit-ramp set: **829 `P96A`/`P96B` files**, because
    `DatSim\paletas` is inherited from the engine's PC Fútbol parent and covers clubs PM98
    does not ship. 470 of PM98's 476 resolve one; the other six fall back to `P96A0000.DAT`,
    which is the engine's own miss branch (`kit_palette_re.md` §2).
* ~~`DAT.PKF` / `DATSIM.PKF` match-sim rating tables are still LZ-packed.~~ — **MOOT, closed
  2026-07-28 (s76).** This entry already carried its own answer: *"Only needed to tune the
  abstracted engine toward the original — the byte-exact engine gets these from the code path
  itself, so this is track-A work only."* Track A is gone. Since s74 BOTH of the original's
  engines are ported byte-exact and `MatchSim.simulate` routes every fixture to one of them
  (`Pm98StatMatch` for an instant result, `Pm98LiveMatch` for a watched match), so there is no
  abstracted engine left to tune. Unpacking them would buy nothing.
* ~~**The top-level MINIESC kit bank looks mismapped**~~ — **FIXED 2026-07-26 (s62).**
  The id mapping was fine (1381 is club 9902 "STARS", whose kit sprite IS a star); the
  DECODE was not: `export_kits()` rendered through the Pillow path, which honours the
  stripped DIB header's bogus `bfOffBits`, rotating every 48-wide sprite 21 rows + 16
  columns — exactly `export_art.py`'s own module warning. All 476 re-exported through
  `exact=True` (`pkf_image.dib_indices`). Two corrections to the old note: it was NOT
  invisible (MenuScreen, MatchSimulador and `PMChrome.kit()` consume this bank), and the
  BRACKET now blits it.

## 6. Android packaging / device polish

APKs build in GitHub Actions (`build-android.yml`) and publish to the rolling `latest`
pre-release; **never run `./gradlew` on this box** (8 GB, it OOMs).

~~app icon/splash~~ — **BUILT 2026-07-27 from the original's own files**
(`docs/re/android_packaging_re.md`): the launcher icon is `MANAGER.EXE`'s own 32x32 8bpp
`RT_ICON` — the football Windows drew for the game — decoded straight out of the PE
resource tree by `tools/re/export_exe_icon.py` and scaled 6x nearest-neighbour; the boot
splash is the extracted title frame `art/screens/title/fondo7.png`, unfiltered and 1:1.
Godot's default `icon.svg` is deleted. **No adaptive icon on purpose** — it needs a
background layer the original does not have, and any plate colour would be a guess.

~~a signed release build~~ — **WIRED 2026-07-27, waiting on one secret.** The workflow
exports `--export-release` when `ANDROID_RELEASE_KEYSTORE_BASE64` (+ `_KEY_ALIAS`,
`_KEYSTORE_PASSWORD`) is set and falls back to the debug-signed APK when it is not, so
nothing breaks without it. Verified against the shipped engine rather than assumed: Godot
4.6 has no `export/android/release_keystore` editor setting, so the key is passed through
`GODOT_ANDROID_KEYSTORE_RELEASE_{PATH,USER,PASSWORD}`. **Mats declined the keystore 2026-07-27** — the only thing it buys him is not having to
uninstall before installing a new build, and he does not care. Do NOT raise it again.
The wiring stays (it costs nothing dormant); if it is ever wanted, generating the keystore is
deliberately left to Mats (a key made in CI would change every run, which makes every
build a different app to Android); the exact three commands are in the packaging doc.

Still open: **the real-device pass** (touch targets, tall-phone letterboxing, the launcher
mask) — it needs the APK on a phone, which this box cannot do.

## What is NOT missing (so the list above reads correctly)

* **Art extracted from the original files**, not drawn: 1915 faces, 1480 kits, 675 screen
  chromes, 387 flags, 62 icons, 13 fonts, 9 match sprites — all under `app/art/`.
  PKF decompression is solved (`tools/re/pkf_unpack.py`, `pkf_image.py`, `export_art.py`,
  `export_faces.py`, plus the per-screen `build_*_chrome_from_frames.py` bakers).
* **Audio extracted from the original files** (`docs/re/audio_re.md`): the DINAMIC0 menu
  theme from `MUSICAS.PKF` (S3M) and eight match SFX from `SFX/AMBIENTE.PKF` (u8 PCM
  @ 11025 Hz), wired through the `AudioManager` autoload. Not shipped: the alt goal roars,
  the "oé" chants, and `SFX/COMENT.PKF` (45 MB of Spanish commentary).
* **The engine RE substrate**: collision-geometry builder (`Pm98CollBuilder`), match-tick
  driver (`Pm98Driver`), the full per-player DECIDE/ADVANCE, relationship matrix, marker
  and role selection, ball advance, the trig LUTs, the event queue and dispatcher — all
  ported and oracle-locked. They are done; they are simply not the engine the app calls.
* **325 GDScript test scripts** under `app/tests/` (**232** `test_*`, 42 `diag_*`, 52+ `shot_*`).
  **The first full sweep ran to completion 2026-07-26**: 223 of 225 `test_*` green (11 of
  them print non-standard pass markers — "ALL GREEN", per-check "PASS", "N checks, 0
  FAIL"), the 2 failures both accounted for (`test_decideset` = the +0x43c sentinel gap,
  fixed the same day by `f5ab46c`, green on HEAD; `test_pyramid` = FLAKY, an RNG season
  meeting the sparse-English-squads gap — S3's non-reproducibility makes it
  non-deterministic). `shot_*` all ran; ~~the two `*_tapthrough` harnesses fail their
  boot-raises-TITLE check when a prior career save exists in `user://`~~ — **FIXED
  2026-07-27**: both harnesses now `Career.delete_save()` before boot (tests own their
  state) and the squad tap-through drives the real entry chain (TEAMS IN CHAMPIONSHIPS
  → shield card → START OF SEASON) instead of racing it — 10/10 + 23/23 green. The 3
  rotten `diag_*` are runtime-rot only (all 42 parse clean, re-verified 2026-07-27) —
  probes, not tests, left as probes. **CI test gate ADDED 2026-07-27**:
  `build-android.yml` now runs a curated 15-test headless gate (<3 min, deterministic,
  `test_pyramid` excluded until S3) before every APK; the 20+ `diff_*_parity.py`
  gates remain manual-only.
* **Render-diff discipline**: screen after screen is baked from the real captured frames and
  proven at 0 differing pixels by a `tools/re/diff_*_parity.py`. That is the standard every
  new screen has to clear.

## Where the truth lives

| question | file |
|---|---|
| is screen X faithful? | `docs/re/STATUS_INDEX.md` — the DERIVED answer: every RE doc against its gate, suite, scene, EXE addresses and `Evidence:` paths. Rebuild with `python3 tools/re/build_status_index.py`; it exits non-zero if any `Evidence:` path has rotted |
| ...and the doc's own sentence about it? | the `Status:` line at the top of `docs/re/<screen>_re.md`, where one exists (21 of 135). It is a convenience, NOT the delegation — see the note below |
| which frame witnesses screen X? | `docs/re/WALKTHROUGH_MANIFEST.md` — all 636 frames named + who cites them |
| what does the app do that the original does not (and vice versa)? | `docs/re/APP_VS_SPEC_AUDIT.md` |
| what is decoded already? | `docs/re/EXACT_PORT_PLAN.md` §"Already decoded — cite, don't redo" |
| where is the byte-exact engine? | `docs/re/PLAN_byte_exact_match_engine.md` + `docs/re/M5_S58_FRONTIER_1032.md` (supersedes s57) |
| what did the complete audit find? | `docs/re/AUDIT_COMPLETE_2026-07-26.md` + `docs/re/AUDIT_season_playthrough_2026-07-25.md` |
| which source file proves a claim? | `docs/re/SOURCE_INVENTORY.md`, `docs/re/SPEC_BINDING.md` |
