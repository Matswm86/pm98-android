# Transfer VALUE (CLUB FEE) + WAGE — source-witnessed evidence (2026-07-22)

> **✅ SOLVED 2026-07-22c (see §10).** The generative model is a byte-exact LOOKUP
> TABLE in `MANAGER.EXE` (`FUN_00576cd0`), not a curve — which is why no exponent
> ever fit. `fee = feeTable[idx]×5000`, `wage = wageTable[idx]×5000`,
> `idx = stature*54 + abilityTier(AV)*6 + ageTier(age)`. Tables extracted to
> `docs/re/value_tables.json`; **reproduces all 13 fee/wage witnesses exactly**
> (`tools/re/validate_value_model.py`). §1-§9 below are the evidence trail that led
> there; §10 is the answer. No guessing — the numbers are the game's own bytes.

Owner complaint #1: "the values are nothing like the original." This session pins
what the real numbers ARE (35 source witnesses), proves the app model is wrong, and
proves the exact generative model is NOT a simple stored field or a core4 curve —
it is `f(attrs, age) × selling-club stature`, now fully RE'd as a table (§10).
**No guessed curve is shipped** (owner + `wage_formula_re.md` S5).

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

## 10. ✅ SOLVED — the generator is `FUN_00576cd0`, a lookup table ×5000 (2026-07-22c)

