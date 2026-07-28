#!/usr/bin/env python3
"""Prove the UNSACKABLE patch, from the real bytes, by CFG reachability.

    python3 tools/hack/verify_unsackable.py [STOCK_EXE] [HACK_EXE]

`FUN_00545fd0` is the weekly hub screen's own run(). Before it draws the menu it tests
three dismissal conditions and, on ANY of them, falls into ONE shared block:

    0054608b  call 0x5e5050            ; the "PREMIER MANAGER 98" modal
    0054609e  call 0x57a500            ; FUN_0057a500(club, 0xffff) -- detach the manager
    005460a3  jmp  0x5466ab            ; ...and return without building a next screen

So "the board can never dismiss you" is exactly "0x54608b is unreachable from the
function's entry". This script walks the function's control-flow graph out of the real
instruction bytes with capstone -- every conditional takes BOTH edges, calls fall
through, `ret` terminates -- and asserts:

    stock  MANAGER.EXE       -> the block IS reachable, by all three arms
    hacked MANAGER_HACK.EXE  -> the block is NOT reachable, by any path

It also re-checks that the three flipped jumps still land on their documented targets,
so the patch cannot silently drift into "unreachable because we broke the function".

Not covered, and the script says so: `FUN_0057b6b0` @0x57b6e5 is a SECOND
`push 0xffff / call FUN_0057a500`, swept over a club list by `FUN_005865b0`, gated on
the Promanager flag `DAT_0066b1e4`. It is not one of the board's three dismissals and
this patch does not touch it.
"""

from __future__ import annotations

import sys
from pathlib import Path

from capstone import CS_ARCH_X86, CS_GRP_CALL, CS_GRP_JUMP, CS_GRP_RET, CS_MODE_32, Cs

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_STOCK = ROOT / "extracted" / "Premier Manager 98" / "MANAGER.EXE"

TEXT_VA = 0x401000
TEXT_OFF = 0x400

FUNC_ENTRY = 0x545FD0
DISMISS_BLOCK = 0x54608B  # call FUN_005e5050 (the modal) -> detach -> return
DETACH_CALL = 0x54609E  # call FUN_0057a500(club, 0xffff)
# Each test's own "you are sacked" arm: it loads that reason's message pointer and falls
# into the shared block above. Checked separately so the report names WHICH arm died.
ARMS = [
    ("finance msg 0x662d24", 0x54601B),
    ("results msg 0x662d2c", 0x546046),
    ("squad   msg 0x662d30", 0x546071),
]

# (name, VA of the "keep him" jump, stock opcode, target). Mirrors build_hack_exe.py.
SITES = [
    ("finance", 0x546019, 0x76, 0x54603A),
    ("results", 0x546044, 0x74, 0x546063),
    ("squad", 0x546067, 0x73, 0x5460A8),
]

# The function is large (it draws the whole hub); bound the walk generously.
SCAN_LIMIT = 0x546FFF


def _off(va: int) -> int:
    return va - TEXT_VA + TEXT_OFF


def reachable(data: bytes, entry: int, target: int) -> tuple[bool, list[int]]:
    """Walk the CFG from `entry`; return (target reached, one witness path)."""
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    md.detail = True
    seen: set[int] = set()
    # worklist entries are (va, path-so-far)
    work: list[tuple[int, list[int]]] = [(entry, [entry])]
    while work:
        va, path = work.pop()
        while True:
            if va in seen or not (FUNC_ENTRY <= va <= SCAN_LIMIT):
                break
            seen.add(va)
            if va == target:
                return True, path
            ins = next(md.disasm(data[_off(va) : _off(va) + 16], va, 1), None)
            if ins is None:
                break
            groups = set(ins.groups)
            nxt = va + ins.size
            if CS_GRP_RET in groups:
                break
            if CS_GRP_JUMP in groups:
                dest = ins.operands[0].imm if ins.operands[0].type == 2 else None
                if ins.mnemonic == "jmp":
                    if dest is None:
                        break  # indirect jump: cannot follow, stop this path
                    va = dest
                    path = path + [dest]
                    continue
                if dest is not None:
                    work.append((dest, path + [dest]))
            # calls and everything else fall through
            _ = CS_GRP_CALL
            va = nxt
    return False, []


def check(path: Path, expect_reachable: bool) -> bool:
    data = path.read_bytes()
    ok = True
    print(f"\n{path.name}")
    for name, va, stock_op, target in SITES:
        op = data[_off(va)]
        rel = int.from_bytes(data[_off(va) + 1 : _off(va) + 2], "little", signed=True)
        got = va + 2 + rel
        kind = "jmp" if op == 0xEB else f"cond({op:#04x})"
        flag = "OK" if got == target else "TARGET DRIFT"
        if got != target:
            ok = False
        print(f"  {name:<8} {va:#x}  {kind:<12} -> {got:#x}  [{flag}]")
        if expect_reachable and op != stock_op:
            print(f"    FAIL: expected the stock opcode {stock_op:#04x} here")
            ok = False
        if not expect_reachable and op != 0xEB:
            print(f"    FAIL: expected 0xeb (jmp) here")
            ok = False

    for label, va in ARMS + [
        ("SHARED modal+detach", DISMISS_BLOCK),
        ("detach FUN_0057a500", DETACH_CALL),
    ]:
        hit, _ = reachable(data, FUNC_ENTRY, va)
        verdict = "OK" if hit == expect_reachable else "FAIL"
        print(f"  {label:<22} {va:#x} reachable from entry: {str(hit):<5} [{verdict}]")
        if hit != expect_reachable:
            ok = False
    return ok


def main() -> int:
    stock = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_STOCK
    hack = Path(sys.argv[2]) if len(sys.argv) > 2 else stock.with_name("MANAGER_HACK.EXE")
    if not hack.exists():
        print(f"no patched EXE at {hack} -- run tools/hack/build_hack_exe.py first")
        return 2
    ok = check(stock, expect_reachable=True)
    ok = check(hack, expect_reachable=False) and ok
    print("\nPASS" if ok else "\nFAILURES ABOVE")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
