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

**Not yet analysed, and deliberately not claimed.** A raw diff of the three later frames
against `ROUND 2`, with the round plate and the MATCHES panel masked out, leaves ~5,000 px in
a box spanning x27..525 y85..462 — but that box contains the SORTEO drum, which is ANIMATED,
so a raw diff cannot separate a per-round chrome difference from two captures landing on
different drum frames. Separating them is the next step: mask the drum rect (or film it, as
`autodrive`'s `film.sh` already does for the draw) and re-diff.

A SEMIFINAL and a FINAL draw are still missing.
