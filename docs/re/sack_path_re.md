# SACK path decode — MANAGER.EXE (2026-07-17, BUILT 2026-07-28)

Status: **SHIPPED** — the three dismissals, the seven-week board review and the
post-sack exit to the TITLE screen are live; gate `app/tests/test_sacking.gd`
(MANAGER.EXE `FUN_00545fd0` / `FUN_0057a980` / `FUN_0057d3a0`). See
§"BUILT 2026-07-28" for what shipped and the two declared divergences.

Answers the open question in `promanager_career_screens_re.md` ("What screen
follows a sack is NOT witnessed and NOT string-provable"). Session 1 (night)
decoded the sack DECISION + MESSAGE selection + immediate aftermath; session 2
(morning, same date) traced the caller chain end-to-end and **RESOLVED the
post-sack surface** (§"Post-sack surface RESOLVED") plus the previously
un-chased internals: what increments +0x224, what sets +0x294, and what
DAT_0066b1e8 is (§"Sack internals decoded").

Method: Ghidra 12.1.2 headless (`~/ghidra-projects/pm98`, DecompileAt.java) +
raw byte scans of `extracted/Premier Manager 98/MANAGER.EXE`. Every address
below was read from the binary this session; nothing is inferred from memory.

## File-offset ↔ VA mapping (PE sections)

The RE docs quote strings by FILE OFFSET; code quotes VAs. MANAGER.EXE maps:

| section | VA | raw offset | note |
|---|---|---|---|
| .text  | 0x401000 | 0x400    | code |
| .rdata | 0x623000 | 0x221e00 | |
| .data  | 0x652000 | 0x250600 | strings live here: VA = off + 0x401a00 |

So e.g. file 0x261d44 = VA 0x663744 (NOT off+0x400000 — the flat +0x400000
shorthand used informally in older notes is wrong for .data by 0x1a00).

## The sack decision — `FUN_00545fd0` (weekly board check)

`FUN_00545fd0(this)` — 1791 bytes, virtual **slot 71** (offset 0x11c) of the
class whose vtable sits at **0x6338b0** (ctor ≈ 0x545c55). `this+0x480` holds
the board/career state object; all conditions below read that object.

Message pointer table at 0x662d24/0x662d2c/0x662d30 (all three referenced ONLY
from this function). Decision structure (decompiled):

```c
board = this->+0x480;
msg = 0x663818;                                  // financial-disaster text
if ((board->+0x224 < 4)                          // A: financial counter
    && (msg = 0x663744, board->+0x294 == 0)      // B: sack flag
    && (15 < board->+0x28                        // C: squad size > 15
        || (msg = 0x663690, DAT_0066b1e8 != 0))) // D: squad-min waiver
{
    ... normal weekly path (loan replies, CPU offers, team-offer screens) ...
} else {
    FUN_005e5050(hwnd, "PREMIER MANAGER 98", msg, 0x1001, 0, 0); // modal box
    FUN_0057a500(surfaceMgr, 0xffff);            // surface id := 0xffff
    FUN_0057d230();
    return;                                      // NO next screen built here
}
```

### The three sacks (condition → full message)

1. **Financial** — `board->+0x224 >= 4` → file 0x261e18 / VA 0x663818:
   *"The Directors have held an urgent meeting.\nThey have decided to
   terminate your contract as manager due to the disastrous financial
   management of the club."*
   +0x224 is a counter (threshold 4 — plausibly consecutive weeks in financial
   distress); what increments it is un-chased.
2. **Board sack (confidence)** — `board->+0x294 != 0` → file 0x261d44+0x261d6f
   / VA 0x663744: *"The Directors have held an urgent meeting,\nand have
   sacked you as manager of the club."*
   +0x294 is a pre-set sack flag; the confidence logic that sets it is
   un-chased.
3. **Squad minimum** — `board->+0x28 <= 15` AND `DAT_0066b1e8 == 0` → file
   0x261c90 / VA 0x663690: *"The Directors have decided to terminate your
   contract due to bad management of your squad, which does not have the
   minimum number of players needed to play in any championship."*
   +0x28 ≤ 15 ⇒ the 16-player floor (the app's `TransferMarket.SQUAD_MIN=16`
   sell/release guards match the EXE's sack threshold). `DAT_0066b1e8`
   nonzero WAIVES this sack — its semantics are UNKNOWN (do not guess).

### Aftermath (what the sack routine actually does)

Modal message box (title "PREMIER MANAGER 98", flags 0x1001) →
`FUN_0057a500(club, 0xffff)` → `FUN_0057eb30` frees the club's
human-management data → return to caller. **CORRECTION (session 2):** the
session-1 reading of +0x5c as a "surface id" was wrong. Decoded meaning:

- **club+0x5c = index of the club's HUMAN MANAGER record** in the manager
  array `DAT_0066c178` (stride 0x9c, count `DAT_0066c17c`); **0xffff = no
  human manager**. Proof: `FUN_0057d210(club)` returns
  `DAT_0066c178 + club->0x5c * 0x9c` (guarded on != 0xffff), and
  `FUN_004f8a00`'s reconciliation loop purges manager records whose club's
  +0x5c no longer points back at their index. `FUN_0057a500` = DETACH-manager
  helper (all 7 call sites pass 0xffff ✓).
- **`FUN_0057eb30(club)`** (777 B) = human-management data (re)initializer,
  fired on +0x5c change. Always: +0x224 := 0, +0x1ec := max(+0x1e8,+0x1ec).
  On DETACH (0xffff): frees **+0x1e4 = the 52-week financial table**
  (0x6a70 bytes = 52 × 0x20c-byte week blocks; first float of a block = bank
  balance, see FUN_0057fce0 below) plus the +0x200/+0x204 16-byte blocks. On
  ATTACH: allocates the table, backfills weeks 0..DAT_0066b1d8-1 with balance
  +0x1e8, creates the +0x1e0 board/objectives record (0x40 B, club id +
  `FUN_0057d780(+0x18,+0x1c,+0x50,+0x58)`). NOT "backdrop buffers".

## Post-sack surface RESOLVED (session 2, full caller chain)

Every address below read from the binary; decompiles in this session's
scratchpad runs (DecompileAt on the listed VAs).

1. **`FUN_004f9940` = the screen FACTORY** (385 B): takes a screen id,
   constructs the screen object (switch over ids 0x384/0x392/0x398..0x3c1/
   0x4e3e), calls vtable slot **0x118 = init** (for id 900/0x392 → the
   0x6338b0 class → init = `FUN_005469c0`, which BUILDS the weekly hub menu:
   CRect button grid, `RECURSOS\PREMIER\ICONOS\MENUPRIN...` art, title
   switched by `DAT_0066b1e4` — nonzero → "PROMANAGER MENU" string 0x65e204),
   then slot **0x11c = run** (= `FUN_00545fd0`, this doc). **Screen 900/0x392
   IS the weekly hub menu screen**; the board processing (sacks, messages,
   loan replies, CPU offers) is the front half of its run().
   The vtable at 0x6338b0 spans 141 slots (0x6338b0..0x633ae0).
2. **`FUN_004f96c0(club, id, arg)` = the career screen driver.** Loop:
   factory(id) → after the screen finishes, next id := `FUN_005bce40(screen,0)`
   (a message pump returning **screen+0x58**, the "next screen" the user's
   click stored) fed back into the factory UNFILTERED — this is the loop that
   mounts every career screen. After EVERY screen it checks
   **club+0x5c == 0xffff** (sacked/detached):
   - another manager record still live (scan of DAT_0066c178, club id +0x24
     != 0 and < 0x26ae, whose club's +0x5c != 0xffff) → **return** (code
     0x396) — multi-manager games simply continue with the other managers;
   - **no live manager → throw CGFXException(code 0x4e3e)**.
3. **Catch:** `FUN_004f8a00` (the season orchestrator that drives divisions
   DAT_0066b190[14], week loop, season end) catches the CGFXException at
   handler 0x4f8eab — **accepts ONLY code 0x4e3e** (anything else rethrown),
   runs cleanup `FUN_004f92e0`, and RETURNS (continuation 0x4f8ec6 = function
   epilogue; bytes verified).
4. **`FUN_004f81e0` = the outer game loop:** after `FUN_004f8a00` returns it
   loops back to `FUN_004f9380()`, which mounts **screen 0x4e3e = the MAIN
   MENU** and returns the menu choice (0x4e35 → `DAT_0066b1e4=0` career;
   0x4e36 → `DAT_0066b1e4=1` career; 0x4e3a = exit, caught at handler
   0x4f8269).

**⇒ In a single-human-manager career the original returns to the MAIN MENU
after a mid-season sack.** There is no mid-career post-sack OFFERS surface in
the binary's control flow. (Season-END screens exist separately and are now
fully chased — `FUN_004f9800` mounts 0x3b8 "END OF THE SEASON" and
`FUN_004f98c0` mounts 0x3ba "END OF THE GAME", both Promanager-gated; the
season-end OFFERS re-mount is the annual 0x3c1 OFFERS SELECTION screen. Full
decode 2026-07-17: [`seasonend_flow_re.md`](seasonend_flow_re.md).)
The app's post-sack OFFERS SELECTION mount is therefore a **known divergence
from the original**, no longer "unknown".

Weekly chain feeding the hub: `FUN_00448b60` (week driver, 3 call sites) →
`FUN_0057a980(club)` (per-club weekly update, below) →
`FUN_004f96c0(club, 900, 0)` → factory → hub init+run.

Side note on the other `call [reg+0x11c]` sites: `FUN_0044ee70` /
`FUN_0044cae0` are match-day screen loops whose factory ids are normalized to
a fixed set (0x3bb persistent + {0x39b,0x39c,0x3ac,0x3af,0x3ae,0x39d}) — the
board/hub id 900/0x392 never flows through them; only FUN_0057a980's direct
`FUN_004f96c0(club, 900, 0)` call mounts it.

## Sack internals decoded (session 2)

### +0x224 — consecutive loss-week counter (financial sack at ≥4)

Incremented in **`FUN_0057ee50`** (called via `FUN_0057a940`, the weekly
finance step). Test: `FUN_0057fce0(club, DAT_0066b1d8)` =
`*(float*)(club->0x1e4 + week*0x20c)` — **the bank balance of the current
week block** — compared against `_DAT_00638de0` = **0.0** (verified in
.rdata):

- balance ≥ 0.0 (or bypass `DAT_0066b1f8 != 0`): **+0x224 := 0** and manager
  record confidence **+0x2c += 1** (clamped < 0x3e9 = 1000);
- balance < 0.0: **+0x224 += 1**, confidence **+0x2c −= 5**, and (if
  `DAT_0066c0d8 != 0`) board message file 0x261eb4 / VA 0x6638b4:
  *"You have been running the club\nat a loss for %u week%c now.\n"*
  (%u = counter, %c = 's' when >1).

⇒ **financial sack = 4 consecutive weeks with negative bank balance.**
`DAT_0066b1f8` writers: `FUN_005765f0` (save-load path via `FUN_005602e0`)
and the region 0x54aa10..0x54aae8 — **CHASED 2026-07-17 (s10): these are the
four NIVELES "SELECT LEVEL OF THE GAME" choice handlers** (witness frame
`screenshots/promanager-career-2026-07-16/02_select_level_of_the_game.png`;
handler-table DATA refs 0x54a486/0x54a521; each handler ends
`FUN_005bd200(1)` = dialog unlink + result). Combos (asm-verified):

| handler | b1f4 | b1f8 | b1ec | = witnessed level caption |
|---|---|---|---|---|
| 0x54aa10 | 1 | **1** | 0 | TRAINER — "Automatic finances / Automatic contract renewal" |
| 0x54aa60 | 1 | 0 | 0 | MANAGER — "Automatic contract renewal" |
| 0x54aab0 | 0 | 0 | 1 | ACCOUNTANT — "Automatic tactics and squad" |
| 0x54aad0 | 0 | 0 | 0 | TOTAL — "Total control" |

⇒ **`DAT_0066b1f8` = the "Automatic finances" option (TRAINER level)** —
auto-managed finances is WHY it bypasses the financial sack. New global ids:
**`DAT_0066b1f4` = automatic contract renewal** (TRAINER+MANAGER),
**`DAT_0066b1ec` = automatic tactics and squad** (ACCOUNTANT). Guard
`DAT_00658a44` = players-age-OFF (¬bit4 of screen+0x3f4, setter 0x54a9f0);
TRAINER/MANAGER with "Players age ?" ON are refused with the modal
*"Options "Automatic contract renewal"\nand "Players age" are not
compatible."* (VA 0x65e8bc).

### +0x294 — board results-review sack flag

Set in **`FUN_0057a980`** (per-club weekly update), gated on
`DAT_0066b1e4 != 0` (mode, below) AND `club+0x50 == DAT_0066b1dc` (club's
division == division being updated) AND week > 9
(`FUN_0057d5a0` = `FUN_00586960(club->0x50)` = the division's current
week/round; **internals CHASED 2026-07-17 (s10)**: per-division (0-3 only)
cache of division vtable +0x150 = `FUN_00415510` — scan rounds 0..count
(+0x148), return the FIRST round whose date passes `FUN_004ecf20` (≥ today),
clamped to last round; cached per exact game date, invalidated by
`FUN_004ecf70` date-equality against `DAT_0066b18c`, value slots this+0xc,
date stamps this+0x44). Fixed-week schedule — club+0x58 = the
board-expectation BAND, club+0x50 = division index into `DAT_0066b190[]`:

| week | bands checked | action |
|---|---|---|
| 10 | +0x58 ∈ {0,1} | warning if below expectation at wk10 |
| 14 | +0x58 ∈ {0,1} | **+0x294 := 1** if below at wk10 AND not recovered by wk14, else := 0 |
| 18 | all | warning |
| 22 | all | **+0x294 := 1** if below at wk18 AND not recovered by wk22, else := 0 |
| 26 | all | **+0x294 := 1** if below at wk18 AND still below at wk26, else := 0 |
| 30 | +0x58 = 0 | warning |
| 34 | +0x58 = 0 | **+0x294 := 1** if below at wk30 AND not recovered by wk34, else := 0 |

Warning text (posted via `FUN_0057d2d0` to the club+0x220 message list,
shown as modals by the hub run): file 0x261d9c / VA 0x66379c: *"The
Directors inform you that they are very unhappy with the current situation
of the team and they expect better results."*

"Below expectation" = **`FUN_0057d3a0(club, week)`**, league position
(league vtable +0x88(club id)) vs band threshold:

- division 0 (Premier): band 1 → pos > 8; band 2 → pos > 15; band ≥3 →
  pos > 17; band 0 → points-based, **reference RESOLVED 2026-07-17 (s10) at
  asm level (0x57d400-0x57d476)**: division vtable +0x168 = `FUN_00415a00`
  builds a club-id table insertion-sorted by LEAGUE POINTS computed from
  played fixtures (`FUN_00441c70` sort, key `FUN_00440720`: home/away W/D/L
  → points values snapshot+0x18/+0x1a/+0x1c; fixture records: home +0x38,
  away +0x3a, goals +0x3c/+0x3d, played +0x40); the reference = the FIRST
  entry (`word [table+0]`) = **the league points-leader as of week−1**, and
  the trip condition is `leader_points ≥ own_points + 7` (both via division
  +0x188 = `FUN_00416490` points-as-of-week; positions via +0x88 likewise
  take (club, week−1)). Equal-points tie order = insertion-sort stability
  over the snapshot's input club list (un-chased which input order).
- divisions 1/2/3: first band of the division (4/7/10) → pos > 6; second
  band (5/8/0xb) → pos > 13; else → pos > 15.
- division > 3: never (no board review).

"Recovered" = **`FUN_0057d5b0(club, wkA, wkB)`** — the improvement check
between the warning week and the review week (same position/points machinery;
Premier band 0 = back within 7 points).

The flag is transient: **`FUN_0057a730`** (weekly reset, called from
`FUN_00586250` at the top of each season-loop pass in FUN_004f8a00) zeroes
+0x294 (and +0x270/+0x274) before the review can re-set it; `FUN_00545fd0`
consumes it in the same week's hub run. It is also save-persisted
(`FUN_0057bfb0`, the club deserializer, restores both +0x224 and +0x294).

### DAT_0066b1e8 — dead dev flag (squad-min waiver NEVER fires in retail)

BSS (beyond .data raw size → initial 0). The ONLY writes in the entire
binary are the two `= 0` in `FUN_004f81e0`'s menu branches (0x4f823c,
0x4f825c — both mode selections). No other store, direct or via the write
scan (ScanWrites.java over all write-mnemonics). ⇒ in the retail EXE the
squad-minimum sack (+0x28 ≤ 15) is ALWAYS armed, in both modes. Readers:
0x546069 (this check), FUN_005469c0 (hub init, 4 sites), FUN_004fd350,
0x549c4b/0x547f8e/0x54822e (undefined-code region — un-chased).

