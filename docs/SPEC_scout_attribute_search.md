# SPEC — SCOUT: name search + per-attribute thresholds (OURS, not the binary's)

**Owner decision, Mats, 2026-07-25.** Two additions to the SCOUT screen that the original
does not have. Label them ours in code the same way `Youth.SEARCH_SPEEDUP` is labelled, so a
future faithfulness audit does not mistake them for reversed behaviour.

## What the original actually offers (witnessed this session)

Live frame `out/refrun-scout-search/play/p0023_UNKNOWN.png`, SCOUT screen, scout W. Lumb
(5 stars, wage £51,000):

- **five criteria spinners**: `POSITION` · `AGE` · `ROLE` · `QUALITY` · `PRICE`
- **seven toggles**: Premier · 1st Div. · 2nd Div. · 3rd Div. · E.U. PLAYERS ·
  NON E.U. PLAYERS · PLAYERS WITHOUT TEAM
- a `SEARCH` button and a `PLAYERS FOUND` result list

`ScoutScreen.gd:88-93` documents only three of the five (AGE 5 bands, QUALITY 7 bands,
PRICE 10 bands, from the binary tables at 0x661e08 / 0x661e20 / 0x661e40). **POSITION and
ROLE are present on the real screen** — check whether the port carries them.

There is **no per-attribute criterion anywhere** in the original. Every spinner was stepped
through its full cycle live (`out/refrun-scout-search/`, contact sheets `sheet_*.png`):

- **POSITION** — blank + `GOALKEEPER` · `DEFENDER` · `MIDFIELDER` · `FORWARD`
- **QUALITY** — blank + `50-65` · `66-70` · `71-75` · `76-80` · `81-85` · `86-90` · `+90`.
  Exactly the seven in `ScoutScreen.gd:92`, confirmed. This is the `AV` number,
  i.e. `(VE+RE+AG+CA)>>2`.
- **ROLE** — blank + **18 named roles**, in `posFine` order (table below)
- AGE and PRICE were not stepped; the port documents 5 and 10 bands from the binary tables.

So everything below is new.

## The ROLE dropdown — the posFine name table (WITNESSED, closes a standing gap)

The fine role was previously known only as a pitch glyph with no text name. The SCOUT
ROLE dropdown names all eighteen, and the dropdown order **is** the `posFine` index —
proven by Cole (`posFine 9`, card reads `ROLE: CENTRE FORWARD`).

| # | role | # | role | # | role |
|---|---|---|---|---|---|
| 1 | KEEPER | 7 | RIGHT MID. | 13 | CENTRAL STRIKER |
| 2 | RIGHT BACK | 8 | INSIDE RIGHT | 14 | LEFT WINGER |
| 3 | LEFT BACK | 9 | CENTRE FORWARD | 15 | DEF. MIDFIELDER |
| 4 | SWEEPER | 10 | CENTRAL MID. | 16 | RIGHT FORWARD |
| 5 | INS. CENT. LEFT | 11 | LEFT MID. | 17 | LEFT FORWARD |
| 6 | INS. CENT. RIGHT | 12 | RIGHT WINGER | 18 | INSIDE LEFT |

Cross-checked against `game_db` populations and coherent throughout: 1 holds all 983 GKs,
2-6 are the 3,104 defenders, 9 is the largest forward group at 1,411.

**One honest wrinkle:** roles 13, 16 and 17 (CENTRAL STRIKER, RIGHT/LEFT FORWARD) are held
mostly by players whose *coarse* `pos` is `MF`, not `FW` (13 = MF 324 / FW 72). Either the
coarse byte is independent of the fine role in the source data, or the extractor derives it
with a different grouping. Not resolved here; do not assume `pos` follows from `posFine`.

## Addition 1 — name search

A free-text field that filters `PLAYERS FOUND` (and the searchable pool) by player name.
Substring, case-insensitive, accent-insensitive if cheap.

## Addition 2 — per-attribute thresholds

Six independent "at least" filters, one per **skill** attribute. These are exactly the six
`Training.TRAINABLE` attributes, so the searchable set equals the improvable set:

| filter label | code | notes |
|---|---|---|
| HANDLING | `PO` | keeper skill; `GKSAVE = PO + 10` in the keeper slot, clamped 99 |
| PASSING | `PA` | the only skill the match engine reads (`PASS`) |
| DRIBBLING | `RM` | **RM is DRIBBLING** — confirmed against Cole's live card |
| HEADING | `RG` | **RG is HEADING** — same source |
| TACKLING | `EN` | |
| SHOOTING | `TI` | |

**Threshold values: 30 to 95 in steps of 5** (14 stops: 30, 35, 40, ... 95), plus an
"any" / off position. Semantics are `attr >= threshold`; multiple filters AND together.

The four GENERAL attributes (SPEED `VE`, STAMINA `RE`, AGGRESSION `AG`, QUALITY `CA`) are
**not** part of this: they are already covered by the original's `QUALITY` band, since that
band is their mean. Mats: *"Rating is already ingame."*

## The honesty note that goes with it

Only `STR` (the mean of VE/RE/AG/CA), `PASS` (=PA) and `GKSAVE` (=PO+10) are read by the
match engine. The participant map in `docs/re/stat_match_engine_re.md:346-352` annotates
`EN`, `RM`, `RG` and `TI` as *"unread by stat engine"*.

So four of the six filters above let a player optimise on numbers that do not move a
scoreline. That is a deliberate choice, made with the fact known: the attributes are real
game data, they are what TRAINING improves, and in the port they weight which player is
named in match commentary. They are not, however, a route to a better result.

Do not "fix" this by hiding them. Mats asked for all six.

## Attribute label reference (confirmed against the live PLAYER INFORMATION card)

Andrew Alexander COLE, Manchester Utd., frame `p0056_UNKNOWN.png`:

```
SPEED 87  STAMINA 86  AGGRESSION 84  QUALITY 75  FITNESS 70  MORAL 99   RATING 83
HANDLING 13  PASSING 70  DRIBBLING 86  HEADING 73  TACKLING 65  SHOOTING 88
ROLE: CENTRE FORWARD            (posFine 9)
```

`game_db` for the same player: `VE 87 RE 86 AG 84 CA 75 · PO 13 PA 70 RM 86 RG 73 EN 65
TI 88`. Every value matches, so the card labels pin all ten codes.

`RATING = (VE+RE+AG+CA+FITNESS+MORAL) / 6` = `(87+86+84+75+70+99)//6 = 83`, matching the
card exactly (`Morale.av6`, `FUN_00581e60`).

**Latent trap found while confirming this — FIXED, verify before repeating it.** `Training.gd`
`_NAMES` used to map `"RM": "Heading", "RG": "Dribbling"` — swapped — and to call VE "Pace",
CA "Ability" and PO "Goalkeeping", none of which is a word the game prints. It now carries the
card's own ten labels (`RM: Dribbling`, `RG: Heading`, `VE: Speed`, `CA: Quality`,
`PO: Handling`). The 2026-07-26 work list still listed this as open; it was not.
