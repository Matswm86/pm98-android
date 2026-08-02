# The realised palette — MANAGER.EXE draws in MANAGER.PAL, not the shared VGA table

Status: **CLOSED (2026-08-02, s91).** Four banks were fixed against their own witnesses in
s90; the general rule in `export_art.render` is now fixed too, and the 83 PNGs it had
already mis-decoded are corrected. §4 carries the measurement that decided it and the exact
limits of what the render-diff shows.

`Evidence:` `tools/re/probe_realised_palette_witness.py`,
`tools/re/probe_realised_palette_scope.py`, `tools/re/fix_realised_palette.py`,
`tools/re/export_art.py` (`realised_palette`), `tools/re/export_flags.py` (`flag_palette`),
`tools/re/export_faces.py`, `tools/re/build_match_header_from_frames.py`,
`tools/re/pkf_image.py`, `screenshots/` (all 1,752 original captures).

## 1. The two tables, and the 21 entries where they part

| table | where | used by |
|---|---|---|
| the shared VGA table | `DAT.PKF +0x5CA`, 256 x RGBA in VGA-DAC order | `pkf_image.vga_palette()` — and, until s90, most sprite decodes |
| the realised palette | the RIFF `PAL ` file `MANAGER.PAL` inside `DAT.PKF`, plus the 20 Windows static system colours | `export_flags.flag_palette()`, `app/data/shadow_lut.bin`'s first 768 bytes |

**Twenty-one of the 256 entries differ**: 8, 27, 28, 29, 85-90, 111-116, 119-123. A sprite
decoded through the wrong one is right everywhere except where it uses one of those, which
is why the defect hides: it is invisible on most art and glaring on the art that happens to
use a green ramp or the 119-123 band.

## 2. The measurement that settles which is realised

Twenty-five walkthrough frames, sampled at random, reduced to their distinct colours:

| | frames |
|---|---|
| carry a colour NOT in the shared VGA table | **25 of 25** (10-21 such colours each) |
| carry a colour NOT in MANAGER.PAL + statics | **6 of 25** |

and those six are the screens MANAGER.EXE does not draw — the DATABASE (`Dbasewin.exe`,
which realises the embedded table of `RC_DBASE::LIGA_ESTRELLAS.BMP`) and the 3D match view.
For every frame MANAGER.EXE itself paints, **every pixel is a MANAGER.PAL entry and some are
not VGA entries at all.**

## 3. Three banks found wrong, three fixed, each against its own witness

| bank | symptom | after |
|---|---|---|
| MINIBAND flags (2026-07-26) | 99 px of "dither" over 24 EURO LEAGUE cells | 0 px |
| RIDIESC kits (s90) | Sporting Port.'s hoops `(66,104,44)` vs the frame's `(17,127,43)`; 91 of 476 kits use an affected index | 82 -> 31 on-sprite, the rest being the edge pass |
| MINIFOTO / BIGFOTO faces (s90) | `mini/8432.png` 138 wrong px of 1024 on the FICHA card | 0 px on three witnesses |

Each was found the same way and each was believed correct for the same reason: the
exporter's own check had compared the DIB's *embedded* palette against the shared VGA table
and stopped there, never asking about the third.

## 4. The sweep — DONE (2026-08-02, s91)

`export_art.render` selected `vga_palette()` for every `DM` sprite and every
`force_vga=True` caller:

```
    pal = vga_palette() if (is_dm or force_vga) else riff_palette(pal_name)   # WRONG
```

s90 named this and did not flip it, on the rule that each bank needs its own witness. That
rule is kept — what changed is that the witness is now available for **every index at
once**, which decides every bank in one measurement instead of forty.

### 4.1 The premise that makes a colour-level witness sufficient

`tools/re/probe_realised_palette_scope.py` and
`tools/re/probe_realised_palette_witness.py`. Both start from the same check, asserted at
runtime rather than assumed: **none of the 21 VGA colours appears anywhere in the realised
table.** So a pixel carrying one can only have come from that index decoded through the
wrong table — there is no second way to produce it, and no free parameter to tune.

### 4.2 The measurement

Every original capture the project holds — **1,752 frames across 37 directories**, every
screen, every competition, both executables:

| | pixels |
|---|---|
| a colour that is a VGA-table entry at one of the 21 | **0** |
| the realised colour at those same 21 | **12,919,661** |

Not 0 "in the sampled frames": 0 in all of them. Every VGA hit anywhere under
`screenshots/` is inside a `parity-run*/app/` directory — that is the PORT's own render of
this very defect, which is corroboration, not a counterexample. Per index the split is in
the tool's own output; the largest are 116 (0 vs 1,720,535), 85 (0 vs 1,648,145) and
111 (0 vs 1,143,004).