### DAT_0066b1e4 — career-mode flag (0x4e36 menu choice → 1)

Set by the main-menu outer loop: choice 0x4e35 → 0, choice 0x4e36 → 1 (also
restored by the save-load path `FUN_005765f0`; a further writer
`FUN_005454f0` is referenced only as a data pointer at 0x544e15/0x544e26 —
un-chased). Gates: the +0x294 results review (above), the season-end screens
`FUN_004f9800`/`FUN_004f98c0` (= 0x3b8 END OF THE SEASON / 0x3ba END OF THE
GAME, decoded in [`seasonend_flow_re.md`](seasonend_flow_re.md)), the annual
career-setup screen
(`FUN_004f9520((b1e4!=0)+0x3c0)` → screen 0x3c0 vs 0x3c1; 0x3c1 re-mounted
each season once `DAT_0066b18c` > 0x7cd = 1997), and the hub title
("PROMANAGER MENU" when nonzero). All of that matches the witnessed
Promanager-vs-Manager-League gating in promanager_career_screens_re.md —
consistent with **b1e4 = 1 ⇔ Promanager mode**, though the menu-button ↔
choice-code mapping (which button returns 0x4e36) was not witnessed this
session.

## Side finds (same function, normal path)

- Loan replies: rejection format VA 0x663518 *"%s%s has rejected your loan
  request for %s."* (pointer slot 0x662d54), fired per pending loan request
  (+0x94 field on the offer node).
