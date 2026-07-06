# MO (morale) + FITNESS + RATING/AV decode — MANAGER.EXE

Closes the APP_VS_SPEC_AUDIT "REMAINING GAP: MO" (owner call 2026-07-02: "morale IS
in MANAGER.EXE — RE it"). Reversed 2026-07-03 with Ghidra `DecompileAt` against
`~/ghidra-projects/pm98` + the new batch PCode oracle `tools/re/ghidra_scripts/
SweepEmu.java`. Ported to `app/scripts/Morale.gd`. Every constant below was read
from the binary; the result-delta matrix was EMULATED out of the real code
(600/600 clean returns), not transcribed by hand.

## Storage — two dynamic bytes on the management player struct

| offset  | field        | range      | persisted                             |
|---------|--------------|------------|---------------------------------------|
| `+0xa6` | MORALE base  | 40..99     | yes — save deserializer `FUN_00583bd0` |
| `+0xa7` | FITNESS      | 40..99     | yes (same stream)                     |

Neither exists in the EQUIPOS.PKF player record — both are runtime state, which is
why the extractor/`game_db.json` never carried them and the app rendered `-`.

## The canonical mutators — `FUN_00584cc0` (morale) / `FUN_00584c60` (fitness)

Identical shape, different byte. `add(delta)`:

```
if delta < 0:
    if value < 50:   delta = (2*delta) / 4     # halved   (soft floor)
    elif value <= 74: delta = (3*delta) / 4    # three-quarters
    # value >= 75: full hit
    # C-style truncation toward zero: (d + (d>>31 & 3)) >> 2
value = clamp(value + delta, 40, 99)
```

Negative hits are damped when the man is already low; positives always land full.
Hard clamp 40..99 (`0x28`..`0x63`).

## Season init — `FUN_005825c0` (roster reset, new game + season rollover)

- `morale = 90 + rand(10)` (`FUN_0058df90(10)` = `rand()*10 >> 15`, i.e. 0..9).
- `player+0xa8 = 99` (companion cap byte).
- If not injured: `fitness += (40 - fitness) / 2` — halfway toward 40. A fresh
  99-fitness man lands on **70**, which is EXACTLY what walkthrough frames 081/084
  show (VdG + Solskjaer both FITNESS 70 in week 1) — and morale 94/90 sits in the
  init band 90..99. The frames validate the init path end-to-end.

## The DISPLAYED morale — `FUN_00582db0` (getter, computed at render time)

```
mo = base(+0xa6)
   + position_preference_term          # FUN_00582e90, <= 0
   + out_of_position_penalty           # -15, XI-slot zone check vs DAT_00638e34.. tables
   + club_term                         # FUN_0057b710, >= 0 (rich club / fair wage / cup run)
return clamp(mo, 40, 99)
```

- **Position-preference term** (`FUN_00582e90`): the player carries SIX preferred
  fine-position bytes at `+0x1d..+0x22`; the term takes the MINIMUM "distance"
  between his current fine pos (`+0x18`) and each preference through an 18x18
  banded distance table (exact match 0; near 5/15/24; far 40; keeper<->outfield 70),
  then returns `-(min*3)>>2` (i.e. −0.75×min → 0..−52).
- **Out-of-position penalty**: if he sits in an XI slot (`+0x19 < 0xc`) whose pitch
  rect (formation table row `(slot+2)*0x20` off the club) falls outside his role's
  allowed zone (`DAT_00638e34/38/3c/40[role*0x14]`), morale shows −15.
- **Club term** (`FUN_0057b710`, club object = `this`):
  - gate term: if `+0x1fc` > 999,999: `min(8, receipts/players/div * 2)` with div
    by division band (`+0x58`): 0→5M, 1→4M, 2→3M, 3→2M, else 1M. `+0x1fc` is
    banked into the finance ledger and ZEROED after every match
    (`FUN_0057af10`), so it is the latest GATE RECEIPTS, not club cash.
  - wage term: avg = wage bill(`+0x1f8`)/players(`+0x28`; the post-match loop
    counts this field down per man — it is the squad count); player wage float
    (`+0x74`) ≤ 4.0×avg → +8; ≤ 8.0×avg → +4; above → 0 (constants 0x638da0/da4).
    The bill/wage unit is shared between the two fields (only ratios are
    compared); the port reads both as yearly.
  - competition term: slot 7 of the club's competition array (`+0x264`) through
    `FUN_00578b80` (small bonuses by competition id + round byte; ids 8/9/0xb and
    the deep 0xc rounds return huge values that pin the display at 99).

## RATING / AV — `FUN_00581e60` ★ the un-RE'd FICHA RATING + squad-AV lever, CLOSED

```
RATING = (VE + RE + AG + CA + FITNESS + MORALE_displayed) / 6      # integer div
```

(struct bytes `+0x9c +0x9d +0x9e +0x9f +0xa7` + `FUN_00582db0()`.)

**Confirmed against the walkthrough frames with real game_db attrs:**

| player     | VE RE AG CA (game_db) | FI | MO | (sum)/6 | frame |
|------------|----------------------|----|----|---------|-------|
| Van der Gouw | 81 79 79 80        | 70 | 94 | 484/6 = **80** | 081: RATING **80** ✓ |
| Solskjaer  | 87 83 81 84          | 70 | 90 | 495/6 = **82** | 084: RATING **82** ✓ |

The squad screens' keeper-AV mystery (frame 80 vs our outfield-8 average 51) is
resolved: the original never averages the 10 skill attrs — RATING/AV is the four
CORE attrs + the two dynamic bars. Same function drives the auto-sub pick (below).

### Table-paint proof + TEAM RATING (closed 2026-07-06)

The squad-TABLE AV column (LINE-UP / TACTICS board / VIEW RIVAL) is the SAME
function — traced from the paint side (decompiles in `docs/re/lineup/`):

- **`FUN_004f5260`** = the boxed-row squad-table control's row painter (the
  vtable paint the LINE-UP screen widgets dispatch to). It calls
  `FUN_00581e60()` and draws it at rel x `0x142..0x15a` → screen **353..377 =
  the walked AV cell [353,22)**; the numeric-mode MO cell (rel `0x128..0x140`)
  comes from `FUN_00582db0()`; the RATING-mode star strip gets the SAME
  `FUN_00581e60` value via the star drawer `FUN_004f79b0` (the (AV+1)/10
  halves rule). Shirt-number byte `+0xf8` at rel 3..24, name at rel
  `0x27..0x8e`, injured/banned branch via `FUN_005836a0` — every walked column
  accounted for. The stored-attr weighted-mean search (tacticas_screen_re.md)
  failed precisely because FI/MO are dynamic, not in EQUIPOS.
