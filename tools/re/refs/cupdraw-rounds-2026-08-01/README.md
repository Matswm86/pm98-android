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

## A THIRD career, 2026-08-01 (s87) — and it breaks the "one per-round axis" reading

A Manchester Utd career started from scratch on this session's own drive
(`plans/season_cupdraw_late.json`, display `:6`, `PM98_NO_RAISE=1`) banked six more, and two
of them are things the corpus had never held:

| file | competition | round plate | leg plates |
|---|---|---|---|
| `manutd_s1_eurocup_groups_1_8_final.png` | European Cup | **`1/8 FINAL`** | **BOTH BLANK** |
| `manutd_s1_cocacola_round3.png` | Coca-Cola Cup | `ROUND 3` | MATCH / REPLAY |
| `manutd_s1_facup_round3.png` | F.A. Cup | `ROUND 3` | MATCH / REPLAY |
| `manutd_s1_facup_round4.png` | F.A. Cup | `ROUND 4` | MATCH / REPLAY |
| `manutd_s1_eurocup_qtr_finals.png` | European Cup | `QTR. FINALS` | **1ST LEG / 2ND LEG** |
| `manutd_s1_facup_round5.png` | F.A. Cup | **`ROUND 5`** | MATCH / REPLAY |

**The leg plates are a COMPETITION axis as well as a round one.** s86's reading — "ROUND 2 is
two-legged and ROUND 3 / ROUND 4 / QTR. FINALS are not" — was measured over four frames of
the Coca-Cola Cup ALONE, and it is right about that competition. It does not generalise: the
EUROPEAN CUP's `QTR. FINALS` reads **1ST LEG / 2ND LEG** while the Coca-Cola Cup's reads
MATCH / REPLAY. The port already models this correctly (`Career` builds every European
bracket with `legs: 2` and `Cup.draw_leg_plates` reads the tie), so this frame CONFIRMS the
port rather than correcting it — but the corpus note had to be widened or the next session
would have "fixed" the European Cup to one leg.

**And the group draw is a SCREEN FORM the port does not have.**
`manutd_s1_eurocup_groups_1_8_final.png` is the European Cup's group draw, and it is not the
MATCHES layout with different content — it is a different right-hand panel:

* the header plate reads **GROUPS** in BLACK on WHITE, where every other draw reads MATCHES
  in white on the green plate;
* under it are **six group boxes in a 2 x 3 grid**, each with its own green `GROUP <letter>`
  header and four rows;
* a filled row is `kit | club name | national flag` — the frame catches the draw mid-reveal
  with GROUP A holding Sporting Port. / Real Madrid C.F. / Anorthosis / W.Lodz and B..F
  still empty;
* the bottom-left tie-detail card is **entirely blank**, leg plates included;
* the round plate reads `1/8 FINAL`, which is the original's own header for the group phase
  (`Round 1`..`Round 6` run under it).

The port raises NO draw at all for the group stage — `Cup.draw_next_round` is a deliberate
no-op while the group phase is live. That is now a witnessed gap with a frame behind it.

### Season 2 of the same career — two more European labels, both two-legged

| file | competition | round plate | leg plates |
|---|---|---|---|
| `manutd_s2_eurocup_round2.png` | European Cup | **`ROUND 2`** | **1ST LEG / 2ND LEG** |
| `manutd_s2_uefa_1_32_finals.png` | U.E.F.A. Cup | **`1/32 FINALS`** | **1ST LEG / 2ND LEG** |

Two more new labels, and the European leg plates hold at both of them — so every witnessed
European round is two-legged (`ROUND 2`, `1/32 FINALS`, `QTR. FINALS`) while every witnessed
domestic round outside Coca-Cola `ROUND 2` is not. Note also that this season's European Cup
raised a `ROUND 2` draw rather than the group form: the group phase is not every season's
entry route, so `manutd_s1_eurocup_groups_1_8_final.png` is the group draw and not simply
"the European Cup's first draw".

Still missing after four drives: a **SEMIFINAL** and a **FINAL** draw.

## CORRECTED 2026-08-02 (s88) — three of these filenames were wrong, and the table with them

The s87 rows above were written from the drive's own guesses at what each frame was. Read
off the pixels instead (`tools/re/probe_cupdraw_labels.py`, which crops each plate's ink
mask and XORs it against the port's own BMFont render, so a name is a 0-px match or it is
reported unresolved), **three of the six s1 frames were filed under the wrong competition
and round**. They have been RENAMED to what they actually are:

| was called | actually is | now called |
|---|---|---|
| `manutd_s1_eurocup_qtr_finals.png` | F.A. Cup `ROUND 4` | `manutd_s1_facup_round4.png` |
| `manutd_s1_facup_round3.png` | European Cup `QTR. FINALS` | `manutd_s1_eurocup_qtr_finals.png` |
| `manutd_s1_facup_round4.png` | F.A. Cup `ROUND 3` | `manutd_s1_facup_round3.png` |