- The weekly loop walks the board's message list (+0x220) showing each entry
  in a "PREMIER MANAGER 98" modal, and constructs the CPU/team-offer screens
  (`FUN_0052afc0`, `FUN_0052b8a0`) for offers on the manager's players —
  consistent with team_offer_re.md's flow.

## BUILT 2026-07-28 — the sacking is now where the original raises it

Status: **the three dismissals SHIP**, in `FUN_00545fd0`'s own order, raised by the
weekly hub mount and exiting to the TITLE screen.

Session 3 re-read the two functions above straight off the bytes with capstone
(`extracted/Premier Manager 98/MANAGER.EXE`, .text VA = file offset + 0x400c00) rather
than trusting the session-2 transcription. **Everything in §"Sack internals decoded"
reproduced exactly**, including the arms the port now implements:

* `FUN_0057a980` @0x57ad6a..0x57aec9 — the Promanager gate (`DAT_0066b1e4`), the
  division match (`club+0x50 == DAT_0066b1dc`), `FUN_0057d5a0() >= 10`, then the seven
  week arms 0xa/0xe/0x12/0x16/0x1a/0x1e/0x22 with the band gates
  (`[esi+0x58] == 0 || == 1` at 10/14, unrestricted at 18/22/26, `== 0` at 30/34),
  `mov [esi+0x294], eax` @0x57aeb2 and the warning post `FUN_0057d2d0(0x662d28)`.
  Week 26 is the one arm that calls `FUN_0057d3a0` TWICE (0x57ae47 + 0x57ae58) instead
  of the recovery check — "still below", not "did not improve".