**The rule is now `realised_palette()`** for the `DM` / `force_vga` arm, in both the `exact`
and the PIL path, with `vga_palette()` kept for the callers that genuinely want the shared
table.

### 4.3 The art that rule had already produced

83 PNGs under `app/art/` carried a VGA-only colour, **43,022 px** in eleven banks — the
NIVEL level plates, the twelve stadium plates, thirteen hub menu icons, twelve competition
logos, the SORTEO drums and hands, DIRECTIVA, the EQUIPO WIN tactics chips, three DBASE
icons and four loose backgrounds. They are corrected in place by
`tools/re/fix_realised_palette.py`, a pure remap of the 21 colours.

That remap is equivalent to a re-decode, and that equivalence is **checked, not asserted**:
on the 7 files of `app/art/screens/cup/` that are plain exporter output, a forced re-export
through the fixed `render()` is byte-identical to the remap. It is done that way rather than
by re-running every exporter because the other 4 files in that same bank are hand-curated
and `--force` discards the curation.

### 4.4 What the render-diff does and does not show

Stated plainly, because it is the honest shape of the evidence. `diff_entry_parity.py` over
its eighteen binding pairs is **0 px before and 0 px after** (bar the two long-standing
exclusions, the LineEdit caret and the FICHA demo photo). The walkthrough's binding frames
do not happen to show the changed pixels — the level plates in their unselected state, the
ground plates, the hub icons — so they neither confirm nor refute the change, and no parity
gate regressed. Fifteen art-touching CI tests stay green.

The evidence for the change is therefore §4.2's, which is **colour-level rather than
sprite-level** — exactly the standard §5 below accepted for NANOESC, and for the same
reason: a frame witnessing the specific sprite does not exist, while a corpus-wide
falsification of the wrong table does.

Two cases are settled and were NOT swept up:

* **`app/art/faces/dbcard/`** is Dbasewin's own rendering under its own palette and asserts
  0 px against two walked frames of its own. Two applications, two realised palettes. It
  uses none of the 21 indices, so the sweep would not have touched it in any case.
* **`_generic.png`** uses no affected index; `force_vga` there is a no-op, not a bug.

## 5. A fourth bank — NANOESC, and a witness that decides it (2026-08-02, s90)

`map_crests.py` exports MINIESC and NANOESC three lines apart, and the 2026-07-27 fix landed
on MINIESC only: `flag_palette()` for the 48x64 kits, plain `riff_palette("MANAGER.PAL")`
for the 24x32 nano ones. Those two tables differ at exactly **one** index — **8**, the
Windows static "money green" — and **89 of the 476 NANOESC kits use it**, rendering
`(192,227,192)` where the running game shows `(192,220,192)`.

The docstring claimed the nano bank was "verified SAD-0.0 vs walkthrough frames 008/013
under MANAGER.PAL", which is true and does not decide the question: those frames' clubs use
no index-8 pixel. The frames themselves do decide it, on the colour rather than the sprite:

| frame | `(192,227,192)` MANAGER.PAL's own index 8 | `(192,220,192)` the Windows static |
|---|---|---|
| 008 (three captures) | **0 px** | 166 / 563 / 2,527 |
| 009 (three captures) | **0 px** | 166 / 563 / 2,527 |
| 013 (three captures) | **0 px** | 152 / 11 / 1 |

MANAGER.EXE never paints MANAGER.PAL's raw index 8 and paints the static thousands of times,
so the realised table is the one with the statics in it. Bank re-exported; 89 kits changed;
`test_manager_panel`, `test_knockout_layout`, `test_results_screen` and `test_cupdraw_screen`
all still pass.

Corroborated on the way, though it does not decide index 8 either: the port's SELECCION
screen — the panel that blits the NANOESC kits 1:1 — was diffed against a fresh live capture
of the original's own team-select screen taken this session, and comes out at **13 px over
the whole 640x480 frame** once the two arrow buttons' state is masked. Those 13 are a single
vertical line at x=390: the original's blinking text caret. Twenty kits, 0 px. What that
confirms is the bank's geometry and its other 235 entries; **none of the twenty Premier
clubs' nano kits uses index 8**, checked rather than assumed.

Recorded rather than glossed: there is still no NANOESC *sprite* witness of an affected club
— every banked barra frame is club 40 or 59, and no club in the SELECCION grid touches index
8 either — so this rides on the palette-level measurement above plus MINIESC's own
26-of-26-px index-8 finding, not on a frame of that kit.
