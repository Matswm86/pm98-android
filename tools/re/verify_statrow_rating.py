"""Falsify (or not) the STATISTICS row-widget RATING formula against the live frames.

The row widget's draw method `FUN_004afce0` does NOT read a stored rating. It
recomputes one from the 0x48-byte stat record every paint (`@0x4b03f6..0x4b04cb`):

    ratio(n, d) = 0 if n + d == 0 else (100 * n) // (n + d)
    A = ratio(rec+0x08, rec+0x04)      # note: numerator is the SECOND field
    B = ratio(rec+0x14, rec+0x18)      # SHOTS
    C = ratio(rec+0x1c, rec+0x20)      # PASSES
    D = ratio(rec+0x24, rec+0x28)      # TAC.
    M = (A + B + C + D) >> 2
    RATING = 4 + (6 * (M + 10 * min(rec+0x10, 10))) // 100

Every input except `rec+0x08` (the per-player involvement counter that
`FUN_00450510` folds in at participant `+0xf4`) is legible straight off the
frame, because the x/y cells print `n` and `n + d`. So each observed row pins an
INTERVAL for its own `rec+0x08`. The formula survives only if

  * every row's interval is non-empty,
  * each player's full-time interval intersects [half-time value, +inf) --
    `+0xf4` only ever accumulates, and
  * the per-sheet involvement totals stay under the accumulator's budget
    (`FUN_00450510` distributes exactly `dur` counts over all 22 participants,
    so one team's share of a 45-minute half is at most 45, and 90 after two).

Data below is read off `screenshots/wine-captures-2026-07-24-statistics-live/`
02 (Man Utd half-time) and 06 (Man Utd full-time). Nothing is inferred.

Usage: python3 tools/re/verify_statrow_rating.py
"""

from __future__ import annotations

# (name, MIN, rating, shots (n, n+d), passes, tackles, goals)
# `None` for an x/y cell means the frame printed "-/-" (n + d == 0).
HALFTIME = [
    ("Schmeichel", 45, 4, None, (2, 5), None, 0),
    ("G.Neville", 45, 5, (1, 1), (2, 6), (0, 1), 0),
    ("Irwin", 45, 6, (1, 1), (1, 2), (1, 5), 0),
    ("Berg", 45, 5, None, None, (2, 2), 0),
    ("Pallister", 45, 4, None, (1, 2), (0, 3), 0),
    ("Butt", 45, 5, (1, 2), (0, 6), (1, 3), 0),
    ("Beckham", 45, 5, (1, 1), None, (0, 4), 0),
    ("Sheringham", 45, 4, None, (0, 1), (1, 3), 0),
    ("Cole", 45, 4, None, (1, 2), (0, 1), 0),
    ("Giggs", 45, 6, (1, 1), (4, 7), (0, 2), 0),
    ("Solskjaer", 45, 6, (2, 3), (1, 4), (2, 6), 1),
]
HALFTIME_TOTAL = ("TEAM TOTAL", 45, 7, (7, 9), (12, 35), (7, 30), 1)

FULLTIME = [
    ("Schmeichel", 90, 4, None, (2, 6), None, 0),
    ("G.Neville", 90, 6, (1, 1), (5, 11), (2, 6), 0),
    ("Irwin", 90, 6, (1, 1), (1, 4), (1, 9), 0),
    ("Berg", 90, 7, None, (2, 2), (3, 3), 0),
    ("Pallister", 90, 4, None, (1, 5), (0, 5), 0),
    ("Butt", 90, 5, (1, 3), (5, 11), (3, 9), 0),
    ("Beckham", 90, 6, (2, 2), (1, 2), (3, 10), 0),
    ("Sheringham", 90, 7, (1, 1), (3, 5), (3, 7), 0),
    ("Cole", 90, 7, (1, 1), (5, 6), (2, 3), 0),
    ("Giggs", 90, 7, (1, 1), (7, 12), (3, 7), 0),
    ("Solskjaer", 45, 6, (2, 3), (1, 4), (2, 6), 1),
]
FULLTIME_TOTAL = ("TEAM TOTAL", 90, 7, (10, 13), (33, 68), (22, 65), 1)