EXE trace closed it. The market fee+wage are written to **player+0x70 (fee)** and
**player+0x74 (wage)** by **`FUN_00576cd0`**, invoked per squad-player by
**`FUN_0057a5a0`** (which first calls `FUN_0057a180` to set the club's stature).
My earlier `+0x74` float-store scan missed the write because the store is
`FSTP [ESI+0x8]` where `ESI = player+0x6c` (base folded across the call, disp `0x8`).

**Exact model (asm-verified `FUN_00576cd0` @0x576cd0, tables dumped from the EXE):**
```
AV          = (VE + RE + AG + CA) >> 2            # core4>>2, the on-screen "AV"
abilityTier = AV>=95?0 : >=90?1 : >=85?2 : >=80?3 : >=75?4 : >=70?5 : >=65?6 : >=60?7 : 8
ageTier     = age<20?0 : <23?1 : <26?2 : <30?3 : <33?4 : 5
idx         = stature*54 + abilityTier*6 + ageTier        # word index
fee   (£)   = feeTable [idx] * 5000     # feeTable  @VA 0x638788
wage  (£/yr)= wageTable[idx] * 5000     # wageTable @VA 0x638208
```
- **Tables**: 13 stature bands × 9 ability tiers × 6 age tiers = **702 uint16 each**,
  extracted byte-exact to `docs/re/value_tables.json` (`tools/re/extract_value_tables.py`).
  Stature 0 = elite (Liverpool/Man Utd), rising to 12 = lowest; higher stature → far
  lower fees+wages at equal ability (this IS the "club stature" the witnesses showed).
- **Multiplier**: the asm does `FILD word; FMUL double[0x638d08]` where `[0x638d08]=1e6`,
  and the display path divides by 200 → **net ×5000** (= the £5,000 offer base step).
  Every witness validates with a single ×5000, so use 5000 directly in the port.
- **stature** = `club+0x58`, set by `FUN_0057a180`: the club's rank within its league
  (`vtable+0x78`, capped at 12); special ids 0x26ae→0, 0x26de/0x26e4 (free/youth)→12/13.
  This is the ONE input the app must reproduce for a byte-exact runtime port (a club
  rank/reputation 0-12); the tables + tiers + ×5000 above are fully fixed.

**Validation (`python3 tools/re/validate_value_model.py`): 13/13 witnesses exact.**
Berger AV88→stature0 £11M/£1M; Scholes AV81→stature0 £8.5M/£575k; Marcelle(Barnsley)
AV78→stature3 £650k/£175k; Wilson(Northampton) AV59→low stature £5k/£5k; Spiteri AV65
(NB: his on-screen AV78 in §2 was a mis-read; core4 gives 65)→stature3 £150k/£25k.

**Port (next step, no guess left):** replace `TransferMarket.value_of` +
`FinanceModel._player_wage` with the `value_tables.json` lookup above, deriving each
club's stature 0-12 the way `FUN_0057a180` does (rank within division). Re-verify vs
the 13 witnesses + Ward £15k/Frandsen £175k before shipping.

## 11. Reproduce (§10)
`python3 tools/re/extract_value_tables.py` (writes `value_tables.json`) ·
`python3 tools/re/validate_value_model.py` (13/13 witness check) ·
EXE: `FUN_00576cd0`/`FUN_0057a5a0`/`FUN_0057a180`, tables @0x638788 (fee) & 0x638208 (wage).

## 12. ✅ STATURE fully RE'd + PORTED — band = division + squad-strength threshold (2026-07-22d)

The prior "one remaining input" (each club's stature band 0-12) is now **traced byte-exact**,
no guess left. `FUN_0057a180(club)` sets `club+0x58` = the band passed to `FUN_00576cd0`:

- **clubId `0x26ae` → band 0**; free/youth `0x26de`/`0x26e4` → band **12** (asm sets +0x58=12,
  +0x50=13; the earlier "→12/13" note conflated the two fields).
- **Normal club:** it finds which of 10 league objects (`DAT_0066b190[0..3]` = the 4 English
  divisions, then `[7..12]`) the club is in via `vtable+0x48(clubId)`, computes the club's
  **average AV** `FUN_0057a340(club)` = `floor( Σ(VE+RE+AG+CA over squad) / (nPlayers*4) )`,
  then `band = clamp( leagueVtable+0x78(avgAV), 0, 12 )`.
- The `+0x78` method is **per-division** (that's why the 4 divisions have distinct vtables) and
  is a pure **threshold on avgAV**, mapping each division onto a fixed band sub-range:

| Division (tier) | `+0x78` fn | avgAV thresholds → band |
|---|---|---|
| Premier (1) | `FUN_0041c660` | ≥80→**0**, 76-79→**1**, 72-75→**2**, ≤71→**3** |
| Division 1 (2) | `FUN_00410c10` | ≥64→**4**, 60-63→**5**, ≤59→**6** |
| Division 2 (3) | `FUN_004255e0` | ≥54→**7**, 52-53→**8**, ≤51→**9** |
| Division 3 (4) | `FUN_0042ed60` | ≥50→**10**, 48-49→**11**, ≤47→**12** |

Verified against the shipped `game_db.json`: Man Utd avgAV81→**0**, Liverpool 80→**0**,
Barnsley 71→**3**, Blackpool (Div2) 54→**7** — matching every pinned witness (Berger/Scholes
stature 0, Marcelle/Barnsley 3, Taylor/Blackpool 7). Age-tier has ONE extra asm branch missed
by §10's summary: age<20 **and** AV≥95 **and** band==0 → ageTier **1** (not 0).

**PORTED (2026-07-22d):** `TransferMarket.stature_of(players, tier)` reproduces the table above;
`TransferMarket.value_of/yearly_wage/weekly_wage(player, band)` are the RE'd `FUN_00576cd0`
lookup (×5000). `FinanceModel`/`Contract`/`Career`/`Main`/screens now thread **band** (a club's
squad-derived stature), not tier. The invented fee curve + `_player_wage`/`_WAGE_BASE`/`_TIER_FEE`
are deleted. Headless suite green; Taylor £3M + 13/13 witnesses reproduce through the live GDScript.
Decompiled sources: `docs/re/decompiled/fn_0057a180*.c`, `fn_0057a340*.c`, `fn_0057a5a0*.c`,
`fn_00576cd0*.c`, and the four `+0x78` rank fns.

## 13. Foreign (non-English) club stature — the shared threshold `FUN_004457a0` (2026-07-22e)

§12 reversed the FOUR English divisions' `+0x78` band fns. It left the *foreign* clubs
(Nantes, Estudiantes, …; `game_db.json` `leagueId: null`) un-RE'd, so the app valued a
foreign scout/offer target with an **empty squad + the manager's own division tier** —
Landreau's fee swung £750k↔£3.25M by the player-manager's division. Now closed, no guessing.

**How `FUN_0057a180` picks a foreign club's threshold.** The league-object array
`DAT_0066b190[0..12]` is built by `FUN_00441ea0` (decompiled). Indices **0-3** are the
English divisions (Prem/Div1/Div2/Div3). `FUN_0057a180` scans 0-3 first; if the club is in
none, it scans the **second group, indices 7-12** (constructors `FUN_00457ac0(7)`,
`FUN_0045dfb0(8)`, `FUN_00451b30(9)`, `FUN_004631a0(10)`, `FUN_00431b30(11)`, and the simple
object at vtable `0x626e80` = idx 12). band = `(matchedVtable+0x78)(avgAV)`, clamped ≤12.

Reading each of those six vtables' `+0x78` slot straight from `.rdata` (validated first
against the four English slots, which match §12 exactly) gives:

| idx | league-obj vtable | `+0x78` fn |
|---|---|---|
| 7 | `0x627438` | **`FUN_004457a0`** |
| 8 | `0x627568` | **`FUN_004457a0`** |
| 9 | `0x627300` | **`FUN_004457a0`** |
| 10 | `0x627698` | **`FUN_004457a0`** |
| 11 | `0x623f70` | **`FUN_004457a0`** |
| 12 | `0x626e80` | **`FUN_004457a0`** |

**All six foreign leagues share ONE threshold fn.** `FUN_004457a0` (decompiled,
`docs/re/decompiled/fn_004457a0*.c`) maps a club's avgAV → band **0-9** (finer than Prem's
0-3, and it never reaches the 10-12 tail — so the earlier handoff guess "foreign falls into
bands 7-12" was wrong):

| avgAV | ≥80 | 76-79 | 72-75 | 68-71 | 64-67 | 60-63 | 56-59 | 54-55 | 52-53 | ≤51 |
|---|---|---|---|---|---|---|---|---|---|---|
| band | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |

**PORTED (2026-07-22e):** `TransferMarket._foreign_band(avg)` = `FUN_004457a0`;
`TransferMarket.stature_of(players, tier)` routes any non-1-4 tier through it;
`TransferMarket.english_tier_of(club, leagues)` returns 1-4 for an English club and **0** for
a foreign/leagueless one (kept distinct from `FinanceModel.tier_of`, whose foreign→2 default
is a FINANCE default, not a stature one). The foreign-reachable valuation sites now pass the
club's OWN squad + `english_tier_of`: `Career._scout_row` (frozen rows),
`Career._resolve_pending_bids`, `Main._show_browse_offer_card`, `Main._show_player_info`.
Result (byte-exact table, verified live): Nantes avgAV 71 → band **3**; Landreau fee
**£3,250,000** — deterministic, independent of the manager's division. Guarded by
`test_transfers._foreign_stature`. Decompiled: `fn_004457a0`, `fn_00441ea0`, and the five
foreign-league ctors in `docs/re/decompiled/`.
