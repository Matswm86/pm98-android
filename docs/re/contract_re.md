# Player Contracts & Wages — reverse-engineering notes + model

The squad's **RENEW** button (on the transfer/squad screen) was a one-tap reset of a
player's term — no wage, no negotiation, no way for a player to say no. PM98's renewal is a
negotiation: a player has a wage he wants, can **reject your offer for renewal**, and walks
on a **free transfer** when his deal runs out. This rollout makes RENEW that negotiation and
gives wages weight — a signing or a renewal raise now moves a live weekly wage bill.

## Faithful surface (strings scanned from MANAGER.EXE)

```
RENEW                                CLUB FEE / YEARLY WAGE / MONTHLY WAGE / WAGE
FREE TRANSFER / "Free if relegated"  CONTRACT / COMPENSATIONS OF CONTRACT
"%s has renewed his contract."
"%s has rejected your offer for renewal."
"%s has left your club as his contract has not been renewed"
"The transfer deadline is now %u week%s away."
Options "Automatic contract renewal"   "This option is automatic in the Trainer level."
```

So a renewal is offered, can be **rejected**, an unrenewed deal ends in a **free transfer**
departure, and PM98 exposes an **Automatic contract renewal** option (automated at higher
Trainer levels). Wages are shown **yearly** and **monthly** per player.

## What we built (and what is ours vs PM98's)

PM98's per-player wages are **data-driven** — they live in the EQUIPOS / save data, not in
code (like the fee + finance models, see `finance_constants.md`). So the **surface** above is
PM98's; the wage + demand **model** is ours, in `app/scripts/Contract.gd`, calibrated to
`FinanceModel.weekly_wage` so a signing's wage and the club's books agree.

- **Wages are stored on the player** (`wage`, weekly £), stamped when he joins (seed /
  signing / youth promotion). A player with no stored wage (a pre-contracts save, a GameDB
  club) falls back to his **market wage**, which is deterministic, so legacy data behaves
  identically. `Contract.current_weekly` is the single source of truth; `YEARLY WAGE` =
  `current_weekly × 52`, `MONTHLY WAGE` = `× 52 / 12`.
- **Wage demand** (`demanded_weekly`): floored at his current wage (he never re-signs for a
  cut), otherwise his market wage scaled by **ambition** — young, improving, higher-CA players
  push hardest (age ≤21 → ×1.40 … ≥32 → ×0.98, plus a small CA nudge), rounded to £100.
- **The negotiation** (`renewal_options` + `evaluate_renewal`): three offers — **hold** his
  current terms (a lowball for anyone wanting a raise), **meet** his demand, or **better** it
  (×1.10) to lock him in. He accepts at/above his demand, may balk in a narrow band just below
  it (`SOFT_FLOOR` = 0.90), and flatly refuses under that → **"has rejected your offer for
  renewal."** On acceptance his term resets to `NEW_TERM_YEARS` (3) and his stored wage
  updates to the agreed figure (so a raise flows into the bill).
- **The live wage bill → cash** (`Career.player_weekly_wage`): the sum of the squad's
  contracted wages is drawn from cash **every week**, so signings and renewal raises lift your
  outgoings. To avoid double-counting, `weekly_net` is now the per-week finance delta **without**
  player wages (`weekly_balance + weekly_wages`); for an unchanged squad the live draw exactly
  equals the wages added back, i.e. **identical** cash to before. `FinanceModel.summary` honours
  a player's stored `wage` over the market estimate, so the books reflect a raise.
- **Free-transfer expiry + auto-renew** (`advance_season`): a player in the final year of his
  deal (`is_expiring`, `contract_years ≤ 1`) leaves on a **FREE TRANSFER** at the rollover if
  you didn't tie him down — *"has left your club as his contract has not been renewed"*. The
  per-player **Automatic contract renewal** flag (`auto_renew`) re-signs an expiring player at
  his demand instead, **if the club can fund the deal** (a season's wage); otherwise he still
  leaves. You set it in advance on the player's deal screen.

## Screen (interim PM98 chrome)

The RENEW negotiation and the squad list are connective menu flows, so they use the
sanctioned interim chrome (`_set_view`, as with training / news), not a reversed art screen:

- **MY SQUAD** lists each player with his weekly wage and an **EXPIRING** tag, headed by the
  live `£X/wk wage bill`.
- The player's deal screen shows **YEARLY WAGE (£/mo)**, his contract years, an **EXPIRING**
  marker, and an **Auto-renew at expiry: ON/OFF** toggle.
- **RENEW** opens the negotiation: *"On £X/wk now — he wants £Y/wk — pick an offer"* over the
  hold / meet / better rows; the chosen offer is accepted or **rejected**.

## Tests + verification

`app/tests/test_contract.gd` covers the unit model (market/current/demanded wage, the
never-a-cut floor, ambition by age, offer monotonicity, accept/reject thresholds, expiring,
the squad bill) and the Career integration (wages stamped at create, the live bill drawn from
cash each week, a signing lifting the bill, the RENEW negotiation accepting/rejecting with the
faithful messages, auto-renew at the rollover incl. the affordability guard, and persistence
incl. legacy-save migration). Verified by a REAL render (`PM98_CONTRACT_SHOT=1` under opengl3,
`screens/contract.png`): *Renew LUKIC — on £7,900/wk, wants £8,700/wk* over the three offers
(£7,900 / £8,700 / £9,600 ×3y), the demand and the "better" figure reconciling
(£8,700 × 1.10 → £9,600). 29 harnesses green; headless compile guard clean.