* `FUN_0057d3a0` @0x57d3cc..0x57d582 — the thresholds, as literals:
  Premier band 1 `mov ecx,8`, band 2 `mov ecx,0xf`, else `mov edx,0x11`; band 0 the
  points arm with `add edi,7`. Divisions 1/2/3 repeat one shape: first band `mov ecx,6`,
  second `mov edx,0xd`, else `mov ecx,0xf` — with the band literals **4/5** (div 1),
  **7/8** (div 2), **0xa/0xb** (div 3). So club+0x58 is a GLOBAL index, Premier 0..3 and
  three bands per lower division.

### The band the port uses — DECLARED INFERENCE

`club+0x58`'s own loader site was **not** located (no `mov [reg+0x58]` write survives a
linear scan of the club-loader region, and `FUN_00579c70` never writes `param_1[0x16]`),
so the port does **not** read the band from the archive. It derives it from the game's own
START OF SEASON objective LABEL, which is witnessed for all 92 English clubs
(`club_economy.json`, frames s29..s32 of 2026-07-19):

| division | labels witnessed | bands in the binary | port's map |
|---|---|---|---|
| Premier | Champion / U.E.F.A. / Mid Table / Avoid Relegation | 0 / 1 / 2 / 3 | in that order |
| Div 1 | Promotion / Mid Table / Avoid Relegation | 4 / 5 / 6 | in that order |
| Div 2 | same three | 7 / 8 / 9 | in that order |
| Div 3 | same three | 10 / 11 / 12 | in that order |

