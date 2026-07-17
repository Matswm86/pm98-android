# SACK path decode — MANAGER.EXE (2026-07-17)

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
and an undefined-code region 0x54aa29..0x54aad4 (4 writes) — un-chased.

### +0x294 — board results-review sack flag

Set in **`FUN_0057a980`** (per-club weekly update), gated on
`DAT_0066b1e4 != 0` (mode, below) AND `club+0x50 == DAT_0066b1dc` (club's
division == division being updated) AND week > 9
(`FUN_0057d5a0` = `FUN_00586960(club->0x50)` = the division's current
week/round; internals un-chased). Fixed-week schedule — club+0x58 = the
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
  pos > 17; band 0 → points-based: 7+ points behind a reference club taken
  from the week-N standings (reference resolution decompiler-obscured —
  un-chased, do not guess).
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

## App implications (no code changed for this doc)

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
