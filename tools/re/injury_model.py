"""Binary-exact PM98 injury model, transcribed from MANAGER.EXE.

Source functions (extracted/Premier Manager 98/MANAGER.EXE):
  0x5850b0  roll_A  rand(100) -> type   (WEEKLY illness+injury; incl virus/cold)
  0x585210  roll_B  rand(100) -> type   (MATCH injury; NO virus/cold)
  0x584e70  setter  stores type@+2, rolls 4 weighted coins, jump-table @0x585048
            -> per-type DURATION in weeks (bytes +0/+1 = remaining/total)
  0x584b80  apply(player,kind): kind0=recover, kind!=0 -> roll_A, news tag 8
  0x584c00  apply_match(player):            roll_B, news tag 7
  0x58df90  rng(n) -> uniform 0..n-1

Injury-name table @0x6622e8 (18 entries) — see Availability.INJURY_TYPES.
This module is the SPEC: the exact CDFs and duration formulas, no invention.
"""

from __future__ import annotations

# ---- type distributions: (threshold_exclusive, type_index) cumulative on rand(100)
# roll_A @0x5850b0 — the exact cmp ladder (jae falls through to next test).
ROLL_A = [
    (0x13, 0),
    (0x14, 1),
    (0x19, 2),
    (0x23, 3),
    (0x2D, 4),
    (0x35, 5),
    (0x3D, 6),
    (0x45, 7),
    (0x4A, 0),
    (0x4B, 9),
    (0x50, 10),
    (0x55, 11),
    (0x57, 12),
    (0x5C, 13),
    (0x61, 14),
    (0x62, 15),
    # tail: cmp 0x63 -> <99: type 16, ==99: type 17  (sbb/add 0x11)
]
# roll_B @0x585210 — same ladder minus virus(0)/cold(1); [69,74)->type 8 not 0.
ROLL_B = [
    (0x19, 2),
    (0x23, 3),
    (0x2D, 4),
    (0x35, 5),
    (0x3D, 6),
    (0x45, 7),
    (0x4A, 8),
    (0x4B, 9),
    (0x50, 10),
    (0x55, 11),
    (0x57, 12),
    (0x5C, 13),
    (0x61, 14),
    (0x62, 15),
]


def roll_type(r: int, ladder: list[tuple[int, int]]) -> int:
    """r in 0..99 -> injury type index, exact binary cmp order."""
    for thresh, ty in ladder:
        if r < thresh:
            return ty
    # tail (0x585335 / 0x5851f7): cmp 0x63; sbb eax,eax; add eax,0x11
    return 16 if r < 0x63 else 17


def type_pmf(ladder: list[tuple[int, int]]) -> dict[int, float]:
    counts: dict[int, int] = {}
    for r in range(100):
        t = roll_type(r, ladder)
        counts[t] = counts.get(t, 0) + 1
    return {t: c / 100 for t, c in sorted(counts.items())}


# ---- duration jump table @0x585048 : type -> handler formula ----------------
# coins (each 0/1):  A=rand<75  B=rand<50  C=rand<25  D=rand<12
# handlers write weeks = f(A,B,C,D) into byte+0 (remaining) and byte+1 (total).
def _dur(handler: int, A: int, B: int, C: int, D: int) -> int:
    if handler == 0x584EDD:  # type 1
        return B + 1
    if handler == 0x584EF4:  # type 3
        return 1
    if handler == 0x584F07:  # type 5
        return B + 3
    if handler == 0x584F1E:  # type 6
        return (D + C + B + 5) & 0xFF
    if handler == 0x584F39:  # types 0,2,8
        return B + 1
    if handler == 0x584F50:  # type 9
        return 2
    if handler == 0x584F63:  # types 4,7,10
        return B + 2
    if handler == 0x584F7A:  # type 11
        return (C + B + 3) & 0xFF
    if handler == 0x584F94:  # type 12
        return ((C + B + 9) * 2) & 0xFF
    if handler == 0x584FB0:  # type 13
        return (C + B + 6) & 0xFF
    if handler == 0x584FCA:  # type 14
        return ((C + B) * 2 + D + 5) & 0xFF
    if handler == 0x584FE8:  # type 15
        return ((C + B) * 2 + D + 0x19) & 0xFF
    if handler == 0x585006:  # type 16
        return ((D + C + A + B + 0xA) * 2) & 0xFF
    if handler == 0x585029:  # type 17
        return ((C + B + 0x14) * 2 + D) & 0xFF
    raise KeyError(hex(handler))


JUMP = {
    0: 0x584F39,
    1: 0x584EDD,
    2: 0x584F39,
    3: 0x584EF4,
    4: 0x584F63,
    5: 0x584F07,
    6: 0x584F1E,
    7: 0x584F63,
    8: 0x584F39,
    9: 0x584F50,
    10: 0x584F63,
    11: 0x584F7A,
    12: 0x584F94,
    13: 0x584FB0,
    14: 0x584FCA,
    15: 0x584FE8,
    16: 0x585006,
    17: 0x585029,
}


def duration_stats(ty: int) -> tuple[int, int, float]:
    """(min, max, mean) weeks for an injury type over the 16 coin outcomes."""
    h = JUMP[ty]
    vals = [_dur(h, A, B, C, D) for A in (0, 1) for B in (0, 1) for C in (0, 1) for D in (0, 1)]
    # weight by coin probabilities
    pa = {0: 0.25, 1: 0.75}
    pb = {0: 0.50, 1: 0.50}
    pc = {0: 0.75, 1: 0.25}
    pd = {0: 0.88, 1: 0.12}
    mean = 0.0
    for A in (0, 1):
        for B in (0, 1):
            for C in (0, 1):
                for D in (0, 1):
                    mean += _dur(h, A, B, C, D) * pa[A] * pb[B] * pc[C] * pd[D]
    return min(vals), max(vals), mean


NAMES = [
    "virus",
    "cold",
    "pulled muscle",
    "dead leg",
    "pulled hamstring",
    "sprained ankle",
    "dislocated wrist",
    "dislocated finger",
    "sprained wrist",
    "groin strain",
    "broken nose",
    "broken toe",
    "broken cheekbone",
    "dislocated shoulder",
    "fractured rib",
    "shin splints injury",
    "slipped disc",
    "broken leg",
]

if __name__ == "__main__":
    for name, ladder in [
        ("ROLL_A weekly (illness+injury)", ROLL_A),
        ("ROLL_B match (injury only)", ROLL_B),
    ]:
        pmf = type_pmf(ladder)
        print(f"\n=== {name} — P(type)% then duration weeks(min..max mean) ===")
        tot = 0.0
        for t in range(18):
            p = pmf.get(t, 0.0)
            tot += p
            lo, hi, mean = duration_stats(t)
            print(
                f"  {t:2d} {NAMES[t]:20s} P={p * 100:5.1f}%  dur {lo:2d}..{hi:2d} mean {mean:5.2f}"
            )
        print(f"  sum P = {tot * 100:.1f}%")
