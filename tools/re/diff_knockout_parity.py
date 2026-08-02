#!/usr/bin/env python3
"""Pixel-parity gate: the RESULTS -> cup KNOCKOUT views vs their live-witnessed frames.

Compares shot_knockout_parity.gd's captures against
  tools/re/refs/knockout-2026-07-26/06_euroleague_round1_played.png     (list, European)
  tools/re/refs/knockout-2026-07-26/03_facup_r3_drawn_UNPLAYED_1997-12-20.png (list, dom)
  tools/re/refs/knockout-2026-07-26/03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png
                                                                        (bracket, European)
  tools/re/refs/knockout-2026-07-26/08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png
                                                                        (bracket, domestic)

Buckets are reported separately because each has a stated, documented cause:

* the BARRA manager kit at (106,6) -- the pre-existing hole shared with ResultsScreen and
  EuroGroupScreen: only Man Utd's 35x44 header patch has been cut from the original, so a
  Bolton W barra differs by the whole blit;
* the SCROLLBAR column x478..493 (list cases) -- its arrows and trough are the original's
  own, but the thumb's length and tracking are an INFERENCE (the two frames in hand differ
  only in the thumb's length, which fixes neither the rounding nor the minimum), recorded
  as such in docs/re/knockout_views_re.md;
* the eight KIT columns (bracket cases) -- the 48x64 blit is the game's own MINIESC
  sprite, verified unique-best at (26/423, T+8) on all 16 witnessed cells, but the
  original draws an outline/bevel ring in a second, UN-REVERSED pass (~170-420 px per
  cell), so the two 60x68 kit columns per panel are declared, exactly as the RE doc says;
* the competition RAIL (euro bracket case only) -- WHICH rail chips are lit is career
  state this port does not model (the March career's cwc/uefa/supercup chips differ from
  the August rail the port ships); the domestic case's rail matches its witness 0 px and
  is NOT bucketed.

Everything else must be zero.

Usage: diff_knockout_parity.py <shot_dir>
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools/re/refs/knockout-2026-07-26"

# 649 px on every case until 2026-08-01: the port drew Man Utd's whole captured panel for
# club 40 and a bare NANOESC kit with no furniture for anybody else. The panel is FURNITURE
# + the club's own kit, and the furniture was recovered from two careers that occlude
# different pixels of it (tools/re/build_manager_panel_from_frames.py, gate
# app/tests/test_manager_panel.gd). **14 px** now.
#
# CORRECTED 2026-08-02 (s90): those 14 px are NOT "the un-reversed 1-px kit rim". The 0x20
# edge pass is reversed and shipped since s90, and applying it here makes this cell WORSE,
# not better (14 -> 72 for the edge alone, 128..181 with any of the attested spreads) — so
# this is not a 0x20 site. Split against the NANOESC sprite's own alpha, **all 14 are OFF
# the sprite**: they are in the baked PANEL FURNITURE, which is exactly the two-career
# occlusion gap the line above records. A third witnessed career that clears those pixels
# closes this; nothing about the kit blit does.
BARRA_KIT = ("barra kit", 106, 6, 35, 44)
SCROLL_COL = ("scrollbar", 478, 125, 16, 286)
RAIL = ("rail", 500, 110, 140, 321)
KIT_COLS = [
    (f"kit {side} T{top}", x, top + 2, 60, 68)
    for top in (113, 193, 273, 353)
    for side, x in (("L", 22), ("R", 416))
]
# The CARDS layout's 17x20 ridi kit icons (x13 / x271 at the four bar tops per card):
# the sprite is the game's own ridi bank, matched unique-best at (13, bar_top), but the
# original draws the same un-reversed outline/bevel pass over it (~30 px per icon) --
# the identical residual the bracket's MINIESC columns and the euro group screen carry.
CARD_ICONS = [
    (f"icon {side} y{top}", x, top, 17, 20)
    for top in (209, 231, 301, 323)
    for side, x in (("L", 13), ("R", 271))
]
# The SINGLE-LEG card has only the first block, so only its two icon rows exist.
CARD_ICONS_TOP = [
    (f"icon {side} y{top}", x, top, 17, 20)
    for top in (209, 231)
    for side, x in (("L", 13), ("R", 271))
]
# The FINAL's two 48x60 kit wells keep CompResultScreen's documented approximation: the
# original's hi-res panel kit bank is un-extracted, so the app's own art is aspect-fitted
# and the wells are declared.
FINAL_KITS = [("final kit L", 146, 158, 48, 60), ("final kit R", 306, 158, 48, 60)]
# The DOMESTIC final's two 17x20 ridi icons carry the same shadowed-blit residual as every
# other ridi cell in this file (the pass is ported for MAN-TO-MAN but these screens are
# still on their baked rings -- docs/re/shadow_blit_re.md §7).
DOM_FINAL_ICONS = [
    (f"icon y{top}", 145, top, 17, 20) for top in (178, 200)
]
# The laurel wreath's kit keeps CompResultScreen's documented approximation (the original's
# hi-res panel kit bank is un-extracted), exactly as the euro final's two wells do.
DOM_FINAL_LAUREL = [("laurel kit", 398, 338, 53, 57)]
# Two faces this card's PLAYED witness settles the PEN of but not the GLYPHS, so each is a
# named, bounded bucket rather than a silent difference:
#   * the score digits -- the closest extracted bank is proman12 (the club rows' own), which
#     costs 193 px over the two boxes against 244 for the GDI approximation, so proman12 is
#     what ships; the residual is the last few px of a face nobody has cut yet;
#   * the WINNER band's champion -- 13 ink rows where proman12 gives 9, and no extracted
#     bank matches (proman12 608 px, the GDI approximation 530), so CompResultScreen's
#     declared approximation carries over. Both are recorded in knockout_views_re.md.
DOM_FINAL_SCORES = [(f"score y{top}", 321, top, 36, 20) for top in (178, 200)]
DOM_FINAL_WINNER = [("winner name", 55, 382, 317, 17)]
# The FINALIST plates' 24x32 nano kits, at plate_x0 + 2 / y377.
FINALIST_KITS = [("finalist kit 1", 22, 377, 24, 32), ("finalist kit 2", 283, 377, 24, 32)]

# The KIT LIST's 28x22 kit wells: eight rows at pitch 30 from y154, one well each side --
# x15 in both column sets, x289 (European) / x344 (domestic) on the right.
KL_WELLS_EURO = [
    (f"kit {side} y{154 + 30 * i}", x, 154 + 30 * i, 28, 22)
    for i in range(8)
    for side, x in (("L", 15), ("R", 289))
]
KL_WELLS_DOM = [
    (f"kit {side} y{154 + 30 * i}", x, 154 + 30 * i, 28, 22)
    for i in range(8)
    for side, x in (("L", 15), ("R", 344))
]

# The phase paginator's plate is TWO ROWS TALLER on the paged-back frame than on the live
# one: white rows 77..101 at x190 against 78..100 on 03_euroleague_qtrfinals_LEG1, at the
# identical width (139..322) and with the identical label. One witness of each state is not
# a rule, so the band is declared for the decided case rather than guessed at; the port
# renders the live-phase plate, which is 0 px on every other case here.
PAGINATOR = [("paginator plate", 139, 76, 184, 27)]
# The same phenomenon on the CARDS family, witnessed 2026-07-28 on the paged-back
# Coca-Cola semifinals: the label plate's white surround reaches x310..336 on rows 85 and
# 109 and one column further left at x336 on the rows between, where the LIVE-phase frame
# the band was cut from has the plate's black border there. One witness of each state is
# not a rule, so the plate's outer frame is declared for the paged-back case exactly as
# the bracket's is; the port renders the live-phase plate, 0 px on every live case here.
PAGINATOR_CARDS = [("paginator plate", 310, 85, 27, 25)]

CASES = [
    ("knockout_euro_round1", "06_euroleague_round1_played.png", [BARRA_KIT, SCROLL_COL]),
    ("knockout_facup_round3", "03_facup_r3_drawn_UNPLAYED_1997-12-20.png", [BARRA_KIT, SCROLL_COL]),
    (
        "knockout_euro_qtr",
        "03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png",
        [BARRA_KIT, RAIL, *KIT_COLS],
    ),
    # The DECIDED bracket -- both legs played, AGGR. filled, the winner inked through.
    # Witness banked 2026-07-28 (screenshots/wine-captures-2026-07-28-knockout-decided);
    # it is the cell the 07-26 bracket build had to declare as an inference.
    (
        "knockout_euro_qtr_done",
        "09_euroleague_qtrfinals_DECIDED_1998-04-11.png",
        [BARRA_KIT, RAIL, *KIT_COLS, *PAGINATOR],
    ),
    (
        "knockout_facup_qtr",
        "08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png",
        [BARRA_KIT, *KIT_COLS],
    ),
    # The euro cases bucket the rail (career-state chip lit-states, as the bracket case
    # documents); the cocacola semis rail matches the baked rail_cocacola.png 0 px and
    # is enforced.
    (
        "knockout_euro_semis",
        "04_euroleague_semifinals_LEG1_PLAYED_1998-04-04.png",
        [BARRA_KIT, RAIL, *CARD_ICONS],
    ),
    (
        "knockout_cocacola_semis",
        "06_cocacola_semifinals_drawn_1998-01-10.png",
        [BARRA_KIT, *CARD_ICONS],
    ),
    # The DECIDED Coca-Cola semifinals (tools/re/refs/knockout-2026-07-28): both legs
    # played, both FINALIST plates FILLED. The two 24x32 nano kits in those plates carry
    # the same un-reversed outline pass as every other kit blit here.
    (
        "knockout_cocacola_semis_done",
        "../knockout-2026-07-28/13_cocacola_semifinals_TWOLEGS_1998-04-11.png",
        [BARRA_KIT, RAIL, *CARD_ICONS, *FINALIST_KITS, *PAGINATOR_CARDS],
    ),
    # The SINGLE-LEG (F.A. Cup) semifinals, built 2026-07-28 from
    # tools/re/refs/knockout-2026-07-28/12: one RESULT block per card, the neutral ground
    # as its first row, the panel ending after it, and both FINALIST plates filled.
    (
        "knockout_facup_semis",
        "../knockout-2026-07-28/12_facup_semifinals_FINALISTS_1998-04-11.png",
        [BARRA_KIT, RAIL, *CARD_ICONS_TOP, *FINALIST_KITS],
    ),
    # The KIT LIST (5-8 ties), built 2026-07-28: three witnesses, two competitions, two
    # careers, both column sets. Its 28x22 kit wells carry the same un-reversed on-sprite
    # bevel every other kit blit in this file does, so the two wells per row are declared
    # exactly as the bracket's columns are.
    (
        "knockout_uefa_kitlist",
        "01_uefa_1_8finals_leg1_played_1997-12-07.png",
        [BARRA_KIT, *KL_WELLS_EURO],
    ),
    (
        "knockout_cwc_kitlist",
        "09_comp_cwc.png",
        [BARRA_KIT, *KL_WELLS_EURO],
    ),
    (
        "knockout_cocacola_kitlist",
        "13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png",
        [BARRA_KIT, *KL_WELLS_DOM],
    ),
    (
        "knockout_euro_final",
        "05_euroleague_final_UNDECIDED_1998-04-25.png",
        [BARRA_KIT, RAIL, *FINAL_KITS],
    ),
    # The DOMESTIC final's own body, built 2026-07-28 from
    # tools/re/refs/knockout-2026-07-28/14: MATCH RESULT over STADIUM, two club bars with a
    # ridi icon each, an empty REPLAY RESULT panel, and the shared filled WINNER band.
    (
        "knockout_cocacola_final",
        "../knockout-2026-07-28/14_cocacola_final_WINNER_1998-04-11.png",
        [BARRA_KIT, RAIL, *DOM_FINAL_ICONS, *DOM_FINAL_LAUREL,
         *DOM_FINAL_SCORES, *DOM_FINAL_WINNER],
    ),
]


def _bucket(buckets: list, x: int, y: int) -> str | None:
    for tag, rx, ry, rw, rh in buckets:
        if rx <= x < rx + rw and ry <= y < ry + rh:
            return tag
    return None


def main() -> int:
    shot_dir = Path(sys.argv[1])
    fail = False
    for name, ref, buckets in CASES:
        shot = Image.open(shot_dir / f"{name}.png").convert("RGB")
        wit = Image.open(REFS / ref).convert("RGB").crop((0, 0, 640, 480))
        if shot.size != (640, 480):
            print(f"{name}: unexpected shot size {shot.size}")
            fail = True
            continue
        n = 0
        binned: dict[str, int] = {}
        first = None
        diff = Image.new("RGB", (640, 480), (0, 0, 0))
        for y in range(480):
            for x in range(640):
                a = shot.getpixel((x, y))
                b = wit.getpixel((x, y))
                if a == b:
                    continue
                tag = _bucket(buckets, x, y)
                if tag is not None:
                    binned[tag] = binned.get(tag, 0) + 1
                    continue
                n += 1
                diff.putpixel((x, y), (255, 0, 0))
                if first is None:
                    first = (x, y, a, b)
        tag = "OK " if n == 0 else "BAD"
        kits = sum(v for k, v in binned.items() if k.startswith("kit"))
        rest = {k: v for k, v in binned.items() if not k.startswith("kit")}
        extra = f", kits {kits}" if kits else ""
        print(f"{tag} {name}: {n} outside ({rest}{extra})")
        if first is not None:
            print(f"      first at {first[0]},{first[1]} got {first[2]} want {first[3]}")
            diff.save(shot_dir / f"diff_{name}.png")
            fail = True
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
