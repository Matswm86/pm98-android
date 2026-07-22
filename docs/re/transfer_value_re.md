# Transfer VALUE (CLUB FEE) + WAGE — source-witnessed evidence (2026-07-22)

Owner complaint #1: "the values are nothing like the original." This session pins
what the real numbers ARE (35 source witnesses), proves the app model is wrong, and
proves the exact generative model is NOT a simple stored field or a core4 curve —
it is `f(attrs, age) × selling-club stature`, whose forms + the stature table remain
un-RE'd. **No guessed curve is shipped** (owner + `wage_formula_re.md` S5).

## 1. The "AV" column IS core4>>2 (EXE-verified, not assumed)

The TRANSFER MARKET / player-card "AV" number = the four core attributes averaged.
`FUN_00553194` (player card) computes it as `_ultoa(FUN_00534570() >> 2, …)`, and
`FUN_00534570` = `byte[+0x9c]+[+0x9d]+[+0x9e]+[+0x9f]` = core4 (VE+RE+AG+CA). So the
on-screen AV lets us map any witnessed row back to its EQUIPOS player: `core4 ≈ AV*4`
(±3 from the floor division). Verified against EQUIPOS: Leese(Barnsley) core4 273 →
273//4 = 68 = screen AV; Fursth(Colonia) 269//4 = 67 = screen AV.

## 2. 35 source witnesses — two TRANSFER MARKET screens (1997-08)

`wine-captures-2026-07-15/transfer_market.png` (Man Utd, wk2) +
`wine-captures-2026-07-19-lowerdiv/transfers_open.png` (Barnsley, wk1). Columns:
name · AV · MO · CLUB FEE · WAGE · YEARS(left/total). Full table decoded in
`tools/re/probe_value_witness.py`. Representative rows (name · AV · FEE · WAGE):

| player | AV | CLUB FEE | WAGE | note |
|---|---|---|---|---|
| Wilson (Northampton) | 59 | £5,000 | £5,000 | the minimum fee |
| Martindale | 54 | £25,000 | £10,000 | |
| Rickers | 53 | £50,000 | £5,000 | |
| Carragher | 57 | £75,000 | £5,000 | |
| Van Blerk | 68 | £90,000 | £25,000 | GK |
| Kadijevic | 73 | £150,000 | £30,000 | GK |
| Spiteri | 78 | £150,000 | £25,000 | |
| Gojkovic | 71 | £850,000 | £35,000 | |
| Villarroya | 74 | £500,000 | £90,000 | |
| Roberts | 78 | £1,500,000 | £125,000 | GK |
| Marcelle | 78 | £650,000 | £175,000 | |
| Scholes | 81 | £8,500,000 | £575,000 | |
| Zé Elías | 80 | £9,500,000 | £500,000 | |
| Berger | 88 | £11,000,000 | £1,000,000 | |

## 3. Fee & wage do NOT track core4 — they scale with selling-club stature

At near-equal AV the fee/wage span 100×+ : **Spiteri AV78 £150k vs Marcelle AV78
£650k vs (higher) Scholes AV81 £8.5M**; **Wilson AV59 £5k vs Berger AV88 £11M**.
The big numbers cluster at the big clubs (Berger=Liverpool, Scholes/Zé Elías at
Prem giants); the £5k floor rows sit at Div-2/3 clubs. This is the SAME stature
multiplier `wage_formula_re.md §3` found for wages (Bolton 1.0 vs Villa/Arsenal
2.08), now seen to drive the FEE as well:

> **fee = g(attrs, age) × club_stature**,  **wage = f(core4) × club_stature**

The `YEARS` column (contract length left) also moves the fee (1-yr-left players are
cheaper at equal ability). None of core4, Σ(10 attrs), age, `b1a/b16/b17`, `fine`,
or `band` orders the witnesses by fee/wage on its own (see the probe output).

## 4. What is ruled OUT (so next session doesn't re-walk it)

- **Not a simple stored EQUIPOS field** — `probe_value_witness.py` dumps every
  decoded per-player field for all 66 name-matches; no single byte/word is monotone
  in fee or wage. (Extends `wage_formula_re.md §1`, which disproved a stored *wage*.)
