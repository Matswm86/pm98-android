# CUP DRAW round labels — five frames, one career, 2026-08-01 (s85)

Banked off this session's `season_youth_b9_sign` wine drive (isolated `Xvfb :7`, a Bolton W
TOTAL-level career). They exist because s84 counted the RE corpus and found **four** distinct
round labels across three competitions — Coca-Cola `ROUND 3`, F.A. Cup `ROUND 3` / `ROUND 4`,
U.E.F.A. `1/16 FINAL` — and no knockout-stage draw at all, which is why
`CupDrawScreen`'s per-round axis was unanswerable.

| frame | competition | round plate |
|---|---|---|
| `keep_0019_cup_draw.png` | Coca-Cola Cup | `ROUND 2` |
| `keep_0049_cup_draw.png` | Coca-Cola Cup | `ROUND 3` |
| `keep_0076_cup_draw.png` | Coca-Cola Cup | `ROUND 4` |
| `keep_0111_cup_draw.png` | Coca-Cola Cup | **`QTR. FINALS`** |
| `keep_0121_cup_draw.png` | F.A. Cup | `ROUND 3` |

Three of those labels are NEW to the corpus, and one of them is a KNOCKOUT-stage draw. More
usefully, the first four are **four rounds of the SAME competition from the SAME career**,
which is precisely the comparison the corpus could not make before: any per-round variation
in the chrome has to show up between them.

## ANALYSED 2026-08-01 (s86) — and the axis is the LEG PLATES

`tools/re/probe_cupdraw_per_round.py` does what the note below asked for. The animated
region is MEASURED rather than guessed: the union of pixels that differ across the three
reference-run frames of ONE Coca-Cola round (`p0125` / `p0131` / `p0133`) is 34,708 px, and
the picture box goes in whole because a union taken from another career cannot cover this
career's ball positions. With that, the round plate and the MATCHES panel masked, all six
pairs of the four Coca-Cola frames read:

| pair | LEG plates | button strip | ELSEWHERE |
|---|---|---|---|
| ROUND 2 vs ROUND 3 / ROUND 4 / QTR. FINALS | **397 px** | ~35 | **0** |
| ROUND 3 vs ROUND 4 / QTR. FINALS, ROUND 4 vs QTR. FINALS | **0** | ~28 | **0** |

So the cup draw has **exactly one per-round axis and it is the bottom-left leg plates**:
ROUND 2 reads **1ST LEG / 2ND LEG**, and ROUND 3, ROUND 4 and QTR. FINALS all read
MATCH / REPLAY. (The button-strip column is the mouse pointer the drive left behind — named
rather than masked, because masking it would hide a real difference in the same pixels.)

That is not decoration: it says how the tie is PLAYED, and the port had the Coca-Cola Cup on
a single competition-wide `legs: 1`, so it resolved a two-legged second round on one result.
`Career.LEAGUE_CUP_OPTS.round_legs_by_round` now carries `{2: 2}` — the witnessed round and
no other. ROUND 1 is unwitnessed and deliberately unpinned. Gate:
`app/tests/test_cup_round_legs.gd`.

## A SECOND CAREER, same answer

| file | career | competition | round | plates |
|---|---|---|---|---|
| `manutd_s2_cocacola_round2.png` | Man Utd, season 2 | Coca-Cola Cup | `ROUND 2` | **1ST LEG / 2ND LEG** |
| `manutd_s2_facup_round3.png` | Man Utd, season 2 | F.A. Cup | `ROUND 3` | MATCH / REPLAY |

A different club, a different season, a different draw — and Coca-Cola ROUND 2 is two-legged
again. The finding is no longer one career's.

A SEMIFINAL and a FINAL draw are **still missing**. Two drives have now tried for them and
neither reached one: a Man Utd career driven from February 1998 was knocked out of both cups
before the tail of the ladder and its manager was sacked early in season 2. The draw only
appears for a round the manager's own club is still in, so this is a matter of surviving to
April, not of driving longer.