The FINDINGS above survive the correction — a European Cup `QTR. FINALS` frame reading
1ST LEG / 2ND LEG exists, an F.A. Cup `ROUND 4` frame reading MATCH / REPLAY exists, and
every witnessed European round is still two-legged. What was wrong was which file each row
pointed at, which is exactly the kind of error that makes the next session measure the wrong
pixels.

The full table, regenerated from the frames themselves (`python3
tools/re/probe_cupdraw_labels.py`):

| frame | competition | round plate | leg 1 | leg 2 |
|---|---|---|---|---|
| `keep_0019_cup_draw.png` | Coca-Cola Cup | `ROUND 2` | 1ST LEG | 2ND LEG |
| `keep_0049_cup_draw.png` | Coca-Cola Cup | `ROUND 3` | MATCH | REPLAY |
| `keep_0076_cup_draw.png` | Coca-Cola Cup | `ROUND 4` | MATCH | REPLAY |
| `keep_0111_cup_draw.png` | Coca-Cola Cup | `QTR. FINALS` | MATCH | REPLAY |
| `keep_0121_cup_draw.png` | F.A. Cup | `ROUND 3` | MATCH | REPLAY |
| `manutd_s1_cocacola_round3.png` | Coca-Cola Cup | `ROUND 3` | MATCH | REPLAY |
| `manutd_s1_eurocup_groups_1_8_final.png` | EUROPEAN CUP | `1/8 FINAL` | (blank) | (blank) |
| `manutd_s1_eurocup_qtr_finals.png` | EUROPEAN CUP | `QTR. FINALS` | 1ST LEG | 2ND LEG |
| `manutd_s1_facup_round3.png` | F.A. Cup | `ROUND 3` | MATCH | REPLAY |
| `manutd_s1_facup_round4.png` | F.A. Cup | `ROUND 4` | MATCH | REPLAY |
| `manutd_s1_facup_round5.png` | F.A. Cup | `ROUND 5` | MATCH | REPLAY |
| `manutd_s2_cocacola_round2.png` | Coca-Cola Cup | `ROUND 2` | 1ST LEG | 2ND LEG |
| `manutd_s2_eurocup_round2.png` | EUROPEAN CUP | `ROUND 2` | 1ST LEG | 2ND LEG |
| `manutd_s2_facup_round3.png` | F.A. Cup | `ROUND 3` | MATCH | REPLAY |
| `manutd_s2_uefa_1_32_finals.png` | UEFA CUP | `1/32 FINALS` | 1ST LEG | 2ND LEG |

### Two things the reading settled that no one had asked

* **The quarter-final plate keeps its full stop, and the port was dropping it.**
  `Cup.draw_round_plate` normalised `QTR. FINALS` to `QTR FINALS` because the EXE carries
  `QTR FINALS` at VA 0x653e04. That string is the **COCA-COLA CUP's own** block — five
  entries after `COCA-COLA CUP` at 0x653de4 — and the Coca-Cola Cup's own quarter-final draw
  (`keep_0111`) renders the plate **with** the dot, as does the European Cup's. So the plate
  comes from the SHARED uppercase set at 0x6538b0 (`SEMIFINALS` / `QTR. FINALS` /
  `1/8 FINAL` / `1/16 FINAL`), and the port has been printing a wrong string on every
  quarter-final card it raised. Fixed s88; gates `test_cup_draw_then_play`,
  `test_refrun_findings`, `test_europe`.
* **The U.E.F.A. Cup has TWO title spellings on this screen and both are witnessed at 0 px.**
  `p0747_cup_draw.png` (1/16 FINAL) reads `U.E.F.A. CUP`; `manutd_s2_uefa_1_32_finals.png`
  (1/32 FINALS) reads `UEFA CUP`. The EXE carries both (`UEFA Cup` 0x653878, `U.E.F.A. CUP`
  0x6538d4). What selects between them is NOT reversed and is not guessed at here.

### And the GROUP DRAW form is BUILT (s88)

`manutd_s1_eurocup_groups_1_8_final.png` is now the binding frame of `CupDrawScreen`'s third
panel form. Chrome `tools/re/build_groupdraw_chrome_from_frame.py`, geometry
`tools/re/probe_groupdraw_frame.py`, render-diff case `cupdraw_groups.png` in
`tools/re/diff_cupdraw_parity.py`, gate `app/tests/test_cupdraw_screen.gd` §7. It reproduces
this frame at **1 differing pixel** outside the CONTINUE ball and the eight kit/flag sprites
that carry the un-reversed 1-px on-sprite edge pass.

Still missing after FIVE drives: a **SEMIFINAL** and a **FINAL** draw. The s88 drive resumed
the s87 career at 30 January 1999 (Premier week 26, season 2) and Manchester Utd went out
before the tail of the ladder again; the career rolled into a 1999/2000 preseason and the
drive's PRESEASON rule dismissed it back to the title screen.