- **Not a plain float store to player+0x74** — `FindStoreDisp 0x74` finds NO
  `FST/FSTP [reg+0x74]` anywhere; the only `+0x74` float write (`FUN_005811e0`) is
  the finance-ledger weekly accumulator (`club+0x1e4 + week*0x20c`), re-confirmed
  this pass. So the wage float at player+0x74 is written **indirectly / lazily**,
  not by a direct displacement store the scanners catch.
- **`FUN_00581e60` is a 6-attr rating** `(VE+RE+AG+CA + byte[+0xa7] + FUN_00582db0)/6`,
  NOT the fee.
- Player-card wage display (`FUN_0053f2dd`, `FUN_00553194`) only READS the pre-set
  `*(float*)(player+0x74)` and formats it via the currency formatter `FUN_0058dd00`.

## 5. Compute-site map (the un-traced generative pass)

- Currency formatter = `FUN_0058dd00(dst, (double)value, 0)`; it has ~24 callers
  (`FindRefsTo 0x58dd00`) — every £-render in the game. The fee/wage GENERATION is
  the code that fills `player+0x74` (and the fee) before these read it.
- core4 (`FUN_00534570`) callers: `FUN_00587eb0` (roster-insert — zeroes +0x24..+0x64
  but NOT +0x74), `FUN_00588ae0` (new-signing jealousy — READS +0x74 to compare
  wages), plus the card renderers. The writer of +0x74 is on a **new-game roster
  pass reachable from the club loader `FUN_00579c70`**, still un-decompiled.

## 6. Two bounded closure paths (either finishes the fix EXACTLY, no guess)