The fit is 1:1 in every division and the threshold order matches the label order of
severity (title / European places / mid-table / the drop), which is what makes the map
forced rather than chosen — but it is still an inference, and it is flagged as one in
`Career.BOARD_BAND_OF_LABEL`. A club with no witnessed label gets band −1, which behaves
exactly like the binary's `division > 3` arm: **no review at all**.

### What shipped

| piece | where |
|---|---|
| the three messages, MANAGER.EXE's own bytes | `Career.SACK_MSG_FINANCE` / `_RESULTS` / `_SQUAD` |
| the board warning, 0x66379c | `Career.BOARD_WARN_MSG` |
| the seven review weeks + band gates | `Career.BOARD_REVIEW`, `_board_results_review()` |
| the thresholds + the 7-point title arm | `Career.BOARD_BAND_POS`, `below_expectation()` |
| club+0x294 | `Career.board_sack_flag` (saved, cleared by `_reset_board_review()`) |
| FUN_00545fd0's order of test | `Career.sack_message()` |
| the modal + the exit | `Main._show_career` → `_leave_career_sacked()` → TITLE |

`app/tests/test_sacking.gd` pins all of it (the order of test, the band table, the
verbatim strings, a driven season that only ever reviews on the seven weeks, and the
save/load round trip).

### Two divergences, both deliberate and both recorded

