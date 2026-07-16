# SACK path decode — MANAGER.EXE (2026-07-17)

Answers the open question in `promanager_career_screens_re.md` ("What screen
follows a sack is NOT witnessed and NOT string-provable") as far as static RE
reaches tonight: the sack DECISION + MESSAGE selection + immediate aftermath
are now decoded from the binary; the *next screen* is constructed by the
weekly-driver caller, not by the sack routine itself (bounded follow-up below).

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

Modal message box (title "PREMIER MANAGER 98", flags 0x1001) → surface id set
to 0xffff via `FUN_0057a500` (a 22-byte setter: writes this+0x5c, triggers
`FUN_0057eb30`) → `FUN_0057eb30` treats 0xffff as TEARDOWN: frees the backdrop
buffers (+0x1e4/+0x200/+0x204) and builds nothing → return to caller.

**⇒ The post-sack screen is chosen by the CALLER of virtual slot 0x11c, not
here.** `FUN_0057a500` is otherwise only ever called with 0xffff (7 sites) —
it is a close-surface helper, not a screen selector.

## Open follow-up (bounded)

`call [reg+0x11c]` sites: 0x41203f 0x4269ec 0x43004c 0x432da1 0x43e5fb
0x44cbda 0x44d4c0 0x44ecb7 0x44eccc 0x44f2e5 0x44f337 0x4f9aa2 0x5c7fbb
0x5c8465 0x5f73c0. The week-advance driver among these (the one dispatching on
the 0x6338b0-vtable object) decides what mounts after the sack — that trace,
or a wine witness (engineer a squad-minimum sack: sell to <16 with the waiver
clear), closes the question. Until then the app's post-sack OFFERS SELECTION
mount stays flagged "original mid-career surface unknown" (see
promanager_career_screens_re.md).

## Side finds (same function, normal path)

- Loan replies: rejection format VA 0x663518 *"%s%s has rejected your loan
  request for %s."* (pointer slot 0x662d54), fired per pending loan request
  (+0x94 field on the offer node).
- The weekly loop walks the board's message list (+0x220) showing each entry
  in a "PREMIER MANAGER 98" modal, and constructs the CPU/team-offer screens
  (`FUN_0052afc0`, `FUN_0052b8a0`) for offers on the manager's players —
  consistent with team_offer_re.md's flow.

## App implications (no code changed for this doc)

- The app's post-sack `_show_job_offers()` mount keeps its honest flag — the
  original's post-sack surface is STILL unproven (teardown + caller-decided).
- The app has no financial-distress sack counter (+0x224 semantics un-chased);
  its squad-floor guards PREVENT the state that triggers sack #3 rather than
  simulating the sack — divergence is documented, not invented away.