1. **EXE**: decompile the transfer-market LIST render (a `FUN_0058dd00` caller that
   loops a club's players and prints CLUB FEE + WAGE per row) and the +0x74 writer on
   the new-game roster pass; read `g(attrs,age)` and the `club_stature` field.
2. **Witness sweep (Wine)**: capture the TRANSFER MARKET screen for ~10 clubs across
   all 4 divisions (each screen yields ~17 fee+wage+AV rows already club-tagged).
   With the exact club per row, solve `club_stature = wage / f(core4)` per club and
   fit `g` — validated, not assumed. `transfer_market.png` proves one screen alone
   gives 17 rows, so ~5-8 screens pins the table.

## 7. The app model is provably wrong (why the owner is right)

`TransferMarket.value_of` = `_TIER_FEE[tier]·(CA/50)^4·age_factor` and
`FinanceModel._player_wage` = `base(tier)·(CA/55)^1.6`:
- A 19yo backup GK (Landreau, CA92) → app fee **£8.9M** (tier-1). Real GKs of far
  higher standing: Kadijevic AV73 £150k, Friedel AV70 £750k, Mora AV75 £1.5M.
- Wage 8× high (Ward £121,680 app vs £15,000 real, `wage_formula_re.md §4`).
Both are wrong in a KNOWN direction; the fix is §6, not a re-tuned exponent.

## 8. Reproduce
`python3 tools/re/probe_value_witness.py` (35-witness decode + full field dump).
EXE leads re-run with the `ghidra_scripts/` headless harness against
`~/ghidra-projects/pm98` (program `MANAGER.EXE`).

## 9. EXE trace 2026-07-22b — the "seeded roster pass" model is DISPROVEN

This session traced the EXE (path §6.1) and **corrects** the prior framing that
"an un-traced new-game roster pass writes `player+0x74`." No such pass exists.
All statements below are decompiler/asm-verified (Ghidra headless, `MANAGER.EXE`),
NOT fitted — the exact generative arithmetic is still open, so no curve is shipped.

**9.1 The DBC player record carries NO money field (kills "just read it").**
The engine player parser `FUN_005820f0` (our `equipos_parse.parse_player` replica)
reads: id, squadNo, 2 names, slot, 6 fine bytes, `b1a/b16/b17`, band, DOB, height,
weight, (flag==0) 10 len-prefixed bio STRINGS, then the 10 attr bytes `+0x9c..0xa5`.
The record **ends after the attrs** — there is no stored fee or wage. So the market
fee/wage are computed, not tabled (extends §4, §7 of `wage_formula_re.md`).

**9.2 `player+0x74` (wage) and `player+0x70` (fee) are per-player FLOAT fields set
only at SIGNING, never seeded at load.** Full-binary float-store scans
(`FindFloatWrite74.java` for disp `0x70` and `0x74`, catching direct, `lea`+fstp and
`add`+fstp idioms) find the ONLY non-stack writes to `[reg+0x74]`/`[reg+0x70]` are:
- the finance ledger `FUN_005811e0`/`FUN_00581180` (indexed `[edx+eax*4+0x70/0x74]`,
  the weekly club records — not a player), and
- **`FUN_0058a360 @0x58a496`** = transfer/contract RESOLUTION. On a completed signing
  it does `FLD [ESI+0x1c]; FSTP [EBX+0x70]` — copies the **negotiated** fee from the
  pending-offer struct (`ESI = FUN_00589e20()`, field `+0x1c`) onto the new
  club-player record `EBX+0x70`. (Emits the "has been signed by / has renewed his
  contract / has rejected your offer" messages.)
So `+0x70/+0x74` hold the *agreed* fee/wage of a signed player; they are 0/unset for
un-transacted players. The club-load chain writes neither: `FUN_005792b0` (per-club
driver) → `FUN_00579b80` → `FUN_00579c70` (squad do-while) and the post-load pass
`FUN_00579460` (= filename/string bookkeeping) never touch `+0x70/+0x74`.
`FUN_00587eb0` (roster-insert) zeroes `+0x24..+0x64`, sets squad-nums + the `+0x100`
list-next, and calls core4 only to pick squad slots. Jealousy `FUN_00588ae0` and the
card renders only READ `+0x74`.

**9.3 The market fee+wage are DISPLAY-COMPUTED per player and passed to the card.**
The player/offer card `FUN_00533ddc` (asm `asm_533ddc` in scratch) formats the two
money columns from a struct pointer `EDX = [ESP+0x18]`:
`FLD [EDX+0x70] → FUN_0058dd00` (FEE/VALUE col, x=0xfc, Euro8 font) and
`FLD [EDX+0x74] → FUN_0058dd00` (WAGE col, x=0x142, ProMan8). It does NOT compute
them — the caller fills that struct. The offer-acceptance test `FUN_005889c0` reads
the same `struct+0x70` as the asking fee (`fVar1 = *(float*)(off+0x70)`), applies a
contract-years discount (`off+0x9a` years, flag `off+0x98`, constants `_DAT_00638fb0
/fb8/fc0`), and accepts iff `fee ≤ bid (param2+0x1c)`. So the FEE the owner sees IS a
float on the market/offer struct; the **arithmetic that first fills it from the
player's attrs + selling-club stature is the one remaining un-traced link.**

**9.4 Narrowed NEXT target (both bounded, no guess):**
1. **EXE:** find who fills the market/offer struct `+0x70`(fee)/`+0x74`(wage) BEFORE
   the card reads them — i.e. the offer/market-row constructor invoked from the
   transfer-list populate (`FUN_00532a50` → `FUN_00465d90`/`FUN_004f4860` row build)
   and from "open offer". That constructor reads player attrs (`+0x9c..0x9f`) + the
   selling club's stature field and does the `g(attrs,age)×stature` / `f(core4)×
   stature` FMUL. Scan: functions with `FMUL` that read byte `[reg+0x9c..0x9f]` and
   are reachable from `FUN_00532a50`. That FMUL site = the exact model. Also trace
   the INSURANCE modal wage render (the Ward/Frandsen witnesses) — it computes the
   displayed wage the same way and is a smaller function than the transfer list.
2. **Wine witness sweep:** unchanged from §6.2 (club-tagged fee+wage+AV rows).
New tool this session: `tools/re/ghidra_scripts/FindFloatWrite74.java` (backward-walk
float-store scanner; run `-postScript FindFloatWrite74.java 0x70` / `0x74`).
