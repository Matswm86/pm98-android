# YOUTH TEAM — a FILLED ROSTER ROW, 2026-08-01 (s86)

B9's third and last visual gap. The first two closed in s84 (the filled PLAYERS FOUND panel
and the training chips); this one needed the prospect actually **SIGNED**, because the row
tap raises the contract-offer card and only OFFER puts him on the roster. s84 wrote
`tools/re/wine/plans/season_youth_b9_sign.json` for exactly that and no drive had ever
reached a signature.

Banked off this session's drive: an isolated wineprefix on `Xvfb :8` (never Mats's
desktop, `PM98_NO_RAISE=1`), a TOTAL-level Bolton W career, driven from a fresh start to
**Saturday 3 October 1998**.

| file | what it is |
|---|---|
| `b9_roster_signed_1998-10-03.png` | the witness — one signed youngster on the roster |
| `b9_roster_signed_prev.png` | the same screen ~2 weeks earlier, as the stability check |

The two differ by **1,672 px and every one of them is inside the header date plaque**
(x451..639, y9..51). The roster widget itself is identical, so the widget is stable and one
cut is enough — the same test s84 applied to the PLAYERS FOUND panel.

## What the frame says

The row: `Burgess | SP 20 | ST 19 | AG 20 | QU 21 | AV 20 | ROL | £5,000 | 3 | 3`

Measured off it, and each one was a defect in the port:

* **the name is NOT upper-cased** — "Burgess", the same correction s84 had to make to the
  PLAYERS FOUND name column;
* **the five parameter cells are (212,63,0)**, the AV column header's orange — note they do
  NOT carry their own headers' slate (100,100,140), so "each value carries its header's ink"
  is not the rule here;
* **the money is (150,0,0)** and **the two trailing figures are (42,63,170)**, each its own
  header's ink;
* **there are TWO figures under the single YEARS header**, at cx **406** and **432**, while
  the header's own ink spans x396..441. The port drew one, centred at 418 — between them.
  The pair is the youth card's own YEARS / LEFT (refrun `p0771`). This row has 3 and 3, so
  it cannot say which cell is which; the port follows the card's order and says so.

## And a second thing the frame settles

The scout is **S. Munt**, and his star bar is **1.5**, not 2 — one full 13-px glyph and one
8-px half. His SEARCH CAPABILITY block reads HANDLING and TACKLING YES and the other four
NO, which is the identical mask J. Casson and C. Dewhurst carry. Measured by
`tools/re/probe_youth_cap_mask.py`, all three of the scouts previously read as "2★" are
1.5★ — so the s85 conclusion that the mask is *per scout* rested on a star bar counted by
eye, and the mask does follow the rating. See `YouthScreen.CAP_BY_STARS`.

## What is still open on this row

The row's INKS and COLUMNS are done. The row **PLATE and its per-cell GRID** are still the
port's own: `tools/re/diff_youth_parity.py` reports the pair (`youth_b9roster`) at
**1,816 px over the row band** and does not gate on it. Closing it is the same bake
`build_youth_found_list_from_frames.py` did for the PLAYERS FOUND widget, against this
frame.
