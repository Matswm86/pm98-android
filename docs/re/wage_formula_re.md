# Player WAGES — reverse-engineering the real formula (2026-07-19)

> **SUPERSEDED (2026-07-23).** The "wage = f(core4) × club_factor" fit below (and the
> `FinanceModel._player_wage` CA^1.6 model it critiques) are BOTH dead. Wages are the
> byte-exact PM98 lookup table `wageTable[band*54 + abilTier*6 + ageTier] * 5000`
> (`TransferMarket.yearly_wage`, `docs/re/transfer_value_re.md §10/§14`), which reproduces
> all **19** Man Utd week-1 wage witnesses EXACTLY once the age basis is `1997 - birthYear`
> (§14). The club_factor mystery here was the wrong model + a +1 age bug. Kept for history.

Owner ask (s22/s23 NEXT #1): the app's wage bill is "WAY too wrong". This closes
the **question of where wages come from** and validates the **structure of the real
formula** against source-witnessed ground truth, without inventing the parts that are
still un-RE'd. Supersedes the `contract_re.md` claim that wages "live in the
EQUIPOS/save data" — that is **disproven below**.

## 1. Wages are NOT a stored EQUIPOS field (disproven, not assumed)

`tools/re/probe_wage_field.py` parses all 476 club records with the engine-exact
parser (`equipos_parse.py`) and sums every candidate per-player integer over the
VALID squad of the three clubs whose week-1 wage bill was witnessed live
(`export_club_economy.py`): **Arsenal 232,692 / Aston Villa 129,326 / Bolton 39,903
per week**. For a stored wage field F, `sum(F over squad) * k` must equal the anchor
for the SAME `k` across all three clubs. Result:

| candidate | Arsenal k | Villa k | Bolton k | constant? |
|---|---|---|---|---|
| u16@struct+0x16 (`b16│b17<<8`) | 10.68 | 9.34 | 1.85 | no (spread 1.21) |
| byte +0x16 / +0x17 / +0x1a | — | — | — | no (spread ≥1.19) |
| CA alone | 108.99 | 93.51 | 26.44 | no (1.08) |
| Σ all 10 attrs | 13.30 | 10.67 | 2.73 | no (1.19) |

No field gives a constant `k`. `u16@+0x16` is just two small role/contract codes
concatenated (values 257=0x0101, 769=0x0301, 770=0x0302, 1537=0x0601), not money.
**Conclusion: the per-player wage is computed, not stored** — consistent with
`finance_constants.md` (finance is a runtime float ledger; initial values load from
the DB and are accumulated, not tabled).

## 2. Where the wage lives at runtime (from `morale_re.md`, re-confirmed)

- **player + 0x74** = the runtime wage float (new-signing jealousy `FUN_00588ae0`,
  morale wage-term `FUN_0057b710` read it; the morale RE only ever compared RATIOS,
  so it never pinned the absolute value).
- **club + 0x1f8** = the wage bill; **club + 0x28** = squad count.
- `core4 = VE+RE+AG+CA` via **`FUN_00534570`** (bytes +0x9c..+0x9f), re-decompiled
  this pass — exact.

The write to player+0x74 is **not** in the DBC loader (`FUN_005820f0`, our
`equipos_parse` replica — it only writes attrs +0x9c..+0x9f, with the 0x26e4
degrade branch), **not** in the roster-insert/slot-picker (`FUN_00587eb0`), **not**
in season-init (`FUN_005825c0`, which sets morale/fitness/+0xa8 only). No `mov`/`lea+
fstp` store to +0x74 exists in the player-code range — the sole `lea …+0x74; fstp`
in the binary (`FUN_005811e0`) is a **finance-ledger** accumulator (`club+0x1e4` week
records, 0x20c-byte stride), not the player wage. So the wage is computed on a
**new-game roster pass not yet traced** (or on-demand from core4). This is the one
remaining un-RE'd link.

## 3. The real formula's STRUCTURE — derived from witnesses, cross-validated

Two **witnessed original per-player wages** (INSURANCE POLICY modal, fresh Bolton
career wk3, `insurance_screen_re.md` frames 35/38; monthly = yearly/12 truncated):

| player | core4 | age | witnessed yearly |
|---|---|---|---|
| Ward | 221 | 27 | £15,000 (£1,250/mo) |
| Frandsen | 316 | 27 | £175,000 (£14,583/mo) |

Both age 27, so the core4→wage relation is clean here. Fit an exponential through the
two points: **`wage_yr = 49.44 · 1.02620^core4`** (≈ **+2.62 %/core4 point**;
`tools/re/probe_wage_formula.py`). Cross-checked against the three witnessed
**club** bills (yearly = weekly×52):

| club | predicted Σ | anchor Σ | ratio |
|---|---|---|---|
| **Bolton** | 2,161,543 | 2,074,956 | **1.04** ✓ |
| Aston Villa | 3,240,137 | 6,724,952 | 0.48 |
| Arsenal | 5,798,540 | 12,099,984 | 0.48 |

The **same** ability curve reproduces Bolton's entire bill to 4 % AND both witnessed
Bolton players exactly — but Villa and Arsenal each need a **consistent ~2.08×**
multiplier. No single ability-only curve can satisfy all five constraints (a steeper
curve that matched Villa/Arsenal would violate the Frandsen witness), so:

> **wage = f(core4) × club_factor**, where `f` is ≈exponential (~2.6 %/point) and
> `club_factor ≈ 1.0` for Bolton, `≈ 2.08` for Villa & Arsenal.

Villa (budget u32 1000) and Arsenal (1200) share the SAME 2.08× despite different
budgets, so `club_factor` is **not** proportional to the budget field — it is a
discrete stature/reputation tier. Bolton (promoted from Div 1 in 96-97, budget 400)
sits at 1.0. **Three clubs cannot determine what drives it** — flagged, not guessed.

## 4. Why the current app model is "WAY too wrong"

`FinanceModel._player_wage` = `base(tier) · (CA/55)^1.6`, tier-based on the single CA
attr, no club_factor:
- Ward: 4000·(39/55)^1.6 ≈ **£121,680/yr** vs witnessed £15,000 → **8× too high**.
- Frandsen: ≈ £399,568/yr vs £175,000 → **2.3× too high**.
- All Premier clubs share tier-1 base, so Bolton ≈ Arsenal per-CA — the real game
  pays a promoted club far less. Two independent errors (curve too shallow/high +
  no club stature), compounding.

## 5. Open gaps (flagged, to be closed before ANY app change — no guessing)

1. **Exact base curve** — exponential vs power-law vs lookup-table are
   indistinguishable from 2 points (power fit `1.17e-12·core4^6.87` matches Bolton
   1.09, Villa/Arsenal 0.47 — same shape). Extrapolating the wrong FORM to core4
   extremes (e.g. an old backup keeper with high core4 but low CA, like Lukic
   core4=309) could be very wrong. Do NOT ship a form-assumed curve.
2. **`club_factor` driver** — measured 1.0 (Bolton) vs 2.08 (Villa≈Arsenal); the
   field that produces it is un-RE'd (not budget u32). Needs ≥4–5 more witnessed
   club week-1 bills spanning divisions, OR the EXE trace below.
3. **Age term** — both witnesses are age 27; whether wage also scales with age is
   untested (a young star or a veteran at the same core4 may differ).

## 6. Two closure paths
- **Witness campaign**: capture 4–5 more clubs' week-1 wage bills + a handful of
  per-player INSURANCE-modal wages spanning ages/divisions → pins base FORM,
  club_factor driver, and any age term by validation.
- **EXE trace**: find the new-game roster pass that writes player+0x74 (start from
  the callers of the club loader `FUN_00579c70` / the `FUN_00588xxx` roster builders
  above the insert `FUN_00587eb0`), decompile the core4→×club→store sequence.

## 7. Reproduce
`python3 tools/re/probe_wage_field.py` (disproof) ·
`python3 tools/re/probe_wage_witness.py` (squad attrs+ages+witnessed wages) ·
`python3 tools/re/probe_wage_formula.py` (curve fit + 3-club cross-validation).
