# The UNSACKABLE cheat — the three tests that end a career, and how to switch them off

Reversed + built 2026-07-28. Two artefacts, the same pair the three-forwards cheat has:

* `tools/hack/build_hack_exe.py --cheats=unsackable` — patches a copy of the owned
  `MANAGER.EXE` into `MANAGER_HACK.EXE` (the original is never modified).
* `tools/hack/verify_unsackable.py` — proves the patch on the REAL bytes by control-flow
  reachability, both for effect and for non-regression.

Everything below is about `FUN_00545fd0`. Sack path map:
[`sack_path_re.md`](sack_path_re.md).

## 1. There is no "sacking screen" — the sack is the hub's own run()

`FUN_00545fd0` IS the weekly hub screen's `run()`. Before it draws the menu it tests three
dismissal conditions in one order and, on ANY of them, raises one modal, detaches the
manager and returns without building a next screen. `FUN_004f96c0` then finds no live
manager record and throws `CGFXException(0x4e3e)`, which drops a single-manager career
back on the MAIN MENU. Disassembled again for this patch:

```
00546008  mov  eax, [ebp+0x480]            ; the club
0054600e  mov  edi, 3
00546013  cmp  [eax+0x224], edi            ; consecutive weeks running at a loss
00546019  jbe  0x54603a                    ;   -> keep him, fall to test 2
0054601b  mov  eax, [0x662d24]             ;   SACK_MSG_FINANCE  (-> 0x663818)
   ...
00546038  jmp  0x54608b
0054603a  mov  ecx, [eax+0x294]            ; the board's RESULTS-REVIEW sack flag
00546040  xor  ebx, ebx
00546042  cmp  ecx, ebx
00546044  je   0x546063                    ;   -> keep him, fall to test 3
00546046  mov  eax, [0x662d2c]             ;   SACK_MSG_RESULTS  (-> 0x663744)
   ...
00546061  jmp  0x54608b
00546063  cmp  [eax+0x28], 0x10            ; squad size vs the 16-man minimum
00546067  jae  0x5460a8                    ;   -> keep him, carry on drawing the hub
00546069  cmp  [0x66b1e8], ebx
0054606f  jne  0x5460a8
00546071  mov  eax, [0x662d30]             ;   SACK_MSG_SQUAD    (-> 0x663690)
   ...
0054608b  call 0x5e5050                    ; the shared "PREMIER MANAGER 98" modal
00546090  mov  ecx, [ebp+0x480]
00546099  push 0xffff
0054609e  call 0x57a500                    ; FUN_0057a500(club, 0xffff) -- detach
005460a3  jmp  0x5466ab                    ; ...and return
005460a8  mov  ecx, [eax+0x280]            ; the hub build carries on
```

All three arms converge on ONE block at `0x54608b`, so "the board can never dismiss you"
is exactly "`0x54608b` is unreachable from `0x545fd0`".

## 2. The patch — three bytes

Every "keep him" branch is a **2-byte short jump whose target is the next test** (or, for
the third, the hub build). So each opcode can become `JMP rel8` with its displacement
untouched:

| site | VA | stock | patched | target (unchanged) |
|---|---|---|---|---|
| finance | `0x546019` | `0x76` `jbe` | `0xEB` `jmp` | `0x54603a` |
| results | `0x546044` | `0x74` `je` | `0xEB` `jmp` | `0x546063` |
| squad | `0x546067` | `0x73` `jae` | `0xEB` `jmp` | `0x5460a8` |

No code cave, no displaced instruction, nothing relocated, no section resized. A
`--cheats=unsackable` build differs from `MANAGER.EXE` at **exactly three file offsets**
(`0x145419`, `0x145444`, `0x145467` — `cmp -l` confirms three lines and no more). The
builder asserts both the stock opcode AND that the short jump still decodes to the
documented target before it writes, so a different build cannot be silently mispatched.

## 3. Validation — CFG reachability on the real bytes

`tools/hack/verify_unsackable.py` walks `FUN_00545fd0`'s control-flow graph out of the
instruction bytes with capstone (every conditional takes both edges, calls fall through,
`ret` terminates) and reports, per binary, whether each dismissal arm and the shared
modal+detach block can be reached from the function entry:

```
MANAGER.EXE
  finance msg 0x662d24   0x54601b reachable from entry: True  [OK]
  results msg 0x662d2c   0x546046 reachable from entry: True  [OK]
  squad   msg 0x662d30   0x546071 reachable from entry: True  [OK]
  SHARED modal+detach    0x54608b reachable from entry: True  [OK]
  detach FUN_0057a500    0x54609e reachable from entry: True  [OK]

MANAGER_HACK.EXE
  finance msg 0x662d24   0x54601b reachable from entry: False [OK]
  results msg 0x662d2c   0x546046 reachable from entry: False [OK]
  squad   msg 0x662d30   0x546071 reachable from entry: False [OK]
  SHARED modal+detach    0x54608b reachable from entry: False [OK]
  detach FUN_0057a500    0x54609e reachable from entry: False [OK]
```

The stock rows are the important ones: they show the walk really does reach all three
arms in the unpatched binary, so "unreachable" in the patched one is the patch and not a
broken walker.

