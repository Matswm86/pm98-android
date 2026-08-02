# The realised palette — MANAGER.EXE draws in MANAGER.PAL, not the shared VGA table

Status: **MEASURED and partly acted on (2026-08-02, s90).** Three banks are fixed and
verified at 0 px; `export_art.render`'s general rule is now known to be wrong and the
remaining sweep is named below rather than done.

`Evidence:` `tools/re/export_flags.py` (`flag_palette`), `tools/re/export_faces.py`,
`tools/re/build_match_header_from_frames.py`, `tools/re/pkf_image.py` (`vga_palette`,
`riff_palette`), `screenshots/original-walkthrough-2026-07-02/`.

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

## 4. What is NOT done — the sweep, named

`export_art.render` still selects `vga_palette()` for every `DM` sprite and every
`force_vga=True` caller:

```
    pal = vga_palette() if (is_dm or force_vga) else riff_palette(pal_name)
```

Given §2 that rule is wrong for anything MANAGER.EXE draws, but flipping it blind would be
exactly the guess this project does not make: each bank needs its own witness, because a
bank that uses no affected index is unchanged either way and a bank drawn by another
executable has a different answer again. The banks to walk, in the order their witnesses are
easiest to find, are the `force_vga` callers — `export_competitions`, `export_faces`'s
`_generic` (checked: no affected index, unchanged either way), `preview_menu` — plus every
`DM` decode that reaches `app/art/`.

Two cases are already settled and must not be swept up:

* **`app/art/faces/dbcard/`** is Dbasewin's own rendering under its own palette and asserts
  0 px against two walked frames of its own. Two applications, two realised palettes.
* **`_generic.png`** uses no affected index; `force_vga` there is a no-op, not a bug.