1. **The Promanager gate is not applied.** The original runs the results review only when
   `DAT_0066b1e4 != 0`; this port routes MANAGER LEAGUE and PRO-MANAGER LEAGUE through one
   career (`Main._title_action`), and it already ships the Promanager-gated screens
   (OFFERS SELECTION, MANAGER HISTORY, END OF THE SEASON), so the review runs always.
2. **The post-sack surface drops the autosave.** `FUN_0057a500`/`FUN_0057eb30` free the
   manager's data outright, so the running career is gone and the player has only what he
   last SAVED. `_leave_career_sacked()` deletes the "Continue" autosave and leaves the ten
   explicit SAVE GAME slots alone — the closest the port's autosaving hub can come.

**The port's old end-of-season SACK_GAP verdict and its post-sack JOB OFFERS mount are
both deleted** (`Manager.sack_decision` is gone). The offers list survives only as the
HEADHUNT route, which was always an app-side extension and is still flagged as one.

## App implications (superseded 2026-07-28 by the section above; kept for the record)

- **Post-sack surface is now PROVEN: the original quits to the MAIN MENU**
  (single-manager career). The app's post-sack `_show_job_offers()` mount is
  a documented DIVERGENCE, not an unknown. A faithful port either returns to
  the title/menu, or keeps the offers mount explicitly flagged as an
  app-side extension.
- Financial sack is now implementable faithfully: 4 consecutive weeks of
  negative bank balance (weekly check), with the loss-week warning message
  and the confidence −5/+1 bookkeeping on the manager record.
