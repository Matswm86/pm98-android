# RENEW negotiation screen — LIVE WITNESS + REBUILD (2026-07-23)

> Source: original `MANAGER.EXE` under wine (this repo's `.wineprefix`), a fresh
> **TOTAL-level** Manager-League career, MWM @ Aston Villa, Week 1. Reference frames in
> `screenshots/wine-captures-2026-07-23-renew-ground-villa/` (24_ficha → 28_offerresult).
> No invention: every claim below is read straight off the captured frames.

## BUILT 2026-07-23 — frame-true OFFER panel, 0px chrome parity
The invented full-screen browse list is GONE. `PlayerInfoScreen` now has a **renew mode**
(`begin_renew` / `end_renew`): the identity/stat zone becomes the OFFER panel, drawn from the
frame-cut `app/art/screens/ficha/renew_overlay.png` (headers/bars/◄►arrows/OFFER-label/CLAUSES
labels+sliders/CANCEL+OFFER, value cells + clause boxes cleared) + the dynamic layer (offered
CLUB FEE / YEARLY WAGE / YEARS, clause checkboxes via `renew_check_on/off.png`). Wired in
`Main._open_renew_negotiation`: OFFER → `Career.renew` (+ offered term) with the accept/reject
verdict, CANCEL → back to the plain card. **The OFFER-panel chrome is 0px vs frame 25** (baked
overlay region diff = 0/57940 px at the measured +1px window offset). Guard:
`app/tests/test_player_info_renew.gd` (33 asserts). Known honest gaps below (stepper increment,
clause sliders) are documented, not faked.

## Verdict (original finding): the app's RENEW screen WAS an INVENTED SUBSTITUTE

`Main._open_renew_negotiation` renders a generic full-screen blue browse list
("Offer current terms / Meet his wage demand / Better his demand", via `_mount_browse`).
The original shows **nothing like it**. The prior "sanctioned interim chrome for connective
flows" policy (contract_re.md) is REFUTED by the witness — the real RENEW is a reversed art
screen, so it must be rebuilt frame-true like every other ported screen.

## Level gate (witnessed at SELECT LEVEL, frame 01_level)
- **TRAINER** → "Automatic finances, Automatic contract renewal"
- **MANAGER** → "Automatic contract renewal"
- **ACCOUNTANT** → "Automatic tactics and squad"
- **TOTAL** → "Total control"

⇒ The manual RENEW negotiation only exists in **TOTAL** level. In TRAINER/MANAGER the engine
auto-renews (no screen). The app should gate the manual renew UI on TOTAL and auto-renew in
the other manual levels (Career already has `auto_renew`; wire the level flag).

## The real RENEW screen (frame 25_renew) — a negotiation FORM on the FICHA card

Pressing RENEW on the PLAYER INFORMATION card (frame 24_ficha) does NOT navigate away. The
card's top half (attributes/rating panel) is REPLACED in place by an **OFFER** panel; the
bottom half keeps the read-only **CONTRACT** panel. Layout (top→bottom, left column labelled
vertically OFFER / CONTRACT):

**OFFER panel (editable — your proposal):**
- Player photo + name header (kept from the card, blue title bar).
- `CLUB FEE` — orange value cell (static, = his release/again-fee, e.g. £7,500,000).
- `YEARLY WAGE` — value cell flanked by **◄ / ►** stepper arrows (adjust the offered wage).
- `YEARS` — value cell flanked by **◄ / ►** stepper arrows (adjust contract length).
- `CLAUSES` column (right): four rows, each a checkbox; some carry a slider/figure:
  - `Free if relegated` (checked red-X in the witness)
  - `Matches to renew` (checkbox + greyed slider)
  - `Scoring bonus` (checkbox + slider)
  - `House and car` (checkbox)
- **CANCEL** and **OFFER** buttons (centred, between OFFER and CONTRACT panels).

**CONTRACT panel (read-only — his current deal):**
- `CLUB FEE` £7,500,000 · `YEARLY WAGE` £575,000 · `YEARS` 2 · `LEFT` 2 · `CLAUSES:` (same
  four rows, current state).

**Bottom action row (unchanged from the card):** RENEW / TRANSFER / SACK / OK.

## Mechanics witnessed
- Wage/years are adjusted by the ◄/► steppers (increment size not yet measured — the arrow
  hit-points are small; measure off frame 25 during the rebuild).
- **OFFER** submits the proposal → the panel closes and returns to the plain FICHA card with an
  info-coin (frame 28_offerresult; offering his exact current terms accepted silently). The
  accept/reject + the "has rejected your offer for renewal" path (contract_re.md) drive off this.
- **CANCEL** returns to the plain card without offering.

## Rebuild checklist (evidence-first, one measured frame)
1. Measure the OFFER-panel geometry off frame 25_renew (native 640×480): the OFFER/CONTRACT
   split, CLUB FEE / YEARLY WAGE / YEARS cells, the two ◄/► arrow hit-rects, the 4 CLAUSES
   rows + their checkboxes/sliders, CANCEL + OFFER button rects.
2. Add a `renew` mode to `PlayerInfoScreen` (swap the attributes panel for the OFFER form;
   keep the CONTRACT panel + the bottom RENEW/TRANSFER/SACK/OK row).
3. Wire steppers to the `Contract` model (offered weekly/years), CLAUSES to the real clause
   fields, OFFER → `Career.renew` with the accept/reject verdict + info-coin/alert, CANCEL → close.
4. Delete `Main._open_renew_negotiation`'s `_mount_browse` substitute.
5. Render-diff the rebuilt panel vs frame 25_renew (0px target) before calling it done.

## Open (do NOT fake)
- Stepper increment size + the wage/years min-max the engine will accept.
- Clause slider ranges (Matches-to-renew target, Scoring-bonus figure) — measure/RE, don't invent.
- The reject-message + affordability behaviour on OFFER (contract_re.md has the model; confirm
  against a live rejected offer).