# The accumulator hands out exactly `dur` involvement counts across BOTH sides'
# 22 participants, so one team can never exceed the elapsed minutes.
BUDGET_HT = 45
BUDGET_FT = 90


def ratio(n: int, d: int) -> int:
    """`FUN_004afce0`'s percentage helper: 100*n/(n+d), 0 when the pair is empty."""
    total = n + d
    return 0 if total == 0 else (100 * n) // total


def pair(cell: tuple[int, int] | None) -> tuple[int, int]:
    """Frame cell "x/y" -> the two stored record fields (n, d) with d = y - x."""
    if cell is None:
        return 0, 0
    n, y = cell
    return n, y - n


def rating(minutes: int, involvement: int, shots, passes, tackles, goals: int) -> int:
    a = ratio(involvement, minutes)  # numerator is rec+0x08, partner is rec+0x04
    b = ratio(*pair(shots))
    c = ratio(*pair(passes))
    d = ratio(*pair(tackles))
    mean = (a + b + c + d) >> 2
    return 4 + (6 * (mean + 10 * min(goals, 10))) // 100


def solve(row, limit: int = 400) -> list[int]:
    """Every involvement count in [0, limit] that reproduces the printed rating."""
    name, minutes, observed, shots, passes, tackles, goals = row
    return [x for x in range(limit + 1) if rating(minutes, x, shots, passes, tackles, goals) == observed]


def report(label: str, rows, total_row, budget: int) -> tuple[bool, dict[str, tuple[int, int]]]:
    print(f"\n=== {label} ===")
    ok = True
    windows: dict[str, tuple[int, int]] = {}
    lo_sum = hi_sum = 0
    for row in rows:
        sols = solve(row)
        name = row[0]
        if not sols:
            print(f"  {name:<12} rating {row[2]}  INFEASIBLE -> formula refuted")
            ok = False
            continue
        windows[name] = (sols[0], sols[-1])
        lo_sum += sols[0]
        hi_sum += sols[-1]
        print(f"  {name:<12} rating {row[2]}  rec+0x08 in [{sols[0]}, {sols[-1]}]")
    tot = solve(total_row)
    if not tot:
        print("  TEAM TOTAL   INFEASIBLE -> formula refuted")
        ok = False
    else:
        print(f"  {'TEAM TOTAL':<12} rating {total_row[2]}  sum(rec+0x08) in [{tot[0]}, {tot[-1]}]")
        # The total row's rec+0x08 IS the column sum, so it must overlap the
        # per-row windows' reachable sum, and stay inside the accumulator budget.
        overlap = (max(lo_sum, tot[0]), min(hi_sum, tot[-1], budget))
        if overlap[0] > overlap[1]:
            print(f"  !! per-row sum [{lo_sum}, {hi_sum}] vs total [{tot[0]}, {tot[-1]}]"
                  f" vs budget {budget}: NO OVERLAP -> refuted")
            ok = False
        else:
            print(f"  consistency: column sum lands in [{overlap[0]}, {overlap[1]}]"
                  f"  (per-row [{lo_sum}, {hi_sum}], budget {budget})")
    return ok, windows


def main() -> int:
    ok_ht, w_ht = report("Man Utd HALF-TIME (frame 02)", HALFTIME, HALFTIME_TOTAL, BUDGET_HT)
    ok_ft, w_ft = report("Man Utd FULL-TIME (frame 06)", FULLTIME, FULLTIME_TOTAL, BUDGET_FT)

    print("\n=== monotonicity (rec+0x08 only accumulates: FT >= HT) ===")
    ok_mono = True
    for name, (lo_h, hi_h) in w_ht.items():
        lo_f, hi_f = w_ft[name]
        if hi_f < lo_h:
            print(f"  {name:<12} FT max {hi_f} < HT min {lo_h}  -> refuted")
            ok_mono = False
        else:
            print(f"  {name:<12} HT [{lo_h}, {hi_h}]  FT [{max(lo_f, lo_h)}, {hi_f}]  ok")

    verdict = ok_ht and ok_ft and ok_mono
    print(f"\nVERDICT: {'SURVIVES' if verdict else 'REFUTED'}"
          f" — 24 rating cells across 2 live frames")
    return 0 if verdict else 1


if __name__ == "__main__":
    raise SystemExit(main())