- **TEAM RATING** (`FUN_004fe540`, draws the `TEAM RATING` string):
  `FUN_0057a3a0() / 0xb` — `FUN_0057a3a0` sums `FUN_00581e60()` over the XI
  (`+0x19 < 0xc`) SKIPPING injured/banned (`FUN_005836a0`), and the divisor is
  a FIXED 11 regardless of how many were skipped. **Walked proof, exact:**
  frame 155 (Beckham injured) shows 77 = (936 − 88)/11 — unreachable by any
  mean; frame 015 shows 87 = 959/11.
- **Beckham single-point anchor (frame 155)**: FI 82 + MO 99 + AV 88 all
  frame-shown; core4 (game_db) = 350 → (350+82+99)/6 = **88** exact.
- **014→155 delta**: all 11 MU AVs rise exactly +1 across the Mon-4 friendly —
  consistent with the played +3 FI / +3 MO post-match delta (+6/6 = +1).
- **Preseason fitness**: the Mon-4-Aug frames (014/015) need FI ≈ 95-99 on
  several men (Giovanni AV 91 with core4 352 needs FI+MO ≥ 194), while the
  post-kickoff FICHA frames (081/084) show FI 70 — so the `FUN_005825c0`
  halfway-toward-40 fitness leg lands at/by season KICKOFF, not at new-game
  creation; preseason squads sit at ~99.
- **CPU best-XI picker `FUN_005776f0`** (rival/auto-pick side): per broad
  group (`+0x1c`), over UNPICKED men (`+0x19 == 0x63`), takes max of
  `FUN_00581e60() * (+0xa8 cap byte)` (falls back to adjacent groups). The
  cap byte is 99 for everyone at init, so ordering equals pure-rating order —
  the app's `Tactics.auto_pick` stays faithful; `+0xa8`'s career semantics
  remain un-RE'd.

## Post-match updates (every club, every round)

1. **Slot deltas** (`FUN_00582690`, per player; QU = quality byte `+0x9f`):

   | state                        | fitness | morale            |
   |------------------------------|---------|-------------------|
   | injured or banned (`FUN_005836a0`) | −3 | QU<81 ? −4 : −5 |
   | played (slot < 0xc)          | +3      | +3                |
   | bench (slot 0xc..0x10)       | −1      | QU<81 ? −2 : −3   |
   | out of the 16 (slot ≥ 0x11)  | −2      | QU<81 ? −4 : −5   |

   Good players suffer MORE when left out. All through the damped mutators.

2. **Result delta** (`FUN_0057af10` → vtable `+0xd4` = `FUN_004179a0`): ONE value
   from (home division band, away division band, result), applied to EVERY player
   of the club. The full 2×10×10×3 matrix was PCode-emulated out of the binary:
   `docs/re/inventory-evidence/morale_result_delta.json` (oracle run
   `tools/re/specs/_moraledelta_run.spec/.out`, 600/600 RET). Anchors: same-band
   home win +8 / draw −2 / loss −10; away win +10 / draw +5 / loss −4; a band-3
   minnow winning away at a band-0 giant +20, the giant losing that game at home
   −24. Bands 0..3 = English divisions (cross-group defaults cover 4-6/7-9
   continental bands — the same grouping the wealth-divisor switch uses).