- Results-review sack is implementable faithfully: warnings at weeks
  10/18/30, sack evaluations at 14/22/26/34 per the band table above
  (Manager League careers never run it — DAT_0066b1e4 == 0 in that mode).
- The app's squad-floor guards PREVENT the state that triggers sack #3 rather
  than simulating the sack — divergence documented, not invented away; note
  the waiver global is dead in retail, so the original ALWAYS sacks at ≤15.


## The UNMANAGED-CLUB RELEASE LADDER — `FUN_0057b6b0`, read in full 2026-07-28 (s78)

`handoff-pm98-unsackable-hub-circle-2026-07-28` flagged `FUN_0057b6b0` @`0x57b6e5` as "a
SECOND `push 0xffff / call FUN_0057a500`, swept over a club list by `FUN_005865b0`, gated on
`DAT_0066b1e4` and on `FUN_0057a570` — not reversed, not touched". It is reversed now, and it
is a small function:

```
FUN_0057b6b0(club):
    if club[+0x10] > 0x26ae:      goto staff        ; club id above 9902 = a FOREIGN club
    FUN_0057f700()                                   ; a global per-club season step
    FUN_005883d0(club)
    if club[+0x5c] == 0xffff:     goto staff        ; not the hot seat -> nothing to release
    if DAT_0066b1e4 == 0:         goto staff        ; only in season-advance MODE 1
    if FUN_0057a570(club) != 0:   goto staff        ; the club is still IN its competition
    FUN_0057a500(club, 0xffff)                       ; DETACH THE MANAGER
staff:
    for (s = club[+0x24]; s; s = s[+0x100]):  FUN_00582c80(s)
```

and its one gate that was not previously read is the interesting one:

```
FUN_0057a570(club):
    idx = club[+0x50]                       ; the competition-index selector (stadium_screen_re.md)
    if idx >= 4: return 1                   ; a cup / foreign index counts as "still in"
    comp = DAT_0066b190[idx]                ; the league object for that index
    return comp->vtbl[0xc8](club[+0x10])    ; does that league still contain this club?
```

So the ladder is: **when the season advances and the manager's club is no longer a member of
the league it was hired into, the manager is detached from it** — the same
`FUN_0057a500(club, 0xffff)` the board's three dismissals use, so it ends the career the same
way. It is not one of the board's dismissals and the UNSACKABLE patch (`hack_unsackable.md`)
deliberately does not touch it, which is why that document's "not covered, said plainly" note
stands.

**Timing, and the mode flag.** `FUN_005865b0` sweeps a club-id list through it, and it has
exactly ONE caller: `FUN_004f8a00 @0x4f8dd6`, the season/competition driver. `DAT_0066b1e4` is
not a general "Promanager" flag but that driver's own MODE: `FUN_004f80a0` dispatches
`0x4e35 -> DAT_0066b1e4 = 0` and `0x4e36 -> DAT_0066b1e4 = 1`, calling `FUN_004f8a00` either
way, and the release only runs in mode 1.

**Not ported, and why.** The port has no equivalent of "the league object no longer contains
this club" as a separate fact — `Career` moves a relegated club's `league_id` directly — so
wiring this would need the membership model first. It is recorded here rather than
approximated.

## "FREE IF RELEGATED" — still not closed, and this is exactly how far it got

The clause itself is fully settled: it is offer-record field `rec+0x10`, its checkbox is the
top row of the CONTRACT panel, its generation rule is AV-banded, and the port ticks it with a
0-px render-diff (`offer_record_re.md` §5.1). Its DRAW is `0x52bfc0`, keyed on bit 3 of the
offer flags at `screen+0x144`.

What it DOES on relegation is **still not found.** The s76 note said a sweep of `screen+0x144`
was the wrong instrument (370 sites, almost all vtable calls) and that the offer-COMMIT path
was needed instead; that path was followed as far as `FUN_005889c0` (the accept test, which
reads only the asking price at `+0x1c` and the player's own `+0x70`/`+0x98`/`+0x9a`), and no
consumer of the clause turned up there. So the gap is unchanged and is stated as unchanged:
the clause is generated, stored, and drawn, and nothing has been found that reads it back.