The patch touches no engine code at all, so the `three_forwards` oracle
(`tools/hack/run_hack_oracle.sh`) is unaffected — a combined build differs from a
`--cheats=three_forwards` build at those same three bytes and nowhere else.

## 4. What this does NOT cover, said plainly

`FUN_0057b6b0` @`0x57b6e5` is a **second** `push 0xffff / call FUN_0057a500`, swept over a
club list by `FUN_005865b0`. It is gated on `club+0x10 <= 0x26ae`, on the club having a
human manager (`club+0x5c != 0xffff`), on the Promanager career flag `DAT_0066b1e4`, and
on `FUN_0057a570` — which reads `club+0x50` (the competition preset index reversed in
[`stadium_screen_re.md`](stadium_screen_re.md)), looks the club's competition up in
`DAT_0066b190`, and calls its `vtbl[0xc8]` with `club+0x10`.

That is **not** one of the board's three dismissals and it is **not reversed**. This patch
does not touch it, the port does not model it, and neither claims to. It is the same
thread as the two open items "free if relegated" and "the unmanaged-club release ladder"
in [`REMAINING.md`](../REMAINING.md), and it is written down here because it was found
while chasing the sack, not because it is closed.

The four other calls to `FUN_0057a500` in `.text` were read and are job changes, not
dismissals: `0x549225` is the LEAVE CHAMPIONSHIP confirm (`FUN_005e5050` style `0x1006`,
`eax == 2` = Yes, then screen `0x396`), `0x563105` releases a club whose `+0x5c` matches
the manager being moved, and `0x55e8a6` / `0x56263f` are the same shape inside the
manager-record rebuild.

## 5. The Android port — SHIPPED 2026-07-28

The port's `Career.sack_message()` **is** those three tests, in the binary's own order and
with MANAGER.EXE's own message bytes, and `Main` consumes it at the hub mount — the same
place the original consumes it. So the port's mirror of "the three arms are unreachable"
is one early return at the head of that function (and of `sack_message_reason()`):

| EXE | port |
|---|---|
| `0x546019` / `0x546044` / `0x546067` flipped to `jmp` | `if cheat_unsackable: return ""` at the head of `Career.sack_message()` |
| the arms become unreachable code | the three `if`s below it are never evaluated |
| nothing else in the image changes | `sacked` is never set, so no career record, reputation hit or job-offer mount fires |

**The switch.** `AudioManager.cheat_unsackable`, persisted in `user://settings.cfg` under
the same `[cheats]` block the three-forwards switch uses (neither is a PM98 option, so
neither lives with them), and mirrored into `Career.cheat_unsackable` by
`AudioManager.set_unsackable`. Default OFF, and OFF leaves every dismissal exactly as the
original raises it.

**The UI** is a second row on the hub dropdown's OPTIONS modal, above THREE UP FRONT:
`OptionsPanel.R_UNSACK_ON` / `R_UNSACK_OFF` at design y306, same ON/OFF X-box idiom as
TRANSITIONS, in the game's own proman face and the modal's frame-sampled label ink. The
declared band grew from `(146,318,280,22)` to `(138,303,288,37)` to hold both rows:

* y303 is the first row of the box the original leaves free of label ink and OK-plate red
  (rows 300..302 still carry the TRANSITIONS caption at x177..266);
* x138 is 2 px inside the box's own left edge — the old x146 was found, by the new live
  diff below, to clip "THREE UP FRONT"'s right-aligned ink, which reaches x141.

**The gate.** `tools/re/diff_options_parity.py` now proves FOUR things, one more than it
did: the baked chrome is still 0 px vs the MANAGER.EXE capture outside the band; the band
overlaps none of the original's controls; the original draws nothing under it; and — new
2026-07-28 — the **LIVE Godot render** of the modal, in the capture's own MANAGER.INI
state, is **0 px vs the capture outside the band** (1892 px inside it = the two cheat rows
themselves). The frame is banked at
`tools/re/refs/options-2026-07-28/options_witness_state.png`, rendered by
`Main._options_shot` under Xvfb + GL. Until now that file's own docstring said a
live-render diff of this modal "has never been built"; it has now.

**Tests.** `app/tests/test_unsackable.gd` (31 checks, all pass) drives a real career into
each of the three conditions and asserts: with the cheat OFF each still raises
MANAGER.EXE's own message and reason word and the binary's precedence still holds; with it
ON none of them raise anything, singly or all three at once; a full 39-week driven season
with all three conditions **re-armed after every week** raises zero dismissals while the
identical state with the cheat off does dismiss; and the switch moves both the setting and
`Career`'s static live (the same career object flips back to dismissable when it is turned
off). `test_options_panel.gd` pins the four X-boxes inside the band, the two rows'
non-overlap and the setter wiring.

## 6. README wording (drop under the Download section)

```markdown
### Unsackable

The board can hold as many urgent meetings as it likes. Three weeks in the red, a results
review gone against you, a squad down to ten men: none of them end the career. Off by
default, toggle it in OPTIONS.
```

Evidence: `tools/hack/verify_unsackable.py`, `tools/hack/build_hack_exe.py`,
`app/tests/test_unsackable.gd`, `tools/re/diff_options_parity.py`,
`tools/re/refs/options-2026-07-28/options_witness_state.png`