## Weekly tick (`FUN_0057b400`, per club)

League-position morale CEILING: `ceiling = FUN_00418030(division, position)`;
**only after 11 league games** (`FUN_0057d5a0() < 11 → ceiling 99`; also 99 if
division > 3 or the current cup-holder check fires). Division 0 table:

| position | 1-2 | 3-5 | 6-10 | 11-15 | 16+ |
|----------|-----|-----|------|-------|-----|
| ceiling  | 99  | 70  | 50   | 30    | 10  |

(Boundaries read with a 1-based position; the position getter — vtable `+0x84`,
un-decompiled — could be 0-based, which would shift every band one place. ±1
uncertainty, port uses 1-based like `Career.position()`.)

(div 1: <6→99 <9→70 <14→50 else 20 · div 2: <11→99 <15→70 else 30 · div 3:
<19→99 else 50.) Then per player: `if morale > ceiling + 8: add(-10 - rand(3))`.
A star squad rooted mid-table bleeds morale 10-12/week toward `ceiling+8`.

## Substitution nudge (`FUN_00578720` → `FUN_00582d80`, both players)

The auto-sub replaces an injured XI man with the best bench man by `FUN_00581e60`
RATING (doubled for same broad position, halved for a keeper candidate), swaps
slot bytes, then nudges BOTH through the slot-based table:
in XI now → QU<81 ? +2 : +1 · out now → QU<81 ? −2 : −4.

## New-signing jealousy (`FUN_00588ae0`, on the signing club's roster)

For every OTHER player of the club, against the newcomer N (fine pos `+0x18`,
broad group `+0x1c`, wage float `+0x74`; core4 = VE+RE+AG+CA, `FUN_00534570`,
quartered):

- **comparable core4/4 (within ±2 of N)** — own player (owning club `+0x6c` ==
  this club `+0x10`): same fine pos → N out-earns him −60, else −40; same broad
  group → N out-earns −50, else −30. Loanee at the club: same fine −50, same
  broad −40.
- **clear gap (>2 either way)** and his core4/4 < N's+3: own player: same fine →
  N out-earns −60, else −30; same broad (his wage < N's) → −20. Loanee: fine
  −35, broad −20.
- **clear gap and he's ≥ N+3** (clearly better man): −35 (the −50 same-fine
  assignment is immediately shadowed by the same-broad −35 — sequential
  assignment in the binary).

All deltas run through the damped mutator. Signing a star INTO a position
demoralises the incumbents — walkthrough gut-feel now has its mechanism.

## App port — `app/scripts/Morale.gd` (+ Career.gd hooks)

- `add/fitness_add` damped mutators; `season_init` (90+rand(10), fitness halfway
  to 40, fresh career seeds fitness 70 to match the frame-proven week-1 state).
- `display(p, ctx)`: base + the render-time terms. `club_term` (gate/wage,
  FUN_0057b710) is CODED and unit-tested, but **no screen feeds it yet** — no
  walkthrough frame shows a career-evolved morale to validate the term against,
  and feeding it to one screen would disagree with another for the same man.
  Every screen calls `display(p)` (ctx `{}`) → base morale, self-consistent.
  The preference/OOP/competition terms are the same held-back class (below).
- `av6(p)` = the confirmed RATING formula — now drives the FICHA RATING box and
  the SQUAD/LINE-UP/RIVAL/OFFERS AV cells; FI/MO cells drop their app-invented
  TI/RM placeholders for the real dynamics.
- Career hooks: post-match slot+result deltas for BOTH sides of every simulated
  fixture (manager + living league), weekly ceiling decay from the live table,
  jealousy on `sign_player`/`sign_free_agent`/`sign_loan`, season rollover
  re-init in `advance_season`.

## Honest gaps (all deliberate, evidence-bounded)

- The 6-byte preferred-position list builder for a FRESH career is un-RE'd (the
  save loader reads it verbatim; whatever seeds it on new game wasn't chased).
  Port uses `[posFine]` — exact for a man in his natural role, misses secondary
  positions until that builder is decoded.
- OOP −15 needs the formation-zone tables (`DAT_00638e34..40`) — un-dumped; the
  app's XI editor doesn't yet place men out of role, so the term is moot until
  the NEXT-2 lineup body work lands.
- Competition term `FUN_00578b80`: decoded mechanically (id×round → bonus) but
  slot-7 semantics (which competition array entry) unverified — not ported.
- The EXE match-sim's own USE of morale (does MO feed the sim?) is the match
  engine track, not this decode.
- Bench (slot 0xc..0x10): the app has no matchday-16 picker; it auto-marks the
  top-5 rated fit non-XI men as bench — mirrors the AI auto-pick (which the
  original provably drives by the same RATING function in the sub routine).
- AI-vs-AI transfer jealousy (TransferMarket.ai_round) not hooked; manager-club
  signings only.
